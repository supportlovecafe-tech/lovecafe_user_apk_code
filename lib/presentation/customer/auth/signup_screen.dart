import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/providers/auth_provider.dart';

class SignupScreen extends ConsumerStatefulWidget {
  const SignupScreen({super.key});

  @override
  ConsumerState<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends ConsumerState<SignupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailOrPhoneController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _acceptedTerms = false;

  Future<void> _signUp() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    if (!_acceptedTerms) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content:
                Text('Please accept the Terms & Privacy Policy to continue')),
      );
      return;
    }
    final firstName = _firstNameController.text.trim();
    final lastName = _lastNameController.text.trim();
    final emailOrPhone = _emailOrPhoneController.text.trim();
    final password = _passwordController.text.trim();

    setState(() => _isLoading = true);
    try {
      String email = emailOrPhone;
      // If it's a phone number (doesn't contain '@'), convert to proxy email for auth
      if (!email.contains('@')) {
        final phone = emailOrPhone.replaceAll(RegExp(r'\D'), '');
        email = '$phone@lovecafe.local';
      }

      await ref.read(authProvider.notifier).signUpWithEmail(
            firstName: firstName,
            lastName: lastName,
            email: email,
            password: password,
          );

      if (!mounted) return;
      context.go('/'); // go home
    } on AuthException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.message)),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.toString().replaceAll('Exception: ', ''))),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _signUpWithGoogle() async {
    if (!_acceptedTerms) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content:
                Text('Please accept the Terms & Privacy Policy to continue')),
      );
      return;
    }
    setState(() => _isLoading = true);
    try {
      await ref.read(authProvider.notifier).signInWithGoogle();
      if (!mounted) return;
      context.go('/'); // go home
    } on AuthException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.message)),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.toString().replaceAll('Exception: ', ''))),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 32.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 12),
              Text(
                'CREATE ACCOUNT',
                style: theme.textTheme.displaySmall?.copyWith(
                  fontWeight: FontWeight.w900,
                  letterSpacing: -1,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Join the premium cinematic dining experience.',
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: colorScheme.onSurface.withValues(alpha: 0.6),
                ),
              ),
              const SizedBox(height: 32),
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: colorScheme.surface,
                  borderRadius: BorderRadius.circular(32),
                  border: Border.all(
                      color: colorScheme.outline.withValues(alpha: 0.1)),
                ),
                child: Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      _buildInputField(
                        label: 'FIRST NAME',
                        controller: _firstNameController,
                        hint: 'John',
                        icon: Icons.person_outline_rounded,
                        validator: (value) =>
                            value == null || value.trim().isEmpty
                                ? 'Please enter your first name'
                                : null,
                      ),
                      const SizedBox(height: 20),
                      _buildInputField(
                        label: 'LAST NAME',
                        controller: _lastNameController,
                        hint: 'Doe',
                        icon: Icons.person_outline_rounded,
                        validator: (value) =>
                            value == null || value.trim().isEmpty
                                ? 'Please enter your last name'
                                : null,
                      ),
                      const SizedBox(height: 20),
                      _buildInputField(
                        label: 'EMAIL OR PHONE',
                        controller: _emailOrPhoneController,
                        hint: 'user@example.com or 9876543210',
                        icon: Icons.contact_mail_rounded,
                        keyboardType: TextInputType.emailAddress,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty)
                            return 'Please enter email or phone';
                          final isEmail = value.contains('@');
                          if (isEmail) {
                            if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$')
                                .hasMatch(value)) {
                              return 'Please enter a valid email';
                            }
                          } else {
                            if (!RegExp(r'^\d{10}$').hasMatch(value.trim())) {
                              return 'Please enter a valid 10-digit phone number';
                            }
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 20),
                      _buildInputField(
                        label: 'PASSWORD',
                        controller: _passwordController,
                        hint: '••••••••',
                        icon: Icons.lock_outline_rounded,
                        obscureText: true,
                        validator: (value) => value == null || value.length < 6
                            ? 'Password must be at least 6 characters'
                            : null,
                      ),
                      const SizedBox(height: 20),
                      Row(
                        children: [
                          Checkbox(
                            value: _acceptedTerms,
                            onChanged: (value) {
                              setState(() {
                                _acceptedTerms = value ?? false;
                              });
                            },
                            activeColor: colorScheme.primary,
                          ),
                          Expanded(
                            child: Text(
                              'I accept the Terms & Conditions and Privacy Policy',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: colorScheme.onSurface
                                    .withValues(alpha: 0.7),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: _isLoading ? null : _signUp,
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size.fromHeight(72),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24)),
                ),
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('SIGN UP',
                        style: TextStyle(
                            fontWeight: FontWeight.w900, letterSpacing: 2)),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                      child: Divider(
                          color: colorScheme.outline.withValues(alpha: 0.1))),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Text(
                      'OR CONTINUE WITH',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: colorScheme.onSurface.withValues(alpha: 0.3),
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.5,
                      ),
                    ),
                  ),
                  Expanded(
                      child: Divider(
                          color: colorScheme.outline.withValues(alpha: 0.1))),
                ],
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: _isLoading ? null : _signUpWithGoogle,
                icon: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    'G',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                      color: Colors.blue.shade600,
                    ),
                  ),
                ),
                label: const Text('Sign in with Google'),
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size.fromHeight(72),
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.black87,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24),
                    side: BorderSide(color: Colors.grey.shade300),
                  ),
                  elevation: 0,
                  textStyle: theme.textTheme.labelLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Center(
                child: TextButton(
                  onPressed: () => context.go('/login'),
                  child: RichText(
                    text: TextSpan(
                      text: "Already have an account? ",
                      style: theme.textTheme.bodyMedium?.copyWith(
                          color: colorScheme.onSurface.withValues(alpha: 0.5)),
                      children: [
                        TextSpan(
                          text: 'SIGN IN',
                          style: TextStyle(
                              color: colorScheme.primary,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 1),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () {
                  ref.read(authProvider.notifier).loginAsGuest();
                  context.go('/home');
                },
                style: TextButton.styleFrom(
                  foregroundColor: colorScheme.onSurface.withValues(alpha: 0.6),
                ),
                child: const Text(
                  'CONTINUE AS GUEST',
                  style:
                      TextStyle(fontWeight: FontWeight.w900, letterSpacing: 2),
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInputField({
    required String label,
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    TextInputType? keyboardType,
    bool obscureText = false,
    String? Function(String?)? validator,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: theme.textTheme.labelSmall?.copyWith(
            fontWeight: FontWeight.w900,
            letterSpacing: 2,
            color: colorScheme.primary,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          obscureText: obscureText,
          validator: validator,
          autovalidateMode: AutovalidateMode.onUserInteraction,
          style: const TextStyle(fontWeight: FontWeight.bold),
          decoration: InputDecoration(
            hintText: hint,
            prefixIcon: Icon(icon,
                size: 20, color: colorScheme.primary.withValues(alpha: 0.5)),
            filled: true,
            fillColor: colorScheme.onSurface.withValues(alpha: 0.03),
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(20),
                borderSide: BorderSide.none),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
          ),
        ),
      ],
    );
  }
}
