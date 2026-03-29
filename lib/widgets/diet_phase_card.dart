import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../state/providers.dart';
import '../theme/app_theme.dart';
import '../utils/plateau_detector.dart';

/// Compact card showing current diet phase status on the home screen.
/// Only visible for users with goal == 'cut'.
class DietPhaseCard extends ConsumerWidget {
  const DietPhaseCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(userProfileProvider);
    final profile = profileAsync.valueOrNull;

    // Only show for users with goal == 'cut'
    if (profile == null || profile.goal != 'cut') {
      return const SizedBox.shrink();
    }

    final plateauAsync = ref.watch(plateauStatusProvider);

    return plateauAsync.when(
      data: (status) {
        if (status == null) return const SizedBox.shrink();
        return _buildCard(context, status);
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }

  Widget _buildCard(BuildContext context, PlateauStatus status) {
    // Refeed in progress
    if (status.currentPhase == 'refeed') {
      final remaining = status.daysRemainingInRefeed ?? 0;
      final elapsed = PlateauDetector.refeedDurationDays - remaining;

      return _PhaseCard(
        icon: Icons.restaurant,
        iconColor: AppColors.primary,
        backgroundColor: AppColors.primary.withOpacity(0.1),
        title: 'Refeed Break',
        subtitle: 'Day $elapsed of ${PlateauDetector.refeedDurationDays}',
        trailing: remaining > 0
            ? '$remaining days left'
            : 'Complete! Tap to resume',
        trailingColor: remaining > 0 ? AppColors.primary : AppColors.success,
        progress: elapsed / PlateauDetector.refeedDurationDays,
        progressColor: AppColors.primary,
        onTap: () => Navigator.pushNamed(context, '/myplan'),
      );
    }

    // Plateau detected
    if (status.isPlateaued) {
      return _PhaseCard(
        icon: Icons.trending_flat,
        iconColor: Colors.orange.shade700,
        backgroundColor: AppColors.warning.withOpacity(0.15),
        title: 'Weight Plateau Detected',
        subtitle: 'Your weight has stalled for 3+ weeks',
        trailing: 'Tap to learn more',
        trailingColor: Colors.orange.shade700,
        onTap: () => Navigator.pushNamed(context, '/myplan'),
      );
    }

    // Resumed deficit after refeed
    if (status.currentPhase == 'resumed_deficit') {
      return _PhaseCard(
        icon: Icons.trending_down,
        iconColor: AppColors.primary,
        backgroundColor: AppColors.primaryLight.withOpacity(0.2),
        title: 'Deficit Resumed',
        subtitle: '${status.daysInCurrentPhase} days since refeed',
        trailing: 'On track',
        trailingColor: AppColors.primary,
        onTap: () => Navigator.pushNamed(context, '/myplan'),
      );
    }

    // Normal deficit — no special UI needed
    return const SizedBox.shrink();
  }
}

class _PhaseCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final Color backgroundColor;
  final String title;
  final String subtitle;
  final String trailing;
  final Color trailingColor;
  final double? progress;
  final Color? progressColor;
  final VoidCallback? onTap;

  const _PhaseCard({
    required this.icon,
    required this.iconColor,
    required this.backgroundColor,
    required this.title,
    required this.subtitle,
    required this.trailing,
    required this.trailingColor,
    this.progress,
    this.progressColor,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: iconColor.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, size: 20, color: iconColor),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  trailing,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: trailingColor,
                  ),
                ),
                const SizedBox(width: 4),
                Icon(Icons.chevron_right, size: 16, color: AppColors.textMuted),
              ],
            ),
            if (progress != null) ...[
              const SizedBox(height: 10),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: progress!.clamp(0.0, 1.0),
                  minHeight: 4,
                  backgroundColor: (progressColor ?? AppColors.primary).withOpacity(0.2),
                  valueColor: AlwaysStoppedAnimation<Color>(
                    progressColor ?? AppColors.primary,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
