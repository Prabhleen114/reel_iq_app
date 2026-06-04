import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'core/navigation/app_router.dart';
import 'core/services/mock_config.dart';
import 'core/services/firestore_service.dart';
import 'core/services/analytics_service.dart';
import 'core/services/crashlytics_service.dart';
import 'core/services/subscription_service.dart';
import 'core/theme/app_theme.dart';

// ViewModels
import 'features/auth/presentation/viewmodels/auth_viewmodel.dart';
import 'features/dashboard/presentation/viewmodels/dashboard_viewmodel.dart';
import 'features/analysis/presentation/viewmodels/analysis_viewmodel.dart';
import 'features/reel_upload/presentation/viewmodels/upload_viewmodel.dart';
import 'features/hook_testing/presentation/viewmodels/hook_testing_viewmodel.dart';
import 'features/profile/presentation/viewmodels/profile_viewmodel.dart';
import 'features/instagram/data/services/instagram_service.dart';
import 'features/instagram/data/services/reel_analysis_service.dart';
import 'features/instagram/data/services/creator_analysis_service.dart';
import 'features/instagram/presentation/viewmodels/instagram_viewmodel.dart';

// Repositories
import 'features/auth/data/repositories/auth_repository.dart';
import 'features/dashboard/data/repositories/analysis_repository.dart';
import 'features/hook_testing/data/repositories/hook_testing_repository.dart';
import 'features/analysis/data/services/analysis_api_service.dart';
import 'features/dashboard/data/services/planner_api_service.dart';
import 'features/dashboard/presentation/viewmodels/planner_viewmodel.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // ─── Crashlytics + Firebase Initialisation ──────────────────────────────
  final crashlyticsService = CrashlyticsService();

  try {
    await Firebase.initializeApp();
    MockConfig.useMockMode = false;
    debugPrint('ReelIQ: Live Firebase initialisation successful.');
  } catch (e) {
    MockConfig.useMockMode = true;
    debugPrint(
        'ReelIQ Warning: Firebase unavailable — running in Offline Mock Mode.');
    debugPrint(e.toString());
  }

  // Wire Flutter errors to Crashlytics (no-op in mock mode)
  await crashlyticsService.initialize();

  // ─── Core Services ───────────────────────────────────────────────────────
  final firestoreService = FirestoreService();
  final analyticsService = AnalyticsService();
  final subscriptionService = createSubscriptionService();
  await subscriptionService.initialize();

  // ─── Repository Layer ────────────────────────────────────────────────────
  final authRepository = AuthRepository(firestoreService);
  final apiService = AnalysisApiService();
  final analysisRepository = AnalysisRepository(apiService);
  final hookTestingRepository = HookTestingRepository();
  final instagramService = MockInstagramService();
  final reelAnalysisService = MockReelAnalysisService(apiService);
  final creatorAnalysisService = MockCreatorAnalysisService();
  final plannerApiService = PlannerApiService();

  runApp(
    MultiProvider(
      providers: [
        // ─── Core Services (Provider, not ChangeNotifier) ───
        Provider<FirestoreService>.value(value: firestoreService),
        Provider<AnalyticsService>.value(value: analyticsService),
        Provider<CrashlyticsService>.value(value: crashlyticsService),

        // ─── Subscription (ChangeNotifier) ──────────────────
        ChangeNotifierProvider<SubscriptionService>.value(
          value: subscriptionService,
        ),

        // ─── Repositories ───────────────────────────────────
        Provider<AuthRepository>.value(value: authRepository),
        Provider<AnalysisApiService>.value(value: apiService),
        Provider<AnalysisRepository>.value(value: analysisRepository),
        Provider<HookTestingRepository>.value(value: hookTestingRepository),
        Provider<InstagramService>.value(value: instagramService),
        Provider<ReelAnalysisService>.value(value: reelAnalysisService),
        Provider<CreatorAnalysisService>.value(value: creatorAnalysisService),
        Provider<PlannerApiService>.value(value: plannerApiService),

        // ─── ViewModels ─────────────────────────────────────
        ChangeNotifierProvider<AuthViewModel>(
          create: (context) => AuthViewModel(authRepository),
        ),
        ChangeNotifierProvider<DashboardViewModel>(
          create: (context) => DashboardViewModel(analysisRepository),
        ),
        ChangeNotifierProvider<AnalysisViewModel>(
          create: (context) => AnalysisViewModel(analysisRepository),
        ),
        ChangeNotifierProvider<UploadViewModel>(
          create: (context) => UploadViewModel(analysisRepository),
        ),
        ChangeNotifierProvider<HookTestingViewModel>(
          create: (context) => HookTestingViewModel(hookTestingRepository),
        ),
        ChangeNotifierProvider<ProfileViewModel>(
          create: (context) => ProfileViewModel(),
        ),
        ChangeNotifierProvider<InstagramViewModel>(
          create: (context) => InstagramViewModel(
            instagramService,
            reelAnalysisService,
            creatorAnalysisService,
          ),
        ),
        ChangeNotifierProvider<PlannerViewModel>(
          create: (context) => PlannerViewModel(plannerApiService),
        ),
      ],
      child: const ReelIQApp(),
    ),
  );
}

class ReelIQApp extends StatelessWidget {
  const ReelIQApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'ReelIQ',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      themeMode: ThemeMode.dark,
      routerConfig: AppRouter.router,
    );
  }
}
