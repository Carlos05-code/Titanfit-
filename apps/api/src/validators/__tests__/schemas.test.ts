import {
  checkInSchema,
  createWorkoutSchema,
  habitMonthQuerySchema,
  loginSchema,
  paginationQuerySchema,
  recordSleepSchema,
  registerSchema,
  updateProfileSchema,
  workoutIdParamsSchema,
} from '../index';

describe('registerSchema', () => {
  it('accepts a valid registration', () => {
    const r = registerSchema.safeParse({
      body: { email: 'Foo@Bar.com', password: 'supersecret', name: 'Titan' },
    });
    expect(r.success).toBe(true);
    if (r.success) expect(r.data.body.email).toBe('foo@bar.com');
  });

  it('rejects short passwords and bad emails', () => {
    expect(
      registerSchema.safeParse({ body: { email: 'a@b.com', password: 'short', name: 'x' } }).success,
    ).toBe(false);
    expect(
      registerSchema.safeParse({ body: { email: 'nope', password: 'supersecret', name: 'Titan' } })
        .success,
    ).toBe(false);
  });
});

describe('loginSchema', () => {
  it('normalizes the email case', () => {
    const r = loginSchema.safeParse({ body: { email: 'Titan@X.com', password: 'pw' } });
    expect(r.success).toBe(true);
    if (r.success) expect(r.data.body.email).toBe('titan@x.com');
  });
});

describe('updateProfileSchema', () => {
  it('requires at least one field', () => {
    expect(updateProfileSchema.safeParse({ body: {} }).success).toBe(false);
    expect(updateProfileSchema.safeParse({ body: { name: 'New' } }).success).toBe(true);
  });

  it('rejects unknown keys (whitelisting)', () => {
    const r = updateProfileSchema.safeParse({ body: { xpPoints: 9999 } });
    expect(r.success).toBe(false);
  });
});

describe('createWorkoutSchema', () => {
  it('accepts a minimal workout', () => {
    expect(createWorkoutSchema.safeParse({ body: { title: 'Push day' } }).success).toBe(true);
  });

  it('accepts date as date-only or ISO-8601', () => {
    expect(
      createWorkoutSchema.safeParse({ body: { title: 'A', date: '2026-08-05' } }).success,
    ).toBe(true);
    expect(
      createWorkoutSchema.safeParse({
        body: { title: 'A', date: '2026-08-05T10:00:00Z' },
      }).success,
    ).toBe(true);
  });

  it('rejects garbage dates and negative durations', () => {
    expect(
      createWorkoutSchema.safeParse({ body: { title: 'A', date: 'not-a-date' } }).success,
    ).toBe(false);
    expect(
      createWorkoutSchema.safeParse({ body: { title: 'A', duration: -5 } }).success,
    ).toBe(false);
  });

  it('rejects unknown exercise keys', () => {
    const r = createWorkoutSchema.safeParse({
      body: { title: 'A', exercises: [{ name: 'Squat', cheats: true }] },
    });
    expect(r.success).toBe(false);
  });
});

describe('workoutIdParamsSchema', () => {
  it('accepts a UUID and rejects anything else', () => {
    const uuid = 'f47ac10b-58cc-4372-a567-0e02b2c3d479';
    expect(workoutIdParamsSchema.safeParse({ params: { id: uuid } }).success).toBe(true);
    expect(workoutIdParamsSchema.safeParse({ params: { id: 'abc' } }).success).toBe(false);
    expect(workoutIdParamsSchema.safeParse({ params: {} }).success).toBe(false);
  });
});

describe('paginationQuerySchema', () => {
  it('coerces strings and applies defaults', () => {
    const r = paginationQuerySchema.safeParse({ query: {} });
    expect(r.success).toBe(true);
    if (r.success) {
      expect(r.data.query.page).toBe(1);
      expect(r.data.query.limit).toBe(20);
    }
    const r2 = paginationQuerySchema.safeParse({ query: { page: '3', limit: '50' } });
    expect(r2.success).toBe(true);
    if (r2.success) {
      expect(r2.data.query.page).toBe(3);
      expect(r2.data.query.limit).toBe(50);
    }
  });

  it('clamps limit at 100', () => {
    expect(paginationQuerySchema.safeParse({ query: { limit: '9999' } }).success).toBe(false);
  });
});

describe('habitMonthQuerySchema', () => {
  it('defaults year/month to now', () => {
    const r = habitMonthQuerySchema.safeParse({ query: {} });
    expect(r.success).toBe(true);
    if (r.success) {
      expect(r.data.query.year).toBe(new Date().getFullYear());
      expect(r.data.query.month).toBe(new Date().getMonth() + 1);
    }
  });
});

describe('checkInSchema', () => {
  it('accepts a valid habit type', () => {
    const r = checkInSchema.safeParse({ body: { type: 'WORKOUT_COMPLETED' } });
    expect(r.success).toBe(true);
  });

  it('rejects values outside the Prisma enum', () => {
    expect(checkInSchema.safeParse({ body: { type: 'WORKOUT' } }).success).toBe(false);
    expect(checkInSchema.safeParse({ body: { type: 'READ' } }).success).toBe(false);
  });
});

describe('recordSleepSchema', () => {
  it('accepts ISO-8601 with offset', () => {
    const r = recordSleepSchema.safeParse({
      body: { sleepTime: '2026-08-05T22:00:00Z', wakeTime: '2026-08-06T06:00:00Z' },
    });
    expect(r.success).toBe(true);
  });

  it('rejects naive date-times (no offset)', () => {
    const r = recordSleepSchema.safeParse({
      body: { sleepTime: '2026-08-05 22:00:00', wakeTime: '2026-08-06 06:00:00' },
    });
    expect(r.success).toBe(false);
  });
});