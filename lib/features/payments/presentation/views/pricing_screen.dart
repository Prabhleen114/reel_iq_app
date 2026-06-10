import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/glass_card.dart';
import '../../../auth/presentation/viewmodels/auth_viewmodel.dart';
import '../viewmodels/payment_viewmodel.dart';

class PricingScreen extends StatefulWidget {
  const PricingScreen({super.key});

  @override
  State<PricingScreen> createState() => _PricingScreenState();
}

class _PricingScreenState extends State<PricingScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<PaymentViewModel>(context, listen: false).initRazorpay();
    });
  }

  @override
  void dispose() {
    Provider.of<PaymentViewModel>(context, listen: false).disposeRazorpay();
    super.dispose();
  }

  void _upgradeToPro() {
    final authVM = Provider.of<AuthViewModel>(context, listen: false);
    final paymentVM = Provider.of<PaymentViewModel>(context, listen: false);
    
    if (authVM.user == null) return;
    
    paymentVM.startPayment(
      userId: authVM.user!.uid,
      email: authVM.user!.email,
      name: authVM.user!.displayName,
    );
  }

  void _restorePurchase() async {
    final authVM = Provider.of<AuthViewModel>(context, listen: false);
    final paymentVM = Provider.of<PaymentViewModel>(context, listen: false);
    
    if (authVM.user == null) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Checking subscription status...'),
        backgroundColor: AppTheme.cardBackground,
      ),
    );

    final isPro = await paymentVM.checkProStatus(authVM.user!.uid);
    if (isPro) {
      await authVM.refreshUser(); // Refresh local auth user state
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Pro status restored!'),
            backgroundColor: AppTheme.success,
          ),
        );
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No active Pro subscription found.'),
            backgroundColor: AppTheme.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authVM = Provider.of<AuthViewModel>(context);
    final isAlreadyPro = authVM.user?.hasActivePro ?? false;

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('Upgrade to Pro'),
        leading: IconButton(
          icon: const Icon(Icons.close_rounded),
          onPressed: () => context.pop(),
        ),
      ),
      body: Consumer<PaymentViewModel>(
        builder: (context, paymentVM, child) {
          // Success State
          if (paymentVM.status == PaymentStatus.success) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0.0, end: 1.0),
                    duration: const Duration(milliseconds: 600),
                    curve: Curves.elasticOut,
                    builder: (context, value, child) {
                      return Transform.scale(
                        scale: value,
                        child: Container(
                          width: 80,
                          height: 80,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: AppTheme.primaryGradient,
                          ),
                          child: const Icon(Icons.check_rounded, color: Colors.white, size: 40),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Welcome to Pro!',
                    style: TextStyle(
                      color: AppTheme.textPrimary,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Your account has been upgraded.',
                    style: TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 32),
                  ElevatedButton(
                    onPressed: () {
                      paymentVM.reset();
                      authVM.refreshUser();
                      context.pop();
                    },
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                      backgroundColor: Colors.white.withOpacity(0.1),
                    ),
                    child: const Text('Return to Dashboard'),
                  ),
                ],
              ),
            );
          }

          // Error Snackbar handling
          if (paymentVM.status == PaymentStatus.failed && paymentVM.errorMessage.isNotEmpty) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(paymentVM.errorMessage),
                  backgroundColor: AppTheme.error,
                  behavior: SnackBarBehavior.floating,
                ),
              );
              paymentVM.reset();
            });
          }

          return Stack(
            children: [
              SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text(
                      'Supercharge Your Content',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: AppTheme.textPrimary,
                        fontSize: 28,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Get unlimited access to AI tools designed specifically for short-form creators.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: AppTheme.textSecondary,
                        fontSize: 15,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 32),

                    // Free Tier
                    GlassCard(
                      borderColor: Colors.white.withOpacity(0.1),
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Free Sandbox Tier',
                            style: TextStyle(
                              color: AppTheme.textPrimary,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 16),
                          _buildFeatureRow('5 Reel Audits per month', true, isFree: true),
                          _buildFeatureRow('1 Content Calendar', true, isFree: true),
                          _buildFeatureRow('Basic Analytics', true, isFree: true),
                          _buildFeatureRow('Hook Lab', false, isFree: true),
                          _buildFeatureRow('Weekly Creator Reports', false, isFree: true),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Pro Tier (Highlighted)
                    Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        gradient: AppTheme.primaryGradient,
                        boxShadow: [
                          BoxShadow(
                            color: AppTheme.primary.withOpacity(0.3),
                            blurRadius: 20,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      padding: const EdgeInsets.all(2), // Gradient border width
                      child: Container(
                        decoration: BoxDecoration(
                          color: AppTheme.cardBackground,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  'ReelIQ Pro',
                                  style: TextStyle(
                                    color: AppTheme.primary,
                                    fontSize: 22,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    gradient: AppTheme.primaryGradient,
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: const Text(
                                    'MOST POPULAR',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 9,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 1.2,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            const Row(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  '₹199',
                                  style: TextStyle(
                                    color: AppTheme.textPrimary,
                                    fontSize: 32,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Padding(
                                  padding: EdgeInsets.only(bottom: 6, left: 4),
                                  child: Text(
                                    '/month',
                                    style: TextStyle(
                                      color: AppTheme.textSecondary,
                                      fontSize: 14,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            const Text(
                              'Auto-renews monthly. Cancel anytime.',
                              style: TextStyle(
                                color: AppTheme.textMuted,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 20),
                            _buildFeatureRow('Unlimited Reel Audits', true),
                            _buildFeatureRow('Unlimited AI Content Calendars', true),
                            _buildFeatureRow('Full Analytics & Insights', true),
                            _buildFeatureRow('Hook Lab Access', true),
                            _buildFeatureRow('Weekly Creator Reports', true),
                            _buildFeatureRow('Public Profile Analysis', true),
                            _buildFeatureRow('Priority Support', true),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),

                    if (isAlreadyPro)
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppTheme.success.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppTheme.success.withOpacity(0.3)),
                        ),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.star_rounded, color: AppTheme.success),
                            SizedBox(width: 8),
                            Text(
                              "You're already a Pro!",
                              style: TextStyle(
                                color: AppTheme.success,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      )
                    else
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Container(
                            decoration: BoxDecoration(
                              gradient: AppTheme.primaryGradient,
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(
                                  color: AppTheme.primary.withOpacity(0.3),
                                  blurRadius: 12,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: ElevatedButton(
                              onPressed: (paymentVM.status == PaymentStatus.creatingOrder || 
                                         paymentVM.status == PaymentStatus.processingPayment ||
                                         paymentVM.status == PaymentStatus.verifying) 
                                         ? null 
                                         : _upgradeToPro,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.transparent,
                                shadowColor: Colors.transparent,
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: const Text(
                                'Upgrade to Pro',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          TextButton(
                            onPressed: _restorePurchase,
                            child: const Text(
                              'Restore Subscription / Check Status',
                              style: TextStyle(
                                color: AppTheme.textSecondary,
                                decoration: TextDecoration.underline,
                              ),
                            ),
                          ),
                        ],
                      ),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
              
              // Loading Overlay
              if (paymentVM.status == PaymentStatus.creatingOrder || 
                  paymentVM.status == PaymentStatus.processingPayment ||
                  paymentVM.status == PaymentStatus.verifying)
                Container(
                  color: Colors.black.withOpacity(0.7),
                  child: Center(
                    child: GlassCard(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const CircularProgressIndicator(color: AppTheme.primary),
                          const SizedBox(height: 16),
                          Text(
                            paymentVM.status == PaymentStatus.creatingOrder ? 'Setting up secure checkout...' :
                            paymentVM.status == PaymentStatus.verifying ? 'Verifying payment...' :
                            'Awaiting payment...',
                            style: const TextStyle(
                              color: AppTheme.textPrimary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildFeatureRow(String text, bool isIncluded, {bool isFree = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(
            isIncluded ? Icons.check_circle_rounded : Icons.cancel_rounded,
            color: isIncluded 
                ? (isFree ? AppTheme.textMuted : AppTheme.success) 
                : Colors.white.withOpacity(0.1),
            size: 20,
          ),
          const SizedBox(width: 12),
          Text(
            text,
            style: TextStyle(
              color: isIncluded ? AppTheme.textPrimary : AppTheme.textMuted.withOpacity(0.5),
              fontSize: 15,
              decoration: isIncluded ? TextDecoration.none : TextDecoration.lineThrough,
            ),
          ),
        ],
      ),
    );
  }
}
