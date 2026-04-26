import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../state/providers.dart';
import '../repos/lyva_repo.dart';

class WeeklyProgressCard extends ConsumerWidget {
  const WeeklyProgressCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final repo = ref.read(lyvaRepoProvider);

    return FutureBuilder(
      future: _getWeeklyProgress(repo),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const SizedBox.shrink();
        }

        final data = snapshot.data!;
        final completed = data['completed'] as int;
        final total = data['total'] as int;

        if (total == 0) {
          return const SizedBox.shrink();
        }

        final progress = completed / total;
        final isComplete = completed >= total;

        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: isComplete
                  ? [
                      theme.colorScheme.primary.withOpacity(0.1),
                      theme.colorScheme.tertiary.withOpacity(0.1),
                    ]
                  : [
                      theme.colorScheme.primaryContainer.withOpacity(0.3),
                      theme.colorScheme.surface,
                    ],
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: theme.colorScheme.outline.withOpacity(0.2),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    isComplete ? Icons.check_circle : Icons.fitness_center,
                    color: isComplete
                        ? theme.colorScheme.primary
                        : theme.colorScheme.onSurfaceVariant,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    isComplete ? 'This Week: Complete! ðŸŽ‰' : 'This Week',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: isComplete
                          ? theme.colorScheme.primary
                          : theme.colorScheme.onSurface,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Progress bar
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  value: progress,
                  minHeight: 8,
                  backgroundColor: theme.colorScheme.surfaceContainerHighest,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    isComplete
                        ? theme.colorScheme.primary
                        : theme.colorScheme.secondary,
                  ),
                ),
              ),
              const SizedBox(height: 8),

              // Stats
              Text(
                '$completed of $total workouts completed',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),

              if (!isComplete && completed > 0) ...[
                const SizedBox(height: 8),
                Text(
                  'Keep going. Consistency compounds.',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant.withOpacity(0.7),
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],

              if (isComplete) ...[
                const SizedBox(height: 8),
                Text(
                  'You showed up all week. This is how progress happens.',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.primary,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Future<Map<String, int>> _getWeeklyProgress(LyvaRepo repo) async {
    final template = await repo.getLatestWorkoutTemplate();
    if (template == null) {
      return {'completed': 0, 'total': 0};
    }

    final totalDays = template.daysPerWeek;

    // Get all sessions from this week
    final now = DateTime.now();
    final weekStart = now.subtract(Duration(days: now.weekday - 1));
    final weekStartMidnight =
        DateTime(weekStart.year, weekStart.month, weekStart.day);

    // For v0.1, we'll do a simple count
    // In v1.0, you'd query sessions with date filters
    final latestSession = await repo.getLatestWorkoutSession();

    // Simple heuristic: count completed sessions this week
    // This is a placeholder - you'd want to query all sessions in date range
    int completedThisWeek = 0;
    if (latestSession != null &&
        latestSession.completed &&
        latestSession.date.isAfter(weekStartMidnight)) {
      completedThisWeek = latestSession.dayIndex;
    }

    return {
      'completed': completedThisWeek.clamp(0, totalDays),
      'total': totalDays,
    };
  }
}