import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:bugdetmate/core/database/database_helper.dart';
import 'package:bugdetmate/core/database/tables.dart';
import 'package:bugdetmate/features/budget/services/budget_service.dart';
import 'package:bugdetmate/features/budget/models/budget_model.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  tearDown(() async {
    await DatabaseHelper.instance.close();
  });

  test('Anti-double-counting: unpaid recurring becomes paid without double deduction', () async {
    final db = await DatabaseHelper.instance.getDatabase(inMemory: true);
    final service = BudgetService(db: db);

    // Set overall budget: 15,000,000 VND, startDay: 1
    await service.setBudget(
      BudgetModel(amount: 15000000.0, startDay: 1),
    );

    // Create recurring rule: Rent 5,000,000 VND
    final ruleId = await db.insert(AppTables.recurringRules, {
      'title': 'Tiền nhà',
      'amount': 5000000.0,
      'category_id': 5, // Nhà cửa
      'wallet_id': 1,
      'due_day': 5,
      'is_active': 1,
    });

    const cycleMonth = '2026-10';

    // Ensure cycle payments generated
    await service.ensureCycleRecurringPayments(cycleMonth: cycleMonth);

    // Check available balance before payment:
    // Budget: 15M - Unpaid Recurring: 5M - Spent: 0 = 10M
    var summary = await service.getBudgetSummary(
      cycleMonth: cycleMonth,
      now: DateTime(2026, 10, 2),
    );
    expect(summary.totalBudget, 15000000.0);
    expect(summary.unpaidRecurringTotal, 5000000.0);
    expect(summary.actualSpentTotal, 0.0);
    expect(summary.availableBalance, 10000000.0);

    // User or auto-sync pays rent: transaction created
    final txId = await db.insert(AppTables.transactions, {
      'wallet_id': 1,
      'category_id': 5,
      'amount': 5000000.0,
      'type': 'expense',
      'transaction_date': DateTime(2026, 10, 5).millisecondsSinceEpoch ~/ 1000,
      'note': 'Dong tien nha thang 10',
      'source': 'auto_notification',
    });

    // Mark recurring payment as paid with transactionId
    await service.markRecurringPaymentAsPaid(
      ruleId: ruleId,
      cycleMonth: cycleMonth,
      transactionId: txId,
      paidDate: DateTime(2026, 10, 5).millisecondsSinceEpoch ~/ 1000,
    );

    // Check available balance after payment:
    // Budget: 15M - Unpaid Recurring: 0M - Actual Spent: 5M = 10M
    // Notice: NO DOUBLE COUNTING! Balance remains 10M, not reduced to 5M!
    summary = await service.getBudgetSummary(
      cycleMonth: cycleMonth,
      now: DateTime(2026, 10, 6),
    );
    expect(summary.unpaidRecurringTotal, 0.0);
    expect(summary.actualSpentTotal, 5000000.0);
    expect(summary.availableBalance, 10000000.0);

    await db.close();
  });

  test('Flexible cycle based on custom salary start day (e.g. day 15)', () async {
    final db = await DatabaseHelper.instance.getDatabase(inMemory: true);
    final service = BudgetService(db: db);

    // Salary arrives on the 15th
    await service.setBudget(
      BudgetModel(amount: 20000000.0, startDay: 15),
    );

    final range1 = service.getCycleDateRange(
      startDay: 15,
      currentDate: DateTime(2026, 10, 20),
    );
    expect(range1.startDate, DateTime(2026, 10, 15));
    expect(range1.endDate, DateTime(2026, 11, 14, 23, 59, 59));

    final range2 = service.getCycleDateRange(
      startDay: 15,
      currentDate: DateTime(2026, 10, 10),
    );
    expect(range2.startDate, DateTime(2026, 9, 15));
    expect(range2.endDate, DateTime(2026, 10, 14, 23, 59, 59));

    await db.close();
  });

  test('Burn-rate calculation warns when projected spend exceeds budget', () async {
    final db = await DatabaseHelper.instance.getDatabase(inMemory: true);
    final service = BudgetService(db: db);

    // Budget: 10,000,000 VND
    await service.setBudget(
      BudgetModel(amount: 10000000.0, startDay: 1),
    );

    const cycleMonth = '2026-10';

    // Day 5: spent 4,000,000 VND already (800k/day * 31 days = 24.8M projected!)
    await db.insert(AppTables.transactions, {
      'wallet_id': 1,
      'category_id': 1,
      'amount': 4000000.0,
      'type': 'expense',
      'transaction_date': DateTime(2026, 10, 5, 12).millisecondsSinceEpoch ~/ 1000,
      'note': 'Shopping big',
      'source': 'manual',
    });

    final summary = await service.getBudgetSummary(
      cycleMonth: cycleMonth,
      now: DateTime(2026, 10, 5, 23, 59),
    );

    expect(summary.dailyBurnRate, greaterThan(0));
    expect(summary.isBurnRateWarning, true);
    expect(summary.projectedTotalSpent, greaterThan(summary.totalBudget));

    await db.close();
  });
}
