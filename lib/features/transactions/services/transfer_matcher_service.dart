import 'package:sqflite/sqflite.dart';
import 'package:bugdetmate/core/database/tables.dart';
import 'package:bugdetmate/core/constants/app_constants.dart';

/// Ghép cặp chuyển tiền nội bộ an toàn.
/// Dùng AppConstants.transferMatchWindowSeconds và AppConstants.transferKeywords.
class TransferMatcherService {
  final Database db;

  TransferMatcherService({required this.db});

  /// Tìm và ghép cặp chuyển tiền nội bộ cho một giao dịch mới.
  /// Trả về true nếu tự động ghép cặp thành công, false nếu không.
  Future<bool> matchTransfers({
    required int transactionId,
    required List<int> walletIds,
  }) async {
    final tx = await db.query(
      AppTables.transactions,
      where: 'id = ?',
      whereArgs: [transactionId],
    );

    if (tx.isEmpty) return false;
    final current = tx.first;

    final currentWalletId = current['wallet_id'] as int;
    final currentAmount = current['amount'] as double;
    final currentDate = current['transaction_date'] as int;
    final currentType = current['type'] as String;
    final currentNote = current['note'] as String? ?? '';

    // Xác định loại đối ứng
    final oppositeType = currentType == 'expense' ? 'income' : 'expense';

    // Tìm giao dịch đối ứng: cùng số tiền, khác ví, trong cửa sổ thời gian
    final candidates = await db.query(
      AppTables.transactions,
      where: '''
        id != ? AND wallet_id != ? AND wallet_id IN (${walletIds.map((_) => '?').join(',')})
        AND amount = ? AND type = ?
        AND ABS(transaction_date - ?) <= ?
        AND transfer_pair_id IS NULL
      ''',
      whereArgs: [
        transactionId,
        currentWalletId,
        ...walletIds,
        currentAmount,
        oppositeType,
        currentDate,
        AppConstants.transferMatchWindowSeconds,
      ],
      orderBy: 'ABS(transaction_date - $currentDate) ASC',
      limit: 1,
    );

    if (candidates.isEmpty) return false;

    final candidate = candidates.first;
    final candidateId = candidate['id'] as int;
    final candidateNote = candidate['note'] as String? ?? '';

    // Kiểm tra từ khóa chuyển khoản
    final hasKeyword = _containsTransferKeyword(currentNote) ||
        _containsTransferKeyword(candidateNote);

    if (hasKeyword) {
      // Tự động ghép cặp
      await db.update(
        AppTables.transactions,
        {'type': 'transfer', 'transfer_pair_id': candidateId},
        where: 'id = ?',
        whereArgs: [transactionId],
      );
      await db.update(
        AppTables.transactions,
        {'type': 'transfer', 'transfer_pair_id': transactionId},
        where: 'id = ?',
        whereArgs: [candidateId],
      );
      return true;
    } else {
      // Trùng tiền trong cửa sổ thời gian nhưng không có từ khóa → gắn cờ review
      await db.update(
        AppTables.transactions,
        {'needs_review': 1},
        where: 'id = ?',
        whereArgs: [transactionId],
      );
      return false;
    }
  }

  /// Kiểm tra xem text có chứa bất kỳ từ khóa chuyển khoản nào không.
  /// Keywords lấy từ AppConstants, không hardcode.
  bool _containsTransferKeyword(String text) {
    final lowerText = text.toLowerCase();
    return AppConstants.transferKeywords.any(
      (keyword) => lowerText.contains(keyword.toLowerCase()),
    );
  }
}
