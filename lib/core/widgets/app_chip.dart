import 'package:flutter/material.dart';

import '../../app/theme/app_colors.dart';

class AppChip extends StatelessWidget {
  final String label;
  final Color? color;
  final Color? textColor;
  final EdgeInsetsGeometry? padding;
  final double? fontSize;
  final FontWeight? fontWeight;

  const AppChip({
    super.key,
    required this.label,
    this.color,
    this.textColor,
    this.padding,
    this.fontSize,
    this.fontWeight,
  });

  @override
  Widget build(BuildContext context) {
    final resolvedColor = color ?? AppColors.primary.withValues(alpha: 0.12);
    final resolvedTextColor = textColor ?? AppColors.primaryDark;

    return Container(
      padding: padding ??
          const EdgeInsets.symmetric(
            horizontal: 10,
            vertical: 7,
          ),
      decoration: BoxDecoration(
        color: resolvedColor,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: fontSize ?? 12,
          fontWeight: fontWeight ?? FontWeight.w700,
          color: resolvedTextColor,
        ),
      ),
    );
  }
}