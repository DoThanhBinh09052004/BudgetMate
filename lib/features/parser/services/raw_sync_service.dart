import 'package:sqflite/sqflite.dart';
import 'package:bugdetmate/core/database/tables.dart';
import 'package:bugdetmate/core/constants/app_constants.dart';
import 'package:bugdetmate/features/parser/services/regex_parser_service.dart';

/// Đọc raw_notifications chưa xử lý, parse và đẩy sang bảng transactions.
class RawSyncService {
  final Database db;
  final RegexParserService parser;

  RawSyncService({required this.db, required this.parser});

  /// Xử lý tất cả raw_notifications chưa parse (is_processed = 0).
  /// Đảm bảo tính nguyên tử (ACID) và cập nhật số dư ví tương ứng.
  /// Trả về số lượng giao dịch được tạo mới.
  Future<int> syncUnprocessed() async {
    final unprocessed = await db.query(
      AppTables.rawNotifications,
      where: 'is_processed = ?',
      whereArgs: [0],
      orderBy: 'post_time ASC',
    );

    if (unprocessed.isEmpty) return 0;

    int created = 0;

    await db.transaction((txn) async {
      // Xác định ví mặc định (ưu tiên ví 1, fallback về ví đầu tiên)
      final wallets = await txn.query(
        AppTables.wallets,
        columns: ['id'],
        limit: 1,
      );
      final defaultWalletId = wallets.isNotEmpty
          ? wallets.first['id'] as int
          : 1;

      for (final raw in unprocessed) {
        final id = raw['id'] as int;
        final packageName = raw['package_name'] as String;
        final text = raw['text'] as String? ?? '';
        final title = raw['title'] as String? ?? '';

        final parsed = parser.parse(
          packageName: packageName,
          text: text,
          title: title,
        );

        if (parsed != null) {
          final cleanNote = parsed.note.trim().isEmpty ? null : parsed.note.trim();
          await txn.insert(AppTables.transactions, {
            'wallet_id': defaultWalletId,
            'amount': parsed.amount,
            'type': parsed.type,
            'transaction_date': raw['post_time'],
            'note': cleanNote,
            'source': 'auto_notification',
            'raw_notification_id': id,
            'needs_review':
                parsed.confidenceScore < AppConstants.minConfidenceScore
                ? 1
                : 0,
          });

          // Cập nhật số dư ví nguyên tử
          final balanceChange = parsed.type == 'expense'
              ? -parsed.amount
              : parsed.amount;
          await txn.rawUpdate(
            'UPDATE ${AppTables.wallets} SET balance = balance + ? WHERE id = ?',
            [balanceChange, defaultWalletId],
          );

          created++;
        }

        // Đánh dấu đã xử lý dù parse thành công hay không
        await txn.update(
          AppTables.rawNotifications,
          {'is_processed': 1},
          where: 'id = ?',
          whereArgs: [id],
        );
      }
    });

    return created;
  }
}
