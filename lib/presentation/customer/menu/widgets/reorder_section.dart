import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/models/food_item.dart';
import '../../../../core/providers/cart_provider.dart';
import '../../../../core/providers/menu_provider.dart';
import '../../../../core/providers/reorder_provider.dart';
import '../../../../core/providers/seat_selection_provider.dart';
import '../../../shared/widgets/safe_network_image.dart';

/// Netflix-style horizontal scroll "Order Again" section shown at top of menu.
/// Hidden entirely when there are no suggestions.
class ReorderSection extends ConsumerWidget {
  const ReorderSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reorderState = ref.watch(reorderProvider);
    final menuState = ref.watch(menuProvider);
    final menu = menuState.items;

    // Filter reorder suggestions to only show items that are present in the current menu and are available/in stock
    final activeSuggestions = reorderState.suggestions.map((suggestion) {
      try {
        return menu.firstWhere((menuItem) => menuItem.id == suggestion.foodId && menuItem.isAvailable);
      } catch (_) {
        return null;
      }
    }).whereType<FoodItem>().toList();

    // Nothing to show — hide section completely
    if (!reorderState.isLoading && activeSuggestions.isEmpty) {
      return const SliverToBoxAdapter(child: SizedBox.shrink());
    }

    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return SliverToBoxAdapter(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section header
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 12),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.replay_rounded, color: AppColors.primary, size: 16),
                ),
                const SizedBox(width: 10),
                Text(
                  'Order Again',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.3,
                  ),
                ),
                const Spacer(),
                Text(
                  'Previously ordered',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: colorScheme.onSurface.withValues(alpha: 0.4),
                  ),
                ),
              ],
            ),
          ).animate().fadeIn(duration: 300.ms),

          // Horizontal scroll cards
          SizedBox(
            height: 140,
            child: reorderState.isLoading
                ? _buildShimmerRow()
                : ListView.builder(
                    scrollDirection: Axis.horizontal,
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.only(left: 24, right: 8),
                    itemCount: activeSuggestions.length,
                    itemBuilder: (context, index) {
                      final item = activeSuggestions[index];
                      return _ReorderCard(
                        item: item,
                        index: index,
                        onAddAgain: () {
                          final selection = ref.read(seatSelectionProvider);
                          ref.read(cartProvider.notifier).validateAndAddItem(
                                item,
                                selection.hallId,
                              );
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('${item.name} added to cart'),
                              behavior: SnackBarBehavior.floating,
                              duration: const Duration(seconds: 1),
                            ),
                          );
                        },
                      );
                    },
                  ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _buildShimmerRow() {
    return ListView.builder(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.only(left: 24),
      itemCount: 4,
      itemBuilder: (_, __) => Container(
        width: 120,
        margin: const EdgeInsets.only(right: 12),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(16),
        ),
      ).animate(onPlay: (c) => c.repeat()).shimmer(
            duration: 1200.ms,
            color: Colors.white.withValues(alpha: 0.05),
          ),
    );
  }
}

class _ReorderCard extends StatelessWidget {
  final FoodItem item;
  final int index;
  final VoidCallback onAddAgain;

  const _ReorderCard({
    required this.item,
    required this.index,
    required this.onAddAgain,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      width: 120,
      margin: const EdgeInsets.only(right: 12),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: colorScheme.outline.withValues(alpha: 0.08)),
        boxShadow: [
          BoxShadow(
            color: colorScheme.onSurface.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Image
          Expanded(
            flex: 5,
            child: ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
              child: SafeNetworkImage(
                imageUrl: item.imageUrl,
                width: double.infinity,
                height: double.infinity,
                fit: BoxFit.cover,
                borderRadius: BorderRadius.zero,
              ),
            ),
          ),

          // Info
          Expanded(
            flex: 4,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(8, 6, 8, 6),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.name,
                    style: theme.textTheme.labelSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                      fontSize: 10,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '₹${item.price.toInt()}',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w900,
                      color: AppColors.primary,
                    ),
                  ),
                  const Spacer(),
                  // Add Again button
                  GestureDetector(
                    onTap: onAddAgain,
                    child: Container(
                      height: 22,
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Center(
                        child: Text(
                          '⚡ Add Again',
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w900,
                            color: AppColors.primary,
                            letterSpacing: 0.3,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    )
        .animate(delay: Duration(milliseconds: 60 * index))
        .fadeIn(duration: 300.ms)
        .slideX(begin: 0.15, end: 0);
  }
}
