/// Model đại diện cho 1 quy tắc parse thông báo của ngân hàng/ví điện tử.
/// Được load từ assets/rules/bank_rules.json hoặc inject trực tiếp cho testing.
class TypeIndicators {
  final List<String> expense;
  final List<String> income;

  const TypeIndicators({required this.expense, required this.income});

  factory TypeIndicators.fromJson(Map<String, dynamic> json) {
    return TypeIndicators(
      expense: List<String>.from(json['expense'] ?? []),
      income: List<String>.from(json['income'] ?? []),
    );
  }

  Map<String, dynamic> toJson() => {'expense': expense, 'income': income};
}

class BankRule {
  final String bankId;
  final String packageName;
  final String displayName;
  final List<String> amountPatterns;
  final TypeIndicators typeIndicators;
  final String notePattern;
  final String accountPattern;

  const BankRule({
    required this.bankId,
    required this.packageName,
    required this.displayName,
    required this.amountPatterns,
    required this.typeIndicators,
    required this.notePattern,
    required this.accountPattern,
  });

  factory BankRule.fromJson(Map<String, dynamic> json) {
    return BankRule(
      bankId: json['bankId'] as String,
      packageName: json['packageName'] as String,
      displayName: json['displayName'] as String,
      amountPatterns: List<String>.from(json['amountPatterns'] ?? []),
      typeIndicators: TypeIndicators.fromJson(json['typeIndicators'] ?? {}),
      notePattern: json['notePattern'] as String? ?? '',
      accountPattern: json['accountPattern'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
    'bankId': bankId,
    'packageName': packageName,
    'displayName': displayName,
    'amountPatterns': amountPatterns,
    'typeIndicators': typeIndicators.toJson(),
    'notePattern': notePattern,
    'accountPattern': accountPattern,
  };
}

/// Kết quả parse từ một thông báo thô.
class ParsedTransaction {
  final double amount;
  final String type; // 'expense' or 'income'
  final String note;
  final String? accountSuffix;
  final double confidenceScore;

  const ParsedTransaction({
    required this.amount,
    required this.type,
    required this.note,
    this.accountSuffix,
    required this.confidenceScore,
  });
}
