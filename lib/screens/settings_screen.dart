import 'package:flutter/material.dart';
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

/// Premium section: shows navigable tiles when premium is active, otherwise feature cards
class _PremiumSection extends ConsumerWidget {
  final dynamic profile;

  const _PremiumSection({required this.profile});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final accessAsync = ref.watch(premiumAccessProvider);
    final hasAccess = accessAsync.valueOrNull?.hasAccess ?? false;

    if (hasAccess) {
      return Column(
        children: [
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
          PremiumFeatureCard(
            feature: PremiumFeature.exportData,
            icon: Icons.download_outlined,
            title: 'Export Data',
            description: 'Export your progress data to CSV',
          ),
        ],
      );
    }

    return Column(
      children: [
        PremiumFeatureCard(
          feature: PremiumFeature.progressPhotos,
          icon: Icons.camera_outlined,
          title: 'Progress Photos',
          description: 'AI body analysis and achievable celeb comparisons',
        ),
        const SizedBox(height: 8),
        PremiumFeatureCard(
          feature: PremiumFeature.cyclePredictions,
          icon: Icons.auto_graph_outlined,
          title: 'Cycle Predictions',
          description: 'AI-powered period predictions and training adjustments',
        ),
        const SizedBox(height: 8),
        PremiumFeatureCard(
          feature: PremiumFeature.exportData,
          icon: Icons.download_outlined,
          title: 'Export Data',
          description: 'Export your progress data to CSV',
        ),
      ],
    );
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
