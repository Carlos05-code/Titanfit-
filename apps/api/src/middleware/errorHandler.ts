import { NextFunction, Request, Response } from 'express';
import { ZodError } from 'zod';
import { Prisma } from '@prisma/client';
import { AppError } from '../utils/AppError';

/**
 * Centralized error handler.
 *
 * Controllers forward failures with `next(err)` (see `asyncHandler`). This
 * middleware translates expected domain errors (AppError), validation errors
 * (Zod), and known Prisma errors into a consistent JSON envelope WITHOUT
 * leaking internal details. Unexpected errors log the full stack server-side
 * and return a generic message when `NODE_ENV=production`.
 */
export function errorHandler(
  err: Error,
  _req: Request,
  res: Response,
  _next: NextFunction,
): void {
  // Expected domain error carrying its own status.
  if (err instanceof AppError) {
    res.status(err.status).json({
      success: false,
      error: err.message,
      code: err.code,
    });
    return;
  }

  // Request validation error.
  if (err instanceof ZodError) {
    res.status(400).json({
      success: false,
      error: 'Validation failed',
      code: 'VALIDATION_ERROR',
      details: err.errors.map((e) => ({
        field: e.path.join('.'),
        message: e.message,
      })),
    });
    return;
  }

  // Known Prisma failures: unique conflicts and record-not-found.
  if (err instanceof Prisma.PrismaClientKnownRequestError) {
    if (err.code === 'P2002') {
      res.status(409).json({ success: false, error: 'Resource already exists', code: 'CONFLICT' });
      return;
    }
    if (err.code === 'P2025') {
      res.status(404).json({ success: false, error: 'Resource not found', code: 'NOT_FOUND' });
      return;
    }
  }

  // Unexpected failure: log everything, leak nothing.
  console.error('Unhandled error:', err);
  const isProduction = process.env.NODE_ENV === 'production';
  res.status(500).json({
    success: false,
    error: isProduction ? 'Internal server error' : err.message,
    code: 'INTERNAL_ERROR',
  });
}