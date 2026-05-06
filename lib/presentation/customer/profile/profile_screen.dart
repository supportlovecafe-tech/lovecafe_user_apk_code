import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
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
        email: _emailController.text.trim().isEmpty ? null : _emailController.text.trim(),
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
      backgroundColor: colorScheme.background,
      body: CustomScrollView(
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
                    _buildMenuTile(
                      context,
                      icon: Icons.brightness_4_rounded,
                      title: 'Dark Mode',
                      subtitle: 'Toggle theme for a cinematic experience',
                      trailing: Switch(
                        value: themeMode == ThemeMode.dark,
                        onChanged: (value) {
                          ref.read(themeProvider.notifier).toggleTheme();
                        },
                        activeColor: colorScheme.primary,
                      ),
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
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: colorScheme.outline.withOpacity(0.1)),
      ),
      child: Column(
        children: [
          _buildFormInput('FIRST NAME', _firstNameController, Icons.person_outline),
          const SizedBox(height: 20),
          _buildFormInput('LAST NAME', _lastNameController, Icons.person_outline),
          const SizedBox(height: 20),
          _buildFormInput('EMAIL', _emailController, Icons.alternate_email),
          const SizedBox(height: 20),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('PHONE NUMBER', style: theme.textTheme.labelSmall?.copyWith(fontWeight: FontWeight.w900, color: colorScheme.primary.withOpacity(0.5))),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                width: double.infinity,
                decoration: BoxDecoration(
                  color: colorScheme.onSurface.withOpacity(0.01),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: colorScheme.outline.withOpacity(0.05)),
                ),
                child: Text(auth.phone ?? 'N/A', style: TextStyle(color: colorScheme.onSurface.withOpacity(0.4), fontWeight: FontWeight.bold)),
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
            child: Text('CANCEL', style: TextStyle(color: colorScheme.onSurface.withOpacity(0.5))),
          ),
        ],
      ),
    );
  }

  Widget _buildFormInput(String label, TextEditingController controller, IconData icon) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: theme.textTheme.labelSmall?.copyWith(fontWeight: FontWeight.w900, color: colorScheme.primary)),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          decoration: InputDecoration(
            prefixIcon: Icon(icon, size: 20),
            filled: true,
            fillColor: colorScheme.onSurface.withOpacity(0.03),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
          ),
        ),
      ],
    );
  }

  Widget _buildAppBar(BuildContext context, ThemeData theme, ColorScheme colorScheme) {
    return SliverAppBar(
      pinned: true,
      backgroundColor: colorScheme.background.withOpacity(0.8),
      title: Text('Account', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900)),
      centerTitle: true,
    );
  }

  Widget _buildProfileHeader(BuildContext context, ThemeData theme, ColorScheme colorScheme, AuthState auth) {
    return Column(
      children: [
        Stack(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(colors: [colorScheme.primary, colorScheme.primary.withOpacity(0.3)]),
              ),
              child: CircleAvatar(
                radius: 60,
                backgroundColor: colorScheme.surface,
                child: Icon(Icons.person_rounded, size: 60, color: colorScheme.onSurface.withOpacity(0.3)),
              ),
            ),
            Positioned(
              bottom: 4,
              right: 4,
              child: GestureDetector(
                onTap: () => setState(() => _isEditing = !_isEditing),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: _isEditing ? Colors.green : colorScheme.primary,
                    shape: BoxShape.circle,
                    border: Border.all(color: colorScheme.surface, width: 3),
                  ),
                  child: Icon(_isEditing ? Icons.check_rounded : Icons.edit_rounded, size: 16, color: Colors.white),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        Text(auth.userName ?? 'User Name',
            style: theme.textTheme.headlineLarge?.copyWith(fontWeight: FontWeight.w900, letterSpacing: -1)),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.phone_android_rounded, size: 14, color: colorScheme.onSurface.withOpacity(0.4)),
            const SizedBox(width: 4),
            Text(auth.phone ?? '', style: theme.textTheme.bodySmall?.copyWith(color: colorScheme.onSurface.withOpacity(0.4), fontWeight: FontWeight.bold)),
            if (auth.email != null && auth.email!.isNotEmpty) ...[
              const SizedBox(width: 12),
              Container(width: 4, height: 4, decoration: BoxDecoration(shape: BoxShape.circle, color: colorScheme.onSurface.withOpacity(0.2))),
              const SizedBox(width: 12),
              Icon(Icons.alternate_email_rounded, size: 14, color: colorScheme.onSurface.withOpacity(0.4)),
              const SizedBox(width: 4),
              Text(auth.email!, style: theme.textTheme.bodySmall?.copyWith(color: colorScheme.onSurface.withOpacity(0.4), fontWeight: FontWeight.bold)),
            ],
          ],
        ),
        const SizedBox(height: 24),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          decoration: BoxDecoration(color: colorScheme.primary.withOpacity(0.1), borderRadius: BorderRadius.circular(20)),
          child: Text('GOLD CINEPHILE', style: theme.textTheme.labelSmall?.copyWith(color: colorScheme.primary, fontWeight: FontWeight.w900, letterSpacing: 2)),
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
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    Widget card = Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: colorScheme.outline.withOpacity(0.1)),
      ),
      child: Column(children: [
        Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: colorScheme.primary.withOpacity(0.1), shape: BoxShape.circle), child: Icon(icon, color: colorScheme.primary, size: 20)),
        const SizedBox(height: 16),
        Text(value, style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w900)),
        const SizedBox(height: 4),
        Text(label, style: theme.textTheme.labelSmall?.copyWith(color: colorScheme.onSurface.withOpacity(0.4), fontWeight: FontWeight.w900, letterSpacing: 1)),
      ]),
    );

    return isExpanded ? Expanded(child: card) : card;
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return Align(alignment: Alignment.centerLeft, child: Padding(padding: const EdgeInsets.only(left: 4, bottom: 20), child: Text(title, style: theme.textTheme.labelSmall?.copyWith(fontWeight: FontWeight.w900, letterSpacing: 2.5, color: colorScheme.onSurface.withOpacity(0.3)))));
  }

  Widget _buildMenuTile(BuildContext context, {required IconData icon, required String title, required String subtitle, VoidCallback? onTap, Widget? trailing}) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(color: colorScheme.surface, borderRadius: BorderRadius.circular(24), border: Border.all(color: colorScheme.outline.withOpacity(0.1))),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        leading: Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: colorScheme.primary.withOpacity(0.05), borderRadius: BorderRadius.circular(16)), child: Icon(icon, color: colorScheme.primary, size: 24)),
        title: Text(title, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
        subtitle: Padding(padding: const EdgeInsets.only(top: 4), child: Text(subtitle, style: theme.textTheme.bodySmall?.copyWith(color: colorScheme.onSurface.withOpacity(0.4)))),
        trailing: trailing ?? Icon(Icons.chevron_right_rounded, color: colorScheme.onSurface.withOpacity(0.2)),
        onTap: onTap,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      ),
    );
  }

  Widget _buildLogoutButton(BuildContext context, ThemeData theme, ColorScheme colorScheme, WidgetRef ref) {
    return Container(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: () async { 
          await ref.read(authProvider.notifier).logout(); 
          if (context.mounted) {
            context.go('/welcome');
          }
        },
        icon: const Icon(Icons.logout_rounded, size: 20),
        label: Text('SIGN OUT', style: theme.textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w900, letterSpacing: 2)),
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 24), 
          foregroundColor: colorScheme.error, 
          side: BorderSide(color: colorScheme.error.withOpacity(0.2)), 
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
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
        decoration: BoxDecoration(color: colorScheme.surface, borderRadius: const BorderRadius.vertical(top: Radius.circular(40))),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(width: 60, height: 6, margin: const EdgeInsets.only(bottom: 32), decoration: BoxDecoration(color: colorScheme.onSurface.withOpacity(0.1), borderRadius: BorderRadius.circular(3))),
          Container(padding: const EdgeInsets.all(20), decoration: BoxDecoration(color: colorScheme.primary.withOpacity(0.1), shape: BoxShape.circle), child: Icon(Icons.auto_awesome_rounded, color: colorScheme.primary, size: 40)),
          const SizedBox(height: 24),
          Text(title, style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w900)),
          const SizedBox(height: 40),
          ElevatedButton(onPressed: () => Navigator.pop(context), style: ElevatedButton.styleFrom(minimumSize: const Size.fromHeight(64), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20))), child: const Text('GOT IT')),
        ]),
      ),
    );
  }
}
