import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
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
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final cart = ref.watch(cartProvider);
    final total = cart.items.fold<double>(
        0, (sum, item) => sum + (item.foodItem.price * item.quantity));

    return Scaffold(
      backgroundColor: colorScheme.background,
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
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    return AppBar(
      backgroundColor: Colors.transparent,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      leading: IconButton(
        icon: Icon(Icons.arrow_back_ios_new_rounded,
            color: colorScheme.onSurface, size: 20),
        onPressed: () => context.pop(),
      ),
      title: Text('My Cart',
          style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900)),
      centerTitle: true,
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: colorScheme.primary.withOpacity(0.05),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.shopping_bag_outlined,
                  size: 80, color: colorScheme.primary.withOpacity(0.3)),
            ),
            const SizedBox(height: 32),
            Text('Your cart is empty', 
                style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w900)),
            const SizedBox(height: 12),
            Text('Add some delicious food to start your premium dining experience!',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(color: colorScheme.onSurface.withOpacity(0.6))),
            const SizedBox(height: 40),
            ElevatedButton(
              onPressed: () => context.go('/menu'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              ),
              child: const Text('EXPLORE MENU'),
            ),
          ],
        ),
      ),
    );
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
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: colorScheme.outline.withOpacity(0.1)),
        boxShadow: [
          BoxShadow(
            color: colorScheme.onSurface.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              SafeNetworkImage(
                imageUrl: item.foodItem.imageUrl,
                width: 90,
                height: 90,
                fit: BoxFit.cover,
                borderRadius: BorderRadius.circular(16),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.foodItem.name,
                      style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '₹${item.foodItem.price.toInt()}',
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: colorScheme.primary,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              ),
              _buildQuantityPicker(ref, item),
            ],
          ),
          if (item.note != null && item.note!.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 16),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: colorScheme.onSurface.withOpacity(0.03),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(Icons.notes_rounded,
                        color: colorScheme.onSurface.withOpacity(0.4), size: 16),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        item.note!,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurface.withOpacity(0.6),
                          fontStyle: FontStyle.italic,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    GestureDetector(
                      onTap: () => _showNoteEditor(context, ref, item),
                      child: Text(
                        'EDIT',
                        style: theme.textTheme.labelSmall?.copyWith(
                            color: colorScheme.primary,
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
              padding: const EdgeInsets.only(top: 12),
              child: InkWell(
                onTap: () => _showNoteEditor(context, ref, item),
                child: Row(
                  children: [
                    Icon(Icons.add_comment_outlined,
                        size: 14, color: colorScheme.primary.withOpacity(0.6)),
                    const SizedBox(width: 8),
                    Text(
                      'Add a note',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: colorScheme.primary.withOpacity(0.6),
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
        color: AppColors.surfaceContainer,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.surfaceContainerHigh),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _pickerButton(
            icon: Icons.remove,
            onTap: () => ref
                .read(cartProvider.notifier)
                .updateQuantity(item.foodItem.id, -1),
            color: AppColors.textSecondary,
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Text(
              '${item.quantity}',
              style: AppTextStyles.headingMedium.copyWith(fontSize: 14),
            ),
          ),
          _pickerButton(
            icon: Icons.add,
            onTap: () => ref
                .read(cartProvider.notifier)
                .updateQuantity(item.foodItem.id, 1),
            color: AppColors.primary,
          ),
        ],
      ),
    );
  }

  Widget _pickerButton(
      {required IconData icon,
      required VoidCallback onTap,
      required Color color}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(8),
        child: Icon(icon, size: 18, color: color),
      ),
    );
  }

  Widget _buildSummary(BuildContext context, WidgetRef ref, double subtotal) {
    final seatSelection = ref.watch(seatSelectionProvider);
    final cartNotifier = ref.watch(cartProvider.notifier);
    final colorScheme = Theme.of(context).colorScheme;
    
    final discount = cartNotifier.discount;
    final cgst = cartNotifier.cgst;
    final sgst = cartNotifier.sgst;
    final platformCharges = cartNotifier.platformCharges;
    final total = cartNotifier.totalAmount;

    return Container(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 40),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.12),
            blurRadius: 20,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _summaryRow('Subtotal', '₹${subtotal.toStringAsFixed(2)}'),
            const SizedBox(height: 8),
            if (discount > 0) ...[
              _summaryRow('Promo Savings', '-₹${discount.toStringAsFixed(2)}', isPromo: true),
              const SizedBox(height: 8),
            ],
            _summaryRow('CGST (2.5%)', '₹${cgst.toStringAsFixed(2)}'),
            const SizedBox(height: 8),
            _summaryRow('SGST (2.5%)', '₹${sgst.toStringAsFixed(2)}'),
            const SizedBox(height: 8),
            _summaryRow('Platform Fee (1%)', '₹${platformCharges.toStringAsFixed(2)}'),
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Divider(height: 1),
            ),
            _summaryRow('Grand Total', '₹${total.toStringAsFixed(2)}',
                isMain: true),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: () {
                if (!seatSelection.isComplete) {
                  _showLocationSelection(context, ref);
                  return;
                }
                context.push('/checkout');
              },
              child: Text(
                seatSelection.isComplete
                    ? 'PROCEED TO CHECKOUT'
                    : 'SELECT SEAT TO CONTINUE',
              ),
            ),
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
                  colors: [Colors.amber.withOpacity(0.18), Colors.orange.withOpacity(0.08)],
                ),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.amber.withOpacity(0.3)),
                boxShadow: [
                  BoxShadow(color: Colors.amber.withOpacity(0.05), blurRadius: 10)
                ],
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.amber.withOpacity(0.2),
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
