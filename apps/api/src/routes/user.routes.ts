import { Router } from 'express';
import { userController } from '../controllers/user.controller';
import { authenticate } from '../middleware/auth';
import { asyncHandler } from '../middleware/asyncHandler';
import { validate } from '../middleware/validate';
import { updateProfileSchema } from '../validators';

const router = Router();

router.get('/profile', authenticate, asyncHandler(userController.getProfile));
router.patch('/profile', authenticate, validate(updateProfileSchema), asyncHandler(userController.updateProfile));

export default router;