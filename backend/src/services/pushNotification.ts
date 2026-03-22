import apn from 'apn';
import { query, queryOne } from '../config/db';

// ============================================================
// Apple Push Notification Service
// ============================================================

let apnProvider: apn.Provider | null = null;

/** Initialize APN provider (call once at startup) */
export function initAPNProvider(options?: apn.ProviderOptions): apn.Provider {
  apnProvider = new apn.Provider(
    options ?? {
      token: {
        key: process.env.APN_KEY_PATH || './certs/APNsAuthKey.p8',
        keyId: process.env.APN_KEY_ID || '',
        teamId: process.env.APN_TEAM_ID || '',
      },
      production: process.env.NODE_ENV === 'production',
    }
  );

  apnProvider.on('error' as any, (err: Error) => {
    console.error('[APN] Provider error:', err.message);
  });

  console.log('[APN] Push notification provider initialized');
  return apnProvider;
}

/** Shutdown provider gracefully */
export function shutdownAPNProvider() {
  apnProvider?.shutdown();
  apnProvider = null;
}

// ============================================================
// Core send function
// ============================================================

interface PushPayload {
  title: string;
  body: string;
  data?: Record<string, any>;
  badge?: number;
  sound?: string;
  category?: string;
  threadId?: string;
}

export async function sendPushNotification(
  deviceToken: string,
  title: string,
  body: string,
  data?: Record<string, any>,
  badge?: number
): Promise<{ success: boolean; reason?: string }> {
  if (!apnProvider) {
    console.warn('[APN] Provider not initialized — skipping push');
    return { success: false, reason: 'provider_not_initialized' };
  }

  const notification = new apn.Notification();
  notification.alert = { title, body };
  notification.topic = process.env.APN_BUNDLE_ID || 'com.medcare.app';
  notification.sound = 'default';
  notification.badge = badge ?? 0;
  notification.payload = data ? { customData: data } : {};
  notification.expiry = Math.floor(Date.now() / 1000) + 3600; // 1 hour

  try {
    const result = await apnProvider.send(notification, deviceToken);

    if (result.failed.length > 0) {
      const failure = result.failed[0];
      const reason = failure.response?.reason || 'unknown';

      // Remove invalid/expired tokens from DB
      if (
        reason === 'BadDeviceToken' ||
        reason === 'Unregistered' ||
        reason === 'ExpiredProviderToken'
      ) {
        await removeDeviceToken(deviceToken);
        console.warn(`[APN] Removed invalid token: ${deviceToken.slice(0, 8)}...`);
      }

      return { success: false, reason };
    }

    return { success: true };
  } catch (err: any) {
    console.error('[APN] Send error:', err.message);
    return { success: false, reason: err.message };
  }
}

// ============================================================
// Batch send for multiple recipients
// ============================================================

export async function sendBatchPush(
  deviceTokens: string[],
  title: string,
  body: string,
  data?: Record<string, any>,
  badge?: number
): Promise<{ sent: number; failed: number; errors: string[] }> {
  const results = await Promise.allSettled(
    deviceTokens.map((token) => sendPushNotification(token, title, body, data, badge))
  );

  let sent = 0;
  let failed = 0;
  const errors: string[] = [];

  for (const result of results) {
    if (result.status === 'fulfilled' && result.value.success) {
      sent++;
    } else {
      failed++;
      if (result.status === 'fulfilled' && result.value.reason) {
        errors.push(result.value.reason);
      } else if (result.status === 'rejected') {
        errors.push(result.reason?.message || 'unknown');
      }
    }
  }

  return { sent, failed, errors };
}

// ============================================================
// Domain-specific notification helpers
// ============================================================

export async function sendDoseReminder(
  deviceToken: string,
  medicineName: string,
  scheduledTime: string
) {
  return sendPushNotification(
    deviceToken,
    'Time for your medicine',
    `Take ${medicineName} — scheduled at ${scheduledTime}`,
    { type: 'dose_reminder', medicineName, scheduledTime },
    1
  );
}

export async function sendMissedDoseAlert(
  caregiverToken: string,
  patientName: string,
  medicineName: string
) {
  return sendPushNotification(
    caregiverToken,
    'Missed Dose Alert',
    `${patientName} missed their dose of ${medicineName}`,
    { type: 'missed_dose', patientName, medicineName },
    1
  );
}

export async function sendMessageNotification(
  deviceToken: string,
  senderName: string,
  preview: string
) {
  return sendPushNotification(
    deviceToken,
    senderName,
    preview.length > 100 ? preview.substring(0, 97) + '...' : preview,
    { type: 'new_message', senderName },
    1
  );
}

export async function sendAppointmentReminder(
  deviceToken: string,
  doctorName: string,
  time: string
) {
  return sendPushNotification(
    deviceToken,
    'Upcoming Appointment',
    `Your appointment with Dr. ${doctorName} is at ${time}`,
    { type: 'appointment_reminder', doctorName, time }
  );
}

export async function sendVitalAlert(
  doctorToken: string,
  patientName: string,
  vitalType: string,
  value: any,
  threshold: { min?: number; max?: number }
) {
  const valueStr = typeof value === 'object' ? JSON.stringify(value) : String(value);
  return sendPushNotification(
    doctorToken,
    'Vital Alert',
    `${patientName}: ${vitalType} reading ${valueStr} is outside safe range`,
    { type: 'vital_alert', patientName, vitalType, value, threshold },
    1
  );
}

export async function sendQueueNotification(
  deviceToken: string,
  position: number,
  estimatedWait: number
) {
  return sendPushNotification(
    deviceToken,
    'Queue Update',
    position <= 2
      ? `You're next! Estimated wait: ${estimatedWait} min`
      : `Your position: #${position} — ~${estimatedWait} min wait`,
    { type: 'queue_update', position, estimatedWait }
  );
}

// ============================================================
// Device token DB helpers
// ============================================================

export async function saveDeviceToken(
  userId: string,
  deviceToken: string,
  platform: 'ios' | 'android' = 'ios'
): Promise<void> {
  await query(
    `INSERT INTO device_tokens (user_id, token, platform, updated_at)
     VALUES ($1, $2, $3, NOW())
     ON CONFLICT (token) DO UPDATE SET user_id = $1, platform = $3, updated_at = NOW()`,
    [userId, deviceToken, platform]
  );
}

export async function removeDeviceToken(deviceToken: string): Promise<void> {
  await query('DELETE FROM device_tokens WHERE token = $1', [deviceToken]);
}

export async function removeAllUserTokens(userId: string): Promise<void> {
  await query('DELETE FROM device_tokens WHERE user_id = $1', [userId]);
}

export async function getUserTokens(userId: string): Promise<string[]> {
  const rows = await query<{ token: string }>(
    'SELECT token FROM device_tokens WHERE user_id = $1',
    [userId]
  );
  return rows.map((r) => r.token);
}

// ============================================================
// Notification preferences DB helpers
// ============================================================

export interface NotificationPreferences {
  dose_reminders: boolean;
  missed_dose_alerts: boolean;
  messages: boolean;
  appointments: boolean;
  vital_alerts: boolean;
  queue_updates: boolean;
  marketing: boolean;
}

const DEFAULT_PREFERENCES: NotificationPreferences = {
  dose_reminders: true,
  missed_dose_alerts: true,
  messages: true,
  appointments: true,
  vital_alerts: true,
  queue_updates: true,
  marketing: false,
};

export async function getNotificationPreferences(
  userId: string
): Promise<NotificationPreferences> {
  const row = await queryOne<{ preferences: NotificationPreferences }>(
    'SELECT preferences FROM notification_preferences WHERE user_id = $1',
    [userId]
  );
  return row?.preferences ?? DEFAULT_PREFERENCES;
}

export async function updateNotificationPreferences(
  userId: string,
  prefs: Partial<NotificationPreferences>
): Promise<NotificationPreferences> {
  const current = await getNotificationPreferences(userId);
  const merged = { ...current, ...prefs };

  await query(
    `INSERT INTO notification_preferences (user_id, preferences, updated_at)
     VALUES ($1, $2, NOW())
     ON CONFLICT (user_id) DO UPDATE SET preferences = $2, updated_at = NOW()`,
    [userId, JSON.stringify(merged)]
  );

  return merged;
}
