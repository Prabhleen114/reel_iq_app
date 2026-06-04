import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/theme/app_theme.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen>
    with TickerProviderStateMixin {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  static const List<_OnboardingPage> _pages = [
    _OnboardingPage(
      gradient: LinearGradient(
        colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      icon: Icons.insights_rounded,
      tagline: 'STEP 1 OF 3',
      title: 'Analyze Your\nContent',
      subtitle:
          'Upload any Reel and get an AI-powered analysis — hook strength, CTA score, viral potential, and AI-generated rewrites.',
    ),
    _OnboardingPage(
      gradient: LinearGradient(
        colors: [Color(0xFF8B5CF6), Color(0xFF06B6D4)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      icon: Icons.calendar_month_rounded,
      tagline: 'STEP 2 OF 3',
      title: 'Plan Your\nContent Calendar',
      subtitle:
          'Generate a complete 30-day content calendar with daily reel ideas, hooks, captions, CTAs, and recommended posting times.',
    ),
    _OnboardingPage(
      gradient: LinearGradient(
        colors: [Color(0xFF06B6D4), Color(0xFF10B981)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      icon: Icons.trending_up_rounded,
      tagline: 'STEP 3 OF 3',
      title: 'Track Your\nCreator Growth',
      subtitle:
          'Connect Instagram, get weekly performance reports, and level up your creator strategy — all powered by local AI.',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeIn,
    );
    _fadeController.forward();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  Future<void> _completeOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('reeliq_onboarded', true);
    if (mounted) context.go('/login');
  }

  void _nextPage() {
    if (_currentPage < _pages.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    } else {
      _completeOnboarding();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: Stack(
          children: [
            // Background glow
            Positioned.fill(
              child: IgnorePointer(
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 500),
                  decoration: BoxDecoration(
                    gradient: RadialGradient(
                      center: Alignment.topCenter,
                      radius: 1.4,
                      colors: [
                        _pages[_currentPage]
                            .gradient
                            .colors
                            .first
                            .withOpacity(0.08),
                        AppTheme.background,
                      ],
                    ),
                  ),
                ),
              ),
            ),
            Column(
              children: [
                const SizedBox(height: 60),
                // Page dots
                _buildDots(),
                const Spacer(),
                // Page view
                SizedBox(
                  height: 420,
                  child: PageView.builder(
                    controller: _pageController,
                    itemCount: _pages.length,
                    onPageChanged: (index) {
                      setState(() => _currentPage = index);
                    },
                    itemBuilder: (context, index) {
                      return _buildPage(_pages[index]);
                    },
                  ),
                ),
                const Spacer(),
                // Actions
                _buildActions(),
                const SizedBox(height: 48),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDots() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(_pages.length, (index) {
        final isActive = index == _currentPage;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          width: isActive ? 24 : 8,
          height: 8,
          margin: const EdgeInsets.symmetric(horizontal: 4),
          decoration: BoxDecoration(
            gradient: isActive ? _pages[_currentPage].gradient : null,
            color: isActive ? null : AppTheme.cardBorder,
            borderRadius: BorderRadius.circular(4),
          ),
        );
      }),
    );
  }

  Widget _buildPage(_OnboardingPage page) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Icon container
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              gradient: page.gradient,
              borderRadius: BorderRadius.circular(28),
              boxShadow: [
                BoxShadow(
                  color: page.gradient.colors.first.withOpacity(0.4),
                  blurRadius: 32,
                  spreadRadius: 4,
                  offset: const Offset(0, 12),
                ),
              ],
            ),
            child: Icon(page.icon, color: Colors.white, size: 52),
          ),
          const SizedBox(height: 40),
          Text(
            page.tagline,
            style: const TextStyle(
              color: AppTheme.textMuted,
              fontSize: 11,
              letterSpacing: 3,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          ShaderMask(
            shaderCallback: (bounds) => page.gradient.createShader(bounds),
            child: Text(
              page.title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 36,
                fontWeight: FontWeight.w900,
                height: 1.1,
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            page.subtitle,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppTheme.textSecondary,
              fontSize: 16,
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActions() {
    final isLast = _currentPage == _pages.length - 1;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          SizedBox(
            width: double.infinity,
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: _pages[_currentPage].gradient,
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color:
                        _pages[_currentPage].gradient.colors.first.withOpacity(0.4),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: ElevatedButton(
                onPressed: _nextPage,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: Text(
                  isLast ? "Let's Get Started" : 'Next',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
          if (!isLast) ...[
            const SizedBox(height: 16),
            TextButton(
              onPressed: _completeOnboarding,
              child: const Text(
                'Skip',
                style: TextStyle(color: AppTheme.textMuted, fontSize: 14),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _OnboardingPage {
  final LinearGradient gradient;
  final IconData icon;
  final String tagline;
  final String title;
  final String subtitle;

  const _OnboardingPage({
    required this.gradient,
    required this.icon,
    required this.tagline,
    required this.title,
    required this.subtitle,
  });
}
