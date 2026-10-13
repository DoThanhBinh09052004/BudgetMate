import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;
import 'package:bugdetmate/features/parser/models/bank_rule_model.dart';

/// Service bóc tách thông báo ngân hàng bằng regex động.
/// Rules được inject qua constructor (testing) hoặc load từ JSON (production).
class RegexParserService {
  List<BankRule> _rules;

  RegexParserService({List<BankRule>? rules}) : _rules = rules ?? [];

  /// Load rules từ assets/rules/bank_rules.json (gọi trong production)
  Future<void> loadRulesFromAsset() async {
    final jsonString = await rootBundle.loadString('assets/rules/bank_rules.json');
    final Map<String, dynamic> jsonData = json.decode(jsonString);
    final List<dynamic> rulesList = jsonData['rules'] ?? [];
    _rules = rulesList.map((r) => BankRule.fromJson(r)).toList();
  }

  /// Trả về danh sách packageName đã cấu hình — dùng cho Java whitelist qua MethodChannel
  List<String> getPackageNames() {
    return _rules.map((r) => r.packageName).toList();
  }

  /// Parse thông báo thô từ một packageName cụ thể.
  /// Trả về null nếu không tìm được rule phù hợp hoặc không parse được amount.
  ParsedTransaction? parse({required String packageName, required String text}) {
    final rule = _rules.where((r) => r.packageName == packageName).firstOrNull;
    if (rule == null) return null;

    // 1. Parse amount
    double? amount;
    for (final pattern in rule.amountPatterns) {
      final match = RegExp(pattern).firstMatch(text);
      if (match != null && match.groupCount >= 1) {
        amount = _normalizeAmount(match.group(1)!);
        break;
      }
    }
    if (amount == null) return null;

    // 2. Determine type (expense/income)
    String type = 'expense'; // default
    for (final indicator in rule.typeIndicators.income) {
      if (text.contains(indicator)) {
        type = 'income';
        break;
      }
    }
    // Explicit expense indicators override
    for (final indicator in rule.typeIndicators.expense) {
      if (text.contains(indicator)) {
        type = 'expense';
        break;
      }
    }

    // 3. Extract note
    String note = '';
    double confidenceScore = 0.5;
    if (rule.notePattern.isNotEmpty) {
      final noteMatch = RegExp(rule.notePattern).firstMatch(text);
      if (noteMatch != null && noteMatch.groupCount >= 1) {
        note = noteMatch.group(1)!.trim();
        confidenceScore += 0.3;
      }
    }

    // 4. Extract account suffix
    String? accountSuffix;
    if (rule.accountPattern.isNotEmpty) {
      final accountMatch = RegExp(rule.accountPattern).firstMatch(text);
      if (accountMatch != null && accountMatch.groupCount >= 1) {
        accountSuffix = accountMatch.group(1);
        confidenceScore += 0.2;
      }
    }

    return ParsedTransaction(
      amount: amount,
      type: type,
      note: note,
      accountSuffix: accountSuffix,
      confidenceScore: confidenceScore.clamp(0.0, 1.0),
    );
  }

  /// Chuẩn hóa định dạng số tiền Việt Nam: "50,000" → 50000.0, "2.000.000" → 2000000.0
  double _normalizeAmount(String raw) {
    String cleaned = raw.replaceAll(' ', '');

    if (cleaned.contains('.') && cleaned.contains(',')) {
      final lastDot = cleaned.lastIndexOf('.');
      final lastComma = cleaned.lastIndexOf(',');
      if (lastComma > lastDot) {
        cleaned = cleaned.replaceAll('.', '').replaceAll(',', '.');
      } else {
        cleaned = cleaned.replaceAll(',', '');
      }
    } else if (cleaned.contains(',')) {
      final parts = cleaned.split(',');
      if (parts.length == 2 && parts.last.length <= 2) {
        cleaned = cleaned.replaceAll(',', '.');
      } else {
        cleaned = cleaned.replaceAll(',', '');
      }
    } else if (cleaned.contains('.')) {
      final parts = cleaned.split('.');
      if (parts.length > 2 || (parts.length == 2 && parts.last.length == 3)) {
        cleaned = cleaned.replaceAll('.', '');
      }
    }

    return double.tryParse(cleaned) ?? 0.0;
  }
}
