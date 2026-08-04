import { Router } from 'express';
import { habitController } from '../controllers/habit.controller';
import { authenticate } from '../middleware/auth';

const router = Router();

router.get('/', authenticate, (req: any, res) => habitController.getAll(req, res));
router.get('/monthly', authenticate, (req: any, res) => habitController.getMonthly(req, res));
router.get('/streaks', authenticate, (req: any, res) => habitController.getStreaks(req, res));
router.post('/checkin', authenticate, (req: any, res) => habitController.checkIn(req, res));

export default router;
