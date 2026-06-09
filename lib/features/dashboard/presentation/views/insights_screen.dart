import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/glass_card.dart';
import '../../../profile/presentation/viewmodels/profile_viewmodel.dart';
import '../viewmodels/dashboard_viewmodel.dart';

class InsightsScreen extends StatefulWidget {
  final bool embeddedMode;

  const InsightsScreen({super.key, this.embeddedMode = false});

  @override
  State<InsightsScreen> createState() => _InsightsScreenState();
}

class _InsightsScreenState extends State<InsightsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _competitorController = TextEditingController();
  bool _isAnalyzingCompetitor = false;
  Map<String, dynamic>? _competitorResult;

  final List<Map<String, dynamic>> _competitorHistory = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _competitorController.dispose();
    super.dispose();
  }

  void _analyzeCompetitor() async {
    final username = _competitorController.text.trim();
    if (username.isEmpty) return;

    setState(() {
      _isAnalyzingCompetitor = true;
      _competitorResult = null;
    });

    final profileVM = Provider.of<ProfileViewModel>(context, listen: false);

    // Simulate competitor analysis
    await Future.delayed(const Duration(milliseconds: 1800));

    final nameClean = username.replaceAll('@', '');
    final result = {
      'username': '@$nameClean',
      'postingFrequency': '4-5 Reels per week',
      'hookStyle': 'Highly visual, opens with bold text overlays in first 1.5s',
      'captionStyle': 'Short and value-oriented, using 4 targeted hashtags',
      'contentThemes': 'Technical tutorials, developer humor, workspace aesthetics',
      'opportunities': [
        'High demand for code-along reels - create interactive templates',
        'Leverage dynamic audio trends in software development reels'
      ],
      'contentGaps': [
        'Lacks step-by-step beginner guides - perfect opportunity to capture entry-level audience',
        'No direct CTA guides - you can outperform by offering free code templates in DMs'
      ],
      'recommendations': [
        'Post at 6:30 PM EST to capture developer peak hours',
        'Use the DM automation comment trigger (e.g. "Comment CODE") to boost engagement rates'
      ]
    };

    if (mounted) {
      setState(() {
        _isAnalyzingCompetitor = false;
        _competitorResult = result;
        _competitorHistory.insert(0, result);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isTablet = size.width > 600;

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('Creator Insights'),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppTheme.accent,
          labelColor: AppTheme.accent,
          unselectedLabelColor: AppTheme.textMuted,
          tabs: const [
            Tab(text: 'My Insights'),
            Tab(text: 'Competitor Audits'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildMyInsights(isTablet),
          _buildCompetitorAudits(isTablet),
        ],
      ),
    );
  }

  Widget _buildMyInsights(bool isTablet) {
    final dashboardVM = Provider.of<DashboardViewModel>(context);
    final hasData = dashboardVM.analyses.isNotEmpty;

    // Aggregate some mock/real stats from recent analyses
    final String bestTopic = hasData 
        ? dashboardVM.analyses.first.title.split(' ').take(2).join(' ') 
        : 'Tech tutorials';
    final int growthScore = hasData ? (dashboardVM.averageViralScore + 4).clamp(50, 98) : 84;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: isTablet ? 650 : double.infinity),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Growth Potential Score
              GlassCard(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    const Text(
                      'Growth Potential Score',
                      style: TextStyle(color: AppTheme.textSecondary, fontSize: 14, fontWeight: FontWeight.w500),
                    ),
                    const SizedBox(height: 16),
                    Stack(
                      alignment: Alignment.center,
                      children: [
                        SizedBox(
                          width: 110,
                          height: 110,
                          child: CircularProgressIndicator(
                            value: growthScore / 100.0,
                            strokeWidth: 8,
                            backgroundColor: Colors.white.withOpacity(0.04),
                            valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.accent),
                          ),
                        ),
                        Text(
                          '$growthScore%',
                          style: const TextStyle(color: AppTheme.textPrimary, fontSize: 28, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Audience engagement and pacing metrics are showing upward trends!',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: AppTheme.textMuted, fontSize: 12),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Content Themes
              const Text(
                'Key Content Performance',
                style: TextStyle(color: AppTheme.textPrimary, fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              
              GlassCard(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    _buildInsightRow('Top Performing Topic', bestTopic, AppTheme.accent),
                    const Divider(color: Colors.white10, height: 24),
                    _buildInsightRow('Posting Consistency', 'Good (3 posts/week)', AppTheme.success),
                    const Divider(color: Colors.white10, height: 24),
                    _buildInsightRow('Core Content Theme', 'Educational Tutorials (45%)', AppTheme.primary),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Copilot recommendations
              const Text(
                'Weekly Copilot Strategic Advice',
                style: TextStyle(color: AppTheme.textPrimary, fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              
              _buildCopilotTipCard(
                'Niche Advantage',
                'Your educational reels perform 28% better than motivational content. Prioritize tutorials with clear screen overlays.',
                Icons.lightbulb_rounded,
                AppTheme.accent,
              ),
              const SizedBox(height: 12),
              _buildCopilotTipCard(
                'Pacing Optimization',
                'Edits with an average shot duration of 2.8 seconds have 40% higher retention rates. Increase jump cuts in intros.',
                Icons.speed_rounded,
                AppTheme.primary,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInsightRow(String label, String value, Color color) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 14)),
        Text(
          value,
          style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 14),
        ),
      ],
    );
  }

  Widget _buildCopilotTipCard(String title, String desc, IconData icon, Color color) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.cardBackground.withOpacity(0.4),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.12)),
      ),
      padding: const EdgeInsets.all(16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 14),
                ),
                const SizedBox(height: 6),
                Text(
                  desc,
                  style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13, height: 1.45),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompetitorAudits(bool isTablet) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: isTablet ? 650 : double.infinity),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Audit Competitor Strategy',
                style: TextStyle(color: AppTheme.textPrimary, fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 6),
              const Text(
                'Deconstruct a competitor account. Our copilot will analyze hook styles, posting frequencies, and pinpoint content gaps.',
                style: TextStyle(color: AppTheme.textMuted, fontSize: 13, height: 1.45),
              ),
              const SizedBox(height: 20),

              // Search Bar
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _competitorController,
                      enabled: !_isAnalyzingCompetitor,
                      textInputAction: TextInputAction.search,
                      decoration: const InputDecoration(
                        hintText: 'Enter Instagram username (e.g. @creatorshub)',
                        prefixIcon: Icon(Icons.alternate_email_rounded, color: AppTheme.accent),
                      ),
                      onSubmitted: (_) => _analyzeCompetitor(),
                    ),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    onPressed: _isAnalyzingCompetitor ? null : _analyzeCompetitor,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
                    ),
                    child: _isAnalyzingCompetitor
                        ? const SizedBox(
                            width: 20, 
                            height: 20, 
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)
                          )
                        : const Icon(Icons.bolt_rounded, color: Colors.white),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              if (_competitorResult != null) ...[
                _buildCompetitorDetailsCard(_competitorResult!),
                const SizedBox(height: 24),
              ],

              // History list
              if (_competitorHistory.isNotEmpty) ...[
                const Text(
                  'Recent Audits History',
                  style: TextStyle(color: AppTheme.textPrimary, fontSize: 15, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _competitorHistory.length,
                  itemBuilder: (context, index) {
                    final item = _competitorHistory[index];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 10.0),
                      child: ListTile(
                        onTap: () {
                          setState(() {
                            _competitorResult = item;
                          });
                        },
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: BorderSide(
                            color: _competitorResult?['username'] == item['username']
                                ? AppTheme.accent.withOpacity(0.3)
                                : Colors.white.withOpacity(0.05),
                          ),
                        ),
                        tileColor: AppTheme.cardBackground.withOpacity(0.3),
                        leading: const Icon(Icons.person_search_rounded, color: AppTheme.accent),
                        title: Text(item['username'] as String, style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
                        subtitle: Text('Posting: ${item['postingFrequency']}', style: const TextStyle(fontSize: 12)),
                        trailing: const Icon(Icons.chevron_right_rounded, color: AppTheme.textMuted),
                      ),
                    );
                  },
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCompetitorDetailsCard(Map<String, dynamic> data) {
    return GlassCard(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const CircleAvatar(
                backgroundColor: AppTheme.accent,
                radius: 20,
                child: Icon(Icons.alternate_email_rounded, color: Colors.white),
              ),
              const SizedBox(width: 14),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    data['username'] as String,
                    style: const TextStyle(color: AppTheme.textPrimary, fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const Text('AI Strategy Deconstruction', style: TextStyle(color: AppTheme.textMuted, fontSize: 11)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Overview metrics (Posting, hook, caption style)
          _buildMetricSection('Posting Frequency', data['postingFrequency'] as String),
          _buildMetricSection('Hook Strategy', data['hookStyle'] as String),
          _buildMetricSection('Caption Format', data['captionStyle'] as String),
          _buildMetricSection('Content Themes', data['contentThemes'] as String),
          
          const Divider(color: Colors.white10, height: 28),

          // Content Gaps (Red)
          const Text(
            'Linguistic & Content Gaps',
            style: TextStyle(color: AppTheme.error, fontSize: 13, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          ...(data['contentGaps'] as List<String>).map((gap) => Padding(
                padding: const EdgeInsets.only(bottom: 6.0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('• ', style: TextStyle(color: AppTheme.error, fontWeight: FontWeight.bold)),
                    Expanded(child: Text(gap, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13, height: 1.4))),
                  ],
                ),
              )),

          const SizedBox(height: 20),

          // Opportunities (Green)
          const Text(
            'Audited Opportunities',
            style: TextStyle(color: AppTheme.success, fontSize: 13, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          ...(data['opportunities'] as List<String>).map((opp) => Padding(
                padding: const EdgeInsets.only(bottom: 6.0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('• ', style: TextStyle(color: AppTheme.success, fontWeight: FontWeight.bold)),
                    Expanded(child: Text(opp, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13, height: 1.4))),
                  ],
                ),
              )),

          const SizedBox(height: 20),

          // Actionable recommendations (Cyan)
          const Text(
            'Recommended Plan for You',
            style: TextStyle(color: AppTheme.accent, fontSize: 13, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          ...(data['recommendations'] as List<String>).map((rec) => Padding(
                padding: const EdgeInsets.only(bottom: 6.0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('• ', style: TextStyle(color: AppTheme.accent, fontWeight: FontWeight.bold)),
                    Expanded(child: Text(rec, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13, height: 1.4))),
                  ],
                ),
              )),
        ],
      ),
    );
  }

  Widget _buildMetricSection(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label.toUpperCase(),
            style: const TextStyle(color: AppTheme.textMuted, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 0.8),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13, height: 1.4),
          ),
        ],
      ),
    );
  }
}
