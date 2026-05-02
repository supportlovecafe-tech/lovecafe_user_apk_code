import 'package:go_router/go_router.dart';

// Onboarding
import '../../presentation/customer/onboarding/splash_screen.dart';
import '../../presentation/customer/onboarding/welcome_screen.dart';

// Auth
import '../../presentation/customer/auth/login_screen.dart';
import '../../presentation/customer/auth/signup_screen.dart';
import '../../presentation/customer/auth/otp_verification_screen.dart';

// Core Experience
import '../../presentation/customer/home/home_screen.dart';
import '../../presentation/customer/menu/menu_screen.dart';

// Checkout Flow
import '../../presentation/customer/menu/cart_screen.dart';
import '../../presentation/customer/menu/checkout_screen.dart';
import '../../presentation/customer/menu/order_success_screen.dart';

// Orders & Profile
import '../../presentation/customer/orders/orders_screen.dart';
import '../../presentation/customer/profile/profile_screen.dart';
import '../../presentation/customer/profile/payment_methods_screen.dart';

final appRouter = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) => const SplashScreen(),
    ),
    GoRoute(
      path: '/welcome',
      builder: (context, state) => const WelcomeScreen(),
    ),
    GoRoute(
      path: '/login',
      builder: (context, state) => const LoginScreen(),
    ),
    GoRoute(
      path: '/signup',
      builder: (context, state) => const SignupScreen(),
    ),
    GoRoute(
      path: '/otp-verification',
      builder: (context, state) {
        final data = state.extra as Map<String, dynamic>;
        return OtpVerificationScreen(signupData: data);
      },
    ),
    GoRoute(
      path: '/home',
      builder: (context, state) => const HomeScreen(),
    ),
    GoRoute(
      path: '/menu',
      builder: (context, state) => const MenuScreen(),
    ),
    GoRoute(
      path: '/cart',
      builder: (context, state) => const CartScreen(),
    ),
    GoRoute(
      path: '/checkout',
      builder: (context, state) => const CheckoutScreen(),
    ),
    GoRoute(
      path: '/success',
      builder: (context, state) => const OrderSuccessScreen(),
    ),
    GoRoute(
      path: '/orders',
      builder: (context, state) => const OrdersScreen(),
    ),
    GoRoute(
      path: '/profile',
      builder: (context, state) => const ProfileScreen(),
    ),
    GoRoute(
      path: '/payment-methods',
      builder: (context, state) => const PaymentMethodsScreen(),
    ),
  ],
);
