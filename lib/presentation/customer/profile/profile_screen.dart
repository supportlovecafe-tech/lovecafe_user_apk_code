import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/constants/app_gradients.dart';
import '../../../core/constants/app_shadows.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/providers/theme_provider.dart';
import '../../../core/providers/loyalty_provider.dart';
import '../../shared/widgets/custom_bottom_nav_bar.dart';
import '../loyalty/cinepoints_history_screen.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  bool _isEditing = false;
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    final auth = ref.read(authProvider);
    final names = (auth.userName ?? '').split(' ');
    _firstNameController.text = names.isNotEmpty ? names[0] : '';
    _lastNameController.text = names.length > 1 ? names.skip(1).join(' ') : '';
    _emailController.text = auth.email ?? '';
  }

  Future<void> _saveProfile() async {
    setState(() => _isLoading = true);
    try {
      await ref.read(authProvider.notifier).updateProfile(
        firstName: _firstNameController.text.trim(),
        lastName: _lastNameController.text.trim(),
      );
      setState(() => _isEditing = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile updated successfully!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final authState = ref.watch(authProvider);
    final themeMode = ref.watch(themeProvider);

    return Scaffold(
      backgroundColor: AppColors.bg,
      extendBody: true,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          _buildAppBar(context, theme, colorScheme),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
              child: Column(
                children: [
                  _buildProfileHeader(context, theme, colorScheme, authState),
                  const SizedBox(height: 40),
                  if (_isEditing) ...[
                    _buildEditForm(theme, colorScheme),
                  ] else ...[
                    _buildQuickStats(context, theme, colorScheme),
                    const SizedBox(height: 48),
                    _buildSectionHeader(context, 'PREFERENCES'),
                    _buildMenuTile(
                      context,
                      icon: Icons.receipt_long_rounded,
                      title: 'My Orders',
                      subtitle: 'View your cinematic feasts history',
                      onTap: () => context.push('/orders'),
                    ),

                    const SizedBox(height: 32),
                    _buildSectionHeader(context, 'SUPPORT & SETTINGS'),
                    _buildMenuTile(
                      context,
                      icon: Icons.help_outline_rounded,
                      title: 'Help Center',
                      subtitle: 'Concierge help and assistance',
                      onTap: () => _showComingSoon(context, 'Support'),
                    ),
                  ],
                  const SizedBox(height: 48),
                  _buildLogoutButton(context, theme, colorScheme, ref),
                  const SizedBox(height: 120),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: const CustomBottomNavBar(currentIndex: 4),
    );
  }

  Widget _buildEditForm(ThemeData theme, ColorScheme colorScheme) {
    final auth = ref.watch(authProvider);
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: AppColors.glassBorder),
      ),
      child: Column(
        children: [
          _buildFormInput('FIRST NAME', _firstNameController, Icons.person_outline),
          const SizedBox(height: 20),
          _buildFormInput('LAST NAME', _lastNameController, Icons.person_outline),
          const SizedBox(height: 20),
          _buildFormInput('EMAIL', _emailController, Icons.alternate_email, enabled: false),
          const SizedBox(height: 20),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('PHONE NUMBER', style: theme.textTheme.labelSmall?.copyWith(fontWeight: FontWeight.w900, color: colorScheme.primary.withValues(alpha: 0.5))),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                width: double.infinity,
                decoration: BoxDecoration(
                  color: colorScheme.onSurface.withValues(alpha: 0.01),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: colorScheme.outline.withValues(alpha: 0.05)),
                ),
                child: Text(auth.phone ?? 'N/A', style: TextStyle(color: colorScheme.onSurface.withValues(alpha: 0.4), fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          const SizedBox(height: 32),
          ElevatedButton(
            onPressed: _isLoading ? null : _saveProfile,
            style: ElevatedButton.styleFrom(
              minimumSize: const Size.fromHeight(60),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            ),
            child: _isLoading ? const CircularProgressIndicator() : const Text('SAVE CHANGES'),
          ),
          const SizedBox(height: 12),
          TextButton(
            onPressed: () => setState(() => _isEditing = false),
            child: Text('CANCEL', style: TextStyle(color: colorScheme.onSurface.withValues(alpha: 0.5))),
          ),
        ],
      ),
    );
  }

  Widget _buildFormInput(String label, TextEditingController controller, IconData icon, {bool enabled = true}) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: theme.textTheme.labelSmall?.copyWith(fontWeight: FontWeight.w900, color: colorScheme.primary)),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          enabled: enabled,
          decoration: InputDecoration(
            prefixIcon: Icon(icon, size: 20),
            filled: true,
            fillColor: colorScheme.onSurface.withValues(alpha: 0.03),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
          ),
        ),
      ],
    );
  }

  Widget _buildAppBar(BuildContext context, ThemeData theme, ColorScheme colorScheme) {
    return SliverAppBar(
      pinned: true,
      backgroundColor: AppColors.bg,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      title: Text('My Profile',
          style: AppTextStyles.headingSmall),
      centerTitle: false,
    );
  }

  Widget _buildProfileHeader(BuildContext context, ThemeData theme, ColorScheme colorScheme, AuthState auth) {
    return Column(
      children: [
        Stack(
          children: [
            Container(
              padding: const EdgeInsets.all(3),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: AppGradients.primaryButton,
              ),
              child: CircleAvatar(
                radius: 58,
                backgroundColor: AppColors.surfaceElevated,
                child: Icon(Icons.person_rounded, size: 58,
                    color: AppColors.textDisabled),
              ),
            ),
            Positioned(
              bottom: 4,
              right: 4,
              child: GestureDetector(
                onTap: () => setState(() => _isEditing = !_isEditing),
                child: Container(
                  padding: const EdgeInsets.all(9),
                  decoration: BoxDecoration(
                    color: _isEditing ? AppColors.success : AppColors.primary,
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.bg, width: 3),
                    boxShadow: AppShadows.iconGlow,
                  ),
                  child: Icon(
                      _isEditing ? Icons.check_rounded : Icons.edit_rounded,
                      size: 16,
                      color: Colors.white),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        Text(auth.userName ?? 'Guest User',
            style: AppTextStyles.headingLarge),
        const SizedBox(height: 6),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.phone_android_rounded,
                size: 12, color: AppColors.textDisabled),
            const SizedBox(width: 4),
            Text(auth.phone ?? '',
                style: AppTextStyles.labelSmall),
            if (auth.email != null && auth.email!.isNotEmpty) ...[
              const SizedBox(width: 10),
              Container(
                  width: 3,
                  height: 3,
                  decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.textDisabled)),
              const SizedBox(width: 10),
              Text(auth.email!,
                  style: AppTextStyles.labelSmall),
            ],
          ],
        ),
        const SizedBox(height: 16),
        Container(
          padding:
              const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
                color: AppColors.primary.withValues(alpha: 0.3)),
          ),
          child: Text('GOLD CINEPHILE',
              style: AppTextStyles.sectionTitle
                  .copyWith(color: AppColors.primary, letterSpacing: 2)),
        ),
      ],
    );
  }

  Widget _buildQuickStats(BuildContext context, ThemeData theme, ColorScheme colorScheme) {
    final loyalty = ref.watch(loyaltyProvider);
    return Row(children: [
      _buildStatCard(context, 'SCREENINGS', '42', Icons.stars_rounded), 
      const SizedBox(width: 16), 
      Expanded(
        child: InkWell(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const CinePointsHistoryScreen()),
            );
          },
          borderRadius: BorderRadius.circular(32),
          child: _buildStatCard(context, 'CINEPOINTS', loyalty.availablePoints.toString(), Icons.auto_awesome_rounded, isExpanded: false),
        ),
      ),
    ]);
  }

  Widget _buildStatCard(BuildContext context, String label, String value, IconData icon, {bool isExpanded = true}) {
    Widget card = Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated.withValues(alpha: 0.85),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.glassBorder),
        boxShadow: AppShadows.purpleGlow,
      ),
      child: Column(children: [
        Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                shape: BoxShape.circle),
            child: Icon(icon, color: AppColors.primary, size: 20)),
        const SizedBox(height: 12),
        Text(value, style: AppTextStyles.headingSmall),
        const SizedBox(height: 3),
        Text(label, style: AppTextStyles.sectionTitle),
      ]),
    );
    return isExpanded ? Expanded(child: card) : card;
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return Align(alignment: Alignment.centerLeft, child: Padding(padding: const EdgeInsets.only(left: 4, bottom: 20), child: Text(title, style: AppTextStyles.labelSmall.copyWith(fontWeight: FontWeight.w900, letterSpacing: 2.5, color: AppColors.textDisabled))));
  }

  Widget _buildMenuTile(BuildContext context, {required IconData icon, required String title, required String subtitle, VoidCallback? onTap, Widget? trailing}) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated.withValues(alpha: 0.5), 
        borderRadius: BorderRadius.circular(24), 
        border: Border.all(color: AppColors.glassBorder),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        leading: Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(16)), child: Icon(icon, color: AppColors.primary, size: 24)),
        title: Text(title, style: AppTextStyles.titleMedium),
        subtitle: Padding(padding: const EdgeInsets.only(top: 4), child: Text(subtitle, style: AppTextStyles.bodySmall.copyWith(color: AppColors.textDisabled))),
        trailing: trailing ?? Icon(Icons.chevron_right_rounded, color: AppColors.textDisabled),
        onTap: onTap,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      ),
    );
  }

  Widget _buildLogoutButton(BuildContext context, ThemeData theme, ColorScheme colorScheme, WidgetRef ref) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: OutlinedButton.icon(
        onPressed: () async {
          try {
            await ref.read(authProvider.notifier).logout();
          } catch (e) {
            debugPrint('Logout error (non-fatal): $e');
          } finally {
            if (context.mounted) {
              context.go('/welcome');
            }
          }
        },
        icon: const Icon(Icons.logout_rounded, size: 18),
        label: Text('Sign Out',
            style: AppTextStyles.buttonMedium
                .copyWith(color: AppColors.error, letterSpacing: 1)),
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.error,
          side: BorderSide(color: AppColors.error.withValues(alpha: 0.25)),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16)),
        ),
      ),
    );
  }

  void _showComingSoon(BuildContext context, String title) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.fromLTRB(24, 12, 24, 40),
        decoration: BoxDecoration(color: AppColors.surfaceElevated.withValues(alpha: 0.95), borderRadius: const BorderRadius.vertical(top: Radius.circular(40))),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(width: 60, height: 6, margin: const EdgeInsets.only(bottom: 32), decoration: BoxDecoration(color: colorScheme.onSurface.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(3))),
          Container(padding: const EdgeInsets.all(20), decoration: BoxDecoration(color: colorScheme.primary.withValues(alpha: 0.1), shape: BoxShape.circle), child: Icon(Icons.auto_awesome_rounded, color: colorScheme.primary, size: 40)),
          const SizedBox(height: 24),
          Text(title, style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w900)),
          const SizedBox(height: 40),
          ElevatedButton(onPressed: () => Navigator.pop(context), style: ElevatedButton.styleFrom(minimumSize: const Size.fromHeight(64), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20))), child: const Text('GOT IT')),
        ]),
      ),
    );
  }
}
