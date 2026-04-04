import 'dart:ui';

import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

class GlassPanel extends StatefulWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final BorderRadius borderRadius;
  final VoidCallback? onTap;
  final double blurSigma;
  final Color? tintColor;
  final Gradient? gradient;

  const GlassPanel({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(AppSpacing.x4),
    this.borderRadius = const BorderRadius.all(Radius.circular(AppRadii.l)),
    this.onTap,
    this.blurSigma = 12,
    this.tintColor,
    this.gradient,
  });

  @override
  State<GlassPanel> createState() => _GlassPanelState();
}

class _GlassPanelState extends State<GlassPanel> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final panel = ClipRRect(
      borderRadius: widget.borderRadius,
      child: BackdropFilter(
        filter: ImageFilter.blur(
          sigmaX: widget.blurSigma,
          sigmaY: widget.blurSigma,
        ),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOut,
          padding: widget.padding,
          decoration: BoxDecoration(
            color: widget.tintColor ?? Colors.white.withValues(alpha: 0.82),
            gradient: widget.gradient,
            borderRadius: widget.borderRadius,
            border: Border.all(color: AppColors.border),
            boxShadow: [
              BoxShadow(
                color: Colors.white.withValues(alpha: 0.6),
                blurRadius: 10,
                offset: const Offset(-2, -2),
              ),
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.08),
                blurRadius: 16,
                offset: const Offset(4, 8),
              ),
            ],
          ),
          child: widget.child,
        ),
      ),
    );

    if (widget.onTap == null) {
      return panel;
    }

    return AnimatedScale(
      duration: const Duration(milliseconds: 140),
      curve: Curves.easeOut,
      scale: _pressed ? 0.97 : 1.0,
      child: GestureDetector(
        onTap: widget.onTap,
        onTapDown: (_) => setState(() => _pressed = true),
        onTapUp: (_) => setState(() => _pressed = false),
        onTapCancel: () => setState(() => _pressed = false),
        child: panel,
      ),
    );
  }
}
