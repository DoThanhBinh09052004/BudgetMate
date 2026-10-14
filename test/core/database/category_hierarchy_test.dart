import 'package:flutter_test/flutter_test.dart';
import 'package:bugdetmate/core/database/database_helper.dart';
import 'package:bugdetmate/core/database/tables.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  test('Categories table should support parent_id hierarchy and seed subcategories', () async {
    final db = await DatabaseHelper.instance.getDatabase(inMemory: true);

    // 1. Kiểm tra seed data mặc định đã có danh mục cha và danh mục con
    final allCategories = await db.query(AppTables.categories);
    final parents = allCategories.where((c) => c['parent_id'] == null).toList();
    final children = allCategories.where((c) => c['parent_id'] != null).toList();

    expect(parents.isNotEmpty, true, reason: 'Phải có danh mục cha mặc định');
    expect(children.isNotEmpty, true, reason: 'Phải có danh mục con mặc định');

    // Kiểm tra danh mục Ăn uống có các con: Cơm trưa / tối, Trà sữa & Cà phê...
    final foodParent = parents.firstWhere((c) => c['name'] == 'Ăn uống');
    final foodChildren = children.where((c) => c['parent_id'] == foodParent['id']).map((c) => c['name'] as String).toList();
    expect(foodChildren, contains('Cơm trưa / tối'));
    expect(foodChildren, contains('Trà sữa & Cà phê'));

    // 2. Thử insert danh mục con tùy chỉnh
    final customChildId = await db.insert(AppTables.categories, {
      'name': 'Bánh tráng trộn',
      'type': 'expense',
      'icon': 'coffee',
      'color': '#F97316',
      'parent_id': foodParent['id'],
      'is_default': 0,
    });
    expect(customChildId, isPositive);

    final updatedChildren = await db.query(
      AppTables.categories,
      where: 'parent_id = ?',
      whereArgs: [foodParent['id']],
    );
    expect(updatedChildren.any((c) => c['name'] == 'Bánh tráng trộn'), true);
  });
}
