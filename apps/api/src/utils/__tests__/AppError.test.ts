import { AppError } from '../AppError';

describe('AppError', () => {
  it('stores status, code and message', () => {
    const err = new AppError(400, 'BAD_REQUEST', 'nope');
    expect(err).toBeInstanceOf(AppError);
    expect(err).toBeInstanceOf(Error);
    expect(err.status).toBe(400);
    expect(err.code).toBe('BAD_REQUEST');
    expect(err.message).toBe('nope');
  });

  it('exposes typed factories', () => {
    expect(AppError.badRequest('x').status).toBe(400);
    expect(AppError.unauthorized('x').status).toBe(401);
    expect(AppError.forbidden('x').status).toBe(403);
    expect(AppError.notFound('User').status).toBe(404);
    expect(AppError.notFound('User').message).toBe('User not found');
    expect(AppError.conflict('x').status).toBe(409);
  });
});