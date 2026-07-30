import { Router } from 'express';
import { workoutController } from '../controllers/workout.controller';
import { authenticate } from '../middleware/auth';

const router = Router();

router.get('/stats', authenticate, (req: any, res) => workoutController.getStats(req, res));
router.get('/', authenticate, (req: any, res) => workoutController.getAll(req, res));
router.get('/:id', authenticate, (req: any, res) => workoutController.getById(req, res));
router.post('/', authenticate, (req: any, res) => workoutController.create(req, res));
router.put('/:id', authenticate, (req: any, res) => workoutController.update(req, res));
router.delete('/:id', authenticate, (req: any, res) => workoutController.delete(req, res));

export default router;
