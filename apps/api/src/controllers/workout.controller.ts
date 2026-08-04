import { Response } from 'express';
import { z } from 'zod';
import { workoutService } from '../services/workout.service';
import { AuthenticatedRequest } from '../types';

const createWorkoutSchema = z.object({
  body: z.object({
    title: z.string().min(1),
    goal: z.enum(['MUSCLE_GAIN', 'FAT_LOSS', 'ENDURANCE', 'STRENGTH', 'GENERAL_FITNESS']).optional(),
    date: z.string().optional(),
    duration: z.number().int().positive().optional(),
    calories: z.number().int().positive().optional(),
    notes: z.string().optional(),
    exercises: z.array(z.object({
      name: z.string().min(1),
      sets: z.number().int().positive().optional(),
      reps: z.number().int().positive().optional(),
      weight: z.number().positive().optional(),
      duration: z.number().int().positive().optional(),
      calories: z.number().int().positive().optional(),
      order: z.number().int().optional(),
    })).optional(),
  }),
});

export class WorkoutController {
  async getAll(req: AuthenticatedRequest, res: Response) {
    try {
      const page = parseInt(req.query.page as string) || 1;
      const limit = parseInt(req.query.limit as string) || 20;
      const result = await workoutService.getAll(req.user!.userId, page, limit);
      res.json({ success: true, data: result });
    } catch (error: any) {
      res.status(500).json({ success: false, error: error.message });
    }
  }

  async getById(req: AuthenticatedRequest, res: Response) {
    try {
      const workout = await workoutService.getById(req.params.id as string, req.user!.userId);
      res.json({ success: true, data: workout });
    } catch (error: any) {
      res.status(404).json({ success: false, error: error.message });
    }
  }

  async create(req: AuthenticatedRequest, res: Response) {
    try {
      const data = createWorkoutSchema.parse(req).body;
      const workout = await workoutService.create(req.user!.userId, data);
      res.status(201).json({ success: true, data: workout });
    } catch (error: any) {
      if (error instanceof z.ZodError) {
        res.status(400).json({ success: false, error: 'Validation failed', details: error.errors });
        return;
      }
      res.status(500).json({ success: false, error: error.message });
    }
  }

  async update(req: AuthenticatedRequest, res: Response) {
    try {
      const workout = await workoutService.update(req.params.id as string, req.user!.userId, req.body);
      res.json({ success: true, data: workout });
    } catch (error: any) {
      res.status(404).json({ success: false, error: error.message });
    }
  }

  async delete(req: AuthenticatedRequest, res: Response) {
    try {
      await workoutService.delete(req.params.id as string, req.user!.userId);
      res.json({ success: true, message: 'Workout deleted' });
    } catch (error: any) {
      res.status(404).json({ success: false, error: error.message });
    }
  }

  async getStats(req: AuthenticatedRequest, res: Response) {
    try {
      const stats = await workoutService.getStats(req.user!.userId);
      res.json({ success: true, data: stats });
    } catch (error: any) {
      res.status(500).json({ success: false, error: error.message });
    }
  }
}

export const workoutController = new WorkoutController();
