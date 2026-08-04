import dotenv from 'dotenv';
import { AppError } from '../utils/AppError';

dotenv.config();

export const isProduction = process.env.NODE_ENV === 'production';

/**
 * In production the signing secrets MUST come from the environment.
 * Throw at boot rather than silently signing tokens with a known default —
 * the code fallbacks exist only for local development convenience.
 */
const requiredInProduction = (value: string | undefined, name: string): string => {
  if (isProduction && (!value || value.length < 16)) {
    throw new AppError(500, 'CONFIG_ERROR',
      `${name} must be set to a value of at least 16 characters in production`);
  }
  return value || '';
};

export const config = {
  port: parseInt(process.env.PORT || '3000', 10),
  nodeEnv: process.env.NODE_ENV || 'development',
  isProduction,
  jwt: {
    secret: requiredInProduction(process.env.JWT_SECRET, 'JWT_SECRET') || 'local-dev-secret',
    refreshSecret:
      requiredInProduction(process.env.JWT_REFRESH_SECRET, 'JWT_REFRESH_SECRET') ||
      'local-dev-refresh-secret',
    expiresIn: process.env.JWT_EXPIRES_IN || '15m',
    refreshExpiresIn: process.env.JWT_REFRESH_EXPIRES_IN || '7d',
  },
  cors: {
    // Comma-separated allowlist; `*` reflects any origin (native apps send no Origin).
    origins: (process.env.CORS_ORIGINS || '*').split(',').map((o) => o.trim()),
  },
  database: {
    url: process.env.DATABASE_URL || '',
  },
};