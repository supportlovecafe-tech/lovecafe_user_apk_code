import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_gradients.dart';
import '../../../core/constants/app_shadows.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/providers/loyalty_provider.dart';

class CinePointsHistoryScreen extends ConsumerWidget {
  const CinePointsHistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final loyalty = ref.watch(loyaltyProvider);

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // ── App Bar
          SliverAppBar(
            pinned: true,
            backgroundColor: AppColors.bg,
            surfaceTintColor: Colors.transparent,
            elevation: 0,
            title: Text('CinePoints', style: AppTextStyles.headingSmall),
            centerTitle: false,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new_rounded,
                  color: AppColors.textPrimary, size: 18),
              onPressed: () => Navigator.pop(context),
            ),
          ),

          // ── VIP Summary Card
          SliverToBoxAdapter(
            child: _SummaryCard(loyalty: loyalty)
                .animate()
                .fadeIn(duration: 400.ms)
                .slideY(begin: 0.1, end: 0),
          ),

          // ── How to earn? Section
          SliverToBoxAdapter(
            child: _HowToEarnSection()
                .animate()
                .fadeIn(delay: 100.ms, duration: 400.ms)
                .slideY(begin: 0.1, end: 0),
          ),

          // ── Transaction History Header
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 28, 24, 12),
              child: Row(
                children: [
                  Text('TRANSACTION HISTORY',
                      style: AppTextStyles.sectionTitle),
                  const Spacer(),
                  Text('${loyalty.transactions.length} records',
                      style: AppTextStyles.labelSmall),
                ],
              ),
            ),
          ),

          // ── Transactions List
          if (loyalty.transactions.isEmpty)
            SliverToBoxAdapter(
              child: _EmptyState(),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) => _TransactionTile(
                    tx: loyalty.transactions[index],
                    index: index,
                  ),
                  childCount: loyalty.transactions.length,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ── VIP Summary Card ──────────────────────────────────

class _SummaryCard extends StatelessWidget {
  final LoyaltyState loyalty;
  const _SummaryCard({required this.loyalty});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
      child: Container(
        padding: const EdgeInsets.all(28),
        decoration: BoxDecoration(
          color: AppColors.surface, // Dark background
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: AppColors.primary, width: 2),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.5),
              blurRadius: 40,
              spreadRadius: 4,
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('You have',
                    style: AppTextStyles.bodyMedium
                        .copyWith(color: AppColors.textSecondary)),
                Text(
                  '${loyalty.availablePoints}',
                  style: AppTextStyles.displayHero.copyWith(
                    color: AppColors.textPrimary,
                    fontSize: 56,
                    height: 1.1,
                    letterSpacing: -1,
                  ),
                ),
                Text(
                  'CinePoints',
                  style: AppTextStyles.titleMedium.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
            Icon(
              Icons.star_border_rounded,
              color: AppColors.primary,
              size: 80,
            ),
          ],
        ),
      ),
    );
  }
}

class _HowToEarnSection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('How to earn?', style: AppTextStyles.titleMedium),
          const SizedBox(height: 16),
          _buildEarnRow('Place an order', 'Per ₹100 spent', '+10 pts'),
          const SizedBox(height: 16),
          _buildEarnRow('Write a review', 'Per review', '+50 pts'),
          const SizedBox(height: 16),
          _buildEarnRow('Refer a friend', 'Per successful referral', '+100 pts'),
          const SizedBox(height: 28),
          SizedBox(
            width: double.infinity,
            height: 56,
            child: OutlinedButton(
              onPressed: () {},
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: AppColors.primary.withValues(alpha: 0.5), width: 1.5),
                backgroundColor: AppColors.primary.withValues(alpha: 0.05),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              child: Text(
                'View Rewards',
                style: AppTextStyles.buttonMedium.copyWith(color: AppColors.textPrimary),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEarnRow(String title, String subtitle, String points) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: AppTextStyles.bodyMedium),
            const SizedBox(height: 2),
            Text(subtitle,
                style: AppTextStyles.bodySmall
                    .copyWith(color: AppColors.textDisabled)),
          ],
        ),
        Text(points,
            style: AppTextStyles.labelLarge.copyWith(color: AppColors.primary)),
      ],
    );
  }
}

class _Stat extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _Stat(this.label, this.value, this.color);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(label,
            style: AppTextStyles.labelSmall
                .copyWith(color: Colors.white.withValues(alpha: 0.6))),
        const SizedBox(height: 4),
        Text(value,
            style: AppTextStyles.headingSmall.copyWith(color: color)),
      ],
    );
  }
}

// ── Transaction Tile ──────────────────────────────────

class _TransactionTile extends StatelessWidget {
  final dynamic tx;
  final int index;

  const _TransactionTile({required this.tx, required this.index});

  @override
  Widget build(BuildContext context) {
    final isEarn = tx.type == 'EARN';
    final color = isEarn ? AppColors.success : AppColors.primary;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
        boxShadow: AppShadows.card,
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              shape: BoxShape.circle,
              border: Border.all(color: color.withValues(alpha: 0.2)),
            ),
            child: Icon(
              isEarn ? Icons.add_rounded : Icons.remove_rounded,
              color: color,
              size: 20,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isEarn ? 'Points Earned' : 'Points Redeemed',
                  style: AppTextStyles.titleSmall,
                ),
                const SizedBox(height: 3),
                Text(
                  DateFormat('dd MMM yyyy • hh:mm a').format(tx.createdAt),
                  style: AppTextStyles.bodySmall,
                ),
              ],
            ),
          ),
          Text(
            '${isEarn ? '+' : '−'}${tx.points}',
            style: AppTextStyles.priceMedium.copyWith(color: color),
          ),
        ],
      ),
    )
        .animate()
        .fadeIn(delay: (index * 60).ms, duration: 250.ms)
        .slideY(begin: 0.08, end: 0);
  }
}

// ── Empty State ──────────────────────────────────

class _EmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(60),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.secondary.withValues(alpha: 0.08),
            ),
            child: Icon(Icons.history_rounded,
                size: 48, color: AppColors.secondary.withValues(alpha: 0.4)),
          ),
          const SizedBox(height: 20),
          Text('No transactions yet', style: AppTextStyles.headingSmall),
          const SizedBox(height: 8),
          Text(
            'Order food to start earning CinePoints and unlock exclusive rewards.',
            textAlign: TextAlign.center,
            style: AppTextStyles.bodyMedium,
          ),
        ],
      ),
    ).animate().fadeIn(delay: 200.ms);
  }
}
