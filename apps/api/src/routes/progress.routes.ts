import { Router } from 'express';
import { progressController } from '../controllers/progress.controller';
import { authenticate } from '../middleware/auth';

const router = Router();

router.get('/stats', authenticate, (req: any, res) => progressController.getStats(req, res));
router.get('/weight', authenticate, (req: any, res) => progressController.getWeightHistory(req, res));

export default router;
