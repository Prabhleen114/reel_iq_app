import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/glass_card.dart';
import '../../data/services/creator_analysis_service.dart';
import '../viewmodels/instagram_viewmodel.dart';

class CreatorAnalysisView extends StatefulWidget {
  const CreatorAnalysisView({super.key});

  @override
  State<CreatorAnalysisView> createState() => _CreatorAnalysisViewState();
}

class _CreatorAnalysisViewState extends State<CreatorAnalysisView> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final igVM = Provider.of<InstagramViewModel>(context, listen: false);
      if (igVM.isConnected && igVM.creatorAnalysis == null) {
        igVM.analyzeCreatorProfile();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final igVM = Provider.of<InstagramViewModel>(context);
    final size = MediaQuery.of(context).size;
    final isTablet = size.width > 600;

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('Creator Profile Audit'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () {
            context.pop();
          },
        ),
      ),
      body: igVM.isAnalyzingCreator && igVM.creatorAnalysis == null
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: AppTheme.primary),
                  SizedBox(height: 24),
                  Text(
                    'Running Creator Profile Audit...',
                    style: TextStyle(
                      color: AppTheme.textPrimary,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Scanning caption heuristics, post frequencies & engagement ratios.',
                    style: TextStyle(color: AppTheme.textMuted, fontSize: 12),
                  ),
                ],
              ),
            )
          : igVM.creatorAnalysis == null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.analytics_outlined, color: AppTheme.textMuted, size: 48),
                      const SizedBox(height: 16),
                      const Text(
                        'Connect your Instagram account to audit profile insights.',
                        style: TextStyle(color: AppTheme.textPrimary, fontSize: 15),
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton(
                        onPressed: () {
                          context.pop(); // Go back to Instagram connect tab
                        },
                        child: const Text('Go to Library'),
                      ),
                    ],
                  ),
                )
              : SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        maxWidth: isTablet ? 900 : double.infinity,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _buildCreatorScoreDashboard(igVM.creatorAnalysis!),
                          const SizedBox(height: 24),
                          if (isTablet)
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: _buildNicheCard(igVM.creatorAnalysis!),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: _buildMetricsBreakdown(igVM.creatorAnalysis!),
                                ),
                              ],
                            )
                          else ...[
                            _buildNicheCard(igVM.creatorAnalysis!),
                            const SizedBox(height: 20),
                            _buildMetricsBreakdown(igVM.creatorAnalysis!),
                          ],
                          const SizedBox(height: 24),
                          _buildRecommendationsSection(igVM.creatorAnalysis!),
                          const SizedBox(height: 48),
                        ],
                      ),
                    ),
                  ),
                ),
    );
  }

  Widget _buildCreatorScoreDashboard(CreatorProfileAnalysis analysis) {
    return GlassCard(
      padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 20),
      child: Column(
        children: [
          const Text(
            'Overall Creator Power Score',
            style: TextStyle(
              color: AppTheme.textSecondary,
              fontSize: 15,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 24),
          Stack(
            alignment: Alignment.center,
            children: [
              // Outer glow container
              Container(
                width: 150,
                height: 150,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.primary.withOpacity(0.15),
                      blurRadius: 48,
                      spreadRadius: 8,
                    ),
                  ],
                ),
              ),
              SizedBox(
                width: 150,
                height: 150,
                child: CircularProgressIndicator(
                  value: analysis.creatorScore / 100.0,
                  strokeWidth: 10,
                  backgroundColor: Colors.white.withOpacity(0.04),
                  valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.primary),
                ),
              ),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    analysis.creatorScore.toString(),
                    style: const TextStyle(
                      color: AppTheme.textPrimary,
                      fontSize: 44,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const Text(
                    '/ 100',
                    style: TextStyle(color: AppTheme.textMuted, fontSize: 12),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 28),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: AppTheme.primary.withOpacity(0.12),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.primary.withOpacity(0.2)),
            ),
            child: Text(
              analysis.creatorScore >= 80
                  ? 'Highly Optimized Creator'
                  : analysis.creatorScore >= 60
                      ? 'Growing Content Influence'
                      : 'Pacing & Consistency Required',
              style: const TextStyle(
                color: AppTheme.textPrimary,
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNicheCard(CreatorProfileAnalysis analysis) {
    return GlassCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Icon(Icons.explore_rounded, color: AppTheme.accent, size: 20),
              const SizedBox(width: 8),
              const Text(
                'Niche Diagnostics',
                style: TextStyle(color: AppTheme.textPrimary, fontSize: 15, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 20),
          const Text(
            'Primary Focus',
            style: TextStyle(color: AppTheme.textMuted, fontSize: 11, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 6),
          Text(
            analysis.niche,
            style: const TextStyle(
              color: AppTheme.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'Core Keywords & Signals Detected',
            style: TextStyle(color: AppTheme.textMuted, fontSize: 11, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: analysis.nicheKeywords.map((keyword) {
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppTheme.accent.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppTheme.accent.withOpacity(0.2)),
                ),
                child: Text(
                  keyword,
                  style: const TextStyle(
                    color: AppTheme.accent,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricsBreakdown(CreatorProfileAnalysis analysis) {
    return GlassCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Icon(Icons.insights_rounded, color: AppTheme.success, size: 20),
              const SizedBox(width: 8),
              const Text(
                'Audit Performance Scores',
                style: TextStyle(color: AppTheme.textPrimary, fontSize: 15, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _buildScoreRow('Posting Consistency', analysis.consistencyScore, AppTheme.primary),
          const Divider(color: Colors.white10, height: 24),
          _buildScoreRow('Brand Readiness', analysis.brandReadinessScore, AppTheme.success),
          const Divider(color: Colors.white10, height: 24),
          _buildScoreRow('Growth Potential', analysis.growthPotentialScore, AppTheme.accent),
        ],
      ),
    );
  }

  Widget _buildScoreRow(String label, int score, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
            Text(
              '$score%',
              style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 13),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: score / 100.0,
            minHeight: 5,
            backgroundColor: Colors.white10,
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        ),
      ],
    );
  }

  Widget _buildRecommendationsSection(CreatorProfileAnalysis analysis) {
    return GlassCard(
      borderColor: AppTheme.accent.withOpacity(0.3),
      backgroundColor: AppTheme.accent.withOpacity(0.02),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Icon(Icons.lightbulb_rounded, color: AppTheme.accent, size: 22),
              const SizedBox(width: 8),
              const Text(
                'Growth Roadmap & Action Items',
                style: TextStyle(color: AppTheme.textPrimary, fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(color: Colors.white10),
          const SizedBox(height: 12),
          Text(
            analysis.recommendations,
            style: const TextStyle(
              color: AppTheme.textSecondary,
              fontSize: 13.5,
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }
}
