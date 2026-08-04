/**
 * Domain-level application error carrying an HTTP status.
 *
 * Controllers/services throw `AppError` for expected, user-facing failures
 * (e.g. "not found", "conflict", "validation"). The centralized error handler
 * maps it to a consistent JSON envelope — never leaking internal messages.
 */
export class AppError extends Error {
  public readonly status: number;
  public readonly code: string;

  constructor(status: number, code: string, message: string) {
    super(message);
    this.name = 'AppError';
    this.status = status;
    this.code = code;
  }

  static notFound(resource: string, id?: string): AppError {
    return new AppError(404, 'NOT_FOUND', id
      ? `${resource} not found (id: ${id})`
      : `${resource} not found`);
  }

  static conflict(message: string): AppError {
    return new AppError(409, 'CONFLICT', message);
  }

  static unauthorized(message = 'Unauthorized'): AppError {
    return new AppError(401, 'UNAUTHORIZED', message);
  }

  static forbidden(message = 'Forbidden'): AppError {
    return new AppError(403, 'FORBIDDEN', message);
  }

  static badRequest(message: string): AppError {
    return new AppError(400, 'BAD_REQUEST', message);
  }
}