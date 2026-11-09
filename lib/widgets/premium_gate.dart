import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../theme/app_theme.dart';
import '../services/premium_service.dart';
import '../services/analytics_service.dart';
import '../state/providers.dart';

/// Recheck at the action boundary, including actions outside a gated body.
Future<bool> requirePremiumAccess(
  BuildContext context,
  WidgetRef ref,
  PremiumFeature feature,
) async {
  try {
    final profile = await ref.read(userProfileProvider.future);
    if (!context.mounted) return false;
    final access = await ref
        .read(premiumServiceProvider)
        .getAccessStatusAsync(profile);
    if (!context.mounted) return false;
    if (access.canAccessFeature(feature)) return true;
    await Navigator.pushNamed(context, ref.read(accountSessionProvider).recoverable ? '/paywall' : '/account');
  } catch (_) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Unable to verify access. Please try again.'),
        ),
      );
    }
  }
  return false;
}

/// A widget that gates premium content behind trial/subscription with tier awareness
class PremiumGate extends ConsumerWidget {
  final PremiumFeature feature;
  final Widget child;
  final bool showGate;

  const PremiumGate({
    super.key,
    required this.feature,
    required this.child,
    this.showGate = true,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!showGate) return child;

    final accessAsync = ref.watch(premiumAccessProvider);

    return accessAsync.when(
      data: (access) {
        // Tier-aware: check if user can access THIS specific feature
        if (access.canAccessFeature(feature)) return child;

        // Track gate encountered
        WidgetsBinding.instance.addPostFrameCallback((_) {
          final analytics = AnalyticsService();
          analytics.logPremiumGateEncountered(
            featureId: feature.id,
            screen: ModalRoute.of(context)?.settings.name ?? 'unknown',
          );
        });

        // Case 1: Essentials user trying to access a Premium-tier feature
        if (access.tier == PremiumTier.essentials &&
            feature.requiredTier == PremiumTier.premium) {
          return _buildOverlay(
            context: context,
            child: child,
            opacity: 0.4,
            badgeColor: AppColors.seasonAccent,
            icon: Icons.arrow_upward,
            label: 'Upgrade to Premium',
            onTap: () => Navigator.pushNamed(
              context,
              '/paywall',
              arguments: {'highlightTier': 'premium'},
            ),
          );
        }

        // A local trial cannot bypass account and server verification.
        if (access.type == PremiumAccessType.none) {
          return _buildOverlay(
            context: context,
            child: child,
            opacity: 0.5,
            badgeColor: AppColors.seasonAccent,
            icon: Icons.star,
            label: 'Account & Subscription Required',
            onTap: () => Navigator.pushNamed(context, '/paywall'),
          );
        }

        // Case 3: Trial expired or no subscription — direct to paywall
        return _buildOverlay(
          context: context,
          child: child,
          opacity: 0.4,
          badgeColor: AppColors.textMuted,
          icon: Icons.lock,
          label: 'Subscribe to Unlock',
          onTap: () => Navigator.pushNamed(context, '/paywall'),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, __) => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Unable to verify access. Please try again.'),
            TextButton(
              onPressed: () => ref.invalidate(premiumAccessProvider),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOverlay({
    required BuildContext context,
    required Widget child,
    required double opacity,
    required Color badgeColor,
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Stack(
        children: [
          Opacity(
            opacity: opacity,
            child: IgnorePointer(child: child),
          ),
          Positioned.fill(
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: badgeColor,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(icon, size: 14, color: Colors.white),
                    const SizedBox(width: 6),
                    Text(
                      label,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// A button that navigates to the paywall
class PremiumButton extends StatelessWidget {
  final PremiumFeature feature;
  final String label;
  final IconData? icon;

  const PremiumButton({
    super.key,
    required this.feature,
    required this.label,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: () {
        final analytics = AnalyticsService();
        analytics.logPremiumFeatureTapped(featureId: feature.id);
        Navigator.pushNamed(context, '/paywall');
      },
      icon: Icon(icon ?? Icons.star, size: 16),
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label),
          const SizedBox(width: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: AppColors.seasonAccent.withOpacity(0.2),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              feature.requiredTier == PremiumTier.premium
                  ? 'Premium'
                  : 'Essentials',
              style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: AppColors.seasonAccent,
              ),
            ),
          ),
        ],
      ),
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.textPrimary,
        side: BorderSide(color: AppColors.seasonAccent.withOpacity(0.5)),
      ),
    );
  }
}

/// A card that shows a premium feature and navigates to paywall
class PremiumFeatureCard extends StatelessWidget {
  final PremiumFeature feature;
  final IconData icon;
  final String title;
  final String description;

  const PremiumFeatureCard({
    super.key,
    required this.feature,
    required this.icon,
    required this.title,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        final analytics = AnalyticsService();
        analytics.logPremiumFeatureTapped(featureId: feature.id);
        Navigator.pushNamed(context, '/paywall');
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: AppColors.seasonAccent.withOpacity(0.3),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: AppColors.seasonAccent.withOpacity(0.1),
                borderRadius: BorderRadius.circular(24),
              ),
              child: Icon(icon, color: AppColors.seasonAccent, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: feature.requiredTier == PremiumTier.premium
                              ? AppColors.seasonAccent
                              : AppColors.primary,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          feature.requiredTier == PremiumTier.premium
                              ? 'Premium'
                              : 'Essentials',
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: const TextStyle(
                      fontSize: 14,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: AppColors.textMuted),
          ],
        ),
      ),
    );
  }
}
