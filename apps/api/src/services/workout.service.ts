import prisma from '../utils/prisma';
import { AppError } from '../utils/AppError';
import { calculateLevel } from '../utils/helpers';
import { CreateWorkoutBody, UpdateWorkoutBody } from '../validators';

const WORKOUT_XP = 50;
const XP_PER_LEVEL = 1000;

export class WorkoutService {
  async getAll(userId: string, page: number, limit: number) {
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
    if (!workout) throw AppError.notFound('Workout', id);
    return workout;
  }

  async create(userId: string, data: CreateWorkoutBody) {
    // Create the workout and award XP atomically so a crash can't split them.
    const workout = await prisma.$transaction(async (tx) => {
      const created = await tx.workout.create({
        data: {
          userId,
          title: data.title,
          goal: data.goal,
          date: data.date ? new Date(data.date) : new Date(),
          duration: data.duration,
          calories: data.calories,
          notes: data.notes,
          exercises: data.exercises
            ? {
                create: data.exercises.map((e, i) => ({
                  name: e.name,
                  sets: e.sets,
                  reps: e.reps,
                  weight: e.weight,
                  duration: e.duration,
                  calories: e.calories,
                  order: e.order ?? i + 1,
                })),
              }
            : undefined,
        },
        include: { exercises: { orderBy: { order: 'asc' } } },
      });

      const user = await tx.user.update({
        where: { id: userId },
        data: { xpPoints: { increment: WORKOUT_XP } },
      });
      const newLevel = calculateLevel(user.xpPoints, XP_PER_LEVEL);
      if (newLevel > user.level) {
        await tx.user.update({ where: { id: userId }, data: { level: newLevel } });
      }

      return created;
    });

    return workout;
  }

  async update(id: string, userId: string, data: UpdateWorkoutBody) {
    const existing = await prisma.workout.findFirst({ where: { id, userId } });
    if (!existing) throw AppError.notFound('Workout', id);

    return prisma.workout.update({
      where: { id },
      data: {
        ...data,
        date: data.date ? new Date(data.date) : undefined,
      },
      include: { exercises: { orderBy: { order: 'asc' } } },
    });
  }

  async delete(id: string, userId: string) {
    const existing = await prisma.workout.findFirst({ where: { id, userId } });
    if (!existing) throw AppError.notFound('Workout', id);
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
}

export const workoutService = new WorkoutService();