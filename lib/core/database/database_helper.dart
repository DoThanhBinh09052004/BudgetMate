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
      _database = await openDatabase(
        inMemoryDatabasePath,
        version: AppConstants.dbVersion,
        onCreate: _onCreate,
        onUpgrade: _onUpgrade,
        onConfigure: _onConfigure,
      );
      return _database!;
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
    if (oldVersion < 2) {
      await db.execute(
        'ALTER TABLE ${AppTables.categories} ADD COLUMN parent_id INTEGER REFERENCES ${AppTables.categories}(id) ON DELETE CASCADE;',
      );
    }
  }

  Future<void> _seedDefaults(Database db) async {
    // Default Wallets
    final walletBatch = db.batch();
    for (final wallet in SeedData.defaultWallets) {
      walletBatch.insert(AppTables.wallets, wallet);
    }
    await walletBatch.commit(noResult: true);

    // Default Expense Categories (Cha & Con)
    for (final cat in SeedData.defaultExpenseCategories) {
      final parentId = await db.insert(AppTables.categories, {
        'name': cat['name'],
        'type': 'expense',
        'icon': cat['icon'],
        'color': cat['color'],
        'parent_id': null,
        'is_default': 1,
      });

      final children = (cat['children'] as List<dynamic>?) ?? [];
      if (children.isNotEmpty) {
        final childBatch = db.batch();
        for (final child in children) {
          childBatch.insert(AppTables.categories, {
            'name': child['name'],
            'type': 'expense',
            'icon': child['icon'],
            'color': cat['color'],
            'parent_id': parentId,
            'is_default': 1,
          });
        }
        await childBatch.commit(noResult: true);
      }
    }

    // Default Income Categories (Cha & Con)
    for (final cat in SeedData.defaultIncomeCategories) {
      final parentId = await db.insert(AppTables.categories, {
        'name': cat['name'],
        'type': 'income',
        'icon': cat['icon'],
        'color': cat['color'],
        'parent_id': null,
        'is_default': 1,
      });

      final children = (cat['children'] as List<dynamic>?) ?? [];
      if (children.isNotEmpty) {
        final childBatch = db.batch();
        for (final child in children) {
          childBatch.insert(AppTables.categories, {
            'name': child['name'],
            'type': 'income',
            'icon': child['icon'],
            'color': cat['color'],
            'parent_id': parentId,
            'is_default': 1,
          });
        }
        await childBatch.commit(noResult: true);
      }
    }
  }

  Future<void> close() async {
    if (_database != null && _database!.isOpen) {
      await _database!.close();
      _database = null;
    }
  }
}
