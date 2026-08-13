#!/usr/bin/env node
/**
 * End-to-end smoke test for the TitanFit API.
 *
 * Exercises the hardened surface: auth flows, CRUD + gamification side
 * effects, validation rejections, token rotation and 401 handling.
 *
 * Usage:
 *   node scripts/smoke-api.mjs [BASE_URL] [EMAIL]
 *
 * Env:
 *   BASE_URL  base URL (default https://titanfit-api.onrender.com)
 *   EMAIL     unique test email (default smoke-<timestamp>@test.com)
 *
 * The test user is NOT deleted by this script — clean up via
 * scripts/delete-user.mjs or the DB directly.
 */
const BASE = process.env.BASE_URL || process.argv[2] || 'https://titanfit-api.onrender.com';
const API = `${BASE}/api`;
const EMAIL = process.env.EMAIL || process.argv[3] || `smoke-${Date.now()}@test.com`;
const PASSWORD = 'SmokeTest-12345';

// The auth rate limiter (20 req / 15 min per IP) trips on the final section;
// set SKIP_RATE_LIMIT=1 to skip it when re-running within the same window.
const SKIP_RATE_LIMIT = process.env.SKIP_RATE_LIMIT === '1';

let passed = 0;
let failed = 0;
let accessToken = '';
let refreshToken = '';
let workoutId = '';

function check(name, condition, detail = '') {
  if (condition) {
    passed++;
    console.log(`  PASS  ${name}`);
  } else {
    failed++;
    console.error(`  FAIL  ${name}${detail ? ` — ${detail}` : ''}`);
  }
}

async function req(method, path, { token, body } = {}) {
  const res = await fetch(`${API}${path}`, {
    method,
    headers: {
      'Content-Type': 'application/json',
      ...(token ? { Authorization: `Bearer ${token}` } : {}),
    },
    body: body ? JSON.stringify(body) : undefined,
  });
  const json = await res.json().catch(() => ({}));
  return { status: res.status, json };
}

const uuid = '[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}';

console.log(`\nTitanFit API smoke test — ${BASE}\n`);

// ── Health (root path, not under /api) ────────────────────────────────────
const healthRes = await fetch(`${BASE}/health`, { method: 'GET' });
check('health endpoint returns 200', healthRes.status === 200, `got ${healthRes.status}`);

// ── Registration & login ──────────────────────────────────────────────────
const reg = await req('POST', '/auth/register', {
  body: { email: EMAIL, password: PASSWORD, name: 'Smoke Tester' },
});
check('register returns 201 + tokens', reg.status === 201 && !!reg.json.data?.accessToken,
  `got ${reg.status}`);
accessToken = reg.json.data?.accessToken ?? '';
refreshToken = reg.json.data?.refreshToken ?? '';

const dup = await req('POST', '/auth/register', {
  body: { email: EMAIL, password: PASSWORD, name: 'Smoke Tester' },
});
check('duplicate email rejected with 409', dup.status === 409, `got ${dup.status}`);

const login = await req('POST', '/auth/login', {
  body: { email: EMAIL.toUpperCase(), password: PASSWORD },
});
check('login (case-insensitive email) returns 200', login.status === 200 && !!login.json.data?.accessToken,
  `got ${login.status}`);
accessToken = login.json.data?.accessToken ?? '';
refreshToken = login.json.data?.refreshToken ?? '';

const badLogin = await req('POST', '/auth/login', { body: { email: EMAIL, password: 'wrong-pass' } });
check('wrong password rejected with 401', badLogin.status === 401, `got ${badLogin.status}`);

// ── AuthZ: no token → 401 ────────────────────────────────────────────────
const anon = await req('GET', '/workouts/stats');
check('unauthenticated request rejected with 401', anon.status === 401, `got ${anon.status}`);

// ── Workouts ──────────────────────────────────────────────────────────────
const workout = await req('POST', '/workouts', {
  token: accessToken,
  body: {
    title: 'Push Day',
    goal: 'STRENGTH',
    date: new Date().toISOString().split('T')[0],
    duration: 60,
    calories: 420,
    exercises: [
      { name: 'Bench Press', sets: 4, reps: 8, weight: 80, order: 1 },
      { name: 'Shoulder Press', sets: 3, reps: 10, weight: 40, order: 2 },
    ],
  },
});
check('create workout returns 201', workout.status === 201 && !!workout.json.data?.id,
  `got ${workout.status}`);
workoutId = workout.json.data?.id ?? '';

const list = await req('GET', '/workouts?page=1&limit=10', { token: accessToken });
check('list workouts paginates', list.status === 200 && Array.isArray(list.json.data?.workouts),
  `got ${list.status}`);

const patch = await req('PATCH', `/workouts/${workoutId}`, {
  token: accessToken,
  body: { title: 'Push Day (updated)', duration: 75 },
});
check('PATCH workout returns 200 + updated title',
  patch.status === 200 && patch.json.data?.title === 'Push Day (updated)', `got ${patch.status}`);

const badId = await req('GET', '/workouts/not-a-uuid', { token: accessToken });
check('invalid uuid rejected with 400', badId.status === 400, `got ${badId.status}`);

const foreignWorkout = await req('PATCH', '/workouts/00000000-0000-4000-8000-000000000000', {
  token: accessToken,
  body: { title: 'Hijack attempt' },
});
check('foreign/missing workout gives 404, not 403', foreignWorkout.status === 404, `got ${foreignWorkout.status}`);

// ── Habits ────────────────────────────────────────────────────────────────
const checkin = await req('POST', '/habits/checkin', {
  token: accessToken,
  body: { type: 'WORKOUT_COMPLETED', date: new Date().toISOString().split('T')[0] },
});
check('habit check-in returns 200', checkin.status === 200, `got ${checkin.status}`);

const badHabit = await req('POST', '/habits/checkin', {
  token: accessToken,
  body: { type: 'NOT_A_HABIT' },
});
check('invalid habit type rejected with 400', badHabit.status === 400, `got ${badHabit.status}`);

const monthly = await req('GET', '/habits/monthly?year=2026&month=8', { token: accessToken });
check('monthly habits returns 200', monthly.status === 200, `got ${monthly.status}`);

// ── Sleep ─────────────────────────────────────────────────────────────────
const sleep = await req('POST', '/sleep', {
  token: accessToken,
  body: {
    sleepTime: '2026-08-12T22:30:00Z',
    wakeTime: '2026-08-13T06:30:00Z',
  },
});
check('record sleep returns 201', sleep.status === 201, `got ${sleep.status}`);

const badSleep = await req('POST', '/sleep', {
  token: accessToken,
  body: { sleepTime: '2026-08-12 22:30:00', wakeTime: '2026-08-13 06:30:00' },
});
check('naive sleep timestamps rejected with 400', badSleep.status === 400, `got ${badSleep.status}`);

// ── Progress & profile ────────────────────────────────────────────────────
const stats = await req('GET', '/progress/stats', { token: accessToken });
check('progress stats return totals', stats.status === 200 && stats.json.data?.totalWorkouts >= 1,
  `got ${stats.status}`);

const profile = await req('PATCH', '/users/profile', {
  token: accessToken,
  body: { name: 'Smoke Tester Pro', weight: 82.5, fitnessLevel: 'INTERMEDIATE' },
});
check('PATCH profile returns updated weight',
  profile.status === 200 && profile.json.data?.weight === 82.5, `got ${profile.status}`);

const forged = await req('PATCH', '/users/profile', {
  token: accessToken,
  body: { xpPoints: 999999 },
});
check('unknown profile fields rejected with 400', forged.status === 400, `got ${forged.status}`);

// ── Token rotation & logout ───────────────────────────────────────────────
const refreshed = await req('POST', '/auth/refresh', { body: { refreshToken } });
check('refresh returns fresh tokens', refreshed.status === 200 && !!refreshed.json.data?.accessToken,
  `got ${refreshed.status}`);
const rotatedToken = refreshed.json.data?.refreshToken ?? '';

const logout = await req('POST', '/auth/logout', { token: accessToken });
check('logout returns 200', logout.status === 200, `got ${logout.status}`);

const reuse = await req('POST', '/auth/refresh', { body: { refreshToken: rotatedToken } });
check('rotated refresh token rejected after logout (401)',
  reuse.status === 401 || reuse.status === 400, `got ${reuse.status}`);

// ── Rate limiting (auth endpoints) ────────────────────────────────────────
// Runs last on purpose: tripping the limiter blocks this IP for 15 minutes.
if (SKIP_RATE_LIMIT) {
  console.log('  SKIP  rate limiter (SKIP_RATE_LIMIT=1)');
} else {
  let limited = false;
  for (let i = 0; i < 25; i++) {
    const r = await req('POST', '/auth/login', { body: { email: EMAIL, password: 'x' } });
    if (r.status === 429) {
      limited = true;
      break;
    }
  }
  check('auth rate limiter kicks in after repeated attempts', limited, 'no 429 observed');
}

console.log(`\n${passed} passed, ${failed} failed\n`);
console.log(`Test user: ${EMAIL} (clean up with scripts/delete-user.mjs)\n`);
process.exit(failed === 0 ? 0 : 1);