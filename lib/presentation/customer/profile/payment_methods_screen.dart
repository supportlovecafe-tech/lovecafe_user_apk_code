import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';

class PaymentMethodsScreen extends ConsumerWidget {
  const PaymentMethodsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: colorScheme.onSurface, size: 20),
          onPressed: () => context.pop(),
        ),
        title: Text('Payment Methods',
            style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900)),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionHeader(context, 'YOUR CARDS'),
            _buildCreditCard(
              context,
              brand: 'VISA',
              number: '**** **** **** 4242',
              expiry: '12/26',
              holder: 'Julian Vance',
              color: const Color(0xFF1A1A2E),
            ),
            const SizedBox(height: 20),
            _buildAddCardButton(context),
            const SizedBox(height: 48),
            _buildSectionHeader(context, 'UPI IDS'),
            _buildUPIOption(context, 'julian@oksbi', 'Primary UPI ID', true),
            _buildUPIOption(context, 'vance@paytm', 'Secondary UPI ID', false),
            const SizedBox(height: 20),
            _buildAddButton(context, 'ADD NEW UPI ID'),
            const SizedBox(height: 48),
            _buildSectionHeader(context, 'WALLETS'),
            _buildWalletOption(context, 'CineWallet', '₹1,240.00', true),
            _buildWalletOption(context, 'Amazon Pay', 'Linked', false),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Text(
        title,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          fontWeight: FontWeight.w900,
          letterSpacing: 2,
          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.3),
        ),
      ),
    );
  }

  Widget _buildCreditCard(BuildContext context, {
    required String brand,
    required String number,
    required String expiry,
    required String holder,
    required Color color,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(brand, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 24, fontStyle: FontStyle.italic)),
              const Icon(Icons.contactless_rounded, color: Colors.white, size: 28),
            ],
          ),
          const SizedBox(height: 40),
          Text(number, style: const TextStyle(color: Colors.white, fontSize: 22, letterSpacing: 2, fontWeight: FontWeight.w500)),
          const SizedBox(height: 40),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('CARD HOLDER', style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1)),
                  const SizedBox(height: 4),
                  Text(holder.toUpperCase(), style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('EXPIRES', style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1)),
                  const SizedBox(height: 4),
                  Text(expiry, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAddCardButton(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      height: 100,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: colorScheme.outline.withOpacity(0.1), width: 2),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.add_rounded, color: colorScheme.primary, size: 32),
            const SizedBox(height: 8),
            Text('ADD NEW CARD', style: TextStyle(color: colorScheme.primary, fontWeight: FontWeight.w900, letterSpacing: 1, fontSize: 12)),
          ],
        ),
      ),
    );
  }

  Widget _buildUPIOption(BuildContext context, String id, String label, bool isSelected) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: isSelected ? colorScheme.primary : colorScheme.outline.withOpacity(0.06)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: colorScheme.primary.withOpacity(0.1), shape: BoxShape.circle),
            child: Icon(Icons.account_balance_rounded, color: colorScheme.primary, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(id, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                Text(label, style: TextStyle(color: colorScheme.onSurface.withOpacity(0.4), fontSize: 12)),
              ],
            ),
          ),
          if (isSelected) Icon(Icons.check_circle_rounded, color: colorScheme.primary),
        ],
      ),
    );
  }

  Widget _buildWalletOption(BuildContext context, String name, String balance, bool isSelected) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: colorScheme.outline.withOpacity(0.06)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: colorScheme.secondary.withOpacity(0.1), shape: BoxShape.circle),
            child: Icon(Icons.account_balance_wallet_rounded, color: colorScheme.secondary, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                Text(balance, style: TextStyle(color: colorScheme.secondary, fontSize: 12, fontWeight: FontWeight.w900)),
              ],
            ),
          ),
          Icon(Icons.chevron_right_rounded, color: colorScheme.onSurface.withOpacity(0.2)),
        ],
      ),
    );
  }

  Widget _buildAddButton(BuildContext context, String label) {
    final colorScheme = Theme.of(context).colorScheme;
    return TextButton.icon(
      onPressed: () {},
      icon: const Icon(Icons.add_rounded),
      label: Text(label, style: const TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1)),
      style: TextButton.styleFrom(foregroundColor: colorScheme.primary),
    );
  }
}
