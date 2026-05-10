import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/models/combo_model.dart';

/// Bottom sheet showing full combo details with item breakdown, savings highlight,
/// and an "Add Combo to Cart" CTA.
class ComboDetailPopup extends StatelessWidget {
  final ComboMeal combo;
  final VoidCallback onAddToCart;

  const ComboDetailPopup({
    super.key,
    required this.combo,
    required this.onAddToCart,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          Center(
            child: Container(
              width: 48,
              height: 5,
              margin: const EdgeInsets.only(top: 12, bottom: 20),
              decoration: BoxDecoration(
                color: colorScheme.onSurface.withOpacity(0.12),
                borderRadius: BorderRadius.circular(3),
              ),
            ),
          ),

          // Image
          if (combo.imageUrl.isNotEmpty)
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 24),
              height: 180,
              clipBehavior: Clip.antiAlias,
              decoration: BoxDecoration(borderRadius: BorderRadius.circular(20)),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Image.network(
                    combo.imageUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(color: colorScheme.primary.withOpacity(0.1)),
                  ),
                  // Gradient
                  Positioned.fill(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [Colors.transparent, Colors.black.withOpacity(0.5)],
                        ),
                      ),
                    ),
                  ),
                  // Savings ribbon
                  if (combo.hasSavings)
                    Positioned(
                      bottom: 14,
                      left: 14,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(colors: [Color(0xFF4CAF50), Color(0xFF087f23)]),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          '🎉 Save ${combo.savingsLabel}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w900,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),

          // Content
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title + category
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(combo.name, style: AppTextStyles.headingMedium),
                          const SizedBox(height: 4),
                          Text(combo.category,
                              style: TextStyle(
                                  fontSize: 12,
                                  color: const Color(0xFFFF6B35),
                                  fontWeight: FontWeight.w700)),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '₹${combo.price.toInt()}',
                          style: TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.w900,
                            color: colorScheme.primary,
                          ),
                        ),
                        if (combo.hasSavings)
                          Text(
                            '₹${combo.originalPrice!.toInt()}',
                            style: TextStyle(
                              fontSize: 13,
                              color: colorScheme.onSurface.withOpacity(0.35),
                              decoration: TextDecoration.lineThrough,
                            ),
                          ),
                      ],
                    ),
                  ],
                ),

                if (combo.description.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Text(combo.description,
                      style: TextStyle(
                          fontSize: 13,
                          color: colorScheme.onSurface.withOpacity(0.6),
                          height: 1.5)),
                ],

                const SizedBox(height: 20),
                Text(
                  "WHAT'S INCLUDED",
                  style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.5,
                      color: colorScheme.onSurface.withOpacity(0.4)),
                ),
                const SizedBox(height: 12),

                // Items breakdown
                ...combo.items.map((ci) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Row(
                        children: [
                          Container(
                            width: 28,
                            height: 28,
                            decoration: BoxDecoration(
                              color: const Color(0xFFFF6B35).withOpacity(0.12),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Center(
                              child: Text(
                                '${ci.quantity}×',
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w900,
                                  color: Color(0xFFFF6B35),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(ci.foodItemName,
                                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                          ),
                          Text(
                            '₹${(ci.foodItemPrice * ci.quantity).toInt()}',
                            style: TextStyle(
                                fontSize: 13,
                                color: colorScheme.onSurface.withOpacity(0.5),
                                fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                    )),

                // Divider + total savings breakdown
                if (combo.hasSavings) ...[
                  const Divider(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Total if bought separately',
                          style: TextStyle(
                              fontSize: 12, color: colorScheme.onSurface.withOpacity(0.5))),
                      Text(
                        '₹${combo.originalPrice!.toInt()}',
                        style: TextStyle(
                            fontSize: 12,
                            color: colorScheme.onSurface.withOpacity(0.5),
                            decoration: TextDecoration.lineThrough),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('You save',
                          style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: Colors.green)),
                      Text(
                        '₹${combo.savings.toInt()}',
                        style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w900,
                            color: Colors.green),
                      ),
                    ],
                  ),
                ],

                const SizedBox(height: 24),
              ],
            ),
          ),

          // Add to cart CTA
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
            child: SizedBox(
              width: double.infinity,
              height: 58,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFFF6B35), Color(0xFFFF2D55)],
                  ),
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFFF2D55).withOpacity(0.35),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: ElevatedButton.icon(
                  onPressed: () {
                    onAddToCart();
                    Navigator.of(context).pop();
                  },
                  icon: const Icon(Icons.add_shopping_cart_rounded, color: Colors.white),
                  label: const Text(
                    'ADD COMBO TO CART',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
