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

class _RegisterPageState extends State<RegisterPage>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _regionController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _isSubmitting = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  late AnimationController _entryController;
  late Animation<double> _formFade;
  late Animation<Offset> _formSlide;

  @override
  void initState() {
    super.initState();
    _entryController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    )..forward();

    _formFade = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _entryController, curve: Curves.easeOut),
    );
    _formSlide = Tween<Offset>(
      begin: const Offset(0, 0.15),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _entryController, curve: Curves.easeOutCubic),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _regionController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _entryController.dispose();
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
      body: Stack(
        children: [
          // Top left circle decoration
          Positioned(
            top: -80,
            left: -50,
            child: Container(
              width: 240,
              height: 240,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.primaryLight.withValues(alpha: 0.25),
              ),
            ),
          ),
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(AppSpacing.x5),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 460),
                  child: FadeTransition(
                    opacity: _formFade,
                    child: SlideTransition(
                      position: _formSlide,
                      child: Container(
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(AppRadii.xl),
                          boxShadow: AppShadows.card,
                          border: Border.all(color: AppColors.border),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(AppSpacing.x6),
                          child: Form(
                            key: _formKey,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      width: 40,
                                      height: 40,
                                      decoration: BoxDecoration(
                                        color: AppColors.oliveLight,
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(
                                        Icons.eco_rounded,
                                        color: AppColors.primaryDark,
                                        size: 20,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    const Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Create account',
                                          style: TextStyle(
                                            color: AppColors.textPrimary,
                                            fontSize: 20,
                                            fontWeight: FontWeight.w800,
                                            letterSpacing: -0.3,
                                          ),
                                        ),
                                        Text(
                                          'Set up your AgriSentinel profile',
                                          style: TextStyle(
                                            color: AppColors.textMuted,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                                const SizedBox(height: AppSpacing.x6),
                                AppTextField(
                                  controller: _nameController,
                                  label: 'Full name',
                                  icon: Icons.person_outline_rounded,
                                  validator: (value) =>
                                      AuthValidators.requiredField(
                                    value,
                                    label: 'Name',
                                  ),
                                ),
                                const SizedBox(height: AppSpacing.x3),
                                AppTextField(
                                  controller: _regionController,
                                  label: 'Region',
                                  icon: Icons.location_on_outlined,
                                  validator: (value) =>
                                      AuthValidators.requiredField(
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
                                          ? Icons.visibility_off_outlined
                                          : Icons.visibility_outlined,
                                      color: AppColors.textMuted,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: AppSpacing.x3),
                                AppTextField(
                                  controller: _confirmPasswordController,
                                  label: 'Confirm password',
                                  icon: Icons.lock_reset_outlined,
                                  obscureText: _obscureConfirmPassword,
                                  validator: (value) =>
                                      AuthValidators.confirmPassword(
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
                                          ? Icons.visibility_off_outlined
                                          : Icons.visibility_outlined,
                                      color: AppColors.textMuted,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: AppSpacing.x6),
                                AppPrimaryButton(
                                  onPressed: _isSubmitting ? null : _submit,
                                  isLoading: _isSubmitting,
                                  label: 'Register',
                                  icon: Icons.person_add_alt_1_rounded,
                                ),
                                const SizedBox(height: AppSpacing.x3),
                                TextButton(
                                  onPressed:
                                      _isSubmitting ? null : widget.onLoginTap,
                                  child: const Text(
                                    'Already have an account? Login',
                                    style: TextStyle(
                                      color: AppColors.primary,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
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
            ),
          ),
        ],
      ),
    );
  }
}
