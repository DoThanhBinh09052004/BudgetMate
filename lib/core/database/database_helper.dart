import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';
import 'package:bugdetmate/core/database/tables.dart';

class DatabaseHelper {
  static const String _dbName = 'budgetmate.db';
  static const int _dbVersion = 1;

  DatabaseHelper._internal();
  static final DatabaseHelper instance = DatabaseHelper._internal();

  Database? _database;

  Future<Database> get database async {
    if (_database != null && _database!.isOpen) {
      return _database!;
    }
    _database = await getDatabase();
    return _database!;
  }

  Future<Database> getDatabase({bool inMemory = false}) async {
    if (inMemory) {
      return await openDatabase(
        inMemoryDatabasePath,
        version: _dbVersion,
        onCreate: _onCreate,
        onConfigure: _onConfigure,
      );
    }

    if (_database != null && _database!.isOpen) {
      return _database!;
    }

    final dbPath = await getDatabasesPath();
    final path = p.join(dbPath, _dbName);

    _database = await openDatabase(
      path,
      version: _dbVersion,
      onCreate: _onCreate,
      onConfigure: _onConfigure,
    );

    return _database!;
  }

  Future<void> _onConfigure(Database db) async {
    await db.execute('PRAGMA foreign_keys = ON;');
  }

  Future<void> _onCreate(Database db, int version) async {
    final batch = db.batch();

    batch.execute(AppTables.createWallets);
    batch.execute(AppTables.createCategories);
    batch.execute(AppTables.createRawNotifications);
    batch.execute(AppTables.createTransactions);
    batch.execute(AppTables.createUserCategoryRules);
    batch.execute(AppTables.createBudgets);
    batch.execute(AppTables.createRecurringRules);
    batch.execute(AppTables.createRecurringPayments);

    await batch.commit(noResult: true);

    await _seedDefaults(db);
  }

  Future<void> _seedDefaults(Database db) async {
    final seedBatch = db.batch();

    // Default Wallets
    seedBatch.insert(AppTables.wallets, {
      'name': 'Tiền mặt',
      'type': 'cash',
      'balance': 0.0,
      'account_number_suffix': null,
      'icon': 'cash',
      'color': '#10B981',
    });
    seedBatch.insert(AppTables.wallets, {
      'name': 'Tài khoản ngân hàng',
      'type': 'bank',
      'balance': 0.0,
      'account_number_suffix': null,
      'icon': 'account_balance',
      'color': '#1E40AF',
    });

    // Default Expense Categories
    final expenseCategories = [
      {'name': 'Ăn uống', 'icon': 'restaurant', 'color': '#EF4444'},
      {'name': 'Di chuyển', 'icon': 'directions_car', 'color': '#F59E0B'},
      {'name': 'Mua sắm', 'icon': 'shopping_bag', 'color': '#EC4899'},
      {'name': 'Hóa đơn & Dịch vụ', 'icon': 'receipt_long', 'color': '#3B82F6'},
      {'name': 'Nhà cửa', 'icon': 'home', 'color': '#8B5CF6'},
      {'name': 'Chuyển tiền nội bộ', 'icon': 'swap_horiz', 'color': '#64748B'},
    ];

    for (final cat in expenseCategories) {
      seedBatch.insert(AppTables.categories, {
        'name': cat['name'],
        'type': 'expense',
        'icon': cat['icon'],
        'color': cat['color'],
        'is_default': 1,
      });
    }

    // Default Income Categories
    final incomeCategories = [
      {'name': 'Lương', 'icon': 'payments', 'color': '#059669'},
      {'name': 'Thưởng', 'icon': 'card_giftcard', 'color': '#10B981'},
      {'name': 'Thu nhập khác', 'icon': 'add_circle', 'color': '#06B6D4'},
    ];

    for (final cat in incomeCategories) {
      seedBatch.insert(AppTables.categories, {
        'name': cat['name'],
        'type': 'income',
        'icon': cat['icon'],
        'color': cat['color'],
        'is_default': 1,
      });
    }

    await seedBatch.commit(noResult: true);
  }

  Future<void> close() async {
    if (_database != null && _database!.isOpen) {
      await _database!.close();
      _database = null;
    }
  }
}
