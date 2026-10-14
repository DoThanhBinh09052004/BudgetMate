import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:bugdetmate/core/database/database_helper.dart';
import 'package:bugdetmate/core/database/tables.dart';
import 'package:bugdetmate/features/transactions/services/transaction_service.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  group('TransactionService Atomic Tests', () {
    late Database db;
    late TransactionService service;
    late int walletId;
    late int categoryId;

    setUp(() async {
      db = await DatabaseHelper.instance.getDatabase(inMemory: true);
      await db.delete(AppTables.transactions);
      await db.delete(AppTables.wallets);
      await db.delete(AppTables.categories);
      service = TransactionService(db: db);

      walletId = await db.insert(AppTables.wallets, {
        'name': 'Ví tiền mặt',
        'type': 'cash',
        'balance': 1000000.0,
      });

      categoryId = await db.insert(AppTables.categories, {
        'name': 'Ăn uống',
        'type': 'expense',
        'icon': 'utensils',
        'color': '#F97316',
      });
    });

    test('createTransaction inserts transaction and atomically updates wallet balance', () async {
      final txId = await service.createTransaction(
        walletId: walletId,
        categoryId: categoryId,
        amount: 200000.0,
        type: 'expense',
        note: 'Tiền chợ',
      );

      expect(txId, greaterThan(0));

      final wallet = await db.query(AppTables.wallets, where: 'id = ?', whereArgs: [walletId]);
      expect(wallet.first['balance'], 800000.0);

      final tx = await db.query(AppTables.transactions, where: 'id = ?', whereArgs: [txId]);
      expect(tx.first['amount'], 200000.0);
      expect(tx.first['note'], 'Tiền chợ');
    });

    test('createTransaction handles income correctly', () async {
      final txId = await service.createTransaction(
        walletId: walletId,
        categoryId: null,
        amount: 500000.0,
        type: 'income',
        note: 'Thưởng',
      );

      expect(txId, greaterThan(0));

      final wallet = await db.query(AppTables.wallets, where: 'id = ?', whereArgs: [walletId]);
      expect(wallet.first['balance'], 1500000.0);
    });

    test('updateTransaction adjusts wallet balance accurately when amount and note change', () async {
      final txId = await service.createTransaction(
        walletId: walletId,
        categoryId: categoryId,
        amount: 100000.0,
        type: 'expense',
        note: 'Cà phê',
      );

      await service.updateTransaction(
        transactionId: txId,
        walletId: walletId,
        categoryId: categoryId,
        newAmount: 150000.0,
        newType: 'expense',
        newNote: 'Cà phê và bánh',
      );

      final wallet = await db.query(AppTables.wallets, where: 'id = ?', whereArgs: [walletId]);
      expect(wallet.first['balance'], 850000.0); // 1,000,000 - 150,000

      final tx = await db.query(AppTables.transactions, where: 'id = ?', whereArgs: [txId]);
      expect(tx.first['amount'], 150000.0);
      expect(tx.first['note'], 'Cà phê và bánh');
    });

    test('deleteTransaction reverts wallet balance and removes transaction row', () async {
      final txId = await service.createTransaction(
        walletId: walletId,
        categoryId: categoryId,
        amount: 300000.0,
        type: 'expense',
      );

      // Verify wallet decreased to 700k
      var wallet = await db.query(AppTables.wallets, where: 'id = ?', whereArgs: [walletId]);
      expect(wallet.first['balance'], 700000.0);

      // Delete
      await service.deleteTransaction(txId);

      // Verify wallet restored to 1M
      wallet = await db.query(AppTables.wallets, where: 'id = ?', whereArgs: [walletId]);
      expect(wallet.first['balance'], 1000000.0);

      final tx = await db.query(AppTables.transactions, where: 'id = ?', whereArgs: [txId]);
      expect(tx.isEmpty, isTrue);
    });

    test('getRecentTransactions returns joined category and parent information', () async {
      final childCatId = await db.insert(AppTables.categories, {
        'name': 'Trà sữa',
        'type': 'expense',
        'icon': 'coffee',
        'color': '#F97316',
        'parent_id': categoryId,
      });

      await service.createTransaction(
        walletId: walletId,
        categoryId: childCatId,
        amount: 50000.0,
        type: 'expense',
        note: 'Gong Cha',
      );

      final recent = await service.getRecentTransactions(limit: 10);
      expect(recent.length, 1);
      expect(recent.first['category_name'], 'Trà sữa');
      expect(recent.first['parent_name'], 'Ăn uống');
    });

    test('confirmTransaction updates needs_review flag to 0', () async {
      final txId = await service.createTransaction(
        walletId: walletId,
        amount: 50000.0,
        type: 'expense',
        needsReview: 1,
      );

      await service.confirmTransaction(txId);

      final tx = await db.query(AppTables.transactions, where: 'id = ?', whereArgs: [txId]);
      expect(tx.first['needs_review'], 0);
    });
  });
}
