import 'package:flutter/material.dart';
import 'package:bugdetmate/core/constants/app_constants.dart';
import 'package:bugdetmate/core/theme/app_theme.dart';

/// Component hiển thị logo thương hiệu BudgetMate với kích thước tùy chỉnh và hiệu ứng bo góc.
class AppLogo extends StatelessWidget {
  final double size;
  final double borderRadius;
  final bool showShadow;

  const AppLogo({
    super.key,
    this.size = 32.0,
    this.borderRadius = 8.0,
    this.showShadow = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(borderRadius),
        boxShadow: showShadow
            ? [
                BoxShadow(
                  color: AppTheme.primaryBlue.withAlpha(50),
                  blurRadius: 10,
                  spreadRadius: 1,
                  offset: const Offset(0, 2),
                ),
              ]
            : null,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: Image.asset(
          AppConstants.appLogo,
          width: size,
          height: size,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) => Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              color: AppTheme.primaryBlue.withAlpha(40),
              borderRadius: BorderRadius.circular(borderRadius),
            ),
            child: Icon(
              Icons.wallet_rounded,
              color: AppTheme.primaryBlue,
              size: size * 0.6,
            ),
          ),
        ),
      ),
    );
  }
}
