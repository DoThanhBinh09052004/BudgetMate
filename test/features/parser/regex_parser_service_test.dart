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

  test('Parse Sacombank expense notification correctly', () {
    final sacomRule = BankRule(
      bankId: 'sacombank',
      packageName: 'com.sacombank.ewallet',
      displayName: 'Sacombank',
      amountPatterns: [
        r'PS:\s*[+-]?([\d.,]+)\s*(?:VND|đ|d)',
      ],
      typeIndicators: const TypeIndicators(
        expense: ['-', 'PS: -'],
        income: ['+', 'PS: +'],
      ),
      notePattern: r'(?:Nội dung|Noi dung|ND):\s*(.+?)$',
      accountPattern: r'TK:\s*(\d+)',
    );

    final customParser = RegexParserService(rules: [sacomRule]);
    const rawText =
        'SACOMBANK 13/10/2026 11:26\nTK: 0123456789\nPS: -30,000 VND\nSố dư khả dụng: 1,500,000 VND\nNội dung: Mua ca phe Highlands';

    final result = customParser.parse(
      packageName: 'com.sacombank.ewallet',
      text: rawText,
    );

    expect(result, isNotNull);
    expect(result!.amount, 30000.0);
    expect(result.type, 'expense');
    expect(result.note, contains('Mua ca phe Highlands'));
    expect(result.accountSuffix, '0123456789');
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

  test('Parse Sacombank SMS notification from Google Messages or MIUI SMS correctly', () {
    final sacomRule = BankRule(
      bankId: 'sacombank',
      packageName: 'com.sacombank.ewallet',
      displayName: 'Sacombank',
      amountPatterns: [
        r'PS:\s*[+-]?([\d.,]+)\s*(?:VND|đ|d)',
      ],
      typeIndicators: const TypeIndicators(
        expense: ['-', 'PS: -'],
        income: ['+', 'PS: +'],
      ),
      notePattern: r'(?:Nội dung|Noi dung|ND):\s*(.+?)$',
      accountPattern: r'TK:\s*(\d+)',
    );

    final customParser = RegexParserService(rules: [sacomRule]);
    const smsText =
        'TK: 0123456789\nPS: -30,000 VND\nSố dư khả dụng: 1,500,000 VND\nNội dung: Mua ca phe Highlands';

    // Notification từ app Google Messages (title thường là tên người gửi / brandname "SACOMBANK")
    final result = customParser.parse(
      packageName: 'com.google.android.apps.messaging',
      title: 'SACOMBANK 13/10/2026 11:26',
      text: smsText,
    );

    expect(result, isNotNull);
    expect(result!.amount, 30000.0);
    expect(result.type, 'expense');
    expect(result.note, contains('Mua ca phe Highlands'));
    expect(result.accountSuffix, '0123456789');
  });

  test('getPackageNames returns all configured bank packages plus SMS apps', () {
    final packages = parser.getPackageNames();
    expect(packages, contains('com.techcombank.mobile'));
    expect(packages, contains('com.VCB'));
    expect(packages, contains('com.google.android.apps.messaging'));
    expect(packages, contains('com.android.mms'));
    expect(packages.length, 5);
  });
}
