import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/glass_card.dart';
import '../../../auth/presentation/viewmodels/auth_viewmodel.dart';
import '../viewmodels/profile_viewmodel.dart';
import '../../../dashboard/presentation/viewmodels/dashboard_viewmodel.dart';

class ProfileScreen extends StatefulWidget {
  final bool embeddedMode;

  const ProfileScreen({
    super.key,
    this.embeddedMode = false,
  });

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<ProfileViewModel>(context, listen: false).refresh();
    });
  }

  void _logout() async {
    final authViewModel = Provider.of<AuthViewModel>(context, listen: false);
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.cardBackground,
        title: const Text('Log Out'),
        content: const Text('Are you sure you want to end your ReelIQ session?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel', style: TextStyle(color: AppTheme.textSecondary)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Log Out', style: TextStyle(color: AppTheme.error)),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      await authViewModel.logout();
      if (mounted) {
        context.go('/login');
      }
    }
  }

  void _editInstagramHandle(ProfileViewModel profileVM) async {
    final controller = TextEditingController(text: profileVM.instagramHandle);
    final newHandle = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.cardBackground,
        title: const Text('Connect Instagram'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: 'Enter handle (e.g. @priya_creations)',
            prefixIcon: Icon(Icons.alternate_email_rounded, color: AppTheme.accent),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: AppTheme.textSecondary)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            child: const Text('Connect', style: TextStyle(color: AppTheme.accent)),
          ),
        ],
      ),
    );

    if (newHandle != null && newHandle.isNotEmpty) {
      profileVM.setInstagramHandle(newHandle.startsWith('@') ? newHandle : '@$newHandle');
    }
  }

  @override
  Widget build(BuildContext context) {
    final authViewModel = Provider.of<AuthViewModel>(context);
    final profileVM = Provider.of<ProfileViewModel>(context);
    final dashboardVM = Provider.of<DashboardViewModel>(context);
    final size = MediaQuery.of(context).size;
    final isTablet = size.width > 600;

    final user = authViewModel.user;

    final body = SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(20, widget.embeddedMode ? 64 : 16, 20, 32),
      child: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: isTablet ? 600 : double.infinity,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // User Info Card with connected Instagram
              if (user != null)
                GlassCard(
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    children: [
                      Container(
                        width: 58,
                        height: 58,
                        decoration: const BoxDecoration(
                          gradient: AppTheme.primaryGradient,
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: user.profilePictureUrl.isNotEmpty
                              ? ClipOval(
                                  child: Image.network(
                                    user.profilePictureUrl,
                                    width: 58,
                                    height: 58,
                                    fit: BoxFit.cover,
                                  ),
                                )
                              : Text(
                                  user.displayName.isNotEmpty ? user.displayName[0].toUpperCase() : 'U',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 22,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              user.displayName,
                              style: const TextStyle(
                                color: AppTheme.textPrimary,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 3),
                            InkWell(
                              onTap: () => _editInstagramHandle(profileVM),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.alternate_email_rounded, color: AppTheme.accent, size: 14),
                                  const SizedBox(width: 4),
                                  Text(
                                    user.instagramHandle.isNotEmpty ? user.instagramHandle : profileVM.instagramHandle,
                                    style: const TextStyle(
                                      color: AppTheme.accent,
                                      fontSize: 13,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  const Icon(Icons.edit_rounded, color: AppTheme.textMuted, size: 12),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 20),

              // Subscription Status Plan Card
              _buildSubscriptionCard(profileVM, isPro: authVM.user?.hasActivePro ?? false),
              const SizedBox(height: 20),

              // Weekly Creator Report (Concept B / Pro Requirement)
              _buildWeeklyCreatorReport(profileVM, isPro: authVM.user?.hasActivePro ?? false),
              const SizedBox(height: 20),

              // Usage statistics
              const Text(
                'USAGE STATISTICS',
                style: TextStyle(
                  color: AppTheme.textMuted,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 8),
              GlassCard(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    _buildUsageRow(
                      'Reels Audited',
                      (authVM.user?.hasActivePro ?? false)
                          ? '${profileVM.analysesPerformed} / Unlimited' 
                          : '${profileVM.analysesPerformed} / ${profileVM.maxFreeAnalyses}',
                      (authVM.user?.hasActivePro ?? false) ? 1.0 : (profileVM.analysesPerformed / profileVM.maxFreeAnalyses).clamp(0.0, 1.0),
                    ),
                    const SizedBox(height: 16),
                    _buildUsageRow(
                      'Content Calendars Generated',
                      (authVM.user?.hasActivePro ?? false) ? 'Unlimited' : '${dashboardVM.totalReelsAnalyzed > 0 ? 1 : 0} / 2 Plans',
                      (authVM.user?.hasActivePro ?? false) ? 1.0 : 0.5,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Settings Options
              const Text(
                'SYSTEM SETTINGS',
                style: TextStyle(
                  color: AppTheme.textMuted,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 8),
              GlassCard(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Column(
                  children: [
                    SwitchListTile(
                      value: profileVM.useMockMode,
                      onChanged: (value) {
                        profileVM.toggleMockMode(value);
                        if (user != null) {
                          dashboardVM.loadAnalyses(user.uid);
                        }
                      },
                      activeColor: AppTheme.accent,
                      title: const Text(
                        'Offline Mock Mode',
                        style: TextStyle(color: AppTheme.textPrimary, fontSize: 14, fontWeight: FontWeight.bold),
                      ),
                      subtitle: const Text(
                        'Simulates visual and speech audio metrics offline',
                        style: TextStyle(color: AppTheme.textMuted, fontSize: 11),
                      ),
                      secondary: const Icon(Icons.cloud_off_rounded, color: AppTheme.textSecondary),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 28),

              // Log Out Button
              ElevatedButton.icon(
                onPressed: _logout,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.error.withOpacity(0.08),
                  foregroundColor: AppTheme.error,
                  side: BorderSide(color: AppTheme.error.withOpacity(0.15)),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                icon: const Icon(Icons.logout_rounded, size: 18),
                label: const Text('Log Out Session', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
              ),
            ],
          ),
        ),
      ),
    );

    if (widget.embeddedMode) {
      return body;
    }

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('Creator Profile'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () {
            context.pop();
          },
        ),
      ),
      body: body,
    );
  }

  Widget _buildSubscriptionCard(ProfileViewModel profileVM, {required bool isPro}) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.cardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isPro ? AppTheme.accent.withOpacity(0.3) : Colors.white.withOpacity(0.04),
        ),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('MEMBERSHIP PLAN', style: TextStyle(color: AppTheme.textMuted, fontSize: 9, fontWeight: FontWeight.bold, letterSpacing: 1.0)),
                  const SizedBox(height: 4),
                  Text(
                    isPro ? 'Pro Creator Plan' : 'Free Sandbox Tier',
                    style: TextStyle(
                      color: isPro ? AppTheme.accent : AppTheme.textPrimary,
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: isPro ? AppTheme.accent.withOpacity(0.12) : Colors.white.withOpacity(0.04),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  isPro ? 'ACTIVE' : 'FREE',
                  style: TextStyle(
                    color: isPro ? AppTheme.accent : AppTheme.textSecondary,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            isPro
                ? 'Enjoy unlimited analysis audits, rewrites, dynamic calendars, and premium weekly creator reports.'
                : 'Free tier limits your account to 5 video audits per month.',
            style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12, height: 1.4),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () {
              if (!isPro) {
                context.push('/pricing');
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: isPro ? Colors.white.withOpacity(0.06) : AppTheme.accent,
              foregroundColor: isPro ? AppTheme.textPrimary : Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: Text(
              isPro ? 'Subscription Active' : 'Upgrade to Pro — ₹199/month',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWeeklyCreatorReport(ProfileViewModel profileVM, {required bool isPro}) {
    if (!isPro) {
      return Container(
        decoration: BoxDecoration(
          color: AppTheme.cardBackground.withOpacity(0.6),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withOpacity(0.02)),
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Dummy content blurred
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Image.asset(
                'assets/images/logo.png', // dummy placeholder
                errorBuilder: (_, __, ___) => Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(height: 12, width: 100, color: Colors.white.withOpacity(0.05)),
                    const SizedBox(height: 8),
                    Container(height: 10, width: 250, color: Colors.white.withOpacity(0.03)),
                    const SizedBox(height: 6),
                    Container(height: 10, width: 200, color: Colors.white.withOpacity(0.03)),
                  ],
                ),
              ),
            ),
            
            // Blur effect overlay with Lock
            Positioned.fill(
              child: Container(
                color: Colors.black.withOpacity(0.65),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.lock_outline_rounded, color: AppTheme.accent, size: 28),
                    const SizedBox(height: 8),
                    const Text(
                      'Weekly Creator Report',
                      style: TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                    const Text(
                      'Pro Membership required to unlock',
                      style: TextStyle(color: AppTheme.textMuted, fontSize: 11),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      );
    }

    return GlassCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Icon(Icons.analytics_rounded, color: AppTheme.accent, size: 20),
              const SizedBox(width: 8),
              const Text(
                'Weekly Creator Report',
                style: TextStyle(color: AppTheme.textPrimary, fontSize: 15, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          _buildReportSection('💡 What Worked', 'Your tutorial-based reels had a 44% increase in retention because of pattern cuts in the first 3 seconds.'),
          const SizedBox(height: 12),
          _buildReportSection('⚠️ What Failed', 'Reels without text caption overlays on screen had a 52% average viewer drop-off in the hook section.'),
          const SizedBox(height: 12),
          _buildReportSection('📈 Best Content Type', 'Development Tips / Code ASMR Setup guides performed above average.'),
          const SizedBox(height: 12),
          _buildReportSection('🗓️ Next Week\'s Suggested Plan', 'Focus on 30s quick tips. Use Curiosity hooks, comment-triggers ("Comment SETUP"), and post between 6:00 PM - 7:30 PM.'),
        ],
      ),
    );
  }

  Widget _buildReportSection(String title, String desc) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(color: AppTheme.textPrimary, fontSize: 13, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 4),
        Text(
          desc,
          style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12, height: 1.4),
        ),
      ],
    );
  }

  // Achievement section removed

  Widget _buildUsageRow(String label, String value, double progressPercent) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
            Text(value, style: const TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.bold, fontSize: 13)),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: progressPercent,
            minHeight: 5,
            backgroundColor: Colors.white.withOpacity(0.04),
            valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.accent),
          ),
        ),
      ],
    );
  }
}
