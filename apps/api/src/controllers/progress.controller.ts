import { Response } from 'express';
import { progressService } from '../services/progress.service';
import { AuthenticatedRequest } from '../types';

export class ProgressController {
  async getStats(req: AuthenticatedRequest, res: Response) {
    const stats = await progressService.getStats(req.user!.userId);
    res.json({ success: true, data: stats });
  }

  async getWeightHistory(req: AuthenticatedRequest, res: Response) {
    const data = await progressService.getWeightHistory(req.user!.userId);
    res.json({ success: true, data });
  }
}

export const progressController = new ProgressController();