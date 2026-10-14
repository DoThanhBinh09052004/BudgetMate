import 'package:flutter/material.dart';
import 'package:bugdetmate/core/theme/app_theme.dart';
import 'package:bugdetmate/core/widgets/app_widgets.dart';

/// Bottom sheet hiển thị thông tin giới thiệu và bảo mật của BudgetMate.
class AboutBottomSheet extends StatelessWidget {
  const AboutBottomSheet({super.key});

  static Future<void> show(BuildContext context) {
    return AppBottomSheet.show(
      context: context,
      showDragHandle: false,
      builder: (_) => const AboutBottomSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.white24,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 20),
          const AppLogo(size: 72, borderRadius: 16, showShadow: true),
          const SizedBox(height: 14),
          const Text(
            'BudgetMate',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Phiên bản 1.0.0 (Build 1)',
            style: TextStyle(
              fontSize: 13,
              color: AppTheme.textMutedDark,
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppTheme.darkSurfaceVariant,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.white12),
            ),
            child: const Column(
              children: [
                Row(
                  children: [
                    Icon(Icons.lock_outline_rounded, size: 18, color: AppTheme.successGreen),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '100% Offline & Bảo mật: Toàn bộ dữ liệu tài chính lưu trên máy của bạn.',
                        style: TextStyle(fontSize: 13, color: Colors.white),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.bolt_rounded, size: 18, color: AppTheme.warningAmber),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Tự động bắt biến động số dư SMS / Notification ngân hàng thông minh.',
                        style: TextStyle(fontSize: 13, color: Colors.white),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          AppPrimaryButton(
            label: 'Đóng',
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }
}
