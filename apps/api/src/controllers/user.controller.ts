import { Response } from 'express';
import { z } from 'zod';
import prisma from '../utils/prisma';
import { AuthenticatedRequest } from '../types';

const updateProfileSchema = z.object({
  body: z.object({
    name: z.string().min(2).max(50).optional(),
    age: z.number().int().min(13).max(120).optional(),
    gender: z.enum(['male', 'female', 'other']).optional(),
    height: z.number().positive().optional(),
    weight: z.number().positive().optional(),
    fitnessLevel: z.enum(['BEGINNER', 'INTERMEDIATE', 'ADVANCED', 'ATHLETE']).optional(),
    goals: z.array(z.enum(['MUSCLE_GAIN', 'FAT_LOSS', 'ENDURANCE', 'STRENGTH', 'GENERAL_FITNESS'])).optional(),
  }),
});

export class UserController {
  async getProfile(req: AuthenticatedRequest, res: Response) {
    try {
      const user = await prisma.user.findUnique({
        where: { id: req.user!.userId },
        select: {
          id: true, email: true, name: true, age: true, gender: true,
          height: true, weight: true, fitnessLevel: true, goals: true,
          xpPoints: true, level: true, disciplineScore: true,
          currentStreak: true, longestStreak: true, createdAt: true,
        },
      });
      if (!user) {
        res.status(404).json({ success: false, error: 'User not found' });
        return;
      }
      res.json({ success: true, data: user });
    } catch (error: any) {
      res.status(500).json({ success: false, error: error.message });
    }
  }

  async updateProfile(req: AuthenticatedRequest, res: Response) {
    try {
      const data = updateProfileSchema.parse(req).body;
      const user = await prisma.user.update({
        where: { id: req.user!.userId },
        data,
        select: {
          id: true, email: true, name: true, age: true, gender: true,
          height: true, weight: true, fitnessLevel: true, goals: true,
          xpPoints: true, level: true, disciplineScore: true,
          currentStreak: true, longestStreak: true, createdAt: true,
        },
      });
      res.json({ success: true, data: user });
    } catch (error: any) {
      if (error instanceof z.ZodError) {
        res.status(400).json({ success: false, error: 'Validation failed', details: error.errors });
        return;
      }
      res.status(500).json({ success: false, error: error.message });
    }
  }
}

export const userController = new UserController();
