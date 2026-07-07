// Web-safe stub: razorpay_flutter does not support web platform.
// On web, payment is handled via demo/bypass mode only.
// ignore: uri_does_not_exist

export 'razorpay_service_stub.dart'
    if (dart.library.io) 'razorpay_service_native.dart';
