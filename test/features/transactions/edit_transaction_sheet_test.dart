import 'package:flutter_test/flutter_test.dart';
import 'package:bugdetmate/core/database/database_helper.dart';
import 'package:bugdetmate/core/database/tables.dart';
import 'package:bugdetmate/features/transactions/screens/edit_transaction_sheet.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  test('Wallet balance updates correctly when editing transaction amount and deleting transaction', () async {
    final db = await DatabaseHelper.instance.getDatabase(inMemory: true);

    // Initial wallet balance = 1,000,000
    final walletId = await db.insert(AppTables.wallets, {
      'name': 'Ví tiền mặt',
      'type': 'cash',
      'balance': 1000000.0,
      'color': '#10B981',
    });

    // Insert expense of 100,000
    final txId = await db.insert(AppTables.transactions, {
      'wallet_id': walletId,
      'amount': 100000.0,
      'type': 'expense',
      'transaction_date': DateTime.now().millisecondsSinceEpoch ~/ 1000,
      'note': 'Ăn sáng phở',
      'source': 'manual',
      'needs_review': 0,
    });

    // 1. Logic Update: Edit expense amount to 150,000
    await EditTransactionSheet.executeEditTransaction(
      db: db,
      txId: txId,
      oldWalletId: walletId,
      newWalletId: walletId,
      oldType: 'expense',
      newType: 'expense',
      oldAmount: 100000.0,
      newAmount: 150000.0,
      categoryId: 1,
      note: 'Ăn sáng phở đặc biệt',
      transactionDate: DateTime.now().millisecondsSinceEpoch ~/ 1000,
    );

    // Wallet balance should now be 1,000,000 - 50,000 = 950,000
    var wallet = (await db.query(
      AppTables.wallets,
      where: 'id = ?',
      whereArgs: [walletId],
    )).first;
    expect(wallet['balance'], 950000.0);

    // 2. Logic Delete: Delete this transaction of 150,000
    await EditTransactionSheet.executeDeleteTransaction(
      db: db,
      txId: txId,
      walletId: walletId,
      type: 'expense',
      amount: 150000.0,
    );

    // Wallet balance should be refunded: 950,000 + 150,000 = 1,100,000
    wallet = (await db.query(
      AppTables.wallets,
      where: 'id = ?',
      whereArgs: [walletId],
    )).first;
    expect(wallet['balance'], 1100000.0);

    // Transaction should be removed
    final remainingTxs = await db.query(
      AppTables.transactions,
      where: 'id = ?',
      whereArgs: [txId],
    );
    expect(remainingTxs.isEmpty, true);

    await db.close();
  });
}
