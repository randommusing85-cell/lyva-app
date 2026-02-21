import 'package:flutter/material.dart';

import '../models/ai_insight.dart';
import '../theme/app_theme.dart';

class AiInsightCard extends StatelessWidget {
  final AiInsight insight;
  final VoidCallback? onDismiss;

  const AiInsightCard({
    super.key,
    required this.insight,
    this.onDismiss,
  });

  IconData _categoryIcon(String category) {
    switch (category) {
      case 'training_preference':
        return Icons.fitness_center;
      case 'nutrition_pattern':
        return Icons.restaurant;
      case 'recovery_need':
        return Icons.self_improvement;
      case 'motivation_style':
        return Icons.emoji_events;
      case 'cycle_pattern':
        return Icons.favorite;
      default:
        return Icons.lightbulb_outline;
    }
  }

  String _categoryLabel(String category) {
    switch (category) {
      case 'training_preference':
        return 'Training';
      case 'nutrition_pattern':
        return 'Nutrition';
      case 'recovery_need':
        return 'Recovery';
      case 'motivation_style':
        return 'Motivation';
      case 'cycle_pattern':
        return 'Cycle';
      default:
        return 'Insight';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(
            _categoryIcon(insight.category),
            size: 18,
            color: AppColors.seasonAccent,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _categoryLabel(insight.category),
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textMuted,
                  ),
                ),
                Text(
                  insight.content,
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.textPrimary,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          if (onDismiss != null)
            GestureDetector(
              onTap: onDismiss,
              child: const Icon(
                Icons.close,
                size: 16,
                color: AppColors.textMuted,
              ),
            ),
        ],
      ),
    );
  }
}
