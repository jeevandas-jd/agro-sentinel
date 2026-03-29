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

class _LoginPageState extends State<LoginPage>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _isSubmitting = false;

  late AnimationController _entryController;
  late Animation<double> _logoScale;
  late Animation<double> _formFade;
  late Animation<Offset> _formSlide;

  @override
  void initState() {
    super.initState();
    _entryController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..forward();

    _logoScale = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(
        parent: _entryController,
        curve: const Interval(0.0, 0.5, curve: Curves.elasticOut),
      ),
    );
    _formFade = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _entryController,
        curve: const Interval(0.3, 1.0, curve: Curves.easeOut),
      ),
    );
    _formSlide = Tween<Offset>(
      begin: const Offset(0, 0.2),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _entryController,
        curve: const Interval(0.3, 1.0, curve: Curves.easeOutCubic),
      ),
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
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
      body: Stack(
        children: [
          // Top green accent blob
          Positioned(
            top: -60,
            right: -40,
            child: Container(
              width: 220,
              height: 220,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.primaryLight.withValues(alpha: 0.30),
              ),
            ),
          ),
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(AppSpacing.x5),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 420),
                  child: Column(
                    children: [
                      // Logo
                      ScaleTransition(
                        scale: _logoScale,
                        child: Container(
                          width: 72,
                          height: 72,
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            shape: BoxShape.circle,
                            boxShadow: AppShadows.raised,
                          ),
                          child: const Icon(
                            Icons.eco_rounded,
                            color: Colors.white,
                            size: 36,
                          ),
                        ),
                      ),

                      const SizedBox(height: AppSpacing.x5),

                      // Form card
                      FadeTransition(
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
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: [
                                    const Text(
                                      'Welcome back',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        color: AppColors.textPrimary,
                                        fontSize: 26,
                                        fontWeight: FontWeight.w800,
                                        letterSpacing: -0.4,
                                      ),
                                    ),
                                    const SizedBox(height: AppSpacing.x1),
                                    const Text(
                                      'Sign in to continue',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        color: AppColors.textMuted,
                                        fontSize: 14,
                                      ),
                                    ),
                                    const SizedBox(height: AppSpacing.x6),
                                    AppTextField(
                                      controller: _emailController,
                                      label: 'Email',
                                      icon: Icons.email_outlined,
                                      hintText: 'name@example.com',
                                      keyboardType:
                                          TextInputType.emailAddress,
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
                                            _obscurePassword =
                                                !_obscurePassword;
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
                                    const SizedBox(height: AppSpacing.x6),
                                    AppPrimaryButton(
                                      onPressed:
                                          _isSubmitting ? null : _submit,
                                      isLoading: _isSubmitting,
                                      label: 'Login',
                                      icon: Icons.login_rounded,
                                    ),
                                    const SizedBox(height: AppSpacing.x3),
                                    OutlinedButton(
                                      onPressed: _isSubmitting
                                          ? null
                                          : widget.onRegisterTap,
                                      child:
                                          const Text('Create account'),
                                    ),
                                    const SizedBox(height: AppSpacing.x4),
                                    Container(
                                      padding: const EdgeInsets.all(
                                          AppSpacing.x3),
                                      decoration: BoxDecoration(
                                        color: AppColors.oliveLight,
                                        borderRadius: BorderRadius.circular(
                                            AppRadii.s),
                                      ),
                                      child: const Text(
                                        '🌱  Demo: demo@agrisentinel.app / demo123',
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                          color: AppColors.primaryDark,
                                          fontSize: 11,
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
                    ],
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
