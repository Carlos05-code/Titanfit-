import {
  calculateDisciplineScore,
  calculateLevel,
  calculateSleepScore,
  errorResponse,
  successResponse,
} from '../helpers';

describe('calculateLevel', () => {
  it('returns level 1 below the threshold', () => {
    expect(calculateLevel(0)).toBe(1);
    expect(calculateLevel(999)).toBe(1);
  });

  it('increments level per threshold', () => {
    expect(calculateLevel(1000)).toBe(2);
    expect(calculateLevel(2500)).toBe(3);
  });

  it('honors a custom xpPerLevel', () => {
    expect(calculateLevel(500, 500)).toBe(2);
  });
});

describe('calculateDisciplineScore', () => {
  it('weights the three sub-scores and caps at 100', () => {
    expect(calculateDisciplineScore(10, 10, 100)).toBe(33);
    expect(calculateDisciplineScore(0, 0, 0)).toBe(0);
    expect(calculateDisciplineScore(10, 10, 10)).toBe(10);
  });

  it('rounds to the nearest integer', () => {
    expect(calculateDisciplineScore(1, 1, 1)).toBe(1);
  });
});

describe('calculateSleepScore', () => {
  it('scores 7-9h as perfect', () => {
    expect(calculateSleepScore(7)).toBe(100);
    expect(calculateSleepScore(8.5)).toBe(100);
    expect(calculateSleepScore(9)).toBe(100);
  });

  it('downgrades borderline durations', () => {
    expect(calculateSleepScore(6.5)).toBe(75);
    expect(calculateSleepScore(9.5)).toBe(75);
    expect(calculateSleepScore(5.5)).toBe(50);
    expect(calculateSleepScore(11)).toBe(50);
    expect(calculateSleepScore(3)).toBe(25);
  });
});

describe('response envelopes', () => {
  it('wraps success payloads', () => {
    expect(successResponse({ id: 1 }, 'done')).toEqual({
      success: true,
      data: { id: 1 },
      message: 'done',
    });
  });

  it('wraps errors', () => {
    expect(errorResponse('boom')).toEqual({ success: false, error: 'boom' });
  });
});