class Exercise {
  final String name;
  final String muscleGroup;
  final IconType icon;

  const Exercise({
    required this.name,
    required this.muscleGroup,
    required this.icon,
  });
}

enum IconType { chest, back, legs, shoulders, arms, core, cardio, full }

const exerciseLibrary = [
  // Chest
  Exercise(name: 'Bench Press', muscleGroup: 'Chest', icon: IconType.chest),
  Exercise(name: 'Incline Bench Press', muscleGroup: 'Chest', icon: IconType.chest),
  Exercise(name: 'Decline Bench Press', muscleGroup: 'Chest', icon: IconType.chest),
  Exercise(name: 'Dumbbell Flyes', muscleGroup: 'Chest', icon: IconType.chest),
  Exercise(name: 'Push-ups', muscleGroup: 'Chest', icon: IconType.chest),
  Exercise(name: 'Cable Crossovers', muscleGroup: 'Chest', icon: IconType.chest),
  Exercise(name: 'Dips', muscleGroup: 'Chest', icon: IconType.chest),
  // Back
  Exercise(name: 'Deadlift', muscleGroup: 'Back', icon: IconType.back),
  Exercise(name: 'Pull-ups', muscleGroup: 'Back', icon: IconType.back),
  Exercise(name: 'Lat Pulldown', muscleGroup: 'Back', icon: IconType.back),
  Exercise(name: 'Barbell Row', muscleGroup: 'Back', icon: IconType.back),
  Exercise(name: 'Seated Cable Row', muscleGroup: 'Back', icon: IconType.back),
  Exercise(name: 'T-Bar Row', muscleGroup: 'Back', icon: IconType.back),
  Exercise(name: 'Face Pull', muscleGroup: 'Back', icon: IconType.back),
  // Legs
  Exercise(name: 'Squat', muscleGroup: 'Legs', icon: IconType.legs),
  Exercise(name: 'Leg Press', muscleGroup: 'Legs', icon: IconType.legs),
  Exercise(name: 'Romanian Deadlift', muscleGroup: 'Legs', icon: IconType.legs),
  Exercise(name: 'Leg Curl', muscleGroup: 'Legs', icon: IconType.legs),
  Exercise(name: 'Leg Extension', muscleGroup: 'Legs', icon: IconType.legs),
  Exercise(name: 'Calf Raises', muscleGroup: 'Legs', icon: IconType.legs),
  Exercise(name: 'Lunges', muscleGroup: 'Legs', icon: IconType.legs),
  // Shoulders
  Exercise(name: 'Overhead Press', muscleGroup: 'Shoulders', icon: IconType.shoulders),
  Exercise(name: 'Lateral Raise', muscleGroup: 'Shoulders', icon: IconType.shoulders),
  Exercise(name: 'Front Raise', muscleGroup: 'Shoulders', icon: IconType.shoulders),
  Exercise(name: 'Rear Delt Fly', muscleGroup: 'Shoulders', icon: IconType.shoulders),
  Exercise(name: 'Arnold Press', muscleGroup: 'Shoulders', icon: IconType.shoulders),
  Exercise(name: 'Shrugs', muscleGroup: 'Shoulders', icon: IconType.shoulders),
  // Arms
  Exercise(name: 'Barbell Curl', muscleGroup: 'Arms', icon: IconType.arms),
  Exercise(name: 'Dumbbell Curl', muscleGroup: 'Arms', icon: IconType.arms),
  Exercise(name: 'Hammer Curl', muscleGroup: 'Arms', icon: IconType.arms),
  Exercise(name: 'Tricep Pushdown', muscleGroup: 'Arms', icon: IconType.arms),
  Exercise(name: 'Skull Crushers', muscleGroup: 'Arms', icon: IconType.arms),
  Exercise(name: 'Preacher Curl', muscleGroup: 'Arms', icon: IconType.arms),
  // Core
  Exercise(name: 'Plank', muscleGroup: 'Core', icon: IconType.core),
  Exercise(name: 'Crunches', muscleGroup: 'Core', icon: IconType.core),
  Exercise(name: 'Russian Twists', muscleGroup: 'Core', icon: IconType.core),
  Exercise(name: 'Leg Raises', muscleGroup: 'Core', icon: IconType.core),
  Exercise(name: 'Ab Wheel', muscleGroup: 'Core', icon: IconType.core),
  Exercise(name: 'Cable Crunch', muscleGroup: 'Core', icon: IconType.core),
  // Cardio
  Exercise(name: 'Running', muscleGroup: 'Cardio', icon: IconType.cardio),
  Exercise(name: 'Cycling', muscleGroup: 'Cardio', icon: IconType.cardio),
  Exercise(name: 'Jump Rope', muscleGroup: 'Cardio', icon: IconType.cardio),
  Exercise(name: 'Burpees', muscleGroup: 'Cardio', icon: IconType.cardio),
  Exercise(name: 'Rowing Machine', muscleGroup: 'Cardio', icon: IconType.cardio),
];
