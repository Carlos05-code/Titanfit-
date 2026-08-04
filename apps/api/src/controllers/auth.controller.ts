import { Request, Response } from 'express';
import { authService } from '../services/auth.service';
import { AuthenticatedRequest } from '../types';
import { LoginBody, RefreshBody, RegisterBody } from '../validators';

export class AuthController {
  async register(req: Request, res: Response) {
    const { email, password, name } = req.body as RegisterBody;
    const result = await authService.register(email, password, name);
    res.status(201).json({ success: true, data: result });
  }

  async login(req: Request, res: Response) {
    const { email, password } = req.body as LoginBody;
    const result = await authService.login(email, password);
    res.json({ success: true, data: result });
  }

  async refresh(req: Request, res: Response) {
    const { refreshToken } = req.body as RefreshBody;
    const tokens = await authService.refresh(refreshToken);
    res.json({ success: true, data: tokens });
  }

  async logout(req: AuthenticatedRequest, res: Response) {
    await authService.logout(req.user!.userId);
    res.json({ success: true, message: 'Logged out successfully' });
  }
}

export const authController = new AuthController();