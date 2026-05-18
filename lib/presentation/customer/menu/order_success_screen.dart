import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';

class OrderSuccessScreen extends StatefulWidget {
  final Map<String, dynamic>? extra;
  const OrderSuccessScreen({super.key, this.extra});

  @override
  State<OrderSuccessScreen> createState() => _OrderSuccessScreenState();
}

class _OrderSuccessScreenState extends State<OrderSuccessScreen> {
  @override
  void initState() {
    super.initState();
    // Auto-redirect to tracking after 5 seconds
    Future.delayed(const Duration(seconds: 5), () {
      if (mounted) {
        context.go('/orders');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final orderId = widget.extra?['orderId'] ?? widget.extra?['displayId'] ?? '#ORD-8829-24';
    final location = widget.extra?['location'] ?? 'Seat ROW F - SEAT 12';
    final total = widget.extra?['total'] ?? '0.00';

    return Scaffold(
      backgroundColor: AppColors.bgDarkStart,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            children: [
              const Spacer(),
              _buildSuccessIcon(context).animate().scale(delay: 200.ms, duration: 400.ms, curve: Curves.easeOutBack),
              const SizedBox(height: 40),
              Text(
                'Order Placed!',
                style: theme.textTheme.headlineLarge?.copyWith(
                  fontWeight: FontWeight.w900,
                  color: AppColors.success,
                ),
              ).animate().fadeIn(delay: 400.ms).slideY(begin: 0.5, end: 0),
              const SizedBox(height: 16),
              Text(
                'Your delicious meal is being prepared.\nRedirecting to tracking in 5s...',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: Colors.white.withOpacity(0.6),
                ),
              ).animate().fadeIn(delay: 600.ms),
              const SizedBox(height: 48),
              _buildOrderSummaryCard(context, orderId, location, total).animate().fadeIn(delay: 800.ms).slideY(begin: 0.2, end: 0),
              const Spacer(),
              _buildActionButtons(context).animate().fadeIn(delay: 1000.ms),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSuccessIcon(BuildContext context) {
    return Container(
      width: 120,
      height: 120,
      decoration: BoxDecoration(
        color: AppColors.success.withOpacity(0.1),
        shape: BoxShape.circle,
        border: Border.all(color: AppColors.success.withOpacity(0.5), width: 2),
        boxShadow: [
          BoxShadow(
            color: AppColors.success.withOpacity(0.3),
            blurRadius: 40,
            spreadRadius: 10,
          )
        ]
      ),
      child: const Icon(
        Icons.check_rounded,
        size: 60,
        color: AppColors.success,
      ),
    ).animate(onPlay: (controller) => controller.repeat(reverse: true)).shimmer(duration: 2.seconds);
  }

  Widget _buildOrderSummaryCard(
      BuildContext context, String orderId, String location, dynamic total) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceDark.withOpacity(0.4),
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: AppColors.borderDark),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.5),
            blurRadius: 30,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(32),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              children: [
                _infoRow(context, 'Order ID', orderId),
                const SizedBox(height: 24),
                _infoRow(context, 'Location', location),
                const SizedBox(height: 24),
                Divider(color: AppColors.borderDark.withOpacity(0.5)),
                const SizedBox(height: 24),
                _infoRow(context, 'Total Paid', '₹$total', isBold: true),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _infoRow(BuildContext context, String label, String value,
      {bool isBold = false}) {
    final theme = Theme.of(context);

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: Colors.white.withOpacity(0.5),
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Text(
            value,
            textAlign: TextAlign.end,
            style: isBold
                ? theme.textTheme.titleLarge?.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w900,
                  )
                : theme.textTheme.bodyLarge?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    final theme = Theme.of(context);
    
    return Column(
      children: [
        GestureDetector(
          onTap: () => context.go('/orders'),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 20),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.primary),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withOpacity(0.3),
                  blurRadius: 20,
                ),
              ],
            ),
            child: Center(
              child: Text(
                'TRACK ORDER',
                style: theme.textTheme.titleMedium?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 2,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () => context.go('/home'),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size.fromHeight(64),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20)),
                  side: BorderSide(color: AppColors.borderDark),
                ),
                child: Text(
                  'HOME',
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: OutlinedButton(
                onPressed: () => context.go('/menu'),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size.fromHeight(64),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20)),
                  side: BorderSide(color: AppColors.borderDark),
                ),
                child: Text(
                  'MENU',
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1,
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
