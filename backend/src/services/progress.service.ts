import prisma from '../utils/prisma';

export class ProgressService {
  async getStats(userId: string) {
    const [user, workoutStats, sleepStats, habits, achievements] = await Promise.all([
      prisma.user.findUnique({
        where: { id: userId },
        select: {
          id: true, name: true, email: true, age: true, gender: true,
          height: true, weight: true, fitnessLevel: true, goals: true,
          xpPoints: true, level: true, disciplineScore: true,
          currentStreak: true, longestStreak: true, createdAt: true,
        },
      }),
      this.getWorkoutStats(userId),
      this.getSleepStats(userId),
      this.getHabitStats(userId),
      prisma.userAchievement.findMany({
        where: { userId },
        orderBy: { unlockedAt: 'desc' },
      }),
    ]);

    return { user, ...workoutStats, ...sleepStats, ...habits, achievements };
  }

  private async getWorkoutStats(userId: string) {
    const [total, totalDuration, totalCalories, weekly] = await Promise.all([
      prisma.workout.count({ where: { userId } }),
      prisma.workout.aggregate({ where: { userId }, _sum: { duration: true } }),
      prisma.workout.aggregate({ where: { userId }, _sum: { calories: true } }),
      this.getWeeklyWorkouts(userId),
    ]);

    return {
      totalWorkouts: total,
      totalWorkoutDuration: totalDuration._sum.duration || 0,
      totalCaloriesBurned: totalCalories._sum.calories || 0,
      weeklyWorkouts: weekly,
    };
  }

  private async getWeeklyWorkouts(userId: string) {
    const weekAgo = new Date();
    weekAgo.setDate(weekAgo.getDate() - 7);
    weekAgo.setHours(0, 0, 0, 0);

    const workouts = await prisma.workout.findMany({
      where: { userId, date: { gte: weekAgo } },
      orderBy: { date: 'asc' },
      select: { date: true, duration: true, calories: true },
    });

    return workouts;
  }

  private async getSleepStats(userId: string) {
    const sleepData = await prisma.sleepRecord.aggregate({
      where: { userId },
      _avg: { score: true, duration: true },
      _count: true,
    });

    return {
      avgSleepScore: Math.round(sleepData._avg.score || 0),
      avgSleepDuration: Math.round((sleepData._avg.duration || 0) * 10) / 10,
      totalSleepRecords: sleepData._count,
    };
  }

  private async getHabitStats(userId: string) {
    const today = new Date();
    today.setHours(0, 0, 0, 0);
    const weekAgo = new Date(today);
    weekAgo.setDate(weekAgo.getDate() - 7);

    const [totalHabits, weeklyHabits] = await Promise.all([
      prisma.habit.count({ where: { userId, completed: true } }),
      prisma.habit.count({
        where: { userId, completed: true, date: { gte: weekAgo } },
      }),
    ]);

    return { totalHabitsCompleted: totalHabits, weeklyHabitsCompleted: weeklyHabits };
  }

  async getWeightHistory(userId: string) {
    const user = await prisma.user.findUnique({
      where: { id: userId },
      select: { weight: true, height: true, createdAt: true, updatedAt: true },
    });
    return user;
  }
}

export const progressService = new ProgressService();
