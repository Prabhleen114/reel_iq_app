import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../data/models/analysis_models.dart';
import '../../../dashboard/data/models/reel_analysis_model.dart';
import 'package:video_player/video_player.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/glass_card.dart';
import '../viewmodels/analysis_viewmodel.dart';
import '../../../dashboard/presentation/viewmodels/dashboard_viewmodel.dart';
import '../../../auth/presentation/viewmodels/auth_viewmodel.dart';

class AnalysisResultScreen extends StatefulWidget {
  final String reelId;

  const AnalysisResultScreen({
    super.key,
    required this.reelId,
  });

  @override
  State<AnalysisResultScreen> createState() => _AnalysisResultScreenState();
}

class _AnalysisResultScreenState extends State<AnalysisResultScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<AnalysisViewModel>(context, listen: false).loadAnalysis(widget.reelId);
    });
  }

  void _deleteAnalysis() async {
    final analysisVM = Provider.of<AnalysisViewModel>(context, listen: false);
    final dashboardVM = Provider.of<DashboardViewModel>(context, listen: false);
    final authVM = Provider.of<AuthViewModel>(context, listen: false);
    
    if (analysisVM.analysis != null && authVM.user != null) {
      final confirm = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: AppTheme.cardBackground,
          title: const Text('Delete Analysis'),
          content: const Text('Are you sure you want to permanently delete this Reel analysis logs?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel', style: TextStyle(color: AppTheme.textSecondary)),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Delete', style: TextStyle(color: AppTheme.error)),
            ),
          ],
        ),
      );

      if (confirm == true && mounted) {
        await dashboardVM.deleteAnalysis(widget.reelId, authVM.user!.uid);
        if (mounted) {
          context.go('/');
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final analysisVM = Provider.of<AnalysisViewModel>(context);
    final size = MediaQuery.of(context).size;
    final isTablet = size.width > 600;

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('AI Analysis Result'),
        actions: [
          if (analysisVM.analysis != null)
            IconButton(
              icon: const Icon(Icons.delete_outline_rounded, color: AppTheme.error),
              onPressed: _deleteAnalysis,
            ),
        ],
      ),
      body: analysisVM.isLoading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.accent))
          : analysisVM.errorMessage != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(analysisVM.errorMessage!, style: const TextStyle(color: AppTheme.error)),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () => analysisVM.loadAnalysis(widget.reelId),
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : analysisVM.analysis == null
                  ? const Center(child: Text('No details found.'))
                  : SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
                      child: Center(
                        child: ConstrainedBox(
                          constraints: BoxConstraints(
                            maxWidth: isTablet ? 800 : double.infinity,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              // Title and Date
                              Text(
                                analysisVM.analysis!.title,
                                style: Theme.of(context).textTheme.displaySmall?.copyWith(
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold,
                                    ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Analyzed on ${_formatDate(analysisVM.analysis!.createdAt)}',
                                style: const TextStyle(color: AppTheme.textMuted, fontSize: 13),
                              ),
                              const SizedBox(height: 24),

                              // Layout adjusts for tablets/wide screens
                              isTablet
                                  ? Row(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Expanded(
                                          flex: 4,
                                          child: _buildVideoCard(analysisVM.analysis!.videoPath, analysisVM.analysis!.videoUrl),
                                        ),
                                        const SizedBox(width: 24),
                                        Expanded(
                                          flex: 5,
                                          child: Column(
                                            children: [
                                              _buildScoreSection(analysisVM.analysis!.viralScore),
                                              const SizedBox(height: 16),
                                              _buildPredictionsSection(analysisVM.analysis!),
                                            ],
                                          ),
                                        ),
                                      ],
                                    )
                                  : Column(
                                      children: [
                                        _buildVideoCard(analysisVM.analysis!.videoPath, analysisVM.analysis!.videoUrl),
                                        const SizedBox(height: 20),
                                        _buildScoreSection(analysisVM.analysis!.viralScore),
                                        const SizedBox(height: 20),
                                        _buildPredictionsSection(analysisVM.analysis!),
                                      ],
                                    ),
                              const SizedBox(height: 24),

                              // Suggestions list
                              _buildSuggestionsSection(analysisVM.analysis!.suggestions),
                              const SizedBox(height: 24),
                              _buildTranscriptSection(analysisVM.analysis!.transcript),
                              const SizedBox(height: 24),
                              _buildAIGenerationsSection(analysisVM.analysis!),
                              const SizedBox(height: 48),
                            ],
                          ),
                        ),
                      ),
                    ),
    );
  }

  Widget _buildVideoCard(String? localPath, String? remoteUrl) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'Reel Playback',
          style: TextStyle(color: AppTheme.textPrimary, fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: AspectRatio(
            aspectRatio: 9 / 16,
            child: _AnalysisVideoPlayer(
              localPath: localPath,
              remoteUrl: remoteUrl,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildScoreSection(int score) {
    return GlassCard(
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
      child: Column(
        children: [
          const Text(
            'Content Potential Score',
            style: TextStyle(color: AppTheme.textSecondary, fontSize: 14, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 16),
          Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 130,
                height: 130,
                child: CircularProgressIndicator(
                  value: score / 100.0,
                  strokeWidth: 10,
                  backgroundColor: Colors.white.withOpacity(0.05),
                  valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.accent),
                ),
              ),
              Column(
                children: [
                  Text(
                    score.toString(),
                    style: const TextStyle(
                      color: AppTheme.textPrimary,
                      fontSize: 38,
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
          const SizedBox(height: 16),
          Text(
            score >= 85 ? 'High Potential' : score >= 75 ? 'Moderate Potential' : 'Needs Optimization',
            style: TextStyle(
              color: score >= 85 ? AppTheme.success : score >= 75 ? AppTheme.warning : AppTheme.error,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPredictionsSection(ReelAnalysisModel model) {
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Creator Audit Metrics',
            style: TextStyle(color: AppTheme.textPrimary, fontSize: 15, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          _buildMetricRow('Hook Score', '${model.hookScore}/100', AppTheme.primary),
          const Divider(color: Colors.white10, height: 16),
          _buildMetricRow('CTA Score', '${model.ctaScore}/100', AppTheme.accent),
          const Divider(color: Colors.white10, height: 16),
          _buildMetricRow('Caption Score', '${model.captionScore}/100', AppTheme.success),
          const Divider(color: Colors.white10, height: 16),
          _buildMetricRow('Trend Alignment', '${model.trendScore}/100', AppTheme.warning),
        ],
      ),
    );
  }

  Widget _buildTranscriptSection(String transcript) {
    if (transcript.isEmpty) return const SizedBox.shrink();
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Speech Transcription (AI Extracted)',
            style: TextStyle(color: AppTheme.textPrimary, fontSize: 15, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.02),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.white.withOpacity(0.04)),
            ),
            child: Text(
              transcript,
              style: const TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 13,
                height: 1.45,
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricRow(String label, String value, Color accentColor) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 14)),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: accentColor.withOpacity(0.12),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: accentColor.withOpacity(0.2)),
          ),
          child: Text(
            value,
            style: TextStyle(color: accentColor, fontWeight: FontWeight.bold, fontSize: 13),
          ),
        ),
      ],
    );
  }

  Widget _buildSuggestionsSection(List<String> suggestions) {
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Recommended Adjustments',
            style: TextStyle(color: AppTheme.textPrimary, fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          ...suggestions.map((suggestion) => Padding(
                padding: const EdgeInsets.only(bottom: 10.0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Padding(
                      padding: EdgeInsets.only(top: 4.0, right: 12.0),
                      child: Icon(
                        Icons.check_circle_outline_rounded,
                        color: AppTheme.accent,
                        size: 16,
                      ),
                    ),
                    Expanded(
                      child: Text(
                        suggestion,
                        style: const TextStyle(color: AppTheme.textSecondary, fontSize: 14, height: 1.4),
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

  Widget _buildAIGenerationsSection(ReelAnalysisModel analysis) {
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

class _AnalysisVideoPlayer extends StatefulWidget {
  final String? localPath;
  final String? remoteUrl;

  const _AnalysisVideoPlayer({this.localPath, this.remoteUrl});

  @override
  State<_AnalysisVideoPlayer> createState() => _AnalysisVideoPlayerState();
}

class _AnalysisVideoPlayerState extends State<_AnalysisVideoPlayer> {
  late VideoPlayerController _controller;
  bool _initialized = false;
  String? _errorMsg;

  @override
  void initState() {
    super.initState();
    _initController();
  }

  void _initController() async {
    try {
      if (widget.localPath != null && File(widget.localPath!).existsSync()) {
        _controller = VideoPlayerController.file(File(widget.localPath!));
      } else if (widget.remoteUrl != null) {
        _controller = VideoPlayerController.networkUrl(Uri.parse(widget.remoteUrl!));
      } else {
        setState(() {
          _errorMsg = "No video playback source available.";
        });
        return;
      }

      await _controller.initialize();
      setState(() {
        _initialized = true;
      });
      _controller.setLooping(true);
      _controller.play();
    } catch (e) {
      setState(() {
        _errorMsg = "Failed to load video file.";
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_errorMsg != null) {
      return Container(
        color: AppTheme.cardBackground,
        child: Center(
          child: Text(_errorMsg!, style: const TextStyle(color: AppTheme.error)),
        ),
      );
    }

    if (!_initialized) {
      return Container(
        color: AppTheme.cardBackground,
        child: const Center(
          child: CircularProgressIndicator(color: AppTheme.accent),
        ),
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
