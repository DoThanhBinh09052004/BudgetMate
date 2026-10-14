import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:bugdetmate/features/home/screens/home_screen.dart';
import 'package:bugdetmate/core/theme/app_theme.dart';

void main() {
  testWidgets('BudgetMateApp smoke test renders home screen', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.darkTheme,
        home: const HomeScreen(
          initialTotalBalance: 0.0,
          initialRecentTransactions: [],
        ),
      ),
    );

    await tester.pump();

    expect(find.text('BudgetMate'), findsOneWidget);
  });
}
