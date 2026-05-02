import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/models/food_item.dart';
import '../../../core/providers/cart_provider.dart';
import '../../../core/providers/seat_selection_provider.dart';
import '../../shared/widgets/safe_network_image.dart';

class FoodDetailScreen extends ConsumerWidget {
  final FoodItem foodItem;

  const FoodDetailScreen({super.key, required this.foodItem});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [AppColors.bgStart, AppColors.bgEnd],
          ),
        ),
        child: CustomScrollView(
          slivers: [
            _buildAppBar(context),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildPriceTag(),
                    const SizedBox(height: 16),
                    _buildTitle(),
                    const SizedBox(height: 12),
                    _buildDescription(),
                    const SizedBox(height: 32),
                    _buildNutritionalInfo(),
                    const SizedBox(height: 32),
                    _buildIngredients(),
                    const SizedBox(height: 120),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      bottomSheet: _buildBottomAction(context, ref),
    );
  }

  Widget _buildAppBar(BuildContext context) {
    return SliverAppBar(
      expandedHeight: 400,
      pinned: true,
      stretch: true,
      backgroundColor: AppColors.bgStart,
      leading: IconButton(
        icon: const CircleAvatar(
          backgroundColor: Colors.black26,
          child: Icon(Icons.arrow_back_ios_new_rounded,
              color: AppColors.white, size: 20),
        ),
        onPressed: () => context.pop(),
      ),
      flexibleSpace: FlexibleSpaceBar(
        stretchModes: const [StretchMode.zoomBackground],
        background: Hero(
          tag: 'food_${foodItem.id}',
          child: Stack(
            fit: StackFit.expand,
            children: [
              SafeNetworkImage(
                imageUrl: foodItem.imageUrl,
                fit: BoxFit.cover,
              ),
              const DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [
                      AppColors.bgEnd,
                      Colors.transparent,
                    ],
                    stops: [0.0, 0.4],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPriceTag() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.primary.withOpacity(0.3)),
      ),
      child: Text(
        '₹${foodItem.price.toInt()}',
        style: AppTextStyles.priceLarge
            .copyWith(fontSize: 20, color: AppColors.primary),
      ),
    );
  }

  Widget _buildTitle() {
    return Text(
      foodItem.name,
      style: AppTextStyles.headingHero.copyWith(
        fontSize: 32,
        height: 1.1,
      ),
    );
  }

  Widget _buildDescription() {
    return Text(
      'Experience the ultimate cinematic indulgence. Our ${foodItem.name} is crafted with premium ingredients, ensuring every bite is a masterpiece of flavor and texture.',
      style: AppTextStyles.bodyMedium.copyWith(height: 1.6),
    );
  }

  Widget _buildNutritionalInfo() {
    return Row(
      children: [
        _infoChip(Icons.local_fire_department_rounded, '450 kcal'),
        const SizedBox(width: 12),
        _infoChip(Icons.timer_outlined, '10-12 mins'),
        const SizedBox(width: 12),
        _infoChip(Icons.star_rounded, '4.8 Rating'),
      ],
    );
  }

  Widget _infoChip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.surfaceContainerHigh),
      ),
      child: Row(
        children: [
          Icon(icon, size: 14, color: AppColors.accent),
          const SizedBox(width: 6),
          Text(
            label,
            style: AppTextStyles.bodySmall.copyWith(
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIngredients() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'PREMIUM INGREDIENTS',
          style: AppTextStyles.bodySmall.copyWith(
            letterSpacing: 2,
            fontWeight: FontWeight.w900,
            color: AppColors.primary,
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 80,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: [
              _ingredientIcon('Freshly Baked', Icons.bakery_dining_rounded),
              _ingredientIcon('Organic', Icons.eco_rounded),
              _ingredientIcon('Gourmet', Icons.restaurant_rounded),
              _ingredientIcon('Chef Spec', Icons.star_outline_rounded),
            ],
          ),
        ),
      ],
    );
  }

  Widget _ingredientIcon(String label, IconData icon) {
    return Container(
      width: 100,
      margin: const EdgeInsets.only(right: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.surfaceContainerHigh),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: AppColors.textMuted, size: 24),
          const SizedBox(height: 8),
          Text(
            label,
            style: AppTextStyles.bodySmall.copyWith(fontSize: 10),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildBottomAction(BuildContext context, WidgetRef ref) {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 40),
      decoration: BoxDecoration(
        color: AppColors.bgEnd,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: AppColors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: () {
          final hallId = ref.read(seatSelectionProvider).hallId;
          ref.read(cartProvider.notifier).validateAndAddItem(foodItem, hallId);
          context.pop();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${foodItem.name} added to cart'),
              backgroundColor: AppColors.primary,
              behavior: SnackBarBehavior.floating,
            ),
          );
        },
        child: const Text('ADD TO ORDER'),
      ),
    );
  }
}
