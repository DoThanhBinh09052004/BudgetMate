import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:bugdetmate/core/theme/app_theme.dart';

void main() {
  test(
    'AppTheme should have FinTech Emerald Green and Dark Charcoal palette',
    () {
      expect(AppTheme.primaryGreen, const Color(0xFF10B981));
      expect(AppTheme.expenseRed, const Color(0xFFF87171));
      expect(AppTheme.incomeGreen, const Color(0xFF34D399));
      expect(AppTheme.darkBackground, const Color(0xFF121212));
      expect(AppTheme.darkSurface, const Color(0xFF1E1E1E));
      expect(AppTheme.darkBorder, const Color(0xFF2E2E2E));
    },
  );
}
