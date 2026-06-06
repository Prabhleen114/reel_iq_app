import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/glass_card.dart';
import '../../../auth/presentation/viewmodels/auth_viewmodel.dart';
import '../viewmodels/instagram_profile_analysis_viewmodel.dart';


class InstagramProfileAnalysisScreen extends StatefulWidget {
  const InstagramProfileAnalysisScreen({super.key});

  @override
  State<InstagramProfileAnalysisScreen> createState() => _InstagramProfileAnalysisScreenState();
}

class _InstagramProfileAnalysisScreenState extends State<InstagramProfileAnalysisScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authViewModel = Provider.of<AuthViewModel>(context, listen: false);
      if (authViewModel.user != null) {
        Provider.of<InstagramProfileAnalysisViewModel>(context, listen: false)
            .loadOrPerformAnalysis(authViewModel.user!.uid);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppTheme.textPrimary, size: 20),
          onPressed: () => context.pop(),
        ),
        title: const Text(
          'Profile Audit',
          style: TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.bold, fontSize: 18),
        ),
      ),
      body: Consumer<InstagramProfileAnalysisViewModel>(
        builder: (context, vm, child) {
          if (vm.isLoading) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: AppTheme.accent),
                  SizedBox(height: 16),
                  Text('Analyzing profile data...', style: TextStyle(color: AppTheme.textSecondary)),
                ],
              ),
            );
          }

          if (vm.errorMessage != null && vm.errorMessage!.contains('not connected')) {
            return _buildConnectState(context);
          }

          if (vm.errorMessage != null) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(32.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline, color: AppTheme.error, size: 48),
                    const SizedBox(height: 16),
                    Text(
                      vm.errorMessage!,
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: AppTheme.textPrimary),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: () {
                        final user = Provider.of<AuthViewModel>(context, listen: false).user;
                        if (user != null) {
                          vm.loadOrPerformAnalysis(user.uid);
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primary,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            );
          }

          if (vm.analysisResult == null) {
            return const Center(child: Text('No analysis found', style: TextStyle(color: AppTheme.textSecondary)));
          }

          final analysis = vm.analysisResult!;
          final profile = vm.profileData;
          final score = analysis['overall_score'] ?? 0;

          return RefreshIndicator(
            onRefresh: () async {
              final user = Provider.of<AuthViewModel>(context, listen: false).user;
              if (user != null) {
                await vm.loadOrPerformAnalysis(user.uid);
              }
            },
            color: AppTheme.accent,
            backgroundColor: AppTheme.cardBackground,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Profile Header
                  if (profile != null) ...[
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 36,
                          backgroundImage: profile['profile_picture_url'] != null
                              ? NetworkImage(profile['profile_picture_url'])
                              : null,
                          child: profile['profile_picture_url'] == null
                              ? const Icon(Icons.person, size: 36)
                              : null,
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                profile['username'] ?? 'Unknown',
                                style: const TextStyle(color: AppTheme.textPrimary, fontSize: 20, fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${profile['followers_count'] ?? 0} Followers',
                                style: const TextStyle(color: AppTheme.textSecondary, fontSize: 14),
                              ),
                            ],
                          ),
                        ),
                        _buildScoreBadge(score),
                      ],
                    ),
                    const SizedBox(height: 24),
                  ],

                  // Strengths & Weaknesses
                  _buildSectionTitle('Performance Snapshot'),
                  const SizedBox(height: 12),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: GlassCard(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Row(
                                children: [
                                  Icon(Icons.check_circle_rounded, color: AppTheme.success, size: 18),
                                  SizedBox(width: 8),
                                  Text('Strengths', style: TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.bold)),
                                ],
                              ),
                              const SizedBox(height: 12),
                              ...List<Widget>.from((analysis['strengths'] as List? ?? []).map((s) => _buildBullet(s))),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: GlassCard(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Row(
                                children: [
                                  Icon(Icons.warning_rounded, color: AppTheme.warning, size: 18),
                                  SizedBox(width: 8),
                                  Text('Weaknesses', style: TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.bold)),
                                ],
                              ),
                              const SizedBox(height: 12),
                              ...List<Widget>.from((analysis['weaknesses'] as List? ?? []).map((w) => _buildBullet(w))),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),
                  _buildSectionTitle('Growth Recommendations'),
                  const SizedBox(height: 12),
                  GlassCard(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: List<Widget>.from((analysis['growth_recommendations'] as List? ?? []).map((r) => Padding(
                        padding: const EdgeInsets.only(bottom: 8.0),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('👉 ', style: TextStyle(fontSize: 16)),
                            Expanded(child: Text(r, style: const TextStyle(color: AppTheme.textSecondary, height: 1.4))),
                          ],
                        ),
                      ))),
                    ),
                  ),

                  const SizedBox(height: 24),
                  _buildSectionTitle('Content Strategy'),
                  const SizedBox(height: 12),
                  GlassCard(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Suggested Pillars', style: TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: List<Widget>.from((analysis['suggested_content_pillars'] as List? ?? []).map((p) => Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: AppTheme.primary.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: AppTheme.primary.withOpacity(0.3)),
                            ),
                            child: Text(p, style: const TextStyle(color: AppTheme.primary, fontSize: 12)),
                          ))),
                        ),
                        const SizedBox(height: 20),
                        const Text('Reel Ideas', style: TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        ...List<Widget>.from((analysis['suggested_reel_ideas'] as List? ?? []).map((i) => Padding(
                          padding: const EdgeInsets.only(bottom: 6.0),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Icon(Icons.lightbulb_outline, color: AppTheme.accent, size: 16),
                              const SizedBox(width: 8),
                              Expanded(child: Text(i, style: const TextStyle(color: AppTheme.textSecondary))),
                            ],
                          ),
                        ))),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        color: AppTheme.textPrimary,
        fontSize: 18,
        fontWeight: FontWeight.w900,
      ),
    );
  }

  Widget _buildBullet(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 6, right: 8),
            width: 4,
            height: 4,
            decoration: const BoxDecoration(color: AppTheme.textMuted, shape: BoxShape.circle),
          ),
          Expanded(child: Text(text, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12))),
        ],
      ),
    );
  }

  Widget _buildScoreBadge(int score) {
    Color scoreColor = AppTheme.success;
    if (score < 50) scoreColor = AppTheme.error;
    else if (score < 75) scoreColor = AppTheme.warning;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: scoreColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: scoreColor.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Text(
            score.toString(),
            style: TextStyle(color: scoreColor, fontSize: 24, fontWeight: FontWeight.w900),
          ),
          Text(
            'SCORE',
            style: TextStyle(color: scoreColor, fontSize: 10, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildConnectState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: const Color(0xFFDD2A7B).withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.camera_alt, color: Color(0xFFDD2A7B), size: 48),
            ),
            const SizedBox(height: 24),
            const Text(
              'Connect Instagram',
              style: TextStyle(color: AppTheme.textPrimary, fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            const Text(
              'To analyze your profile and get AI-driven growth insights, you need to connect your official Meta Instagram account.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppTheme.textSecondary, height: 1.5),
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: () {
                // Navigate to the Instagram connection screen where Meta OAuth is handled.
                context.push('/instagram');
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFE1306C),
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Connect with Meta', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }
}
