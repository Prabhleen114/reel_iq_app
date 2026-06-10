import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class PaymentApiService {
  /// Detects backend base URL (same pattern as other services in this app)
  String _getBaseUrl() {
    if (Platform.isAndroid) {
      return 'http://10.0.2.2:8000';
    } else {
      return 'http://127.0.0.1:8000';
    }
  }

  /// Creates a Razorpay subscription via the backend
  Future<Map<String, dynamic>> createSubscription({
    required String userId,
  }) async {
    final url = '${_getBaseUrl()}/payments/create-subscription';
    debugPrint('[PaymentApiService] Creating subscription: $url');

    final response = await http.post(
      Uri.parse(url),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'user_id': userId,
      }),
    );

    debugPrint('[PaymentApiService] Create subscription response: ${response.statusCode}');

    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    } else {
      throw Exception('Failed to create subscription: ${response.body}');
    }
  }

  /// Verifies subscription signature via the backend
  Future<Map<String, dynamic>> verifySubscription({
    required String subscriptionId,
    required String paymentId,
    required String signature,
    required String userId,
  }) async {
    final url = '${_getBaseUrl()}/payments/verify-subscription';
    debugPrint('[PaymentApiService] Verifying subscription: $url');

    final response = await http.post(
      Uri.parse(url),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'subscription_id': subscriptionId,
        'payment_id': paymentId,
        'signature': signature,
        'user_id': userId,
      }),
    );

    debugPrint('[PaymentApiService] Verify response: ${response.statusCode}');

    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    } else {
      throw Exception('Subscription verification failed: ${response.body}');
    }
  }
}
