import { Router } from 'express';
import authRoutes from './auth.routes';
import userRoutes from './user.routes';
import workoutRoutes from './workout.routes';
import habitRoutes from './habit.routes';
import sleepRoutes from './sleep.routes';
import progressRoutes from './progress.routes';

const router = Router();

router.use('/auth', authRoutes);
router.use('/users', userRoutes);
router.use('/workouts', workoutRoutes);
router.use('/habits', habitRoutes);
router.use('/sleep', sleepRoutes);
router.use('/progress', progressRoutes);

export default router;
