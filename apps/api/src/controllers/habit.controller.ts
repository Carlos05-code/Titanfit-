import { Response } from 'express';
import { habitService } from '../services/habit.service';
import { AuthenticatedRequest } from '../types';

export class HabitController {
  async getAll(req: AuthenticatedRequest, res: Response) {
    try {
      const habits = await habitService.getAll(req.user!.userId, req.query.date as string);
      res.json({ success: true, data: habits });
    } catch (error: any) {
      res.status(500).json({ success: false, error: error.message });
    }
  }

  async getMonthly(req: AuthenticatedRequest, res: Response) {
    try {
      const year = parseInt(req.query.year as string) || new Date().getFullYear();
      const month = parseInt(req.query.month as string) || new Date().getMonth() + 1;
      const habits = await habitService.getMonthly(req.user!.userId, year, month);
      res.json({ success: true, data: habits });
    } catch (error: any) {
      res.status(500).json({ success: false, error: error.message });
    }
  }

  async checkIn(req: AuthenticatedRequest, res: Response) {
    try {
      const { type, date } = req.body;
      if (!type) {
        res.status(400).json({ success: false, error: 'Habit type is required' });
        return;
      }
      const habit = await habitService.checkIn(req.user!.userId, type, date);
      res.json({ success: true, data: habit });
    } catch (error: any) {
      res.status(500).json({ success: false, error: error.message });
    }
  }

  async getStreaks(req: AuthenticatedRequest, res: Response) {
    try {
      const streaks = await habitService.getStreaks(req.user!.userId);
      res.json({ success: true, data: streaks });
    } catch (error: any) {
      res.status(500).json({ success: false, error: error.message });
    }
  }
}

export const habitController = new HabitController();
