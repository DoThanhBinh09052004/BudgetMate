import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:bugdetmate/core/theme/app_theme.dart';
import 'package:bugdetmate/features/transactions/screens/quick_add_sheet.dart';

void main() {
  testWidgets(
    'QuickAddSheet shows 2-tier cascade categories and saves transaction',
    (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final initialWallets = [
        {'id': 1, 'name': 'Tiền mặt', 'type': 'cash', 'balance': 500000.0},
      ];

      final initialCategories = [
        {
          'id': 1,
          'name': 'Ăn uống',
          'type': 'expense',
          'icon': 'utensils',
          'color': '#F97316',
          'parent_id': null,
        },
        {
          'id': 2,
          'name': 'Di chuyển',
          'type': 'expense',
          'icon': 'car',
          'color': '#0EA5E9',
          'parent_id': null,
        },
        {
          'id': 10,
          'name': 'Cơm trưa / tối',
          'type': 'expense',
          'icon': 'utensils',
          'color': '#F97316',
          'parent_id': 1,
        },
        {
          'id': 11,
          'name': 'Trà sữa & Cà phê',
          'type': 'expense',
          'icon': 'coffee',
          'color': '#F97316',
          'parent_id': 1,
        },
      ];

      Map<String, dynamic>? savedTx;

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.darkTheme,
          home: Scaffold(
            body: SingleChildScrollView(
              child: QuickAddSheet(
                initialWallets: initialWallets,
                initialCategories: initialCategories,
                onSaveTransaction: (tx) async => savedTx = tx,
                onSaved: () {},
              ),
            ),
          ),
        ),
      );

      await tester.pump();

      // 1. Verify parent category "Ăn uống" is visible
      expect(find.text('Ăn uống'), findsOneWidget);

      // 2. Tap parent category "Ăn uống"
      await tester.tap(find.text('Ăn uống'));
      await tester.pump();

      // 3. Verify child categories appear (e.g. "Trà sữa & Cà phê")
      expect(find.text('Trà sữa & Cà phê'), findsOneWidget);

      // 4. Tap child category "Trà sữa & Cà phê"
      await tester.tap(find.text('Trà sữa & Cà phê'));
      await tester.pump();

      // 5. Enter amount using quick chip (50k)
      await tester.tap(find.text('50k'));
      await tester.pump();

      // Verify amount display has no +/- prefix
      expect(find.text('50.000'), findsOneWidget);

      // 6. Tap Save button
      await tester.tap(find.text('Lưu Giao Dịch'));
      await tester.pump();

      expect(savedTx, isNotNull);
      expect(savedTx!['amount'], 50000.0);
      expect(savedTx!['category_id'], 11); // Trà sữa & Cà phê
      expect(savedTx!['wallet_id'], 1);
    },
  );
}
