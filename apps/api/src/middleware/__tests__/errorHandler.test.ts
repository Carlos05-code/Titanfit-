import { Response, Request, NextFunction } from 'express';
import { ZodError } from 'zod';
import { errorHandler } from '../errorHandler';
import { AppError } from '../../utils/AppError';

// Keep the errorHandler test hermetic: no real Prisma client fixtures.
jest.mock('@prisma/client', () => {
  class PrismaClientKnownRequestError extends Error {
    code: string;
    clientVersion: string;
    constructor(message: string, meta: { code: string; clientVersion: string }) {
      super(message);
      this.code = meta.code;
      this.clientVersion = meta.clientVersion;
    }
  }
  return { PrismaClientKnownRequestError, Prisma: { PrismaClientKnownRequestError } };
});

function mockRes() {
  const res = {
    status: jest.fn().mockReturnThis(),
    json: jest.fn().mockReturnThis(),
  } as unknown as Response;
  return res;
}

const req = {} as Request;
const next: NextFunction = jest.fn();

describe('errorHandler', () => {
  it('maps AppError to its status + envelope', () => {
    const res = mockRes();
    errorHandler(AppError.unauthorized('Invalid credentials'), req, res, next);
    expect(res.status).toHaveBeenCalledWith(401);
    expect(res.json).toHaveBeenCalledWith({
      success: false,
      error: 'Invalid credentials',
      code: 'UNAUTHORIZED',
    });
  });

  it('maps ZodError to a 400 validation envelope', () => {
    const res = mockRes();
    const zod = new ZodError([{ code: 'custom', message: 'bad', path: ['body', 'email'] }]);
    errorHandler(zod, req, res, next);
    expect(res.status).toHaveBeenCalledWith(400);
    expect(res.json).toHaveBeenCalledWith(
      expect.objectContaining({
        code: 'VALIDATION_ERROR',
        details: [{ field: 'body.email', message: 'bad' }],
      }),
    );
  });

  it('maps Prisma P2002 → 409 and P2025 → 404', () => {
    const { PrismaClientKnownRequestError } = jest.requireMock('@prisma/client') as {
      PrismaClientKnownRequestError: new (
        m: string,
        meta: { code: string; clientVersion: string },
      ) => Error & { code: string };
    };

    const conflict = mockRes();
    errorHandler(
      new PrismaClientKnownRequestError('dup', { code: 'P2002', clientVersion: 'x' }),
      req,
      conflict,
      next,
    );
    expect(conflict.status).toHaveBeenCalledWith(409);

    const missing = mockRes();
    errorHandler(
      new PrismaClientKnownRequestError('gone', { code: 'P2025', clientVersion: 'x' }),
      req,
      missing,
      next,
    );
    expect(missing.status).toHaveBeenCalledWith(404);
  });

  it('leaks nothing in production for unexpected errors', () => {
    const prevEnv = process.env.NODE_ENV;
    process.env.NODE_ENV = 'production';
    try {
      const res = mockRes();
      errorHandler(new Error('secret stack detail'), req, res, next);
      expect(res.status).toHaveBeenCalledWith(500);
      expect(res.json).toHaveBeenCalledWith({
        success: false,
        error: 'Internal server error',
        code: 'INTERNAL_ERROR',
      });
    } finally {
      process.env.NODE_ENV = prevEnv;
    }
  });

  it('surfaces the real message in development', () => {
    const prevEnv = process.env.NODE_ENV;
    process.env.NODE_ENV = 'development';
    try {
      const res = mockRes();
      errorHandler(new Error('local debug info'), req, res, next);
      expect(res.json).toHaveBeenCalledWith(
        expect.objectContaining({ error: 'local debug info' }),
      );
    } finally {
      process.env.NODE_ENV = prevEnv;
    }
  });
});