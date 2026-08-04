import { Response } from 'express';
import { workoutService } from '../services/workout.service';
import { AuthenticatedRequest } from '../types';
import {
  CreateWorkoutBody,
  PaginationQuery,
  UpdateWorkoutBody,
} from '../validators';

export class WorkoutController {
  async getAll(req: AuthenticatedRequest, res: Response) {
    // `validate(paginationQuerySchema)` coerces + defaults these in the route.
    const { page, limit } = req.query as unknown as PaginationQuery;
    const result = await workoutService.getAll(req.user!.userId, page, limit);
    res.json({ success: true, data: result });
  }

  async getById(req: AuthenticatedRequest, res: Response) {
    // `validate(workoutIdParamsSchema)` guarantees a UUID here.
    const id = String(req.params.id);
    const workout = await workoutService.getById(id, req.user!.userId);
    res.json({ success: true, data: workout });
  }

  async create(req: AuthenticatedRequest, res: Response) {
    const workout = await workoutService.create(req.user!.userId, req.body as CreateWorkoutBody);
    res.status(201).json({ success: true, data: workout });
  }

  async update(req: AuthenticatedRequest, res: Response) {
    const id = String(req.params.id);
    const workout = await workoutService.update(id, req.user!.userId, req.body as UpdateWorkoutBody);
    res.json({ success: true, data: workout });
  }

  async delete(req: AuthenticatedRequest, res: Response) {
    const id = String(req.params.id);
    await workoutService.delete(id, req.user!.userId);
    res.json({ success: true, message: 'Workout deleted' });
  }

  async getStats(req: AuthenticatedRequest, res: Response) {
    const stats = await workoutService.getStats(req.user!.userId);
    res.json({ success: true, data: stats });
  }
}

export const workoutController = new WorkoutController();