import { z } from 'zod';

/** Every inbound payload is validated with Zod. Schemas live here (single source). */

// ── Auth ────────────────────────────────────────────────────────────────────

export const registerSchema = z.object({
  body: z.object({
    email: z.string().email().max(254).transform((v) => v.toLowerCase()),
    password: z.string().min(8, 'Password must be at least 8 characters').max(72),
    name: z.string().min(2).max(50),
  }).strict(),
});
export type RegisterBody = z.infer<typeof registerSchema>['body'];

export const loginSchema = z.object({
  body: z.object({
    email: z.string().email().transform((v) => v.toLowerCase()),
    password: z.string().min(1),
  }).strict(),
});
export type LoginBody = z.infer<typeof loginSchema>['body'];

export const refreshSchema = z.object({
  body: z.object({
    refreshToken: z.string().min(1),
  }).strict(),
});
export type RefreshBody = z.infer<typeof refreshSchema>['body'];

// ── Users ───────────────────────────────────────────────────────────────────

export const updateProfileSchema = z.object({
  body: z.object({
    name: z.string().min(2).max(50).optional(),
    age: z.number().int().min(13).max(120).optional(),
    gender: z.enum(['male', 'female', 'other']).optional(),
    height: z.number().positive().max(300).optional(),
    weight: z.number().positive().max(500).optional(),
    fitnessLevel: z.enum(['BEGINNER', 'INTERMEDIATE', 'ADVANCED', 'ATHLETE']).optional(),
    goals: z
      .array(z.enum(['MUSCLE_GAIN', 'FAT_LOSS', 'ENDURANCE', 'STRENGTH', 'GENERAL_FITNESS']))
      .max(5)
      .optional(),
  }).strict().refine((v) => Object.keys(v).length > 0, {
    message: 'At least one field must be provided',
  }),
});
export type UpdateProfileBody = z.infer<typeof updateProfileSchema>['body'];

// ── Workouts ────────────────────────────────────────────────────────────────

export const GoalEnum = z.enum([
  'MUSCLE_GAIN',
  'FAT_LOSS',
  'ENDURANCE',
  'STRENGTH',
  'GENERAL_FITNESS',
]);
export type Goal = z.infer<typeof GoalEnum>;

const exerciseFields = z.object({
  name: z.string().min(1).max(120),
  sets: z.number().int().positive().max(99).optional(),
  reps: z.number().int().positive().max(999).optional(),
  weight: z.number().positive().max(2000).optional(),
  duration: z.number().int().positive().optional(),
  calories: z.number().int().positive().optional(),
  order: z.number().int().optional(),
}).strict();

const dateString = z.string().datetime({ offset: true }).optional().or(z.string().date());

export const createWorkoutSchema = z.object({
  body: z.object({
    title: z.string().min(1).max(120),
    goal: GoalEnum.optional(),
    date: dateString,
    duration: z.number().int().positive().max(1440).optional(),
    calories: z.number().int().positive().optional(),
    notes: z.string().max(2000).optional(),
    exercises: z.array(exerciseFields).max(50).optional(),
  }).strict(),
});
export type CreateWorkoutBody = z.infer<typeof createWorkoutSchema>['body'];

export const updateWorkoutSchema = z.object({
  body: z.object({
    title: z.string().min(1).max(120).optional(),
    goal: GoalEnum.optional(),
    date: dateString,
    duration: z.number().int().positive().max(1440).optional(),
    calories: z.number().int().positive().optional(),
    notes: z.string().max(2000).optional(),
  }).strict().refine((v) => Object.keys(v).length > 0, {
    message: 'At least one field must be provided',
  }),
});
export type UpdateWorkoutBody = z.infer<typeof updateWorkoutSchema>['body'];

export const paginationQuerySchema = z.object({
  query: z.object({
    page: z.coerce.number().int().min(1).max(100000).default(1),
    limit: z.coerce.number().int().min(1).max(100).default(20),
  }),
});
export type PaginationQuery = z.infer<typeof paginationQuerySchema>['query'];

export const workoutIdParamsSchema = z.object({
  params: z.object({
    id: z.string().uuid('Invalid workout id'),
  }),
});

// ── Habits ──────────────────────────────────────────────────────────────────

export const HabitTypeEnum = z.enum([
  'WAKE_UP_EARLY',
  'WORKOUT_COMPLETED',
  'DRINK_WATER',
  'EAT_HEALTHY',
  'SLEEP_ON_TIME',
  'STRETCH',
  'MEDITATE',
]);
export type HabitType = z.infer<typeof HabitTypeEnum>;

export const checkInSchema = z.object({
  body: z.object({
    type: HabitTypeEnum,
    date: z.string().date().optional(),
  }).strict(),
});
export type CheckInBody = z.infer<typeof checkInSchema>['body'];

export const habitQuerySchema = z.object({
  query: z.object({
    date: z.string().date().optional(),
  }),
});
export type HabitQuery = z.infer<typeof habitQuerySchema>['query'];

export const habitMonthQuerySchema = z.object({
  query: z.object({
    year: z.coerce.number().int().min(2000).max(2100).default(new Date().getFullYear()),
    month: z.coerce.number().int().min(1).max(12).default(new Date().getMonth() + 1),
  }),
});
export type HabitMonthQuery = z.infer<typeof habitMonthQuerySchema>['query'];

// ── Sleep ───────────────────────────────────────────────────────────────────

export const recordSleepSchema = z.object({
  body: z.object({
    sleepTime: z.string().datetime({ offset: true }),
    wakeTime: z.string().datetime({ offset: true }),
  }).strict(),
});
export type RecordSleepBody = z.infer<typeof recordSleepSchema>['body'];

export const sleepHistoryQuerySchema = z.object({
  query: z.object({
    days: z.coerce.number().int().min(1).max(365).default(7),
  }),
});
export type SleepHistoryQuery = z.infer<typeof sleepHistoryQuerySchema>['query'];