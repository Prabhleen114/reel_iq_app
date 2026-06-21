import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/gradient_button.dart';
import '../../auth/presentation/viewmodels/auth_viewmodel.dart';
import '../viewmodels/onboarding_viewmodel.dart';

class OnboardingScreen extends StatelessWidget {
  const OnboardingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => OnboardingViewModel(),
      child: const _CreatorOnboarding(),
    );
  }
}

class _CreatorOnboarding extends StatefulWidget {
  const _CreatorOnboarding();

  @override
  State<_CreatorOnboarding> createState() => _CreatorOnboardingState();
}

class _CreatorOnboardingState extends State<_CreatorOnboarding> with TickerProviderStateMixin {
  final _pageController = PageController();
  final _emailController = TextEditingController();
  late final AnimationController _progressController;
  Timer? _factTimer;
  int _page = 0;
  int _factIndex = 0;
  int _featureIndex = 0;

  static const _stages = [
    'Fetching profile',
    'Analyzing content patterns',
    'Identifying strengths',
    'Identifying weaknesses',
    'Predicting growth opportunities',
    'Building creator profile',
  ];
  static const _facts = [
    'Posts with strong first 3-second hooks get significantly more retention.',
    'Most creators focus on content quantity instead of content systems.',
    'Consistency alone rarely creates growth. Strategy does.',
    'Top creators repeat successful content formats.',
  ];
  static const _features = [
    _CreatorFeature('Dashboard', 'Understand performance instantly', Icons.grid_view_rounded),
    _CreatorFeature('Content Planner', 'Build content systems instead of random posts', Icons.calendar_month_rounded),
    _CreatorFeature('AI Suggestions', 'Personalized recommendations from your content', Icons.auto_awesome_rounded),
    _CreatorFeature('Reel Analyzer', 'Understand why content works or fails', Icons.analytics_rounded),
    _CreatorFeature('Insights', 'Discover patterns invisible inside Instagram', Icons.insights_rounded),
    _CreatorFeature('Competitor Analysis', 'Learn what successful creators are doing', Icons.radar_rounded),
  ];

  @override
  void initState() {
    super.initState();
    _progressController = AnimationController(vsync: this, duration: const Duration(seconds: 7))
      ..addStatusListener((status) {
        if (status == AnimationStatus.completed && mounted && _page == 1) _goToPage(2);
      });
  }

  @override
  void dispose() {
    _factTimer?.cancel();
    _pageController.dispose();
    _emailController.dispose();
    _progressController.dispose();
    super.dispose();
  }

  Future<void> _startAnalysis(OnboardingViewModel vm) async {
    final auth = Provider.of<AuthViewModel>(context, listen: false);
    if (auth.user == null) return;
    _goToPage(1);
    _progressController.forward(from: 0);
    _factTimer?.cancel();
    _factTimer = Timer.periodic(const Duration(seconds: 2), (_) {
      if (mounted) setState(() => _factIndex = (_factIndex + 1) % _facts.length);
    });
    final success = await vm.analyzeInstagram(auth.user!.uid);
    if (!success && mounted) {
      _progressController.stop();
      _goToPage(0);
    }
  }

  Future<void> _startTrial(OnboardingViewModel vm) async {
    final auth = Provider.of<AuthViewModel>(context, listen: false);
    await vm.completeOnboarding(auth);
    if (mounted && vm.error == null) context.go('/pricing');
  }

  void _goToPage(int page) {
    setState(() => _page = page);
    _pageController.animateToPage(page, duration: const Duration(milliseconds: 420), curve: Curves.easeOutCubic);
  }

  @override
  Widget build(BuildContext context) {
    final vm = Provider.of<OnboardingViewModel>(context);
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: Stack(
        children: [
          const _GlowBackground(),
          SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 14, 24, 4),
                  child: Row(
                    children: [
                      const Text('CreatorOS', style: TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.w900, fontSize: 16)),
                      const Spacer(),
                      Text('${_page + 1}/5', style: const TextStyle(color: AppTheme.textMuted, fontWeight: FontWeight.w700, fontSize: 12)),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(99),
                    child: LinearProgressIndicator(
                      value: (_page + 1) / 5,
                      minHeight: 4,
                      backgroundColor: AppTheme.cardBorder,
                      valueColor: const AlwaysStoppedAnimation(AppTheme.primary),
                    ),
                  ),
                ),
                if (vm.error != null)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 12, 24, 0),
                    child: Text(vm.error!, style: const TextStyle(color: AppTheme.error)),
                  ),
                Expanded(
                  child: PageView(
                    controller: _pageController,
                    physics: const NeverScrollableScrollPhysics(),
                    children: [
                      _WelcomeStep(emailController: _emailController, vm: vm, onStart: () => _startAnalysis(vm)),
                      _AnalysisStep(vm: vm, controller: _progressController, stages: _stages, fact: _facts[_factIndex]),
                      _RevealStep(onContinue: () => _goToPage(3)),
                      _FeatureStep(
                        feature: _features[_featureIndex],
                        index: _featureIndex,
                        count: _features.length,
                        onNext: () {
                          if (_featureIndex == _features.length - 1) {
                            _goToPage(4);
                          } else {
                            setState(() => _featureIndex++);
                          }
                        },
                      ),
                      _PaywallStep(isLoading: vm.isLoading, onStartTrial: () => _startTrial(vm)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CreatorFeature {
  final String title;
  final String subtitle;
  final IconData icon;
  const _CreatorFeature(this.title, this.subtitle, this.icon);
}

class _WelcomeStep extends StatelessWidget {
  final TextEditingController emailController;
  final OnboardingViewModel vm;
  final VoidCallback onStart;
  const _WelcomeStep({required this.emailController, required this.vm, required this.onStart});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 68, 24, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text("Let's audit your creator potential.", textAlign: TextAlign.center, style: TextStyle(color: AppTheme.textPrimary, fontSize: 34, height: 1.04, fontWeight: FontWeight.w900)),
          const SizedBox(height: 16),
          const Text("Enter your Instagram handle and email. We'll analyze your content, audience patterns, strengths, weaknesses, and growth opportunities.", textAlign: TextAlign.center, style: TextStyle(color: AppTheme.textSecondary, fontSize: 15, height: 1.5)),
          const SizedBox(height: 34),
          _PremiumField(hintText: '@username', icon: Icons.alternate_email_rounded, onChanged: vm.setHandle),
          const SizedBox(height: 14),
          _PremiumField(hintText: 'email@example.com', icon: Icons.mail_outline_rounded, controller: emailController, keyboardType: TextInputType.emailAddress),
          const SizedBox(height: 28),
          GradientButton(text: 'Start Analysis', onPressed: vm.isLoading || vm.handle.trim().isEmpty ? null : onStart, isLoading: vm.isLoading),
          const SizedBox(height: 22),
          const Wrap(
            alignment: WrapAlignment.center,
            spacing: 10,
            runSpacing: 10,
            children: [_TrustChip('AI-powered analysis'), _TrustChip('Creator-focused insights'), _TrustChip('Personalized growth recommendations')],
          ),
        ],
      ),
    );
  }
}

class _AnalysisStep extends StatelessWidget {
  final OnboardingViewModel vm;
  final AnimationController controller;
  final List<String> stages;
  final String fact;
  const _AnalysisStep({required this.vm, required this.controller, required this.stages, required this.fact});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        final progress = controller.value;
        final active = math.min((progress * stages.length).floor(), stages.length - 1);
        return SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 28, 24, 32),
          child: Column(
            children: [
              const SizedBox(height: 18),
              SizedBox(
                width: 180,
                height: 180,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    SizedBox.expand(child: CircularProgressIndicator(value: progress.clamp(0.03, 1), strokeWidth: 10, backgroundColor: AppTheme.cardBorder, valueColor: const AlwaysStoppedAnimation(AppTheme.primary))),
                    CircleAvatar(radius: 58, backgroundColor: AppTheme.cardBackground, child: Text('${(progress * 100).round()}%', style: const TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.w900, fontSize: 28))),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              const Text('Estimated completion: 30-60 seconds', style: TextStyle(color: AppTheme.textMuted, fontWeight: FontWeight.w700)),
              const SizedBox(height: 24),
              _Panel(child: Column(children: List.generate(stages.length, (index) => Padding(
                padding: EdgeInsets.only(bottom: index == stages.length - 1 ? 0 : 12),
                child: Row(children: [
                  Icon(index <= active ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded, color: index <= active ? AppTheme.success : AppTheme.textMuted, size: 20),
                  const SizedBox(width: 12),
                  Text(stages[index], style: TextStyle(color: index <= active ? AppTheme.textPrimary : AppTheme.textMuted, fontWeight: index <= active ? FontWeight.w700 : FontWeight.w500)),
                ]),
              )))),
              const SizedBox(height: 16),
              _Panel(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('CreatorOS fact', style: TextStyle(color: AppTheme.accent, fontWeight: FontWeight.w800)),
                const SizedBox(height: 8),
                AnimatedSwitcher(duration: const Duration(milliseconds: 350), child: Text(fact, key: ValueKey(fact), style: const TextStyle(color: AppTheme.textSecondary, height: 1.45))),
              ])),
              const SizedBox(height: 16),
              const _Panel(child: Text("Pro tip: Give the AI a moment. We're building a personalized creator blueprint.", style: TextStyle(color: AppTheme.textPrimary, height: 1.45, fontWeight: FontWeight.w700))),
            ],
          ),
        );
      },
    );
  }
}

class _RevealStep extends StatelessWidget {
  final VoidCallback onContinue;
  const _RevealStep({required this.onContinue});

  @override
  Widget build(BuildContext context) {
    const strengths = ['Strong content consistency', 'Clear creator positioning', 'High save potential', 'Relatable communication style', 'Strong audience trust'];
    const weaknesses = ['Weak hooks', 'Inconsistent posting frequency', 'Limited shareability', 'Low content series usage', 'Missing retention triggers'];
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const _Panel(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('AI Summary', style: TextStyle(color: AppTheme.accent, fontWeight: FontWeight.w900, fontSize: 13)),
            SizedBox(height: 12),
            Text('Your content performs best when you share practical advice and personal experiences. Your audience responds strongly to educational content, but retention drops during longer introductions. The account shows strong potential for growth through repeatable content frameworks.', style: TextStyle(color: AppTheme.textPrimary, height: 1.55, fontSize: 15)),
          ])),
          const SizedBox(height: 16),
          _InsightList(title: 'Strengths', icon: Icons.check_rounded, color: AppTheme.success, items: strengths),
          const SizedBox(height: 16),
          _InsightList(title: 'Weaknesses', icon: Icons.warning_amber_rounded, color: AppTheme.warning, items: weaknesses),
          const SizedBox(height: 16),
          const _GrowthForecast(),
          const SizedBox(height: 24),
          GradientButton(text: 'Show Me CreatorOS', onPressed: onContinue),
        ],
      ),
    );
  }
}

class _FeatureStep extends StatelessWidget {
  final _CreatorFeature feature;
  final int index;
  final int count;
  final VoidCallback onNext;
  const _FeatureStep({required this.feature, required this.index, required this.count, required this.onNext});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 54, 24, 32),
      child: Column(
        children: [
          const Text('Your operating system is assembled.', textAlign: TextAlign.center, style: TextStyle(color: AppTheme.textPrimary, fontSize: 28, height: 1.08, fontWeight: FontWeight.w900)),
          const SizedBox(height: 28),
          Expanded(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 320),
              child: _Panel(
                key: ValueKey(feature.title),
                child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                  Container(width: 82, height: 82, decoration: BoxDecoration(gradient: AppTheme.primaryGradient, borderRadius: BorderRadius.circular(24)), child: Icon(feature.icon, color: Colors.white, size: 38)),
                  const SizedBox(height: 24),
                  Text(feature.title, textAlign: TextAlign.center, style: const TextStyle(color: AppTheme.textPrimary, fontSize: 25, fontWeight: FontWeight.w900)),
                  const SizedBox(height: 10),
                  Text(feature.subtitle, textAlign: TextAlign.center, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 15, height: 1.45)),
                ]),
              ),
            ),
          ),
          const SizedBox(height: 18),
          Row(mainAxisAlignment: MainAxisAlignment.center, children: List.generate(count, (dot) => AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            width: dot == index ? 24 : 7,
            height: 7,
            margin: const EdgeInsets.symmetric(horizontal: 4),
            decoration: BoxDecoration(color: dot == index ? AppTheme.primary : AppTheme.cardBorder, borderRadius: BorderRadius.circular(99)),
          ))),
          const SizedBox(height: 22),
          GradientButton(text: index == count - 1 ? 'Continue' : 'Next', onPressed: onNext),
        ],
      ),
    );
  }
}

class _PaywallStep extends StatelessWidget {
  final bool isLoading;
  final VoidCallback onStartTrial;
  const _PaywallStep({required this.isLoading, required this.onStartTrial});

  @override
  Widget build(BuildContext context) {
    const benefits = ['Unlimited AI content planning', 'Reel performance analysis', 'Account strengths and weaknesses', 'Growth opportunity tracking', 'Competitor intelligence', 'Hook and caption optimization', 'Monthly creator reports'];
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text('Your growth system is ready.', textAlign: TextAlign.center, style: TextStyle(color: AppTheme.textPrimary, fontSize: 31, height: 1.08, fontWeight: FontWeight.w900)),
          const SizedBox(height: 12),
          const Text('Unlock personalized creator intelligence, content planning, AI audits, and growth tracking.', textAlign: TextAlign.center, style: TextStyle(color: AppTheme.textSecondary, height: 1.45)),
          const SizedBox(height: 22),
          _Panel(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: benefits.map((benefit) => _BenefitRow(benefit)).toList())),
          const SizedBox(height: 16),
          const _PricingCard(title: 'CreatorOS Pro', price: 'Rs.1 trial for 7 days', detail: 'Then Rs.149/month. Less than Rs.5/day.', badge: 'MOST POPULAR'),
          const SizedBox(height: 12),
          const _PricingCard(title: 'CreatorOS Voice', price: 'Rs.199/month', detail: 'Everything in Pro plus AI voice generation, scripts, and narration tools.'),
          const SizedBox(height: 12),
          const _PricingCard(title: 'Quarterly Plan', price: 'Rs.439 every 3 months', detail: 'Save over 20%.', badge: 'BEST VALUE'),
          const SizedBox(height: 22),
          GradientButton(text: 'Start My Rs.1 Trial', onPressed: isLoading ? null : onStartTrial, isLoading: isLoading),
          const SizedBox(height: 12),
          const Text('Cancel anytime. Most creators spend more on one coffee than on their growth system.', textAlign: TextAlign.center, style: TextStyle(color: AppTheme.textMuted, fontSize: 12, height: 1.4)),
        ],
      ),
    );
  }
}

class _GlowBackground extends StatelessWidget {
  const _GlowBackground();
  @override
  Widget build(BuildContext context) => Stack(children: [
    Positioned(top: -80, left: -80, child: _Glow(color: AppTheme.primary.withOpacity(0.16))),
    Positioned(bottom: -120, right: -90, child: _Glow(color: AppTheme.accent.withOpacity(0.12))),
  ]);
}

class _Glow extends StatelessWidget {
  final Color color;
  const _Glow({required this.color});
  @override
  Widget build(BuildContext context) => Container(width: 260, height: 260, decoration: BoxDecoration(shape: BoxShape.circle, boxShadow: [BoxShadow(color: color, blurRadius: 90, spreadRadius: 70)]));
}

class _PremiumField extends StatelessWidget {
  final String hintText;
  final IconData icon;
  final ValueChanged<String>? onChanged;
  final TextEditingController? controller;
  final TextInputType? keyboardType;
  const _PremiumField({required this.hintText, required this.icon, this.onChanged, this.controller, this.keyboardType});

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      onChanged: onChanged,
      keyboardType: keyboardType,
      style: const TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.w700),
      decoration: InputDecoration(
        hintText: hintText,
        prefixIcon: Icon(icon, color: AppTheme.textSecondary),
        filled: true,
        fillColor: AppTheme.cardBackground.withOpacity(0.82),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(18), borderSide: const BorderSide(color: AppTheme.cardBorder)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(18), borderSide: const BorderSide(color: AppTheme.cardBorder)),
      ),
    );
  }
}

class _Panel extends StatelessWidget {
  final Widget child;
  const _Panel({super.key, required this.child});
  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(18),
    decoration: BoxDecoration(color: AppTheme.cardBackground.withOpacity(0.86), borderRadius: BorderRadius.circular(22), border: Border.all(color: Colors.white.withOpacity(0.08))),
    child: child,
  );
}

class _TrustChip extends StatelessWidget {
  final String label;
  const _TrustChip(this.label);
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    decoration: BoxDecoration(color: Colors.white.withOpacity(0.05), borderRadius: BorderRadius.circular(99), border: Border.all(color: Colors.white.withOpacity(0.08))),
    child: Text(label, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12, fontWeight: FontWeight.w700)),
  );
}

class _InsightList extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;
  final List<String> items;
  const _InsightList({required this.title, required this.icon, required this.color, required this.items});
  @override
  Widget build(BuildContext context) => _Panel(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    Text(title, style: TextStyle(color: color, fontWeight: FontWeight.w900, fontSize: 14)),
    const SizedBox(height: 12),
    ...items.map((item) => Padding(padding: const EdgeInsets.only(bottom: 9), child: Row(children: [
      Icon(icon, color: color, size: 18),
      const SizedBox(width: 10),
      Expanded(child: Text(item, style: const TextStyle(color: AppTheme.textPrimary, height: 1.3))),
    ]))),
  ]));
}

class _GrowthForecast extends StatelessWidget {
  const _GrowthForecast();
  @override
  Widget build(BuildContext context) => _Panel(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    const Text('Growth Potential', style: TextStyle(color: AppTheme.primary, fontWeight: FontWeight.w900)),
    const SizedBox(height: 10),
    const Text('Improving hooks, content structure, and posting consistency could increase engagement by 30-70% within 90 days.', style: TextStyle(color: AppTheme.textPrimary, height: 1.45)),
    const SizedBox(height: 16),
    SizedBox(height: 92, child: CustomPaint(painter: _GrowthCurvePainter(), child: const Align(alignment: Alignment.topRight, child: Text('+70%', style: TextStyle(color: AppTheme.success, fontWeight: FontWeight.w900))))),
  ]));
}

class _GrowthCurvePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = AppTheme.success..strokeWidth = 4..style = PaintingStyle.stroke..strokeCap = StrokeCap.round;
    final path = Path()
      ..moveTo(0, size.height * 0.82)
      ..cubicTo(size.width * 0.28, size.height * 0.74, size.width * 0.32, size.height * 0.38, size.width * 0.58, size.height * 0.42)
      ..cubicTo(size.width * 0.75, size.height * 0.45, size.width * 0.78, size.height * 0.1, size.width, size.height * 0.16);
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _BenefitRow extends StatelessWidget {
  final String label;
  const _BenefitRow(this.label);
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: Row(children: [
      const Icon(Icons.check_circle_rounded, color: AppTheme.success, size: 18),
      const SizedBox(width: 10),
      Expanded(child: Text(label, style: const TextStyle(color: AppTheme.textPrimary))),
    ]),
  );
}

class _PricingCard extends StatelessWidget {
  final String title;
  final String price;
  final String detail;
  final String? badge;
  const _PricingCard({required this.title, required this.price, required this.detail, this.badge});
  @override
  Widget build(BuildContext context) => _Panel(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    Row(children: [
      Expanded(child: Text(title, style: const TextStyle(color: AppTheme.textPrimary, fontSize: 17, fontWeight: FontWeight.w900))),
      if (badge != null) Container(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
        decoration: BoxDecoration(gradient: AppTheme.primaryGradient, borderRadius: BorderRadius.circular(99)),
        child: Text(badge!, style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w900)),
      ),
    ]),
    const SizedBox(height: 8),
    Text(price, style: const TextStyle(color: AppTheme.primary, fontSize: 20, fontWeight: FontWeight.w900)),
    const SizedBox(height: 6),
    Text(detail, style: const TextStyle(color: AppTheme.textSecondary, height: 1.35)),
  ]));
}
