import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:bugdetmate/core/database/database_helper.dart';
import 'package:bugdetmate/core/database/tables.dart';
import 'package:bugdetmate/features/home/controllers/home_controller.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  group('HomeController Tests', () {
    late Database db;

    late int walletId;

    setUp(() async {
      db = await DatabaseHelper.instance.getDatabase(inMemory: true);
      await db.delete(AppTables.transactions);
      await db.delete(AppTables.wallets);
      await db.delete(AppTables.categories);

      walletId = await db.insert(AppTables.wallets, {
        'name': 'Ví tiền mặt',
        'type': 'cash',
        'balance': 2500000.0,
      });

      await db.insert(AppTables.categories, {
        'name': 'Ăn uống',
        'type': 'expense',
        'icon': 'utensils',
        'color': '#F97316',
      });
    });

    test('initializes with mock data and auto-groups transactions', () {
      final nowSec = DateTime.now().millisecondsSinceEpoch ~/ 1000;
      final mockTx = [
        {
          'id': 1,
          'wallet_id': 1,
          'amount': 45000.0,
          'type': 'expense',
          'transaction_date': nowSec,
          'category_name': 'Ăn trưa',
        },
      ];

      final controller = HomeController(
        db: db,
        initialTotalBalance: 2500000.0,
        initialRecentTransactions: mockTx,
      );

      expect(controller.state.isLoading, isFalse);
      expect(controller.state.totalBalance, 2500000.0);
      expect(controller.state.recentTransactions.length, 1);
      expect(controller.state.groupedTransactions.isNotEmpty, isTrue);

      controller.dispose();
    });

    test('loadData loads balance, budget, and recent transactions', () async {
      final nowSec = DateTime.now().millisecondsSinceEpoch ~/ 1000;
      await db.insert(AppTables.transactions, {
        'wallet_id': walletId,
        'amount': 120000.0,
        'type': 'expense',
        'transaction_date': nowSec,
        'source': 'manual',
        'needs_review': 0,
      });

      final controller = HomeController(db: db);
      expect(controller.state.isLoading, isTrue);

      await controller.loadData();

      expect(controller.state.isLoading, isFalse);
      expect(controller.state.totalBalance, 2500000.0);
      expect(controller.state.recentTransactions.length, 1);
      expect(controller.state.groupedTransactions.isNotEmpty, isTrue);

      controller.dispose();
    });

    test('prevents redundant concurrent loadData execution', () async {
      final controller = HomeController(db: db);

      final f1 = controller.loadData();
      final f2 = controller.loadData();

      await Future.wait<void>([f1, f2]);

      expect(controller.state.isLoading, isFalse);
      controller.dispose();
    });

    test('safe after dispose does not throw', () async {
      final controller = HomeController(db: db);
      controller.dispose();

      // Should not throw even if loadData is called after dispose
      await controller.loadData();
      expect(controller.isDisposed, isTrue);
    });

    test('confirmNeedsReview updates transaction and reloads', () async {
      final nowSec = DateTime.now().millisecondsSinceEpoch ~/ 1000;
      final txId = await db.insert(AppTables.transactions, {
        'wallet_id': walletId,
        'amount': 50000.0,
        'type': 'expense',
        'transaction_date': nowSec,
        'source': 'auto_notification',
        'needs_review': 1,
      });

      final controller = HomeController(db: db);
      await controller.loadData();
      expect(controller.state.needsReviewTransactions.length, 1);

      await controller.confirmNeedsReview(txId);
      expect(controller.state.needsReviewTransactions.isEmpty, isTrue);
      controller.dispose();
    });
  });
}
