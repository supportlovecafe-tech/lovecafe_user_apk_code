import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/constants/app_gradients.dart';
import '../../../core/constants/app_shadows.dart';
import '../../../core/models/order_model.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/providers/cart_provider.dart';
import '../../../core/providers/orders_provider.dart';
import '../../../core/providers/seat_selection_provider.dart';
import '../../../core/providers/loyalty_provider.dart';
import '../../shared/widgets/primary_button.dart';
import 'widgets/location_popup.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../../core/services/backend_config.dart';

class CheckoutScreen extends ConsumerStatefulWidget {
  const CheckoutScreen({super.key});

  @override
  ConsumerState<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends ConsumerState<CheckoutScreen> {
  PaymentMethod _selectedMethod = PaymentMethod.DEMO_UPI;
  bool _useLoyaltyPoints = false;
  bool _isLoading = false;
  final _phoneController = TextEditingController();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final auth = ref.read(authProvider);
      if (auth.phone != null && auth.phone!.isNotEmpty) {
        _phoneController.text = auth.phone!;
      } else if (auth.email != null && !auth.email!.contains('@')) {
        // Handle proxy email that is actually a phone number
        _phoneController.text = auth.email!.replaceAll('@cinemaeats.local', '');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cartState = ref.watch(cartProvider);
    final cartItems = cartState.items;
    final breakdown = cartState.breakdown;
    final seatSelection = ref.watch(seatSelectionProvider);
    final auth = ref.watch(authProvider);
    final loyalty = ref.watch(loyaltyProvider);
    
    final subtotal = breakdown.subtotal;
    final cgst = breakdown.cgst;
    final sgst = breakdown.sgst;
    final platformFee = breakdown.platformCharges;
    final baseTotal = breakdown.total;
    
    // Loyalty Logic
    final maxRedeemableValue = loyalty.rupeeValue;
    
    // We cap redemption at 50% of order value OR full point value, whichever is smaller
    final capValue = baseTotal * 0.5;
    final actualRedeemValue = _useLoyaltyPoints ? (maxRedeemableValue > capValue ? capValue : maxRedeemableValue) : 0.0;
    final actualRedeemPoints = (actualRedeemValue / LoyaltyNotifier.pointValue).floor();
    
    final grandTotal = baseTotal - actualRedeemValue;

    final allowedMethods = seatSelection.allowedPaymentMethods ?? ['DEMO_UPI', 'DEMO_CARD', 'PAY_ON_DELIVERY', 'PAY_LATER'];
    if (!allowedMethods.contains(_selectedMethod.name)) {
      if (allowedMethods.isNotEmpty) {
        _selectedMethod = PaymentMethod.values.firstWhere(
          (m) => m.name == allowedMethods.first,
          orElse: () => PaymentMethod.PAY_ON_DELIVERY,
        );
      }
    }

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        backgroundColor: AppColors.bg,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.surface,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
            ),
            child: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.textPrimary, size: 16),
          ),
          onPressed: () {
            if (Navigator.canPop(context)) {
              context.pop();
            } else {
              context.go('/menu');
            }
          },
        ),
        title: Text('Checkout', style: AppTextStyles.headingSmall),
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
            _buildOrderItems(cartItems),
            if (cartState.isValidating)
               Padding(
                 padding: EdgeInsets.symmetric(vertical: 8),
                 child: Row(children: [SizedBox(width: 12, height: 12, child: CircularProgressIndicator(strokeWidth: 2)), SizedBox(width: 8), Text('Validating prices...', style: TextStyle(fontSize: 12, color: Colors.white.withValues(alpha: 0.6)))]),
               ),
            const SizedBox(height: 32),

            if (auth.status == AuthStatus.AUTHENTICATED) ...[
              _buildSectionTitle('Loyalty Rewards'),
              _buildLoyaltyCard(loyalty, _useLoyaltyPoints, (val) => setState(() => _useLoyaltyPoints = val), actualRedeemValue),
              const SizedBox(height: 32),
            ],

            _buildSectionTitle('Payment Method'),
            _buildPaymentMethods(seatSelection.allowedPaymentMethods),
            const SizedBox(height: 40),
            
            _buildPriceBreakdown(subtotal, cgst, sgst, platformFee, breakdown.platformFeePercent, actualRedeemValue, grandTotal),
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
      child: Text(title, style: AppTextStyles.sectionTitle),
    );
  }

  Widget _buildLocationCard(SeatSelectionState selection) {
    return InkWell(
      onTap: () => _showLocationSelection(context),
      borderRadius: BorderRadius.circular(24),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.surface, 
          borderRadius: BorderRadius.circular(24), 
          border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
          boxShadow: AppShadows.card,
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12), 
              decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(16)), 
              child: const Icon(Icons.location_on_rounded, color: AppColors.primary),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(selection.hallName ?? 'Cinema Hall', style: AppTextStyles.titleMedium),
                  const SizedBox(height: 4),
                  Text('${selection.screenName} • Seat ${selection.seatLabel}', style: AppTextStyles.bodySmall),
                ],
              ),
            ),
            Icon(Icons.edit_location_alt_rounded, color: AppColors.textDisabled, size: 20),
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
        padding: const EdgeInsets.only(bottom: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                // Combo badge or quantity
                if (item.isCombo)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(colors: [Color(0xFFFF6B35), Color(0xFFFF2D55)]),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Text('COMBO', style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w900, letterSpacing: 0.5)),
                  )
                else
                  Text('${item.quantity}x', style: AppTextStyles.titleMedium.copyWith(color: AppColors.primary)),
                const SizedBox(width: 8),
                Expanded(child: Text(item.foodItem.name, style: AppTextStyles.titleMedium)),
                Text('₹${(item.foodItem.price * item.quantity).toStringAsFixed(0)}', style: AppTextStyles.priceSmall),
              ],
            ),
            // Feature 1: Show item note if present
            if (item.note != null && item.note!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 6, left: 2),
                child: Row(
                  children: [
                    Icon(Icons.notes_rounded, size: 12, color: AppColors.textDisabled),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        item.note!,
                        style: AppTextStyles.bodySmall.copyWith(fontStyle: FontStyle.italic),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      )).toList(),
    );
  }

  Widget _buildLoyaltyCard(LoyaltyState loyalty, bool isSelected, Function(bool) onChanged, double discount) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: AppGradients.cinePoints,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: isSelected ? Colors.transparent : Colors.white.withValues(alpha: 0.05)),
        boxShadow: isSelected ? AppShadows.purpleGlow : [],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.auto_awesome_rounded, color: AppColors.gold, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Use ${loyalty.availablePoints} Points', style: AppTextStyles.titleMedium),
                const SizedBox(height: 2),
                Text('Save ₹${loyalty.rupeeValue.toStringAsFixed(0)} on this order', style: AppTextStyles.bodySmall.copyWith(color: Colors.white70)),
              ],
            ),
          ),
          Switch(
            value: isSelected,
            onChanged: loyalty.availablePoints > 0 ? onChanged : null,
            activeThumbColor: AppColors.gold,
            activeTrackColor: Colors.white24,
            inactiveThumbColor: Colors.white54,
            inactiveTrackColor: Colors.black26,
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentMethods(List<String>? allowedMethods) {
    final methods = allowedMethods ?? ['DEMO_UPI', 'DEMO_CARD', 'PAY_ON_DELIVERY', 'PAY_LATER'];
    return Column(
      children: [
        if (methods.contains('DEMO_UPI')) ...[
          _paymentTile(PaymentMethod.DEMO_UPI, 'UPI / QR Scan', Icons.qr_code_rounded),
          const SizedBox(height: 12),
        ],
        if (methods.contains('DEMO_CARD')) ...[
          _paymentTile(PaymentMethod.DEMO_CARD, 'Credit / Debit Card', Icons.credit_card_rounded),
          const SizedBox(height: 12),
        ],
        if (methods.contains('PAY_ON_DELIVERY')) ...[
          _paymentTile(PaymentMethod.PAY_ON_DELIVERY, 'Cash (Requires OTP Verification)', Icons.money_rounded),
          const SizedBox(height: 12),
        ],
        if (methods.contains('PAY_LATER')) ...[
          _paymentTile(PaymentMethod.PAY_LATER, 'Pay Later', Icons.calendar_today_rounded),
        ],
      ],
    );
  }

  Widget _paymentTile(PaymentMethod method, String label, IconData icon) {
    final isSelected = _selectedMethod == method;
    return InkWell(
      onTap: () => setState(() => _selectedMethod = method),
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary.withValues(alpha: 0.08) : AppColors.surfaceElevated.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: isSelected ? AppColors.primary : AppColors.glassBorder, width: 1),
          boxShadow: isSelected ? AppShadows.pinkGlowSoft : [],
        ),
        child: Row(
          children: [
            Icon(icon, color: isSelected ? AppColors.primary : AppColors.textDisabled),
            const SizedBox(width: 16),
            Text(label, style: isSelected ? AppTextStyles.titleMedium.copyWith(color: AppColors.primary) : AppTextStyles.bodyMedium),
            const Spacer(),
            if (isSelected) const Icon(Icons.check_circle_rounded, color: AppColors.primary, size: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildPriceBreakdown(double subtotal, double cgst, double sgst, double platformFee, double platformFeePercent, double discount, double total) {
    return Column(
      children: [
        _priceRow('Subtotal', subtotal),
        const SizedBox(height: 8),
        _priceRow('CGST (2.5%)', cgst),
        const SizedBox(height: 8),
        _priceRow('SGST (2.5%)', sgst),
        const SizedBox(height: 8),
        _priceRow('Platform Fee (${platformFeePercent.toStringAsFixed(platformFeePercent == platformFeePercent.toInt() ? 0 : 1)}%)', platformFee),
        if (discount > 0) ...[
          const SizedBox(height: 8),
          _priceRow('CinePoints Discount', -discount, isDiscount: true),
        ],
        Padding(padding: const EdgeInsets.symmetric(vertical: 16), child: Divider(color: AppColors.divider)),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Grand Total', style: AppTextStyles.headingMedium),
            Text('₹${total.toStringAsFixed(2)}', style: AppTextStyles.priceLarge),
          ],
        ),
      ],
    );
  }

  Widget _priceRow(String label, double value, {bool isDiscount = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: AppTextStyles.bodyMedium),
        Text('${value < 0 ? "-" : ""}₹${value.abs().toStringAsFixed(2)}', 
          style: AppTextStyles.bodyLarge.copyWith(color: isDiscount ? AppColors.success : AppColors.textPrimary)),
      ],
    );
  }

  Widget _buildBottomAction(double grandTotal, int pointsToRedeem) {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 40),
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated.withValues(alpha: 0.95), 
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        border: Border(top: BorderSide(color: AppColors.glassBorder)),
        boxShadow: AppShadows.purpleGlow,
      ),
      child: PrimaryButton(
        label: _isLoading ? 'PROCESSING...' : (_selectedMethod == PaymentMethod.PAY_ON_DELIVERY || _selectedMethod == PaymentMethod.PAY_LATER || grandTotal == 0 ? 'PLACE ORDER' : 'PAY ₹${grandTotal.toStringAsFixed(0)}'),
        onPressed: (_isLoading || ref.watch(cartProvider).isValidating) ? null : () => _processPayment(grandTotal, pointsToRedeem),
      ),
    );
  }

  Future<void> _processPayment(double grandTotal, int pointsRedeemed) async {
    final seatSelection = ref.read(seatSelectionProvider);
    final auth = ref.read(authProvider);
    final isGuest = auth.status != AuthStatus.AUTHENTICATED;
    
    // Final Confirmation Dialog capturing details
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        bool otpSent = false;
        bool isProcessing = false;
        String? sessionId;
        final otpController = TextEditingController();

        return StatefulBuilder(
          builder: (context, setDialogState) {
            final colorScheme = Theme.of(context).colorScheme;
            final requiresOtp = _selectedMethod == PaymentMethod.PAY_ON_DELIVERY;

            return AlertDialog(
              backgroundColor: colorScheme.surface,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
              title: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.1), shape: BoxShape.circle),
                    child: Icon(requiresOtp ? Icons.security_rounded : Icons.error_outline_rounded, color: AppColors.primary, size: 40),
                  ),
                  const SizedBox(height: 16),
                  Text(requiresOtp ? 'CONFIRM & VERIFY' : 'CONFIRM DETAILS', textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1)),
                ],
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Location:\n${seatSelection.hallName}\n${seatSelection.screenName} • Seat ${seatSelection.seatLabel}',
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 24),
                    const Text('Delivery Contact', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
                    const SizedBox(height: 16),
                    if (isGuest) ...[
                      TextField(
                        controller: _firstNameController,
                        enabled: !otpSent && !isProcessing,
                        decoration: InputDecoration(
                          hintText: 'First Name',
                          filled: true,
                          fillColor: colorScheme.onSurface.withValues(alpha: 0.05),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _lastNameController,
                        enabled: !otpSent && !isProcessing,
                        decoration: InputDecoration(
                          hintText: 'Last Name',
                          filled: true,
                          fillColor: colorScheme.onSurface.withValues(alpha: 0.05),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],
                    TextField(
                      controller: _phoneController,
                      keyboardType: TextInputType.phone,
                      enabled: !otpSent && !isProcessing,
                      decoration: InputDecoration(
                        hintText: 'Phone Number',
                        filled: true,
                        fillColor: colorScheme.onSurface.withValues(alpha: 0.05),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      ),
                    ),
                    if (requiresOtp && otpSent) ...[
                      const SizedBox(height: 16),
                      TextField(
                        controller: otpController,
                        keyboardType: TextInputType.number,
                        textAlign: TextAlign.center,
                        enabled: !isProcessing,
                        style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 24, letterSpacing: 4),
                        decoration: InputDecoration(
                          hintText: '000000',
                          filled: true,
                          fillColor: colorScheme.onSurface.withValues(alpha: 0.05),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text('Please enter the 6-digit OTP sent to your phone.', textAlign: TextAlign.center, style: TextStyle(fontSize: 12, color: Colors.grey)),
                    ],
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: isProcessing ? null : () => Navigator.pop(context, {'confirmed': false}),
                  child: Text('CANCEL', style: TextStyle(color: colorScheme.onSurface.withValues(alpha: 0.5))),
                ),
                ElevatedButton(
                  onPressed: isProcessing ? null : () async {
                    if (_phoneController.text.trim().isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Phone number is required.')));
                      return;
                    }
                    if (isGuest && (_firstNameController.text.trim().isEmpty || _lastNameController.text.trim().isEmpty)) {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Name is required for guest checkout.')));
                      return;
                    }

                    if (requiresOtp) {
                      if (!otpSent) {
                        // Send OTP
                        setDialogState(() => isProcessing = true);
                        try {
                          final baseUrl = BackendConfig.backendApiUrl;
                          final response = await http.post(
                            Uri.parse('$baseUrl/api/auth/send-otp'),
                            headers: {'Content-Type': 'application/json'},
                            body: jsonEncode({'phone': _phoneController.text.trim()}),
                          );

                          if (response.statusCode == 200) {
                            final data = jsonDecode(response.body);
                            sessionId = data['sessionId'];
                            setDialogState(() {
                              otpSent = true;
                              isProcessing = false;
                            });
                          } else {
                            throw Exception('Failed to send OTP. Please try again.');
                          }
                        } catch (e) {
                          setDialogState(() => isProcessing = false);
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
                        }
                      } else {
                        // Verify OTP
                        final code = otpController.text.trim();
                        if (code.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please enter the OTP.')));
                          return;
                        }
                        setDialogState(() => isProcessing = true);
                        try {
                          final baseUrl = BackendConfig.backendApiUrl;
                          final res = await http.post(
                            Uri.parse('$baseUrl/api/auth/verify-otp'),
                            headers: {'Content-Type': 'application/json'},
                            body: jsonEncode({'sessionId': sessionId, 'otpCode': code}),
                          );

                          if (res.statusCode == 200) {
                            final data = jsonDecode(res.body);
                            final token = data['verificationToken'];
                            Navigator.pop(context, {'confirmed': true, 'token': token});
                          } else {
                            final errorData = jsonDecode(res.body);
                            throw Exception(errorData['error'] ?? 'Invalid OTP');
                          }
                        } catch (e) {
                          setDialogState(() => isProcessing = false);
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
                        }
                      }
                    } else {
                      // Non-OTP flow
                      Navigator.pop(context, {'confirmed': true});
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: isProcessing
                      ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : Text(requiresOtp 
                          ? (otpSent ? 'VERIFY & SUBMIT' : 'SEND OTP') 
                          : ((_selectedMethod == PaymentMethod.PAY_LATER) ? 'CONFIRM' : 'PAY NOW')),
                ),
              ],
            );
          }
        );
      },
    );

    if (result == null || result['confirmed'] != true) return;
    
    final phone = _phoneController.text.trim();
    final token = result['token'];

    _finalizeOrder(grandTotal, pointsRedeemed, phone, token);
  }

  Future<void> _finalizeOrder(double grandTotal, int pointsRedeemed, String phone, String? verificationToken) async {
    setState(() => _isLoading = true);
    
    try {
      final cart = ref.read(cartProvider);
      final cartNotifier = ref.read(cartProvider.notifier);
      final seatSelection = ref.read(seatSelectionProvider);

      final subtotal = cartNotifier.subtotal;
      final cgst = cartNotifier.cgst;
      final sgst = cartNotifier.sgst;
      final platformFee = cartNotifier.platformCharges;

      int itemCounter = 0;
      final orderItems = cart.items.map((item) {
        final idx = itemCounter++;
        return OrderItem(
          itemId: '${item.foodItem.id}_${DateTime.now().microsecondsSinceEpoch}_$idx',
          foodItem: item.foodItem,
          quantity: item.quantity,
          note: item.note,
          isCombo: item.isCombo,
          comboId: item.comboId,
          comboName: item.comboName,
        );
      }).toList();

      final Map<String, dynamic> metadata = {
        'subtotal': subtotal,
        'cgst': cgst,
        'sgst': sgst,
        'platform_charges': platformFee,
      };
      
      final auth = ref.read(authProvider);
      if (auth.status != AuthStatus.AUTHENTICATED) {
         metadata['guest_first_name'] = _firstNameController.text.trim();
         metadata['guest_last_name'] = _lastNameController.text.trim();
      }
      
      if (verificationToken != null) {
        metadata['verificationToken'] = verificationToken;
      }

      final order = await ref.read(ordersProvider.notifier).placeOrder(
        orderItems,
        grandTotal,
        seatSelection.displayLabel,
        paymentMethod: _selectedMethod,
        customerPhone: phone,
        pointsRedeemed: pointsRedeemed,
        metadata: metadata,
      );

      if (order == null) throw Exception('Order could not be verified. Please check your connection.');
      
      ref.read(cartProvider.notifier).clearCart();
      if (mounted) {
        context.go('/success', extra: {
          'orderId': order.displayId,
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
