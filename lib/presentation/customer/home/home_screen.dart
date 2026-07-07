import 'dart:ui';
import 'dart:async';
import '../loyalty/cinepoints_history_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/offers_provider.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/constants/app_gradients.dart';
import '../../../core/constants/app_shadows.dart';
import '../../../core/models/food_item.dart';
import '../../../core/providers/menu_provider.dart';
import '../../../core/providers/cart_provider.dart';
import '../../../core/providers/seat_selection_provider.dart';
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
  late PageController _pageController;
  Timer? _carouselTimer;
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: 0, viewportFraction: 0.92);
    _startCarouselTimer();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final selection = ref.read(seatSelectionProvider);
      if (!selection.isComplete && !_hasShownLocationPopup) {
        _hasShownLocationPopup = true;
        _showLocationSelection(context);
        return;
      }
      if (selection.isComplete) {
        ref.read(menuProvider.notifier).refreshMenu(selection.hallId!);
      }
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    _carouselTimer?.cancel();
    super.dispose();
  }

  void _startCarouselTimer() {
    _carouselTimer?.cancel();
    _carouselTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      final offers = ref.read(offersProvider).value ?? [];
      if (offers.length > 1) {
        _currentPage = (_currentPage + 1) % offers.length;
        if (_pageController.hasClients) {
          _pageController.animateToPage(
            _currentPage,
            duration: const Duration(milliseconds: 800),
            curve: Curves.easeInOut,
          );
        }
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
    final notifications = ref.read(notificationProvider);
    final theme = Theme.of(context);

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) => ClipRRect(
          borderRadius:
              const BorderRadius.vertical(top: Radius.circular(28)),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
            child: Container(
              color: AppColors.surface.withValues(alpha: 0.92),
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      margin: const EdgeInsets.only(bottom: 24),
                      decoration: BoxDecoration(
                        color: AppColors.borderStrong,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Notifications',
                          style: AppTextStyles.headingSmall),
                      if (notifications.isNotEmpty)
                        TextButton(
                          onPressed: () =>
                              ref.read(notificationProvider.notifier).clearAll(),
                          child: Text('Clear All',
                              style: AppTextStyles.labelMedium.copyWith(
                                  color: AppColors.primary)),
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
                                Icon(Icons.notifications_off_outlined,
                                    size: 56,
                                    color: AppColors.textDisabled),
                                const SizedBox(height: 12),
                                Text('No notifications yet',
                                    style: AppTextStyles.bodyMedium),
                              ],
                            ),
                          )
                        : ListView.separated(
                            controller: scrollController,
                            itemCount: notifications.length,
                            separatorBuilder: (_, __) =>
                                const SizedBox(height: 8),
                            itemBuilder: (context, index) {
                              final n = notifications[index];
                              return Container(
                                padding: const EdgeInsets.all(14),
                                decoration: BoxDecoration(
                                  color: n.isRead
                                      ? AppColors.surfaceElevated
                                      : AppColors.primary.withValues(alpha: 0.06),
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: n.isRead
                                        ? Colors.white.withValues(alpha: 0.05)
                                        : AppColors.primary.withValues(alpha: 0.2),
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(9),
                                      decoration: BoxDecoration(
                                        color: (n.type == 'chat'
                                                ? AppColors.secondary
                                                : AppColors.warning)
                                            .withValues(alpha: 0.12),
                                        shape: BoxShape.circle,
                                      ),
                                      child: Icon(
                                        n.type == 'chat'
                                            ? Icons.chat_bubble_outline_rounded
                                            : Icons.restaurant_outlined,
                                        size: 16,
                                        color: n.type == 'chat'
                                            ? AppColors.secondary
                                            : AppColors.warning,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(n.title,
                                              style: AppTextStyles.titleSmall),
                                          const SizedBox(height: 2),
                                          Text(n.body,
                                              style: AppTextStyles.bodySmall,
                                              maxLines: 2),
                                        ],
                                      ),
                                    ),
                                    Text(
                                      DateFormat('HH:mm').format(n.timestamp),
                                      style: AppTextStyles.labelSmall,
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
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
        if (catLower == 'popcorn')
          return itemCat.contains('popcorn') || itemCat.contains('corn');
        if (catLower == 'snacks')
          return itemCat.contains('snack') ||
              itemCat.contains('taco') ||
              itemCat.contains('side');
        if (catLower == 'beverages')
          return itemCat.contains('beverage') ||
              itemCat.contains('drink') ||
              itemCat.contains('soda');
        if (catLower == 'meals')
          return itemCat.contains('meal') ||
              itemCat.contains('burger') ||
              itemCat.contains('pizza');
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
    final activeSuggestions = reorderState.suggestions.map((suggestion) {
      try {
        return menu.firstWhere(
            (menuItem) =>
                menuItem.id == suggestion.foodId && menuItem.isAvailable);
      } catch (_) {
        return null;
      }
    }).whereType<FoodItem>().toList();

    return Scaffold(
      backgroundColor: AppColors.bg,
      extendBody: true,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          _buildAppBar(context, selection),
          ref.watch(offersProvider).when(
                data: (offersList) =>
                    _buildHeroCarousel(context, offersList),
                loading: () => const SliverToBoxAdapter(
                  child: SizedBox(
                      height: 220, child: Center(child: CircularProgressIndicator())),
                ),
                error: (_, __) => _buildHeroCarousel(context, const []),
              ),
          if (!selection.isComplete)
            _buildEmptyCinemaState(context)
          else ...[
            _buildSearchBar(context),
            _buildRewardsBanner(context),
            _buildSectionHeader(context, 'Our Menu', 'Explore delicious categories', showViewAll: false),
            _buildOurMenuGrid(context, menuState, comboState),
            if (activeSuggestions.isNotEmpty) ...[
              _buildSectionHeader(
                  context, 'Order Again', 'Pick up where you left off',
                  showViewAll: false),
              _buildHorizontalScroll(context, activeSuggestions),
            ],
            _buildSectionHeader(context, 'Popular Right Now',
                'Trending across all screens'),
            _buildHorizontalScroll(context, hallMenu, maxCount: 8),
            if (comboState.items.isNotEmpty) ...[
              _buildSectionHeader(context, 'Combo Deals',
                  'Premium cinema combos & savings'),
              _buildComboSection(context, comboState.items),
            ],
          ],
          const SliverToBoxAdapter(child: SizedBox(height: 120)),
        ],
      ),
      bottomNavigationBar: const CustomBottomNavBar(currentIndex: 0),
    );
  }

  // ══════════════════════════════════════════
  // APP BAR
  // ══════════════════════════════════════════

  Widget _buildAppBar(BuildContext context, SeatSelectionState seatSelection) {
    final unreadCount = ref.watch(unreadNotificationsCountProvider);

    return SliverAppBar(
      pinned: true,
      floating: false,
      toolbarHeight: 70,
      backgroundColor: AppColors.bg,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      title: GestureDetector(
        onTap: () => _showLocationSelection(context),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Image.asset(
              'assets/logo_transparent.png',
              height: 40,
              filterQuality: FilterQuality.high,
              fit: BoxFit.contain,
            ),
            if (seatSelection.isComplete)
              Row(
                children: [
                  Icon(Icons.location_on_rounded,
                      size: 11, color: AppColors.primary),
                  const SizedBox(width: 3),
                  Flexible(
                    child: Text(
                      seatSelection.displayLabel,
                      style: AppTextStyles.labelSmall
                          .copyWith(color: AppColors.primary),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
      actions: [
        GestureDetector(
          onTap: () => _showNotificationSheet(context),
          child: Container(
            margin: const EdgeInsets.only(right: 16),
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.surface,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
            ),
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Icon(Icons.notifications_none_rounded,
                    color: AppColors.textPrimary, size: 20),
                if (unreadCount > 0)
                  Positioned(
                    right: -3,
                    top: -3,
                    child: Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        shape: BoxShape.circle,
                        border: Border.all(color: AppColors.bg, width: 1.5),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ══════════════════════════════════════════
  // HERO CAROUSEL
  // ══════════════════════════════════════════

  Widget _buildHeroCarousel(
      BuildContext context, List<Map<String, dynamic>> offers) {
    final defaultBanner = {
      'title': 'Movies + Food\n= Perfect Night',
      'description': 'Order gourmet cinema food directly to your seat.',
      'banner_url': null,
      'category': 'CINEMA',
    };
    final items = offers.isEmpty ? [defaultBanner] : offers;

    return SliverToBoxAdapter(
      child: Column(
        children: [
          const SizedBox(height: 16),
          SizedBox(
            height: 210,
            child: PageView.builder(
              controller: _pageController,
              onPageChanged: (i) => setState(() => _currentPage = i),
              itemCount: items.length,
              itemBuilder: (context, index) {
                final offer = items[index];
                return _buildHeroBannerCard(context, offer);
              },
            ),
          ),
          if (items.length > 1) ...[
            const SizedBox(height: 12),
            _buildCarouselIndicators(items.length),
          ],
          const SizedBox(height: 8),
        ],
      ).animate().fadeIn(duration: 400.ms),
    );
  }

  Widget _buildHeroBannerCard(
      BuildContext context, Map<String, dynamic> offer) {
    final String title = offer['title'] as String? ?? 'Gourmet Cinema Food';
    final String description =
        offer['description'] as String? ?? 'Delivered right to your seat.';
    final String? bannerUrl = offer['banner_url'] as String?;
    final String category = offer['category'] as String? ?? '';

    String imageUrl =
        bannerUrl ?? 'https://images.unsplash.com/photo-1513106580091-1d82408b8cd6?w=900';
    if (bannerUrl == null || bannerUrl.isEmpty) {
      if (category.contains('BEVERAGE') || category == 'UNLIMITED') {
        imageUrl =
            'https://images.unsplash.com/photo-1437419764061-2473afe69fc2?w=900';
      }
    }

    return GestureDetector(
      onTap: () {
        if (offer.containsKey('id')) context.push('/menu', extra: offer);
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(32),
          color: AppColors.surface,
          border: Border.all(
            color: AppColors.primary.withValues(alpha: 0.8),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.4),
              blurRadius: 30,
              spreadRadius: 2,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(32),
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Background image
              SafeNetworkImage(
                imageUrl: imageUrl,
                fit: BoxFit.cover,
                borderRadius: BorderRadius.zero,
              ),
              // Dark gradient overlay from left
              DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                    colors: [
                      AppColors.bg.withValues(alpha: 0.95),
                      AppColors.bg.withValues(alpha: 0.6),
                      Colors.transparent,
                    ],
                    stops: const [0.0, 0.6, 1.0],
                  ),
                ),
              ),
              // Soft vignette around the banner
              DecoratedBox(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: Alignment.center,
                    radius: 1.0,
                    colors: [
                      Colors.transparent,
                      AppColors.bg.withValues(alpha: 0.7),
                    ],
                  ),
                ),
              ),
              // Pink ambient glow top-right
              Positioned(
                right: -20,
                top: -20,
                child: Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                          color: AppColors.primary.withValues(alpha: 0.4),
                          blurRadius: 100),
                    ],
                  ),
                ),
              ),
              // Content
              Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Offer badge
                    if (category.isNotEmpty && category != 'CINEMA')
                      Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                              color: AppColors.primary.withValues(alpha: 0.4)),
                        ),
                        child: Text(
                          category.replaceAll('_', ' '),
                          style: AppTextStyles.sectionTitle.copyWith(
                            color: AppColors.primary,
                            letterSpacing: 1,
                          ),
                        ),
                      ),
                    // Title
                    Text(
                      title,
                      style: AppTextStyles.headingMedium.copyWith(
                        fontSize: 22,
                        height: 1.2,
                        color: AppColors.textPrimary,
                      ),
                      maxLines: 3,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      description,
                      style: AppTextStyles.bodySmall
                          .copyWith(color: AppColors.textSecondary),
                      maxLines: 2,
                    ),
                    const SizedBox(height: 14),
                    // CTA button
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 18, vertical: 9),
                      decoration: BoxDecoration(
                        gradient: AppGradients.primaryButton,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: AppShadows.buttonPrimary,
                      ),
                      child: Text(
                        'Order Now',
                        style: AppTextStyles.labelLarge
                            .copyWith(color: Colors.white),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCarouselIndicators(int count) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(count, (i) {
        final bool active = i == _currentPage;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          margin: const EdgeInsets.symmetric(horizontal: 3),
          width: active ? 20 : 6,
          height: 6,
          decoration: BoxDecoration(
            color: active ? AppColors.primary : AppColors.borderStrong,
            borderRadius: BorderRadius.circular(3),
          ),
        );
      }),
    );
  }

  // ══════════════════════════════════════════
  // EMPTY STATE
  // ══════════════════════════════════════════

  Widget _buildEmptyCinemaState(BuildContext context) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 32, 24, 0),
        child: Container(
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(24),
            border:
                Border.all(color: Colors.white.withValues(alpha: 0.05)),
            boxShadow: AppShadows.card,
          ),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: AppGradients.pinkNeonGlow,
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.location_on_rounded,
                    size: 40, color: AppColors.primary),
              ),
              const SizedBox(height: 24),
              Text('Ready to eat?',
                  style: AppTextStyles.headingMedium),
              const SizedBox(height: 10),
              Text(
                'Select a cinema hall to explore our premium menu and order directly to your seat.',
                textAlign: TextAlign.center,
                style: AppTextStyles.bodyMedium,
              ),
              const SizedBox(height: 28),
              GestureDetector(
                onTap: () => _showLocationSelection(context),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 32, vertical: 14),
                  decoration: BoxDecoration(
                    gradient: AppGradients.primaryButton,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: AppShadows.buttonPrimary,
                  ),
                  child: Text('Select Cinema Hall',
                      style: AppTextStyles.buttonMedium),
                ),
              ),
            ],
          ),
        ),
      ).animate().fadeIn(duration: 400.ms),
    );
  }

  // ══════════════════════════════════════════
  // SEARCH BAR
  // ══════════════════════════════════════════

  Widget _buildSearchBar(BuildContext context) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
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
            onChanged: (val) => setState(() => _searchQuery = val),
            style: AppTextStyles.bodyMedium
                .copyWith(color: AppColors.textPrimary),
            cursorColor: AppColors.primary,
            decoration: InputDecoration(
              hintText: 'Search popcorn, tacos, drinks...',
              hintStyle: AppTextStyles.bodyMedium
                  .copyWith(color: AppColors.textSecondary.withValues(alpha: 0.7)),
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
              prefixIcon: Icon(Icons.search_rounded,
                  color: AppColors.textSecondary, size: 24),
              suffixIcon: _searchQuery.isNotEmpty
                  ? GestureDetector(
                      onTap: () => setState(() => _searchQuery = ''),
                      child: Icon(Icons.close_rounded,
                          color: AppColors.textDisabled, size: 18),
                    )
                  : null,
              contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16, vertical: 14),
            ),
          ),
        ),
      ).animate().fadeIn(delay: 100.ms, duration: 300.ms),
    );
  }


  // ══════════════════════════════════════════
  // REWARDS BANNER
  // ══════════════════════════════════════════

  Widget _buildRewardsBanner(BuildContext context) {
    final loyalty = ref.watch(loyaltyProvider);
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
        child: GestureDetector(
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
                builder: (context) => const CinePointsHistoryScreen()),
          ),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: AppColors.primary, width: 1.5),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.4),
                  blurRadius: 20,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${loyalty.availablePoints} CinePoints',
                        style: AppTextStyles.titleMedium.copyWith(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Tap to view & redeem rewards',
                        style: AppTextStyles.labelSmall
                            .copyWith(color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.star_border_rounded,
                  color: AppColors.primary,
                  size: 32,
                ).animate(onPlay: (c) => c.repeat(reverse: true)).scale(
                    duration: 1500.ms,
                    begin: const Offset(1, 1),
                    end: const Offset(1.1, 1.1)),
                const SizedBox(width: 8),
                Icon(Icons.arrow_forward_ios_rounded,
                    size: 14, color: AppColors.textDisabled),
              ],
            ),
          ),
        ),
      ).animate().fadeIn(delay: 200.ms, duration: 300.ms),
    );
  }

  // ══════════════════════════════════════════
  // OUR MENU GRID
  // ══════════════════════════════════════════

  Widget _buildOurMenuGrid(BuildContext context, MenuState menuState, ComboState comboState) {
    final categories = [
      ('COMBOS', 'assets/images/categories/cat_combos.png', 'Combos'),
      ('POPCORN', 'assets/images/categories/cat_popcorn.png', 'Popcorn'),
      ('BEVERAGES', 'assets/images/categories/cat_beverage.png', 'Beverages'),
      ('SNACKS', 'assets/images/categories/cat_snacks.png', 'Snacks'),
      ('PIZZA', 'assets/images/categories/cat_pizza.png', 'Pizza'),
      ('BURGER', 'assets/images/categories/cat_burger.png', 'Burger'),
      ('LASSI', 'assets/images/categories/cat_lassi.png', 'Lassi'),
      ('ICE_CREAM', 'assets/images/categories/cat_ice_cream.png', 'Ice Cream'),
      ('MILKSHAKE', 'assets/images/categories/cat_milkshake.png', 'Milkshake'),
      ('LOVE_SPECIAL', 'assets/images/categories/cat_love_special.png', 'Love Special'),
      ('SANDWICH', 'assets/images/categories/cat_sandwich.png', 'Sandwich'),
      ('TIKKA', 'assets/images/categories/cat_tikka.png', 'Tikka'),
      ('WRAPS', 'assets/images/categories/cat_wraps.png', 'Wraps'),
      ('TACO', 'assets/images/categories/cat_taco.png', 'Taco'),
      ('MOMO', 'assets/images/categories/cat_momo.png', 'Momo'),
      ('CHINESE_RICE_COMBO', 'assets/images/categories/cat_chinese_rice_combo.png', 'Chinese Combo'),
      ('CHINESE_NOODLES_COMBO', 'assets/images/categories/cat_chinese_rice_combo.png', 'Noodles Combo'),
      ('CHINESE_PASTA', 'assets/images/categories/cat_pizza.png', 'Pasta'),
      ('FUSION_FOODS', 'assets/images/categories/cat_fusion.png', 'Fusion Foods'),
    ];

    final availableCategoryNames = menuState.items.map((e) => e.category?.toUpperCase() ?? '').toSet();
    final hasCombos = comboState.items.isNotEmpty;

    final filteredCategories = categories.where((cat) {
      if (cat.$1 == 'COMBOS') return hasCombos;
      // The category from DB might be 'Burger', so we check against upper-cased DB categories
      // Some DB categories might not perfectly match ID, but standard is upper ID = upper category.
      return availableCategoryNames.contains(cat.$1);
    }).toList();

    if (filteredCategories.isEmpty) {
      return const SliverToBoxAdapter(child: SizedBox());
    }

    return SliverPadding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
      sliver: SliverGrid(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          mainAxisSpacing: 16,
          crossAxisSpacing: 16,
          childAspectRatio: 0.85,
        ),
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            final (id, imagePath, label) = filteredCategories[index];
            return GestureDetector(
              onTap: () {
                ref.read(categoryProvider.notifier).setCategory(id == 'COMBOS' ? 'Combos' : id);
                context.go('/menu');
              },
              child: Container(
                decoration: BoxDecoration(
                  color: AppColors.surfaceElevated.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.glassBorder),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Expanded(
                      child: ClipRRect(
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                        child: Image.asset(
                          imagePath,
                          width: double.infinity,
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      label,
                      textAlign: TextAlign.center,
                      style: AppTextStyles.labelMedium.copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                  ],
                ),
              ).animate().fadeIn(delay: (50 * index).ms),
            );
          },
          childCount: filteredCategories.length,
        ),
      ),
    );
  }

  // ══════════════════════════════════════════
  // SECTION HEADER
  // ══════════════════════════════════════════

  Widget _buildSectionHeader(BuildContext context, String title, String subtitle,
      {bool showViewAll = true}) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 28, 20, 12),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppTextStyles.headingSmall),
                const SizedBox(height: 2),
                Text(subtitle, style: AppTextStyles.bodySmall),
              ],
            ),
            if (showViewAll)
              GestureDetector(
                onTap: () => context.go('/menu'),
                child: Text(
                  'View All',
                  style: AppTextStyles.labelMedium
                      .copyWith(color: AppColors.primary),
                ),
              ),
          ],
        ),
      ),
    );
  }

  // ══════════════════════════════════════════
  // HORIZONTAL SCROLL — compact cards
  // ══════════════════════════════════════════

  Widget _buildHorizontalScroll(BuildContext context, List<FoodItem> items,
      {int? maxCount}) {
    if (items.isEmpty) return const SliverToBoxAdapter(child: SizedBox());
    final displayItems =
        maxCount != null ? items.take(maxCount).toList() : items;

    return SliverToBoxAdapter(
      child: SizedBox(
        height: 210,
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 20),
          itemCount: displayItems.length,
          itemBuilder: (context, index) {
            final item = displayItems[index];
            return Padding(
              padding: EdgeInsets.only(
                  right: 12,
                  left: index == 0 ? 0 : 0),
              child: FoodItemCard(
                id: item.id,
                name: item.name,
                description: item.description,
                imageUrl: item.imageUrl,
                price: item.price,
                isVeg: item.isVeg,
                mode: FoodCardMode.compact,
                onAdd: () {
                  ref.read(cartProvider.notifier).validateAndAddItem(
                      item, ref.read(seatSelectionProvider).hallId);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('${item.name} added!'),
                      duration: const Duration(seconds: 1),
                    ),
                  );
                },
                onTap: () => context.push('/food-detail', extra: item),
              ),
            );
          },
        ),
      ),
    );
  }

  // ══════════════════════════════════════════
  // COMBO SECTION
  // ══════════════════════════════════════════

  Widget _buildComboSection(BuildContext context, List<ComboMeal> combos) {
    return SliverToBoxAdapter(
      child: SizedBox(
        height: 210,
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 20),
          itemCount: combos.length,
          itemBuilder: (context, index) {
            final combo = combos[index];
            return Padding(
              padding: const EdgeInsets.only(right: 12),
              child: FoodItemCard(
                id: combo.id,
                name: combo.name,
                description: combo.description,
                imageUrl: combo.imageUrl,
                price: combo.price,
                originalPrice: combo.originalPrice,
                savingsLabel: combo.savingsLabel,
                mode: FoodCardMode.compact,
                onAdd: () {
                  final foodItem = FoodItem(
                    id: combo.id,
                    name: combo.name,
                    description: combo.description,
                    imageUrl: combo.imageUrl,
                    price: combo.price,
                    category: combo.category,
                  );
                  ref.read(cartProvider.notifier).validateAndAddItem(
                      foodItem, ref.read(seatSelectionProvider).hallId);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('${combo.name} added!'),
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
}
