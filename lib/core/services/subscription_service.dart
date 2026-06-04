import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:shared_preferences/shared_preferences.dart';

// ─── Feature Flags ───────────────────────────────────────────────────────────
/// Set to true when your app is live on Play Store / App Store with active IAP.
const bool kBillingEnabled = false;

/// Product IDs configured in Play Console / App Store Connect.
const String kProMonthlyProductId = 'reeliq_pro_monthly_199';
const String kProYearlyProductId = 'reeliq_pro_yearly_1499';

// ─── Plan Limits ─────────────────────────────────────────────────────────────
const int kFreeAnalysesPerMonth = 5;
const int kFreeCalendarsPerMonth = 1;

/// Abstract contract for subscription management.
abstract class SubscriptionService extends ChangeNotifier {
  bool get isPro;
  int get maxAnalyses;
  int get maxCalendars;
  bool get weeklyReportsEnabled;

  Future<void> initialize();
  Future<void> purchasePro();
  Future<void> restorePurchases();
  Future<void> cancelPro();
}

// ─────────────────────────────────────────────────────────────────────────────
// LOCAL SUBSCRIPTION SERVICE
// Works offline, persists via SharedPreferences.
// Used when kBillingEnabled = false OR as fallback.
// ─────────────────────────────────────────────────────────────────────────────

class LocalSubscriptionService extends SubscriptionService {
  bool _isPro = false;
  DateTime? _planExpiry;

  @override
  bool get isPro => _isPro && (_planExpiry == null || _planExpiry!.isAfter(DateTime.now()));

  @override
  int get maxAnalyses => isPro ? 999999 : kFreeAnalysesPerMonth;

  @override
  int get maxCalendars => isPro ? 999999 : kFreeCalendarsPerMonth;

  @override
  bool get weeklyReportsEnabled => isPro;

  @override
  Future<void> initialize() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _isPro = prefs.getBool('reeliq_is_pro') ?? false;
      final expiryStr = prefs.getString('reeliq_plan_expiry');
      if (expiryStr != null) {
        _planExpiry = DateTime.tryParse(expiryStr);
      }
      notifyListeners();
    } catch (e) {
      debugPrint('LocalSubscriptionService.initialize error: $e');
    }
  }

  /// Simulate a Pro upgrade (used for testing / demo mode).
  Future<void> simulateProUpgrade({int durationDays = 30}) async {
    _isPro = true;
    _planExpiry = DateTime.now().add(Duration(days: durationDays));
    await _persist();
    notifyListeners();
  }

  @override
  Future<void> purchasePro() async {
    // In local mode, simulate immediate upgrade
    await simulateProUpgrade();
  }

  @override
  Future<void> restorePurchases() async {
    // No-op in local mode
    debugPrint('LocalSubscriptionService: restorePurchases (local mock — no-op)');
  }

  @override
  Future<void> cancelPro() async {
    _isPro = false;
    _planExpiry = null;
    await _persist();
    notifyListeners();
  }

  Future<void> _persist() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('reeliq_is_pro', _isPro);
      if (_planExpiry != null) {
        await prefs.setString('reeliq_plan_expiry', _planExpiry!.toIso8601String());
      } else {
        await prefs.remove('reeliq_plan_expiry');
      }
    } catch (e) {
      debugPrint('LocalSubscriptionService._persist error: $e');
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// IN-APP PURCHASE SUBSCRIPTION SERVICE
// Full Google Play Billing / StoreKit integration.
// Activate by setting kBillingEnabled = true in production builds.
// ─────────────────────────────────────────────────────────────────────────────

class InAppPurchaseSubscriptionService extends SubscriptionService {
  final InAppPurchase _iap = InAppPurchase.instance;
  StreamSubscription<List<PurchaseDetails>>? _purchaseSubscription;

  bool _isPro = false;
  DateTime? _planExpiry;

  @override
  bool get isPro => _isPro;

  @override
  int get maxAnalyses => isPro ? 999999 : kFreeAnalysesPerMonth;

  @override
  int get maxCalendars => isPro ? 999999 : kFreeCalendarsPerMonth;

  @override
  bool get weeklyReportsEnabled => isPro;

  @override
  Future<void> initialize() async {
    if (!kBillingEnabled) {
      debugPrint('InAppPurchaseSubscriptionService: Billing disabled by feature flag');
      return;
    }

    final available = await _iap.isAvailable();
    if (!available) {
      debugPrint('InAppPurchaseSubscriptionService: Store not available');
      return;
    }

    // Restore local state
    final prefs = await SharedPreferences.getInstance();
    _isPro = prefs.getBool('reeliq_is_pro') ?? false;

    // Listen to purchase updates
    _purchaseSubscription = _iap.purchaseStream.listen(
      _handlePurchaseUpdates,
      onError: (e) => debugPrint('IAP stream error: $e'),
    );

    // Restore previous purchases on init
    await _iap.restorePurchases();
    notifyListeners();
  }

  void _handlePurchaseUpdates(List<PurchaseDetails> purchases) async {
    for (final purchase in purchases) {
      if (purchase.status == PurchaseStatus.purchased ||
          purchase.status == PurchaseStatus.restored) {
        if (purchase.productID == kProMonthlyProductId ||
            purchase.productID == kProYearlyProductId) {
          _isPro = true;
          _planExpiry = purchase.productID == kProYearlyProductId
              ? DateTime.now().add(const Duration(days: 365))
              : DateTime.now().add(const Duration(days: 30));
          await _persistPro();
        }
        if (purchase.pendingCompletePurchase) {
          await _iap.completePurchase(purchase);
        }
      } else if (purchase.status == PurchaseStatus.error) {
        debugPrint('IAP purchase error: ${purchase.error?.message}');
      }
    }
    notifyListeners();
  }

  @override
  Future<void> purchasePro() async {
    if (!kBillingEnabled) return;
    final response = await _iap.queryProductDetails({kProMonthlyProductId});
    if (response.productDetails.isEmpty) {
      debugPrint('InAppPurchaseSubscriptionService: Product not found');
      return;
    }
    final purchaseParam = PurchaseParam(
      productDetails: response.productDetails.first,
    );
    await _iap.buyNonConsumable(purchaseParam: purchaseParam);
  }

  @override
  Future<void> restorePurchases() async {
    if (!kBillingEnabled) return;
    await _iap.restorePurchases();
  }

  @override
  Future<void> cancelPro() async {
    _isPro = false;
    _planExpiry = null;
    await _persistPro();
    notifyListeners();
  }

  Future<void> _persistPro() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('reeliq_is_pro', _isPro);
    if (_planExpiry != null) {
      await prefs.setString('reeliq_plan_expiry', _planExpiry!.toIso8601String());
    }
  }

  @override
  void dispose() {
    _purchaseSubscription?.cancel();
    super.dispose();
  }
}

/// Factory that returns the correct [SubscriptionService] based on [kBillingEnabled].
SubscriptionService createSubscriptionService() {
  if (kBillingEnabled) {
    return InAppPurchaseSubscriptionService();
  }
  return LocalSubscriptionService();
}
