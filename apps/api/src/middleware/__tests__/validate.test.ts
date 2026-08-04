import { Request, Response, NextFunction } from 'express';
import { z } from 'zod';
import { validate } from '../validate';

function mockReq(body: unknown, query: unknown, params: unknown) {
  return { body, query, params } as unknown as Request;
}

describe('validate middleware', () => {
  const schema = z.object({
    body: z.object({ name: z.string().min(2) }),
    query: z.object({ page: z.coerce.number().default(1) }),
    params: z.object({ id: z.string().uuid() }),
  });

  it('replaces req.body/query/params with parsed values', () => {
    const req = mockReq(
      { name: 'Titan' },
      {},
      { id: 'f47ac10b-58cc-4372-a567-0e02b2c3d479' },
    );
    const next: NextFunction = jest.fn();

    const mw = validate(schema);
    mw(req, {} as Response, next);

    expect(next).toHaveBeenCalledWith();
    expect(req.body).toEqual({ name: 'Titan' });
    expect(req.query).toEqual({ page: 1 });
  });

  it('forwards ZodError on invalid input', () => {
    const req = mockReq({ name: 'x' }, {}, { id: 'nope' });
    const next: NextFunction = jest.fn();

    validate(schema)(req, {} as Response, next);

    expect(next).toHaveBeenCalled();
    expect(next).toHaveBeenCalledWith(expect.any(z.ZodError));
  });
});