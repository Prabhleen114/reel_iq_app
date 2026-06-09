import 'dart:io';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:video_player/video_player.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/glass_card.dart';
import '../../../auth/presentation/viewmodels/auth_viewmodel.dart';
import '../../../profile/presentation/viewmodels/profile_viewmodel.dart';
import '../viewmodels/upload_viewmodel.dart';

class UploadReelScreen extends StatefulWidget {
  final bool embeddedMode;

  const UploadReelScreen({
    super.key,
    this.embeddedMode = false,
  });

  @override
  State<UploadReelScreen> createState() => _UploadReelScreenState();
}

class _UploadReelScreenState extends State<UploadReelScreen> {
  final _titleController = TextEditingController();

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  void _upload() async {
    final uploadVM = Provider.of<UploadViewModel>(context, listen: false);
    final authVM = Provider.of<AuthViewModel>(context, listen: false);
    final profileVM = Provider.of<ProfileViewModel>(context, listen: false);

    // Free limit warning (5 analyses limit per month)
    if (!profileVM.isPro && profileVM.analysesPerformed >= profileVM.maxFreeAnalyses) {
      final upgrade = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: AppTheme.cardBackground,
          title: const Text('Analysis Limit Reached'),
          content: const Text(
            'You have used all 5 free analyses for this month. Upgrade to Pro for ₹199/month for unlimited audits.',
            style: TextStyle(color: AppTheme.textSecondary),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel', style: TextStyle(color: AppTheme.textSecondary)),
            ),
            ElevatedButton(
              onPressed: () {
                profileVM.toggleSubscription(); // Instantly upgrades to Pro!
                Navigator.pop(context, true);
              },
              style: ElevatedButton.styleFrom(backgroundColor: AppTheme.accent),
              child: const Text('Upgrade Pro (₹199)', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      );
      if (upgrade != true) return;
    }

    if (authVM.user != null) {
      uploadVM.setTitle(_titleController.text);
      final analysis = await uploadVM.uploadReel(authVM.user!.uid);
      if (analysis != null && mounted) {
        // Record metrics
        profileVM.recordAnalysisPerformed();
        
        // Redirect to analysis result screen
        if (widget.embeddedMode) {
          context.push('/analysis/${analysis.id}');
        } else {
          context.replace('/analysis/${analysis.id}');
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final uploadVM = Provider.of<UploadViewModel>(context);
    final size = MediaQuery.of(context).size;
    final isTablet = size.width > 600;

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('Analyze Reel'),
        automaticallyImplyLeading: !widget.embeddedMode,
        leading: widget.embeddedMode
            ? null
            : IconButton(
                icon: const Icon(Icons.arrow_back_rounded),
                onPressed: () {
                  uploadVM.clearVideo();
                  context.pop();
                },
              ),
      ),
      body: Stack(
        children: [
          // Background glows
          Positioned(
            top: -50,
            left: -50,
            child: Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.primary.withOpacity(0.1),
                    blurRadius: 80,
                    spreadRadius: 80,
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            bottom: -50,
            right: -50,
            child: Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.accent.withOpacity(0.08),
                    blurRadius: 80,
                    spreadRadius: 80,
                  ),
                ],
              ),
            ),
          ),
          SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
            child: Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: isTablet ? 550 : double.infinity,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Video Picker / Video Player Container
                    uploadVM.videoFile == null
                        ? GestureDetector(
                            onTap: uploadVM.isLoading ? null : () => uploadVM.pickVideo(),
                            child: AspectRatio(
                              aspectRatio: 9 / 16,
                              child: Container(
                                decoration: BoxDecoration(
                                  color: AppTheme.cardBackground,
                                  borderRadius: BorderRadius.circular(24),
                                  border: Border.all(color: AppTheme.cardBorder, width: 1.5),
                                ),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(20),
                                      decoration: BoxDecoration(
                                        color: AppTheme.primary.withOpacity(0.12),
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(
                                        Icons.add_a_photo_outlined,
                                        color: AppTheme.primary,
                                        size: 36,
                                      ),
                                    ),
                                    const SizedBox(height: 20),
                                    const Text(
                                      'Select Reel Video',
                                      style: TextStyle(
                                        color: AppTheme.textPrimary,
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    const Text(
                                      'Supports MP4, MOV. Max length 3 mins.',
                                      style: TextStyle(
                                        color: AppTheme.textMuted,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          )
                        : Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(24),
                                child: AspectRatio(
                                  aspectRatio: 9 / 16,
                                  child: _LocalVideoPreview(videoFile: uploadVM.videoFile!),
                                ),
                              ),
                              const SizedBox(height: 12),
                              TextButton.icon(
                                onPressed: uploadVM.isLoading ? null : () => uploadVM.clearVideo(),
                                icon: const Icon(Icons.refresh_rounded, color: AppTheme.error),
                                label: const Text(
                                  'Change Video',
                                  style: TextStyle(color: AppTheme.error, fontWeight: FontWeight.bold),
                                ),
                              ),
                            ],
                          ),
                    const SizedBox(height: 24),

                    // Inputs and Details
                    GlassCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const Text(
                            'Reel Information',
                            style: TextStyle(
                              color: AppTheme.textPrimary,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 16),
                          TextField(
                            controller: _titleController,
                            enabled: !uploadVM.isLoading,
                            textCapitalization: TextCapitalization.sentences,
                            decoration: const InputDecoration(
                              labelText: 'Reel Title or Topic',
                              hintText: 'e.g. 5 Coding Tricks I Wish I Knew Sooner',
                              prefixIcon: Icon(Icons.title_rounded, color: AppTheme.textSecondary),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 28),

                    // Error display
                    if (uploadVM.errorMessage != null)
                      Container(
                        padding: const EdgeInsets.all(12),
                        margin: const EdgeInsets.only(bottom: 20),
                        decoration: BoxDecoration(
                          color: AppTheme.error.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppTheme.error.withOpacity(0.3)),
                        ),
                        child: Text(
                          uploadVM.errorMessage!,
                          style: const TextStyle(color: AppTheme.error, fontSize: 13),
                        ),
                      ),

                    // Upload Button
                    ElevatedButton.icon(
                      onPressed: (uploadVM.videoFile == null || uploadVM.isLoading) ? null : _upload,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      icon: const Icon(Icons.bolt_rounded, color: Colors.white),
                      label: const Text('Start AI Analysis'),
                    ),
                    const SizedBox(height: 36),
                  ],
                ),
              ),
            ),
          ),

          // Uploading loading Overlay
          if (uploadVM.isLoading)
            Container(
              color: Colors.black.withOpacity(0.85),
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(32.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          color: AppTheme.primary.withOpacity(0.12),
                          shape: BoxShape.circle,
                        ),
                        child: const Center(
                          child: SizedBox(
                            width: 48,
                            height: 48,
                            child: CircularProgressIndicator(
                              valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primary),
                              strokeWidth: 3,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 32),
                      const Text(
                        'Uploading & Transcribing Reel',
                        style: TextStyle(
                          color: AppTheme.textPrimary,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '${(uploadVM.uploadProgress * 100).toInt()}% uploaded',
                        style: const TextStyle(
                          color: AppTheme.accent,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 20),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: SizedBox(
                          width: 200,
                          height: 6,
                          child: LinearProgressIndicator(
                            value: uploadVM.uploadProgress,
                            backgroundColor: Colors.white.withOpacity(0.1),
                            valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.accent),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      const Text(
                        'Running AI linguistic and engagement scoring models...',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: AppTheme.textMuted,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _LocalVideoPreview extends StatefulWidget {
  final File videoFile;

  const _LocalVideoPreview({required this.videoFile});

  @override
  State<_LocalVideoPreview> createState() => _LocalVideoPreviewState();
}

class _LocalVideoPreviewState extends State<_LocalVideoPreview> {
  late VideoPlayerController _controller;
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.file(widget.videoFile)
      ..initialize().then((_) {
        setState(() {
          _initialized = true;
        });
        _controller.setLooping(true);
        _controller.play();
      });
  }

  @override
  void didUpdateWidget(covariant _LocalVideoPreview oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.videoFile.path != widget.videoFile.path) {
      _controller.dispose();
      _initialized = false;
      _controller = VideoPlayerController.file(widget.videoFile)
        ..initialize().then((_) {
          setState(() {
            _initialized = true;
          });
          _controller.setLooping(true);
          _controller.play();
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
        // Simple play/pause trigger overlay
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
          child: Container(
            color: Colors.transparent,
            width: double.infinity,
            height: double.infinity,
          ),
        ),
        if (!_controller.value.isPlaying)
          IgnorePointer(
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.5),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.play_arrow_rounded,
                color: Colors.white,
                size: 32,
              ),
            ),
          ),
      ],
    );
  }
}
