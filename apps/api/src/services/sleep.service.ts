import prisma from '../utils/prisma';
import { AppError } from '../utils/AppError';
import { calculateLevel, calculateSleepScore } from '../utils/helpers';
import { RecordSleepBody } from '../validators';

const SLEEP_XP = 30;
const XP_PER_LEVEL = 1000;

export class SleepService {
  async record(userId: string, data: RecordSleepBody) {
    const sleep = new Date(data.sleepTime);
    const wake = new Date(data.wakeTime);

    if (Number.isNaN(sleep.getTime()) || Number.isNaN(wake.getTime())) {
      throw AppError.badRequest('sleepTime and wakeTime must be valid ISO-8601 dates');
    }

    const durationHours = Math.round(
      (wake.getTime() - sleep.getTime()) / (1000 * 60 * 60) * 10,
    ) / 10;

    if (durationHours <= 0) {
      throw AppError.badRequest('Wake time must be after sleep time');
    }

    const score = calculateSleepScore(durationHours);

    // Persist the record and award XP atomically.
    const record = await prisma.$transaction(async (tx) => {
      const created = await tx.sleepRecord.create({
        data: { userId, sleepTime: sleep, wakeTime: wake, duration: durationHours, score },
      });

      const user = await tx.user.update({
        where: { id: userId },
        data: { xpPoints: { increment: SLEEP_XP } },
      });
      const newLevel = calculateLevel(user.xpPoints, XP_PER_LEVEL);
      if (newLevel > user.level) {
        await tx.user.update({ where: { id: userId }, data: { level: newLevel } });
      }

      return created;
    });

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
    const [totalRecords, avgScore, avgDuration, recent] = await Promise.all([
      prisma.sleepRecord.count({ where: { userId } }),
      prisma.sleepRecord.aggregate({ where: { userId }, _avg: { score: true } }),
      prisma.sleepRecord.aggregate({ where: { userId }, _avg: { duration: true } }),
      prisma.sleepRecord.findMany({
        where: { userId },
        orderBy: { sleepTime: 'desc' },
        take: 7,
      }),
    ]);

    return {
      totalRecords,
      avgScore: Math.round(avgScore._avg.score || 0),
      avgDuration: Math.round((avgDuration._avg.duration || 0) * 10) / 10,
      recent,
    };
  }
}

export const sleepService = new SleepService();