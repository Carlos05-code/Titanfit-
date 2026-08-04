import { Request, Response } from 'express';

/**
 * JSON 404 handler — replaces Express's default HTML "Cannot GET /x"
 * response, which would otherwise leak route-structure details.
 */
export function notFound(_req: Request, res: Response): void {
  res.status(404).json({
    success: false,
    error: 'Resource not found',
    code: 'NOT_FOUND',
  });
}