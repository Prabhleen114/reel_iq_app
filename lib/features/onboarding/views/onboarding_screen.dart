import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/glass_card.dart';
import '../../../core/widgets/gradient_button.dart';
import '../../auth/presentation/viewmodels/auth_viewmodel.dart';
import '../viewmodels/onboarding_viewmodel.dart';

class OnboardingScreen extends StatelessWidget {
  const OnboardingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => OnboardingViewModel(),
      child: const _OnboardingScreenContent(),
    );
  }
}

class _OnboardingScreenContent extends StatefulWidget {
  const _OnboardingScreenContent();

  @override
  State<_OnboardingScreenContent> createState() => _OnboardingScreenContentState();
}

class _OnboardingScreenContentState extends State<_OnboardingScreenContent> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _nextPage() {
    if (_currentPage < 2) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  Future<void> _handleStep1Submit(OnboardingViewModel vm) async {
    final authVm = Provider.of<AuthViewModel>(context, listen: false);
    if (authVm.user == null) return;
    
    final success = await vm.analyzeInstagram(authVm.user!.uid);
    if (success && mounted) {
      _nextPage();
    }
  }

  Future<void> _handleFinalSubmit(OnboardingViewModel vm) async {
    final authVm = Provider.of<AuthViewModel>(context, listen: false);
    await vm.completeOnboarding(authVm);
    if (mounted && vm.error == null) {
      context.go('/');
    }
  }

  @override
  Widget build(BuildContext context) {
    final vm = Provider.of<OnboardingViewModel>(context);

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'STEP ${_currentPage + 1}/3',
                  style: const TextStyle(
                    color: AppTheme.textMuted,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 2.0,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(3, (index) {
                final isActive = index <= _currentPage;
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  width: isActive ? 32 : 12,
                  height: 4,
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  decoration: BoxDecoration(
                    color: isActive ? AppTheme.primary : AppTheme.cardBorder,
                    borderRadius: BorderRadius.circular(4),
                  ),
                );
              }),
            ),
            if (vm.error != null)
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(vm.error!, style: const TextStyle(color: AppTheme.error)),
              ),
            Expanded(
              child: PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(), // Disable swipe
                onPageChanged: (index) => setState(() => _currentPage = index),
                children: [
                  _buildStep1(vm),
                  _buildStep2(vm),
                  _buildStep3(vm),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStep1(OnboardingViewModel vm) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Icon(Icons.person_search_rounded, size: 64, color: AppTheme.accent),
          const SizedBox(height: 24),
          const Text(
            'Connect Your Instagram',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white),
          ),
          const SizedBox(height: 12),
          const Text(
            'We will use this to personalize your dashboard and analyze your niche.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 16, color: AppTheme.textSecondary),
          ),
          const SizedBox(height: 32),
          TextField(
            onChanged: vm.setHandle,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: '@username',
              hintStyle: const TextStyle(color: AppTheme.textMuted),
              filled: true,
              fillColor: AppTheme.cardBackground,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              prefixIcon: const Icon(Icons.alternate_email, color: AppTheme.textMuted),
            ),
          ),
          const SizedBox(height: 32),
          GradientButton(
            text: 'Continue',
            onPressed: vm.isLoading || vm.handle.isEmpty ? null : () => _handleStep1Submit(vm),
            isLoading: vm.isLoading,
          ),
        ],
      ),
    );
  }

  Widget _buildStep2(OnboardingViewModel vm) {
    final availableInterests = [
      'Technology', 'AI', 'Coding', 'Business', 'Finance', 'Education', 
      'Fitness', 'Gaming', 'Travel', 'Fashion', 'Motivation', 'Entertainment', 'Lifestyle'
    ];

    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 40),
          const Text(
            'What do you create about?',
            style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white),
          ),
          const SizedBox(height: 12),
          const Text(
            'Select all that apply. This helps us generate personalized reel ideas.',
            style: TextStyle(fontSize: 16, color: AppTheme.textSecondary),
          ),
          const SizedBox(height: 32),
          Expanded(
            child: SingleChildScrollView(
              child: Wrap(
                spacing: 12,
                runSpacing: 12,
                children: availableInterests.map((interest) {
                  final isSelected = vm.interests.contains(interest);
                  return FilterChip(
                    label: Text(interest),
                    selected: isSelected,
                    onSelected: (_) => vm.toggleInterest(interest),
                    selectedColor: AppTheme.primary.withOpacity(0.3),
                    checkmarkColor: AppTheme.primary,
                    backgroundColor: AppTheme.cardBackground,
                    side: BorderSide(
                      color: isSelected ? AppTheme.primary : AppTheme.cardBorder,
                    ),
                    labelStyle: TextStyle(
                      color: isSelected ? Colors.white : AppTheme.textSecondary,
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
          GradientButton(
            text: 'Continue',
            onPressed: vm.interests.isEmpty ? null : _nextPage,
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildStep3(OnboardingViewModel vm) {
    final confidenceLevels = [
      'Very Comfortable',
      'Comfortable',
      'Nervous',
      'Camera Shy'
    ];

    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 40),
          const Text(
            'How comfortable are you on camera?',
            style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white),
          ),
          const SizedBox(height: 12),
          const Text(
            'We will use this to recommend faceless vs talking-head content.',
            style: TextStyle(fontSize: 16, color: AppTheme.textSecondary),
          ),
          const SizedBox(height: 32),
          Expanded(
            child: ListView.builder(
              itemCount: confidenceLevels.length,
              itemBuilder: (context, index) {
                final level = confidenceLevels[index];
                final isSelected = vm.cameraConfidence == level;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12.0),
                  child: InkWell(
                    onTap: () => vm.setCameraConfidence(level),
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: isSelected ? AppTheme.primary.withOpacity(0.2) : AppTheme.cardBackground,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isSelected ? AppTheme.primary : AppTheme.cardBorder,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            isSelected ? Icons.radio_button_checked : Icons.radio_button_unchecked,
                            color: isSelected ? AppTheme.primary : AppTheme.textMuted,
                          ),
                          const SizedBox(width: 16),
                          Text(
                            level,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                              color: isSelected ? Colors.white : AppTheme.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          GradientButton(
            text: 'Complete Setup',
            onPressed: vm.isLoading || vm.cameraConfidence.isEmpty ? null : () => _handleFinalSubmit(vm),
            isLoading: vm.isLoading,
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}
