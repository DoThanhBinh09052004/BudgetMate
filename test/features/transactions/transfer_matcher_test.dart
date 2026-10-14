import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:bugdetmate/core/database/database_helper.dart';
import 'package:bugdetmate/features/transactions/services/transfer_matcher_service.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  tearDown(() async {
    await DatabaseHelper.instance.close();
  });

  test(
    'Auto-pairs internal transfer with keyword within time window',
    () async {
      final db = await DatabaseHelper.instance.getDatabase(inMemory: true);
      final matcher = TransferMatcherService(db: db);

      final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;

      // Wallet A expense
      final idA = await db.insert('transactions', {
        'wallet_id': 1,
        'amount': 500000.0,
        'type': 'expense',
        'transaction_date': now,
        'note': 'Chuyen tien noi bo',
        'source': 'auto_notification',
      });

      // Wallet B income (30s later)
      final idB = await db.insert('transactions', {
        'wallet_id': 2,
        'amount': 500000.0,
        'type': 'income',
        'transaction_date': now + 30,
        'note': 'Nhan CK tu tai khoan',
        'source': 'auto_notification',
      });

      // Get all user wallet IDs
      final walletIds = [1, 2];

      final paired = await matcher.matchTransfers(
        transactionId: idB,
        walletIds: walletIds,
      );

      expect(paired, true);

      // Verify both transactions now have type 'transfer' and transfer_pair_id set
      final txA = await db.query(
        'transactions',
        where: 'id = ?',
        whereArgs: [idA],
      );
      final txB = await db.query(
        'transactions',
        where: 'id = ?',
        whereArgs: [idB],
      );

      expect(txA.first['type'], 'transfer');
      expect(txB.first['type'], 'transfer');
      expect(txA.first['transfer_pair_id'], idB);
      expect(txB.first['transfer_pair_id'], idA);

      await db.close();
    },
  );

  test('Same amount, same window, no keyword → flags needs_review', () async {
    final db = await DatabaseHelper.instance.getDatabase(inMemory: true);
    final matcher = TransferMatcherService(db: db);

    final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;

    await db.insert('transactions', {
      'wallet_id': 1,
      'amount': 500000.0,
      'type': 'expense',
      'transaction_date': now,
      'note': 'Thanh toan dich vu',
      'source': 'auto_notification',
    });

    final idB = await db.insert('transactions', {
      'wallet_id': 2,
      'amount': 500000.0,
      'type': 'income',
      'transaction_date': now + 30,
      'note': 'Nhan tien',
      'source': 'auto_notification',
    });

    final paired = await matcher.matchTransfers(
      transactionId: idB,
      walletIds: [1, 2],
    );

    expect(paired, false); // Not auto-paired

    final txB = await db.query(
      'transactions',
      where: 'id = ?',
      whereArgs: [idB],
    );
    expect(txB.first['needs_review'], 1);

    await db.close();
  });
}
