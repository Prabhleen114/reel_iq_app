import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/glass_card.dart';
import '../viewmodels/instagram_viewmodel.dart';
import '../../data/models/instagram_reel.dart';

class InstagramLibraryView extends StatefulWidget {
  const InstagramLibraryView({super.key});

  @override
  State<InstagramLibraryView> createState() => _InstagramLibraryViewState();
}

class _InstagramLibraryViewState extends State<InstagramLibraryView> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<InstagramViewModel>(context, listen: false).checkConnection();
    });
  }

  void _showMockOAuthDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return _SimulatedOAuthDialog(
          onSuccess: () async {
            final vm = Provider.of<InstagramViewModel>(this.context, listen: false);
            await vm.connect();
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final igVM = Provider.of<InstagramViewModel>(context);
    final size = MediaQuery.of(context).size;
    final isTablet = size.width > 600;

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: igVM.isLoading && !igVM.isConnected
          ? const Center(child: CircularProgressIndicator(color: AppTheme.accent))
          : SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 64, 20, 32),
              child: Center(
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxWidth: isTablet ? 900 : double.infinity,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Disconnected Gate View
                      if (!igVM.isConnected) ...[
                        const SizedBox(height: 40),
                        _buildConnectGate(),
                      ]
                      // Connected View
                      else ...[
                        _buildProfileHeader(igVM),
                        const SizedBox(height: 32),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'My Reels Library',
                              style: TextStyle(
                                color: AppTheme.textPrimary,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              '${igVM.reels.length} Recent Reels',
                              style: const TextStyle(color: AppTheme.textMuted, fontSize: 13),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        _buildReelsGrid(igVM, isTablet),
                      ],
                    ],
                  ),
                ),
              ),
            ),
    );
  }

  Widget _buildConnectGate() {
    final igVM = Provider.of<InstagramViewModel>(context, listen: false);
    return GlassCard(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 48),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Glowing Instagram/Meta Icon
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: const Color(0xFFE1306C).withOpacity(0.12),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFE1306C).withOpacity(0.2),
                  blurRadius: 32,
                  spreadRadius: 8,
                ),
              ],
            ),
            child: const Icon(
              Icons.camera_alt_rounded,
              color: Color(0xFFE1306C),
              size: 48,
            ),
          ),
          const SizedBox(height: 32),
          const Text(
            'Connect Instagram Professional',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppTheme.textPrimary,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'Sync your active Reels, view counts, likes, and comments directly using the secure Meta Graph API to unlock deep AI hook audits.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppTheme.textSecondary,
              fontSize: 14,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 36),
          // Connection details checklist
          _buildChecklistItem('Fetch recent Reel performance diagnostics'),
          const SizedBox(height: 12),
          _buildChecklistItem('Analyze hook lines and caption CTA strength'),
          const SizedBox(height: 12),
          _buildChecklistItem('Audit overall creator consistency and brand compatibility'),
          const SizedBox(height: 36),

          ElevatedButton.icon(
            onPressed: igVM.isConnecting ? null : _showMockOAuthDialog,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFE1306C),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
            ),
            icon: const Icon(Icons.link_rounded),
            label: const Text('Connect Account', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _buildChecklistItem(String text) {
    return Row(
      children: [
        const Icon(Icons.check_circle_rounded, color: AppTheme.success, size: 20),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13),
          ),
        ),
      ],
    );
  }

  Widget _buildProfileHeader(InstagramViewModel igVM) {
    return GlassCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Row(
            children: [
              // Avatar
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Image.network(
                  igVM.profile.photoUrl,
                  width: 60,
                  height: 60,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    width: 60,
                    height: 60,
                    color: AppTheme.primary,
                    child: const Icon(Icons.person_rounded, color: Colors.white),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      igVM.profile.displayName,
                      style: const TextStyle(
                        color: AppTheme.textPrimary,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '@${igVM.profile.username}',
                      style: const TextStyle(color: AppTheme.textMuted, fontSize: 13),
                    ),
                  ],
                ),
              ),
              // Disconnect Action
              TextButton(
                onPressed: () => igVM.disconnect(),
                child: const Text('Disconnect', style: TextStyle(color: AppTheme.error, fontSize: 13)),
              ),
            ],
          ),
          const SizedBox(height: 20),
          const Divider(color: Colors.white10),
          const SizedBox(height: 16),
          // Stats Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildProfileStat('Followers', _formatCount(igVM.profile.followersCount)),
              _buildProfileStat('Following', _formatCount(igVM.profile.followingCount)),
              _buildProfileStat('Posts', igVM.profile.postsCount.toString()),
              _buildProfileStat('Reels', igVM.profile.reelsCount.toString()),
            ],
          ),
          const SizedBox(height: 24),
          // Run Audit Action Button
          ElevatedButton.icon(
            onPressed: () {
              context.push('/creator-analysis');
            },
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
              backgroundColor: AppTheme.accent,
              foregroundColor: Colors.white,
            ),
            icon: const Icon(Icons.analytics_rounded),
            label: const Text('Audit Creator Profile'),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileStat(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            color: AppTheme.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(color: AppTheme.textMuted, fontSize: 11),
        ),
      ],
    );
  }

  Widget _buildReelsGrid(InstagramViewModel igVM, bool isTablet) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: isTablet ? 3 : 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 9 / 14,
      ),
      itemCount: igVM.reels.length,
      itemBuilder: (context, index) {
        final reel = igVM.reels[index];
        return _ReelGridTile(
          reel: reel,
          onTap: () {
            context.push('/reel-inspector/${reel.id}');
          },
        );
      },
    );
  }

  String _formatCount(int count) {
    if (count >= 1000000) {
      return '${(count / 1000000).toStringAsFixed(1)}M';
    } else if (count >= 1000) {
      return '${(count / 1000).toStringAsFixed(1)}K';
    }
    return count.toString();
  }
}

class _ReelGridTile extends StatelessWidget {
  final InstagramReel reel;
  final VoidCallback onTap;

  const _ReelGridTile({
    required this.reel,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Stack(
          children: [
            // Thumbnail
            Positioned.fill(
              child: Image.network(
                reel.thumbnailUrl,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  color: AppTheme.cardBackground,
                  child: const Icon(Icons.video_library_rounded, color: AppTheme.textMuted),
                ),
              ),
            ),
            // Bottom Gradient Overlay
            Positioned.fill(
              child: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.transparent, Colors.black87],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
              ),
            ),
            // Play Button indicator on center
            Align(
              alignment: Alignment.center,
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.black38,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white30),
                ),
                child: const Icon(Icons.play_arrow_rounded, color: Colors.white, size: 24),
              ),
            ),
            // Telemetry Counters
            Positioned(
              bottom: 8,
              left: 8,
              right: 8,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    reel.caption,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.favorite_rounded, color: Colors.white, size: 12),
                          const SizedBox(width: 4),
                          Text(
                            _shortenCount(reel.likesCount),
                            style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          const Icon(Icons.mode_comment_rounded, color: Colors.white, size: 12),
                          const SizedBox(width: 4),
                          Text(
                            _shortenCount(reel.commentsCount),
                            style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _shortenCount(int value) {
    if (value >= 1000) {
      return '${(value / 1000).toStringAsFixed(0)}K';
    }
    return value.toString();
  }
}

class _SimulatedOAuthDialog extends StatefulWidget {
  final VoidCallback onSuccess;

  const _SimulatedOAuthDialog({required this.onSuccess});

  @override
  State<_SimulatedOAuthDialog> createState() => _SimulatedOAuthDialogState();
}

class _SimulatedOAuthDialogState extends State<_SimulatedOAuthDialog> {
  bool _isLoading = false;

  void _authorize() async {
    setState(() {
      _isLoading = true;
    });

    await Future.delayed(const Duration(milliseconds: 1800));

    if (mounted) {
      Navigator.pop(context);
      widget.onSuccess();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: const Color(0xFF1E1E24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 450, maxHeight: 550),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Mock Webview Title Bar
              Container(
                color: const Color(0xFF2C2C35),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  children: [
                    const Icon(Icons.lock_rounded, color: AppTheme.success, size: 14),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Text(
                        'instagram.com/oauth/authorize...',
                        style: TextStyle(
                          color: AppTheme.textSecondary,
                          fontSize: 12,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: AppTheme.textMuted, size: 18),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),

              // Mock Webview Content
              Expanded(
                child: _isLoading
                    ? const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            CircularProgressIndicator(color: Color(0xFFE1306C)),
                            const SizedBox(height: 16),
                            Text(
                              'Authenticating via Meta Secure...',
                              style: TextStyle(color: AppTheme.textSecondary, fontSize: 13),
                            ),
                          ],
                        ),
                      )
                    : SingleChildScrollView(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // Branding
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.camera_alt_rounded, color: Color(0xFFE1306C), size: 36),
                                const SizedBox(width: 12),
                                Text(
                                  'Instagram API',
                                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                      ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 24),
                            const Divider(color: Colors.white10),
                            const SizedBox(height: 16),
                            const Text(
                              'ReelIQ requests permissions to access:',
                              style: TextStyle(
                                color: AppTheme.textPrimary,
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 16),
                            _buildPermissionRow(
                              Icons.account_box_outlined,
                              'Instagram Profile Information',
                              'Access your account username, media count, and statistics.',
                            ),
                            const SizedBox(height: 16),
                            _buildPermissionRow(
                              Icons.video_collection_outlined,
                              'Instagram Media Library',
                              'Read your posts, reels, video tracks, and captions metadata.',
                            ),
                            const SizedBox(height: 16),
                            _buildPermissionRow(
                              Icons.insights_outlined,
                              'Instagram Account Insights',
                              'Read reach stats, view counts, likes, and comments analytics.',
                            ),
                            const SizedBox(height: 24),
                            const Text(
                              'You are logged in as tech_creator_iq.',
                              textAlign: TextAlign.center,
                              style: TextStyle(color: AppTheme.textMuted, fontSize: 12),
                            ),
                          ],
                        ),
                      ),
              ),

              // Action buttons
              if (!_isLoading)
                Container(
                  color: const Color(0xFF2C2C35),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Cancel', style: TextStyle(color: AppTheme.textSecondary)),
                      ),
                      const SizedBox(width: 16),
                      ElevatedButton(
                        onPressed: _authorize,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFE1306C),
                          foregroundColor: Colors.white,
                        ),
                        child: const Text('Authorize'),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPermissionRow(IconData icon, String title, String desc) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: AppTheme.accent, size: 20),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(color: AppTheme.textPrimary, fontSize: 13, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 2),
              Text(
                desc,
                style: const TextStyle(color: AppTheme.textMuted, fontSize: 11, height: 1.4),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
