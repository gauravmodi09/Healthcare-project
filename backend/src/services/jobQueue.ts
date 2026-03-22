import Bull from 'bull';
import { env } from '../config/env';
import { query } from '../config/db';
import {
  sendDoseReminder,
  sendMissedDoseAlert,
  sendVitalAlert,
  getUserTokens,
  getNotificationPreferences,
} from './pushNotification';
import { emitVitalAlert } from './websocket';

// ============================================================
// Queue definitions — Redis-backed via Bull
// ============================================================

const defaultJobOptions: Bull.JobOptions = {
  attempts: 3,
  backoff: {
    type: 'exponential',
    delay: 2000, // 2s, 4s, 8s
  },
  removeOnComplete: 100,  // keep last 100 completed
  removeOnFail: 200,      // keep last 200 failed
};

function createQueue(name: string): Bull.Queue {
  const q = new Bull(name, env.REDIS_URL, {
    defaultJobOptions,
  });

  // Global event handlers
  q.on('completed', (job) => {
    console.log(`[Queue:${name}] Job ${job.id} completed`);
  });

  q.on('failed', (job, err) => {
    console.error(`[Queue:${name}] Job ${job.id} failed (attempt ${job.attemptsMade}):`, err.message);
  });

  q.on('stalled', (job) => {
    console.warn(`[Queue:${name}] Job ${job.id} stalled`);
  });

  q.on('error', (err) => {
    console.error(`[Queue:${name}] Queue error:`, err.message);
  });

  return q;
}

// ============================================================
// 1. Dose Reminder Queue
// ============================================================

interface DoseReminderJobData {
  medicineId: string;
  medicineName: string;
  profileId: string;
  userId: string;
  scheduledTime: string;
  caregiverUserId?: string;
}

export const doseReminderQueue = createQueue('dose-reminders');

doseReminderQueue.process(async (job) => {
  const data = job.data as DoseReminderJobData;
  console.log(`[DoseReminder] Processing reminder for ${data.medicineName} at ${data.scheduledTime}`);

  // Check if dose is still pending
  const dose = await query(
    `SELECT id, status FROM dose_logs
     WHERE medicine_id = $1 AND scheduled_time = $2 AND status = 'pending'`,
    [data.medicineId, data.scheduledTime]
  );

  if (dose.length === 0) {
    console.log(`[DoseReminder] Dose already handled — skipping`);
    return { skipped: true };
  }

  // Check user notification preferences
  const prefs = await getNotificationPreferences(data.userId);
  if (!prefs.dose_reminders) {
    return { skipped: true, reason: 'notifications_disabled' };
  }

  // Send push notification
  const tokens = await getUserTokens(data.userId);
  const results = await Promise.allSettled(
    tokens.map((token) =>
      sendDoseReminder(token, data.medicineName, data.scheduledTime)
    )
  );

  return { sent: results.length, medicineName: data.medicineName };
});

// ============================================================
// 2. Missed Dose Check — runs periodically to detect missed doses
// ============================================================

interface MissedDoseCheckData {
  windowMinutes?: number; // how far back to check (default 30)
}

export const missedDoseQueue = createQueue('missed-dose-checks');

missedDoseQueue.process(async (job) => {
  const { windowMinutes = 30 } = job.data as MissedDoseCheckData;
  console.log(`[MissedDose] Checking doses missed in last ${windowMinutes} minutes`);

  // Find pending doses past their scheduled time
  const missedDoses = await query<{
    dose_id: string;
    medicine_id: string;
    brand_name: string;
    profile_id: string;
    user_id: string;
    profile_name: string;
    caregiver_phone: string | null;
    scheduled_time: string;
  }>(
    `SELECT dl.id AS dose_id, dl.medicine_id, m.brand_name,
            p.id AS profile_id, p.user_id, p.name AS profile_name,
            p.caregiver_phone, dl.scheduled_time
     FROM dose_logs dl
     JOIN medicines m ON m.id = dl.medicine_id
     JOIN episodes e ON e.id = m.episode_id
     JOIN profiles p ON p.id = e.profile_id
     WHERE dl.status = 'pending'
       AND dl.scheduled_time < NOW() - INTERVAL '${windowMinutes} minutes'
       AND dl.scheduled_time > NOW() - INTERVAL '${windowMinutes * 2} minutes'`
  );

  // Mark as missed and notify
  for (const dose of missedDoses) {
    await query(
      `UPDATE dose_logs SET status = 'missed' WHERE id = $1 AND status = 'pending'`,
      [dose.dose_id]
    );

    // Notify caregiver if configured
    if (dose.caregiver_phone) {
      const prefs = await getNotificationPreferences(dose.user_id);
      if (prefs.missed_dose_alerts) {
        const caregiverTokens = await getUserTokens(dose.user_id);
        for (const token of caregiverTokens) {
          await sendMissedDoseAlert(token, dose.profile_name, dose.brand_name);
        }
      }
    }
  }

  return { checked: missedDoses.length, markedMissed: missedDoses.length };
});

// ============================================================
// 3. Report Generation Queue
// ============================================================

interface ReportJobData {
  profileId: string;
  userId: string;
  reportType: 'weekly' | 'monthly';
  startDate: string;
  endDate: string;
}

export const reportGenerationQueue = createQueue('report-generation');

reportGenerationQueue.process(async (job) => {
  const data = job.data as ReportJobData;
  console.log(`[Report] Generating ${data.reportType} report for profile ${data.profileId}`);

  // Compile adherence data
  const adherenceStats = await query<{
    total_doses: string;
    taken: string;
    missed: string;
    skipped: string;
  }>(
    `SELECT
       COUNT(*) AS total_doses,
       COUNT(*) FILTER (WHERE dl.status = 'taken') AS taken,
       COUNT(*) FILTER (WHERE dl.status = 'missed') AS missed,
       COUNT(*) FILTER (WHERE dl.status = 'skipped') AS skipped
     FROM dose_logs dl
     JOIN medicines m ON m.id = dl.medicine_id
     JOIN episodes e ON e.id = m.episode_id
     WHERE e.profile_id = $1
       AND dl.scheduled_time BETWEEN $2 AND $3`,
    [data.profileId, data.startDate, data.endDate]
  );

  // Compile vital summaries
  const vitalSummary = await query<{
    type: string;
    count: string;
    avg_value: string;
  }>(
    `SELECT type, COUNT(*) AS count,
            AVG((value->>'bpm')::numeric) AS avg_value
     FROM vitals
     WHERE profile_id = $1
       AND recorded_at BETWEEN $2 AND $3
     GROUP BY type`,
    [data.profileId, data.startDate, data.endDate]
  );

  // Store report record
  const reportId = require('uuid').v4();
  await query(
    `INSERT INTO reports (id, profile_id, type, period_start, period_end, data, created_at)
     VALUES ($1, $2, $3, $4, $5, $6, NOW())`,
    [
      reportId,
      data.profileId,
      data.reportType,
      data.startDate,
      data.endDate,
      JSON.stringify({
        adherence: adherenceStats[0] ?? null,
        vitals: vitalSummary,
      }),
    ]
  );

  return { reportId, profileId: data.profileId, type: data.reportType };
});

// ============================================================
// 4. Vital Check Queue — periodic threshold monitoring
// ============================================================

interface VitalCheckData {
  lookbackMinutes?: number;
}

export const vitalCheckQueue = createQueue('vital-checks');

vitalCheckQueue.process(async (job) => {
  const { lookbackMinutes = 15 } = job.data as VitalCheckData;
  console.log(`[VitalCheck] Checking vitals from last ${lookbackMinutes} minutes`);

  // Define thresholds per vital type
  const thresholds: Record<string, { min?: number; max?: number; key: string }> = {
    hr: { min: 50, max: 120, key: 'bpm' },
    spo2: { min: 90, max: 100, key: 'percentage' },
    temp: { min: 35.0, max: 38.5, key: 'celsius' },
    glucose: { min: 54, max: 300, key: 'mg_dl' },
  };

  // Query recent vitals
  const recentVitals = await query<{
    vital_id: string;
    profile_id: string;
    profile_name: string;
    type: string;
    value: any;
    doctor_id: string | null;
    recorded_at: string;
  }>(
    `SELECT v.id AS vital_id, v.profile_id, p.name AS profile_name,
            v.type, v.value, pdl.doctor_id, v.recorded_at
     FROM vitals v
     JOIN profiles p ON p.id = v.profile_id
     LEFT JOIN patient_doctor_links pdl ON pdl.profile_id = v.profile_id AND pdl.status = 'active'
     WHERE v.recorded_at > NOW() - INTERVAL '${lookbackMinutes} minutes'
       AND v.type IN ('hr', 'spo2', 'temp', 'glucose')`
  );

  let alertCount = 0;

  for (const vital of recentVitals) {
    const threshold = thresholds[vital.type];
    if (!threshold) continue;

    const parsedValue = typeof vital.value === 'string' ? JSON.parse(vital.value) : vital.value;
    const numValue = parsedValue[threshold.key];

    if (numValue == null) continue;

    const breached =
      (threshold.min != null && numValue < threshold.min) ||
      (threshold.max != null && numValue > threshold.max);

    if (breached && vital.doctor_id) {
      alertCount++;

      // WebSocket alert to doctor
      emitVitalAlert(vital.doctor_id, {
        patientId: vital.profile_id,
        patientName: vital.profile_name,
        vitalType: vital.type,
        value: parsedValue,
        threshold: { min: threshold.min, max: threshold.max },
        recordedAt: vital.recorded_at,
      });

      // Push notification to doctor
      const doctorTokens = await getUserTokens(vital.doctor_id);
      for (const token of doctorTokens) {
        await sendVitalAlert(
          token,
          vital.profile_name,
          vital.type,
          parsedValue,
          { min: threshold.min, max: threshold.max }
        );
      }
    }
  }

  return { checked: recentVitals.length, alerts: alertCount };
});

// ============================================================
// 5. Data Sync Queue — wearable API polling
// ============================================================

interface DataSyncJobData {
  userId: string;
  profileId: string;
  provider: 'terra' | 'noise' | 'healthkit';
  accessToken?: string;
}

export const dataSyncQueue = createQueue('data-sync');

dataSyncQueue.process(async (job) => {
  const data = job.data as DataSyncJobData;
  console.log(`[DataSync] Syncing ${data.provider} data for profile ${data.profileId}`);

  // Placeholder: actual API calls would go here
  // For Terra API: fetch from https://api.tryterra.co/v2/...
  // For Noise: fetch from their wearable API

  // Record last sync timestamp
  await query(
    `INSERT INTO sync_logs (profile_id, provider, synced_at, status)
     VALUES ($1, $2, NOW(), 'completed')
     ON CONFLICT (profile_id, provider)
     DO UPDATE SET synced_at = NOW(), status = 'completed'`,
    [data.profileId, data.provider]
  );

  return { provider: data.provider, profileId: data.profileId, status: 'completed' };
});

// ============================================================
// 6. Cleanup Queue — periodic maintenance
// ============================================================

interface CleanupJobData {
  tasks: Array<'expired_consents' | 'old_notifications' | 'stale_tokens' | 'old_logs'>;
}

export const cleanupQueue = createQueue('cleanup');

cleanupQueue.process(async (job) => {
  const { tasks = ['expired_consents', 'old_notifications', 'stale_tokens'] } =
    job.data as CleanupJobData;

  const results: Record<string, number> = {};

  for (const task of tasks) {
    switch (task) {
      case 'expired_consents': {
        const rows = await query(
          `DELETE FROM abdm_consents WHERE expires_at < NOW() RETURNING id`
        );
        results.expired_consents = rows.length;
        break;
      }
      case 'old_notifications': {
        const rows = await query(
          `DELETE FROM notifications WHERE created_at < NOW() - INTERVAL '90 days' RETURNING id`
        );
        results.old_notifications = rows.length;
        break;
      }
      case 'stale_tokens': {
        const rows = await query(
          `DELETE FROM device_tokens WHERE updated_at < NOW() - INTERVAL '60 days' RETURNING token`
        );
        results.stale_tokens = rows.length;
        break;
      }
      case 'old_logs': {
        const rows = await query(
          `DELETE FROM sync_logs WHERE synced_at < NOW() - INTERVAL '30 days' RETURNING profile_id`
        );
        results.old_logs = rows.length;
        break;
      }
    }
  }

  console.log('[Cleanup] Results:', results);
  return results;
});

// ============================================================
// Scheduled (repeatable) jobs — call once on startup
// ============================================================

export async function startScheduledJobs() {
  // Check for missed doses every 15 minutes
  await missedDoseQueue.add(
    { windowMinutes: 30 },
    {
      repeat: { cron: '*/15 * * * *' },
      jobId: 'missed-dose-periodic',
    }
  );

  // Vital threshold checks every 5 minutes
  await vitalCheckQueue.add(
    { lookbackMinutes: 5 },
    {
      repeat: { cron: '*/5 * * * *' },
      jobId: 'vital-check-periodic',
    }
  );

  // Daily cleanup at 3 AM
  await cleanupQueue.add(
    { tasks: ['expired_consents', 'old_notifications', 'stale_tokens', 'old_logs'] },
    {
      repeat: { cron: '0 3 * * *' },
      jobId: 'daily-cleanup',
    }
  );

  console.log('[JobQueue] Scheduled jobs registered');
}

// ============================================================
// Queue health — for /health endpoint
// ============================================================

export async function getQueueHealth(): Promise<Record<string, { waiting: number; active: number; failed: number }>> {
  const queues = [
    { name: 'dose-reminders', q: doseReminderQueue },
    { name: 'missed-dose-checks', q: missedDoseQueue },
    { name: 'report-generation', q: reportGenerationQueue },
    { name: 'vital-checks', q: vitalCheckQueue },
    { name: 'data-sync', q: dataSyncQueue },
    { name: 'cleanup', q: cleanupQueue },
  ];

  const health: Record<string, { waiting: number; active: number; failed: number }> = {};

  for (const { name, q } of queues) {
    const [waiting, active, failed] = await Promise.all([
      q.getWaitingCount(),
      q.getActiveCount(),
      q.getFailedCount(),
    ]);
    health[name] = { waiting, active, failed };
  }

  return health;
}

// ============================================================
// Graceful shutdown
// ============================================================

export async function shutdownQueues() {
  console.log('[JobQueue] Shutting down queues...');
  await Promise.all([
    doseReminderQueue.close(),
    missedDoseQueue.close(),
    reportGenerationQueue.close(),
    vitalCheckQueue.close(),
    dataSyncQueue.close(),
    cleanupQueue.close(),
  ]);
  console.log('[JobQueue] All queues closed');
}
