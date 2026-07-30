import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/constants/app_gradients.dart';
import '../../../core/constants/app_shadows.dart';
import '../../../core/providers/cart_provider.dart';
import '../../../core/providers/seat_selection_provider.dart';
import '../../../core/providers/offers_provider.dart';
import '../../../core/models/food_item.dart';
import 'widgets/location_popup.dart';
import '../../shared/widgets/safe_network_image.dart';
import '../../shared/widgets/custom_bottom_nav_bar.dart';

class CartScreen extends ConsumerWidget {
  const CartScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cart = ref.watch(cartProvider);
    final total = cart.items.fold<double>(
        0, (sum, item) => sum + (item.foodItem.price * item.quantity));

    return Scaffold(
      backgroundColor: AppColors.bg,
      extendBody: true,
      body: Column(
        children: [
          _buildAppBar(context),
          // BOGO Upsell alert shelf
          if (cart.items.isNotEmpty) _buildBogoAlerts(context, ref, cart.items),
          Expanded(
            child: cart.items.isEmpty
                ? _buildEmptyState(context)
                : _buildCartList(context, ref, cart.items),
          ),
          if (cart.items.isNotEmpty) _buildSummary(context, ref, total),
        ],
      ),
      bottomNavigationBar: const CustomBottomNavBar(currentIndex: 2),
    );
  }

  Widget _buildAppBar(BuildContext context) {
    return AppBar(
      backgroundColor: AppColors.bg,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new_rounded,
            color: AppColors.textPrimary, size: 18),
        onPressed: () {
          if (context.canPop()) {
            context.pop();
          } else {
            context.go('/menu');
          }
        },
      ),
      title: Text('My Cart', style: AppTextStyles.headingSmall),
      centerTitle: true,
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.06),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.shopping_bag_outlined,
                      size: 72, color: AppColors.primary.withValues(alpha: 0.35))
                  .animate(onPlay: (controller) => controller.repeat(reverse: true))
                  .moveY(begin: -5, end: 5, duration: 2000.ms, curve: Curves.easeInOut)
                  .scale(begin: const Offset(0.95, 0.95), end: const Offset(1.05, 1.05), duration: 2000.ms, curve: Curves.easeInOut),
            ),
            const SizedBox(height: 28),
            Text('Your cart is empty',
                style: AppTextStyles.headingMedium),
            const SizedBox(height: 10),
            Text(
              'Add some delicious food to start\nyour premium dining experience!',
              textAlign: TextAlign.center,
              style: AppTextStyles.bodyMedium,
            ),
            const SizedBox(height: 36),
            GestureDetector(
              onTap: () => context.go('/menu'),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 36, vertical: 14),
                decoration: BoxDecoration(
                  gradient: AppGradients.primaryButton,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: AppShadows.buttonPrimary,
                ),
                child: Text('Explore Menu',
                    style: AppTextStyles.buttonMedium),
              ),
            ),
          ],
        ),
      ),
    ).animate().fadeIn(duration: 300.ms);
  }

  Widget _buildCartList(BuildContext context, WidgetRef ref, List<CartItem> cart) {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
      itemCount: cart.length,
      itemBuilder: (context, index) {
        final item = cart[index];
        return Dismissible(
          key: ValueKey(item.foodItem.id),
          direction: DismissDirection.endToStart,
          background: Container(
            alignment: Alignment.centerRight,
            margin: const EdgeInsets.only(bottom: 16),
            padding: const EdgeInsets.only(right: 24),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.error,
              borderRadius: BorderRadius.circular(24),
            ),
            child: const Icon(Icons.delete_sweep_rounded, color: Colors.white, size: 28),
          ),
          onDismissed: (direction) {
            ref.read(cartProvider.notifier).removeItem(item.foodItem.id);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('${item.foodItem.name} removed from cart'),
                behavior: SnackBarBehavior.floating,
                backgroundColor: Theme.of(context).colorScheme.error,
              ),
            );
          },
          child: _buildCartItem(context, ref, item),
        );
      },
    );
  }

  Widget _buildCartItem(BuildContext context, WidgetRef ref, CartItem item) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated.withValues(alpha: 0.85),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.glassBorder),
        boxShadow: AppShadows.purpleGlow,
      ),
      child: Column(
        children: [
          Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: SafeNetworkImage(
                  imageUrl: item.foodItem.imageUrl,
                  width: 80,
                  height: 80,
                  fit: BoxFit.cover,
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.foodItem.name,
                      style: AppTextStyles.titleMedium,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 5),
                    Text(
                      '₹${item.foodItem.price.toInt()} each',
                      style: AppTextStyles.priceSmall,
                    ),
                  ],
                ),
              ),
              _buildQuantityPicker(ref, item),
            ],
          ),
          if (item.note != null && item.note!.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.surfaceElevated,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    Icon(Icons.notes_rounded,
                        color: AppColors.textDisabled, size: 14),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        item.note!,
                        style: AppTextStyles.bodySmall
                            .copyWith(fontStyle: FontStyle.italic),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    GestureDetector(
                      onTap: () => _showNoteEditor(context, ref, item),
                      child: Text(
                        'EDIT',
                        style: AppTextStyles.labelSmall.copyWith(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1),
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            Padding(
              padding: const EdgeInsets.only(top: 10),
              child: InkWell(
                onTap: () => _showNoteEditor(context, ref, item),
                child: Row(
                  children: [
                    Icon(Icons.add_comment_outlined,
                        size: 13, color: AppColors.primary.withValues(alpha: 0.6)),
                    const SizedBox(width: 6),
                    Text(
                      'Add a note',
                      style: AppTextStyles.labelSmall.copyWith(
                        color: AppColors.primary.withValues(alpha: 0.6),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  void _showNoteEditor(BuildContext context, WidgetRef ref, CartItem item) {
    final TextEditingController noteController = TextEditingController(text: item.note);
    final colorScheme = Theme.of(context).colorScheme;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: colorScheme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Add Note for ${item.foodItem.name}', style: AppTextStyles.headingMedium),
              const SizedBox(height: 24),
              TextField(
                controller: noteController,
                maxLines: 3,
                decoration: InputDecoration(
                  hintText: 'e.g., "Less spicy", "No onions"',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  filled: true,
                  fillColor: AppColors.surfaceContainer,
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () {
                  ref.read(cartProvider.notifier).updateItemNote(item.foodItem.id, noteController.text);
                  Navigator.pop(context);
                },
                child: const Text('SAVE NOTE'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuantityPicker(WidgetRef ref, CartItem item) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.glassBorder),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _pickerButton(
            icon: Icons.remove_rounded,
            onTap: () => ref
                .read(cartProvider.notifier)
                .updateQuantity(item.foodItem.id, -1),
            color: AppColors.textSecondary,
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Text('${item.quantity}',
                style: AppTextStyles.titleLarge),
          ),
          _pickerButton(
            icon: Icons.add_rounded,
            onTap: () => ref
                .read(cartProvider.notifier)
                .updateQuantity(item.foodItem.id, 1),
            color: AppColors.primary,
            isPrimary: true,
          ),
        ],
      ),
    );
  }

  Widget _pickerButton(
      {required IconData icon,
      required VoidCallback onTap,
      required Color color,
      bool isPrimary = false}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(9),
        decoration: isPrimary
            ? BoxDecoration(
                gradient: AppGradients.primaryButton,
                borderRadius: const BorderRadius.only(
                  topRight: Radius.circular(14),
                  bottomRight: Radius.circular(14),
                ),
              )
            : null,
        child: Icon(icon, size: 16, color: isPrimary ? Colors.white : color),
      ),
    );
  }

  Widget _buildSummary(BuildContext context, WidgetRef ref, double subtotal) {
    final seatSelection = ref.watch(seatSelectionProvider);
    final cartNotifier = ref.watch(cartProvider.notifier);

    final discount = cartNotifier.discount;
    final cgst = cartNotifier.cgst;
    final sgst = cartNotifier.sgst;
    final platformCharges = cartNotifier.platformCharges;
    final total = cartNotifier.totalAmount;

    return Container(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated.withValues(alpha: 0.95),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        border: Border(top: BorderSide(color: AppColors.glassBorder)),
        boxShadow: AppShadows.purpleGlow,
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _summaryRow('Subtotal', '₹${subtotal.toStringAsFixed(2)}'),
            const SizedBox(height: 6),
            if (discount > 0) ...[
              _summaryRow('Promo Savings', '-₹${discount.toStringAsFixed(2)}', isPromo: true),
              const SizedBox(height: 6),
            ],
            _summaryRow('CGST (2.5%)', '₹${cgst.toStringAsFixed(2)}'),
            const SizedBox(height: 6),
            _summaryRow('SGST (2.5%)', '₹${sgst.toStringAsFixed(2)}'),
            const SizedBox(height: 6),
            _summaryRow(
              'Platform Fee (${cartNotifier.platformFeePercent.toStringAsFixed(cartNotifier.platformFeePercent == cartNotifier.platformFeePercent.toInt() ? 0 : 1)}%)',
              '₹${platformCharges.toStringAsFixed(2)}',
            ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 14),
              child: Divider(height: 1, color: AppColors.divider),
            ),
            _summaryRow('Grand Total', '₹${total.toStringAsFixed(2)}',
                isMain: true),
            const SizedBox(height: 20),
            // Gradient checkout button
            GestureDetector(
              onTap: () {
                if (!seatSelection.isComplete) {
                  _showLocationSelection(context, ref);
                  return;
                }
                context.push('/checkout');
              },
              child: Container(
                width: double.infinity,
                height: 56,
                decoration: BoxDecoration(
                  gradient: AppGradients.primaryButton,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: AppShadows.buttonPrimary,
                ),
                child: Center(
                  child: Text(
                    seatSelection.isComplete
                        ? 'Proceed to Checkout'
                        : 'Select Seat to Continue',
                    style: AppTextStyles.buttonLarge,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _summaryRow(String label, String value, {bool isMain = false, bool isPromo = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: isMain
              ? AppTextStyles.headingMedium
              : isPromo
                  ? AppTextStyles.bodyMedium.copyWith(color: Colors.greenAccent, fontWeight: FontWeight.bold)
                  : AppTextStyles.bodyMedium,
        ),
        Text(
          value,
          style: isMain
              ? AppTextStyles.priceLarge
              : isPromo
                  ? AppTextStyles.bodyLarge.copyWith(color: Colors.greenAccent, fontWeight: FontWeight.w900)
                  : AppTextStyles.bodyLarge,
        ),
      ],
    );
  }

  Widget _buildBogoAlerts(BuildContext context, WidgetRef ref, List<CartItem> cartItems) {
    final offersState = ref.watch(offersProvider);
    return offersState.when(
      data: (offers) {
        final alerts = _getBogoUpsells(cartItems, offers);
        if (alerts.isEmpty) return const SizedBox.shrink();
        
        return Column(
          children: alerts.map((alert) {
            final missingQty = alert['missingQuantity'] as int;
            final item = alert['item'] as FoodItem;
            return Container(
              margin: const EdgeInsets.only(left: 24, right: 24, top: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.amber.withValues(alpha: 0.18), Colors.orange.withValues(alpha: 0.08)],
                ),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.amber.withValues(alpha: 0.3)),
                boxShadow: [
                  BoxShadow(color: Colors.amber.withValues(alpha: 0.05), blurRadius: 10)
                ],
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.amber.withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.card_giftcard_rounded, color: Colors.amber, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'EXCLUSIVE BOGO REMINDER',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w900,
                            color: Colors.amber[200],
                            letterSpacing: 1.5,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          alert['message'] as String,
                          style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold, height: 1.3),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: () {
                      ref.read(cartProvider.notifier).updateQuantity(item.id, missingQty);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Added $missingQty more ${item.name} to complete your BOGO!'),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.amber,
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      minimumSize: Size.zero,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    child: Text(
                      '+ ADD $missingQty',
                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w900),
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }

  List<Map<String, dynamic>> _getBogoUpsells(List<CartItem> cartItems, List<Map<String, dynamic>> activeOffers) {
    final List<Map<String, dynamic>> alerts = [];
    
    for (final offer in activeOffers) {
      final category = offer['category'] as String? ?? '';
      if (!category.startsWith('BUY_')) continue;
      
      final buyQty = offer['buy_quantity'] as int? ?? 1;
      final getQty = offer['get_quantity'] as int? ?? 1;
      final blockSize = buyQty + getQty;
      
      final mappedItemIds = List<String>.from(
        offer['offer_items']?.map((oi) => oi['food_item_id'] as String) ?? []
      );
      
      int totalCartQty = 0;
      CartItem? representativeItem;
      
      for (final item in cartItems) {
        if (mappedItemIds.contains(item.foodItem.id)) {
          totalCartQty += item.quantity;
          representativeItem = item;
        }
      }
      
      if (totalCartQty > 0) {
        final remainder = totalCartQty % blockSize;
        if (remainder > 0 && remainder <= buyQty) {
          final missingQty = blockSize - remainder;
          alerts.add({
            'offer': offer,
            'item': representativeItem!.foodItem,
            'missingQuantity': missingQty,
            'message': 'Add $missingQty more ${representativeItem.foodItem.name}(s) to unlock your "${offer['title']}" BOGO free deal!',
          });
        }
      }
    }
    
    return alerts;
  }

  void _showLocationSelection(BuildContext context, WidgetRef ref) {
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
}
