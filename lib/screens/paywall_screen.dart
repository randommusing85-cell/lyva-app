import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import '../theme/app_theme.dart';
import '../services/premium_service.dart';
import '../services/analytics_service.dart';
import '../state/providers.dart';

class PaywallScreen extends ConsumerStatefulWidget {
  /// Optional: highlight a specific tier (e.g. when upgrading from essentials)
  final PremiumTier? highlightTier;

  const PaywallScreen({super.key, this.highlightTier});

  @override
  ConsumerState<PaywallScreen> createState() => _PaywallScreenState();
}

class _PaywallScreenState extends ConsumerState<PaywallScreen> {
  bool _isYearly = true; // Default to yearly (better value)
  bool _purchasing = false;
  String? _purchasingPackageId;

  @override
  void initState() {
    super.initState();
    ref.read(analyticsProvider).logPaywallViewed();
  }

  @override
  Widget build(BuildContext context) {
    final offeringsAsync = ref.watch(offeringsProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          onPressed: () {
            ref.read(analyticsProvider).logPaywallDismissed();
            Navigator.pop(context);
          },
          icon: const Icon(Icons.close, color: AppColors.textPrimary),
        ),
      ),
      body: offeringsAsync.when(
        data: (offerings) => _buildPaywall(offerings),
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
        error: (e, _) => _buildPaywall(null), // Show UI with placeholder prices
      ),
    );
  }

  Widget _buildPaywall(Offerings? offerings) {
    final currentOffering = offerings?.current;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 40),
      child: Column(
        children: [
          // Hero header
          _buildHeader(),
          const SizedBox(height: 24),

          // Billing toggle
          _buildBillingToggle(),
          const SizedBox(height: 20),

          // Tier cards
          _buildEssentialsCard(currentOffering),
          const SizedBox(height: 12),
          _buildPremiumCard(currentOffering),
          const SizedBox(height: 24),

          // Feature comparison
          _buildFeatureComparison(),
          const SizedBox(height: 24),

          // Restore purchases
          TextButton(
            onPressed: _purchasing ? null : _restorePurchases,
            child: const Text(
              'Restore Purchases',
              style: TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary,
                decoration: TextDecoration.underline,
              ),
            ),
          ),

          const SizedBox(height: 8),

          // Terms & Privacy
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              TextButton(
                onPressed: () => _openUrl('https://kineticiq.ai/terms'),
                child: const Text(
                  'Terms',
                  style: TextStyle(fontSize: 12, color: AppColors.textMuted),
                ),
              ),
              const Text(' \u2022 ', style: TextStyle(color: AppColors.textMuted)),
              TextButton(
                onPressed: () => _openUrl('https://kineticiq.ai/privacy'),
                child: const Text(
                  'Privacy',
                  style: TextStyle(fontSize: 12, color: AppColors.textMuted),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        Container(
          width: 72,
          height: 72,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [AppColors.seasonAccent, AppColors.primary],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(36),
          ),
          child: const Icon(Icons.star, color: Colors.white, size: 36),
        ),
        const SizedBox(height: 16),
        const Text(
          'Unlock Lyva',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Choose the plan that fits your goals',
          style: TextStyle(
            fontSize: 15,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildBillingToggle() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _isYearly = false),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: !_isYearly ? AppColors.primary : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Text(
                    'Monthly',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: !_isYearly ? Colors.white : AppColors.textSecondary,
                    ),
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _isYearly = true),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: _isYearly ? AppColors.primary : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Yearly',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: _isYearly ? Colors.white : AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: _isYearly
                              ? Colors.white.withOpacity(0.25)
                              : AppColors.primary.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          'Save 33%',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: _isYearly ? Colors.white : AppColors.primary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEssentialsCard(Offering? offering) {
    final packageId = _isYearly ? '\$rc_annual' : '\$rc_monthly';
    final package = _findPackage(offering, 'essentials', _isYearly);
    final price = package?.storeProduct.priceString ??
        (_isYearly ? '\$39.99/yr' : '\$4.99/mo');
    final isHighlighted = widget.highlightTier == PremiumTier.essentials;

    return _TierCard(
      tierName: 'Essentials',
      price: price,
      period: _isYearly ? '/year' : '/month',
      features: const [
        'Advanced Analytics',
        'Export Data (CSV & PDF)',
        'Meal Scanner',
        'Custom Workouts',
      ],
      highlighted: isHighlighted,
      accentColor: AppColors.primary,
      purchasing: _purchasing && _purchasingPackageId == 'essentials',
      onSubscribe: package != null
          ? () => _handlePurchase(package, 'essentials')
          : null,
    );
  }

  Widget _buildPremiumCard(Offering? offering) {
    final package = _findPackage(offering, 'premium', _isYearly);
    final price = package?.storeProduct.priceString ??
        (_isYearly ? '\$79.99/yr' : '\$9.99/mo');
    final isHighlighted = widget.highlightTier != PremiumTier.essentials;

    return _TierCard(
      tierName: 'Premium',
      price: price,
      period: _isYearly ? '/year' : '/month',
      badge: 'BEST VALUE',
      features: const [
        'Everything in Essentials',
        'AI Coaching',
        'AI Memory & Insights',
        'Progress Photos & Analysis',
        'Cycle Predictions',
      ],
      highlighted: isHighlighted,
      accentColor: AppColors.seasonAccent,
      purchasing: _purchasing && _purchasingPackageId == 'premium',
      onSubscribe: package != null
          ? () => _handlePurchase(package, 'premium')
          : null,
    );
  }

  /// Find the right package from the offering.
  /// RevenueCat packages are identified by their identifiers.
  Package? _findPackage(Offering? offering, String tier, bool yearly) {
    if (offering == null) return null;

    // Try to find by custom package identifier first
    final targetId = '${tier}_${yearly ? 'yearly' : 'monthly'}';
    for (final pkg in offering.availablePackages) {
      if (pkg.identifier.contains(targetId)) return pkg;
    }

    // Fallback: try standard RC package types
    if (tier == 'essentials') {
      // Essentials packages are typically the lower-priced ones
      final sorted = [...offering.availablePackages]
        ..sort((a, b) => a.storeProduct.price.compareTo(b.storeProduct.price));
      if (yearly) {
        return sorted.where((p) =>
            p.packageType == PackageType.annual ||
            p.identifier.contains('annual') ||
            p.identifier.contains('yearly')).firstOrNull;
      } else {
        return sorted.where((p) =>
            p.packageType == PackageType.monthly ||
            p.identifier.contains('monthly')).firstOrNull;
      }
    }

    // Premium: try the higher-priced packages
    if (tier == 'premium') {
      final sorted = [...offering.availablePackages]
        ..sort((a, b) => b.storeProduct.price.compareTo(a.storeProduct.price));
      if (yearly) {
        return sorted.where((p) =>
            p.packageType == PackageType.annual ||
            p.identifier.contains('annual') ||
            p.identifier.contains('yearly')).firstOrNull;
      } else {
        return sorted.where((p) =>
            p.packageType == PackageType.monthly ||
            p.identifier.contains('monthly')).firstOrNull;
      }
    }

    return null;
  }

  Widget _buildFeatureComparison() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Compare Plans',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 16),
          // Header row
          Row(
            children: [
              const Expanded(
                flex: 3,
                child: Text('Feature', style: TextStyle(fontSize: 12, color: AppColors.textMuted, fontWeight: FontWeight.w600)),
              ),
              Expanded(
                child: Center(
                  child: Text('Ess.', style: TextStyle(fontSize: 12, color: AppColors.primary, fontWeight: FontWeight.w600)),
                ),
              ),
              Expanded(
                child: Center(
                  child: Text('Pro', style: TextStyle(fontSize: 12, color: AppColors.seasonAccent, fontWeight: FontWeight.w600)),
                ),
              ),
            ],
          ),
          const Divider(height: 16),
          _comparisonRow('Advanced Analytics', true, true),
          _comparisonRow('Export Data', true, true),
          _comparisonRow('Meal Scanner', true, true),
          _comparisonRow('Custom Workouts', true, true),
          _comparisonRow('AI Coaching', false, true),
          _comparisonRow('AI Memory', false, true),
          _comparisonRow('Progress Photos', false, true),
          _comparisonRow('Cycle Predictions', false, true),
        ],
      ),
    );
  }

  Widget _comparisonRow(String feature, bool essentials, bool premium) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Text(
              feature,
              style: const TextStyle(fontSize: 13, color: AppColors.textPrimary),
            ),
          ),
          Expanded(
            child: Center(
              child: Icon(
                essentials ? Icons.check_circle : Icons.cancel_outlined,
                size: 18,
                color: essentials ? AppColors.primary : AppColors.textMuted.withOpacity(0.4),
              ),
            ),
          ),
          Expanded(
            child: Center(
              child: Icon(
                premium ? Icons.check_circle : Icons.cancel_outlined,
                size: 18,
                color: premium ? AppColors.seasonAccent : AppColors.textMuted.withOpacity(0.4),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _handlePurchase(Package package, String tier) async {
    setState(() {
      _purchasing = true;
      _purchasingPackageId = tier;
    });

    try {
      final service = ref.read(premiumServiceProvider);
      final customerInfo = await service.purchase(package);
      final purchasedTier = service.getTierFromCustomerInfo(customerInfo);

      // Update local profile cache
      if (purchasedTier != PremiumTier.none) {
        final profileRepo = ref.read(userProfileRepoProvider);
        await profileRepo.updatePremiumTier(purchasedTier.name);
      }

      // Track analytics
      ref.read(analyticsProvider).logSubscriptionStarted(
            tier: tier,
            period: _isYearly ? 'yearly' : 'monthly',
          );

      // Refresh providers
      ref.invalidate(userProfileProvider);
      ref.invalidate(premiumAccessProvider);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Welcome to Lyva ${tier == 'premium' ? 'Premium' : 'Essentials'}!'),
            backgroundColor: AppColors.primary,
          ),
        );
        Navigator.pop(context, true);
      }
    } on PlatformException catch (e) {
      // User cancelled — handle silently
      if (e.code == '1' || e.message?.contains('cancel') == true) {
        // Purchase cancelled by user — do nothing
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Purchase failed: ${e.message}'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Purchase failed: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _purchasing = false;
          _purchasingPackageId = null;
        });
      }
    }
  }

  Future<void> _restorePurchases() async {
    setState(() => _purchasing = true);

    try {
      final service = ref.read(premiumServiceProvider);
      final customerInfo = await service.restorePurchases();
      final tier = service.getTierFromCustomerInfo(customerInfo);

      if (tier != PremiumTier.none) {
        final profileRepo = ref.read(userProfileRepoProvider);
        await profileRepo.updatePremiumTier(tier.name);

        ref.read(analyticsProvider).logSubscriptionRestored(tier: tier.name);
        ref.invalidate(userProfileProvider);
        ref.invalidate(premiumAccessProvider);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Subscription restored: ${tier.name}'),
              backgroundColor: AppColors.primary,
            ),
          );
          Navigator.pop(context, true);
        }
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No active subscription found'),
            backgroundColor: AppColors.textMuted,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Restore failed: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _purchasing = false);
    }
  }

  Future<void> _openUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }
}

// ============================================================================
// TIER CARD WIDGET
// ============================================================================

class _TierCard extends StatelessWidget {
  final String tierName;
  final String price;
  final String period;
  final String? badge;
  final List<String> features;
  final bool highlighted;
  final Color accentColor;
  final bool purchasing;
  final VoidCallback? onSubscribe;

  const _TierCard({
    required this.tierName,
    required this.price,
    required this.period,
    this.badge,
    required this.features,
    required this.highlighted,
    required this.accentColor,
    required this.purchasing,
    this.onSubscribe,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: highlighted
            ? Border.all(color: accentColor, width: 2)
            : Border.all(color: AppColors.textMuted.withOpacity(0.15)),
        boxShadow: highlighted
            ? [
                BoxShadow(
                  color: accentColor.withOpacity(0.15),
                  blurRadius: 20,
                  offset: const Offset(0, 4),
                ),
              ]
            : [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
      ),
      child: Column(
        children: [
          // Badge
          if (badge != null)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 6),
              decoration: BoxDecoration(
                color: accentColor,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(18),
                ),
              ),
              child: Center(
                child: Text(
                  badge!,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                    letterSpacing: 1,
                  ),
                ),
              ),
            ),

          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Tier name
                Text(
                  tierName,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: accentColor,
                  ),
                ),
                const SizedBox(height: 8),

                // Price
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      price,
                      style: const TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                        height: 1,
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 4, left: 4),
                      child: Text(
                        period,
                        style: const TextStyle(
                          fontSize: 14,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Features
                ...features.map((f) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 3),
                      child: Row(
                        children: [
                          Icon(Icons.check, size: 18, color: accentColor),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              f,
                              style: const TextStyle(
                                fontSize: 14,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    )),

                const SizedBox(height: 16),

                // Subscribe button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: purchasing ? null : onSubscribe,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: highlighted ? accentColor : AppColors.surface,
                      foregroundColor: highlighted ? Colors.white : accentColor,
                      side: highlighted ? null : BorderSide(color: accentColor),
                      disabledBackgroundColor: accentColor.withOpacity(0.4),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: purchasing
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : Text(
                            'Subscribe to $tierName',
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
