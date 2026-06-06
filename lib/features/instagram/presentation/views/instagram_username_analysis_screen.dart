import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/glass_card.dart';
import '../../../auth/presentation/viewmodels/auth_viewmodel.dart';
import '../viewmodels/public_profile_viewmodel.dart';

class InstagramUsernameAnalysisScreen extends StatefulWidget {
  const InstagramUsernameAnalysisScreen({super.key});

  @override
  State<InstagramUsernameAnalysisScreen> createState() => _InstagramUsernameAnalysisScreenState();
}

class _InstagramUsernameAnalysisScreenState extends State<InstagramUsernameAnalysisScreen> {
  final TextEditingController _usernameController = TextEditingController();

  @override
  void dispose() {
    _usernameController.dispose();
    super.dispose();
  }

  void _analyze() {
    final username = _usernameController.text.trim();
    if (username.isEmpty) return;

    final authVm = Provider.of<AuthViewModel>(context, listen: false);
    if (authVm.user == null) return;

    Provider.of<PublicProfileViewModel>(context, listen: false)
        .analyzeUsername(authVm.user!.uid, username);
  }

  @override
  Widget build(BuildContext context) {
    final vm = Provider.of<PublicProfileViewModel>(context);

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
          onPressed: () {
            vm.reset();
            context.pop();
          },
        ),
        title: const Text(
          'Public Profile Analysis',
          style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (vm.currentAnalysis == null) ...[
              GlassCard(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: AppTheme.primary.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.search_rounded, color: AppTheme.primary, size: 40),
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'Analyze Any Public Profile',
                      style: TextStyle(color: AppTheme.textPrimary, fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Enter an Instagram username (e.g., @mrbeast) to get a deep AI audit of their content, hooks, and growth strategy.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: AppTheme.textSecondary, fontSize: 14, height: 1.5),
                    ),
                    const SizedBox(height: 32),
                    TextField(
                      controller: _usernameController,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        hintText: '@username',
                        hintStyle: TextStyle(color: AppTheme.textMuted.withOpacity(0.5)),
                        filled: true,
                        fillColor: Colors.white.withOpacity(0.05),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.white.withOpacity(0.1)),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.white.withOpacity(0.1)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: AppTheme.primary),
                        ),
                        prefixIcon: const Icon(Icons.alternate_email_rounded, color: AppTheme.textMuted),
                      ),
                      onSubmitted: (_) => _analyze(),
                    ),
                    const SizedBox(height: 24),
                    if (vm.error != null) ...[
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppTheme.error.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: AppTheme.error.withOpacity(0.3)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.error_outline_rounded, color: AppTheme.error, size: 20),
                            const SizedBox(width: 12),
                            Expanded(child: Text(vm.error!, style: const TextStyle(color: AppTheme.error, fontSize: 13))),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: vm.isLoading ? null : _analyze,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: vm.isLoading
                            ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                            : const Text('Analyze Profile', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      ),
                    ),
                  ],
                ),
              ),
            ] else ...[
              // Results State
              _buildResultsView(vm),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildResultsView(PublicProfileViewModel vm) {
    final analysis = vm.currentAnalysis!;
    final ai = analysis.aiAnalysis;
    final profile = analysis.profileSnapshot;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Row(
          children: [
            CircleAvatar(
              radius: 30,
              backgroundImage: NetworkImage(profile['profile_picture_url'] ?? ''),
              backgroundColor: AppTheme.cardBackground,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(profile['display_name'] ?? profile['username'], style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                  Text('@${profile['username']}', style: const TextStyle(color: AppTheme.textMuted)),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: AppTheme.accent, width: 3),
              ),
              child: Text(
                '${ai['profile_score'] ?? 0}',
                style: const TextStyle(color: AppTheme.accent, fontSize: 24, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        
        // Scores
        Row(
          children: [
            Expanded(child: _buildScoreCard('Bio Score', ai['bio_score'])),
            const SizedBox(width: 12),
            Expanded(child: _buildScoreCard('Content', ai['content_quality_score'])),
            const SizedBox(width: 12),
            Expanded(child: _buildScoreCard('Consistency', ai['consistency_score'])),
            const SizedBox(width: 12),
            Expanded(child: _buildScoreCard('Growth Pot.', ai['growth_potential_score'])),
          ],
        ),
        const SizedBox(height: 24),

        // Deep Analysis
        _buildSectionCard('Profile Strategy', [
          _buildInfoRow('Niche', ai['niche_detection'] ?? 'Unknown'),
          _buildInfoRow('Audience', ai['audience_persona_detection'] ?? 'Unknown'),
          _buildInfoRow('Positioning', ai['competitor_positioning'] ?? 'Unknown'),
          _buildInfoRow('Brand Strength', ai['brand_strength_analysis'] ?? 'Unknown'),
        ]),

        const SizedBox(height: 16),
        _buildListCard('Top Content Pillars', ai['top_content_pillars']),
        
        const SizedBox(height: 16),
        _buildListCard('Strong Hook Patterns', ai['top_hook_patterns']),
        
        const SizedBox(height: 16),
        _buildListCard('Weak Hook Patterns', ai['weak_hook_patterns']),

        const SizedBox(height: 16),
        _buildSectionCard('Content Strategy', [
          _buildInfoRow('Posting Frequency', ai['posting_frequency_analysis'] ?? 'Unknown'),
          _buildInfoRow('Hashtag Strategy', ai['hashtag_strategy_analysis'] ?? 'Unknown'),
        ]),

        const SizedBox(height: 24),
        const Text('AI Recommendations', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 16),

        _buildListCard('10 Reel Ideas', ai['10_reel_ideas']),
        const SizedBox(height: 16),
        _buildListCard('10 Hook Ideas', ai['10_hook_ideas']),
        const SizedBox(height: 16),
        _buildListCard('10 Caption Ideas', ai['10_caption_ideas']),
        const SizedBox(height: 16),
        _buildListCard('30-Day Growth Plan', ai['30_day_growth_plan']),
        
        const SizedBox(height: 40),
      ],
    );
  }

  Widget _buildScoreCard(String label, dynamic score) {
    return GlassCard(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
      child: Column(
        children: [
          Text(
            '${score ?? 0}',
            style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(color: AppTheme.textMuted, fontSize: 10),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildSectionCard(String title, List<Widget> children) {
    return GlassCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(color: AppTheme.primary, fontSize: 14, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(color: AppTheme.textMuted, fontSize: 12)),
          const SizedBox(height: 4),
          Text(value, style: const TextStyle(color: AppTheme.textPrimary, fontSize: 14, height: 1.4)),
        ],
      ),
    );
  }

  Widget _buildListCard(String title, dynamic itemsRaw) {
    List<String> items = [];
    if (itemsRaw is List) {
      items = itemsRaw.map((e) => e.toString()).toList();
    } else if (itemsRaw is String) {
      items = [itemsRaw];
    }

    return GlassCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(color: AppTheme.accent, fontSize: 14, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          ...items.map((item) => Padding(
                padding: const EdgeInsets.only(bottom: 12.0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('• ', style: TextStyle(color: AppTheme.textMuted, fontSize: 16)),
                    Expanded(child: Text(item, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 14, height: 1.4))),
                  ],
                ),
              )),
        ],
      ),
    );
  }
}
