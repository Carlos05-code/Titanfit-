import prisma from '../utils/prisma';
import { calculateDisciplineScore } from '../utils/helpers';

export class HabitService {
  async getAll(userId: string, date?: string) {
    const queryDate = date ? new Date(date) : new Date();
    const startOfDay = new Date(queryDate);
    startOfDay.setHours(0, 0, 0, 0);
    const endOfDay = new Date(queryDate);
    endOfDay.setHours(23, 59, 59, 999);

    const habits = await prisma.habit.findMany({
      where: {
        userId,
        date: { gte: startOfDay, lte: endOfDay },
      },
    });
    return habits;
  }

  async getMonthly(userId: string, year: number, month: number) {
    const start = new Date(year, month - 1, 1);
    const end = new Date(year, month, 0, 23, 59, 59, 999);

    const habits = await prisma.habit.findMany({
      where: { userId, date: { gte: start, lte: end } },
      orderBy: { date: 'asc' },
    });
    return habits;
  }

  async checkIn(userId: string, type: string, date?: string) {
    const habitDate = date ? new Date(date) : new Date();
    const startOfDay = new Date(habitDate);
    startOfDay.setHours(0, 0, 0, 0);

    const existing = await prisma.habit.findUnique({
      where: {
        userId_type_date: {
          userId,
          type: type as any,
          date: startOfDay,
        },
      },
    });

    if (existing) {
      return prisma.habit.update({
        where: { id: existing.id },
        data: { completed: !existing.completed },
      });
    }

    const habit = await prisma.habit.create({
      data: {
        userId,
        type: type as any,
        completed: true,
        date: startOfDay,
      },
    });

    await this.updateStreaks(userId);
    await this.awardXp(userId, 25);
    return habit;
  }

  async getStreaks(userId: string) {
    const user = await prisma.user.findUnique({
      where: { id: userId },
      select: { currentStreak: true, longestStreak: true, disciplineScore: true },
    });
    return user;
  }

  private async updateStreaks(userId: string) {
    const habits = await prisma.habit.findMany({
      where: { userId, completed: true },
      orderBy: { date: 'desc' },
    });

    if (habits.length === 0) return;

    let streak = 0;
    const today = new Date();
    today.setHours(0, 0, 0, 0);

    for (let i = 0; i < habits.length; i++) {
      const expectedDate = new Date(today);
      expectedDate.setDate(expectedDate.getDate() - i);
      const habitDate = new Date(habits[i].date);
      habitDate.setHours(0, 0, 0, 0);

      if (habitDate.getTime() === expectedDate.getTime()) {
        streak++;
      } else {
        break;
      }
    }

    const user = await prisma.user.findUnique({ where: { id: userId } });
    if (!user) return;

    const newLongestStreak = Math.max(user.longestStreak, streak);
    const disciplineScore = calculateDisciplineScore(streak, streak, 75);

    await prisma.user.update({
      where: { id: userId },
      data: {
        currentStreak: streak,
        longestStreak: newLongestStreak,
        disciplineScore,
      },
    });
  }

  private async awardXp(userId: string, points: number) {
    const user = await prisma.user.update({
      where: { id: userId },
      data: { xpPoints: { increment: points } },
    });
    const newLevel = Math.floor(user.xpPoints / 1000) + 1;
    if (newLevel > user.level) {
      await prisma.user.update({
        where: { id: userId },
        data: { level: newLevel },
      });
    }
  }
}

export const habitService = new HabitService();
