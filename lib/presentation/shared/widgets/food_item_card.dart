import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import 'safe_network_image.dart';

class FoodItemCard extends StatefulWidget {
  final String id;
  final String name;
  final String imageUrl;
  final double price;
  final double? originalPrice;
  final String? savingsLabel;
  final VoidCallback onAdd;
  final VoidCallback? onTap;

  const FoodItemCard({
    super.key,
    required this.id,
    required this.name,
    required this.imageUrl,
    required this.price,
    this.originalPrice,
    this.savingsLabel,
    required this.onAdd,
    this.onTap,
  });

  @override
  State<FoodItemCard> createState() => _FoodItemCardState();
}

class _FoodItemCardState extends State<FoodItemCard> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) {
        setState(() => _isPressed = false);
        widget.onTap?.call();
      },
      onTapCancel: () => setState(() => _isPressed = false),
      child: AnimatedScale(
        scale: _isPressed ? 0.95 : 1.0,
        duration: const Duration(milliseconds: 150),
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.surfaceDark.withOpacity(0.6),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: AppColors.primary.withOpacity(0.3)),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withOpacity(_isPressed ? 0.4 : 0.15),
                blurRadius: _isPressed ? 30 : 15,
                spreadRadius: _isPressed ? 5 : 0,
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Image + Hero part
                  Expanded(
                    flex: 7,
                    child: Stack(
                      children: [
                        ClipRRect(
                          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                          child: Hero(
                            tag: 'food_${widget.id}',
                            child: SafeNetworkImage(
                              imageUrl: widget.imageUrl.isNotEmpty
                                  ? widget.imageUrl
                                  : 'https://images.unsplash.com/photo-1546069901-ba9599a7e63c?w=400', 
                              fit: BoxFit.cover,
                              width: double.infinity,
                              height: double.infinity,
                            ),
                          ),
                        ),
                        if (widget.savingsLabel != null)
                          Positioned(
                            bottom: 8,
                            left: 8,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [AppColors.secondary, AppColors.secondary.withOpacity(0.8)],
                                ),
                                borderRadius: BorderRadius.circular(10),
                                boxShadow: [
                                  BoxShadow(color: AppColors.secondary.withOpacity(0.4), blurRadius: 8)
                                ],
                              ),
                              child: Text(
                                widget.savingsLabel!,
                                style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w900),
                              ),
                            ),
                          ),
                        Positioned(
                          top: 8,
                          right: 8,
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: AppColors.bgDarkStart.withOpacity(0.8),
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(color: AppColors.success.withOpacity(0.5), blurRadius: 10)
                              ],
                            ),
                            child: const Icon(
                              Icons.circle,
                              color: AppColors.success,
                              size: 10,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Info + Add button part
                  Expanded(
                    flex: 4,
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTextStyles.headingMedium.copyWith(
                              fontSize: 14,
                              color: Colors.white,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '⭐ Neon Pick',
                            style: AppTextStyles.bodySmall.copyWith(
                              fontSize: 9,
                              color: AppColors.accent,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.5,
                            ),
                          ).animate(onPlay: (controller) => controller.repeat(reverse: true)).shimmer(duration: 1.seconds),
                          const Spacer(),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Flexible(
                                child: Row(
                                  children: [
                                    Text(
                                      '₹${widget.price.toInt()}',
                                      style: AppTextStyles.priceLarge.copyWith(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w900,
                                        color: AppColors.primaryLight,
                                      ),
                                    ),
                                    if (widget.originalPrice != null && widget.originalPrice! > widget.price) ...[
                                      const SizedBox(width: 4),
                                      Text(
                                        '₹${widget.originalPrice!.toInt()}',
                                        style: TextStyle(
                                          fontSize: 11,
                                          decoration: TextDecoration.lineThrough,
                                          color: Colors.white.withOpacity(0.3),
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                              _buildAddButton(),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ).animate().fadeIn(duration: 300.ms).slideY(begin: 0.1, end: 0),
      ),
    );
  }

  Widget _buildAddButton() {
    return Material(
      color: AppColors.primary.withOpacity(0.2),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: AppColors.primary),
      ),
      elevation: 0,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: widget.onAdd,
        splashColor: AppColors.primary.withOpacity(0.5),
        highlightColor: AppColors.primary.withOpacity(0.3),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          child: const Icon(
            Icons.add_rounded,
            color: Colors.white,
            size: 18,
          ),
        ),
      ),
    );
  }
}
