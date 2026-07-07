import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/constants/app_gradients.dart';
import '../../../core/constants/app_shadows.dart';
import '../../../core/providers/orders_provider.dart';
import '../../../core/models/order_model.dart';
import '../../../core/providers/chat_provider.dart';
import '../../../core/providers/notification_provider.dart';
import '../../shared/widgets/custom_bottom_nav_bar.dart';

class OrdersScreen extends ConsumerStatefulWidget {
  const OrdersScreen({super.key});

  @override
  ConsumerState<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends ConsumerState<OrdersScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final allOrders = ref.watch(ordersProvider);

    final activeOrders = allOrders.where((o) =>
        o.status != OrderStatus.DELIVERED &&
        o.status != OrderStatus.CANCELLED).toList();

    final completedOrders = allOrders.where((o) =>
        o.status == OrderStatus.DELIVERED ||
        o.status == OrderStatus.CANCELLED).toList();

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: Column(
        children: [
          _buildAppBar(context, allOrders.length),
          _buildTabBar(activeOrders.length, completedOrders.length),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                // Tab 1: Active Orders
                activeOrders.isEmpty
                    ? _buildEmptyState(context, isActive: true)
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                        itemCount: activeOrders.length,
                        itemBuilder: (context, index) {
                          final order = activeOrders[index];
                          return _buildActiveOrderCard(context, order);
                        },
                      ),
                // Tab 2: Transaction History
                completedOrders.isEmpty
                    ? _buildEmptyState(context, isActive: false)
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                        itemCount: completedOrders.length,
                        itemBuilder: (context, index) {
                          final order = completedOrders[index];
                          return _buildHistoryCard(context, order);
                        },
                      ),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: const CustomBottomNavBar(currentIndex: 3),
    );
  }

  Widget _buildAppBar(BuildContext context, int count) {
    return AppBar(
      backgroundColor: Colors.transparent,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new_rounded,
            color: AppColors.textPrimary, size: 18),
        onPressed: () {
          if (Navigator.of(context).canPop()) {
            context.pop();
          } else {
            context.go('/home');
          }
        },
      ),
      title: Text('My Orders', style: AppTextStyles.headingSmall),
      centerTitle: true,
      actions: [
        if (count > 0)
          Center(
            child: Container(
              margin: const EdgeInsets.only(right: 24),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                '$count',
                style: AppTextStyles.labelLarge.copyWith(color: AppColors.primary),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildTabBar(int activeCount, int historyCount) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
        borderRadius: BorderRadius.circular(16),
      ),
      child: TabBar(
        controller: _tabController,
        indicator: BoxDecoration(
          color: AppColors.primary,
          borderRadius: BorderRadius.circular(14),
        ),
        indicatorSize: TabBarIndicatorSize.tab,
        labelColor: Colors.white,
        unselectedLabelColor: AppColors.textDisabled,
        labelStyle: AppTextStyles.labelMedium,
        unselectedLabelStyle: AppTextStyles.labelMedium.copyWith(fontWeight: FontWeight.normal),
        dividerColor: Colors.transparent,
        tabs: [
          Tab(text: 'Active ($activeCount)'),
          Tab(text: 'History ($historyCount)'),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, {required bool isActive}) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.06),
              shape: BoxShape.circle,
            ),
            child: Icon(
                isActive ? Icons.receipt_long_rounded : Icons.history_rounded,
                size: 72, color: AppColors.primary.withValues(alpha: 0.35)),
          ),
          const SizedBox(height: 28),
          Text(isActive ? 'No active orders' : 'No past orders',
              style: AppTextStyles.headingMedium),
          const SizedBox(height: 10),
          Text(
              isActive
                  ? 'Place an order to see live tracking here.'
                  : 'Your completed orders will appear here.',
              textAlign: TextAlign.center,
              style: AppTextStyles.bodyMedium),
          if (isActive) ...[
            const SizedBox(height: 36),
            GestureDetector(
              onTap: () => context.go('/menu'),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 36, vertical: 14),
                decoration: BoxDecoration(
                  gradient: AppGradients.primaryButton,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: AppShadows.buttonPrimary,
                ),
                child: Text('Explore Menu',
                    style: AppTextStyles.buttonMedium),
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ============ ACTIVE ORDER CARD ============

  Widget _buildActiveOrderCard(BuildContext context, OrderModel order) {
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated.withValues(alpha: 0.85),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.glassBorder),
        boxShadow: AppShadows.purpleGlow,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Column(
          children: [
            _buildOrderHeader(order),
            _buildOrderDetails(order),
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.04),
                borderRadius: const BorderRadius.vertical(bottom: Radius.circular(24)),
              ),
              child: Column(
                children: [
                  _buildTrackingTimeline(context, order.status),
                  const SizedBox(height: 16),
                  _buildStatusMessage(order.status),
                  const SizedBox(height: 16),
                  _buildTrackButton(context, order),
                  const SizedBox(height: 12),
                  _buildChatButton(context, order),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChatButton(BuildContext context, OrderModel order) {
    final hasNewMessages = ref.watch(hasNewChatMessagesProvider);
    
    return Container(
      decoration: hasNewMessages ? BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.3),
            blurRadius: 12,
            spreadRadius: 2,
          ),
        ],
      ) : null,
      child: OutlinedButton.icon(
        onPressed: () {
          // Mark relevant notifications as read when opening chat
          _showChatSheet(context, order);
        },
        icon: Stack(
          clipBehavior: Clip.none,
          children: [
            const Icon(Icons.chat_bubble_outline_rounded, size: 18),
            if (hasNewMessages)
              Positioned(
                right: -2,
                top: -2,
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: AppColors.primary,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
          ],
        ),
        label: const Text('CONTACT OUTLET'),
        style: OutlinedButton.styleFrom(
          minimumSize: const Size.fromHeight(56),
          side: BorderSide(color: AppColors.primary.withValues(alpha: hasNewMessages ? 1.0 : 0.5), width: hasNewMessages ? 2 : 1),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          backgroundColor: hasNewMessages ? AppColors.primary.withValues(alpha: 0.05) : null,
        ),
      ),
    );
  }

  Widget _buildStatusMessage(OrderStatus status) {
    String message;
    IconData icon;
    Color color;
    switch (status) {
      case OrderStatus.PENDING:
        message = 'Your order has been placed and is waiting for confirmation.';
        icon = Icons.hourglass_top_rounded;
        color = Colors.orange;
        break;
      case OrderStatus.PREPARING:
        message = 'The kitchen is preparing your order now!';
        icon = Icons.restaurant_rounded;
        color = Colors.blue;
        break;
      case OrderStatus.READY:
        message = '🎉 Your food is ready to serve! Our staff will deliver it shortly.';
        icon = Icons.celebration_rounded;
        color = AppColors.success;
        break;
      default:
        message = '';
        icon = Icons.info_outline;
        color = AppColors.textDisabled;
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.15)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: AppTextStyles.bodySmall.copyWith(
                color: color,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============ HISTORY CARD ============

  Widget _buildHistoryCard(BuildContext context, OrderModel order) {
    final isDelivered = order.status == OrderStatus.DELIVERED;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.glassBorder),
      ),
      child: Column(
        children: [
          _buildOrderHeader(order),
          _buildOrderDetails(order),
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: (isDelivered ? AppColors.success : AppColors.error).withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          isDelivered ? Icons.check_circle_rounded : Icons.cancel_rounded,
                          size: 18,
                          color: isDelivered ? AppColors.success : AppColors.error,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          isDelivered ? 'Delivered' : 'Cancelled',
                          style: AppTextStyles.labelMedium.copyWith(
                            color: isDelivered ? AppColors.success : AppColors.error,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                OutlinedButton(
                  onPressed: () => context.push('/menu'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    side: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
                  ),
                  child: Text(
                    'REORDER',
                    style: AppTextStyles.labelSmall.copyWith(letterSpacing: 1),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ============ SHARED WIDGETS ============

  Widget _buildOrderHeader(OrderModel order) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'ORDER ${order.displayId.toUpperCase()}',
                style: AppTextStyles.labelSmall.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                DateFormat('MMM dd, yyyy • hh:mm a').format(order.timestamp),
                style: AppTextStyles.bodySmall.copyWith(color: AppColors.textDisabled),
              ),
            ],
          ),
          _buildStatusChip(order.status),
        ],
      ),
    );
  }

  Widget _buildOrderDetails(OrderModel order) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
      child: Column(
        children: [
          Row(
            children: [
              Icon(Icons.location_on_rounded,
                  size: 16, color: AppColors.textDisabled),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  order.location,
                  style: AppTextStyles.bodySmall.copyWith(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          ...order.items.map((item) {
            final isItemDelivered = item.isDelivered;
            return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        if (isItemDelivered)
                          Container(
                            margin: const EdgeInsets.only(right: 12),
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: AppColors.success.withValues(alpha: 0.1),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.check_circle_rounded, color: AppColors.success, size: 16),
                          ),
                        // Feature 2: combo badge
                        if (item.isCombo)
                          Container(
                            margin: const EdgeInsets.only(right: 8),
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(colors: [Color(0xFFFF6B35), Color(0xFFFF2D55)]),
                              borderRadius: BorderRadius.circular(5),
                            ),
                            child: const Text('COMBO', style: TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.w900, letterSpacing: 0.5)),
                          )
                        else
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: isItemDelivered ? AppColors.success.withValues(alpha: 0.1) : AppColors.primary.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              '${item.quantity}x',
                              style: AppTextStyles.labelSmall.copyWith(
                                color: isItemDelivered ? AppColors.success : AppColors.primary,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            item.foodItem.name,
                            style: AppTextStyles.titleMedium.copyWith(
                              color: isItemDelivered ? AppColors.success : null,
                            ),
                          ),
                        ),
                        Text(
                          '₹${(item.foodItem.price * item.quantity).toInt()}',
                          style: AppTextStyles.priceSmall.copyWith(
                            color: isItemDelivered ? AppColors.success : null,
                          ),
                        ),
                      ],
                    ),
                    // Feature 1: Show item note if present
                    if (item.note != null && item.note!.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 4, left: 4),
                        child: Row(
                          children: [
                            Icon(Icons.notes_rounded, size: 11, color: AppColors.textDisabled),
                            const SizedBox(width: 5),
                            Expanded(
                              child: Text(
                                item.note!,
                                style: AppTextStyles.bodySmall.copyWith(
                                  fontSize: 11,
                                  color: AppColors.textDisabled,
                                  fontStyle: FontStyle.italic,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              );
          }),
          const SizedBox(height: 12),
          Divider(color: Colors.white.withValues(alpha: 0.05)),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Payment Method',
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.textDisabled,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.secondary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  order.paymentMethod.name.replaceAll('DEMO_', '').replaceAll('_', ' '),
                  style: AppTextStyles.labelSmall.copyWith(
                    color: AppColors.secondary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Amount Paid', style: AppTextStyles.bodySmall.copyWith(fontWeight: FontWeight.bold)),
              Text(
                '₹${order.totalAmount.toInt()}',
                style: AppTextStyles.headingSmall.copyWith(color: AppColors.primary),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTrackButton(BuildContext context, OrderModel order) {
    return GestureDetector(
      onTap: () => _showTrackingSheet(context, order),
      child: Container(
        height: 56,
        decoration: BoxDecoration(
          gradient: AppGradients.primaryButton,
          borderRadius: BorderRadius.circular(16),
          boxShadow: AppShadows.buttonPrimary,
        ),
        child: Center(
          child: Text(
            'Live Tracking',
            style: AppTextStyles.buttonLarge,
          ),
        ),
      ),
    );
  }

  Widget _buildStatusChip(OrderStatus status) {
    Color color = AppColors.textDisabled;
    String label = status.name;

    switch (status) {
      case OrderStatus.PENDING:
        color = Colors.orange;
        label = 'ORDER PLACED';
        break;
      case OrderStatus.PREPARING:
        color = AppColors.primary;
        label = 'PREPARING';
        break;
      case OrderStatus.READY:
        color = AppColors.success;
        label = 'READY TO SERVE';
        break;
      case OrderStatus.DELIVERED:
        color = Colors.green.shade700;
        label = 'DELIVERED';
        break;
      case OrderStatus.CANCELLED:
        color = AppColors.error;
        label = 'CANCELLED';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.5)),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.2),
            blurRadius: 8,
          ),
        ],
      ),
      child: Text(
        label,
        style: AppTextStyles.labelSmall.copyWith(
          color: color,
          fontWeight: FontWeight.w900,
          fontSize: 10,
          letterSpacing: 1,
        ),
      ),
    );
  }

  Widget _buildTrackingTimeline(BuildContext context, OrderStatus status) {
    final steps = <_TrackStep>[
      const _TrackStep(
          label: 'Order Placed', icon: Icons.receipt_long_rounded, isActive: true),
      _TrackStep(
          label: 'Preparing',
          icon: Icons.restaurant_rounded,
          isActive: status == OrderStatus.PREPARING || status == OrderStatus.READY),
      _TrackStep(
          label: 'Ready to Serve',
          icon: Icons.stars_rounded,
          isActive: status == OrderStatus.READY),
    ];

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        for (int i = 0; i < steps.length; i++) ...[
          _timelineItem(steps[i]),
          if (i < steps.length - 1)
            Expanded(
              child: Container(
                height: 2,
                margin: const EdgeInsets.symmetric(horizontal: 8),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      steps[i].isActive ? AppColors.primary : Colors.white.withValues(alpha: 0.1),
                      steps[i+1].isActive ? AppColors.primary : Colors.white.withValues(alpha: 0.1),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ],
    );
  }

  Widget _timelineItem(_TrackStep step) {
    final color = step.isActive ? AppColors.primary : AppColors.textDisabled;
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: step.isActive ? AppColors.primary.withValues(alpha: 0.1) : Colors.transparent,
            shape: BoxShape.circle,
            border: Border.all(color: color, width: 2),
            boxShadow: step.isActive ? AppShadows.pinkGlowSoft : [],
          ),
          child: Icon(step.icon, size: 16, color: color),
        ),
        const SizedBox(height: 8),
        Text(
          step.label,
          style: AppTextStyles.labelSmall.copyWith(
            color: color,
            fontWeight: step.isActive ? FontWeight.w900 : FontWeight.normal,
            fontSize: 8,
          ),
        ),
      ],
    );
  }

  void _showTrackingSheet(BuildContext context, OrderModel order) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        padding: const EdgeInsets.fromLTRB(24, 12, 24, 40),
        decoration: BoxDecoration(
          color: AppColors.surfaceElevated.withValues(alpha: 0.95),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(40)),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.15),
              blurRadius: 50,
              offset: const Offset(0, -10),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 60,
                height: 6,
                margin: const EdgeInsets.only(bottom: 32),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            ),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.delivery_dining_rounded, color: AppColors.primary),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Live Tracking', style: AppTextStyles.headingMedium),
                      Text('Order ID: ${order.id.substring(0, order.id.length > 8 ? 8 : order.id.length).toUpperCase()}', 
                          style: AppTextStyles.bodySmall.copyWith(color: AppColors.textDisabled)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 48),
            _buildTrackingTimeline(context, order.status),
            const SizedBox(height: 32),
            _buildStatusMessage(order.status),
            const SizedBox(height: 32),
            GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(
                height: 56,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Center(
                  child: Text('CLOSE', style: AppTextStyles.buttonMedium),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showChatSheet(BuildContext context, OrderModel order) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => _ChatSheet(order: order),
    );
  }
}

class _ChatSheet extends ConsumerStatefulWidget {
  final OrderModel order;
  const _ChatSheet({required this.order});

  @override
  ConsumerState<_ChatSheet> createState() => _ChatSheetState();
}

class _ChatSheetState extends ConsumerState<_ChatSheet> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final messages = ref.watch(chatProvider(widget.order.id));

    return Container(
      height: MediaQuery.of(context).size.height * 0.8,
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated.withValues(alpha: 0.95),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(40)),
      ),
      child: Column(
        children: [
          _buildHeader(context, theme, colorScheme),
          Expanded(
            child: messages.isEmpty
                ? _buildEmptyChat(theme, colorScheme)
                : ListView.builder(
                    padding: const EdgeInsets.all(24),
                    itemCount: messages.length,
                    itemBuilder: (context, index) {
                      final msg = messages[index];
                      final isMe = msg.senderRole == 'CUSTOMER';
                      return _buildMessageBubble(theme, colorScheme, msg, isMe);
                    },
                  ),
          ),
          _buildInputArea(context, theme, colorScheme),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context, ThemeData theme, ColorScheme colorScheme) {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 12, 12, 12),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: colorScheme.outline.withValues(alpha: 0.05))),
      ),
      child: Column(
        children: [
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.only(bottom: 20),
            decoration: BoxDecoration(
              color: colorScheme.onSurface.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Row(
            children: [
              CircleAvatar(
                backgroundColor: colorScheme.primary.withValues(alpha: 0.1),
                child: Icon(Icons.storefront_rounded, color: colorScheme.primary, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Outlet Support', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900)),
                    Text('Replying to Order #${widget.order.id.substring(0,6).toUpperCase()}', 
                        style: theme.textTheme.bodySmall?.copyWith(color: colorScheme.onSurface.withValues(alpha: 0.5))),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close_rounded),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyChat(ThemeData theme, ColorScheme colorScheme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.chat_bubble_outline_rounded, size: 48, color: colorScheme.primary.withValues(alpha: 0.2)),
          const SizedBox(height: 16),
          Text('No messages yet', style: theme.textTheme.titleSmall?.copyWith(color: colorScheme.onSurface.withValues(alpha: 0.3))),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 48),
            child: Text(
              'Send a message to the outlet staff regarding your order.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall?.copyWith(color: colorScheme.onSurface.withValues(alpha: 0.3)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(ThemeData theme, ColorScheme colorScheme, ChatMessage msg, bool isMe) {
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.7),
        decoration: BoxDecoration(
          color: isMe ? colorScheme.primary : colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(20).copyWith(
            bottomRight: isMe ? const Radius.circular(4) : const Radius.circular(20),
            bottomLeft: isMe ? const Radius.circular(20) : const Radius.circular(4),
          ),
        ),
        child: Text(
          msg.content,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: isMe ? colorScheme.onPrimary : colorScheme.onSurface,
          ),
        ),
      ),
    );
  }

  Widget _buildInputArea(BuildContext context, ThemeData theme, ColorScheme colorScheme) {
    return Container(
      padding: EdgeInsets.fromLTRB(24, 16, 24, 16 + MediaQuery.of(context).viewInsets.bottom),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        border: Border(top: BorderSide(color: colorScheme.outline.withValues(alpha: 0.05))),
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              decoration: BoxDecoration(
                color: colorScheme.onSurface.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(28),
              ),
              child: TextField(
                controller: _controller,
                decoration: const InputDecoration(
                  hintText: 'Type a message...',
                  border: InputBorder.none,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          FloatingActionButton.small(
            onPressed: () {
              if (_controller.text.trim().isEmpty) return;
              ref.read(chatProvider(widget.order.id).notifier).sendMessage(_controller.text.trim());
              _controller.clear();
            },
            backgroundColor: colorScheme.primary,
            elevation: 0,
            child: const Icon(Icons.send_rounded, color: Colors.white, size: 20),
          ),
        ],
      ),
    );
  }
}

class _TrackStep {
  final String label;
  final IconData icon;
  final bool isActive;
  const _TrackStep(
      {required this.label, required this.icon, required this.isActive});
}
