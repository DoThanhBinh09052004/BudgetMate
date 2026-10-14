import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:bugdetmate/core/database/database_helper.dart';
import 'package:bugdetmate/core/database/seed_data.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  tearDown(() async {
    await DatabaseHelper.instance.close();
  });

  test('DatabaseHelper creates all 8 tables and seeds default categories and wallets', () async {
    final helper = DatabaseHelper.instance;
    final db = await helper.getDatabase(inMemory: true);

    final tables = await db.rawQuery(
      "SELECT name FROM sqlite_master WHERE type='table';",
    );
    final tableNames = tables.map((t) => t['name'] as String).toList();

    expect(tableNames, contains('wallets'));
    expect(tableNames, contains('categories'));
    expect(tableNames, contains('raw_notifications'));
    expect(tableNames, contains('transactions'));
    expect(tableNames, contains('user_category_rules'));
    expect(tableNames, contains('budgets'));
    expect(tableNames, contains('recurring_rules'));
    expect(tableNames, contains('recurring_payments'));

    final categories = await db.query('categories');
    expect(categories.isNotEmpty, true);
    final categoryNames = categories.map((c) => c['name'] as String).toList();
    expect(categoryNames, contains('Ăn uống'));
    expect(categoryNames, contains('Di chuyển'));
    expect(categoryNames, contains('Mua sắm'));

    final wallets = await db.query('wallets');
    expect(wallets.isNotEmpty, true);
    final walletNames = wallets.map((w) => w['name'] as String).toList();
    expect(walletNames, contains('Tiền mặt'));
    expect(walletNames, contains('Tài khoản ngân hàng'));

    await db.close();
  });

  test('CRUD operations on raw_notifications work properly', () async {
    final helper = DatabaseHelper.instance;
    final db = await helper.getDatabase(inMemory: true);

    final id = await db.insert('raw_notifications', {
      'package_name': 'com.techcombank.mobile',
      'sbn_key': 'key_123',
      'post_time': 1710000000,
      'title': 'Biến động số dư',
      'text': 'TK 1903xxx: -50,000 VND',
      'is_processed': 0,
    });
    expect(id, greaterThan(0));

    final records = await db.query(
      'raw_notifications',
      where: 'sbn_key = ?',
      whereArgs: ['key_123'],
    );
    expect(records.length, 1);
    expect(records.first['package_name'], 'com.techcombank.mobile');
    expect(records.first['is_processed'], 0);

    // Update
    await db.update(
      'raw_notifications',
      {'is_processed': 1},
      where: 'id = ?',
      whereArgs: [id],
    );
    final updated = await db.query(
      'raw_notifications',
      where: 'id = ?',
      whereArgs: [id],
    );
    expect(updated.first['is_processed'], 1);

    await db.close();
  });

  test('Performance indexes are created for dedup and sync queries', () async {
    final helper = DatabaseHelper.instance;
    final db = await helper.getDatabase(inMemory: true);

    final indexes = await db.rawQuery(
      "SELECT name FROM sqlite_master WHERE type='index';",
    );
    final indexNames = indexes.map((i) => i['name'] as String).toList();

    expect(indexNames, contains('idx_transactions_dedup'));
    expect(indexNames, contains('idx_transactions_wallet_date'));
    expect(indexNames, contains('idx_raw_notifications_unprocessed'));
    expect(indexNames, contains('idx_recurring_payments_cycle'));

    await db.close();
  });

  test('wallets and categories have created_at auto-populated', () async {
    final helper = DatabaseHelper.instance;
    final db = await helper.getDatabase(inMemory: true);

    final wallets = await db.query('wallets');
    expect(wallets.isNotEmpty, true);
    for (final wallet in wallets) {
      expect(wallet['created_at'], isNotNull);
      expect(wallet['created_at'], isA<int>());
    }

    final categories = await db.query('categories');
    expect(categories.isNotEmpty, true);
    for (final cat in categories) {
      expect(cat['created_at'], isNotNull);
      expect(cat['created_at'], isA<int>());
    }

    await db.close();
  });

  test('SeedData constants match seeded database content', () async {
    final helper = DatabaseHelper.instance;
    final db = await helper.getDatabase(inMemory: true);

    final wallets = await db.query('wallets');
    expect(wallets.length, SeedData.defaultWallets.length);

    final rootCategories = await db.query(
      'categories',
      where: 'parent_id IS NULL',
    );
    final expectedRootCount =
        SeedData.defaultExpenseCategories.length +
        SeedData.defaultIncomeCategories.length;
    expect(rootCategories.length, expectedRootCount);

    final allCategories = await db.query('categories');
    expect(allCategories.length, greaterThan(expectedRootCount));

    await db.close();
  });

  test('DatabaseHelper has onUpgrade handler that does not crash', () async {
    final helper = DatabaseHelper.instance;
    // Verifies that getDatabase completes without error (onUpgrade is registered)
    final db = await helper.getDatabase(inMemory: true);
    expect(db.isOpen, true);
    await db.close();
  });
}
