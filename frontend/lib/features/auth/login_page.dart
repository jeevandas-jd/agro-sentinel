import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';
import '../../widgets/app_primary_button.dart';
import '../../widgets/app_text_field.dart';
import 'auth_models.dart';
import 'auth_service.dart';
import 'auth_validators.dart';

class LoginPage extends StatefulWidget {
  final AuthService authService;
  final Future<void> Function(DemoUser user) onLoggedIn;
  final VoidCallback onRegisterTap;

  const LoginPage({
    super.key,
    required this.authService,
    required this.onLoggedIn,
    required this.onRegisterTap,
  });

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false) || _isSubmitting) {
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      final user = await widget.authService.login(
        LoginRequest(
          email: _emailController.text,
          password: _passwordController.text,
        ),
      );
      await widget.onLoggedIn(user);
    } on AuthException catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.message)));
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.x5),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(AppRadii.xl),
                  gradient: LinearGradient(
                    colors: [
                      AppColors.cardBright.withValues(alpha: 0.95),
                      AppColors.card.withValues(alpha: 0.95),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  border: Border.all(color: AppColors.border),
                  boxShadow: AppShadows.raised,
                ),
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.x5),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Container(
                          width: 56,
                          height: 56,
                          decoration: BoxDecoration(
                            color: AppColors.accent.withValues(alpha: 0.18),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.satellite_alt,
                            color: AppColors.oliveLight,
                            size: 28,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.x3),
                        Text(
                          'Welcome back',
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.headlineMedium,
                        ),
                        const SizedBox(height: AppSpacing.x1),
                        Text(
                          'Sign in to continue',
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                        const SizedBox(height: AppSpacing.x5),
                        AppTextField(
                          controller: _emailController,
                          label: 'Email',
                          icon: Icons.email_outlined,
                          hintText: 'name@example.com',
                          keyboardType: TextInputType.emailAddress,
                          validator: AuthValidators.email,
                        ),
                        const SizedBox(height: AppSpacing.x3),
                        AppTextField(
                          controller: _passwordController,
                          label: 'Password',
                          icon: Icons.lock_outline,
                          obscureText: _obscurePassword,
                          validator: AuthValidators.password,
                          suffixIcon: IconButton(
                            onPressed: () {
                              setState(() {
                                _obscurePassword = !_obscurePassword;
                              });
                            },
                            icon: Icon(
                              _obscurePassword
                                  ? Icons.visibility_off
                                  : Icons.visibility,
                            ),
                          ),
                        ),
                        const SizedBox(height: AppSpacing.x5),
                        AppPrimaryButton(
                          onPressed: _isSubmitting ? null : _submit,
                          isLoading: _isSubmitting,
                          label: 'Login',
                          icon: Icons.login,
                        ),
                        const SizedBox(height: AppSpacing.x3),
                        OutlinedButton(
                          onPressed: _isSubmitting
                              ? null
                              : widget.onRegisterTap,
                          child: const Text('Create account'),
                        ),
                        const SizedBox(height: AppSpacing.x4),
                        Text(
                          'Demo account: demo@agrisentinel.app / demo123',
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
