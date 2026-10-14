import 'package:flutter/material.dart';
import 'package:bugdetmate/core/theme/app_theme.dart';
import 'package:bugdetmate/core/theme/app_radius.dart';

/// Nút chính (Primary Action) chuẩn FinTech với hỗ trợ Loading và Disabled.
class AppPrimaryButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool isLoading;
  final bool isFullWidth;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final EdgeInsetsGeometry padding;

  const AppPrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.isLoading = false,
    this.isFullWidth = true,
    this.backgroundColor,
    this.foregroundColor,
    this.padding = const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
  });

  @override
  Widget build(BuildContext context) {
    final effectiveBg = backgroundColor ?? AppTheme.primaryEmerald;
    final effectiveFg = foregroundColor ?? Colors.white;

    final child = isLoading
        ? SizedBox(
            height: 20,
            width: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2.2,
              valueColor: AlwaysStoppedAnimation<Color>(effectiveFg),
            ),
          )
        : Row(
            mainAxisSize: isFullWidth ? MainAxisSize.max : MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (icon != null) ...[
                Icon(icon, size: 18, color: effectiveFg),
                const SizedBox(width: 8),
              ],
              Text(
                label,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: effectiveFg,
                ),
              ),
            ],
          );

    final button = ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: effectiveBg,
        foregroundColor: effectiveFg,
        disabledBackgroundColor: effectiveBg.withAlpha(100),
        disabledForegroundColor: effectiveFg.withAlpha(150),
        padding: padding,
        elevation: 0,
        shape: const RoundedRectangleBorder(borderRadius: AppRadius.mdRadius),
      ),
      onPressed: isLoading ? null : onPressed,
      child: child,
    );

    if (isFullWidth) {
      return SizedBox(width: double.infinity, child: button);
    }
    return button;
  }
}

/// Nút phụ (Secondary/Outlined) chuẩn theme.
class AppSecondaryButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool isFullWidth;
  final Color? borderColor;
  final Color? foregroundColor;

  const AppSecondaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.isFullWidth = true,
    this.borderColor,
    this.foregroundColor,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveFg = foregroundColor ?? Colors.white;
    final effectiveBorder = borderColor ?? AppTheme.darkBorder;

    final button = OutlinedButton(
      style: OutlinedButton.styleFrom(
        foregroundColor: effectiveFg,
        side: BorderSide(color: effectiveBorder, width: 1.2),
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
        shape: const RoundedRectangleBorder(borderRadius: AppRadius.mdRadius),
      ),
      onPressed: onPressed,
      child: Row(
        mainAxisSize: isFullWidth ? MainAxisSize.max : MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 18, color: effectiveFg),
            const SizedBox(width: 8),
          ],
          Text(
            label,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: effectiveFg,
            ),
          ),
        ],
      ),
    );

    if (isFullWidth) {
      return SizedBox(width: double.infinity, child: button);
    }
    return button;
  }
}

/// Nút Icon chuẩn touch target.
class AppIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onPressed;
  final String? tooltip;
  final Color? color;
  final Color? backgroundColor;
  final double size;

  const AppIconButton({
    super.key,
    required this.icon,
    required this.onPressed,
    this.tooltip,
    this.color,
    this.backgroundColor,
    this.size = 20,
  });

  @override
  Widget build(BuildContext context) {
    Widget button = IconButton(
      tooltip: tooltip,
      icon: Icon(icon, size: size, color: color ?? Colors.white),
      onPressed: onPressed,
    );

    if (backgroundColor != null) {
      button = Ink(
        decoration: ShapeDecoration(
          color: backgroundColor,
          shape: const CircleBorder(),
        ),
        child: button,
      );
    }

    return button;
  }
}
