import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';
import '../../widgets/app_primary_button.dart';
import '../../widgets/app_text_field.dart';
import 'auth_models.dart';
import 'auth_service.dart';
import 'auth_validators.dart';

class RegisterPage extends StatefulWidget {
  final AuthService authService;
  final Future<void> Function(DemoUser user) onRegistered;
  final VoidCallback onLoginTap;

  const RegisterPage({
    super.key,
    required this.authService,
    required this.onRegistered,
    required this.onLoginTap,
  });

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _regionController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _isSubmitting = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  @override
  void dispose() {
    _nameController.dispose();
    _regionController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
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
      final user = await widget.authService.register(
        RegisterRequest(
          name: _nameController.text,
          region: _regionController.text,
          email: _emailController.text,
          password: _passwordController.text,
        ),
      );
      await widget.onRegistered(user);
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
              constraints: const BoxConstraints(maxWidth: 460),
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
                        Text(
                          'Create account',
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.headlineMedium,
                        ),
                        const SizedBox(height: AppSpacing.x2),
                        Text(
                          'Set up your AgriSentinel demo profile',
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                        const SizedBox(height: AppSpacing.x5),
                        AppTextField(
                          controller: _nameController,
                          label: 'Full name',
                          icon: Icons.person_outline,
                          validator: (value) => AuthValidators.requiredField(
                            value,
                            label: 'Name',
                          ),
                        ),
                        const SizedBox(height: AppSpacing.x3),
                        AppTextField(
                          controller: _regionController,
                          label: 'Region',
                          icon: Icons.location_on_outlined,
                          validator: (value) => AuthValidators.requiredField(
                            value,
                            label: 'Region',
                          ),
                        ),
                        const SizedBox(height: AppSpacing.x3),
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
                        const SizedBox(height: AppSpacing.x3),
                        AppTextField(
                          controller: _confirmPasswordController,
                          label: 'Confirm password',
                          icon: Icons.lock_reset_outlined,
                          obscureText: _obscureConfirmPassword,
                          validator: (value) => AuthValidators.confirmPassword(
                            value,
                            _passwordController.text,
                          ),
                          suffixIcon: IconButton(
                            onPressed: () {
                              setState(() {
                                _obscureConfirmPassword =
                                    !_obscureConfirmPassword;
                              });
                            },
                            icon: Icon(
                              _obscureConfirmPassword
                                  ? Icons.visibility_off
                                  : Icons.visibility,
                            ),
                          ),
                        ),
                        const SizedBox(height: AppSpacing.x5),
                        AppPrimaryButton(
                          onPressed: _isSubmitting ? null : _submit,
                          isLoading: _isSubmitting,
                          label: 'Register',
                          icon: Icons.person_add_alt_1,
                        ),
                        const SizedBox(height: AppSpacing.x3),
                        TextButton(
                          onPressed: _isSubmitting ? null : widget.onLoginTap,
                          child: const Text('Already have an account? Login'),
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
