import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/glass_card.dart';
import '../../data/models/hook_test_model.dart';
import '../viewmodels/hook_testing_viewmodel.dart';

class HookTestingScreen extends StatefulWidget {
  final bool embeddedMode;

  const HookTestingScreen({
    super.key,
    this.embeddedMode = false,
  });

  @override
  State<HookTestingScreen> createState() => _HookTestingScreenState();
}

class _HookTestingScreenState extends State<HookTestingScreen> {
  final _hookAController = TextEditingController();
  final _hookBController = TextEditingController();
  final _hookCController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final hookVM = Provider.of<HookTestingViewModel>(context, listen: false);
      _hookAController.text = hookVM.hookA;
      _hookBController.text = hookVM.hookB;
      _hookCController.text = hookVM.hookC;
    });
  }

  @override
  void dispose() {
    _hookAController.dispose();
    _hookBController.dispose();
    _hookCController.dispose();
    super.dispose();
  }

  void _runComparison() async {
    final hookVM = Provider.of<HookTestingViewModel>(context, listen: false);
    hookVM.setHookA(_hookAController.text);
    hookVM.setHookB(_hookBController.text);
    hookVM.setHookC(_hookCController.text);

    await hookVM.runTest();
  }

  void _reset() {
    _hookAController.clear();
    _hookBController.clear();
    _hookCController.clear();
    Provider.of<HookTestingViewModel>(context, listen: false).clearTest();
  }

  @override
  Widget build(BuildContext context) {
    final hookVM = Provider.of<HookTestingViewModel>(context);
    final size = MediaQuery.of(context).size;
    final isTablet = size.width > 600;

    final body = SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(20, widget.embeddedMode ? 64 : 16, 20, 32),
      child: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: isTablet ? 800 : double.infinity,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
              if (widget.embeddedMode) ...[
                const Text(
                  'Hook Testing Lab',
                  style: TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Test multiple Hook lines to determine which will maximize retention.',
                  style: TextStyle(color: AppTheme.textMuted, fontSize: 13),
                ),
                const SizedBox(height: 24),
              ],

              // Show Error
              if (hookVM.errorMessage != null)
                Container(
                  padding: const EdgeInsets.all(12),
                  margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(
                    color: AppTheme.error.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppTheme.error.withOpacity(0.3)),
                  ),
                  child: Text(
                    hookVM.errorMessage!,
                    style: const TextStyle(color: AppTheme.error, fontSize: 13),
                  ),
                ),

              // Inputs View
              if (hookVM.results.isEmpty) ...[
                _buildHookInputField(
                  label: 'Option A (Linguistic / Benefit-driven)',
                  hint: 'e.g. Stop wasting 5 hours coding this manually...',
                  controller: _hookAController,
                  gradientColors: [AppTheme.primary, AppTheme.secondary],
                  enabled: !hookVM.isLoading,
                ),
                const SizedBox(height: 16),
                _buildHookInputField(
                  label: 'Option B (Question / Curiosity gap)',
                  hint: 'e.g. Is this the most underrated VS Code extension?',
                  controller: _hookBController,
                  gradientColors: [AppTheme.secondary, AppTheme.accent],
                  enabled: !hookVM.isLoading,
                ),
                const SizedBox(height: 16),
                _buildHookInputField(
                  label: 'Option C (Contrarian / Unpopular opinion)',
                  hint: 'e.g. Why most software developer portfolios are garbage...',
                  controller: _hookCController,
                  gradientColors: [AppTheme.accent, AppTheme.primary],
                  enabled: !hookVM.isLoading,
                ),
                const SizedBox(height: 28),
                ElevatedButton.icon(
                  onPressed: hookVM.isLoading ? null : _runComparison,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  icon: hookVM.isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Icon(Icons.compare_arrows_rounded, color: Colors.white),
                  label: Text(hookVM.isLoading ? 'Analyzing Hook Phrasing...' : 'Compare Hooks'),
                ),
              ]

              // Results View
              else ...[
                // Winner Announcement
                if (hookVM.bestHook != null) ...[
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: AppTheme.accentGradient,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.accent.withOpacity(0.2),
                          blurRadius: 16,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.workspace_premium_rounded, size: 36, color: Colors.white),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'WINNER DETERMINED',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 1.5,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${hookVM.bestHook!.label} performs best with a Score of ${hookVM.bestHook!.score}%',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                ],

                // Grid list or Column based on view size
                isTablet
                    ? Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: hookVM.results.map((r) => Expanded(child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 6.0),
                          child: _buildResultCard(r),
                        ))).toList(),
                      )
                    : Column(
                        children: hookVM.results.map((r) => Padding(
                          padding: const EdgeInsets.only(bottom: 16.0),
                          child: _buildResultCard(r),
                        )).toList(),
                      ),

                const SizedBox(height: 24),
                OutlinedButton.icon(
                  onPressed: _reset,
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    side: BorderSide(color: Colors.white.withOpacity(0.12)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  icon: const Icon(Icons.restart_alt_rounded, color: Colors.white),
                  label: const Text('Test New Hook Variations', style: TextStyle(color: Colors.white)),
                ),
              ],
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
        title: const Text('Hook Testing Lab'),
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

  Widget _buildHookInputField({
    required String label,
    required String hint,
    required TextEditingController controller,
    required List<Color> gradientColors,
    required bool enabled,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 8,
              height: 16,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(4),
                gradient: LinearGradient(colors: gradientColors),
              ),
            ),
            const SizedBox(width: 10),
            Text(
              label,
              style: const TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        TextField(
          controller: controller,
          enabled: enabled,
          maxLines: 2,
          minLines: 2,
          textCapitalization: TextCapitalization.sentences,
          maxLength: 120,
          decoration: InputDecoration(
            hintText: hint,
            counterText: '', // Hide default counter
            contentPadding: const EdgeInsets.all(16),
          ),
        ),
      ],
    );
  }

  Widget _buildResultCard(HookTestModel item) {
    return GlassCard(
      borderColor: item.isBest ? AppTheme.accent.withOpacity(0.4) : null,
      backgroundColor: item.isBest ? AppTheme.accent.withOpacity(0.04) : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                item.label,
                style: TextStyle(
                  color: item.isBest ? AppTheme.accent : AppTheme.textPrimary,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              if (item.isBest)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppTheme.accent.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: AppTheme.accent.withOpacity(0.2)),
                  ),
                  child: const Text(
                    'BEST',
                    style: TextStyle(color: AppTheme.accent, fontSize: 9, fontWeight: FontWeight.bold),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            '"${item.hookText}"',
            style: const TextStyle(
              color: AppTheme.textPrimary,
              fontSize: 13,
              fontStyle: FontStyle.italic,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 16),
          const Divider(color: Colors.white10),
          const SizedBox(height: 8),
          Row(
            children: [
              Text(
                'Score: ',
                style: TextStyle(color: AppTheme.textMuted, fontSize: 13),
              ),
              Text(
                '${item.score}%',
                style: TextStyle(
                  color: item.score >= 80 
                      ? AppTheme.success 
                      : item.score >= 65 
                          ? AppTheme.warning 
                          : AppTheme.error,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            item.feedback,
            style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12, height: 1.4),
          ),
        ],
      ),
    );
  }
}
