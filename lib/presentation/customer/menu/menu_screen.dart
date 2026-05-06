import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/models/food_item.dart';
import '../../../core/providers/cart_provider.dart';
import '../../../core/providers/menu_provider.dart';
import '../../../core/providers/seat_selection_provider.dart';
import '../../../core/providers/category_provider.dart';
import '../../shared/widgets/custom_bottom_nav_bar.dart';
import '../../shared/widgets/food_item_card.dart';
import '../../shared/widgets/safe_network_image.dart';
import '../../../core/providers/theme_provider.dart';
import 'widgets/location_popup.dart';

class MenuScreen extends ConsumerStatefulWidget {
  const MenuScreen({super.key});

  @override
  ConsumerState<MenuScreen> createState() => _MenuScreenState();
}

class _MenuScreenState extends ConsumerState<MenuScreen> {
  final List<String> categories = const [
    'All',
    'Popcorn',
    'Snacks',
    'Beverages',
    'Meals',
  ];
  
  final Map<String, List<String>> categoryMatches = {
    'Popcorn': ['POPCORN', 'CORN'],
    'Snacks': ['SNACKS', 'TACOS', 'SIDES', 'STARTERS'],
    'Beverages': ['BEVERAGES', 'DRINKS', 'SODA', 'COFFEE', 'TEA'],
    'Meals': ['MEALS', 'BURGERS', 'PIZZA', 'PLATTERS'],
  };

  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final selection = ref.read(seatSelectionProvider);
      if (!selection.isComplete) {
        _showLocationSelection();
      } else {
        ref.read(menuProvider.notifier).refreshMenu(selection.hallId!);
      }
    });
  }

  void _showLocationSelection() {
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
          ref.read(menuProvider.notifier).refreshMenu(hallId);
        },
      ),
    );
  }

  List<FoodItem> getFilteredFoods(List<FoodItem> allFoods, String? selectedCategory) {
    final availableFoods = allFoods.where((food) => food.isAvailable).toList();
    
    var result = availableFoods;
    
    if (_searchQuery.isNotEmpty) {
      final query = _searchQuery.toLowerCase();
      result = result.where((food) {
        return food.name.toLowerCase().contains(query) ||
            food.description.toLowerCase().contains(query);
      }).toList();
    }
    
    if (selectedCategory != null && selectedCategory != 'All') {
      final matches = categoryMatches[selectedCategory] ?? [];
      result = result.where((food) {
        final cat = (food.category ?? '').toUpperCase();
        return matches.contains(cat) || cat == selectedCategory.toUpperCase();
      }).toList();
    }
    
    return result;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final selectedCategory = ref.watch(categoryProvider);
    final menuState = ref.watch(menuProvider);
    final selection = ref.watch(seatSelectionProvider);
    final foods = getFilteredFoods(menuState.items, selectedCategory);

    return Scaffold(
      backgroundColor: colorScheme.background,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          _buildAppBar(context, selection),
          _buildHeader(context, selection),
          _buildSearchBar(context),
          _buildStickyTabs(context, selectedCategory),
          menuState.isLoading 
            ? _buildShimmerGrid(context)
            : _buildGrid(context, foods, selection),
          const SliverToBoxAdapter(child: SizedBox(height: 120)),
        ],
      ),
      bottomNavigationBar: const CustomBottomNavBar(currentIndex: 1),
    );
  }

  Widget _buildAppBar(BuildContext context, SeatSelectionState selection) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    return SliverAppBar(
      pinned: true,
      backgroundColor: colorScheme.background.withOpacity(0.95),
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      centerTitle: false,
      title: GestureDetector(
        onTap: _showLocationSelection,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Premium Menu',
              style: theme.textTheme.titleLarge?.copyWith(
                color: colorScheme.primary,
                fontWeight: FontWeight.w900,
              ),
            ),
            Row(
              children: [
                Icon(Icons.location_on_rounded,
                    size: 14, color: colorScheme.onSurface.withOpacity(0.5)),
                const SizedBox(width: 4),
                Text(
                  selection.isComplete
                      ? selection.displayLabel
                      : 'Select Cinema & Seat',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurface.withOpacity(0.5),
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Icon(Icons.keyboard_arrow_down_rounded,
                    size: 16, color: colorScheme.onSurface.withOpacity(0.5)),
              ],
            ),
          ],
        ),
      ),
      leading: IconButton(
        onPressed: () => context.go('/home'),
        icon: Icon(Icons.arrow_back_ios_new_rounded,
            color: colorScheme.onSurface, size: 20),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, SeatSelectionState selection) {
    return SliverToBoxAdapter(
      child: Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Neon \nMenu',
              style: AppTextStyles.headingHero.copyWith(
                fontSize: 42,
                height: 1.1,
                color: Colors.white,
                fontWeight: FontWeight.w900,
              ),
            ).animate().shimmer(duration: 2.seconds, color: AppColors.primaryLight.withOpacity(0.5)),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchBar(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.surfaceDark.withOpacity(0.6),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.borderDark.withOpacity(0.5)),
            boxShadow: [
              BoxShadow(
                color: AppColors.accent.withOpacity(0.05),
                blurRadius: 15,
                spreadRadius: 2,
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: TextField(
                onChanged: (v) => setState(() => _searchQuery = v),
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'Search deliciousness...',
                  hintStyle: TextStyle(color: Colors.white.withOpacity(0.4)),
                  prefixIcon: const Icon(Icons.search, color: AppColors.accent),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 15),
                ),
              ),
            ),
          ),
        ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.2, end: 0),
      ),
    );
  }

  Widget _buildStickyTabs(BuildContext context, String? selectedCategory) {
    return SliverPersistentHeader(
      pinned: true,
      delegate: _StickyTabBarDelegate(
        child: Container(
          color: AppColors.bgDarkStart.withOpacity(0.95),
          height: 60,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: categories.length,
            itemBuilder: (context, index) {
              final cat = categories[index];
              final isSelected = (selectedCategory == null && cat == 'All') || (selectedCategory == cat);
              
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
                child: ChoiceChip(
                  label: Text(cat),
                  selected: isSelected,
                  onSelected: (val) {
                    ref.read(categoryProvider.notifier).setCategory(cat == 'All' ? null : cat);
                  },
                  backgroundColor: AppColors.surfaceDark.withOpacity(0.5),
                  selectedColor: AppColors.primary.withOpacity(0.2),
                  side: BorderSide(
                    color: isSelected ? AppColors.primary : AppColors.borderDark,
                  ),
                  labelStyle: TextStyle(
                    color: isSelected ? AppColors.primaryLight : Colors.white.withOpacity(0.4),
                    fontWeight: isSelected ? FontWeight.w900 : FontWeight.normal,
                    fontSize: 12,
                  ),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildGrid(BuildContext context, List<FoodItem> foods, SeatSelectionState selection) {
    if (foods.isEmpty) {
      return SliverToBoxAdapter(
        child: Container(
          height: 400,
          alignment: Alignment.center,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.restaurant_menu, size: 64, color: Colors.grey.withOpacity(0.2)),
              const SizedBox(height: 16),
              Text('No items found in this category', style: TextStyle(color: Colors.grey.withOpacity(0.5))),
            ],
          ),
        ),
      );
    }

    return SliverPadding(
      padding: const EdgeInsets.all(20),
      sliver: SliverGrid(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisSpacing: 20,
          crossAxisSpacing: 20,
          childAspectRatio: 0.7,
        ),
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            final item = foods[index];
            return FoodItemCard(
              id: item.id,
              name: item.name,
              imageUrl: item.imageUrl,
              price: item.price,
              onTap: () => context.push('/food-detail', extra: item),
              onAdd: () {
                ref.read(cartProvider.notifier).validateAndAddItem(item, selection.hallId);
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
          childCount: foods.length,
        ),
      ),
    );
  }

  Widget _buildShimmerGrid(BuildContext context) {
    return const SliverToBoxAdapter(child: Center(child: CircularProgressIndicator()));
  }
}

class _StickyTabBarDelegate extends SliverPersistentHeaderDelegate {
  final Widget child;
  _StickyTabBarDelegate({required this.child});

  @override
  double get minExtent => 60;
  @override
  double get maxExtent => 60;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return child;
  }

  @override
  bool shouldRebuild(_StickyTabBarDelegate oldDelegate) => false;
}
