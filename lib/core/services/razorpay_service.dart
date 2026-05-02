import 'dart:async';
import 'package:razorpay_flutter/razorpay_flutter.dart';

class RazorpayService {
  final Razorpay _razorpay = Razorpay();
  Completer<String>? _paymentCompleter;

  RazorpayService() {
    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _onSuccess);
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _onError);
    _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, _onExternalWallet);
  }

  Future<String> startPayment({
    required String keyId,
    required int amountInPaise,
    required String customerPhone,
    required String customerName,
  }) {
    _paymentCompleter = Completer<String>();
    _razorpay.open({
      'key': keyId,
      'amount': amountInPaise,
      'name': 'Cinema Eats',
      'description': 'Movie food order',
      'prefill': {
        'contact': customerPhone,
        'name': customerName,
      },
      'theme': {'color': '#D32F2F'},
    });
    return _paymentCompleter!.future;
  }

  void dispose() {
    _razorpay.clear();
  }

  void _onSuccess(PaymentSuccessResponse response) {
    _paymentCompleter?.complete(response.paymentId ?? 'success');
  }

  void _onError(PaymentFailureResponse response) {
    _paymentCompleter?.completeError(
      'Payment failed (${response.code}): ${response.message}',
    );
  }

  void _onExternalWallet(ExternalWalletResponse response) {
    _paymentCompleter?.complete(response.walletName ?? 'wallet');
  }
}
