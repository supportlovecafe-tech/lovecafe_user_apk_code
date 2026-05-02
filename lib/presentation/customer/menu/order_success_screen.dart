import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lottie/lottie.dart';
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
      backgroundColor: colorScheme.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            children: [
              const Spacer(),
              _buildSuccessIcon(context),
              const SizedBox(height: 40),
              Text(
                'Order Placed!',
                style: theme.textTheme.headlineLarge?.copyWith(
                  fontWeight: FontWeight.w900,
                  color: colorScheme.primary,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Your delicious meal is being prepared.\nRedirecting to tracking in 5s...',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: colorScheme.onSurface.withOpacity(0.6),
                ),
              ),
              const SizedBox(height: 48),
              _buildOrderSummaryCard(context, orderId, location, total),
              const Spacer(),
              _buildActionButtons(context),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSuccessIcon(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      width: 120,
      height: 120,
      decoration: BoxDecoration(
        color: colorScheme.primary.withOpacity(0.1),
        shape: BoxShape.circle,
        border: Border.all(color: colorScheme.primary.withOpacity(0.2), width: 4),
      ),
      child: Icon(
        Icons.check_circle_rounded,
        size: 80,
        color: colorScheme.primary,
      ),
    );
  }

  Widget _buildOrderSummaryCard(
      BuildContext context, String orderId, String location, dynamic total) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: colorScheme.outline.withOpacity(0.1)),
        boxShadow: [
          BoxShadow(
            color: colorScheme.onSurface.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          _infoRow(context, 'Order ID', orderId),
          const SizedBox(height: 24),
          _infoRow(context, 'Location', location),
          const SizedBox(height: 24),
          Divider(color: colorScheme.outline.withOpacity(0.1)),
          const SizedBox(height: 24),
          _infoRow(context, 'Total Paid', '₹$total', isBold: true),
        ],
      ),
    );
  }

  Widget _infoRow(BuildContext context, String label, String value,
      {bool isBold = false}) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: colorScheme.onSurface.withOpacity(0.5),
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          value,
          style: isBold
              ? theme.textTheme.titleLarge?.copyWith(
                  color: colorScheme.primary,
                  fontWeight: FontWeight.w900,
                )
              : theme.textTheme.bodyLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
        ),
      ],
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final theme = Theme.of(context);
    
    return Column(
      children: [
        ElevatedButton(
          onPressed: () => context.go('/orders'),
          style: ElevatedButton.styleFrom(
            backgroundColor: colorScheme.primary,
            foregroundColor: colorScheme.onPrimary,
            minimumSize: const Size.fromHeight(64),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            elevation: 8,
            shadowColor: colorScheme.primary.withOpacity(0.4),
          ),
          child: Text(
            'TRACK ORDER',
            style: theme.textTheme.titleMedium?.copyWith(
              color: colorScheme.onPrimary,
              fontWeight: FontWeight.w900,
              letterSpacing: 2,
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
                  side: BorderSide(color: colorScheme.outline.withOpacity(0.2)),
                ),
                child: Text(
                  'HOME',
                  style: theme.textTheme.labelLarge?.copyWith(
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
                  side: BorderSide(color: colorScheme.outline.withOpacity(0.2)),
                ),
                child: Text(
                  'MENU',
                  style: theme.textTheme.labelLarge?.copyWith(
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
