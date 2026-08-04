import bcrypt from 'bcryptjs';
import jwt from 'jsonwebtoken';
import { Prisma } from '@prisma/client';
import prisma from '../utils/prisma';
import { config } from '../config';
import { AppError } from '../utils/AppError';
import { AuthPayload } from '../types';

const BCRYPT_ROUNDS = 12;

export class AuthService {
  async register(email: string, password: string, name: string) {
    const normalizedEmail = email.toLowerCase();

    const existing = await prisma.user.findUnique({ where: { email: normalizedEmail } });
    if (existing) throw AppError.conflict('Email already registered');

    const hashedPassword = await bcrypt.hash(password, BCRYPT_ROUNDS);

    let user;
    try {
      user = await prisma.user.create({
        data: { email: normalizedEmail, password: hashedPassword, name },
        select: { id: true, email: true, name: true, createdAt: true },
      });
    } catch (error) {
      // Race on the unique email constraint (TOCTOU window handled here).
      if (error instanceof Prisma.PrismaClientKnownRequestError && error.code === 'P2002') {
        throw AppError.conflict('Email already registered');
      }
      throw error;
    }

    const tokens = this.generateTokens({ userId: user.id, email: user.email });
    await this.storeRefreshToken(user.id, tokens.refreshToken);

    return { user, ...tokens };
  }

  async login(email: string, password: string) {
    const user = await prisma.user.findUnique({ where: { email: email.toLowerCase() } });
    if (!user) throw AppError.unauthorized('Invalid credentials');

    const valid = await bcrypt.compare(password, user.password);
    if (!valid) throw AppError.unauthorized('Invalid credentials');

    const tokens = this.generateTokens({ userId: user.id, email: user.email });
    await this.storeRefreshToken(user.id, tokens.refreshToken);

    const { password: _pw, refreshToken: _rt, ...safeUser } = user;
    return { user: safeUser, ...tokens };
  }

  async refresh(refreshToken: string) {
    let decoded: AuthPayload;
    try {
      decoded = jwt.verify(refreshToken, config.jwt.refreshSecret) as AuthPayload;
    } catch {
      throw AppError.unauthorized('Invalid or expired refresh token');
    }

    const user = await prisma.user.findUnique({ where: { id: decoded.userId } });
    // Reject tokens that were rotated or revoked on logout.
    if (!user || user.refreshToken !== refreshToken) {
      throw AppError.unauthorized('Invalid refresh token');
    }

    const tokens = this.generateTokens({ userId: user.id, email: user.email });
    await this.storeRefreshToken(user.id, tokens.refreshToken);

    return tokens;
  }

  async logout(userId: string) {
    await prisma.user.update({
      where: { id: userId },
      data: { refreshToken: null },
    });
  }

  private async storeRefreshToken(userId: string, refreshToken: string) {
    await prisma.user.update({
      where: { id: userId },
      data: { refreshToken },
    });
  }

  private generateTokens(payload: AuthPayload) {
    const signOptions: jwt.SignOptions = {
      expiresIn: config.jwt.expiresIn as jwt.SignOptions['expiresIn'],
    };
    const refreshSignOptions: jwt.SignOptions = {
      expiresIn: config.jwt.refreshExpiresIn as jwt.SignOptions['expiresIn'],
    };
    const accessToken = jwt.sign(payload, config.jwt.secret, signOptions);
    const refreshToken = jwt.sign(payload, config.jwt.refreshSecret, refreshSignOptions);
    return { accessToken, refreshToken };
  }
}

export const authService = new AuthService();