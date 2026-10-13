class BudgetModel {
  final int? id;
  final int? categoryId; // null = ngân sách tổng
  final double amount;
  final int startDay;

  const BudgetModel({
    this.id,
    this.categoryId,
    required this.amount,
    this.startDay = 1,
  });

  factory BudgetModel.fromMap(Map<String, dynamic> map) {
    return BudgetModel(
      id: map['id'] as int?,
      categoryId: map['category_id'] as int?,
      amount: (map['amount'] as num).toDouble(),
      startDay: map['start_day'] as int? ?? 1,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'category_id': categoryId,
      'amount': amount,
      'start_day': startDay,
    };
  }
}
