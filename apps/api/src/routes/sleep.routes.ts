import { Router } from 'express';
import { sleepController } from '../controllers/sleep.controller';
import { authenticate } from '../middleware/auth';

const router = Router();

router.post('/', authenticate, (req: any, res) => sleepController.record(req, res));
router.get('/history', authenticate, (req: any, res) => sleepController.getHistory(req, res));
router.get('/stats', authenticate, (req: any, res) => sleepController.getStats(req, res));

export default router;
