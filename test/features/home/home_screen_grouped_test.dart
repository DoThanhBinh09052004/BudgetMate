import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:bugdetmate/features/home/screens/home_screen.dart';
import 'package:bugdetmate/core/theme/app_theme.dart';

void main() {
  testWidgets(
    'HomeScreen groups recent transactions by date and displays category details',
    (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final now = DateTime(2026, 10, 14, 15, 30);
      final nowSeconds = now.millisecondsSinceEpoch ~/ 1000;

      final mockRecentTransactions = [
        {
          'id': 1,
          'wallet_id': 1,
          'category_id': 10,
          'amount': 35000.0,
          'type': 'expense',
          'transaction_date': nowSeconds,
          'note': 'ToCoToCo trân châu',
          'category_name': 'Trà sữa',
          'parent_name': 'Ăn uống',
          'category_icon': 'coffee',
          'category_color': '#F97316',
        },
        {
          'id': 2,
          'wallet_id': 1,
          'category_id': 1,
          'amount': 70000.0,
          'type': 'expense',
          'transaction_date': nowSeconds - 3600, // 1 hour earlier
          'note': 'Cơm sườn',
          'category_name': 'Ăn uống',
          'parent_name': null,
          'category_icon': 'utensils',
          'category_color': '#F97316',
        },
      ];

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.darkTheme,
          home: HomeScreen(
            initialTotalBalance: 2000000.0,
            initialRecentTransactions: mockRecentTransactions,
          ),
        ),
      );

      await tester.pump();

      // 1. Verify Date Header is present
      expect(find.text('14'), findsOneWidget); // Day number 14
      expect(
        find.textContaining('105.000'),
        findsOneWidget,
      ); // Day total = 35k + 70k = 105k

      // 2. Verify Category Title formatting: "Ăn uống › Trà sữa" and "Ăn uống"
      expect(find.text('Ăn uống › Trà sữa'), findsOneWidget);
      expect(find.text('Ăn uống'), findsOneWidget);

      // 3. Verify Notes are shown in subtitles
      expect(find.textContaining('ToCoToCo trân châu'), findsOneWidget);
      expect(find.textContaining('Cơm sườn'), findsOneWidget);
    },
  );
}
