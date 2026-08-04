import { Request, Response, NextFunction } from 'express';

/**
 * Minimal structured request logger. Use `structlog`/pino in production
 * observability work; this keeps every request correlated locally in CI/logs.
 */
export function requestLogger(req: Request, res: Response, next: NextFunction): void {
  const started = Date.now();
  res.on('finish', () => {
    const duration = Date.now() - started;
    console.log(`${req.method} ${req.originalUrl} -> ${res.statusCode} (${duration}ms)`);
  });
  next();
}