import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:bugdetmate/core/database/database_helper.dart';
import 'package:bugdetmate/features/parser/services/regex_parser_service.dart';
import 'package:bugdetmate/features/parser/services/raw_sync_service.dart';
import 'package:bugdetmate/features/parser/models/bank_rule_model.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  tearDown(() async {
    await DatabaseHelper.instance.close();
  });

  test(
    'RawSyncService processes raw notifications and inserts transactions',
    () async {
      final helper = DatabaseHelper.instance;
      final db = await helper.getDatabase(inMemory: true);

      final testRules = [
        BankRule(
          bankId: 'tcb',
          packageName: 'com.techcombank.mobile',
          displayName: 'Techcombank',
          amountPatterns: [r'[+-]?([\d.,]+)\s*(?:VND|đ)'],
          typeIndicators: const TypeIndicators(expense: ['-'], income: ['+']),
          notePattern: r'ND:\s*(.+?)(?:\.\s*SD:|$)',
          accountPattern: r'TK\s*(\d{4})',
        ),
      ];
      final parser = RegexParserService(rules: testRules);
      final syncService = RawSyncService(db: db, parser: parser);

      // 1. Insert unprocessed notification
      await db.insert('raw_notifications', {
        'package_name': 'com.techcombank.mobile',
        'sbn_key': 'key_sync_1',
        'post_time': 1710000000,
        'title': 'Biến động số dư',
        'text': 'TK 1903xxx890: -50,000 VND. ND: Highlands Coffee. SD: 12,500,000 VND',
        'is_processed': 0,
      });

      // 2. Insert unparseable notification
      await db.insert('raw_notifications', {
        'package_name': 'com.unsupported.bank',
        'sbn_key': 'key_sync_2',
        'post_time': 1710000010,
        'title': 'Other App',
        'text': 'Random unparseable text',
        'is_processed': 0,
      });

      // Run sync
      final count = await syncService.syncUnprocessed();
      expect(count, 1);

      // Verify transactions
      final transactions = await db.query('transactions');
      expect(transactions.length, 1);
      expect(transactions.first['amount'], 50000.0);
      expect(transactions.first['type'], 'expense');
      expect(transactions.first['needs_review'], 0);

      // Verify all raw notifications are marked as processed
      final rawList = await db.query('raw_notifications');
      for (final raw in rawList) {
        expect(raw['is_processed'], 1);
      }

      // Verify wallet balance is atomically updated (-50000)
      final wallets = await db.query('wallets', where: 'id = 1');
      expect(wallets.isNotEmpty, true);
      expect(wallets.first['balance'], -50000.0);

      await db.close();
    },
  );
}
