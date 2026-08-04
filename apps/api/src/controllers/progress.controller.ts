import { Response } from 'express';
import { progressService } from '../services/progress.service';
import { AuthenticatedRequest } from '../types';

export class ProgressController {
  async getStats(req: AuthenticatedRequest, res: Response) {
    try {
      const stats = await progressService.getStats(req.user!.userId);
      res.json({ success: true, data: stats });
    } catch (error: any) {
      res.status(500).json({ success: false, error: error.message });
    }
  }

  async getWeightHistory(req: AuthenticatedRequest, res: Response) {
    try {
      const data = await progressService.getWeightHistory(req.user!.userId);
      res.json({ success: true, data });
    } catch (error: any) {
      res.status(500).json({ success: false, error: error.message });
    }
  }
}

export const progressController = new ProgressController();
