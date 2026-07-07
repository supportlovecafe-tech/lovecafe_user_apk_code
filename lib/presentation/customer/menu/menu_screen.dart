import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/constants/app_shadows.dart';
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
    
    final availableCategoryNames = menuState.items.map((e) => e.category?.toUpperCase() ?? '').toSet();
    final hasCombos = comboState.items.isNotEmpty;

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
    ].where((cat) {
      if (cat == 'ALL') return true;
      if (cat == 'COMBOS') return hasCombos;
      return availableCategoryNames.contains(cat);
    }).toList();
    
    final showingCombos = selectedCategory == 'Combos';
    final foods = showingCombos ? <FoodItem>[] : getFilteredFoods(menuState.items, selectedCategory);
    final combos = showingCombos || selectedCategory == null
        ? getFilteredCombos(comboState.items, selectedCategory)
        : <ComboMeal>[];

    return Scaffold(
      backgroundColor: AppColors.bg,
      extendBody: true,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            _buildTopBar(context, selection),
            Expanded(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSidebar(context, selectedCategory, flatCategories),
                  Expanded(
                    child: CustomScrollView(
                      physics: const BouncingScrollPhysics(),
                      slivers: [
                        _buildSearchBar(context),
                        _buildOffersCarousel(context, ref),
                        const ReorderSection(),
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
                              : _buildList(context, foods, selection),
                        ],
                        const SliverToBoxAdapter(child: SizedBox(height: 120)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: const CustomBottomNavBar(currentIndex: 1),
    );
  }

  Widget _buildTopBar(BuildContext context, SeatSelectionState selection) {
    return Container(
      color: AppColors.bg,
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
      child: Row(
        children: [
          IconButton(
            onPressed: () => context.go('/home'),
            icon: const Icon(Icons.arrow_back_ios_new_rounded,
                color: AppColors.textPrimary, size: 18),
          ),
          Expanded(
            child: GestureDetector(
              onTap: _showLocationSelection,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Premium Menu',
                    style: AppTextStyles.headingSmall
                        .copyWith(color: AppColors.primary),
                  ),
                  if (selection.isComplete)
                    Row(
                      children: [
                        Icon(Icons.location_on_rounded,
                            size: 11, color: AppColors.textDisabled),
                        const SizedBox(width: 3),
                        Text(
                          selection.displayLabel,
                          style: AppTextStyles.labelSmall,
                        ),
                        Icon(Icons.keyboard_arrow_down_rounded,
                            size: 14, color: AppColors.textDisabled),
                      ],
                    ),
                ],
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.search_rounded,
                color: AppColors.textPrimary, size: 22),
            onPressed: () {},
          ),
          const SizedBox(width: 4),
        ],
      ),
    );
  }

  Widget _buildSearchBar(BuildContext context) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
        child: Row(
          children: [
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: AppColors.surfaceElevated.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(100),
                  border: Border.all(color: AppColors.glassBorder, width: 1),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.2),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: TextField(
                  onChanged: (v) => setState(() => _searchQuery = v),
                  style: AppTextStyles.bodyMedium
                      .copyWith(color: AppColors.textPrimary),
                  cursorColor: AppColors.primary,
                  decoration: InputDecoration(
                    hintText: 'Search deliciousness...',
                    hintStyle: AppTextStyles.bodyMedium
                        .copyWith(color: AppColors.textDisabled),
                    prefixIcon: Icon(Icons.search_rounded,
                        color: AppColors.textDisabled, size: 20),
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    contentPadding:
                        const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            GestureDetector(
              onTap: () => setState(() => _showVegOnly = !_showVegOnly),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: _showVegOnly
                      ? AppColors.success.withValues(alpha: 0.12)
                      : AppColors.surface,
                  borderRadius: BorderRadius.circular(100),
                  border: Border.all(
                    color: _showVegOnly
                        ? AppColors.success
                        : Colors.white.withValues(alpha: 0.06),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      _showVegOnly ? Icons.eco_rounded : Icons.eco_outlined,
                      size: 16,
                      color: _showVegOnly
                          ? AppColors.success
                          : AppColors.textDisabled,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Veg',
                      style: AppTextStyles.labelSmall.copyWith(
                        fontWeight: FontWeight.w700,
                        color: _showVegOnly
                            ? AppColors.success
                            : AppColors.textDisabled,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ).animate().fadeIn(duration: 300.ms),
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
                height: 130,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  itemCount: offers.length,
                  itemBuilder: (context, index) {
                    final offer = offers[index];
                    final bannerUrl = offer['banner_url'] as String?;
                    final hasPoster = bannerUrl != null && bannerUrl.isNotEmpty;

                    return GestureDetector(
                      onTap: () => _showOfferItemsShelf(context, ref, offer, selection),
                      child: Container(
                        width: 220,
                        margin: const EdgeInsets.only(right: 14, bottom: 8, top: 4),
                        decoration: BoxDecoration(
                          gradient: hasPoster
                              ? null
                              : LinearGradient(
                                  colors: [AppColors.primary.withValues(alpha: 0.2), AppColors.secondary.withValues(alpha: 0.1)],
                                ),
                          color: hasPoster ? Colors.black : null,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: hasPoster
                                ? Colors.white.withValues(alpha: 0.08)
                                : AppColors.primary.withValues(alpha: 0.3),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: hasPoster
                                  ? Colors.black.withValues(alpha: 0.3)
                                  : AppColors.primary.withValues(alpha: 0.05),
                              blurRadius: 12,
                            )
                          ],
                        ),
                        clipBehavior: Clip.hardEdge,
                        child: hasPoster
                            ? _buildPosterCard(offer, bannerUrl)
                            : _buildGradientCard(offer),
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

  /// Full-bleed poster image card with gradient overlay text.
  Widget _buildPosterCard(Map<String, dynamic> offer, String bannerUrl) {
    return Stack(
      fit: StackFit.expand,
      children: [
        // Full-bleed poster image
        SafeNetworkImage(
          imageUrl: bannerUrl,
          width: double.infinity,
          height: double.infinity,
          fit: BoxFit.cover,
          borderRadius: BorderRadius.zero,
        ),
        // Dark gradient overlay from bottom (ensures text is readable)
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.transparent,
                Colors.black.withValues(alpha: 0.45),
                Colors.black.withValues(alpha: 0.85),
              ],
              stops: const [0.0, 0.4, 1.0],
            ),
          ),
        ),
        // Text overlay at bottom
        Positioned(
          left: 14,
          right: 14,
          bottom: 12,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.accent.withValues(alpha: 0.85),
                  borderRadius: BorderRadius.circular(5),
                ),
                child: Text(
                  (offer['category'] as String).replaceAll('_', ' '),
                  style: const TextStyle(
                    color: Colors.black,
                    fontSize: 8,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                offer['title'] as String,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w900,
                  shadows: [Shadow(color: Colors.black, blurRadius: 8)],
                ),
              ),
              if ((offer['description'] as String?)?.isNotEmpty ?? false)
                Text(
                  offer['description'] as String,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.7),
                    fontSize: 10,
                    shadows: const [Shadow(color: Colors.black, blurRadius: 6)],
                  ),
                ),
            ],
          ),
        ),
        // Tap arrow indicator top-right
        Positioned(
          top: 10,
          right: 10,
          child: Container(
            padding: const EdgeInsets.all(5),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.4),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
            ),
            child: const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white, size: 11),
          ),
        ),
      ],
    );
  }

  /// Original gradient text card (used when no poster is uploaded).
  Widget _buildGradientCard(Map<String, dynamic> offer) {
    return Padding(
      padding: const EdgeInsets.all(16),
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
                    color: AppColors.accent.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: AppColors.accent.withValues(alpha: 0.5)),
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
                  style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 10),
                ),
              ],
            ),
          ),
          const Icon(Icons.arrow_forward_ios_rounded, color: AppColors.primaryLight, size: 16),
        ],
      ),
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
          border: Border.all(color: colorScheme.outline.withValues(alpha: 0.1)),
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
                  color: Colors.white.withValues(alpha: 0.2),
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
                    color: Colors.pink.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.pink.withValues(alpha: 0.4)),
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
                style: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: 12, height: 1.4),
              ),
            ],
            const SizedBox(height: 24),
            Text(
              'PROMOTIONAL PRODUCTS',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w900,
                color: Colors.white.withValues(alpha: 0.4),
                letterSpacing: 1.5,
              ),
            ),
            const SizedBox(height: 12),
            if (targetItems.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 24),
                child: Text(
                  'No items currently mapped to this promotion.',
                  style: TextStyle(color: Colors.white.withValues(alpha: 0.4), fontSize: 12, fontStyle: FontStyle.italic),
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
                    final offerItemsList = offer['offer_items'] as List? ?? [];
                    final matchedItem = offerItemsList.firstWhere(
                      (oi) => oi['food_item_id'].toString() == item.id,
                      orElse: () => null,
                    );
                    
                    final isUnlimitedOffer = offer['category'] == 'UNLIMITED';
                    
                    // Determine the effective promo price for this item.
                    // Priority: per-item custom_price > global promo_price
                    double? promoPrice;
                    if (matchedItem != null && matchedItem['custom_price'] != null) {
                      promoPrice = (matchedItem['custom_price'] as num).toDouble();
                    } else if (offer['category'] == 'UNLIMITED' || 
                               offer['category'] == 'OFFER_OF_THE_DAY' || 
                               offer['category'] == 'OFFER_OF_THE_WEEK' || 
                               offer['category'] == 'OFFER_OF_THE_FESTIVAL' || 
                               offer['category'] == 'OFFER_OF_THE_FILM') {
                      promoPrice = (offer['promo_price'] as num?)?.toDouble();
                    }
                    
                    // For UNLIMITED, the promo price is ALWAYS shown because it is
                    // the special refill price (not a discount — it may be higher).
                    final showPromoPrice = promoPrice != null && 
                        (isUnlimitedOffer || promoPrice < item.price);

                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.02),
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
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
                                Row(
                                  children: [
                                    if (showPromoPrice) ...[
                                      Text(
                                        '₹${promoPrice.toInt()}',
                                        style: const TextStyle(
                                          color: AppColors.primaryLight,
                                          fontWeight: FontWeight.w900,
                                          fontSize: 14,
                                        ),
                                      ),
                                      const SizedBox(width: 6),
                                      // For UNLIMITED, show original price as reference
                                      // (it's not a strikethrough discount, just context)
                                      if (!isUnlimitedOffer)
                                        Text(
                                          '₹${item.price.toInt()}',
                                          style: TextStyle(
                                            color: Colors.white.withValues(alpha: 0.4),
                                            decoration: TextDecoration.lineThrough,
                                            fontSize: 11,
                                          ),
                                        ),
                                      if (isUnlimitedOffer)
                                        Container(
                                          margin: const EdgeInsets.only(left: 4),
                                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: Colors.orange.withValues(alpha: 0.15),
                                            borderRadius: BorderRadius.circular(6),
                                            border: Border.all(color: Colors.orange.withValues(alpha: 0.4)),
                                          ),
                                          child: const Text(
                                            '∞ Unlimited',
                                            style: TextStyle(
                                              color: Colors.orange,
                                              fontSize: 9,
                                              fontWeight: FontWeight.w900,
                                            ),
                                          ),
                                        ),
                                    ] else ...[
                                      Text(
                                        '₹${item.price.toInt()}',
                                        style: const TextStyle(
                                          color: AppColors.primaryLight,
                                          fontWeight: FontWeight.w900,
                                          fontSize: 14,
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ],
                            ),
                          ),
                          ElevatedButton(
                            onPressed: () {
                              // For unlimited offers, always use the promo price
                              // (per-item custom_price if available, else global promo_price)
                              final itemToAdd = (isUnlimitedOffer && promoPrice != null) 
                                ? item.copyWith(
                                    name: '${item.name} (Unlimited)', 
                                    price: promoPrice
                                  ) 
                                : item;

                              ref.read(cartProvider.notifier).validateAndAddItem(
                                itemToAdd, 
                                selection.hallId,
                                offerId: offer['id'] as String,
                              );
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

  Widget _buildSidebar(BuildContext context, String? selectedCategory, List<String> categories) {
    const Map<String, String> categoryLabels = {
      'ALL': 'All',
      'COMBOS': 'Combos',
      'POPCORN': 'Popcorn',
      'LASSI': 'Lassi',
      'MILKSHAKE': 'Milkshake',
      'ICE_CREAM': 'Ice Cream',
      'BEVERAGES': 'Beverages',
      'LOVE_SPECIAL': 'Love Special',
      'SNACKS': 'Snacks',
      'SANDWICH': 'Sandwich',
      'BURGER': 'Burger',
      'TIKKA': 'Tikka',
      'WRAPS': 'Wraps',
      'TACO': 'Taco',
      'MOMO': 'Momo',
      'CHINESE_RICE_COMBO': 'Chinese Combo',
      'CHINESE_NOODLES_COMBO': 'Noodles Combo',
      'CHINESE_PASTA': 'Pasta',
      'PIZZA': 'Pizza',
      'FUSION_FOODS': 'Fusion Foods',
    };
    
    const Map<String, String> categoryEmojis = {
      'ALL': '🍛',
      'COMBOS': '🔥',
      'POPCORN': '🍿',
      'LASSI': '🥛',
      'MILKSHAKE': '🥤',
      'ICE_CREAM': '🍦',
      'BEVERAGES': '🧃',
      'LOVE_SPECIAL': '❤️',
      'SNACKS': '🍟',
      'SANDWICH': '🥪',
      'BURGER': '🍔',
      'TIKKA': '🍗',
      'WRAPS': '🌯',
      'TACO': '🌮',
      'MOMO': '🥟',
      'CHINESE_RICE_COMBO': '🍚',
      'CHINESE_NOODLES_COMBO': '🍜',
      'CHINESE_PASTA': '🍝',
      'PIZZA': '🍕',
      'FUSION_FOODS': '🌟',
    };

    const Map<String, String> categoryImages = {
      'COMBOS': 'assets/images/categories/cat_combos.png',
      'POPCORN': 'assets/images/categories/cat_popcorn.png',
      'BEVERAGES': 'assets/images/categories/cat_beverage.png',
      'SNACKS': 'assets/images/categories/cat_snacks.png',
      'PIZZA': 'assets/images/categories/cat_pizza.png',
      'BURGER': 'assets/images/categories/cat_burger.png',
      'LASSI': 'assets/images/categories/cat_lassi.png',
      'ICE_CREAM': 'assets/images/categories/cat_ice_cream.png',
      'MILKSHAKE': 'assets/images/categories/cat_milkshake.png',
      'LOVE_SPECIAL': 'assets/images/categories/cat_love_special.png',
      'SANDWICH': 'assets/images/categories/cat_sandwich.png',
      'TIKKA': 'assets/images/categories/cat_tikka.png',
      'WRAPS': 'assets/images/categories/cat_wraps.png',
      'TACO': 'assets/images/categories/cat_taco.png',
      'MOMO': 'assets/images/categories/cat_momo.png',
      'CHINESE_RICE_COMBO': 'assets/images/categories/cat_chinese_rice_combo.png',
      'CHINESE_NOODLES_COMBO': 'assets/images/categories/cat_chinese_rice_combo.png',
      'CHINESE_PASTA': 'assets/images/categories/cat_pizza.png',
      'FUSION_FOODS': 'assets/images/categories/cat_fusion.png',
    };

    return Container(
      width: 90,
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated.withValues(alpha: 0.3),
        border: Border(right: BorderSide(color: AppColors.glassBorder, width: 1)),
      ),
      child: ListView.builder(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.only(bottom: 120),
        itemCount: categories.length,
        itemBuilder: (context, index) {
          final cat = categories[index];
          final isSelected = (selectedCategory == null && cat == 'ALL') ||
              (selectedCategory == 'Combos' && cat == 'COMBOS') ||
              (selectedCategory == cat);
          final isComboTab = cat == 'COMBOS';

          return GestureDetector(
            onTap: () {
              ref.read(categoryProvider.notifier).setCategory(
                  cat == 'ALL'
                      ? null
                      : (cat == 'COMBOS' ? 'Combos' : cat));
            },
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 4),
              decoration: BoxDecoration(
                color: isSelected ? AppColors.surfaceElevated.withValues(alpha: 0.8) : Colors.transparent,
                border: Border(
                  left: BorderSide(
                    color: isSelected 
                      ? (isComboTab ? const Color(0xFFFF6B35) : AppColors.primary)
                      : Colors.transparent,
                    width: 4,
                  ),
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: isSelected 
                        ? (isComboTab ? const Color(0xFFFF6B35).withValues(alpha: 0.2) : AppColors.primary.withValues(alpha: 0.2)) 
                        : AppColors.surface,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isSelected 
                          ? (isComboTab ? const Color(0xFFFF6B35).withValues(alpha: 0.5) : AppColors.primary.withValues(alpha: 0.5)) 
                          : AppColors.glassBorder,
                      ),
                      boxShadow: isSelected
                        ? [
                            BoxShadow(
                              color: (isComboTab ? const Color(0xFFFF6B35) : AppColors.primary).withValues(alpha: 0.2),
                              blurRadius: 10,
                            )
                          ]
                        : [],
                    ),
                    alignment: Alignment.center,
                    child: categoryImages.containsKey(cat)
                        ? ClipOval(
                            child: Image.asset(
                              categoryImages[cat]!,
                              width: 36,
                              height: 36,
                              fit: BoxFit.cover,
                            ),
                          )
                        : Text(
                            categoryEmojis[cat] ?? '🍽️',
                            style: const TextStyle(fontSize: 22),
                          ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    categoryLabels[cat] ?? cat,
                    textAlign: TextAlign.center,
                    style: AppTextStyles.labelSmall.copyWith(
                      color: isSelected 
                        ? (isComboTab ? const Color(0xFFFF6B35) : AppColors.primary) 
                        : AppColors.textSecondary,
                      fontWeight: isSelected ? FontWeight.w900 : FontWeight.w500,
                      fontSize: 10,
                      height: 1.2,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
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
              Icon(Icons.fastfood_rounded, size: 64, color: Colors.grey.withValues(alpha: 0.2)),
              const SizedBox(height: 16),
              Text('No combo deals available at this outlet',
                  style: TextStyle(color: Colors.grey.withValues(alpha: 0.5))),
            ],
          ),
        ),
      );
    }

    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      sliver: SliverGrid(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisSpacing: 16,
          crossAxisSpacing: 16,
          childAspectRatio: 0.65,
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

  Widget _buildList(BuildContext context, List<FoodItem> foods, SeatSelectionState selection) {
    if (foods.isEmpty) {
      return SliverToBoxAdapter(
        child: SizedBox(
          height: 300,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.restaurant_menu_outlined,
                  size: 56, color: AppColors.textDisabled),
              const SizedBox(height: 16),
              Text('No items found in this category',
                  style: AppTextStyles.bodyMedium),
            ],
          ),
        ),
      );
    }

    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      sliver: SliverGrid(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisSpacing: 16,
          crossAxisSpacing: 16,
          childAspectRatio: 0.65,
        ),
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            final item = foods[index];
            return FoodItemCard(
              id: item.id,
              name: item.name,
              description: item.description,
              imageUrl: item.imageUrl,
              price: item.price,
              isVeg: item.isVeg,
              mode: FoodCardMode.compact,
              onAdd: () {
                ref.read(cartProvider.notifier).validateAndAddItem(
                    item, selection.hallId);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('${item.name} added!'),
                    duration: const Duration(seconds: 1),
                  ),
                );
              },
              onTap: () => context.push('/food-detail', extra: item),
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
