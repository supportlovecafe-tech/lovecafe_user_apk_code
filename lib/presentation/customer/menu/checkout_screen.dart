import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/models/order_model.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/providers/cart_provider.dart';
import '../../../core/providers/orders_provider.dart';
import '../../../core/providers/seat_selection_provider.dart';
import '../../../core/providers/loyalty_provider.dart';
import '../../shared/widgets/primary_button.dart';
import 'widgets/location_popup.dart';

class CheckoutScreen extends ConsumerStatefulWidget {
  const CheckoutScreen({super.key});

  @override
  ConsumerState<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends ConsumerState<CheckoutScreen> {
  PaymentMethod _selectedMethod = PaymentMethod.DEMO_UPI;
  bool _useLoyaltyPoints = false;
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final cart = ref.watch(cartProvider);
    final seatSelection = ref.watch(seatSelectionProvider);
    final auth = ref.watch(authProvider);
    final loyalty = ref.watch(loyaltyProvider);

    final subtotal = cart.fold<double>(0, (sum, item) => sum + (item.foodItem.price * item.quantity));
    const serviceFee = 4.5;
    final baseTotal = subtotal + serviceFee;
    
    // Loyalty Logic
    final maxRedeemablePoints = loyalty.availablePoints;
    final maxRedeemableValue = loyalty.rupeeValue;
    
    // We cap redemption at 50% of order value OR full point value, whichever is smaller
    final capValue = baseTotal * 0.5;
    final actualRedeemValue = _useLoyaltyPoints ? (maxRedeemableValue > capValue ? capValue : maxRedeemableValue) : 0.0;
    final actualRedeemPoints = (actualRedeemValue / LoyaltyNotifier.pointValue).floor();
    
    final grandTotal = baseTotal - actualRedeemValue;

    return Scaffold(
      backgroundColor: colorScheme.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: colorScheme.surface,
              shape: BoxShape.circle,
              border: Border.all(color: colorScheme.outline.withOpacity(0.1)),
            ),
            child: Icon(Icons.arrow_back_ios_new_rounded, color: colorScheme.primary, size: 16),
          ),
          onPressed: () {
            if (Navigator.canPop(context)) {
              context.pop();
            } else {
              context.go('/menu');
            }
          },
        ),
        title: Text('Checkout', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900)),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionTitle('Location Details'),
            _buildLocationCard(seatSelection),
            const SizedBox(height: 32),
            
            _buildSectionTitle('Order Summary'),
            _buildOrderItems(cart),
            const SizedBox(height: 32),

            if (auth.status == AuthStatus.AUTHENTICATED) ...[
              _buildSectionTitle('Loyalty Rewards'),
              _buildLoyaltyCard(loyalty, _useLoyaltyPoints, (val) => setState(() => _useLoyaltyPoints = val), actualRedeemValue),
              const SizedBox(height: 32),
            ],

            _buildSectionTitle('Payment Method'),
            _buildPaymentMethods(),
            const SizedBox(height: 40),
            
            _buildPriceBreakdown(subtotal, serviceFee, actualRedeemValue, grandTotal),
            const SizedBox(height: 120),
          ],
        ),
      ),
      bottomSheet: _buildBottomAction(grandTotal, actualRedeemPoints),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Text(title, style: AppTextStyles.bodySmall.copyWith(letterSpacing: 1.5, fontWeight: FontWeight.w900, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.4))),
    );
  }

  Widget _buildLocationCard(SeatSelectionState selection) {
    final colorScheme = Theme.of(context).colorScheme;
    return InkWell(
      onTap: () => _showLocationSelection(context),
      borderRadius: BorderRadius.circular(24),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor, 
          borderRadius: BorderRadius.circular(24), 
          border: Border.all(color: AppColors.primary.withOpacity(0.2), width: 1.5),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12), 
              decoration: BoxDecoration(color: AppColors.primary.withOpacity(0.1), borderRadius: BorderRadius.circular(16)), 
              child: const Icon(Icons.location_on_rounded, color: AppColors.primary),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(selection.hallName ?? 'Cinema Hall', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  Text('${selection.screenName} • Seat ${selection.seatLabel}', style: TextStyle(color: colorScheme.onSurface.withOpacity(0.5), fontSize: 13)),
                ],
              ),
            ),
            Icon(Icons.edit_location_alt_rounded, color: AppColors.primary.withOpacity(0.5), size: 20),
          ],
        ),
      ),
    );
  }

  void _showLocationSelection(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => LocationSelectionPopup(
        onSelected: (hallId, hallName, screen, seat) {
          ref.read(seatSelectionProvider.notifier).updateSelection(
                hallId: hallId,
                hallName: hallName,
                screenName: screen,
                seatLabel: seat,
              );
        },
      ),
    );
  }

  Widget _buildOrderItems(List<CartItem> cart) {
    return Column(
      children: cart.map((item) => Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Row(
          children: [
            Text('${item.quantity}x', style: TextStyle(fontWeight: FontWeight.w900, color: AppColors.primary, fontSize: 14)),
            const SizedBox(width: 12),
            Expanded(child: Text(item.foodItem.name, style: const TextStyle(fontWeight: FontWeight.w600))),
            Text('₹${(item.foodItem.price * item.quantity).toStringAsFixed(0)}', style: const TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
      )).toList(),
    );
  }

  Widget _buildLoyaltyCard(LoyaltyState loyalty, bool isSelected, Function(bool) onChanged, double discount) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [Colors.purple.withOpacity(0.1), Colors.blue.withOpacity(0.1)]),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: isSelected ? Colors.purple.withOpacity(0.3) : colorScheme.outline.withOpacity(0.1)),
      ),
      child: Row(
        children: [
          const Icon(Icons.stars_rounded, color: Colors.purple),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Use ${loyalty.availablePoints} Points', style: const TextStyle(fontWeight: FontWeight.bold)),
                Text('Save ₹${loyalty.rupeeValue.toStringAsFixed(0)} on this order', style: TextStyle(fontSize: 12, color: colorScheme.onSurface.withOpacity(0.5))),
              ],
            ),
          ),
          Switch(
            value: isSelected,
            onChanged: loyalty.availablePoints > 0 ? onChanged : null,
            activeColor: Colors.purple,
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentMethods() {
    return Column(
      children: [
        _paymentTile(PaymentMethod.DEMO_UPI, 'UPI / QR Scan', Icons.qr_code_rounded),
        const SizedBox(height: 12),
        _paymentTile(PaymentMethod.DEMO_CARD, 'Credit / Debit Card', Icons.credit_card_rounded),
      ],
    );
  }

  Widget _paymentTile(PaymentMethod method, String label, IconData icon) {
    final isSelected = _selectedMethod == method;
    final colorScheme = Theme.of(context).colorScheme;
    return InkWell(
      onTap: () => setState(() => _selectedMethod = method),
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary.withOpacity(0.05) : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: isSelected ? AppColors.primary : colorScheme.outline.withOpacity(0.1), width: 2),
        ),
        child: Row(
          children: [
            Icon(icon, color: isSelected ? AppColors.primary : colorScheme.onSurface.withOpacity(0.4)),
            const SizedBox(width: 16),
            Text(label, style: TextStyle(fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
            const Spacer(),
            if (isSelected) const Icon(Icons.check_circle_rounded, color: AppColors.primary, size: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildPriceBreakdown(double subtotal, double fee, double discount, double total) {
    return Column(
      children: [
        _priceRow('Subtotal', subtotal),
        const SizedBox(height: 8),
        _priceRow('Service Fee', fee),
        if (discount > 0) ...[
          const SizedBox(height: 8),
          _priceRow('Loyalty Discount', -discount, isDiscount: true),
        ],
        const Padding(padding: EdgeInsets.symmetric(vertical: 16), child: Divider()),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Grand Total', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18)),
            Text('₹${total.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 24, color: AppColors.primary)),
          ],
        ),
      ],
    );
  }

  Widget _priceRow(String label, double value, {bool isDiscount = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5))),
        Text('${value < 0 ? "-" : ""}₹${value.abs().toStringAsFixed(2)}', style: TextStyle(fontWeight: FontWeight.bold, color: isDiscount ? Colors.green : null)),
      ],
    );
  }

  Widget _buildBottomAction(double grandTotal, int pointsToRedeem) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 40),
      decoration: BoxDecoration(color: colorScheme.surface, borderRadius: const BorderRadius.vertical(top: Radius.circular(32))),
      child: PrimaryButton(
        text: _isLoading ? 'PROCESSING...' : 'PAY ₹${grandTotal.toStringAsFixed(0)}',
        onPressed: _isLoading ? null : () => _processPayment(grandTotal, pointsToRedeem),
      ),
    );
  }

  Future<void> _processPayment(double grandTotal, int pointsRedeemed) async {
    final seatSelection = ref.read(seatSelectionProvider);
    
    // Final Location Confirmation Dialog
    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: Theme.of(context).colorScheme.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        title: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: AppColors.primary.withOpacity(0.1), shape: BoxShape.circle),
              child: const Icon(Icons.error_outline_rounded, color: AppColors.primary, size: 40),
            ),
            const SizedBox(height: 16),
            const Text('CONFIRM LOCATION', textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1)),
          ],
        ),
        content: Text(
          'You are ordering to:\n\n${seatSelection.hallName}\n${seatSelection.screenName} • Seat ${seatSelection.seatLabel}\n\nIs this correct?',
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('NO, CHANGE', style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5))),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('YES, PAY NOW'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _isLoading = true);
    
    try {
      final cart = ref.read(cartProvider);
      final auth = ref.read(authProvider);

      final orderItems = cart.map((item) => OrderItem(foodItem: item.foodItem, quantity: item.quantity)).toList();

      await ref.read(ordersProvider.notifier).placeOrder(
        orderItems,
        grandTotal,
        seatSelection.displayLabel,
        paymentMethod: _selectedMethod,
        customerPhone: auth.phone ?? 'guest',
        pointsRedeemed: pointsRedeemed,
      );

      final latestOrder = ref.read(ordersProvider).first;
      
      ref.read(cartProvider.notifier).clearCart();
      if (mounted) {
        context.go('/success', extra: {
          'orderId': latestOrder.displayId,
          'total': grandTotal,
          'location': seatSelection.displayLabel
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Payment Failed: $e'), backgroundColor: Colors.red));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }
}
