import { ApiResponse } from '../types';

export function successResponse<T>(data: T, message?: string): ApiResponse<T> {
  return { success: true, data, message };
}

export function errorResponse(error: string): ApiResponse {
  return { success: false, error };
}

export function calculateLevel(xpPoints: number): number {
  return Math.floor(xpPoints / 1000) + 1;
}

export function calculateDisciplineScore(
  workoutStreak: number,
  habitStreak: number,
  sleepConsistency: number
): number {
  return Math.min(100, Math.round(
    (workoutStreak * 0.4 + habitStreak * 0.35 + sleepConsistency * 0.25)
  ));
}

export function calculateSleepScore(duration: number): number {
  if (duration >= 7 && duration <= 9) return 100;
  if (duration >= 6 && duration < 7) return 75;
  if (duration >= 9 && duration <= 10) return 75;
  if (duration >= 5 && duration < 6) return 50;
  if (duration > 10) return 50;
  return 25;
}
