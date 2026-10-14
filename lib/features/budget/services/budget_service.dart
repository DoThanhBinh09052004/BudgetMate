import 'package:sqflite/sqflite.dart';
import 'package:bugdetmate/core/database/tables.dart';
import 'package:bugdetmate/features/budget/models/budget_model.dart';
import 'package:bugdetmate/features/budget/models/recurring_payment_model.dart';

/// Engine quản lý ngân sách, chi phí định kỳ chống trừ kép (Anti Double-Counting)
/// và tính toán tốc độ đốt tiền (Burn-Rate Forecast).
class BudgetService {
  final Database db;

  BudgetService({required this.db});

  /// Lưu hoặc cập nhật cấu hình ngân sách
  Future<void> setBudget(BudgetModel budget) async {
    final existing = await db.query(
      AppTables.budgets,
      where: budget.categoryId == null
          ? 'category_id IS NULL'
          : 'category_id = ?',
      whereArgs: budget.categoryId == null ? null : [budget.categoryId],
    );

    if (existing.isNotEmpty) {
      await db.update(
        AppTables.budgets,
        budget.toMap(),
        where: 'id = ?',
        whereArgs: [existing.first['id']],
      );
    } else {
      await db.insert(AppTables.budgets, budget.toMap());
    }
  }

  /// Lấy ngân sách tổng
  Future<BudgetModel?> getOverallBudget() async {
    final results = await db.query(
      AppTables.budgets,
      where: 'category_id IS NULL',
      limit: 1,
    );
    if (results.isEmpty) return null;
    return BudgetModel.fromMap(results.first);
  }

  /// Tính khoảng thời gian của chu kỳ theo ngày nhận lương linh hoạt
  CycleDateRange getCycleDateRange({
    required int startDay,
    required DateTime currentDate,
  }) {
    DateTime startDate;
    DateTime endDate;

    if (currentDate.day >= startDay) {
      startDate = DateTime(currentDate.year, currentDate.month, startDay);
      final nextMonthYear = currentDate.month == 12
          ? currentDate.year + 1
          : currentDate.year;
      final nextMonth = currentDate.month == 12 ? 1 : currentDate.month + 1;
      endDate = DateTime(
        nextMonthYear,
        nextMonth,
        startDay,
      ).subtract(const Duration(seconds: 1));
    } else {
      final prevMonthYear = currentDate.month == 1
          ? currentDate.year - 1
          : currentDate.year;
      final prevMonth = currentDate.month == 1 ? 12 : currentDate.month - 1;
      startDate = DateTime(prevMonthYear, prevMonth, startDay);
      endDate = DateTime(
        currentDate.year,
        currentDate.month,
        startDay,
      ).subtract(const Duration(seconds: 1));
    }

    return CycleDateRange(startDate: startDate, endDate: endDate);
  }

  /// Đảm bảo các khoản recurring cho chu kỳ `cycleMonth` (YYYY-MM) đã được tạo
  Future<void> ensureCycleRecurringPayments({
    required String cycleMonth,
  }) async {
    final rules = await db.query(
      AppTables.recurringRules,
      where: 'is_active = ?',
      whereArgs: [1],
    );

    for (final rule in rules) {
      final ruleId = rule['id'] as int;
      final existing = await db.query(
        AppTables.recurringPayments,
        where: 'rule_id = ? AND cycle_month = ?',
        whereArgs: [ruleId, cycleMonth],
      );

      if (existing.isEmpty) {
        await db.insert(AppTables.recurringPayments, {
          'rule_id': ruleId,
          'cycle_month': cycleMonth,
          'is_paid': 0,
        });
      }
    }
  }

  /// Đánh dấu một khoản chi phí định kỳ đã được thanh toán
  Future<void> markRecurringPaymentAsPaid({
    required int ruleId,
    required String cycleMonth,
    int? transactionId,
    int? paidDate,
  }) async {
    final nowSec = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    await db.update(
      AppTables.recurringPayments,
      {
        'is_paid': 1,
        'transaction_id': transactionId,
        'paid_date': paidDate ?? nowSec,
      },
      where: 'rule_id = ? AND cycle_month = ?',
      whereArgs: [ruleId, cycleMonth],
    );
  }

  /// Tính toán tổng quan ngân sách, khả dụng thực tế và Burn-rate
  Future<BudgetSummary> getBudgetSummary({
    required String cycleMonth,
    DateTime? now,
  }) async {
    final currentTime = now ?? DateTime.now();
    final budget = await getOverallBudget();
    final totalBudget = budget?.amount ?? 0.0;
    final startDay = budget?.startDay ?? 1;

    final dateRange = getCycleDateRange(
      startDay: startDay,
      currentDate: currentTime,
    );
    final startSec = dateRange.startDate.millisecondsSinceEpoch ~/ 1000;
    final endSec = dateRange.endDate.millisecondsSinceEpoch ~/ 1000;

    await ensureCycleRecurringPayments(cycleMonth: cycleMonth);

    // 1. Tính chi phí định kỳ CHƯA thanh toán trong chu kỳ
    final unpaidRecurringQuery = await db.rawQuery(
      '''
      SELECT SUM(r.amount) as total
      FROM ${AppTables.recurringPayments} p
      JOIN ${AppTables.recurringRules} r ON p.rule_id = r.id
      WHERE p.cycle_month = ? AND p.is_paid = 0
    ''',
      [cycleMonth],
    );

    final unpaidRecurringTotal =
        (unpaidRecurringQuery.first['total'] as num?)?.toDouble() ?? 0.0;

    // 2. Tính chi tiêu thực tế ĐÃ phát sinh trong chu kỳ
    final actualSpentQuery = await db.rawQuery(
      '''
      SELECT SUM(amount) as total
      FROM ${AppTables.transactions}
      WHERE type = 'expense' AND transaction_date >= ? AND transaction_date <= ?
    ''',
      [startSec, endSec],
    );

    final actualSpentTotal =
        (actualSpentQuery.first['total'] as num?)?.toDouble() ?? 0.0;

    // 3. Số dư khả dụng thực tế chống trừ kép:
    // Khả dụng = Ngân sách - Chi phí định kỳ (CHƯA thanh toán) - Chi tiêu thực tế (ĐÃ phát sinh)
    final availableBalance =
        totalBudget - unpaidRecurringTotal - actualSpentTotal;

    // 4. Burn-Rate Forecast
    final totalDaysInCycle =
        dateRange.endDate.difference(dateRange.startDate).inDays + 1;
    int daysPassed = currentTime.difference(dateRange.startDate).inDays + 1;
    if (daysPassed < 1) daysPassed = 1;
    if (daysPassed > totalDaysInCycle) daysPassed = totalDaysInCycle;

    final dailyBurnRate = actualSpentTotal / daysPassed;
    final daysRemaining = (totalDaysInCycle - daysPassed).clamp(
      0,
      totalDaysInCycle,
    );
    final projectedTotalSpent =
        actualSpentTotal +
        (dailyBurnRate * daysRemaining) +
        unpaidRecurringTotal;

    final isBurnRateWarning =
        totalBudget > 0 && (projectedTotalSpent > totalBudget);

    return BudgetSummary(
      totalBudget: totalBudget,
      unpaidRecurringTotal: unpaidRecurringTotal,
      actualSpentTotal: actualSpentTotal,
      availableBalance: availableBalance,
      dailyBurnRate: dailyBurnRate,
      projectedTotalSpent: projectedTotalSpent,
      isBurnRateWarning: isBurnRateWarning,
    );
  }
}
