import 'package:sqflite/sqflite.dart';
import 'package:bugdetmate/core/database/tables.dart';
import 'package:bugdetmate/core/constants/app_constants.dart';

/// Kiểm tra trùng lặp Layer 2 (SQLite) bằng cửa sổ thời gian.
/// Dùng AppConstants.deduplicationWindowSeconds thay vì hardcode.
class DeduplicationService {
  final Database db;

  DeduplicationService({required this.db});

  /// Kiểm tra xem giao dịch có trùng với giao dịch đã tồn tại trong cửa sổ thời gian không.
  Future<bool> isDuplicate({
    required int walletId,
    required double amount,
    required String note,
    required int transactionDate,
  }) async {
    final results = await db.query(
      AppTables.transactions,
      where: 'wallet_id = ? AND amount = ? AND note = ? AND ABS(transaction_date - ?) <= ?',
      whereArgs: [
        walletId,
        amount,
        note,
        transactionDate,
        AppConstants.deduplicationWindowSeconds,
      ],
      limit: 1,
    );

    return results.isNotEmpty;
  }
}
