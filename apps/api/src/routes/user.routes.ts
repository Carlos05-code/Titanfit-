import { Router } from 'express';
import { userController } from '../controllers/user.controller';
import { authenticate } from '../middleware/auth';

const router = Router();

router.get('/profile', authenticate, (req: any, res) => userController.getProfile(req, res));
router.put('/profile', authenticate, (req: any, res) => userController.updateProfile(req, res));

export default router;
