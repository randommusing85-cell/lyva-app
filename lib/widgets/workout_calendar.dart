import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../state/providers.dart';
import '../repos/lyva_repo.dart';
import '../models/workout_session_doc.dart';

/// Full-featured workout calendar with month view, navigation, and workout history
class WorkoutCalendar extends ConsumerStatefulWidget {
  final int trainingDaysPerWeek;

  const WorkoutCalendar({
    super.key,
    required this.trainingDaysPerWeek,
  });

  @override
  ConsumerState<WorkoutCalendar> createState() => _WorkoutCalendarState();
}

class _WorkoutCalendarState extends ConsumerState<WorkoutCalendar> {
  late DateTime _currentMonth;
  Map<String, WorkoutSessionDoc>? _sessionsCache;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _currentMonth = DateTime(DateTime.now().year, DateTime.now().month, 1);
    _loadMonthSessions();
  }

  Future<void> _loadMonthSessions() async {
    setState(() => _loading = true);
    
    final repo = ref.read(lyvaRepoProvider);
    final profile = await ref.read(userProfileProvider.future);
    
    if (profile == null) {
      setState(() => _loading = false);
      return;
    }

    // Get all sessions for the current month
    final startOfMonth = DateTime(_currentMonth.year, _currentMonth.month, 1);
    final endOfMonth = DateTime(_currentMonth.year, _currentMonth.month + 1, 0, 23, 59, 59);
    
    final sessions = await repo.getSessionsInDateRange(startOfMonth, endOfMonth);
    
    // Convert to map keyed by date string
    final sessionMap = <String, WorkoutSessionDoc>{};
    for (final session in sessions) {
      final dateKey = _dateKey(session.date);
      sessionMap[dateKey] = session;
    }
    
    setState(() {
      _sessionsCache = sessionMap;
      _loading = false;
    });
  }

  String _dateKey(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  void _previousMonth() {
    setState(() {
      _currentMonth = DateTime(_currentMonth.year, _currentMonth.month - 1, 1);
    });
    _loadMonthSessions();
  }

  void _nextMonth() {
    setState(() {
      _currentMonth = DateTime(_currentMonth.year, _currentMonth.month + 1, 1);
    });
    _loadMonthSessions();
  }

  void _goToToday() {
    final now = DateTime.now();
    setState(() {
      _currentMonth = DateTime(now.year, now.month, 1);
    });
    _loadMonthSessions();
  }

  Future<void> _showDayWorkout(DateTime date, WorkoutSessionDoc? session) async {
    if (session == null) {
      // No workout on this day
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No workout logged on ${_formatDate(date)}')),
      );
      return;
    }

    // Show workout details dialog
    await showDialog(
      context: context,
      builder: (ctx) => _WorkoutDetailDialog(
        date: date,
        session: session,
      ),
    );
  }

  String _formatDate(DateTime date) {
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 
                    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }

  String _formatMonthYear(DateTime date) {
    final months = ['January', 'February', 'March', 'April', 'May', 'June',
                    'July', 'August', 'September', 'October', 'November', 'December'];
    return '${months[date.month - 1]} ${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final profileAsync = ref.watch(userProfileProvider);

    return profileAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, __) => const SizedBox.shrink(),
      data: (profile) {
        if (profile == null) return const SizedBox.shrink();

        final scheduledDays = profile.scheduledDaysList;
        final now = DateTime.now();
        final isCurrentMonth = _currentMonth.year == now.year && _currentMonth.month == now.month;

        // Calculate stats for current month
        int completedCount = 0;
        int missedCount = 0;
        
        if (_sessionsCache != null) {
          final daysInMonth = DateTime(_currentMonth.year, _currentMonth.month + 1, 0).day;
          
          for (int day = 1; day <= daysInMonth; day++) {
            final date = DateTime(_currentMonth.year, _currentMonth.month, day);
            if (date.isAfter(now)) break;
            
            final isScheduled = scheduledDays.contains(date.weekday);
            final dateKey = _dateKey(date);
            final session = _sessionsCache![dateKey];
            
            if (session != null && session.completed) {
              completedCount++;
            } else if (isScheduled) {
              missedCount++;
            }
          }
        }

        return Card(
          elevation: 2,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header with navigation
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.chevron_left),
                      onPressed: _previousMonth,
                      tooltip: 'Previous month',
                    ),
                    Expanded(
                      child: Center(
                        child: Text(
                          _formatMonthYear(_currentMonth),
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    if (!isCurrentMonth)
                      TextButton(
                        onPressed: _goToToday,
                        child: const Text('Today'),
                      ),
                    IconButton(
                      icon: const Icon(Icons.chevron_right),
                      onPressed: isCurrentMonth ? null : _nextMonth,
                      tooltip: 'Next month',
                    ),
                  ],
                ),

                const SizedBox(height: 8),

                // Stats badges
                if (_sessionsCache != null && (completedCount > 0 || missedCount > 0))
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _StatBadge(
                          label: 'Completed',
                          count: completedCount,
                          color: Colors.green,
                        ),
                        const SizedBox(width: 16),
                        _StatBadge(
                          label: 'Missed',
                          count: missedCount,
                          color: Colors.red.shade300,
                        ),
                      ],
                    ),
                  ),

                // Loading indicator
                if (_loading)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.all(8.0),
                      child: CircularProgressIndicator(),
                    ),
                  ),

                // Calendar grid
                if (!_loading && _sessionsCache != null)
                  _CalendarGrid(
                    month: _currentMonth,
                    scheduledDays: scheduledDays,
                    sessions: _sessionsCache!,
                    onDayTap: _showDayWorkout,
                  ),

                const SizedBox(height: 12),

                // Legend
                Wrap(
                  spacing: 16,
                  runSpacing: 8,
                  alignment: WrapAlignment.center,
                  children: [
                    _LegendItem(
                      color: Colors.green,
                      label: 'Completed',
                    ),
                    _LegendItem(
                      color: Colors.red.shade300,
                      label: 'Missed',
                    ),
                    _LegendItem(
                      color: Colors.grey.shade300,
                      label: 'Rest day',
                    ),
                    _LegendItem(
                      color: theme.colorScheme.primary,
                      label: 'Today',
                      isToday: true,
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _CalendarGrid extends StatelessWidget {
  final DateTime month;
  final List<int> scheduledDays;
  final Map<String, WorkoutSessionDoc> sessions;
  final Function(DateTime, WorkoutSessionDoc?) onDayTap;

  const _CalendarGrid({
    required this.month,
    required this.scheduledDays,
    required this.sessions,
    required this.onDayTap,
  });

  String _dateKey(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    final firstDayOfMonth = DateTime(month.year, month.month, 1);
    final daysInMonth = DateTime(month.year, month.month + 1, 0).day;
    final firstWeekday = firstDayOfMonth.weekday;

    final offset = firstWeekday == 7 ? 0 : firstWeekday;

    return Column(
      children: [
        // Day headers
        Row(
          children: ['M', 'T', 'W', 'T', 'F', 'S', 'S'].map((day) {
            return Expanded(
              child: Center(
                child: Text(
                  day,
                  style: theme.textTheme.labelSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 8),

        // Calendar grid
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 7,
            childAspectRatio: 1,
            crossAxisSpacing: 4,
            mainAxisSpacing: 4,
          ),
          itemCount: offset + daysInMonth,
          itemBuilder: (context, index) {
            if (index < offset) {
              return const SizedBox.shrink();
            }

            final day = index - offset + 1;
            final date = DateTime(month.year, month.month, day);
            final dateKey = _dateKey(date);
            final session = sessions[dateKey];
            final isToday = date.year == today.year &&
                date.month == today.month &&
                date.day == today.day;
            final isFuture = date.isAfter(today);
            final isScheduledDay = scheduledDays.contains(date.weekday);

            Color? fillColor;
            Color? borderColor;

            if (isFuture) {
              fillColor = null;
            } else if (session != null && session.completed) {
              fillColor = Colors.green;
            } else if (isScheduledDay) {
              fillColor = Colors.red.shade300;
            } else {
              fillColor = Colors.grey.shade200;
            }

            if (isToday) {
              borderColor = theme.colorScheme.primary;
            }

            return InkWell(
              onTap: isFuture ? null : () => onDayTap(date, session),
              borderRadius: BorderRadius.circular(8),
              child: Container(
                decoration: BoxDecoration(
                  color: fillColor,
                  border: borderColor != null
                      ? Border.all(color: borderColor, width: 2)
                      : null,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(
                  child: Text(
                    '$day',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: fillColor != null && !isFuture
                          ? Colors.white
                          : theme.colorScheme.onSurface,
                      fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}

class _StatBadge extends StatelessWidget {
  final String label;
  final int count;
  final Color color;

  const _StatBadge({
    required this.label,
    required this.count,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            '$count $label',
            style: theme.textTheme.labelMedium?.copyWith(
              color: color.computeLuminance() > 0.5
                  ? Colors.black87
                  : color,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

class _LegendItem extends StatelessWidget {
  final Color color;
  final String label;
  final bool isToday;

  const _LegendItem({
    required this.color,
    required this.label,
    this.isToday = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: isToday ? Colors.transparent : color,
            border: isToday ? Border.all(color: color, width: 2) : null,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: theme.textTheme.labelSmall,
        ),
      ],
    );
  }
}

class _WorkoutDetailDialog extends ConsumerWidget {
  final DateTime date;
  final WorkoutSessionDoc session;

  const _WorkoutDetailDialog({
    required this.date,
    required this.session,
  });

  String _formatDate(DateTime date) {
    final months = ['January', 'February', 'March', 'April', 'May', 'June',
                    'July', 'August', 'September', 'October', 'November', 'December'];
    final weekdays = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
    return '${weekdays[date.weekday - 1]}, ${months[date.month - 1]} ${date.day}, ${date.year}';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final templateAsync = ref.watch(latestWorkoutTemplateProvider);

    return Dialog(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 400, maxHeight: 600),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: session.completed
                    ? Colors.green.shade50
                    : Colors.orange.shade50,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(28),
                ),
              ),
              child: Column(
                children: [
                  Icon(
                    session.completed ? Icons.check_circle : Icons.cancel,
                    size: 48,
                    color: session.completed ? Colors.green : Colors.orange,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    _formatDate(date),
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),

            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: templateAsync.when(
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (_, __) => const Text('Could not load workout details'),
                  data: (template) {
                    if (template == null) {
                      return const Text('Workout plan not found');
                    }

                    final decoded = jsonDecode(template.json);
                    final templateMap = Map<String, dynamic>.from(decoded);
                    final days = (templateMap['days'] as List)
                        .map((d) => Map<String, dynamic>.from(d as Map))
                        .toList();

                    Map<String, dynamic>? dayData;
                    for (final d in days) {
                      if (d['dayIndex'] == session.dayIndex) {
                        dayData = d;
                        break;
                      }
                    }

                    if (dayData == null && session.dayIndex <= days.length) {
                      dayData = days[session.dayIndex - 1];
                    }

                    if (dayData == null) {
                      return Text('Day ${session.dayIndex} details not found');
                    }

                    final title = dayData['title']?.toString() ?? 'Day ${session.dayIndex}';
                    final exercises = (dayData['exercises'] as List?)
                        ?.map((e) => Map<String, dynamic>.from(e as Map))
                        .toList() ?? [];

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Day ${session.dayIndex} of ${template.daysPerWeek}',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: 16),

                        Text(
                          'Exercises',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 12),

                        ...exercises.map((ex) {
                          final name = ex['name']?.toString() ?? 'Exercise';
                          final sets = ex['workingSets']?.toString() ?? '?';
                          final repRange = ex['repRange'];
                          String reps = '?';
                          if (repRange is Map) {
                            final min = repRange['min'];
                            final max = repRange['max'];
                            reps = '$min-$max';
                          }

                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Icon(
                                  Icons.fitness_center,
                                  size: 16,
                                  color: theme.colorScheme.primary,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        name,
                                        style: theme.textTheme.bodyMedium?.copyWith(
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      Text(
                                        '$sets sets x $reps reps',
                                        style: theme.textTheme.bodySmall?.copyWith(
                                          color: theme.colorScheme.onSurfaceVariant,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          );
                        }),
                      ],
                    );
                  },
                ),
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(20),
              child: FilledButton(
                onPressed: () => Navigator.pop(context),
                style: FilledButton.styleFrom(
                  minimumSize: const Size(double.infinity, 48),
                ),
                child: const Text('Close'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}