import 'package:flutter_test/flutter_test.dart';
import 'package:bugdetmate/features/parser/services/regex_parser_service.dart';
import 'package:bugdetmate/features/parser/models/bank_rule_model.dart';
import 'package:bugdetmate/core/constants/app_constants.dart';

void main() {
  late RegexParserService parser;

  setUp(() {
    // Inject rules directly for unit testing — no asset bundle dependency
    final testRules = [
      BankRule(
        bankId: 'tcb',
        packageName: 'com.techcombank.mobile',
        displayName: 'Techcombank',
        amountPatterns: [
          r'[+-]?([\d.,]+)\s*(?:VND|đ)',
        ],
        typeIndicators: const TypeIndicators(
          expense: ['-'],
          income: ['+'],
        ),
        notePattern: r'ND:\s*(.+?)(?:\.\s*SD:|$)',
        accountPattern: r'TK\s*(\d{4})',
      ),
      BankRule(
        bankId: 'vcb',
        packageName: 'com.VCB',
        displayName: 'Vietcombank',
        amountPatterns: [
          r'[+-]?([\d.,]+)\s*(?:VND|đ)',
        ],
        typeIndicators: const TypeIndicators(
          expense: ['-'],
          income: ['+'],
        ),
        notePattern: r'Ref:\s*(.+?)(?:\.\s*SD:|$)',
        accountPattern: r'TK\s*(\d{4})',
      ),
    ];
    parser = RegexParserService(rules: testRules);
  });

  test('Parse Techcombank expense notification correctly', () {
    const rawText =
        'TK 1903xxx890: -50,000 VND luc 12/10/2026 14:30. ND: Highlands Coffee. SD: 12,500,000 VND';
    final result = parser.parse(packageName: 'com.techcombank.mobile', text: rawText);

    expect(result, isNotNull);
    expect(result!.amount, 50000.0);
    expect(result.type, 'expense');
    expect(result.note.toLowerCase(), contains('highlands'));
    expect(result.confidenceScore, greaterThanOrEqualTo(AppConstants.minConfidenceScore));
  });

  test('Parse Vietcombank income notification correctly', () {
    const rawText =
        'VCB: +2,000,000 VND vao TK 0011xxx tại 12/10/2026. Ref: Luong thang 10. SD: 15,000,000 VND';
    final result = parser.parse(packageName: 'com.VCB', text: rawText);

    expect(result, isNotNull);
    expect(result!.amount, 2000000.0);
    expect(result.type, 'income');
    expect(result.note.toLowerCase(), contains('luong'));
  });

  test('Returns null for unknown package name', () {
    const rawText = 'Some random notification text';
    final result = parser.parse(packageName: 'com.unknown.app', text: rawText);
    expect(result, isNull);
  });

  test('Low confidence score when note cannot be extracted', () {
    const rawText = 'TK 1903: -50,000 VND';
    final result = parser.parse(packageName: 'com.techcombank.mobile', text: rawText);

    // May parse amount but note is missing → lower confidence
    if (result != null) {
      expect(result.confidenceScore, lessThan(1.0));
    }
  });

  test('getPackageNames returns all configured bank packages', () {
    final packages = parser.getPackageNames();
    expect(packages, contains('com.techcombank.mobile'));
    expect(packages, contains('com.VCB'));
    expect(packages.length, 2);
  });
}
