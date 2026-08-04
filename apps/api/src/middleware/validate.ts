import { NextFunction, Request, Response } from 'express';
import { ZodSchema } from 'zod';

/**
 * Validates `{ body, query, params }` against a Zod schema and, on success,
 * replaces `req.body` / `req.query` with the *parsed* (coerced, defaulted,
 * transformed) values. Validation failures forward to the global error handler
 * which returns a consistent 400 envelope.
 */
export function validate(schema: ZodSchema) {
  return (req: Request, _res: Response, next: NextFunction): void => {
    const result = schema.safeParse({
      body: req.body,
      query: req.query,
      params: req.params,
    });

    if (!result.success) {
      next(result.error);
      return;
    }

    const parsed = result.data;
    if (parsed.body !== undefined) req.body = parsed.body;
    if (parsed.query !== undefined) req.query = parsed.query as typeof req.query;
    if (parsed.params !== undefined) req.params = parsed.params as typeof req.params;

    next();
  };
}