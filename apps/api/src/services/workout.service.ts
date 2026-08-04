import prisma from '../utils/prisma';

export class WorkoutService {
  async getAll(userId: string, page = 1, limit = 20) {
    const skip = (page - 1) * limit;
    const [workouts, total] = await Promise.all([
      prisma.workout.findMany({
        where: { userId },
        include: { exercises: { orderBy: { order: 'asc' } } },
        orderBy: { date: 'desc' },
        skip,
        take: limit,
      }),
      prisma.workout.count({ where: { userId } }),
    ]);
    return { workouts, total, page, totalPages: Math.ceil(total / limit) };
  }

  async getById(id: string, userId: string) {
    const workout = await prisma.workout.findFirst({
      where: { id, userId },
      include: { exercises: { orderBy: { order: 'asc' } } },
    });
    if (!workout) throw new Error('Workout not found');
    return workout;
  }

  async create(userId: string, data: {
    title: string;
    goal?: string;
    date?: string;
    duration?: number;
    calories?: number;
    notes?: string;
    exercises?: Array<{
      name: string;
      sets?: number;
      reps?: number;
      weight?: number;
      duration?: number;
      calories?: number;
      order?: number;
    }>;
  }) {
    const workout = await prisma.workout.create({
      data: {
        userId,
        title: data.title,
        goal: data.goal as any,
        date: data.date ? new Date(data.date) : new Date(),
        duration: data.duration,
        calories: data.calories,
        notes: data.notes,
        exercises: data.exercises ? {
          create: data.exercises.map((e, i) => ({
            name: e.name,
            sets: e.sets,
            reps: e.reps,
            weight: e.weight,
            duration: e.duration,
            calories: e.calories,
            order: e.order ?? i + 1,
          })),
        } : undefined,
      },
      include: { exercises: { orderBy: { order: 'asc' } } },
    });

    await this.awardXp(userId, 50);
    return workout;
  }

  async update(id: string, userId: string, data: Partial<{
    title: string;
    goal: string;
    date: string;
    duration: number;
    calories: number;
    notes: string;
  }>) {
    const existing = await prisma.workout.findFirst({ where: { id, userId } });
    if (!existing) throw new Error('Workout not found');

    const workout = await prisma.workout.update({
      where: { id },
      data: {
        ...data,
        goal: data.goal as any,
        date: data.date ? new Date(data.date) : undefined,
      },
      include: { exercises: { orderBy: { order: 'asc' } } },
    });
    return workout;
  }

  async delete(id: string, userId: string) {
    const existing = await prisma.workout.findFirst({ where: { id, userId } });
    if (!existing) throw new Error('Workout not found');
    await prisma.workout.delete({ where: { id } });
  }

  async getStats(userId: string) {
    const [totalWorkouts, totalDuration, totalCalories, recent] = await Promise.all([
      prisma.workout.count({ where: { userId } }),
      prisma.workout.aggregate({ where: { userId }, _sum: { duration: true } }),
      prisma.workout.aggregate({ where: { userId }, _sum: { calories: true } }),
      prisma.workout.findMany({
        where: { userId },
        orderBy: { date: 'desc' },
        take: 7,
        select: { date: true, duration: true, calories: true },
      }),
    ]);

    return {
      totalWorkouts,
      totalDuration: totalDuration._sum.duration || 0,
      totalCalories: totalCalories._sum.calories || 0,
      recent,
    };
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

export const workoutService = new WorkoutService();
