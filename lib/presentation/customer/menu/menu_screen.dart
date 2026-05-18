import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/models/food_item.dart';
import '../../../core/models/combo_model.dart';
import '../../../core/providers/cart_provider.dart';
import '../../../core/providers/menu_provider.dart';
import '../../../core/providers/combo_provider.dart';
import '../../../core/providers/seat_selection_provider.dart';
import '../../../core/providers/category_provider.dart';
import '../../../core/providers/offers_provider.dart';
import '../../shared/widgets/custom_bottom_nav_bar.dart';
import '../../shared/widgets/food_item_card.dart';
import '../../shared/widgets/safe_network_image.dart';
import '../../../core/providers/theme_provider.dart';
import 'widgets/location_popup.dart';
import 'widgets/combo_card.dart';
import 'widgets/combo_detail_popup.dart';
import 'widgets/reorder_section.dart';

class MenuScreen extends ConsumerStatefulWidget {
  const MenuScreen({super.key, this.initialOffer});

  final Map<String, dynamic>? initialOffer;

  @override
  ConsumerState<MenuScreen> createState() => _MenuScreenState();
}

class _MenuScreenState extends ConsumerState<MenuScreen> {
  bool _showVegOnly = false;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final selection = ref.read(seatSelectionProvider);
      if (!selection.isComplete) {
        _showLocationSelection();
      } else {
        await ref.read(menuProvider.notifier).refreshMenu(selection.hallId!);
        ref.read(comboProvider.notifier).loadCombos(selection.hallId!);
        
        if (widget.initialOffer != null && mounted) {
          _showOfferItemsShelf(context, ref, widget.initialOffer!, selection);
        }
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
          ref.read(comboProvider.notifier).loadCombos(hallId);
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

    if (_showVegOnly) {
      result = result.where((food) => food.isVeg).toList();
    }
    
    if (selectedCategory != null && selectedCategory != 'ALL' && selectedCategory != 'Combos') {
      result = result.where((food) => food.category.toUpperCase() == selectedCategory.toUpperCase()).toList();
    }
    
    return result;
  }

  List<ComboMeal> getFilteredCombos(List<ComboMeal> allCombos, String? selectedCategory) {
    var result = allCombos;
    if (selectedCategory == null && _searchQuery.isNotEmpty) {
      final query = _searchQuery.toLowerCase();
      result = result.where((c) =>
          c.name.toLowerCase().contains(query) ||
          c.description.toLowerCase().contains(query)).toList();
    }
    if (_showVegOnly) {
      result = result.where((c) => c.isVeg).toList();
    }
    return result;
  }

  bool get _isComboTab => ref.watch(categoryProvider) == 'Combos';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final selectedCategory = ref.watch(categoryProvider);
    final menuState = ref.watch(menuProvider);
    final comboState = ref.watch(comboProvider);
    final selection = ref.watch(seatSelectionProvider);
    
    final flatCategories = [
      'ALL',
      'COMBOS',
      'POPCORN',
      'LASSI',
      'MILKSHAKE',
      'ICE_CREAM',
      'BEVERAGES',
      'LOVE_SPECIAL',
      'SNACKS',
      'SANDWICH',
      'BURGER',
      'TIKKA',
      'WRAPS',
      'TACO',
      'MOMO',
      'CHINESE_RICE_COMBO',
      'CHINESE_NOODLES_COMBO',
      'CHINESE_PASTA',
      'PIZZA',
      'FUSION_FOODS',
    ];
    
    final showingCombos = selectedCategory == 'Combos';
    final foods = showingCombos ? <FoodItem>[] : getFilteredFoods(menuState.items, selectedCategory);
    final combos = showingCombos || selectedCategory == null
        ? getFilteredCombos(comboState.items, selectedCategory)
        : <ComboMeal>[];

    return Scaffold(
      backgroundColor: colorScheme.background,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          _buildAppBar(context, selection),
          _buildHeader(context, selection),
          _buildSearchBar(context),
          _buildOffersCarousel(context, ref),
          const ReorderSection(),
          _buildStickyTabs(context, selectedCategory, flatCategories),
          if (showingCombos)
            comboState.isLoading
                ? _buildShimmerGrid(context)
                : _buildCombosGrid(context, combos, selection)
          else ...[
            if (selectedCategory == null && combos.isNotEmpty)
              _buildCombosHeader(context),
            if (selectedCategory == null && combos.isNotEmpty)
              _buildCombosHorizontalRow(context, combos, selection),
            menuState.isLoading
                ? _buildShimmerGrid(context)
                : _buildGrid(context, foods, selection),
          ],
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
        child: Row(
          children: [
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: AppColors.surfaceDark.withOpacity(0.6),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.borderDark.withOpacity(0.5)),
                ),
                child: TextField(
                  onChanged: (v) => setState(() => _searchQuery = v),
                  style: const TextStyle(color: Colors.white, fontSize: 14),
                  decoration: InputDecoration(
                    hintText: 'Search deliciousness...',
                    hintStyle: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 14),
                    prefixIcon: const Icon(Icons.search, color: AppColors.accent, size: 20),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            GestureDetector(
              onTap: () => setState(() => _showVegOnly = !_showVegOnly),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                decoration: BoxDecoration(
                  color: _showVegOnly ? Colors.green.withOpacity(0.2) : AppColors.surfaceDark.withOpacity(0.6),
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(
                    color: _showVegOnly ? Colors.green : AppColors.borderDark.withOpacity(0.5),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      _showVegOnly ? Icons.eco_rounded : Icons.eco_outlined,
                      size: 16,
                      color: _showVegOnly ? Colors.green : Colors.white.withOpacity(0.4),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'VEG',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                        color: _showVegOnly ? Colors.green : Colors.white.withOpacity(0.4),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.2, end: 0),
    );
  }

  Widget _buildOffersCarousel(BuildContext context, WidgetRef ref) {
    final offersState = ref.watch(offersProvider);
    final selection = ref.watch(seatSelectionProvider);

    return offersState.when(
      data: (offers) {
        if (offers.isEmpty) return const SliverToBoxAdapter(child: SizedBox.shrink());

        return SliverToBoxAdapter(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(colors: [Colors.pink, Colors.purple]),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.stars_rounded, color: Colors.white, size: 14),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Special Offers & Promos',
                      style: AppTextStyles.headingMedium.copyWith(fontSize: 16, fontWeight: FontWeight.w900),
                    ),
                  ],
                ),
              ),
              SizedBox(
                height: 120,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  itemCount: offers.length,
                  itemBuilder: (context, index) {
                    final offer = offers[index];
                    return GestureDetector(
                      onTap: () => _showOfferItemsShelf(context, ref, offer, selection),
                      child: Container(
                        width: 280,
                        margin: const EdgeInsets.only(right: 14, bottom: 8, top: 4),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [AppColors.primary.withOpacity(0.2), AppColors.secondary.withOpacity(0.1)],
                          ),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: AppColors.primary.withOpacity(0.3)),
                          boxShadow: [
                            BoxShadow(color: AppColors.primary.withOpacity(0.05), blurRadius: 8)
                          ],
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: AppColors.accent.withOpacity(0.2),
                                      borderRadius: BorderRadius.circular(6),
                                      border: Border.all(color: AppColors.accent.withOpacity(0.5)),
                                    ),
                                    child: Text(
                                      (offer['category'] as String).replaceAll('_', ' '),
                                      style: const TextStyle(
                                        color: AppColors.accent,
                                        fontSize: 9,
                                        fontWeight: FontWeight.w900,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    offer['title'] as String,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    offer['description'] as String? ?? 'Special promo deal.',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 10),
                                  ),
                                ],
                              ),
                            ),
                            const Icon(Icons.arrow_forward_ios_rounded, color: AppColors.primaryLight, size: 16),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
      loading: () => const SliverToBoxAdapter(child: SizedBox.shrink()),
      error: (_, __) => const SliverToBoxAdapter(child: SizedBox.shrink()),
    );
  }

  void _showOfferItemsShelf(BuildContext context, WidgetRef ref, Map<String, dynamic> offer, SeatSelectionState selection) {
    final menuItems = ref.read(menuProvider).items;
    final mappedItemIds = List<String>.from(
      offer['offer_items']?.map((oi) => oi['food_item_id'] as String) ?? []
    );
    final targetItems = menuItems.where((item) => mappedItemIds.contains(item.id)).toList();
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          border: Border.all(color: colorScheme.outline.withOpacity(0.1)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.pink.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.pink.withOpacity(0.4)),
                  ),
                  child: Text(
                    (offer['category'] as String).replaceAll('_', ' '),
                    style: const TextStyle(color: Colors.pinkAccent, fontSize: 10, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              offer['title'] as String,
              style: AppTextStyles.headingHero.copyWith(fontSize: 24, fontWeight: FontWeight.w900),
            ),
            if (offer['description'] != null && (offer['description'] as String).isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(
                offer['description'] as String,
                style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 12, height: 1.4),
              ),
            ],
            const SizedBox(height: 24),
            Text(
              'PROMOTIONAL PRODUCTS',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w900,
                color: Colors.white.withOpacity(0.4),
                letterSpacing: 1.5,
              ),
            ),
            const SizedBox(height: 12),
            if (targetItems.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 24),
                child: Text(
                  'No items currently mapped to this promotion.',
                  style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 12, fontStyle: FontStyle.italic),
                  textAlign: TextAlign.center,
                ),
              )
            else
              ConstrainedBox(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.4,
                ),
                child: ListView.builder(
                  shrinkWrap: true,
                  physics: const BouncingScrollPhysics(),
                  itemCount: targetItems.length,
                  itemBuilder: (context, index) {
                    final item = targetItems[index];
                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.02),
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: Colors.white.withOpacity(0.05)),
                      ),
                      child: Row(
                        children: [
                          SafeNetworkImage(
                            imageUrl: item.imageUrl,
                            width: 60,
                            height: 60,
                            fit: BoxFit.cover,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item.name,
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '₹${item.price.toInt()}',
                                  style: const TextStyle(
                                    color: AppColors.primaryLight,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          ElevatedButton(
                            onPressed: () {
                              ref.read(cartProvider.notifier).validateAndAddItem(item, selection.hallId);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('${item.name} added to cart!'),
                                  behavior: SnackBarBehavior.floating,
                                  duration: const Duration(seconds: 1),
                                ),
                              );
                            },
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              minimumSize: Size.zero,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            child: const Text('ADD', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildStickyTabs(BuildContext context, String? selectedCategory, List<String> categories) {
    const Map<String, String> categoryLabels = {
      'ALL': '🍛 All',
      'COMBOS': '🔥 Combos',
      'POPCORN': '🍿 Popcorn',
      'LASSI': '🥛 Lassi',
      'MILKSHAKE': '🥤 Milkshake',
      'ICE_CREAM': '🍦 Ice Cream',
      'BEVERAGES': '🧃 Beverages',
      'LOVE_SPECIAL': '❤️ Love Special',
      'SNACKS': '🍟 Snacks',
      'SANDWICH': '🥪 Sandwich',
      'BURGER': '🍔 Burger',
      'TIKKA': '🍗 Tikka',
      'WRAPS': '🌯 Wraps',
      'TACO': '🌮 Taco',
      'MOMO': '🥟 Momo',
      'CHINESE_RICE_COMBO': '🍚 Chinese Combo',
      'CHINESE_NOODLES_COMBO': '🍜 Noodles Combo',
      'CHINESE_PASTA': '🍝 Pasta',
      'PIZZA': '🍕 Pizza',
      'FUSION_FOODS': '🌟 Fusion Foods',
    };

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
              final isSelected = (selectedCategory == null && cat == 'ALL') || 
                  (selectedCategory == 'Combos' && cat == 'COMBOS') || 
                  (selectedCategory == cat);
              final isComboTab = cat == 'COMBOS';
              
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
                child: ChoiceChip(
                  label: Text(categoryLabels[cat] ?? cat),
                  selected: isSelected,
                  onSelected: (val) {
                    ref.read(categoryProvider.notifier).setCategory(
                      cat == 'ALL' ? null : (cat == 'COMBOS' ? 'Combos' : cat)
                    );
                  },
                  backgroundColor: isComboTab
                      ? const Color(0xFFFF6B35).withOpacity(0.08)
                      : AppColors.surfaceDark.withOpacity(0.5),
                  selectedColor: isComboTab
                      ? const Color(0xFFFF6B35).withOpacity(0.25)
                      : AppColors.primary.withOpacity(0.2),
                  side: BorderSide(
                    color: isSelected
                        ? (isComboTab ? const Color(0xFFFF6B35) : AppColors.primary)
                        : (isComboTab ? const Color(0xFFFF6B35).withOpacity(0.3) : AppColors.borderDark),
                  ),
                  labelStyle: TextStyle(
                    color: isSelected
                        ? (isComboTab ? const Color(0xFFFF6B35) : AppColors.primaryLight)
                        : Colors.white.withOpacity(0.4),
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

  Widget _buildCombosHeader(BuildContext context) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [Color(0xFFFF6B35), Color(0xFFFF2D55)]),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.local_fire_department_rounded, color: Colors.white, size: 14),
            ),
            const SizedBox(width: 8),
            Text(
              'Combo Deals',
              style: AppTextStyles.headingMedium.copyWith(fontSize: 16, fontWeight: FontWeight.w900),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCombosHorizontalRow(BuildContext context, List<ComboMeal> combos, SeatSelectionState selection) {
    return SliverToBoxAdapter(
      child: SizedBox(
        height: 240,
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.only(left: 20, right: 8),
          itemCount: combos.length,
          itemBuilder: (context, index) {
            final combo = combos[index];
            return SizedBox(
              width: 180,
              child: Padding(
                padding: const EdgeInsets.only(right: 14, bottom: 4),
                child: ComboCard(
                  combo: combo,
                  onAddToCart: () => _addComboToCart(context, combo, selection),
                  onViewDetails: () => _showComboDetails(context, combo, selection),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildCombosGrid(BuildContext context, List<ComboMeal> combos, SeatSelectionState selection) {
    if (combos.isEmpty) {
      return SliverToBoxAdapter(
        child: Container(
          height: 300,
          alignment: Alignment.center,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.fastfood_rounded, size: 64, color: Colors.grey.withOpacity(0.2)),
              const SizedBox(height: 16),
              Text('No combo deals available at this outlet',
                  style: TextStyle(color: Colors.grey.withOpacity(0.5))),
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
            final combo = combos[index];
            return ComboCard(
              combo: combo,
              onAddToCart: () => _addComboToCart(context, combo, selection),
              onViewDetails: () => _showComboDetails(context, combo, selection),
            );
          },
          childCount: combos.length,
        ),
      ),
    );
  }

  void _addComboToCart(BuildContext context, ComboMeal combo, SeatSelectionState selection) {
    ref.read(cartProvider.notifier).addCombo(combo);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle_rounded, color: Colors.white, size: 18),
            const SizedBox(width: 8),
            Text('${combo.name} added to cart!'),
          ],
        ),
        behavior: SnackBarBehavior.floating,
        backgroundColor: const Color(0xFFFF6B35),
        duration: const Duration(seconds: 2),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  void _showComboDetails(BuildContext context, ComboMeal combo, SeatSelectionState selection) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => ComboDetailPopup(
        combo: combo,
        onAddToCart: () => _addComboToCart(context, combo, selection),
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
              isVeg: item.isVeg,
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
