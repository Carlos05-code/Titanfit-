import prisma from '../utils/prisma';
import { calculateSleepScore } from '../utils/helpers';

export class SleepService {
  async record(userId: string, sleepTime: string, wakeTime: string) {
    const sleep = new Date(sleepTime);
    const wake = new Date(wakeTime);
    const durationMs = wake.getTime() - sleep.getTime();
    const durationHours = Math.round(durationMs / (1000 * 60 * 60) * 10) / 10;

    if (durationHours <= 0) throw new Error('Wake time must be after sleep time');

    const score = calculateSleepScore(durationHours);

    const record = await prisma.sleepRecord.create({
      data: { userId, sleepTime: sleep, wakeTime: wake, duration: durationHours, score },
    });

    await this.awardXp(userId, 30);
    return { ...record, score };
  }

  async getHistory(userId: string, days = 7) {
    const startDate = new Date();
    startDate.setDate(startDate.getDate() - days);
    startDate.setHours(0, 0, 0, 0);

    const records = await prisma.sleepRecord.findMany({
      where: { userId, sleepTime: { gte: startDate } },
      orderBy: { sleepTime: 'desc' },
    });

    const avgScore = records.length > 0
      ? Math.round(records.reduce((sum, r) => sum + (r.score || 0), 0) / records.length)
      : 0;

    const avgDuration = records.length > 0
      ? Math.round(records.reduce((sum, r) => sum + r.duration, 0) / records.length * 10) / 10
      : 0;

    return { records, avgScore, avgDuration, totalRecords: records.length };
  }

  async getStats(userId: string) {
    const [totalRecords, avgScore, avgDuration] = await Promise.all([
      prisma.sleepRecord.count({ where: { userId } }),
      prisma.sleepRecord.aggregate({ where: { userId }, _avg: { score: true } }),
      prisma.sleepRecord.aggregate({ where: { userId }, _avg: { duration: true } }),
    ]);

    const recent = await prisma.sleepRecord.findMany({
      where: { userId },
      orderBy: { sleepTime: 'desc' },
      take: 7,
    });

    return {
      totalRecords,
      avgScore: Math.round(avgScore._avg.score || 0),
      avgDuration: Math.round((avgDuration._avg.duration || 0) * 10) / 10,
      recent,
    };
  }

  private async awardXp(userId: string, points: number) {
    await prisma.user.update({
      where: { id: userId },
      data: { xpPoints: { increment: points } },
    });
  }
}

export const sleepService = new SleepService();
