import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../theme/app_theme.dart';
import '../services/premium_service.dart';
import '../services/analytics_service.dart';
import '../state/providers.dart';

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

        // Case 2: No trial started — offer free trial
        if (access.type == PremiumAccessType.none) {
          return _buildOverlay(
            context: context,
            child: child,
            opacity: 0.5,
            badgeColor: AppColors.seasonAccent,
            icon: Icons.star,
            label: 'Try Free for 7 Days',
            onTap: () => _showTrialOfferSheet(context, ref, feature),
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
      loading: () => child,
      error: (_, __) => child,
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
          Opacity(opacity: opacity, child: IgnorePointer(child: child)),
          Positioned.fill(
            child: Center(
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
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

/// Show trial offer bottom sheet
void _showTrialOfferSheet(
    BuildContext context, WidgetRef ref, PremiumFeature feature) {
  showModalBottomSheet(
    context: context,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (ctx) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                color: AppColors.textMuted.withOpacity(0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColors.seasonAccent,
                    AppColors.seasonAccent.withOpacity(0.7),
                  ],
                ),
                borderRadius: BorderRadius.circular(32),
              ),
              child: const Icon(Icons.star, color: Colors.white, size: 32),
            ),
            const SizedBox(height: 16),
            const Text(
              'Start Your Free Trial',
              style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary),
            ),
            const SizedBox(height: 8),
            Text(
              'Try ${feature.name} and all premium features free for 7 days.',
              textAlign: TextAlign.center,
              style: const TextStyle(
                  fontSize: 15, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () async {
                  final profileRepo = ref.read(userProfileRepoProvider);
                  await profileRepo.startPremiumTrial();
                  ref.invalidate(userProfileProvider);
                  ref.invalidate(premiumAccessProvider);
                  if (ctx.mounted) Navigator.pop(ctx);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.seasonAccent,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Start 7-Day Free Trial',
                    style: TextStyle(
                        fontSize: 16, fontWeight: FontWeight.w600)),
              ),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: () {
                if (ctx.mounted) Navigator.pop(ctx);
                Navigator.pushNamed(context, '/paywall');
              },
              child: const Text(
                'View subscription plans',
                style: TextStyle(
                  fontSize: 13,
                  color: AppColors.textSecondary,
                  decoration: TextDecoration.underline,
                ),
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'No credit card required for trial',
              style: TextStyle(fontSize: 12, color: AppColors.textMuted),
            ),
          ],
        ),
      ),
    ),
  );
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
        side: BorderSide(
          color: AppColors.seasonAccent.withOpacity(0.5),
        ),
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
              child: Icon(
                icon,
                color: AppColors.seasonAccent,
                size: 24,
              ),
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
            const Icon(
              Icons.chevron_right,
              color: AppColors.textMuted,
            ),
          ],
        ),
      ),
    );
  }
}
