import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:bugdetmate/core/database/database_helper.dart';
import 'package:bugdetmate/core/constants/app_constants.dart';
import 'package:bugdetmate/features/transactions/services/deduplication_service.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  tearDown(() async {
    await DatabaseHelper.instance.close();
  });

  test('Duplicate transaction within dedup window is detected', () async {
    final db = await DatabaseHelper.instance.getDatabase(inMemory: true);
    final dedup = DeduplicationService(db: db);

    final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;

    // Insert first transaction
    await db.insert('transactions', {
      'wallet_id': 1,
      'amount': 50000.0,
      'type': 'expense',
      'transaction_date': now,
      'note': 'Highlands Coffee',
      'source': 'auto_notification',
    });

    // Check duplicate within window (45s later)
    final isDuplicate = await dedup.isDuplicate(
      walletId: 1,
      amount: 50000.0,
      note: 'Highlands Coffee',
      transactionDate: now + 45,
    );

    expect(isDuplicate, true);
    await db.close();
  });

  test('Transaction outside dedup window is NOT duplicate', () async {
    final db = await DatabaseHelper.instance.getDatabase(inMemory: true);
    final dedup = DeduplicationService(db: db);

    final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;

    await db.insert('transactions', {
      'wallet_id': 1,
      'amount': 50000.0,
      'type': 'expense',
      'transaction_date': now,
      'note': 'Highlands Coffee',
      'source': 'auto_notification',
    });

    // Check 90s later — outside window
    final isDuplicate = await dedup.isDuplicate(
      walletId: 1,
      amount: 50000.0,
      note: 'Highlands Coffee',
      transactionDate: now + (AppConstants.deduplicationWindowSeconds + 30),
    );

    expect(isDuplicate, false);
    await db.close();
  });
}
