import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/constants/app_gradients.dart';
import '../../../core/constants/app_shadows.dart';
import '../../../core/models/food_item.dart';
import '../../../core/providers/cart_provider.dart';
import '../../../core/providers/seat_selection_provider.dart';
import '../../shared/widgets/safe_network_image.dart';

/// Frontend-only size variant model
/// Regular = base price, Large = 1.4x, Bucket = 1.9x
class _SizeVariant {
  final String label;
  final double multiplier;

  const _SizeVariant(this.label, this.multiplier);

  double priceFor(double base) => (base * multiplier).roundToDouble();
}

class FoodDetailScreen extends ConsumerStatefulWidget {
  final FoodItem foodItem;

  const FoodDetailScreen({super.key, required this.foodItem});

  @override
  ConsumerState<FoodDetailScreen> createState() => _FoodDetailScreenState();
}

class _FoodDetailScreenState extends ConsumerState<FoodDetailScreen> {
  static const List<_SizeVariant> _sizes = [
    _SizeVariant('Regular', 1.0),
    _SizeVariant('Large', 1.4),
    _SizeVariant('Bucket', 1.9),
  ];

  int _selectedSizeIndex = 0;
  int _quantity = 1;

  double get _unitPrice =>
      _sizes[_selectedSizeIndex].priceFor(widget.foodItem.price);
  double get _totalPrice => _unitPrice * _quantity;
  String get _selectedSizeLabel => _sizes[_selectedSizeIndex].label;

  void _addToCart() {
    HapticFeedback.lightImpact();
    final hallId = ref.read(seatSelectionProvider).hallId;
    // Create a modified food item with the selected size's price
    final variantItem = widget.foodItem.copyWith(
      name: _quantity > 1 || _selectedSizeIndex > 0
          ? '${widget.foodItem.name} (${_selectedSizeLabel})'
          : widget.foodItem.name,
      price: _unitPrice,
    );
    for (int i = 0; i < _quantity; i++) {
      ref.read(cartProvider.notifier).validateAndAddItem(variantItem, hallId);
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle_rounded,
                color: AppColors.success, size: 18),
            const SizedBox(width: 10),
            Text('${widget.foodItem.name} added to cart',
                style: AppTextStyles.labelMedium
                    .copyWith(color: AppColors.textPrimary)),
          ],
        ),
        backgroundColor: AppColors.surfaceElevated,
        behavior: SnackBarBehavior.floating,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        duration: const Duration(seconds: 2),
      ),
    );
    context.pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      extendBodyBehindAppBar: true,
      body: CustomScrollView(
        slivers: [
          _buildSliverAppBar(context),
          SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Bestseller badge + title
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _BestsellerBadge()
                          .animate()
                          .fadeIn(duration: 250.ms)
                          .slideY(begin: 0.2, end: 0),
                      const SizedBox(height: 10),
                      Text(
                        widget.foodItem.name,
                        style: AppTextStyles.headingLarge,
                      ).animate().fadeIn(delay: 50.ms, duration: 300.ms),
                      const SizedBox(height: 8),
                      Text(
                        'Experience the ultimate cinematic indulgence. Our ${widget.foodItem.name} is crafted with premium ingredients, ensuring every bite is a masterpiece of flavor.',
                        style: AppTextStyles.bodyMedium,
                      ).animate().fadeIn(delay: 100.ms, duration: 300.ms),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // ── Info chips
                _buildInfoChips()
                    .animate()
                    .fadeIn(delay: 150.ms, duration: 300.ms),

                const SizedBox(height: 28),

                // ── Size selector
                _buildSizeSelector()
                    .animate()
                    .fadeIn(delay: 200.ms, duration: 300.ms),

                const SizedBox(height: 28),

                // ── Quantity stepper
                _buildQuantityStepper()
                    .animate()
                    .fadeIn(delay: 250.ms, duration: 300.ms),

                const SizedBox(height: 28),

                // ── Ingredients
                _buildIngredients()
                    .animate()
                    .fadeIn(delay: 300.ms, duration: 300.ms),

                const SizedBox(height: 130),
              ],
            ),
          ),
        ],
      ),
      bottomSheet: _buildBottomCTA(context),
    );
  }

  // ══════════════════════════════════════════
  // SLIVER APP BAR — hero image
  // ══════════════════════════════════════════

  Widget _buildSliverAppBar(BuildContext context) {
    return SliverAppBar(
      expandedHeight: 380,
      pinned: true,
      stretch: true,
      backgroundColor: AppColors.bg,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      leading: Padding(
        padding: const EdgeInsets.all(10),
        child: GestureDetector(
          onTap: () => context.pop(),
          child: Container(
            decoration: BoxDecoration(
              color: AppColors.bg.withValues(alpha: 0.75),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
            ),
            child: ClipOval(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                child: const Center(
                  child: Icon(Icons.arrow_back_ios_new_rounded,
                      color: Colors.white, size: 18),
                ),
              ),
            ),
          ),
        ),
      ),
      actions: [
        Padding(
          padding: const EdgeInsets.all(10),
          child: Container(
            decoration: BoxDecoration(
              color: AppColors.bg.withValues(alpha: 0.75),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
            ),
            child: ClipOval(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                child: IconButton(
                  icon: const Icon(Icons.favorite_border_rounded,
                      color: Colors.white, size: 18),
                  onPressed: () {},
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
                ),
              ),
            ),
          ),
        ),
      ],
      flexibleSpace: FlexibleSpaceBar(
        stretchModes: const [StretchMode.zoomBackground],
        background: Hero(
          tag: 'food_${widget.foodItem.id}',
          child: Stack(
            fit: StackFit.expand,
            children: [
              SafeNetworkImage(
                imageUrl: widget.foodItem.imageUrl,
                fit: BoxFit.cover,
                borderRadius: BorderRadius.zero,
              ),
              // Gradient fade to dark at bottom
              DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      AppColors.bg.withValues(alpha: 0.5),
                      AppColors.bg,
                    ],
                    stops: const [0.4, 0.75, 1.0],
                  ),
                ),
              ),
              // Radial Vignette
              DecoratedBox(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: Alignment.center,
                    radius: 1.0,
                    colors: [
                      Colors.transparent,
                      AppColors.bg.withValues(alpha: 0.5),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ══════════════════════════════════════════
  // INFO CHIPS
  // ══════════════════════════════════════════

  Widget _buildInfoChips() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        children: [
          _InfoChip(Icons.local_fire_department_outlined, '450 kcal',
              AppColors.warning),
          const SizedBox(width: 10),
          _InfoChip(Icons.timer_outlined, '10–12 min', AppColors.accent),
          const SizedBox(width: 10),
          _InfoChip(Icons.star_rounded, '4.8 Rating', AppColors.gold),
        ],
      ),
    );
  }

  // ══════════════════════════════════════════
  // SIZE SELECTOR
  // ══════════════════════════════════════════

  Widget _buildSizeSelector() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Choose Size', style: AppTextStyles.titleMedium),
          const SizedBox(height: 14),
          Row(
            children: _sizes.asMap().entries.map((entry) {
              final i = entry.key;
              final size = entry.value;
              final bool selected = i == _selectedSizeIndex;
              final double price = size.priceFor(widget.foodItem.price);

              return Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _selectedSizeIndex = i),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: EdgeInsets.only(right: i < 2 ? 10 : 0),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    decoration: BoxDecoration(
                      color: selected
                          ? AppColors.primary.withValues(alpha: 0.12)
                          : AppColors.surface,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: selected
                            ? AppColors.primary
                            : Colors.white.withValues(alpha: 0.07),
                        width: selected ? 1.5 : 1,
                      ),
                      boxShadow: selected ? AppShadows.pinkGlowSoft : [],
                    ),
                    child: Column(
                      children: [
                        Text(
                          size.label,
                          style: AppTextStyles.labelMedium.copyWith(
                            color: selected
                                ? AppColors.primary
                                : AppColors.textSecondary,
                            fontWeight: selected
                                ? FontWeight.w700
                                : FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '₹${price.toInt()}',
                          style: AppTextStyles.priceSmall.copyWith(
                            fontSize: 14,
                            color: selected
                                ? AppColors.primary
                                : AppColors.textDisabled,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  // ══════════════════════════════════════════
  // QUANTITY STEPPER
  // ══════════════════════════════════════════

  Widget _buildQuantityStepper() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text('Quantity', style: AppTextStyles.titleMedium),
          Container(
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.white.withValues(alpha: 0.07)),
            ),
            child: Row(
              children: [
                _StepperButton(
                  icon: Icons.remove_rounded,
                  onTap: () {
                    if (_quantity > 1) {
                      HapticFeedback.selectionClick();
                      setState(() => _quantity--);
                    }
                  },
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Text(
                    '$_quantity',
                    style: AppTextStyles.titleLarge,
                  ),
                ),
                _StepperButton(
                  icon: Icons.add_rounded,
                  onTap: () {
                    HapticFeedback.selectionClick();
                    setState(() => _quantity++);
                  },
                  isAdd: true,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ══════════════════════════════════════════
  // INGREDIENTS
  // ══════════════════════════════════════════

  Widget _buildIngredients() {
    final features = [
      (Icons.bakery_dining_rounded, 'Freshly\nBaked'),
      (Icons.eco_rounded, 'Organic'),
      (Icons.restaurant_rounded, 'Gourmet'),
      (Icons.star_outline_rounded, 'Chef\nSpecial'),
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('PREMIUM INGREDIENTS',
              style: AppTextStyles.sectionTitle),
          const SizedBox(height: 14),
          Row(
            children: features.map((f) {
              final (icon, label) = f;
              return Expanded(
                child: Container(
                  margin: const EdgeInsets.only(right: 10),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                        color: Colors.white.withValues(alpha: 0.05)),
                  ),
                  child: Column(
                    children: [
                      Icon(icon,
                          color: AppColors.textDisabled, size: 20),
                      const SizedBox(height: 6),
                      Text(
                        label,
                        style: AppTextStyles.labelSmall,
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  // ══════════════════════════════════════════
  // BOTTOM CTA
  // ══════════════════════════════════════════

  Widget _buildBottomCTA(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
          20, 0, 20, MediaQuery.of(context).padding.bottom + 16),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surfaceElevated.withValues(alpha: 0.85),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: AppColors.glassBorder),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.3),
              blurRadius: 20,
              offset: const Offset(0, 10),
            )
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: GestureDetector(
            onTap: _addToCart,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              height: 56,
              margin: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                gradient: AppGradients.primaryButton,
                borderRadius: BorderRadius.circular(16),
                boxShadow: AppShadows.buttonPrimary,
              ),
              child: Center(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.shopping_bag_outlined,
                        color: Colors.white, size: 20),
                    const SizedBox(width: 10),
                    Text(
                      'Add to Cart  •  ₹${_totalPrice.toInt()}',
                      style: AppTextStyles.buttonLarge,
                    ),
                  ],
                ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ── Helpers ──────────────────────────────────

class _BestsellerBadge extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: const BoxDecoration(
            color: AppColors.primary,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 6),
        Text(
          'Bestseller',
          style: AppTextStyles.labelMedium.copyWith(color: AppColors.primary),
        ),
      ],
    );
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _InfoChip(this.icon, this.label, this.color);

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 5),
            Flexible(
              child: Text(label,
                  style: AppTextStyles.labelSmall
                      .copyWith(color: AppColors.textPrimary),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis),
            ),
          ],
        ),
      ),
    );
  }
}

class _StepperButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final bool isAdd;

  const _StepperButton({
    required this.icon,
    required this.onTap,
    this.isAdd = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: isAdd ? AppColors.primary.withValues(alpha: 0.12) : Colors.transparent,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(isAdd ? 0 : 14),
            bottomLeft: Radius.circular(isAdd ? 0 : 14),
            topRight: Radius.circular(isAdd ? 14 : 0),
            bottomRight: Radius.circular(isAdd ? 14 : 0),
          ),
        ),
        child: Icon(
          icon,
          color: isAdd ? AppColors.primary : AppColors.textSecondary,
          size: 20,
        ),
      ),
    );
  }
}
