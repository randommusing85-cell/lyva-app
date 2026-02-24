import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:url_launcher/url_launcher.dart';
import '../state/providers.dart';
import '../services/analytics_service.dart';
import '../widgets/workout_day_scheduler.dart';
import '../theme/app_theme.dart';
import '../services/premium_service.dart';
import '../widgets/premium_gate.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  Future<void> _showScheduleDialog(
    BuildContext context,
    WidgetRef ref,
    profile,
  ) async {
    List<int> selectedDays = List<int>.from(profile.scheduledDaysList);

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: const Text('Training Schedule'),
            content: SingleChildScrollView(
              child: WorkoutDayScheduler(
                selectedDays: selectedDays,
                maxDays: profile.trainingDaysPerWeek,
                onChanged: (days) {
                  setState(() {
                    selectedDays = days;
                  });
                },
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: selectedDays.length == profile.trainingDaysPerWeek
                    ? () async {
                        final repo = ref.read(userProfileRepoProvider);
                        profile.scheduledDaysList = selectedDays;
                        profile.updatedAt = DateTime.now();
                        await repo.saveProfile(profile);
                        ref.invalidate(userProfileProvider);

                        if (context.mounted) {
                          Navigator.pop(ctx);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Workout schedule updated!'),
                            ),
                          );
                        }
                      }
                    : null,
                child: const Text('Save'),
              ),
            ],
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final profileAsync = ref.watch(userProfileProvider);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final analytics = ref.read(analyticsProvider);
      analytics.logSettingsViewed();
    });

    return Scaffold(
      body: SafeArea(
        child: profileAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text('Error: $e')),
          data: (profile) {
            if (profile == null) {
              return const Center(child: Text('No profile found'));
            }

            return SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 16),

                  // Header
                  Text(
                    'Settings',
                    style: theme.textTheme.displayMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      letterSpacing: -0.5,
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Profile Card
                  _ProfileCard(profile: profile),

                  const SizedBox(height: 24),

                  // Settings List
                  _SettingsTile(
                    icon: Icons.calendar_month_outlined,
                    title: 'Cycle tracking',
                    subtitle: profile.trackCycle ? 'Enabled' : 'Disabled',
                    onTap: () => Navigator.pushNamed(context, '/edit-profile'),
                  ),

                  if (profile.trackCycle)
                    _SettingsTile(
                      icon: Icons.sync_outlined,
                      title: 'Cycle length',
                      subtitle: '${profile.cycleLength} days',
                      onTap: () => Navigator.pushNamed(context, '/edit-profile'),
                    ),

                  _SettingsTile(
                    icon: Icons.flag_outlined,
                    title: 'Goal',
                    subtitle: _getGoalText(profile.goal),
                    onTap: () => Navigator.pushNamed(context, '/edit-profile'),
                  ),

                  _SettingsTile(
                    icon: Icons.signal_cellular_alt,
                    title: 'Experience',
                    subtitle: _getLevelText(profile.level),
                    onTap: () => Navigator.pushNamed(context, '/edit-profile'),
                  ),

                  _SettingsTile(
                    icon: Icons.calendar_today_outlined,
                    title: 'Training days',
                    subtitle: '${profile.trainingDaysPerWeek} per week',
                    onTap: () => _showScheduleDialog(context, ref, profile),
                  ),

                  _SettingsTile(
                    icon: Icons.healing_outlined,
                    title: 'Injuries & Limitations',
                    subtitle: profile.hasInjuries ? profile.injuryDisplayText : 'None',
                    onTap: () => Navigator.pushNamed(context, '/settings/injuries'),
                  ),

                  _SettingsTile(
                    icon: Icons.notifications_outlined,
                    title: 'Notifications',
                    subtitle: profile.notifyCheckIn || profile.notifyWorkout
                        ? 'Enabled'
                        : 'Disabled',
                    onTap: () => Navigator.pushNamed(context, '/settings/notifications'),
                  ),

                  _HealthPermissionTile(),

                  const SizedBox(height: 24),

                  // Premium Section
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Text(
                      'Premium',
                      style: theme.textTheme.titleSmall?.copyWith(
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),

                  _PremiumSection(profile: profile),

                  const SizedBox(height: 24),

                  // Support Section
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Text(
                      'Support',
                      style: theme.textTheme.titleSmall?.copyWith(
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),

                  _SettingsTile(
                    icon: Icons.help_outline,
                    title: 'Help & FAQ',
                    onTap: () => _showHelpDialog(context),
                  ),

                  _SettingsTile(
                    icon: Icons.feedback_outlined,
                    title: 'Send Feedback',
                    onTap: () => _showFeedbackDialog(context),
                  ),

                  _SettingsTile(
                    icon: Icons.info_outline,
                    title: 'About PrimeForm',
                    onTap: () => _showAboutDialog(context),
                  ),

                  const SizedBox(height: 24),

                  // Legal Section
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Text(
                      'Legal',
                      style: theme.textTheme.titleSmall?.copyWith(
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),

                  _SettingsTile(
                    icon: Icons.health_and_safety_outlined,
                    title: 'Medical Disclaimer',
                    onTap: () => _showFullDisclaimerDialog(context),
                  ),

                  _SettingsTile(
                    icon: Icons.description_outlined,
                    title: 'Terms of Service',
                    onTap: () => _showTermsDialog(context),
                  ),

                  _SettingsTile(
                    icon: Icons.privacy_tip_outlined,
                    title: 'Privacy Policy',
                    onTap: () => _showPrivacyDialog(context),
                  ),

                  const SizedBox(height: 32),

                  // Logo + Version Info
                  Center(
                    child: Column(
                      children: [
                        SvgPicture.asset(
                          'assets/logo/primeform_logo.svg',
                          width: 48,
                          height: 48,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'PrimeForm v1.0.0',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: AppColors.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 32),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  String _getGoalText(String goal) {
    switch (goal) {
      case 'cut':
        return 'Fat Loss';
      case 'recomp':
        return 'Recomposition';
      case 'bulk':
        return 'Muscle Gain';
      default:
        return goal;
    }
  }

  String _getLevelText(String level) {
    switch (level) {
      case 'beginner':
        return 'Beginner';
      case 'intermediate':
        return 'Intermediate';
      case 'advanced':
        return 'Advanced';
      default:
        return level;
    }
  }

  static void showRedeemCodeDialog(BuildContext context, WidgetRef ref) {
    final codeController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Enter Code'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Enter a promo or gift code to unlock premium features.',
              style: TextStyle(
                fontSize: 13,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: codeController,
              textCapitalization: TextCapitalization.characters,
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z0-9]')),
                UpperCaseTextFormatter(),
              ],
              decoration: InputDecoration(
                hintText: 'e.g. PRIMEFORM2025',
                prefixIcon: const Icon(Icons.card_giftcard_outlined),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: AppColors.surfaceVariant,
              ),
              autofocus: true,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              final code = codeController.text.trim();
              if (code.isEmpty) return;

              final service = PremiumService();
              final tier = service.redeemPromoCode(code);

              if (tier != null) {
                final tierName =
                    tier == PremiumTier.premium ? 'premium' : 'essentials';
                final repo = ref.read(userProfileRepoProvider);
                await repo.updatePremiumTier(tierName);
                ref.invalidate(premiumAccessProvider);
                ref.invalidate(userProfileProvider);

                if (ctx.mounted) Navigator.pop(ctx);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        '${tierName[0].toUpperCase()}${tierName.substring(1)} unlocked!',
                      ),
                      backgroundColor: AppColors.primary,
                    ),
                  );
                }
              } else {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                          'Invalid code. Please check and try again.'),
                    ),
                  );
                }
              }
            },
            child: const Text('Redeem'),
          ),
        ],
      ),
    );
  }

  void _showFullDisclaimerDialog(BuildContext context) {
    final analytics = AnalyticsService();
    analytics.logMedicalDisclaimerViewed();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.health_and_safety, color: Colors.orange.shade700),
            const SizedBox(width: 8),
            const Text('Medical Disclaimer'),
          ],
        ),
        content: const SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'IMPORTANT: READ CAREFULLY',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 12),
              Text(
                'PrimeForm provides fitness guidance, NOT medical advice. Always consult your healthcare provider before starting any exercise program.',
              ),
              SizedBox(height: 12),
              Text(
                'Consult a doctor if you:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Text('• Are pregnant or post-partum'),
              Text('• Have pre-existing medical conditions'),
              Text('• Experience pain or discomfort'),
              Text('• Have pelvic floor concerns'),
              SizedBox(height: 12),
              Text(
                'PrimeForm is not a substitute for professional medical advice, diagnosis, or treatment.',
                style: TextStyle(fontStyle: FontStyle.italic),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('I Understand'),
          ),
        ],
      ),
    );
  }

  void _showHelpDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Help & FAQ'),
        content: const SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Q: Why is my plan locked for 14 days?',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              SizedBox(height: 4),
              Text(
                'Consistency is key. The lock helps you stick with your plan long enough to see real results.',
              ),
              SizedBox(height: 16),
              Text(
                'Q: When can I adjust my plan?',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              SizedBox(height: 4),
              Text(
                'Use the AI Coach feature after 7 days to make data-driven adjustments.',
              ),
              SizedBox(height: 16),
              Text(
                'Q: Is this safe for post-partum?',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              SizedBox(height: 4),
              Text(
                'Only after medical clearance. Always follow your doctor\'s advice.',
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showFeedbackDialog(BuildContext context) {
    final uri = Uri(
      scheme: 'mailto',
      path: 'kineticiq.ai@gmail.com',
      query: 'subject=PrimeForm Feedback',
    );
    launchUrl(uri);
  }

  void _showAboutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        content: SingleChildScrollView(
          child: Column(
            children: [
              const SizedBox(height: 8),
              SvgPicture.asset(
                'assets/logo/primeform_logo.svg',
                width: 64,
                height: 64,
              ),
              const SizedBox(height: 12),
              const Text(
                'PrimeForm',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'v1.0.0',
                style: TextStyle(color: AppColors.textMuted, fontSize: 13),
              ),
              const SizedBox(height: 16),
              const Text(
                'The smart fitness app that understands women\'s bodies.',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Features:', style: TextStyle(fontWeight: FontWeight.w600)),
                  Text('• Cycle-aware training'),
                  Text('• Post-partum safe progression'),
                  Text('• AI coaching'),
                  Text('• Personalized nutrition plans'),
                ],
              ),
              const SizedBox(height: 12),
              const Text(
                'Built with science, designed for real bodies.',
                style: TextStyle(fontStyle: FontStyle.italic, color: AppColors.textSecondary),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              const Text(
                'kineticiq.ai@gmail.com',
                style: TextStyle(fontSize: 12, color: AppColors.textMuted),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showTermsDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Terms of Service'),
        content: const SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Last Updated: January 2025',
                style: TextStyle(fontStyle: FontStyle.italic, fontSize: 12),
              ),
              SizedBox(height: 16),
              Text(
                '1. Acceptance of Terms',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Text(
                'By using PrimeForm, you agree to these Terms of Service. If you do not agree, please do not use the app.',
              ),
              SizedBox(height: 16),
              Text(
                '2. Description of Service',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Text(
                'PrimeForm provides fitness guidance, workout plans, nutrition tracking, and AI coaching features. The service is intended for general fitness purposes only.',
              ),
              SizedBox(height: 16),
              Text(
                '3. Not Medical Advice',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Text(
                'PrimeForm is NOT a substitute for professional medical advice, diagnosis, or treatment. Always consult your healthcare provider before starting any exercise or nutrition program.',
              ),
              SizedBox(height: 16),
              Text(
                '4. User Responsibilities',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Text('You agree to:'),
              Text('• Provide accurate information about your health'),
              Text('• Use the app responsibly'),
              Text('• Not rely solely on the app for health decisions'),
              Text('• Stop exercising if you experience pain or discomfort'),
              SizedBox(height: 16),
              Text(
                '5. Limitation of Liability',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Text(
                'PrimeForm and its creators are not liable for any injuries, health issues, or damages arising from use of the app. Use at your own risk.',
              ),
              SizedBox(height: 16),
              Text(
                '6. Changes to Terms',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Text(
                'We may update these terms at any time. Continued use of the app constitutes acceptance of updated terms.',
              ),
              SizedBox(height: 16),
              Text(
                '7. Contact',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Text(
                'For questions about these terms, please contact us through the app\'s feedback feature.',
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showPrivacyDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Privacy Policy'),
        content: const SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Last Updated: January 2025',
                style: TextStyle(fontStyle: FontStyle.italic, fontSize: 12),
              ),
              SizedBox(height: 16),
              Text(
                '1. Information We Collect',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Text('We collect information you provide directly:'),
              Text('• Profile data (age, sex, height, weight)'),
              Text('• Health information (cycle data, injuries)'),
              Text('• Fitness data (workouts, check-ins, meals)'),
              Text('• App usage analytics'),
              SizedBox(height: 16),
              Text(
                '2. How We Use Your Information',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Text('Your data is used to:'),
              Text('• Generate personalized workout and nutrition plans'),
              Text('• Provide AI coaching recommendations'),
              Text('• Track your progress'),
              Text('• Improve app features'),
              SizedBox(height: 16),
              Text(
                '3. Data Storage',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Text(
                'Your data is stored locally on your device and in secure cloud services (Firebase). We use industry-standard security measures to protect your information.',
              ),
              SizedBox(height: 16),
              Text(
                '4. Data Sharing',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Text(
                'We do NOT sell your personal data. We may share anonymized, aggregated data for analytics purposes only.',
              ),
              SizedBox(height: 16),
              Text(
                '5. Your Rights',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Text('You have the right to:'),
              Text('• Access your data'),
              Text('• Correct inaccurate data'),
              Text('• Delete your data'),
              Text('• Export your data'),
              SizedBox(height: 16),
              Text(
                '6. Analytics',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Text(
                'We use Firebase Analytics to understand app usage patterns. This helps us improve the app experience. Analytics data is anonymized and aggregated.',
              ),
              SizedBox(height: 16),
              Text(
                '7. Children\'s Privacy',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Text(
                'PrimeForm is not intended for users under 18. We do not knowingly collect data from children.',
              ),
              SizedBox(height: 16),
              Text(
                '8. Contact Us',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Text(
                'For privacy concerns, please contact us through the app\'s feedback feature.',
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}

/// Profile card matching Figma design
class _ProfileCard extends StatelessWidget {
  final dynamic profile;

  const _ProfileCard({required this.profile});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Profile header
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppColors.primary,
                      AppColors.seasonAccent,
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.auto_awesome,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Profile',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      '${profile.sex == 'male' ? 'Male' : 'Female'} • ${profile.age}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: () => Navigator.pushNamed(context, '/edit-profile'),
                icon: const Icon(Icons.edit_outlined),
                color: AppColors.textSecondary,
              ),
            ],
          ),

          const SizedBox(height: 20),

          // Stats row
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceVariant,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      Text(
                        '${profile.heightCm}',
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'cm',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceVariant,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      Text(
                        profile.weightKg.toStringAsFixed(1),
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'kg',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Settings tile matching Figma design
class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback onTap;

  const _SettingsTile({
    required this.icon,
    required this.title,
    this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        leading: Icon(icon, color: AppColors.textSecondary),
        title: Text(
          title,
          style: theme.textTheme.bodyLarge?.copyWith(
            fontWeight: FontWeight.w500,
          ),
        ),
        subtitle: subtitle != null
            ? Text(
                subtitle!,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: AppColors.textSecondary,
                ),
              )
            : null,
        trailing: const Icon(
          Icons.chevron_right,
          color: AppColors.textMuted,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
    );
  }
}

/// Premium section: tier-aware, shows subscription management + navigable tiles
class _PremiumSection extends ConsumerWidget {
  final dynamic profile;

  const _PremiumSection({required this.profile});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final accessAsync = ref.watch(premiumAccessProvider);
    final access = accessAsync.valueOrNull;

    if (access == null) return const SizedBox.shrink();

    // State 1: Active subscription
    if (access.type == PremiumAccessType.premium) {
      return _buildSubscribedSection(context, ref, access);
    }

    // State 2: Active trial
    if (access.type == PremiumAccessType.trial) {
      return _buildTrialSection(context, ref, access);
    }

    // State 3: Expired trial or no access — show paywall CTA + feature cards
    return _buildNoAccessSection(context, ref);
  }

  Widget _buildSubscribedSection(
      BuildContext context, WidgetRef ref, PremiumAccessStatus access) {
    final tierName = access.tier == PremiumTier.premium ? 'Premium' : 'Essentials';

    return Column(
      children: [
        // Subscription status card
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: access.tier == PremiumTier.premium
                  ? [AppColors.seasonAccent, AppColors.seasonAccent.withOpacity(0.8)]
                  : [AppColors.primary, AppColors.primary.withOpacity(0.8)],
            ),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              const Icon(Icons.star, color: Colors.white, size: 24),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$tierName Plan',
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      'All ${tierName.toLowerCase()} features unlocked',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.white.withOpacity(0.85),
                      ),
                    ),
                  ],
                ),
              ),
              if (access.tier == PremiumTier.essentials)
                TextButton(
                  onPressed: () => Navigator.pushNamed(
                    context,
                    '/paywall',
                    arguments: {'highlightTier': 'premium'},
                  ),
                  style: TextButton.styleFrom(
                    backgroundColor: Colors.white.withOpacity(0.2),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text('Upgrade', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                ),
            ],
          ),
        ),

        // Manage subscription
        _SettingsTile(
          icon: Icons.credit_card_outlined,
          title: 'Manage Subscription',
          subtitle: 'Change plan or cancel',
          onTap: () async {
            final service = ref.read(premiumServiceProvider);
            final url = await service.getManagementUrl();
            if (url != null && context.mounted) {
              launchUrl(Uri.parse(url));
            }
          },
        ),

        // Restore purchases
        _SettingsTile(
          icon: Icons.restore,
          title: 'Restore Purchases',
          subtitle: 'Recover your subscription',
          onTap: () async {
            try {
              final service = ref.read(premiumServiceProvider);
              await service.restorePurchases();
              ref.invalidate(premiumAccessProvider);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Purchases restored'),
                    backgroundColor: AppColors.primary,
                  ),
                );
              }
            } catch (e) {
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Restore failed: $e')),
                );
              }
            }
          },
        ),

        _SettingsTile(
          icon: Icons.card_giftcard_outlined,
          title: 'Enter Code',
          subtitle: 'Redeem a promo or gift code',
          onTap: () => SettingsScreen.showRedeemCodeDialog(context, ref),
        ),

        const SizedBox(height: 8),

        // Show navigable tiles for features user CAN access
        ..._buildFeatureTiles(context, access),
      ],
    );
  }

  Widget _buildTrialSection(
      BuildContext context, WidgetRef ref, PremiumAccessStatus access) {
    return Column(
      children: [
        // Trial status card
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: AppColors.seasonAccent.withOpacity(0.1),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.seasonAccent.withOpacity(0.3)),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.seasonAccent.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.timer_outlined,
                    color: AppColors.seasonAccent, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Free Trial Active',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    Text(
                      '${access.trialDaysRemaining} days remaining',
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.seasonAccent,
                      ),
                    ),
                  ],
                ),
              ),
              TextButton(
                onPressed: () => Navigator.pushNamed(context, '/paywall'),
                style: TextButton.styleFrom(
                  backgroundColor: AppColors.seasonAccent,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: const Text('Subscribe',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
              ),
            ],
          ),
        ),

        // All feature tiles during trial (trial = all access)
        ..._buildAllFeatureTiles(context),

        _SettingsTile(
          icon: Icons.card_giftcard_outlined,
          title: 'Enter Code',
          subtitle: 'Redeem a promo or gift code',
          onTap: () => SettingsScreen.showRedeemCodeDialog(context, ref),
        ),
      ],
    );
  }

  Widget _buildNoAccessSection(BuildContext context, WidgetRef ref) {
    return Column(
      children: [
        // Go Premium card
        GestureDetector(
          onTap: () => Navigator.pushNamed(context, '/paywall'),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.seasonAccent,
                  AppColors.seasonAccent.withOpacity(0.8),
                ],
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: const Icon(Icons.star, color: Colors.white, size: 24),
                ),
                const SizedBox(width: 16),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Go Premium',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'Unlock all features starting at \$4.99/mo',
                        style: TextStyle(fontSize: 13, color: Colors.white70),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right, color: Colors.white),
              ],
            ),
          ),
        ),

        // Feature preview cards
        PremiumFeatureCard(
          feature: PremiumFeature.aiCoaching,
          icon: Icons.smart_toy_outlined,
          title: 'AI Coach',
          description: 'Personalized AI coaching conversations',
        ),
        const SizedBox(height: 8),
        PremiumFeatureCard(
          feature: PremiumFeature.progressPhotos,
          icon: Icons.camera_outlined,
          title: 'Progress Photos',
          description: 'AI body analysis and achievable celeb comparisons',
        ),
        const SizedBox(height: 8),
        PremiumFeatureCard(
          feature: PremiumFeature.customWorkouts,
          icon: Icons.edit_note_outlined,
          title: 'Custom Workouts',
          description: 'Build your own workout routines from scratch',
        ),
        const SizedBox(height: 8),
        PremiumFeatureCard(
          feature: PremiumFeature.exportData,
          icon: Icons.download_outlined,
          title: 'Export Data',
          description: 'Export your progress data as CSV or PDF',
        ),

        const SizedBox(height: 12),
        _SettingsTile(
          icon: Icons.card_giftcard_outlined,
          title: 'Enter Code',
          subtitle: 'Redeem a promo or gift code',
          onTap: () => SettingsScreen.showRedeemCodeDialog(context, ref),
        ),
      ],
    );
  }

  List<Widget> _buildFeatureTiles(
      BuildContext context, PremiumAccessStatus access) {
    final tiles = <Widget>[];

    // AI features (premium tier)
    if (access.canAccessFeature(PremiumFeature.aiCoaching)) {
      tiles.add(_SettingsTile(
        icon: Icons.smart_toy_outlined,
        title: 'AI Coach',
        subtitle: 'Chat with your personal coach',
        onTap: () => Navigator.pushNamed(context, '/ai-coaching'),
      ));
    }

    if (access.canAccessFeature(PremiumFeature.progressPhotos)) {
      tiles.add(_SettingsTile(
        icon: Icons.camera_outlined,
        title: 'Progress Photos',
        subtitle: 'AI body analysis & tracking',
        onTap: () => Navigator.pushNamed(context, '/progress-photos'),
      ));
    }

    if (access.canAccessFeature(PremiumFeature.cyclePredictions) &&
        profile.trackCycle) {
      tiles.add(_SettingsTile(
        icon: Icons.auto_graph_outlined,
        title: 'Cycle Insights',
        subtitle: 'AI predictions & symptom logging',
        onTap: () => Navigator.pushNamed(context, '/cycle-insights'),
      ));
    }

    // Essentials features
    if (access.canAccessFeature(PremiumFeature.customWorkouts)) {
      tiles.add(_SettingsTile(
        icon: Icons.edit_note_outlined,
        title: 'Custom Workouts',
        subtitle: 'Build your own training plans',
        onTap: () => Navigator.pushNamed(context, '/saved-templates'),
      ));
    }

    if (access.canAccessFeature(PremiumFeature.exportData)) {
      tiles.add(_SettingsTile(
        icon: Icons.download_outlined,
        title: 'Export Data',
        subtitle: 'CSV spreadsheet or PDF report',
        onTap: () => Navigator.pushNamed(context, '/export-data'),
      ));
    }

    return tiles;
  }

  List<Widget> _buildAllFeatureTiles(BuildContext context) {
    return [
      _SettingsTile(
        icon: Icons.smart_toy_outlined,
        title: 'AI Coach',
        subtitle: 'Chat with your personal coach',
        onTap: () => Navigator.pushNamed(context, '/ai-coaching'),
      ),
      _SettingsTile(
        icon: Icons.camera_outlined,
        title: 'Progress Photos',
        subtitle: 'AI body analysis & tracking',
        onTap: () => Navigator.pushNamed(context, '/progress-photos'),
      ),
      if (profile.trackCycle)
        _SettingsTile(
          icon: Icons.auto_graph_outlined,
          title: 'Cycle Insights',
          subtitle: 'AI predictions & symptom logging',
          onTap: () => Navigator.pushNamed(context, '/cycle-insights'),
        ),
      _SettingsTile(
        icon: Icons.edit_note_outlined,
        title: 'Custom Workouts',
        subtitle: 'Build your own training plans',
        onTap: () => Navigator.pushNamed(context, '/saved-templates'),
      ),
      _SettingsTile(
        icon: Icons.download_outlined,
        title: 'Export Data',
        subtitle: 'CSV spreadsheet or PDF report',
        onTap: () => Navigator.pushNamed(context, '/export-data'),
      ),
    ];
  }
}

class _HealthPermissionTile extends ConsumerStatefulWidget {
  @override
  ConsumerState<_HealthPermissionTile> createState() => _HealthPermissionTileState();
}

class _HealthPermissionTileState extends ConsumerState<_HealthPermissionTile> {
  bool? _authorized;

  @override
  void initState() {
    super.initState();
    _checkAuth();
  }

  Future<void> _checkAuth() async {
    final service = ref.read(stepTrackingServiceProvider);
    final auth = await service.isAuthorized();
    if (mounted) setState(() => _authorized = auth);
  }

  Future<void> _requestPermission() async {
    final service = ref.read(stepTrackingServiceProvider);
    final granted = await service.requestPermissions();
    if (mounted) {
      setState(() => _authorized = granted);
      if (granted) {
        ref.invalidate(todayStepsProvider);
        ref.invalidate(weeklyStepsProvider);
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(granted
              ? 'Health data access granted'
              : 'Permission denied — you can enable it in device settings'),
          backgroundColor: granted ? AppColors.primary : AppColors.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final subtitle = _authorized == null
        ? 'Checking...'
        : _authorized!
            ? 'Connected'
            : 'Not connected';

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        onTap: _requestPermission,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        leading: const Icon(Icons.favorite_outline, color: AppColors.textSecondary),
        title: Text(
          'Health Data',
          style: theme.textTheme.bodyLarge?.copyWith(
            fontWeight: FontWeight.w500,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: theme.textTheme.bodySmall?.copyWith(
            color: _authorized == true ? AppColors.primary : AppColors.textSecondary,
          ),
        ),
        trailing: _authorized == true
            ? const Icon(Icons.check_circle, color: AppColors.primary, size: 20)
            : const Icon(Icons.chevron_right, color: AppColors.textMuted),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
    );
  }
}

/// Text input formatter that converts input to uppercase
class UpperCaseTextFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    return TextEditingValue(
      text: newValue.text.toUpperCase(),
      selection: newValue.selection,
    );
  }
}
