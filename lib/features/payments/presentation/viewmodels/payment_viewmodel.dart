import 'package:flutter/foundation.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import '../../../../core/services/firestore_service.dart';
import '../../../auth/data/models/user_model.dart';
import '../../data/services/payment_service.dart';

enum PaymentStatus { idle, creatingOrder, processingPayment, verifying, success, failed }

class PaymentViewModel extends ChangeNotifier {
  final PaymentApiService _paymentApiService;
  final FirestoreService _firestoreService;

  PaymentViewModel(this._paymentApiService, this._firestoreService);

  PaymentStatus _status = PaymentStatus.idle;
  PaymentStatus get status => _status;

  String _errorMessage = '';
  String get errorMessage => _errorMessage;

  String _successPaymentId = '';
  String get successPaymentId => _successPaymentId;

  // Razorpay instance
  Razorpay? _razorpay;
  String _currentSubscriptionId = '';
  String _currentUserId = '';
  String _currentKeyId = '';
  String _currentUserEmail = '';
  String _currentUserName = '';
  String _currentUserPhone = '';

  /// Initialize Razorpay listeners
  void initRazorpay() {
    _razorpay = Razorpay();
    _razorpay!.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handlePaymentSuccess);
    _razorpay!.on(Razorpay.EVENT_PAYMENT_ERROR, _handlePaymentError);
    _razorpay!.on(Razorpay.EVENT_EXTERNAL_WALLET, _handleExternalWallet);
  }

  /// Dispose Razorpay listeners
  void disposeRazorpay() {
    _razorpay?.clear();
  }

  /// Start the subscription flow
  Future<void> startPayment({
    required String userId,
    required String email,
    required String name,
    String phone = '',
  }) async {
    _currentUserId = userId;
    _currentUserEmail = email;
    _currentUserName = name;
    _currentUserPhone = phone;
    _errorMessage = '';
    _status = PaymentStatus.creatingOrder;
    notifyListeners();

    try {
      // Step 1: Create subscription on backend
      debugPrint('[PaymentVM] Creating subscription for user: $userId');
      final subData = await _paymentApiService.createSubscription(userId: userId);

      _currentSubscriptionId = subData['subscription_id'] as String;
      _currentKeyId = subData['key_id'] as String;

      debugPrint('[PaymentVM] Subscription created: $_currentSubscriptionId');

      // Step 2: Open Razorpay Checkout
      _status = PaymentStatus.processingPayment;
      notifyListeners();

      final options = {
        'key': _currentKeyId,
        'subscription_id': _currentSubscriptionId,
        'name': 'ReelIQ',
        'description': 'ReelIQ Pro - Monthly Subscription',
        'prefill': {
          'email': email,
          'contact': phone,
          'name': name,
        },
        'theme': {
          'color': '#FF4D8D',
        },
        'modal': {
          'confirm_close': true,
        },
      };

      debugPrint('[PaymentVM] Opening Razorpay checkout...');
      _razorpay!.open(options);
    } catch (e) {
      debugPrint('[PaymentVM] Error creating subscription: $e');
      _status = PaymentStatus.failed;
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
    }
  }

  /// Handle successful payment from Razorpay SDK
  void _handlePaymentSuccess(PaymentSuccessResponse response) async {
    debugPrint('[PaymentVM] Payment success: ${response.paymentId}');
    _status = PaymentStatus.verifying;
    notifyListeners();

    try {
      // Step 3: Verify signature on backend
      final verifyResult = await _paymentApiService.verifySubscription(
        subscriptionId: response.subscriptionId ?? _currentSubscriptionId,
        paymentId: response.paymentId ?? '',
        signature: response.signature ?? '',
        userId: _currentUserId,
      );

      if (verifyResult['verified'] == true) {
        debugPrint('[PaymentVM] Payment verified. Activating Pro...');

        // Step 4: Save payment record to Firestore
        await _firestoreService.savePaymentRecord(
          response.paymentId ?? '',
          {
            'userId': _currentUserId,
            'paymentId': response.paymentId ?? '',
            'subscriptionId': response.subscriptionId ?? _currentSubscriptionId,
            'signature': response.signature ?? '',
            'planName': 'ReelIQ Pro',
            'status': 'captured',
            'createdAt': DateTime.now().toIso8601String(),
          },
        );

        // Step 5: Update user Pro status
        await _firestoreService.activateProStatus(
          _currentUserId,
          subscriptionId: response.subscriptionId ?? _currentSubscriptionId,
          planName: 'ReelIQ Pro',
        );

        _successPaymentId = response.paymentId ?? '';
        _status = PaymentStatus.success;
      } else {
        _status = PaymentStatus.failed;
        _errorMessage = 'Payment verification failed on server.';
      }
    } catch (e) {
      debugPrint('[PaymentVM] Verification error: $e');
      _status = PaymentStatus.failed;
      _errorMessage = 'Verification failed: ${e.toString().replaceAll('Exception: ', '')}';
    }
    notifyListeners();
  }

  /// Handle payment failure from Razorpay SDK
  void _handlePaymentError(PaymentFailureResponse response) {
    debugPrint('[PaymentVM] Payment failed: ${response.code} - ${response.message}');
    _status = PaymentStatus.failed;
    _errorMessage = response.message ?? 'Payment was cancelled or failed.';
    notifyListeners();
  }

  /// Handle external wallet selection
  void _handleExternalWallet(ExternalWalletResponse response) {
    debugPrint('[PaymentVM] External wallet: ${response.walletName}');
    // External wallet selected - Razorpay will handle the flow
  }

  /// Reset state for retry
  void reset() {
    _status = PaymentStatus.idle;
    _errorMessage = '';
    _successPaymentId = '';
    notifyListeners();
  }

  /// Check if user has an active Pro subscription
  Future<bool> checkProStatus(String userId) async {
    try {
      final user = await _firestoreService.getUser(userId);
      return user?.hasActivePro ?? false;
    } catch (e) {
      debugPrint('[PaymentVM] Error checking pro status: $e');
      return false;
    }
  }

  @override
  void dispose() {
    disposeRazorpay();
    super.dispose();
  }
}
