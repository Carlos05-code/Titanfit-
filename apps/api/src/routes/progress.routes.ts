import { Router } from 'express';
import { progressController } from '../controllers/progress.controller';
import { authenticate } from '../middleware/auth';
import { asyncHandler } from '../middleware/asyncHandler';

const router = Router();

router.get('/stats', authenticate, asyncHandler(progressController.getStats));
router.get('/weight', authenticate, asyncHandler(progressController.getWeightHistory));

export default router;