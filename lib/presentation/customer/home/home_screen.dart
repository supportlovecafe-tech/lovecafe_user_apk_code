import 'dart:ui';
import '../loyalty/cinepoints_history_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/models/food_item.dart';
import '../../../core/providers/menu_provider.dart';
import '../../../core/providers/cart_provider.dart';
import '../../../core/providers/seat_selection_provider.dart';
import '../../../core/providers/theme_provider.dart';
import '../../../core/providers/category_provider.dart';
import '../../../core/providers/notification_provider.dart';
import '../../../core/providers/loyalty_provider.dart';
import '../menu/widgets/location_popup.dart';
import '../../shared/widgets/custom_bottom_nav_bar.dart';
import '../../shared/widgets/safe_network_image.dart';
import '../../shared/widgets/food_item_card.dart';
import '../../../core/providers/combo_provider.dart';
import '../../../core/providers/reorder_provider.dart';
import '../../../core/models/combo_model.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  bool _hasShownLocationPopup = false;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final selection = ref.read(seatSelectionProvider);
      if (!selection.isComplete && !_hasShownLocationPopup) {
        _hasShownLocationPopup = true;
        _showLocationSelection(context);
        return;
      }
      if (selection.isComplete && ref.read(menuProvider).items.isEmpty) {
        ref.read(menuProvider.notifier).refreshMenu(selection.hallId!);
      }
    });
  }

  void _showLocationSelection(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => LocationSelectionPopup(
        onSelected: (hallId, hallName, screenName, seat) {
          ref.read(seatSelectionProvider.notifier).updateSelection(
                hallId: hallId,
                hallName: hallName,
                screenName: screenName,
                seatLabel: seat,
              );
          ref.read(menuProvider.notifier).refreshMenu(hallId);
        },
      ),
    );
  }

  void _showNotificationSheet(BuildContext context) {
    final notifications = ref.watch(notificationProvider);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    showModalBottomSheet(
      context: context,
      backgroundColor: colorScheme.surface,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(32))),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) => Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 24),
                  decoration: BoxDecoration(
                    color: colorScheme.onSurface.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Notifications', style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w900)),
                  if (notifications.isNotEmpty)
                    TextButton(
                      onPressed: () => ref.read(notificationProvider.notifier).clearAll(),
                      child: const Text('Clear All'),
                    ),
                ],
              ),
              const SizedBox(height: 16),
              Expanded(
                child: notifications.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.notifications_off_outlined, size: 64, color: colorScheme.onSurface.withOpacity(0.1)),
                            const SizedBox(height: 16),
                            Text('No notifications yet', style: TextStyle(color: colorScheme.onSurface.withOpacity(0.4))),
                          ],
                        ),
                      )
                    : ListView.builder(
                        controller: scrollController,
                        itemCount: notifications.length,
                        itemBuilder: (context, index) {
                          final n = notifications[index];
                          return Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            decoration: BoxDecoration(
                              color: n.isRead ? Colors.transparent : colorScheme.primary.withOpacity(0.05),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: ListTile(
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              leading: Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: (n.type == 'chat' ? Colors.blue : Colors.orange).withOpacity(0.1),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  n.type == 'chat' ? Icons.chat_bubble_rounded : Icons.restaurant_rounded,
                                  size: 18,
                                  color: n.type == 'chat' ? Colors.blue : Colors.orange,
                                ),
                              ),
                              title: Text(n.title, style: theme.textTheme.titleSmall?.copyWith(fontWeight: n.isRead ? FontWeight.bold : FontWeight.w900)),
                              subtitle: Padding(
                                padding: const EdgeInsets.only(top: 4),
                                child: Text(n.body, style: theme.textTheme.bodySmall?.copyWith(color: colorScheme.onSurface.withOpacity(0.6))),
                              ),
                              trailing: Text(
                                DateFormat('HH:mm').format(n.timestamp),
                                style: theme.textTheme.labelSmall?.copyWith(color: colorScheme.onSurface.withOpacity(0.3)),
                              ),
                              onTap: () {
                                ref.read(notificationProvider.notifier).markAsRead(n.id);
                                Navigator.pop(context);
                                if (n.orderId != null) {
                                  context.push('/orders');
                                }
                              },
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final selection = ref.watch(seatSelectionProvider);
    final selectedCategory = ref.watch(categoryProvider);

    final menuState = ref.watch(menuProvider);
    final menu = menuState.items;
    var hallMenu = menu.where((m) => m.isAvailable).toList();
    
    if (selectedCategory != null) {
      final String catLower = selectedCategory.toLowerCase();
      hallMenu = hallMenu.where((item) {
        final itemCat = (item.category ?? '').toLowerCase();
        if (catLower == 'all') return true;
        if (catLower == 'popcorn') return itemCat.contains('popcorn') || itemCat.contains('corn');
        if (catLower == 'snacks') return itemCat.contains('snack') || itemCat.contains('taco') || itemCat.contains('side');
        if (catLower == 'beverages') return itemCat.contains('beverage') || itemCat.contains('drink') || itemCat.contains('soda');
        if (catLower == 'meals') return itemCat.contains('meal') || itemCat.contains('burger') || itemCat.contains('pizza');
        return itemCat.contains(catLower);
      }).toList();
    }
    if (_searchQuery.isNotEmpty) {
      hallMenu = hallMenu.where((item) {
        final query = _searchQuery.toLowerCase();
        return item.name.toLowerCase().contains(query) ||
            item.description.toLowerCase().contains(query);
      }).toList();
    }
    final reorderState = ref.watch(reorderProvider);
    final comboState = ref.watch(comboProvider);

    return Scaffold(
      backgroundColor: colorScheme.background,
      body: Stack(
        children: [
          CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              _buildAppBar(context, selection),
              _buildHeroSpotlight(context, selection),
              if (!selection.isComplete)
                _buildEmptyCinemaState(context)
              else ...[
                _buildSearchBar(context),
                _buildRewardsBanner(context, selection),
                _buildQuickCategoryStrip(context, menu, selectedCategory),
                if (reorderState.suggestions.isNotEmpty) ...[
                  _buildSectionHeader(context, 'ORDER AGAIN', 'Pick up where you left off'),
                  _buildOrderAgainSection(context, reorderState.suggestions),
                ],
                _buildSectionHeader(context, 'POPULAR', 'Trending now'),
                _buildHorizontalProducts(context, hallMenu),
                if (comboState.items.isNotEmpty) ...[
                  _buildSectionHeader(context, 'KING DEALS', 'Premium cinema combos & savings'),
                  _buildComboOffersSection(context, comboState.items),
                ],
              ],
              const SliverToBoxAdapter(child: SizedBox(height: 120)),
            ],
          ),
        ],
      ),
      bottomNavigationBar: const CustomBottomNavBar(currentIndex: 0),
    );
  }

  Widget _buildAppBar(BuildContext context, SeatSelectionState seatSelection) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final unreadCount = ref.watch(unreadNotificationsCountProvider);

    return SliverAppBar(
      pinned: true,
      floating: true,
      toolbarHeight: 90,
      backgroundColor: colorScheme.background.withOpacity(0.9),
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      centerTitle: false,
      title: GestureDetector(
        onTap: () => _showLocationSelection(context),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Image.asset(
              'assets/logo_transparent.png',
              height: 32,
              filterQuality: FilterQuality.high,
              fit: BoxFit.contain,
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Text(
                  'PREMIUM DINING',
                  style: theme.textTheme.labelSmall?.copyWith(
                    letterSpacing: 1,
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onSurface.withOpacity(0.5),
                  ),
                ),
                if (seatSelection.isComplete) ...[
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 6),
                    width: 4,
                    height: 4,
                    decoration: BoxDecoration(
                      color: colorScheme.primary,
                      shape: BoxShape.circle,
                    ),
                  ),
                  Icon(Icons.location_on_rounded, size: 12, color: colorScheme.primary),
                  const SizedBox(width: 2),
                  Flexible(
                    child: Text(
                      seatSelection.displayLabel,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: colorScheme.primary,
                        fontWeight: FontWeight.w900,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
      actions: [
        Stack(
          alignment: Alignment.center,
          children: [
            IconButton(
              icon: Icon(Icons.notifications_none_rounded, color: colorScheme.onSurface),
              onPressed: () => _showNotificationSheet(context),
            ),
            if (unreadCount > 0)
              Positioned(
                right: 8,
                top: 25,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: colorScheme.primary,
                    shape: BoxShape.circle,
                    border: Border.all(color: colorScheme.background, width: 2),
                  ),
                  constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                  child: Text(
                    unreadCount.toString(),
                    style: const TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(width: 8),
      ],
    );
  }

  Widget _buildEmptyCinemaState(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
        child: Container(
          padding: const EdgeInsets.all(40),
          decoration: BoxDecoration(
            color: colorScheme.surface,
            borderRadius: BorderRadius.circular(32),
            border: Border.all(color: colorScheme.outline.withOpacity(0.1)),
            boxShadow: [
              BoxShadow(
                color: colorScheme.onSurface.withOpacity(0.05),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: colorScheme.primary.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.location_on_rounded,
                    size: 48, color: colorScheme.primary),
              ),
              const SizedBox(height: 32),
              Text('Ready to eat?', style: theme.textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w900)),
              const SizedBox(height: 16),
              Text(
                'Select a cinema hall to explore our premium menu and order directly to your seat.',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(color: colorScheme.onSurface.withOpacity(0.6)),
              ),
              const SizedBox(height: 40),
              ElevatedButton(
                onPressed: () => _showLocationSelection(context),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                ),
                child: const Text('SELECT CINEMA HALL'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSearchBar(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
          decoration: BoxDecoration(
            color: AppColors.surfaceDark.withOpacity(0.6),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.borderDark.withOpacity(0.5)),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withOpacity(0.05),
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
                onChanged: (val) => setState(() => _searchQuery = val),
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'Search popcorn, tacos, drinks...',
                  hintStyle: TextStyle(color: Colors.white.withOpacity(0.4)),
                  border: InputBorder.none,
                  icon: Icon(Icons.search_rounded, color: AppColors.primary),
                ),
              ),
            ),
          ),
        ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.2, end: 0),
      ),
    );
  }

  Widget _buildHeroSpotlight(BuildContext context, SeatSelectionState selection) {
    return SliverToBoxAdapter(
      child: Container(
        height: 220,
        margin: const EdgeInsets.symmetric(horizontal: 24),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(32),
          color: AppColors.surfaceDark.withOpacity(0.4),
          border: Border.all(color: AppColors.primary.withOpacity(0.2)),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withOpacity(0.2),
              blurRadius: 30,
              spreadRadius: 5,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(32),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
            child: Stack(
              children: [
                Positioned.fill(
                  child: Image.network(
                    'https://images.unsplash.com/photo-1513106580091-1d82408b8cd6?w=800',
                    fit: BoxFit.cover,
                    opacity: const AlwaysStoppedAnimation(0.3),
                  ).animate(onPlay: (controller) => controller.repeat(reverse: true))
                   .scale(begin: const Offset(1.0, 1.0), end: const Offset(1.05, 1.05), duration: 10.seconds),
                ),
                Positioned(
                  right: -50,
                  top: -50,
                  child: Container(
                    width: 150,
                    height: 150,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: [
                         BoxShadow(color: AppColors.secondary.withOpacity(0.4), blurRadius: 100)
                      ]
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(32.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppColors.accent.withOpacity(0.2),
                          border: Border.all(color: AppColors.accent.withOpacity(0.5)),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text('NEON DEAL', style: TextStyle(color: AppColors.accent, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1)),
                      ).animate().shimmer(duration: 2.seconds, delay: 1.seconds),
                      const SizedBox(height: 12),
                      const Text('50% OFF\nOn Cinema Combos', style: TextStyle(color: Colors.white, fontSize: 24, height: 1.1, fontWeight: FontWeight.w900)),
                      const SizedBox(height: 8),
                      Text('Use code: GLOW50', style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 12, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ).animate().fadeIn(duration: 500.ms).scale(begin: const Offset(0.9, 0.9), end: const Offset(1.0, 1.0)),
    );
  }

  Widget _buildRewardsBanner(BuildContext context, SeatSelectionState selection) {
    final loyalty = ref.watch(loyaltyProvider);
    return SliverToBoxAdapter(
       child: Padding(
         padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
         child: GestureDetector(
           onTap: () {
             // Navigate to CinePoints History
             Navigator.push(
               context,
               MaterialPageRoute(builder: (context) => const CinePointsHistoryScreen()),
             );
           },
           child: Container(
             padding: const EdgeInsets.all(16),
             decoration: BoxDecoration(
               color: AppColors.secondary.withOpacity(0.1),
               borderRadius: BorderRadius.circular(20),
               border: Border.all(color: AppColors.secondary.withOpacity(0.3)),
               boxShadow: [
                 BoxShadow(color: AppColors.secondary.withOpacity(0.1), blurRadius: 15),
               ],
             ),
             child: Row(
               children: [
                 Icon(Icons.stars_rounded, color: AppColors.secondary, size: 28).animate(onPlay: (controller) => controller.repeat(reverse: true)).scale(duration: 1.seconds, begin: const Offset(1, 1), end: const Offset(1.1, 1.1)),
                 const SizedBox(width: 12),
                 Expanded(
                   child: Column(
                     crossAxisAlignment: CrossAxisAlignment.start,
                     children: [
                       const Text('CinePoints', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 12, color: Colors.white)),
                       Text('You have ${loyalty.availablePoints} points to redeem', style: TextStyle(fontSize: 10, color: Colors.white.withOpacity(0.5))),
                     ],
                   ),
                 ),
                 Icon(Icons.arrow_forward_ios_rounded, size: 12, color: AppColors.secondary.withOpacity(0.5)),
               ],
             ),
           ),
         ),
       ).animate().fadeIn(delay: 200.ms),
    );
  }

  Widget _buildQuickCategoryStrip(BuildContext context, List<FoodItem> items, String? current) {
    final categories = ['All', 'Popcorn', 'Snacks', 'Beverages', 'Meals'];
    return SliverToBoxAdapter(
      child: SizedBox(
        height: 60,
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: categories.length,
          itemBuilder: (context, index) {
            final cat = categories[index];
            final isSelected = (current ?? 'All') == cat;
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: ChoiceChip(
                label: Text(cat),
                selected: isSelected,
                onSelected: (val) => ref.read(categoryProvider.notifier).state = cat,
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
      ).animate().slideX(begin: 0.2, end: 0, duration: 400.ms),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title, String subtitle) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 32, 24, 16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18, letterSpacing: 2, color: AppColors.accent)),
                Text(subtitle, style: TextStyle(fontSize: 12, color: Colors.white.withOpacity(0.4))),
              ],
            ),
            const Text('View All', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 12)),
          ],
        ),
      ),
    );
  }

  Widget _buildHorizontalProducts(BuildContext context, List<FoodItem> items) {
    if (items.isEmpty) return const SliverToBoxAdapter(child: SizedBox());
    return SliverToBoxAdapter(
      child: SizedBox(
        height: 280,
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: items.length > 5 ? 5 : items.length,
          itemBuilder: (context, index) {
             final item = items[index];
             return Container(
               width: 200,
               margin: const EdgeInsets.symmetric(horizontal: 8),
               child: FoodItemCard(
                 id: item.id,
                 name: item.name,
                 imageUrl: item.imageUrl,
                 price: item.price,
                 onTap: () => context.push('/food-detail', extra: item),
                 onAdd: () {
                   ref.read(cartProvider.notifier).validateAndAddItem(item, ref.read(seatSelectionProvider).hallId);
                   ScaffoldMessenger.of(context).showSnackBar(
                     SnackBar(
                       content: Text('${item.name} added to cart'),
                       behavior: SnackBarBehavior.floating,
                       duration: const Duration(seconds: 1),
                     ),
                   );
                 },
               ),
             );
          },
        ),
      ),
    );
  }

  Widget _buildOrderAgainSection(BuildContext context, List<ReorderSuggestion> suggestions) {
    return SliverToBoxAdapter(
      child: SizedBox(
        height: 280,
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: suggestions.length,
          itemBuilder: (context, index) {
            final suggestion = suggestions[index];
            final item = suggestion.toFoodItem();
            return Container(
              width: 200,
              margin: const EdgeInsets.symmetric(horizontal: 8),
              child: FoodItemCard(
                id: item.id,
                name: item.name,
                imageUrl: item.imageUrl,
                price: item.price,
                onTap: () => context.push('/food-detail', extra: item),
                onAdd: () {
                  ref.read(cartProvider.notifier).validateAndAddItem(item, ref.read(seatSelectionProvider).hallId);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('${item.name} added to cart'),
                      behavior: SnackBarBehavior.floating,
                      duration: const Duration(seconds: 1),
                    ),
                  );
                },
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildComboOffersSection(BuildContext context, List<ComboMeal> combos) {
    return SliverToBoxAdapter(
      child: SizedBox(
        height: 280,
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: combos.length,
          itemBuilder: (context, index) {
            final combo = combos[index];
            // Map ComboMeal to a format FoodItemCard can use for display
            return Container(
              width: 200,
              margin: const EdgeInsets.symmetric(horizontal: 8),
              child: FoodItemCard(
                id: combo.id,
                name: combo.name,
                imageUrl: combo.imageUrl,
                price: combo.price,
                originalPrice: combo.originalPrice,
                savingsLabel: combo.savingsLabel,
                onTap: () {
                  // Push to detail with a dummy food item created from combo
                  final foodItem = FoodItem(
                    id: combo.id,
                    name: combo.name,
                    description: combo.description,
                    imageUrl: combo.imageUrl,
                    price: combo.price,
                    category: combo.category,
                  );
                  context.push('/food-detail', extra: foodItem);
                },
                onAdd: () {
                  final foodItem = FoodItem(
                    id: combo.id,
                    name: combo.name,
                    description: combo.description,
                    imageUrl: combo.imageUrl,
                    price: combo.price,
                    category: combo.category,
                  );
                  ref.read(cartProvider.notifier).validateAndAddItem(foodItem, ref.read(seatSelectionProvider).hallId);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('${combo.name} added to cart'),
                      behavior: SnackBarBehavior.floating,
                      duration: const Duration(seconds: 1),
                    ),
                  );
                },
              ),
            );
          },
        ),
      ),
    );
  }

  // _buildFoodCard removed as FoodItemCard is now used directly
}
