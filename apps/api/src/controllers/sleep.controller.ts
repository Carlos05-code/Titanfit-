import { Response } from 'express';
import { sleepService } from '../services/sleep.service';
import { AuthenticatedRequest } from '../types';
import { RecordSleepBody, SleepHistoryQuery } from '../validators';

export class SleepController {
  async record(req: AuthenticatedRequest, res: Response) {
    const record = await sleepService.record(req.user!.userId, req.body as RecordSleepBody);
    res.status(201).json({ success: true, data: record });
  }

  async getHistory(req: AuthenticatedRequest, res: Response) {
    const { days } = req.query as unknown as SleepHistoryQuery;
    const history = await sleepService.getHistory(req.user!.userId, days);
    res.json({ success: true, data: history });
  }

  async getStats(req: AuthenticatedRequest, res: Response) {
    const stats = await sleepService.getStats(req.user!.userId);
    res.json({ success: true, data: stats });
  }
}

export const sleepController = new SleepController();