import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/analytics_service.dart';

/// Shows after onboarding to guide users through creating their first plans
class SetupGuideScreen extends ConsumerWidget {
  const SetupGuideScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    // Track analytics
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final analytics = AnalyticsService();
      analytics.logSetupGuideViewed();
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text('Get Started'),
        automaticallyImplyLeading: false,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Spacer(),

              // Success Icon
              Icon(
                Icons.check_circle_outline,
                size: 80,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(height: 24),

              // Title
              Text(
                'Profile Created!',
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),

              Text(
                'Now let\'s create your personalized plans',
                style: theme.textTheme.titleMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 32),

              // Setup Steps
              _SetupStep(
                number: '1',
                title: 'Create Your Nutrition Plan',
                description: 'AI will calculate your calories and macros',
                icon: Icons.restaurant_menu,
                theme: theme,
              ),
              const SizedBox(height: 16),

              _SetupStep(
                number: '2',
                title: 'Create Your Workout Plan',
                description: 'AI will design a training program for you',
                icon: Icons.fitness_center,
                theme: theme,
              ),
              const SizedBox(height: 16),

              _SetupStep(
                number: '3',
                title: 'Start Tracking',
                description: 'Log workouts and daily check-ins',
                icon: Icons.trending_up,
                theme: theme,
              ),

              const SizedBox(height: 32),

              // Philosophy Reminder
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.lightbulb_outline,
                      color: theme.colorScheme.secondary,
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Remember: Stick with your plan for at least 2 weeks before making changes.',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const Spacer(),

              // Action Buttons
              FilledButton(
                onPressed: () {
                  // Navigate to guided setup flow
                  Navigator.of(context).pushNamedAndRemoveUntil(
                    '/guided-setup',
                    (route) => false,
                  );
                },
                child: const Padding(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  child: Text('Let\'s Go!'),
                ),
              ),
              const SizedBox(height: 12),

              TextButton(
                onPressed: () {
                  final analytics = AnalyticsService();
                  analytics.logSetupGuideSkipped();
    
                  Navigator.of(context).pushNamedAndRemoveUntil(
                    '/',
                    (route) => false,
                  );
                },
                child: const Text('Skip, I\'ll do this later'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SetupStep extends StatelessWidget {
  final String number;
  final String title;
  final String description;
  final IconData icon;
  final ThemeData theme;

  const _SetupStep({
    required this.number,
    required this.title,
    required this.description,
    required this.icon,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: theme.colorScheme.outlineVariant),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: theme.colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Center(
              child: Text(
                number,
                style: theme.textTheme.titleMedium?.copyWith(
                  color: theme.colorScheme.onPrimaryContainer,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(icon, size: 18, color: theme.colorScheme.primary),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        title,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  description,
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
  }
}
