import 'dart:convert';
import 'package:flutter/material.dart';
import '../../app/theme/app_colors.dart';

class AppIconView extends StatelessWidget {
  final String? base64Icon;
  final double size;
  final String? fallbackLetter;

  const AppIconView({
    super.key,
    this.base64Icon,
    this.size = 44,
    this.fallbackLetter,
  });

  @override
  Widget build(BuildContext context) {
    if (base64Icon != null && base64Icon!.isNotEmpty) {
      try {
        final bytes = base64Decode(base64Icon!);
        return ClipRRect(
          borderRadius: BorderRadius.circular(size * 0.25),
          child: Image.memory(
            bytes,
            width: size,
            height: size,
            fit: BoxFit.cover,
            errorBuilder: (_, error, stackTrace) => _buildFallback(context),
          ),
        );
      } catch (_) {
        return _buildFallback(context);
      }
    }
    return _buildFallback(context);
  }

  Widget _buildFallback(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final letter = (fallbackLetter != null && fallbackLetter!.isNotEmpty)
        ? fallbackLetter![0].toUpperCase()
        : 'E';

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkElevated : AppColors.lightElevated,
        borderRadius: BorderRadius.circular(size * 0.25),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
          width: 1,
        ),
      ),
      alignment: Alignment.center,
      child: Text(
        letter,
        style: TextStyle(
          color: isDark ? AppColors.darkAccent : AppColors.lightAccent,
          fontSize: size * 0.45,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
