import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../theme/app_theme.dart';
import '../state/providers.dart';
import '../services/notification_service.dart';
import '../services/analytics_service.dart';
import '../services/premium_service.dart';
import 'onboarding_screen.dart';
import 'app_shell.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeIn;
  late Animation<double> _logoScale;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    _fadeIn = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
      ),
    );

    _logoScale = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
      ),
    );

    _controller.forward();

    // Track app opened
    final analytics = AnalyticsService();
    analytics.logAppOpened();

    // Navigate after splash
    _initializeAndNavigate();
  }

  Future<void> _initializeAndNavigate() async {
    // Minimum splash duration for branding
    await Future.delayed(const Duration(milliseconds: 2000));

    // TODO: Future - load AI context/history here before navigating
    // e.g. await aiMemoryService.loadUserContext();

    if (!mounted) return;

    // Wait for profile to be available
    final profile = await ref.read(userProfileProvider.future);

    if (!mounted) return;

    if (profile == null) {
      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          pageBuilder: (_, __, ___) => const OnboardingScreen(),
          transitionsBuilder: (_, animation, __, child) {
            return FadeTransition(opacity: animation, child: child);
          },
          transitionDuration: const Duration(milliseconds: 500),
        ),
      );
    } else {
      NotificationService().setupNotifications(profile);

      // Check if monthly usage counters need a reset
      if (PremiumService.checkAndResetUsageIfNeeded(profile)) {
        final repo = ref.read(userProfileRepoProvider);
        await repo.saveProfile(profile);
      }

      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          pageBuilder: (_, __, ___) => const AppShell(),
          transitionsBuilder: (_, animation, __, child) {
            return FadeTransition(opacity: animation, child: child);
          },
          transitionDuration: const Duration(milliseconds: 500),
        ),
      );
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Center(
        child: FadeTransition(
          opacity: _fadeIn,
          child: ScaleTransition(
            scale: _logoScale,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // App logo icon only
                SvgPicture.asset(
                  'assets/logo/Lyva/splash-screen.svg',
                  width: 100,
                  height: 100,
                ),

                const SizedBox(height: 24),

                // App name in styled text
                const Text(
                  'Lyva',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                    letterSpacing: -0.5,
                  ),
                ),

                const SizedBox(height: 8),

                // Tagline
                const Text(
                  'Your AI Fitness Companion',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                    color: AppColors.textSecondary,
                  ),
                ),

                const SizedBox(height: 48),

                // Loading indicator
                SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    color: AppColors.primary.withOpacity(0.6),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
