import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class AppPrimaryButton extends StatefulWidget {
  final VoidCallback? onPressed;
  final bool isLoading;
  final String label;
  final IconData? icon;

  const AppPrimaryButton({
    super.key,
    required this.onPressed,
    this.isLoading = false,
    required this.label,
    this.icon,
  });

  @override
  State<AppPrimaryButton> createState() => _AppPrimaryButtonState();
}

class _AppPrimaryButtonState extends State<AppPrimaryButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _pressController;
  late Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    _pressController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 120),
      reverseDuration: const Duration(milliseconds: 200),
      lowerBound: 0.95,
      upperBound: 1.0,
      value: 1.0,
    );
    _scaleAnim = _pressController;
  }

  @override
  void dispose() {
    _pressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDisabled = widget.onPressed == null;

    return GestureDetector(
      onTapDown: isDisabled
          ? null
          : (_) => _pressController.reverse(),
      onTapUp: isDisabled
          ? null
          : (_) {
              _pressController.forward();
              widget.onPressed?.call();
            },
      onTapCancel: isDisabled ? null : () => _pressController.forward(),
      child: AnimatedBuilder(
        animation: _scaleAnim,
        builder: (context, child) => Transform.scale(
          scale: _scaleAnim.value,
          child: child,
        ),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          height: 56,
          decoration: BoxDecoration(
            gradient: isDisabled
                ? null
                : const LinearGradient(
                    colors: [AppColors.accent, AppColors.primary],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
            color: isDisabled ? AppColors.border : null,
            borderRadius: BorderRadius.circular(AppRadii.m),
            boxShadow: isDisabled ? null : AppShadows.raised,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (widget.isLoading)
                const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    color: Colors.white,
                  ),
                )
              else ...[
                if (widget.icon != null) ...[
                  Icon(
                    widget.icon,
                    size: 18,
                    color: isDisabled ? AppColors.textMuted : Colors.white,
                  ),
                  const SizedBox(width: 8),
                ],
                Text(
                  widget.label,
                  style: TextStyle(
                    color: isDisabled ? AppColors.textMuted : Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                    letterSpacing: 0.3,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
