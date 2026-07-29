import 'dart:ui';
import 'package:flutter/material.dart';
import '../../core/theme/colors.dart';

/// Một Widget Container hiệu ứng kính mờ (Glassmorphism) với đường viền mờ ảo phong cách Neon.
class GlassContainer extends StatelessWidget {
  final Widget child;
  final double borderRadius;
  final Color? borderColor;
  final Color? backgroundColor;
  final double? width;
  final double? height;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;

  const GlassContainer({
    Key? key,
    required this.child,
    this.borderRadius = 16.0,
    this.borderColor,
    this.backgroundColor,
    this.width,
    this.height,
    this.padding,
    this.margin,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      margin: margin,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(borderRadius),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 15,
            spreadRadius: 2,
            offset: const Offset(0, 5),
          )
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12.0, sigmaY: 12.0),
          child: Container(
            padding: padding ?? const EdgeInsets.all(16.0),
            decoration: BoxDecoration(
              color: backgroundColor ?? AppColors.cardBg,
              borderRadius: BorderRadius.circular(borderRadius),
              border: Border.all(
                color: borderColor ?? AppColors.cardBorder,
                width: 1.5,
              ),
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}
