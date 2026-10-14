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
        {
          'id': 3,
          'wallet_id': 1,
          'category_id': 2,
          'amount': 25000.0,
          'type': 'expense',
          'transaction_date': nowSeconds - 7200,
          'note': '', // Empty string note should NOT cause blank title
          'category_name': 'Di chuyển',
          'parent_name': null,
          'category_icon': 'car',
          'category_color': '#0EA5E9',
        },
        {
          'id': 4,
          'wallet_id': 1,
          'category_id': null,
          'amount': 15000.0,
          'type': 'expense',
          'transaction_date': nowSeconds - 10800,
          'note': 'Gửi xe bệnh viện',
          'category_name': null,
          'parent_name': null,
          'category_icon': null,
          'category_color': null,
        },
        {
          'id': 5,
          'wallet_id': 1,
          'category_id': null,
          'amount': 10000.0,
          'type': 'expense',
          'transaction_date': nowSeconds - 14400,
          'note': '   ', // Blank whitespace note without category should fallback to 'Chi tiêu'
          'category_name': null,
          'parent_name': null,
          'category_icon': null,
          'category_color': null,
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
        find.textContaining('155.000'),
        findsOneWidget,
      ); // Day total = 35k + 70k + 25k + 15k + 10k = 155k

      // 2. Verify Category Title formatting: "Ăn uống › Trà sữa" and "Ăn uống" and "Di chuyển"
      expect(find.text('Ăn uống › Trà sữa'), findsOneWidget);
      expect(find.text('Ăn uống'), findsOneWidget);
      expect(find.text('Di chuyển'), findsOneWidget);

      // 3. Verify Note-as-title when category is null: "Gửi xe bệnh viện"
      expect(find.text('Gửi xe bệnh viện'), findsOneWidget);

      // 4. Verify Fallback title 'Chi tiêu' when note is blank whitespace and category is null
      expect(find.text('Chi tiêu'), findsOneWidget);

      // 5. Verify Notes are shown in subtitles
      expect(find.textContaining('ToCoToCo trân châu'), findsOneWidget);
      expect(find.textContaining('Cơm sườn'), findsOneWidget);
    },
  );
}
