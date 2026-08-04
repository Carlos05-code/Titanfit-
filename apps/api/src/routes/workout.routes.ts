import { Router } from 'express';
import { workoutController } from '../controllers/workout.controller';
import { authenticate } from '../middleware/auth';
import { asyncHandler } from '../middleware/asyncHandler';
import { validate } from '../middleware/validate';
import {
  createWorkoutSchema,
  paginationQuerySchema,
  updateWorkoutSchema,
  workoutIdParamsSchema,
} from '../validators';

const router = Router();

router.get('/stats', authenticate, asyncHandler(workoutController.getStats));
router.get('/', authenticate, validate(paginationQuerySchema), asyncHandler(workoutController.getAll));
router.get('/:id', authenticate, validate(workoutIdParamsSchema), asyncHandler(workoutController.getById));
router.post('/', authenticate, validate(createWorkoutSchema), asyncHandler(workoutController.create));
router.patch('/:id', authenticate, validate(workoutIdParamsSchema), validate(updateWorkoutSchema), asyncHandler(workoutController.update));
router.delete('/:id', authenticate, validate(workoutIdParamsSchema), asyncHandler(workoutController.delete));

export default router;