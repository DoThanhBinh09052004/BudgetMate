import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';
import 'package:bugdetmate/core/constants/app_constants.dart';
import 'package:bugdetmate/core/database/tables.dart';
import 'package:bugdetmate/core/database/seed_data.dart';

class DatabaseHelper {
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
        version: AppConstants.dbVersion,
        onCreate: _onCreate,
        onUpgrade: _onUpgrade,
        onConfigure: _onConfigure,
      );
    }

    if (_database != null && _database!.isOpen) {
      return _database!;
    }

    final dbPath = await getDatabasesPath();
    final path = p.join(dbPath, AppConstants.dbName);

    _database = await openDatabase(
      path,
      version: AppConstants.dbVersion,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
      onConfigure: _onConfigure,
    );

    return _database!;
  }

  Future<void> _onConfigure(Database db) async {
    await db.execute('PRAGMA foreign_keys = ON;');
  }

  Future<void> _onCreate(Database db, int version) async {
    final batch = db.batch();

    // Create all tables
    for (final sql in AppTables.allCreateTableStatements) {
      batch.execute(sql);
    }

    // Create all indexes
    for (final sql in AppTables.allCreateIndexStatements) {
      batch.execute(sql);
    }

    await batch.commit(noResult: true);

    await _seedDefaults(db);
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    // Migration scripts go here, executed sequentially.
    // Each migration block handles upgrading from one version to the next.
    //
    // Example for future migrations:
    // if (oldVersion < 2) {
    //   await db.execute('ALTER TABLE wallets ADD COLUMN bank_code TEXT;');
    // }
    // if (oldVersion < 3) { ... }
  }

  Future<void> _seedDefaults(Database db) async {
    final seedBatch = db.batch();

    // Default Wallets
    for (final wallet in SeedData.defaultWallets) {
      seedBatch.insert(AppTables.wallets, wallet);
    }

    // Default Expense Categories
    for (final cat in SeedData.defaultExpenseCategories) {
      seedBatch.insert(AppTables.categories, {
        'name': cat['name'],
        'type': 'expense',
        'icon': cat['icon'],
        'color': cat['color'],
        'is_default': 1,
      });
    }

    // Default Income Categories
    for (final cat in SeedData.defaultIncomeCategories) {
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
