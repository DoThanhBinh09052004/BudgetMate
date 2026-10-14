import 'package:sqflite/sqflite.dart';
import 'package:bugdetmate/core/database/tables.dart';

/// Dịch vụ quản lý giao dịch và số dư ví nguyên tử (ACID) trên SQLite.
class TransactionService {
  final Database db;

  TransactionService({required this.db});

  /// Tạo giao dịch mới và cập nhật số dư ví trong cùng một SQLite transaction.
  Future<int> createTransaction({
    required int walletId,
    required double amount,
    required String type, // 'expense' or 'income'
    int? categoryId,
    String? note,
    int? transactionDate,
    String source = 'manual',
    int needsReview = 0,
    int? rawNotificationId,
  }) async {
    return await db.transaction((txn) async {
      final date = transactionDate ?? (DateTime.now().millisecondsSinceEpoch ~/ 1000);

      final txId = await txn.insert(AppTables.transactions, {
        'wallet_id': walletId,
        'category_id': categoryId,
        'amount': amount,
        'type': type,
        'transaction_date': date,
        'note': note?.trim().isEmpty == true ? null : note?.trim(),
        'source': source,
        'needs_review': needsReview,
        'raw_notification_id': rawNotificationId,
      });

      // Cập nhật số dư ví
      final balanceChange = type == 'expense' ? -amount : amount;
      await txn.rawUpdate(
        'UPDATE ${AppTables.wallets} SET balance = balance + ? WHERE id = ?',
        [balanceChange, walletId],
      );

      return txId;
    });
  }

  /// Cập nhật thông tin giao dịch và điều chỉnh số dư ví chính xác.
  Future<void> updateTransaction({
    required int transactionId,
    required int walletId,
    required double newAmount,
    required String newType,
    int? categoryId,
    String? newNote,
    int? newTransactionDate,
  }) async {
    await db.transaction((txn) async {
      // 1. Đọc giao dịch cũ để hoàn trả số dư ban đầu
      final oldTxList = await txn.query(
        AppTables.transactions,
        where: 'id = ?',
        whereArgs: [transactionId],
        limit: 1,
      );

      if (oldTxList.isEmpty) return;
      final oldTx = oldTxList.first;
      final oldWalletId = oldTx['wallet_id'] as int;
      final oldAmount = (oldTx['amount'] as num?)?.toDouble() ?? 0.0;
      final oldType = oldTx['type'] as String? ?? 'expense';

      // Hoàn lại số dư cũ
      final revertChange = oldType == 'expense' ? oldAmount : -oldAmount;
      await txn.rawUpdate(
        'UPDATE ${AppTables.wallets} SET balance = balance + ? WHERE id = ?',
        [revertChange, oldWalletId],
      );

      // Áp dụng số dư mới
      final newBalanceChange = newType == 'expense' ? -newAmount : newAmount;
      await txn.rawUpdate(
        'UPDATE ${AppTables.wallets} SET balance = balance + ? WHERE id = ?',
        [newBalanceChange, walletId],
      );

      // 2. Cập nhật bản ghi giao dịch
      final updateData = <String, dynamic>{
        'wallet_id': walletId,
        'category_id': categoryId,
        'amount': newAmount,
        'type': newType,
        'note': newNote?.trim().isEmpty == true ? null : newNote?.trim(),
      };
      if (newTransactionDate != null) {
        updateData['transaction_date'] = newTransactionDate;
      }

      await txn.update(
        AppTables.transactions,
        updateData,
        where: 'id = ?',
        whereArgs: [transactionId],
      );
    });
  }

  /// Xóa giao dịch và hoàn lại số dư ví ban đầu.
  Future<void> deleteTransaction(int transactionId) async {
    await db.transaction((txn) async {
      final txList = await txn.query(
        AppTables.transactions,
        where: 'id = ?',
        whereArgs: [transactionId],
        limit: 1,
      );

      if (txList.isEmpty) return;
      final tx = txList.first;
      final walletId = tx['wallet_id'] as int;
      final amount = (tx['amount'] as num?)?.toDouble() ?? 0.0;
      final type = tx['type'] as String? ?? 'expense';

      // Hoàn trả số dư ví
      final revertChange = type == 'expense' ? amount : -amount;
      await txn.rawUpdate(
        'UPDATE ${AppTables.wallets} SET balance = balance + ? WHERE id = ?',
        [revertChange, walletId],
      );

      // Xóa bản ghi
      await txn.delete(
        AppTables.transactions,
        where: 'id = ?',
        whereArgs: [transactionId],
      );
    });
  }

  /// Xác nhận giao dịch (bỏ cờ needs_review).
  Future<void> confirmTransaction(int transactionId) async {
    await db.update(
      AppTables.transactions,
      {'needs_review': 0},
      where: 'id = ?',
      whereArgs: [transactionId],
    );
  }

  /// Lấy tổng số dư tất cả các ví.
  Future<double> getTotalBalance() async {
    final rows = await db.rawQuery('SELECT SUM(balance) as total FROM ${AppTables.wallets}');
    return (rows.first['total'] as num?)?.toDouble() ?? 0.0;
  }

  /// Lấy các giao dịch cần xác nhận.
  Future<List<Map<String, dynamic>>> getNeedsReviewTransactions({int limit = 5}) async {
    return await db.query(
      AppTables.transactions,
      where: 'needs_review = ?',
      whereArgs: [1],
      orderBy: 'transaction_date DESC',
      limit: limit,
    );
  }

  /// Lấy danh sách giao dịch gần đây đã JOIN với danh mục và danh mục cha.
  Future<List<Map<String, dynamic>>> getRecentTransactions({int limit = 40}) async {
    return await db.rawQuery('''
      SELECT 
        t.*,
        c.name AS category_name,
        c.icon AS category_icon,
        c.color AS category_color,
        p.name AS parent_name
      FROM ${AppTables.transactions} t
      LEFT JOIN ${AppTables.categories} c ON t.category_id = c.id
      LEFT JOIN ${AppTables.categories} p ON c.parent_id = p.id
      ORDER BY t.transaction_date DESC
      LIMIT ?
    ''', [limit]);
  }

  /// Lấy danh sách danh mục theo loại hoặc theo parent_id.
  Future<List<Map<String, dynamic>>> getCategories({String? type, int? parentId}) async {
    String? whereClause;
    List<dynamic>? whereArgs;

    if (type != null && parentId != null) {
      whereClause = 'type = ? AND parent_id = ?';
      whereArgs = [type, parentId];
    } else if (type != null && parentId == null) {
      whereClause = 'type = ? AND parent_id IS NULL';
      whereArgs = [type];
    } else if (parentId != null) {
      whereClause = 'parent_id = ?';
      whereArgs = [parentId];
    }

    return await db.query(
      AppTables.categories,
      where: whereClause,
      whereArgs: whereArgs,
    );
  }

  /// Lấy danh sách tất cả các ví.
  Future<List<Map<String, dynamic>>> getWallets() async {
    return await db.query(AppTables.wallets);
  }
}
