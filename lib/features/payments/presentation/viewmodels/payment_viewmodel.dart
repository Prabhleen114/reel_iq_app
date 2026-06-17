import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import '../../../../core/services/firestore_service.dart';
import '../../../auth/data/models/user_model.dart';
import '../../data/services/payment_service.dart';

enum PaymentStatus { idle, creatingOrder, processingPayment, verifying, success, failed }

class PaymentViewModel extends ChangeNotifier {
  final PaymentApiService _paymentApiService;
  final FirestoreService _firestoreService;
  final InAppPurchase _inAppPurchase = InAppPurchase.instance;

  late StreamSubscription<List<PurchaseDetails>> _subscription;

  PaymentViewModel(this._paymentApiService, this._firestoreService) {
    _initIAP();
  }

  PaymentStatus _status = PaymentStatus.idle;
  PaymentStatus get status => _status;

  String _errorMessage = '';
  String get errorMessage => _errorMessage;

  String _successPaymentId = '';
  String get successPaymentId => _successPaymentId;

  String _currentUserId = '';
  static const String _productId = 'reeliq_pro_monthly';

  void _initIAP() {
    final Stream<List<PurchaseDetails>> purchaseUpdated = _inAppPurchase.purchaseStream;
    _subscription = purchaseUpdated.listen((purchaseDetailsList) {
      _listenToPurchaseUpdated(purchaseDetailsList);
    }, onDone: () {
      _subscription.cancel();
    }, onError: (error) {
      _status = PaymentStatus.failed;
      _errorMessage = 'In-App Purchase failed to initialize: $error';
      notifyListeners();
    });
  }

  void _listenToPurchaseUpdated(List<PurchaseDetails> purchaseDetailsList) {
    for (var purchaseDetails in purchaseDetailsList) {
      if (purchaseDetails.status == PurchaseStatus.pending) {
        _status = PaymentStatus.processingPayment;
        notifyListeners();
      } else {
        if (purchaseDetails.status == PurchaseStatus.error) {
          _handlePaymentError(purchaseDetails.error!);
        } else if (purchaseDetails.status == PurchaseStatus.purchased ||
            purchaseDetails.status == PurchaseStatus.restored) {
          _handlePaymentSuccess(purchaseDetails);
        }
        if (purchaseDetails.pendingCompletePurchase) {
          _inAppPurchase.completePurchase(purchaseDetails);
        }
      }
    }
  }

  Future<void> startPayment({
    required String userId,
    required String email,
    required String name,
    String phone = '',
  }) async {
    _currentUserId = userId;
    _errorMessage = '';
    _status = PaymentStatus.creatingOrder;
    notifyListeners();

    final bool available = await _inAppPurchase.isAvailable();
    if (!available) {
      _status = PaymentStatus.failed;
      _errorMessage = 'Store is currently not available.';
      notifyListeners();
      return;
    }

    const Set<String> kIds = <String>{_productId};
    final ProductDetailsResponse response = await _inAppPurchase.queryProductDetails(kIds);

    if (response.notFoundIDs.isNotEmpty) {
      _status = PaymentStatus.failed;
      _errorMessage = 'Product not found. Please ensure it is configured in the Play Console.';
      notifyListeners();
      return;
    }

    final ProductDetails productDetails = response.productDetails.first;
    final PurchaseParam purchaseParam = PurchaseParam(productDetails: productDetails);

    try {
      _status = PaymentStatus.processingPayment;
      notifyListeners();
      await _inAppPurchase.buyNonConsumable(purchaseParam: purchaseParam);
    } catch (e) {
      _status = PaymentStatus.failed;
      _errorMessage = 'Failed to start purchase: $e';
      notifyListeners();
    }
  }

  Future<void> restorePurchases(String userId) async {
    _currentUserId = userId;
    _status = PaymentStatus.processingPayment;
    notifyListeners();
    try {
      await _inAppPurchase.restorePurchases();
    } catch (e) {
      _status = PaymentStatus.failed;
      _errorMessage = 'Failed to restore purchases: $e';
      notifyListeners();
    }
  }

  Future<void> _handlePaymentSuccess(PurchaseDetails purchaseDetails) async {
    debugPrint('[PaymentVM] Payment success: ${purchaseDetails.purchaseID}');
    _status = PaymentStatus.verifying;
    notifyListeners();

    try {
      // Verify signature on backend
      final verifyResult = await _paymentApiService.verifySubscription(
        purchaseToken: purchaseDetails.verificationData.serverVerificationData,
        productId: purchaseDetails.productID,
        userId: _currentUserId,
      );

      if (verifyResult['verified'] == true) {
        debugPrint('[PaymentVM] Payment verified. Activating Pro...');

        await _firestoreService.savePaymentRecord(
          purchaseDetails.purchaseID ?? purchaseDetails.productID,
          {
            'userId': _currentUserId,
            'paymentId': purchaseDetails.purchaseID,
            'productId': purchaseDetails.productID,
            'purchaseToken': purchaseDetails.verificationData.serverVerificationData,
            'planName': 'ReelIQ Pro Monthly',
            'status': purchaseDetails.status == PurchaseStatus.restored ? 'restored' : 'captured',
            'createdAt': DateTime.now().toIso8601String(),
          },
        );

        await _firestoreService.activateProStatus(
          _currentUserId,
          subscriptionId: purchaseDetails.purchaseID ?? 'restored_sub',
          planName: 'ReelIQ Pro Monthly',
        );

        _successPaymentId = purchaseDetails.purchaseID ?? '';
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

  void _handlePaymentError(IAPError error) {
    debugPrint('[PaymentVM] Payment failed: ${error.code} - ${error.message}');
    _status = PaymentStatus.failed;
    _errorMessage = error.message;
    notifyListeners();
  }

  void reset() {
    _status = PaymentStatus.idle;
    _errorMessage = '';
    _successPaymentId = '';
    notifyListeners();
  }

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
    _subscription.cancel();
    super.dispose();
  }
}
