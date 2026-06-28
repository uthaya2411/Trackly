import 'dart:ui';
import 'package:flutter/material.dart';
import '../../core/constants/colors.dart';

class GlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final double borderRadius;
  final double blurSigma;
  final Color? customColor;
  final Border? customBorder;
  final List<BoxShadow>? customShadows;

  const GlassCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(20.0),
    this.borderRadius = 24.0,
    this.blurSigma = 16.0,
    this.customColor,
    this.customBorder,
    this.customShadows,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Choose dynamic background card coloring based on dark mode settings
    final defaultBgColor = isDark
        ? AppColors.darkCard.withOpacity(0.65)
        : AppColors.lightCard.withOpacity(0.8);

    final defaultBorderColor = isDark
        ? Colors.white.withOpacity(0.06)
        : Colors.black.withOpacity(0.06);

    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blurSigma, sigmaY: blurSigma),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            color: customColor ?? defaultBgColor,
            borderRadius: BorderRadius.circular(borderRadius),
            border:
                customBorder ??
                Border.all(color: defaultBorderColor, width: 1.2),
            boxShadow:
                customShadows ??
                [
                  BoxShadow(
                    color: Colors.black.withOpacity(isDark ? 0.25 : 0.04),
                    blurRadius: 24,
                    spreadRadius: -4,
                    offset: const Offset(0, 8),
                  ),
                ],
          ),
          child: child,
        ),
      ),
    );
  }
}
