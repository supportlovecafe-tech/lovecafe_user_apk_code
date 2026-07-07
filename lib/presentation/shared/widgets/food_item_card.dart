import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_shadows.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/constants/app_gradients.dart';
import 'safe_network_image.dart';

/// Display mode for FoodItemCard
enum FoodCardMode {
  /// Horizontal list tile — menu screen (image right, info left, + button)
  list,

  /// Compact vertical card — home popular section, search results
  compact,
}

/// Cinema Eats — Premium Food Item Card
///
/// [list] mode: reference design — horizontal row with thumbnail on the right,
///   name/description/price on the left, + button on the far right.
///
/// [compact] mode: small vertical card for horizontal scroll sections on Home.
class FoodItemCard extends StatefulWidget {
  final String id;
  final String name;
  final String description;
  final String imageUrl;
  final double price;
  final double? originalPrice;
  final String? savingsLabel;
  final bool isVeg;
  final VoidCallback onAdd;
  final VoidCallback? onTap;
  final FoodCardMode mode;
  final bool isBestseller;

  const FoodItemCard({
    super.key,
    required this.id,
    required this.name,
    this.description = '',
    required this.imageUrl,
    required this.price,
    this.originalPrice,
    this.savingsLabel,
    this.isVeg = true,
    required this.onAdd,
    this.onTap,
    this.mode = FoodCardMode.list,
    this.isBestseller = false,
  });

  @override
  State<FoodItemCard> createState() => _FoodItemCardState();
}

class _FoodItemCardState extends State<FoodItemCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _addController;
  late Animation<double> _addScale;

  @override
  void initState() {
    super.initState();
    _addController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
    );
    _addScale = Tween<double>(begin: 1.0, end: 0.85).animate(
      CurvedAnimation(parent: _addController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _addController.dispose();
    super.dispose();
  }

  void _onAddTap() {
    _addController.forward().then((_) => _addController.reverse());
    widget.onAdd();
  }

  @override
  Widget build(BuildContext context) {
    return switch (widget.mode) {
      FoodCardMode.list => _buildListTile(),
      FoodCardMode.compact => _buildCompactCard(),
    };
  }

  // ══════════════════════════════════════════
  // LIST TILE MODE (Menu Screen)
  // ══════════════════════════════════════════

  Widget _buildListTile() {
    return GestureDetector(
      onTap: widget.onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.primary.withValues(alpha: 0.25), width: 1.2),
          boxShadow: AppShadows.pinkGlowSoft,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── LEFT: info column
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Veg/non-veg dot + name
                  Row(
                    children: [
                      _VegDot(isVeg: widget.isVeg),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          widget.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTextStyles.titleMedium,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  // Description
                  if (widget.description.isNotEmpty)
                    Text(
                      widget.description,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.bodySmall,
                    ),
                  const SizedBox(height: 10),
                  // Price row
                  Row(
                    children: [
                      Text(
                        '₹${widget.price.toInt()}',
                        style: AppTextStyles.priceSmall,
                      ),
                      if (widget.originalPrice != null &&
                          widget.originalPrice! > widget.price) ...[
                        const SizedBox(width: 6),
                        Text(
                          '₹${widget.originalPrice!.toInt()}',
                          style: AppTextStyles.priceStrikethrough,
                        ),
                      ],
                      if (widget.isBestseller) ...[
                        const SizedBox(width: 8),
                        _BestsellerBadge(),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            // ── RIGHT: image + add button stacked
            Stack(
              clipBehavior: Clip.none,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Hero(
                    tag: 'food_${widget.id}',
                    child: SafeNetworkImage(
                      imageUrl: widget.imageUrl.isNotEmpty
                          ? widget.imageUrl
                          : 'https://images.unsplash.com/photo-1546069901-ba9599a7e63c?w=300',
                      width: 110,
                      height: 110,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                // Savings badge
                if (widget.savingsLabel != null)
                  Positioned(
                    top: 0,
                    left: 0,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        gradient: AppGradients.primaryButton,
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(12),
                          bottomRight: Radius.circular(8),
                        ),
                      ),
                      child: Text(
                        widget.savingsLabel!,
                        style: AppTextStyles.labelSmall
                            .copyWith(color: Colors.white, fontSize: 9),
                      ),
                    ),
                  ),
                Positioned(
                  bottom: -8,
                  right: -8,
                  child: ScaleTransition(
                    scale: _addScale,
                    child: GestureDetector(
                      onTap: _onAddTap,
                      child: Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          gradient: AppGradients.primaryButton,
                          shape: BoxShape.circle,
                          boxShadow: AppShadows.pinkGlowSoft,
                          border: Border.all(color: AppColors.surface, width: 2),
                        ),
                        child: const Icon(
                          Icons.add_rounded,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(width: 10),
          ],
        ),
      ),
    )
        .animate()
        .fadeIn(duration: 250.ms)
        .slideY(begin: 0.08, end: 0, duration: 250.ms, curve: Curves.easeOut);
  }

  // ══════════════════════════════════════════
  // COMPACT CARD MODE (Home popular section)
  // ══════════════════════════════════════════

  Widget _buildCompactCard() {
    return GestureDetector(
      onTap: widget.onTap,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.primary.withValues(alpha: 0.25), width: 1.2),
          boxShadow: AppShadows.pinkGlowSoft,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Image
            Expanded(
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    SafeNetworkImage(
                      imageUrl: widget.imageUrl.isNotEmpty
                          ? widget.imageUrl
                          : 'https://images.unsplash.com/photo-1546069901-ba9599a7e63c?w=300',
                      fit: BoxFit.cover,
                      borderRadius: BorderRadius.zero,
                    ),
                    // Gradient overlay for better text contrast if we put badges on image
                    Positioned.fill(
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: AppGradients.cardImageOverlay,
                        ),
                      ),
                    ),
                    // Veg dot badge top-left
                    Positioned(
                      top: 8,
                      left: 8,
                      child: Container(
                        padding: const EdgeInsets.all(5),
                        decoration: BoxDecoration(
                          color: AppColors.bg.withValues(alpha: 0.75),
                          shape: BoxShape.circle,
                        ),
                        child: _VegDot(isVeg: widget.isVeg, size: 8),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // Info
            Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    widget.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.titleSmall,
                  ),
                  if (widget.isBestseller) ...[
                    const SizedBox(height: 2),
                    Text(
                      '⭐ Bestseller',
                      style: AppTextStyles.labelSmall.copyWith(
                        color: AppColors.accent,
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '₹${widget.price.toInt()}',
                        style: AppTextStyles.priceSmall.copyWith(fontSize: 14),
                      ),
                      // Floating Add Button
                      ScaleTransition(
                        scale: _addScale,
                        child: GestureDetector(
                          onTap: _onAddTap,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: AppColors.primary.withValues(alpha: 0.8), width: 1.5),
                            ),
                            child: const Icon(Icons.add_rounded, color: AppColors.primaryLight, size: 16),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    )
        .animate()
        .fadeIn(duration: 300.ms)
        .slideY(begin: 0.06, end: 0, duration: 300.ms, curve: Curves.easeOut);
  }
}

// ── Helpers ──────────────────────────────────

class _VegDot extends StatelessWidget {
  final bool isVeg;
  final double size;

  const _VegDot({required this.isVeg, this.size = 9});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size + 4,
      height: size + 4,
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        border: Border.all(
          color: isVeg ? const Color(0xFF22C55E) : const Color(0xFFEF4444),
          width: 1.5,
        ),
        borderRadius: BorderRadius.circular(3),
      ),
      child: Container(
        decoration: BoxDecoration(
          color: isVeg ? const Color(0xFF22C55E) : const Color(0xFFEF4444),
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}

class _BestsellerBadge extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
      ),
      child: Text(
        'Bestseller',
        style: AppTextStyles.labelSmall.copyWith(
          color: AppColors.primary,
          fontSize: 9,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
