import 'package:isar/isar.dart';

part 'user_profile.g.dart';

@collection
class UserProfile {
  Id id = Isar.autoIncrement;

  /// User's display name for personalized greetings
  String name = '';

  /// Last time user opened the app (for dynamic greetings)
  DateTime? lastLoginAt;

  late int age;
  late String sex; // 'male' or 'female'
  late int heightCm;
  late double weightKg;

  late String goal; // 'cut', 'recomp', 'bulk'
  late String level; // 'beginner', 'intermediate', 'advanced'
  late String equipment; // 'gym', 'home_dumbbells', 'calisthenics'
  late int trainingDaysPerWeek;

  late DateTime createdAt;
  late DateTime updatedAt;

  // ===== WORKOUT SCHEDULE =====
  
  /// Scheduled workout days (1=Monday, 7=Sunday)
  /// Stored as comma-separated string: "1,3,5" = Mon, Wed, Fri
  String scheduledDays = '';
  
  /// Get scheduled days as list of integers
  List<int> get scheduledDaysList {
    if (scheduledDays.isEmpty) return [];
    return scheduledDays
        .split(',')
        .where((s) => s.isNotEmpty)
        .map((s) => int.tryParse(s))
        .whereType<int>()
        .toList();
  }
  
  /// Set scheduled days from list
  set scheduledDaysList(List<int> days) {
    scheduledDays = days.join(',');
  }
  
  /// Check if a specific day is a scheduled workout day
  bool isScheduledWorkoutDay(DateTime date) {
    if (scheduledDays.isEmpty) return false;
    final dayOfWeek = date.weekday; // 1 = Monday, 7 = Sunday
    return scheduledDaysList.contains(dayOfWeek);
  }
  
  /// Get formatted schedule text for display
  String get scheduleDisplayText {
    final days = scheduledDaysList;
    if (days.isEmpty) return 'Not scheduled';
    
    final dayNames = days.map((d) => _getDayName(d, short: true)).toList();
    if (dayNames.length <= 2) {
      return dayNames.join(' & ');
    } else if (dayNames.length == 3) {
      return '${dayNames[0]}, ${dayNames[1]} & ${dayNames[2]}';
    } else {
      return '${dayNames.sublist(0, 3).join(', ')}+';
    }
  }
  
  static String _getDayName(int day, {bool short = false}) {
    const names = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    const fullNames = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday'
    ];
    if (day < 1 || day > 7) return '';
    return short ? names[day - 1] : fullNames[day - 1];
  }

  // ===== CYCLE TRACKING FIELDS =====
  
  /// Whether user wants cycle-aware training
  bool trackCycle = false;
  
  /// Date of last period start (Day 1)
  DateTime? lastPeriodDate;
  
  /// Average cycle length in days (default 28)
  int cycleLength = 28;
  
  /// Average period duration in days (default 5)
  int periodDuration = 5;

  // ===== POST-PARTUM FIELDS =====
  
  /// Post-partum status: 'no', 'early' (0-12w), 'mid' (3-6m), 'late' (6-18m)
  String postPartumStatus = 'no';
  
  /// Date of delivery (for timeline calculation)
  DateTime? deliveryDate;
  
  /// Has medical clearance to exercise
  bool medicalClearance = false;
  
  /// Wants diastasis recti guidance
  bool checkDiastasis = false;
  
  /// Delivery type (affects recovery timeline)
  String deliveryType = 'unknown'; // 'vaginal', 'cesarean', 'unknown'

  // ===== INJURY/LIMITATION FIELDS =====
  
  /// List of injuries/limitations (stored as comma-separated string for Isar)
  /// Examples: 'lower_back', 'knee_left', 'shoulder_right', 'wrist'
  String injuries = '';
  
  /// Additional notes about injuries/limitations
  String? injuryNotes;

  // ===== NOTIFICATION PREFERENCES =====
  
  /// Whether to send daily check-in reminders
  bool notifyCheckIn = true;
  
  /// Whether to send workout day reminders
  bool notifyWorkout = true;
  
  /// Preferred reminder time (hour of day, 0-23)
  int reminderHour = 9;
  
  /// Preferred reminder time (minute, 0-59)
  int reminderMinute = 0;

  // ===== HELPER METHODS =====
  
  /// Get injuries as a list
  List<String> get injuryList {
    if (injuries.isEmpty) return [];
    return injuries.split(',').where((s) => s.isNotEmpty).toList();
  }
  
  /// Set injuries from a list
  set injuryList(List<String> list) {
    injuries = list.join(',');
  }
  
  /// Check if user has any injuries
  bool get hasInjuries => injuries.isNotEmpty;
  
  /// Get formatted injury text for display
  String get injuryDisplayText {
    final list = injuryList;
    if (list.isEmpty) return 'None';
    return list.map((i) => _formatInjuryName(i)).join(', ');
  }
  
  static String _formatInjuryName(String injury) {
    return injury
        .replaceAll('_', ' ')
        .split(' ')
        .map((word) => word.isNotEmpty 
            ? '${word[0].toUpperCase()}${word.substring(1)}' 
            : '')
        .join(' ');
  }
}