import { Response } from 'express';
import { habitService } from '../services/habit.service';
import { AuthenticatedRequest } from '../types';
import { CheckInBody, HabitMonthQuery, HabitQuery } from '../validators';

export class HabitController {
  async getAll(req: AuthenticatedRequest, res: Response) {
    const { date } = req.query as unknown as HabitQuery;
    const habits = await habitService.getAll(req.user!.userId, date);
    res.json({ success: true, data: habits });
  }

  async getMonthly(req: AuthenticatedRequest, res: Response) {
    // `validate(habitMonthQuerySchema)` coerces + defaults these in the route.
    const { year, month } = req.query as unknown as HabitMonthQuery;
    const habits = await habitService.getMonthly(req.user!.userId, year, month);
    res.json({ success: true, data: habits });
  }

  async checkIn(req: AuthenticatedRequest, res: Response) {
    const habit = await habitService.checkIn(req.user!.userId, req.body as CheckInBody);
    res.json({ success: true, data: habit });
  }

  async getStreaks(req: AuthenticatedRequest, res: Response) {
    const streaks = await habitService.getStreaks(req.user!.userId);
    res.json({ success: true, data: streaks });
  }
}

export const habitController = new HabitController();