import { Prisma } from '@prisma/client';
import prisma from '../utils/prisma';
import { calculateDisciplineScore, calculateLevel } from '../utils/helpers';
import { CheckInBody } from '../validators';

const XP_PER_HABIT_POINT = 25;
const XP_PER_LEVEL = 1000;

export class HabitService {
  async getAll(userId: string, date?: string) {
    const queryDate = date ? new Date(date) : new Date();
    const startOfDay = new Date(queryDate);
    startOfDay.setHours(0, 0, 0, 0);
    const endOfDay = new Date(queryDate);
    endOfDay.setHours(23, 59, 59, 999);

    return prisma.habit.findMany({
      where: { userId, date: { gte: startOfDay, lte: endOfDay } },
    });
  }

  async getMonthly(userId: string, year: number, month: number) {
    const start = new Date(year, month - 1, 1);
    const end = new Date(year, month, 0, 23, 59, 59, 999);

    return prisma.habit.findMany({
      where: { userId, date: { gte: start, lte: end } },
      orderBy: { date: 'asc' },
    });
  }

  async checkIn(userId: string, data: CheckInBody) {
    const habitDate = data.date ? new Date(data.date) : new Date();
    const startOfDay = new Date(habitDate);
    startOfDay.setHours(0, 0, 0, 0);

    const existing = await prisma.habit.findUnique({
      where: {
        userId_type_date: { userId, type: data.type, date: startOfDay },
      },
    });

    // If toggling off, no gamification side-effects.
    if (existing) {
      return prisma.habit.update({
        where: { id: existing.id },
        data: { completed: !existing.completed },
      });
    }

    // Create the habit, refresh streaks and award XP as one atomic unit.
    const habit = await prisma.$transaction(async (tx) => {
      const created = await tx.habit.create({
        data: { userId, type: data.type, completed: true, date: startOfDay },
      });

      await this.refreshStreaks(tx, userId);
      await this.awardXp(tx, userId, XP_PER_HABIT_POINT);

      return created;
    });

    return habit;
  }

  async getStreaks(userId: string) {
    const user = await prisma.user.findUnique({
      where: { id: userId },
      select: { currentStreak: true, longestStreak: true, disciplineScore: true },
    });
    return (
      user ?? { currentStreak: 0, longestStreak: 0, disciplineScore: 0 }
    );
  }

  /** Recompute the current-day streak from the completed-habit history. */
  private async refreshStreaks(
    tx: Prisma.TransactionClient,
    userId: string,
  ) {
    const completed = await tx.habit.findMany({
      where: { userId, completed: true },
      orderBy: { date: 'desc' },
      select: { date: true },
      distinct: ['date'],
    });
    if (completed.length === 0) return;

    let streak = 0;
    const today = new Date();
    today.setHours(0, 0, 0, 0);

    for (let i = 0; i < completed.length; i++) {
      const expectedDate = new Date(today);
      expectedDate.setDate(expectedDate.getDate() - i);
      const habitDate = new Date(completed[i].date);
      habitDate.setHours(0, 0, 0, 0);
      if (habitDate.getTime() === expectedDate.getTime()) {
        streak++;
      } else {
        break;
      }
    }

    const user = await tx.user.findUnique({ where: { id: userId } });
    if (!user) return;

    await tx.user.update({
      where: { id: userId },
      data: {
        currentStreak: streak,
        longestStreak: Math.max(user.longestStreak, streak),
        disciplineScore: calculateDisciplineScore(streak, streak, 75),
      },
    });
  }

  private async awardXp(
    tx: Prisma.TransactionClient,
    userId: string,
    points: number,
  ) {
    const user = await tx.user.update({
      where: { id: userId },
      data: { xpPoints: { increment: points } },
    });
    const newLevel = calculateLevel(user.xpPoints, XP_PER_LEVEL);
    if (newLevel > user.level) {
      await tx.user.update({ where: { id: userId }, data: { level: newLevel } });
    }
  }
}

export const habitService = new HabitService();