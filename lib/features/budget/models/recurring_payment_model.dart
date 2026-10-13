class RecurringRuleModel {
  final int? id;
  final String title;
  final double amount;
  final int categoryId;
  final int walletId;
  final int dueDay;
  final bool isActive;

  const RecurringRuleModel({
    this.id,
    required this.title,
    required this.amount,
    required this.categoryId,
    required this.walletId,
    required this.dueDay,
    this.isActive = true,
  });

  factory RecurringRuleModel.fromMap(Map<String, dynamic> map) {
    return RecurringRuleModel(
      id: map['id'] as int?,
      title: map['title'] as String,
      amount: (map['amount'] as num).toDouble(),
      categoryId: map['category_id'] as int,
      walletId: map['wallet_id'] as int,
      dueDay: map['due_day'] as int,
      isActive: (map['is_active'] as int? ?? 1) == 1,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'title': title,
      'amount': amount,
      'category_id': categoryId,
      'wallet_id': walletId,
      'due_day': dueDay,
      'is_active': isActive ? 1 : 0,
    };
  }
}

class RecurringPaymentModel {
  final int? id;
  final int ruleId;
  final String cycleMonth;
  final int? transactionId;
  final bool isPaid;
  final int? paidDate;

  const RecurringPaymentModel({
    this.id,
    required this.ruleId,
    required this.cycleMonth,
    this.transactionId,
    this.isPaid = false,
    this.paidDate,
  });

  factory RecurringPaymentModel.fromMap(Map<String, dynamic> map) {
    return RecurringPaymentModel(
      id: map['id'] as int?,
      ruleId: map['rule_id'] as int,
      cycleMonth: map['cycle_month'] as String,
      transactionId: map['transaction_id'] as int?,
      isPaid: (map['is_paid'] as int? ?? 0) == 1,
      paidDate: map['paid_date'] as int?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'rule_id': ruleId,
      'cycle_month': cycleMonth,
      'transaction_id': transactionId,
      'is_paid': isPaid ? 1 : 0,
      'paid_date': paidDate,
    };
  }
}

class CycleDateRange {
  final DateTime startDate;
  final DateTime endDate;

  const CycleDateRange({required this.startDate, required this.endDate});
}

class BudgetSummary {
  final double totalBudget;
  final double unpaidRecurringTotal;
  final double actualSpentTotal;
  final double availableBalance;
  final double dailyBurnRate;
  final double projectedTotalSpent;
  final bool isBurnRateWarning;

  const BudgetSummary({
    required this.totalBudget,
    required this.unpaidRecurringTotal,
    required this.actualSpentTotal,
    required this.availableBalance,
    required this.dailyBurnRate,
    required this.projectedTotalSpent,
    required this.isBurnRateWarning,
  });
}
