import rateLimit from 'express-rate-limit';

/**
 * Brute-force guard for credential endpoints.
 * 20 attempts / 15 min per IP is generous for a single user and blocks
 * dictionary attacks against /auth/login and /auth/register.
 */
export const authRateLimiter = rateLimit({
  windowMs: 15 * 60 * 1000,
  limit: 20,
  standardHeaders: 'draft-7',
  legacyHeaders: false,
  message: {
    success: false,
    error: 'Too many authentication attempts, please try again later',
    code: 'RATE_LIMITED',
  },
});