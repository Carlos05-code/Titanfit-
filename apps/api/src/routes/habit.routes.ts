import { Router } from 'express';
import { habitController } from '../controllers/habit.controller';
import { authenticate } from '../middleware/auth';
import { asyncHandler } from '../middleware/asyncHandler';
import { validate } from '../middleware/validate';
import { checkInSchema, habitMonthQuerySchema, habitQuerySchema } from '../validators';

const router = Router();

router.get('/', authenticate, validate(habitQuerySchema), asyncHandler(habitController.getAll));
router.get('/monthly', authenticate, validate(habitMonthQuerySchema), asyncHandler(habitController.getMonthly));
router.get('/streaks', authenticate, asyncHandler(habitController.getStreaks));
router.post('/checkin', authenticate, validate(checkInSchema), asyncHandler(habitController.checkIn));

export default router;