import { Router, Request, Response, NextFunction } from 'express';
import { v4 as uuid } from 'uuid';
import { query, queryOne } from '../config/db';
import { authenticate } from '../middleware/auth';
import { sendData } from '../utils/response';

const router = Router();
router.use(authenticate);

// ============================================================
// Achievement definitions
// ============================================================

interface AchievementDef {
  id: string;
  title: string;
  description: string;
  icon: string;
  category: 'adherence' | 'vitals' | 'engagement' | 'social';
  condition: (stats: UserStats) => boolean;
}

interface UserStats {
  totalDosesTaken: number;
  currentStreak: number;
  longestStreak: number;
  totalVitalsLogged: number;
  totalMessages: number;
  totalAppointments: number;
  daysActive: number;
  adherenceRate: number; // 0-100
  profilesCount: number;
}

const ACHIEVEMENTS: AchievementDef[] = [
  // Adherence
  {
    id: 'first_dose',
    title: 'First Step',
    description: 'Take your first dose',
    icon: 'pill',
    category: 'adherence',
    condition: (s) => s.totalDosesTaken >= 1,
  },
  {
    id: 'dose_10',
    title: 'Getting Started',
    description: 'Take 10 doses on time',
    icon: 'checkmark.circle',
    category: 'adherence',
    condition: (s) => s.totalDosesTaken >= 10,
  },
  {
    id: 'dose_50',
    title: 'Consistent',
    description: 'Take 50 doses on time',
    icon: 'star',
    category: 'adherence',
    condition: (s) => s.totalDosesTaken >= 50,
  },
  {
    id: 'dose_100',
    title: 'Centurion',
    description: 'Take 100 doses on time',
    icon: 'trophy',
    category: 'adherence',
    condition: (s) => s.totalDosesTaken >= 100,
  },
  {
    id: 'dose_500',
    title: 'Medicine Master',
    description: 'Take 500 doses on time',
    icon: 'crown',
    category: 'adherence',
    condition: (s) => s.totalDosesTaken >= 500,
  },
  {
    id: 'perfect_week',
    title: 'Perfect Week',
    description: 'Maintain 100% adherence for 7 days',
    icon: 'flame',
    category: 'adherence',
    condition: (s) => s.currentStreak >= 7 && s.adherenceRate === 100,
  },
  {
    id: 'perfect_month',
    title: 'Perfect Month',
    description: 'Maintain 100% adherence for 30 days',
    icon: 'flame.fill',
    category: 'adherence',
    condition: (s) => s.currentStreak >= 30 && s.adherenceRate === 100,
  },

  // Streaks
  {
    id: 'streak_3',
    title: 'Hat Trick',
    description: '3-day streak',
    icon: 'flame',
    category: 'adherence',
    condition: (s) => s.currentStreak >= 3,
  },
  {
    id: 'streak_7',
    title: 'Week Warrior',
    description: '7-day streak',
    icon: 'flame',
    category: 'adherence',
    condition: (s) => s.currentStreak >= 7,
  },
  {
    id: 'streak_30',
    title: 'Monthly Champion',
    description: '30-day streak',
    icon: 'flame.fill',
    category: 'adherence',
    condition: (s) => s.currentStreak >= 30,
  },
  {
    id: 'streak_90',
    title: 'Quarter Master',
    description: '90-day streak',
    icon: 'medal',
    category: 'adherence',
    condition: (s) => s.currentStreak >= 90,
  },
  {
    id: 'streak_365',
    title: 'Year of Health',
    description: '365-day streak',
    icon: 'trophy.fill',
    category: 'adherence',
    condition: (s) => s.currentStreak >= 365,
  },

  // Vitals
  {
    id: 'first_vital',
    title: 'Health Tracker',
    description: 'Log your first vital',
    icon: 'heart',
    category: 'vitals',
    condition: (s) => s.totalVitalsLogged >= 1,
  },
  {
    id: 'vital_50',
    title: 'Data Driven',
    description: 'Log 50 vitals',
    icon: 'chart.line.uptrend.xyaxis',
    category: 'vitals',
    condition: (s) => s.totalVitalsLogged >= 50,
  },

  // Engagement
  {
    id: 'first_message',
    title: 'Connected',
    description: 'Send your first message to a doctor',
    icon: 'message',
    category: 'engagement',
    condition: (s) => s.totalMessages >= 1,
  },
  {
    id: 'first_appointment',
    title: 'Booked',
    description: 'Complete your first appointment',
    icon: 'calendar',
    category: 'engagement',
    condition: (s) => s.totalAppointments >= 1,
  },
  {
    id: 'active_30',
    title: 'Regular',
    description: 'Be active for 30 days',
    icon: 'person.fill.checkmark',
    category: 'engagement',
    condition: (s) => s.daysActive >= 30,
  },

  // Social / Family
  {
    id: 'caregiver',
    title: 'Family Care',
    description: 'Add a family member profile',
    icon: 'person.2',
    category: 'social',
    condition: (s) => s.profilesCount >= 2,
  },
];

// ============================================================
// Helpers
// ============================================================

async function getUserStats(userId: string): Promise<UserStats> {
  // Total doses taken
  const [doseRow] = await query<{ count: string }>(
    `SELECT COUNT(*) AS count
     FROM dose_logs dl
     JOIN medicines m ON m.id = dl.medicine_id
     JOIN episodes e ON e.id = m.episode_id
     JOIN profiles p ON p.id = e.profile_id
     WHERE p.user_id = $1 AND dl.status = 'taken'`,
    [userId]
  );

  // Current streak: consecutive days with 100% adherence
  const streakRows = await query<{ day: string; adherence: string }>(
    `SELECT
       DATE(dl.scheduled_time) AS day,
       CASE WHEN COUNT(*) FILTER (WHERE dl.status != 'taken') = 0 THEN '100' ELSE '0' END AS adherence
     FROM dose_logs dl
     JOIN medicines m ON m.id = dl.medicine_id
     JOIN episodes e ON e.id = m.episode_id
     JOIN profiles p ON p.id = e.profile_id
     WHERE p.user_id = $1
       AND dl.scheduled_time <= NOW()
     GROUP BY DATE(dl.scheduled_time)
     ORDER BY day DESC
     LIMIT 400`,
    [userId]
  );

  let currentStreak = 0;
  for (const row of streakRows) {
    if (row.adherence === '100') {
      currentStreak++;
    } else {
      break;
    }
  }

  let longestStreak = 0;
  let tempStreak = 0;
  for (const row of streakRows) {
    if (row.adherence === '100') {
      tempStreak++;
      longestStreak = Math.max(longestStreak, tempStreak);
    } else {
      tempStreak = 0;
    }
  }

  // Total vitals
  const [vitalRow] = await query<{ count: string }>(
    `SELECT COUNT(*) AS count FROM vitals v
     JOIN profiles p ON p.id = v.profile_id
     WHERE p.user_id = $1`,
    [userId]
  );

  // Total messages sent
  const [msgRow] = await query<{ count: string }>(
    `SELECT COUNT(*) AS count FROM messages WHERE sender_id = $1`,
    [userId]
  );

  // Total completed appointments
  const [apptRow] = await query<{ count: string }>(
    `SELECT COUNT(*) AS count FROM appointments a
     JOIN profiles p ON p.id = a.profile_id
     WHERE p.user_id = $1 AND a.status = 'completed'`,
    [userId]
  );

  // Days active (distinct days with any dose_log or vital)
  const [activeRow] = await query<{ count: string }>(
    `SELECT COUNT(DISTINCT d) AS count FROM (
       SELECT DATE(dl.scheduled_time) AS d
       FROM dose_logs dl
       JOIN medicines m ON m.id = dl.medicine_id
       JOIN episodes e ON e.id = m.episode_id
       JOIN profiles p ON p.id = e.profile_id
       WHERE p.user_id = $1
       UNION
       SELECT DATE(v.recorded_at) AS d
       FROM vitals v
       JOIN profiles p ON p.id = v.profile_id
       WHERE p.user_id = $1
     ) sub`,
    [userId]
  );

  // Adherence rate (last 30 days)
  const [adhRow] = await query<{ total: string; taken: string }>(
    `SELECT COUNT(*) AS total,
            COUNT(*) FILTER (WHERE dl.status = 'taken') AS taken
     FROM dose_logs dl
     JOIN medicines m ON m.id = dl.medicine_id
     JOIN episodes e ON e.id = m.episode_id
     JOIN profiles p ON p.id = e.profile_id
     WHERE p.user_id = $1
       AND dl.scheduled_time > NOW() - INTERVAL '30 days'
       AND dl.scheduled_time <= NOW()`,
    [userId]
  );

  const totalDoses30d = parseInt(adhRow?.total || '0');
  const takenDoses30d = parseInt(adhRow?.taken || '0');
  const adherenceRate = totalDoses30d > 0 ? Math.round((takenDoses30d / totalDoses30d) * 100) : 100;

  // Profile count
  const [profileRow] = await query<{ count: string }>(
    `SELECT COUNT(*) AS count FROM profiles WHERE user_id = $1`,
    [userId]
  );

  return {
    totalDosesTaken: parseInt(doseRow?.count || '0'),
    currentStreak,
    longestStreak,
    totalVitalsLogged: parseInt(vitalRow?.count || '0'),
    totalMessages: parseInt(msgRow?.count || '0'),
    totalAppointments: parseInt(apptRow?.count || '0'),
    daysActive: parseInt(activeRow?.count || '0'),
    adherenceRate,
    profilesCount: parseInt(profileRow?.count || '0'),
  };
}

async function getUnlockedAchievementIds(userId: string): Promise<Set<string>> {
  const rows = await query<{ achievement_id: string }>(
    `SELECT achievement_id FROM user_achievements WHERE user_id = $1`,
    [userId]
  );
  return new Set(rows.map((r) => r.achievement_id));
}

async function unlockAchievement(userId: string, achievementId: string): Promise<void> {
  await query(
    `INSERT INTO user_achievements (id, user_id, achievement_id, unlocked_at)
     VALUES ($1, $2, $3, NOW())
     ON CONFLICT (user_id, achievement_id) DO NOTHING`,
    [uuid(), userId, achievementId]
  );
}

// ============================================================
// GET /api/v1/achievements — List all with unlock status
// ============================================================
router.get('/', async (req: Request, res: Response, next: NextFunction) => {
  try {
    const userId = req.user!.sub;
    const unlocked = await getUnlockedAchievementIds(userId);

    const achievements = ACHIEVEMENTS.map((a) => ({
      id: a.id,
      title: a.title,
      description: a.description,
      icon: a.icon,
      category: a.category,
      unlocked: unlocked.has(a.id),
    }));

    // Sort: unlocked first, then by category
    achievements.sort((a, b) => {
      if (a.unlocked !== b.unlocked) return a.unlocked ? -1 : 1;
      return a.category.localeCompare(b.category);
    });

    sendData(res, achievements);
  } catch (err) {
    next(err);
  }
});

// ============================================================
// POST /api/v1/achievements/check — Check + unlock new ones
// ============================================================
router.post('/check', async (req: Request, res: Response, next: NextFunction) => {
  try {
    const userId = req.user!.sub;
    const stats = await getUserStats(userId);
    const unlocked = await getUnlockedAchievementIds(userId);

    const newlyUnlocked: Array<{ id: string; title: string; description: string; icon: string }> = [];

    for (const achievement of ACHIEVEMENTS) {
      if (unlocked.has(achievement.id)) continue;

      if (achievement.condition(stats)) {
        await unlockAchievement(userId, achievement.id);
        newlyUnlocked.push({
          id: achievement.id,
          title: achievement.title,
          description: achievement.description,
          icon: achievement.icon,
        });
      }
    }

    sendData(res, {
      newly_unlocked: newlyUnlocked,
      total_unlocked: unlocked.size + newlyUnlocked.length,
      total_available: ACHIEVEMENTS.length,
    });
  } catch (err) {
    next(err);
  }
});

// ============================================================
// GET /api/v1/achievements/streaks — Current streak data
// ============================================================
router.get('/streaks', async (req: Request, res: Response, next: NextFunction) => {
  try {
    const userId = req.user!.sub;
    const stats = await getUserStats(userId);

    // Daily breakdown for last 7 days
    const dailyBreakdown = await query<{
      day: string;
      total: string;
      taken: string;
      missed: string;
      skipped: string;
    }>(
      `SELECT
         DATE(dl.scheduled_time) AS day,
         COUNT(*) AS total,
         COUNT(*) FILTER (WHERE dl.status = 'taken') AS taken,
         COUNT(*) FILTER (WHERE dl.status = 'missed') AS missed,
         COUNT(*) FILTER (WHERE dl.status = 'skipped') AS skipped
       FROM dose_logs dl
       JOIN medicines m ON m.id = dl.medicine_id
       JOIN episodes e ON e.id = m.episode_id
       JOIN profiles p ON p.id = e.profile_id
       WHERE p.user_id = $1
         AND dl.scheduled_time > NOW() - INTERVAL '7 days'
         AND dl.scheduled_time <= NOW()
       GROUP BY DATE(dl.scheduled_time)
       ORDER BY day DESC`,
      [userId]
    );

    sendData(res, {
      current_streak: stats.currentStreak,
      longest_streak: stats.longestStreak,
      adherence_rate_30d: stats.adherenceRate,
      total_doses_taken: stats.totalDosesTaken,
      daily_breakdown: dailyBreakdown.map((d) => ({
        date: d.day,
        total: parseInt(d.total),
        taken: parseInt(d.taken),
        missed: parseInt(d.missed),
        skipped: parseInt(d.skipped),
        adherence: parseInt(d.total) > 0
          ? Math.round((parseInt(d.taken) / parseInt(d.total)) * 100)
          : 100,
      })),
    });
  } catch (err) {
    next(err);
  }
});

export default router;
