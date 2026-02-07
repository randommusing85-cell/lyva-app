import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../theme/app_theme.dart';
import '../services/premium_service.dart';
import '../services/analytics_service.dart';

/// A widget that gates premium content and shows a waitlist signup
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

    // Track gate encountered
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final analytics = AnalyticsService();
      analytics.logPremiumGateEncountered(
        featureId: feature.id,
        screen: ModalRoute.of(context)?.settings.name ?? 'unknown',
      );
    });

    return GestureDetector(
      onTap: () => _showPremiumSheet(context, feature),
      child: Stack(
        children: [
          // Blurred/dimmed content
          Opacity(
            opacity: 0.5,
            child: IgnorePointer(child: child),
          ),
          // Premium badge overlay
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.seasonAccent,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.star,
                        size: 14,
                        color: Colors.white,
                      ),
                      SizedBox(width: 4),
                      Text(
                        'Premium',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
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
}

/// A button that shows the premium waitlist sheet
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
      onPressed: () => _showPremiumSheet(context, feature),
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
            child: const Text(
              'Soon',
              style: TextStyle(
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

/// A card that shows a premium feature is coming soon
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
      onTap: () => _showPremiumSheet(context, feature),
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
                          color: AppColors.seasonAccent,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text(
                          'Coming Soon',
                          style: TextStyle(
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

/// Show the premium waitlist bottom sheet
void _showPremiumSheet(BuildContext context, PremiumFeature feature) {
  // Track feature interest
  final premiumService = PremiumService();
  premiumService.trackFeatureInterest(feature);

  final analytics = AnalyticsService();
  analytics.logPremiumFeatureTapped(featureId: feature.id);

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (ctx) => _PremiumWaitlistSheet(feature: feature),
  );
}

/// Premium waitlist signup sheet
class _PremiumWaitlistSheet extends StatefulWidget {
  final PremiumFeature feature;

  const _PremiumWaitlistSheet({required this.feature});

  @override
  State<_PremiumWaitlistSheet> createState() => _PremiumWaitlistSheetState();
}

class _PremiumWaitlistSheetState extends State<_PremiumWaitlistSheet> {
  final _emailController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  bool _loading = false;
  bool _joined = false;
  String? _existingEmail;

  final Set<PremiumFeature> _selectedFeatures = {};

  @override
  void initState() {
    super.initState();
    _selectedFeatures.add(widget.feature);
    _checkExistingWaitlist();

    // Track waitlist sheet viewed
    final analytics = AnalyticsService();
    analytics.logPremiumWaitlistViewed(featureId: widget.feature.id);
  }

  Future<void> _checkExistingWaitlist() async {
    final premiumService = PremiumService();
    final hasJoined = await premiumService.hasJoinedWaitlist();
    final email = await premiumService.getWaitlistEmail();

    if (mounted) {
      setState(() {
        _joined = hasJoined;
        _existingEmail = email;
      });
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _joinWaitlist() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _loading = true);

    try {
      final premiumService = PremiumService();
      await premiumService.joinWaitlist(
        email: _emailController.text.trim(),
        interestedFeatures: _selectedFeatures.toList(),
      );

      // Track analytics
      final analytics = AnalyticsService();
      await analytics.logPremiumWaitlistJoined(
        email: _emailController.text.trim(),
        features: _selectedFeatures.map((f) => f.id).toList(),
      );

      if (mounted) {
        setState(() {
          _joined = true;
          _existingEmail = _emailController.text.trim();
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 20,
          bottom: MediaQuery.of(context).viewInsets.bottom + 20,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Drag handle
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: AppColors.textMuted.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),

              // Header
              Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          AppColors.seasonAccent,
                          AppColors.seasonAccent.withOpacity(0.7),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: const Icon(
                      Icons.star,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 16),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Premium Features',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        Text(
                          'Coming soon!',
                          style: TextStyle(
                            fontSize: 14,
                            color: AppColors.seasonAccent,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              if (_joined) ...[
                // Already joined state
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.check_circle,
                        color: AppColors.primary,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              "You're on the list!",
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: AppColors.primary,
                              ),
                            ),
                            if (_existingEmail != null)
                              Text(
                                "We'll notify $_existingEmail",
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  "We're working hard to bring you amazing premium features. Stay tuned!",
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.textSecondary,
                  ),
                ),
              ] else ...[
                // Feature highlight
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceVariant,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.feature.name,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        widget.feature.description,
                        style: const TextStyle(
                          fontSize: 14,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // Feature selection
                const Text(
                  'What features interest you?',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: PremiumFeature.values.map((feature) {
                    final isSelected = _selectedFeatures.contains(feature);
                    return ChoiceChip(
                      label: Text(feature.name),
                      selected: isSelected,
                      selectedColor: AppColors.primary.withOpacity(0.2),
                      onSelected: (selected) {
                        setState(() {
                          if (selected) {
                            _selectedFeatures.add(feature);
                          } else {
                            _selectedFeatures.remove(feature);
                          }
                        });
                      },
                    );
                  }).toList(),
                ),

                const SizedBox(height: 24),

                // Email signup form
                const Text(
                  'Get notified when premium launches',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 12),
                Form(
                  key: _formKey,
                  child: TextFormField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: InputDecoration(
                      hintText: 'Enter your email',
                      filled: true,
                      fillColor: AppColors.surface,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      prefixIcon: const Icon(Icons.email_outlined),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter your email';
                      }
                      if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$')
                          .hasMatch(value)) {
                        return 'Please enter a valid email';
                      }
                      return null;
                    },
                  ),
                ),

                const SizedBox(height: 16),

                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _loading ? null : _joinWaitlist,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.seasonAccent,
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: AppColors.seasonAccent.withOpacity(0.5),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: _loading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text(
                            'Join the Waitlist',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                  ),
                ),

                const SizedBox(height: 12),

                const Center(
                  child: Text(
                    "We'll only email you about premium features",
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.textMuted,
                    ),
                  ),
                ),

                const SizedBox(height: 8),

                const Center(
                  child: Text(
                    'Questions? Reach us at kineticiq.ai@gmail.com',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.textMuted,
                    ),
                  ),
                ),
              ],

              const SizedBox(height: 20),

              // Preview of premium features
              const Text(
                'Coming in Premium',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 12),
              _FeaturePreviewRow(
                icon: Icons.chat_bubble_outline,
                title: 'AI Coaching',
                description: 'Personalized coaching conversations',
              ),
              const SizedBox(height: 8),
              _FeaturePreviewRow(
                icon: Icons.psychology_outlined,
                title: 'AI Memory',
                description: 'AI learns your patterns over time',
              ),
              const SizedBox(height: 8),
              _FeaturePreviewRow(
                icon: Icons.camera_outlined,
                title: 'Progress Photos',
                description: 'AI body analysis and celeb comparisons',
              ),
              const SizedBox(height: 8),
              _FeaturePreviewRow(
                icon: Icons.auto_graph_outlined,
                title: 'Cycle Predictions',
                description: 'AI-powered period and training predictions',
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FeaturePreviewRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;

  const _FeaturePreviewRow({
    required this.icon,
    required this.title,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 20, color: AppColors.textMuted),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textPrimary,
                ),
              ),
              Text(
                description,
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textMuted,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
