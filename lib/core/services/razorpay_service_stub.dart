import 'dart:async';

/// Web stub for RazorpayService.
/// On web, real Razorpay checkout is not supported.
/// The app uses demo payment mode instead.
class RazorpayService {
  RazorpayService();

  Future<String> startPayment({
    required String keyId,
    required int amountInPaise,
    required String customerPhone,
    required String customerName,
  }) async {
    // Web: simulate a successful demo payment
    await Future.delayed(const Duration(milliseconds: 500));
    return 'WEB_DEMO_PAYMENT_${DateTime.now().millisecondsSinceEpoch}';
  }

  void dispose() {}
}
