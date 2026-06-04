import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../../analysis/data/models/analysis_models.dart';
import 'package:provider/provider.dart';
import 'package:video_player/video_player.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/glass_card.dart';
import '../../data/models/instagram_reel.dart';
import '../../data/services/reel_analysis_service.dart';
import '../viewmodels/instagram_viewmodel.dart';

class ReelInspectorScreen extends StatefulWidget {
  final String reelId;

  const ReelInspectorScreen({
    super.key,
    required this.reelId,
  });

  @override
  State<ReelInspectorScreen> createState() => _ReelInspectorScreenState();
}

class _ReelInspectorScreenState extends State<ReelInspectorScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final igVM = Provider.of<InstagramViewModel>(context, listen: false);
      final reel = igVM.reels.firstWhere(
        (r) => r.id == widget.reelId,
        orElse: () => InstagramReel(
          id: widget.reelId,
          thumbnailUrl: '',
          caption: '',
          likesCount: 0,
          commentsCount: 0,
          publishDate: DateTime.now(),
        ),
      );
      if (reel.thumbnailUrl.isNotEmpty) {
        igVM.inspectReel(reel);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final igVM = Provider.of<InstagramViewModel>(context);
    final size = MediaQuery.of(context).size;
    final isTablet = size.width > 600;

    final reel = igVM.reels.firstWhere(
      (r) => r.id == widget.reelId,
      orElse: () => InstagramReel(
        id: widget.reelId,
        thumbnailUrl: '',
        caption: 'Loading...',
        likesCount: 0,
        commentsCount: 0,
        publishDate: DateTime.now(),
      ),
    );

    final analysis = igVM.getAnalysis(widget.reelId);

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('Reel Inspector'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () {
            context.pop();
          },
        ),
      ),
      body: igVM.isAnalyzingReel && analysis == null
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: AppTheme.accent),
                  SizedBox(height: 24),
                  Text(
                    'AI is auditing your Reel hooks and pacing...',
                    style: TextStyle(color: AppTheme.textSecondary, fontSize: 14),
                  ),
                ],
              ),
            )
          : analysis == null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline_rounded, color: AppTheme.error, size: 48),
                      const SizedBox(height: 16),
                      const Text(
                        'Failed to load analysis for this Reel.',
                        style: TextStyle(color: AppTheme.textPrimary, fontSize: 16),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () => igVM.inspectReel(reel),
                        child: const Text('Retry Analysis'),
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
                          if (isTablet)
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  flex: 4,
                                  child: _buildVideoCard(reel),
                                ),
                                const SizedBox(width: 24),
                                Expanded(
                                  flex: 5,
                                  child: Column(
                                    children: [
                                      _buildViralPotentialCard(analysis.viralScore),
                                      const SizedBox(height: 16),
                                      _buildScoresMatrix(analysis),
                                    ],
                                  ),
                                ),
                              ],
                            )
                          else ...[
                            _buildVideoCard(reel),
                            const SizedBox(height: 20),
                            _buildViralPotentialCard(analysis.viralScore),
                            const SizedBox(height: 20),
                            _buildScoresMatrix(analysis),
                          ],
                          const SizedBox(height: 24),
                          _buildDetailsAccordion(reel),
                          const SizedBox(height: 24),
                          _buildAuditBreakdownSection(analysis),
                          const SizedBox(height: 24),
                          _buildAIGenerationsSection(analysis),
                          const SizedBox(height: 48),
                        ],
                      ),
                    ),
                  ),
                ),
    );
  }

  Widget _buildVideoCard(InstagramReel reel) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'Reel Preview',
          style: TextStyle(color: AppTheme.textPrimary, fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: AspectRatio(
            aspectRatio: 9 / 16,
            child: reel.videoUrl != null
                ? _InspectorVideoPlayer(videoUrl: reel.videoUrl!, thumbnailUrl: reel.thumbnailUrl)
                : Image.network(
                    reel.thumbnailUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      color: AppTheme.cardBackground,
                      child: const Icon(Icons.video_library_rounded, color: AppTheme.textMuted, size: 48),
                    ),
                  ),
          ),
        ),
      ],
    );
  }

  Widget _buildViralPotentialCard(int score) {
    return GlassCard(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          const Text(
            'Viral Potential Score',
            style: TextStyle(color: AppTheme.textSecondary, fontSize: 14, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 16),
          Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 120,
                height: 120,
                child: CircularProgressIndicator(
                  value: score / 100.0,
                  strokeWidth: 8,
                  backgroundColor: Colors.white.withOpacity(0.05),
                  valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.accent),
                ),
              ),
              Column(
                children: [
                  Text(
                    '$score%',
                    style: const TextStyle(
                      color: AppTheme.textPrimary,
                      fontSize: 32,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const Text(
                    'Potential',
                    style: TextStyle(color: AppTheme.textMuted, fontSize: 10),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            score >= 85
                ? 'High Virality Threshold'
                : score >= 70
                    ? 'Healthy Engagement'
                    : 'Needs Pacing Improvements',
            style: TextStyle(
              color: score >= 85
                  ? AppTheme.success
                  : score >= 70
                      ? AppTheme.warning
                      : AppTheme.error,
              fontSize: 15,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScoresMatrix(ConnectedReelAnalysis analysis) {
    return GlassCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Linguistic & Script Scores',
            style: TextStyle(color: AppTheme.textPrimary, fontSize: 15, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),
          _buildScoreBar('Hook Strength', analysis.hookScore, AppTheme.primary),
          const SizedBox(height: 16),
          _buildScoreBar('CTA Strength', analysis.ctaScore, AppTheme.accent),
          const SizedBox(height: 16),
          _buildScoreBar('Caption Quality', analysis.captionScore, AppTheme.success),
          const SizedBox(height: 16),
          _buildScoreBar('Engagement Rating', analysis.engagementScore, const Color(0xFFEC4899)),
        ],
      ),
    );
  }

  Widget _buildScoreBar(String label, int score, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
            Text(
              '$score/100',
              style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 13),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: score / 100.0,
            minHeight: 6,
            backgroundColor: Colors.white10,
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        ),
      ],
    );
  }

  Widget _buildDetailsAccordion(InstagramReel reel) {
    return GlassCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Icon(Icons.info_outline_rounded, color: AppTheme.accent, size: 20),
              const SizedBox(width: 8),
              const Text(
                'Reel Details & Metrics',
                style: TextStyle(color: AppTheme.textPrimary, fontSize: 15, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Telemetry Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatsItem('Likes', reel.likesCount.toString(), Icons.favorite_border_rounded, const Color(0xFFEF4444)),
              _buildStatsItem('Comments', reel.commentsCount.toString(), Icons.mode_comment_outlined, const Color(0xFF3B82F6)),
              if (reel.viewCount != null)
                _buildStatsItem('Views', reel.viewCount.toString(), Icons.play_circle_outline_rounded, AppTheme.accent),
            ],
          ),
          const SizedBox(height: 20),
          const Divider(color: Colors.white10),
          const SizedBox(height: 12),
          const Text(
            'Caption Text',
            style: TextStyle(color: AppTheme.textMuted, fontSize: 12, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 6),
          Text(
            reel.caption.isNotEmpty ? reel.caption : '(No caption provided)',
            style: const TextStyle(
              color: AppTheme.textSecondary,
              fontSize: 13,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Publish Date', style: TextStyle(color: AppTheme.textMuted, fontSize: 12)),
              Text(
                _formatDate(reel.publishDate),
                style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatsItem(String label, String value, IconData icon, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(height: 6),
        Text(
          value,
          style: const TextStyle(color: AppTheme.textPrimary, fontSize: 16, fontWeight: FontWeight.bold),
        ),
        Text(label, style: const TextStyle(color: AppTheme.textMuted, fontSize: 10)),
      ],
    );
  }

  Widget _buildAuditBreakdownSection(ConnectedReelAnalysis analysis) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'Detailed Diagnostics',
          style: TextStyle(color: AppTheme.textPrimary, fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        _buildDiagnosticCategory(
          'Strengths',
          analysis.strengths,
          Icons.check_circle_rounded,
          AppTheme.success,
          const Color(0xFF0F2D1F),
        ),
        const SizedBox(height: 16),
        _buildDiagnosticCategory(
          'Weaknesses',
          analysis.weaknesses,
          Icons.error_rounded,
          AppTheme.error,
          const Color(0xFF2E1517),
        ),
        const SizedBox(height: 16),
        _buildDiagnosticCategory(
          'Suggested Improvements',
          analysis.improvements,
          Icons.lightbulb_rounded,
          AppTheme.accent,
          const Color(0xFF072B36),
        ),
      ],
    );
  }

  Widget _buildDiagnosticCategory(
    String title,
    List<String> items,
    IconData icon,
    Color color,
    Color bgTint,
  ) {
    if (items.isEmpty) return const SizedBox.shrink();

    return Container(
      decoration: BoxDecoration(
        color: bgTint.withOpacity(0.35),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(color: color, fontSize: 15, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...items.map((item) => Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('• ', style: TextStyle(color: color, fontSize: 14, fontWeight: FontWeight.bold)),
                    Expanded(
                      child: Text(
                        item,
                        style: const TextStyle(
                          color: AppTheme.textPrimary,
                          fontSize: 13,
                          height: 1.45,
                        ),
                      ),
                    ),
                  ],
                ),
              )),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }

  Widget _buildAIGenerationsSection(ConnectedReelAnalysis analysis) {
    if (analysis.suggestedHooks.isEmpty &&
        analysis.suggestedCtas.isEmpty &&
        analysis.suggestedCaptions.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'AI Content Enhancements',
          style: TextStyle(color: AppTheme.textPrimary, fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        if (analysis.suggestedHooks.isNotEmpty) ...[
          _buildGenerationCategory('Suggested Hooks', analysis.suggestedHooks, Icons.bolt_rounded, AppTheme.primary),
          const SizedBox(height: 16),
        ],
        if (analysis.suggestedCtas.isNotEmpty) ...[
          _buildGenerationCategory('Suggested CTAs', analysis.suggestedCtas, Icons.call_to_action_rounded, AppTheme.accent),
          const SizedBox(height: 16),
        ],
        if (analysis.suggestedCaptions.isNotEmpty) ...[
          _buildGenerationCategory('Alternative Captions', analysis.suggestedCaptions, Icons.closed_caption_rounded, AppTheme.success),
        ],
      ],
    );
  }

  Widget _buildGenerationCategory(
    String title,
    List<SuggestedTextItem> items,
    IconData icon,
    Color color,
  ) {
    return GlassCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 22),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(color: AppTheme.textPrimary, fontSize: 15, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...items.map((item) => Padding(
                padding: const EdgeInsets.only(bottom: 12.0),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.03),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.white10),
                  ),
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: color.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(color: color.withOpacity(0.2)),
                            ),
                            child: Text(
                              item.type,
                              style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 10),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.copy_rounded, color: AppTheme.textSecondary, size: 18),
                            onPressed: () {
                              Clipboard.setData(ClipboardData(text: item.text));
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('${item.type} copied to clipboard!'),
                                  backgroundColor: color.withOpacity(0.85),
                                  duration: const Duration(seconds: 2),
                                ),
                              );
                            },
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                            visualDensity: VisualDensity.compact,
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        item.text,
                        style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13, height: 1.45),
                      ),
                    ],
                  ),
                ),
              )),
        ],
      ),
    );
  }
}

class _InspectorVideoPlayer extends StatefulWidget {
  final String videoUrl;
  final String thumbnailUrl;

  const _InspectorVideoPlayer({
    required this.videoUrl,
    required this.thumbnailUrl,
  });

  @override
  State<_InspectorVideoPlayer> createState() => _InspectorVideoPlayerState();
}

class _InspectorVideoPlayerState extends State<_InspectorVideoPlayer> {
  late VideoPlayerController _controller;
  bool _initialized = false;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _initializePlayer();
  }

  void _initializePlayer() async {
    try {
      _controller = VideoPlayerController.networkUrl(Uri.parse(widget.videoUrl));
      await _controller.initialize();
      if (mounted) {
        setState(() {
          _initialized = true;
        });
        _controller.setLooping(true);
        _controller.play();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _hasError = true;
        });
      }
    }
  }

  @override
  void dispose() {
    if (_initialized) {
      _controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_hasError) {
      return Image.network(
        widget.thumbnailUrl,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => Container(
          color: AppTheme.cardBackground,
          child: const Icon(Icons.video_library_rounded, color: AppTheme.textMuted, size: 48),
        ),
      );
    }

    if (!_initialized) {
      return Stack(
        fit: StackFit.expand,
        children: [
          Image.network(
            widget.thumbnailUrl,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => Container(color: AppTheme.cardBackground),
          ),
          Container(
            color: Colors.black38,
            child: const Center(
              child: CircularProgressIndicator(color: AppTheme.accent),
            ),
          ),
        ],
      );
    }

    return Stack(
      alignment: Alignment.center,
      children: [
        VideoPlayer(_controller),
        GestureDetector(
          onTap: () {
            setState(() {
              if (_controller.value.isPlaying) {
                _controller.pause();
              } else {
                _controller.play();
              }
            });
          },
          child: Container(color: Colors.transparent),
        ),
        if (!_controller.value.isPlaying)
          IgnorePointer(
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.5),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.play_arrow_rounded, color: Colors.white, size: 32),
            ),
          ),
      ],
    );
  }
}
