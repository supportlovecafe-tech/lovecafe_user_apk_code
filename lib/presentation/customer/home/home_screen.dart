import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
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
                _buildSectionHeader(context, 'POPULAR', 'Trending now'),
                _buildHorizontalProducts(context, hallMenu),
                _buildSectionHeader(context, 'KING DEALS', 'Premium cinema combos'),
                _buildComboCarousel(context, hallMenu),
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
            Text(
              'CineSeat Food',
              style: theme.textTheme.headlineSmall?.copyWith(
                color: colorScheme.primary,
                fontWeight: FontWeight.w900,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 2),
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
            color: colorScheme.surface,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 15,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: TextField(
            onChanged: (val) => setState(() => _searchQuery = val),
            decoration: InputDecoration(
              hintText: 'Search popcorn, tacos, drinks...',
              hintStyle: TextStyle(color: colorScheme.onSurface.withOpacity(0.3)),
              border: InputBorder.none,
              icon: Icon(Icons.search_rounded, color: colorScheme.primary),
            ),
          ),
        ),
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
          gradient: LinearGradient(
            colors: [Colors.black, Colors.grey[900]!],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Stack(
          children: [
             Positioned.fill(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(32),
                  child: Image.network(
                    'https://images.unsplash.com/photo-1513106580091-1d82408b8cd6?w=800',
                    fit: BoxFit.cover,
                    opacity: const AlwaysStoppedAnimation(0.4),
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
                       color: Colors.orange,
                       borderRadius: BorderRadius.circular(20),
                     ),
                     child: const Text('LIMITED OFFER', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                   ),
                   const SizedBox(height: 12),
                   const Text('50% OFF\non Large Combos', style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w900)),
                   const SizedBox(height: 8),
                   const Text('Use code: CINEFEAST', style: TextStyle(color: Colors.white70, fontSize: 12)),
                 ],
               ),
             ),
          ],
        ),
      ),
    );
  }

  Widget _buildRewardsBanner(BuildContext context, SeatSelectionState selection) {
    final loyalty = ref.watch(loyaltyProvider);
    return SliverToBoxAdapter(
       child: Padding(
         padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
         child: Container(
           padding: const EdgeInsets.all(16),
           decoration: BoxDecoration(
             color: Colors.purple.withOpacity(0.1),
             borderRadius: BorderRadius.circular(20),
             border: Border.all(color: Colors.purple.withOpacity(0.2)),
           ),
           child: Row(
             children: [
               const Icon(Icons.stars_rounded, color: Colors.purple),
               const SizedBox(width: 12),
               Expanded(
                 child: Column(
                   crossAxisAlignment: CrossAxisAlignment.start,
                   children: [
                     const Text('Loyalty Points', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                     Text('You have ${loyalty.availablePoints} points to redeem', style: TextStyle(fontSize: 10, color: Colors.white.withOpacity(0.6))),
                   ],
                 ),
               ),
               Icon(Icons.arrow_forward_ios_rounded, size: 12, color: Colors.white.withOpacity(0.4)),
             ],
           ),
         ),
       ),
    );
  }

  Widget _buildQuickCategoryStrip(BuildContext context, List<FoodItem> items, String? current) {
    final categories = ['All', 'Popcorn', 'Snacks', 'Beverages', 'Meals'];
    return SliverToBoxAdapter(
      child: SizedBox(
        height: 60,
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
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
                backgroundColor: Colors.transparent,
                selectedColor: AppColors.primary,
                labelStyle: TextStyle(
                  color: isSelected ? Colors.white : Colors.grey,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            );
          },
        ),
      ),
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
                Text(title, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18, letterSpacing: 1)),
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
               child: _buildFoodCard(context, item),
             );
          },
        ),
      ),
    );
  }

  Widget _buildComboCarousel(BuildContext context, List<FoodItem> items) {
    final combos = items.where((i) => i.category.toLowerCase().contains('combo') || i.category.toLowerCase().contains('meal')).toList();
    if (combos.isEmpty) return const SliverToBoxAdapter(child: SizedBox());
    
    return SliverToBoxAdapter(
      child: SizedBox(
        height: 180,
        child: PageView.builder(
          controller: PageController(viewportFraction: 0.85),
          itemCount: combos.length,
          itemBuilder: (context, index) {
            final combo = combos[index];
            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                color: Colors.white,
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
              ),
              child: Row(
                children: [
                   ClipRRect(
                     borderRadius: const BorderRadius.horizontal(left: Radius.circular(24)),
                     child: SafeNetworkImage(imageUrl: combo.imageUrl, width: 120, height: 180, fit: BoxFit.cover),
                   ),
                   Expanded(
                     child: Padding(
                       padding: const EdgeInsets.all(16.0),
                       child: Column(
                         crossAxisAlignment: CrossAxisAlignment.start,
                         mainAxisAlignment: MainAxisAlignment.center,
                         children: [
                           Text(combo.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                           const SizedBox(height: 4),
                           Text(combo.description, maxLines: 2, style: TextStyle(fontSize: 10, color: Colors.white.withOpacity(0.5))),
                           const Spacer(),
                           Row(
                             mainAxisAlignment: MainAxisAlignment.spaceBetween,
                             children: [
                               Text('₹${combo.price}', style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w900)),
                               IconButton(
                                 onPressed: () => ref.read(cartProvider.notifier).addItem(combo),
                                 icon: const Icon(Icons.add_circle, color: AppColors.primary),
                               ),
                             ],
                           ),
                         ],
                       ),
                     ),
                   ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildFoodCard(BuildContext context, FoodItem item) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
           Expanded(
             child: Stack(
               children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                    child: SafeNetworkImage(imageUrl: item.imageUrl, width: double.infinity, fit: BoxFit.cover),
                  ),
                  Positioned(
                    top: 12,
                    right: 12,
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                      child: const Icon(Icons.favorite_border, size: 16, color: Colors.grey),
                    ),
                  ),
               ],
             ),
           ),
           Padding(
             padding: const EdgeInsets.all(16.0),
             child: Column(
               crossAxisAlignment: CrossAxisAlignment.start,
               children: [
                 Text(item.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                 const SizedBox(height: 4),
                 Text('₹${item.price}', style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w900, fontSize: 16)),
                 const SizedBox(height: 12),
                 ElevatedButton(
                   onPressed: () => ref.read(cartProvider.notifier).addItem(item),
                   style: ElevatedButton.styleFrom(
                     minimumSize: const Size.fromHeight(40),
                     shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                   ),
                   child: const Text('ADD TO CART', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                 ),
               ],
             ),
           ),
        ],
      ),
    );
  }
}
