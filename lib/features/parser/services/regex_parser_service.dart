import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;
import 'package:bugdetmate/features/parser/models/bank_rule_model.dart';

/// Service bóc tách thông báo ngân hàng bằng regex động.
/// Rules được inject qua constructor (testing) hoặc load từ JSON (production).
class RegexParserService {
  static List<BankRule>? _cachedRules;
  List<BankRule> _rules;

  RegexParserService({List<BankRule>? rules}) : _rules = rules ?? [];

  /// Xóa cache rules (dùng cho testing hoặc cập nhật rules)
  static void clearCache() {
    _cachedRules = null;
  }

  /// Load rules từ assets/rules/bank_rules.json (hỗ trợ in-memory caching)
  Future<void> loadRulesFromAsset({bool forceRefresh = false}) async {
    if (!forceRefresh && _cachedRules != null && _cachedRules!.isNotEmpty) {
      _rules = _cachedRules!;
      return;
    }
    final jsonString = await rootBundle.loadString(
      'assets/rules/bank_rules.json',
    );
    final Map<String, dynamic> jsonData = json.decode(jsonString);
    final List<dynamic> rulesList = jsonData['rules'] ?? [];
    _cachedRules = rulesList.map((r) => BankRule.fromJson(r)).toList();
    _rules = _cachedRules!;
  }

  /// Trả về danh sách packageName đã cấu hình (kèm theo các app SMS phổ biến) — dùng cho Java whitelist
  List<String> getPackageNames() {
    final list = _rules.map((r) => r.packageName).toSet();
    // Bổ sung các ứng dụng tin nhắn SMS mặc định để bắt thông báo biến động số dư qua SMS
    list.addAll([
      'com.google.android.apps.messaging', // Google Messages (phổ biến nhất trên Android mới)
      'com.android.mms', // MIUI Messages (Xiaomi/Redmi) & AOSP SMS
      'com.samsung.android.messaging', // Samsung Messages
    ]);
    return list.toList();
  }

  /// Parse thông báo thô từ một packageName cụ thể (hỗ trợ cả app ngân hàng và app SMS).
  /// Trả về null nếu không tìm được rule phù hợp hoặc không parse được amount.
  ParsedTransaction? parse({
    required String packageName,
    required String text,
    String? title,
  }) {
    // 1. Tìm rule trực tiếp theo packageName
    BankRule? rule = _rules
        .where((r) => r.packageName == packageName)
        .firstOrNull;

    // 2. Nếu là ứng dụng tin nhắn SMS (Google Messages, MIUI Messaging, Samsung Messages,...)
    // Hoặc nếu không tìm thấy theo packageName: Quét theo brandname ngân hàng trong title/text
    final isSmsApp =
        packageName.contains('messaging') ||
        packageName.contains('mms') ||
        packageName == 'com.android.mms' ||
        packageName == 'com.google.android.apps.messaging' ||
        packageName == 'com.samsung.android.messaging';

    if (rule == null || isSmsApp) {
      final combined = '${title ?? ''} $text'.toUpperCase();
      final matchedByBrand = _rules.where((r) {
        final brand = r.displayName.toUpperCase();
        final id = r.bankId.toUpperCase();
        return combined.contains(brand) || combined.contains(id);
      }).firstOrNull;

      if (matchedByBrand != null) {
        rule = matchedByBrand;
      }
    }

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
