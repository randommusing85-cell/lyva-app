import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';

import 'firebase_options.dart';
import 'services/premium_service.dart';
import 'theme/app_theme.dart';
import 'screens/app_shell.dart';
import 'screens/plan_screen.dart';
import 'screens/checkin_screen.dart';
import 'screens/my_plan_screen.dart';
import 'screens/workout_plan_screen.dart';
import 'screens/my_workout_plan_screen.dart';
import 'screens/today_workout_screen.dart';
import 'screens/onboarding_screen.dart';
import 'screens/setup_guide_screen.dart';
import 'screens/nutrition_screen.dart';
import 'screens/trends_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/injury_settings_screen.dart';
import 'screens/notification_settings_screen.dart';
import 'services/notification_service.dart';
import 'screens/edit_profile_screen.dart';
import 'screens/workout_coach_screen.dart';
import 'screens/guided_setup_flow_screen.dart';
import 'screens/splash_screen.dart';
import 'screens/ai_coaching_screen.dart';
import 'screens/progress_photos_screen.dart';
import 'screens/progress_photo_detail_screen.dart';
import 'screens/cycle_insights_screen.dart';
import 'screens/advanced_analytics_screen.dart';
import 'screens/export_data_screen.dart';
import 'screens/saved_templates_screen.dart';
import 'screens/custom_workout_builder_screen.dart';
import 'screens/exercise_picker_screen.dart';
import 'screens/paywall_screen.dart';
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  
  // Initialize notification service
  await NotificationService().init();

  // Initialize RevenueCat for in-app subscriptions
  await PremiumService.initRevenueCat(
    apiKey: Platform.isIOS
        ? 'appl_icVfBrmPmXeRDAIXaAEklUtTArq'
        : 'goog_YOUR_ANDROID_REVENUECAT_KEY', // Replace with your Android key
  );

  runApp(const ProviderScope(child: LyvaApp()));
}

class LyvaApp extends ConsumerWidget {
  const LyvaApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp(
      title: 'Lyva',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: const SplashScreen(),
      routes: {
        '/home': (context) => const AppShell(),
        '/onboarding': (context) => const OnboardingScreen(),
        '/plan': (context) => const PlanScreen(),
        '/checkin': (context) => const CheckInScreen(),
        '/myplan': (context) => const MyPlanScreen(),
        '/workout': (context) => const WorkoutPlanScreen(),
        '/my-workout': (context) => const MyWorkoutPlanScreen(),
        '/today-workout': (context) => const TodayWorkoutScreen(),
        '/setup-guide': (context) => const SetupGuideScreen(),
        '/nutrition': (context) => const NutritionScreen(),
        '/trends': (context) => const TrendsScreen(),
        '/settings': (context) => const SettingsScreen(),
        '/settings/injuries': (context) => const InjurySettingsScreen(),
        '/settings/notifications': (context) => const NotificationSettingsScreen(),
        '/edit-profile': (context) => const EditProfileScreen(),
        '/workout-coach': (context) => const WorkoutCoachScreen(),
        '/guided-setup': (context) => const GuidedSetupFlowScreen(),
        '/ai-coaching': (context) => const AiCoachingScreen(),
        '/progress-photos': (context) => const ProgressPhotosScreen(),
        '/progress-photo-detail': (context) => const ProgressPhotoDetailScreen(),
        '/cycle-insights': (context) => const CycleInsightsScreen(),
        '/advanced-analytics': (context) => const AdvancedAnalyticsScreen(),
        '/export-data': (context) => const ExportDataScreen(),
        '/saved-templates': (context) => const SavedTemplatesScreen(),
        '/custom-workout-builder': (context) => const CustomWorkoutBuilderScreen(),
        '/exercise-picker': (context) => const ExercisePickerScreen(),
        '/paywall': (context) {
          final args = ModalRoute.of(context)?.settings.arguments;
          PremiumTier? highlightTier;
          if (args is Map) {
            final tierStr = args['highlightTier'];
            if (tierStr == 'premium') highlightTier = PremiumTier.premium;
            if (tierStr == 'essentials') highlightTier = PremiumTier.essentials;
          }
          return PaywallScreen(highlightTier: highlightTier);
        },
      },
    );
  }
}

