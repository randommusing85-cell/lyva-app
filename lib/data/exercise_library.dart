/// Comprehensive exercise library organized by muscle group.
/// Used by the Custom Workout Builder for exercise selection.

class ExerciseLibrary {
  static const Map<String, List<String>> byCategory = {
    'Chest': [
      'Barbell Bench Press',
      'Dumbbell Bench Press',
      'Incline Bench Press',
      'Incline Dumbbell Press',
      'Decline Bench Press',
      'Cable Fly',
      'Dumbbell Fly',
      'Machine Chest Press',
      'Push-Ups',
      'Pec Deck Machine',
    ],
    'Back': [
      'Barbell Row',
      'Dumbbell Row',
      'Lat Pulldown',
      'Pull-Ups',
      'Chin-Ups',
      'Seated Cable Row',
      'T-Bar Row',
      'Chest-Supported Row',
      'Deadlift',
      'Romanian Deadlift',
      'Face Pull',
    ],
    'Shoulders': [
      'Overhead Press',
      'Dumbbell Shoulder Press',
      'Arnold Press',
      'Lateral Raise',
      'Cable Lateral Raise',
      'Front Raise',
      'Rear Delt Fly',
      'Reverse Pec Deck',
      'Upright Row',
      'Machine Shoulder Press',
    ],
    'Legs': [
      'Barbell Squat',
      'Goblet Squat',
      'Leg Press',
      'Hack Squat',
      'Leg Extension',
      'Leg Curl',
      'Bulgarian Split Squat',
      'Lunges',
      'Walking Lunges',
      'Step-Ups',
      'Calf Raise',
      'Seated Calf Raise',
    ],
    'Glutes': [
      'Hip Thrust',
      'Glute Bridge',
      'Cable Pull-Through',
      'Sumo Deadlift',
      'Glute Kickback',
      'Cable Kickback',
      'Frog Pumps',
      'Single-Leg Hip Thrust',
      'Curtsy Lunge',
      'Banded Clamshell',
    ],
    'Arms': [
      'Barbell Curl',
      'Dumbbell Curl',
      'Hammer Curl',
      'EZ Bar Curl',
      'Cable Curl',
      'Preacher Curl',
      'Tricep Pushdown',
      'Skull Crusher',
      'Overhead Tricep Extension',
      'Dips',
      'Close-Grip Bench Press',
      'Bench Dips',
    ],
    'Core': [
      'Plank',
      'Side Plank',
      'Ab Crunch',
      'Cable Crunch',
      'Hanging Leg Raise',
      'Lying Leg Raise',
      'Russian Twist',
      'Pallof Press',
      'Dead Bug',
      'Hollow Body Hold',
      'Mountain Climbers',
      'Bird Dog',
    ],
    'Full Body': [
      'Burpees',
      'Kettlebell Swing',
      'Clean and Press',
      'Thrusters',
      'Man Makers',
      'Turkish Get-Up',
      'Farmer\'s Walk',
      'Battle Ropes',
      'Box Jumps',
      'Medicine Ball Slam',
    ],
  };

  /// All exercise names as a flat list.
  static List<String> get allExercises {
    final all = <String>[];
    for (final exercises in byCategory.values) {
      all.addAll(exercises);
    }
    return all;
  }

  /// Search exercises across all categories.
  static List<MapEntry<String, String>> search(String query) {
    if (query.trim().isEmpty) return [];
    final q = query.toLowerCase();
    final results = <MapEntry<String, String>>[];

    for (final entry in byCategory.entries) {
      for (final exercise in entry.value) {
        if (exercise.toLowerCase().contains(q)) {
          results.add(MapEntry(entry.key, exercise));
        }
      }
    }

    return results;
  }
}
