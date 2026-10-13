import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:bugdetmate/features/home/screens/home_screen.dart';
import 'package:bugdetmate/features/budget/models/recurring_payment_model.dart';
import 'package:bugdetmate/core/theme/app_theme.dart';

void main() {
  testWidgets('HomeScreen displays balance cards, FAB, and needs review banner', (WidgetTester tester) async {
    const budgetSummary = BudgetSummary(
      totalBudget: 15000000.0,
      unpaidRecurringTotal: 5000000.0,
      actualSpentTotal: 2000000.0,
      availableBalance: 8000000.0,
      dailyBurnRate: 150000.0,
      projectedTotalSpent: 9000000.0,
      isBurnRateWarning: false,
    );

    final needsReviewList = [
      {
        'id': 1,
        'wallet_id': 1,
        'amount': 250000.0,
        'type': 'expense',
        'transaction_date': DateTime.now().millisecondsSinceEpoch ~/ 1000,
        'note': 'Giao dịch lạ',
        'source': 'auto_notification',
        'needs_review': 1,
      }
    ];

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.darkTheme,
        home: HomeScreen(
          initialTotalBalance: 15000000.0,
          initialBudgetSummary: budgetSummary,
          initialNeedsReviewTransactions: needsReviewList,
        ),
      ),
    );

    await tester.pump();

    // Verify title
    expect(find.text('BudgetMate'), findsOneWidget);

    // Verify balance cards
    expect(find.textContaining('Tổng số dư'), findsOneWidget);
    expect(find.textContaining('Khả dụng'), findsOneWidget);

    // Verify FAB
    expect(find.byType(FloatingActionButton), findsOneWidget);

    // Verify needs_review warning banner
    expect(find.textContaining('Cần xác nhận'), findsOneWidget);
  });
}
