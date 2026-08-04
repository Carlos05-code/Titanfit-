import { Response } from 'express';
import { sleepService } from '../services/sleep.service';
import { AuthenticatedRequest } from '../types';

export class SleepController {
  async record(req: AuthenticatedRequest, res: Response) {
    try {
      const { sleepTime, wakeTime } = req.body;
      if (!sleepTime || !wakeTime) {
        res.status(400).json({ success: false, error: 'sleepTime and wakeTime are required' });
        return;
      }
      const record = await sleepService.record(req.user!.userId, sleepTime, wakeTime);
      res.status(201).json({ success: true, data: record });
    } catch (error: any) {
      res.status(400).json({ success: false, error: error.message });
    }
  }

  async getHistory(req: AuthenticatedRequest, res: Response) {
    try {
      const days = parseInt(req.query.days as string) || 7;
      const history = await sleepService.getHistory(req.user!.userId, days);
      res.json({ success: true, data: history });
    } catch (error: any) {
      res.status(500).json({ success: false, error: error.message });
    }
  }

  async getStats(req: AuthenticatedRequest, res: Response) {
    try {
      const stats = await sleepService.getStats(req.user!.userId);
      res.json({ success: true, data: stats });
    } catch (error: any) {
      res.status(500).json({ success: false, error: error.message });
    }
  }
}

export const sleepController = new SleepController();
