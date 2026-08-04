import { Response } from 'express';
import prisma from '../utils/prisma';
import { AppError } from '../utils/AppError';
import { AuthenticatedRequest } from '../types';
import { UpdateProfileBody } from '../validators';

const profileSelect = {
  id: true, email: true, name: true, age: true, gender: true,
  height: true, weight: true, fitnessLevel: true, goals: true,
  xpPoints: true, level: true, disciplineScore: true,
  currentStreak: true, longestStreak: true, createdAt: true,
} as const;

export class UserController {
  async getProfile(req: AuthenticatedRequest, res: Response) {
    const user = await prisma.user.findUnique({
      where: { id: req.user!.userId },
      select: profileSelect,
    });
    if (!user) throw AppError.notFound('User');

    res.json({ success: true, data: user });
  }

  async updateProfile(req: AuthenticatedRequest, res: Response) {
    // `validate(updateProfileSchema)` runs in the route and sets req.body to the
    // parsed, whitelisted fields — no arbitrary column can be mutated.
    const data = req.body as UpdateProfileBody;

    const user = await prisma.user.update({
      where: { id: req.user!.userId },
      data,
      select: profileSelect,
    });

    res.json({ success: true, data: user });
  }
}

export const userController = new UserController();