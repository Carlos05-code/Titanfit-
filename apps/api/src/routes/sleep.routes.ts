import { Router } from 'express';
import { sleepController } from '../controllers/sleep.controller';
import { authenticate } from '../middleware/auth';
import { asyncHandler } from '../middleware/asyncHandler';
import { validate } from '../middleware/validate';
import { recordSleepSchema, sleepHistoryQuerySchema } from '../validators';

const router = Router();

router.post('/', authenticate, validate(recordSleepSchema), asyncHandler(sleepController.record));
router.get('/history', authenticate, validate(sleepHistoryQuerySchema), asyncHandler(sleepController.getHistory));
router.get('/stats', authenticate, asyncHandler(sleepController.getStats));

export default router;