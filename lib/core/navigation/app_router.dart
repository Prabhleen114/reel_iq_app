import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../features/auth/presentation/viewmodels/auth_viewmodel.dart';
import '../../features/auth/presentation/views/splash_screen.dart';
import '../../features/auth/presentation/views/login_screen.dart';
import '../../features/auth/presentation/views/signup_screen.dart';
import '../../features/dashboard/presentation/views/dashboard_screen.dart';
import '../../features/reel_upload/presentation/views/upload_reel_screen.dart';
import '../../features/analysis/presentation/views/analysis_result_screen.dart';
import '../../features/hook_testing/presentation/views/hook_testing_screen.dart';
import '../../features/profile/presentation/views/profile_screen.dart';
import '../../features/instagram/presentation/views/reel_inspector_screen.dart';
import '../../features/instagram/presentation/views/creator_analysis_view.dart';
import '../../features/instagram/presentation/views/instagram_profile_analysis_screen.dart';
import '../../features/instagram/presentation/views/instagram_library_view.dart';
import '../../features/instagram/presentation/views/instagram_username_analysis_screen.dart';
import '../../features/onboarding/views/onboarding_screen.dart';
import '../../features/reports/presentation/views/creator_report_screen.dart';

class AppRouter {
  static final GoRouter router = GoRouter(
    initialLocation: '/splash',
    redirect: (BuildContext context, GoRouterState state) {
      final authViewModel = Provider.of<AuthViewModel>(context, listen: false);
      final isLoggedIn = authViewModel.isLoggedIn;
      final isAuthRoute = state.matchedLocation == '/login' ||
          state.matchedLocation == '/signup';
      final isSplash = state.matchedLocation == '/splash';
      final isOnboarding = state.matchedLocation == '/onboarding';

      // Let splash and onboarding handle their own flow
      if (isSplash || isOnboarding) return null;

      if (!isLoggedIn && !isAuthRoute) {
        return '/login';
      }

      if (isLoggedIn && isAuthRoute) {
        return '/';
      }

      return null;
    },
    routes: <RouteBase>[
      GoRoute(
        path: '/splash',
        builder: (BuildContext context, GoRouterState state) {
          return const SplashScreen();
        },
      ),
      GoRoute(
        path: '/onboarding',
        builder: (BuildContext context, GoRouterState state) {
          return const OnboardingScreen();
        },
      ),
      GoRoute(
        path: '/login',
        builder: (BuildContext context, GoRouterState state) {
          return const LoginScreen();
        },
      ),
      GoRoute(
        path: '/signup',
        builder: (BuildContext context, GoRouterState state) {
          return const SignupScreen();
        },
      ),
      GoRoute(
        path: '/',
        builder: (BuildContext context, GoRouterState state) {
          return const DashboardScreen();
        },
      ),
      GoRoute(
        path: '/upload',
        builder: (BuildContext context, GoRouterState state) {
          return const UploadReelScreen();
        },
      ),
      GoRoute(
        path: '/analysis/:id',
        builder: (BuildContext context, GoRouterState state) {
          final reelId = state.pathParameters['id'] ?? '';
          return AnalysisResultScreen(reelId: reelId);
        },
      ),
      GoRoute(
        path: '/hook-testing',
        builder: (BuildContext context, GoRouterState state) {
          return const HookTestingScreen();
        },
      ),
      GoRoute(
        path: '/profile',
        builder: (BuildContext context, GoRouterState state) {
          return const ProfileScreen();
        },
      ),
      GoRoute(
        path: '/reel-inspector/:id',
        builder: (BuildContext context, GoRouterState state) {
          final reelId = state.pathParameters['id'] ?? '';
          return ReelInspectorScreen(reelId: reelId);
        },
      ),
      GoRoute(
        path: '/creator-analysis',
        builder: (BuildContext context, GoRouterState state) {
          return const CreatorAnalysisView();
        },
      ),
      GoRoute(
        path: '/creator-report/:userId',
        builder: (BuildContext context, GoRouterState state) {
          final userId = state.pathParameters['userId'] ?? '';
          return CreatorReportScreen(userId: userId);
        },
      ),
      GoRoute(
        path: '/instagram-analysis',
        builder: (BuildContext context, GoRouterState state) {
          return const InstagramProfileAnalysisScreen();
        },
      ),
      GoRoute(
        path: '/instagram',
        builder: (BuildContext context, GoRouterState state) {
          return const InstagramLibraryView();
        },
      ),
      GoRoute(
        path: '/public-instagram-analysis',
        builder: (BuildContext context, GoRouterState state) {
          return const InstagramUsernameAnalysisScreen();
        },
      ),
    ],
  );
}
