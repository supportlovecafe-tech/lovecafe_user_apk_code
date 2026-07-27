import 'package:flutter/foundation.dart';

/// Native (Android/iOS) Razorpay service stub.
class RazorpayService {
  RazorpayService() {
    debugPrint("RazorpayService initialized (Native Stub)");
  }

  void openCheckout({
    required double amount,
    required String orderId,
    required String userPhone,
    required String userEmail,
    required Function(String paymentId) onSuccess,
    required Function(String message) onFailure,
  }) {
    onFailure("Razorpay online payments are not enabled for this release.");
  }

  void dispose() {}
}
