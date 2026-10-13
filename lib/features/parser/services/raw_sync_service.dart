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
  /// Trả về số lượng giao dịch được tạo mới.
  Future<int> syncUnprocessed() async {
    final unprocessed = await db.query(
      AppTables.rawNotifications,
      where: 'is_processed = ?',
      whereArgs: [0],
      orderBy: 'post_time ASC',
    );

    int created = 0;

    for (final raw in unprocessed) {
      final id = raw['id'] as int;
      final packageName = raw['package_name'] as String;
      final text = raw['text'] as String? ?? '';

      final parsed = parser.parse(packageName: packageName, text: text);

      if (parsed != null) {
        await db.insert(AppTables.transactions, {
          'wallet_id': 1, // Default wallet fallback; auto-map by accountSuffix in Task 4+
          'amount': parsed.amount,
          'type': parsed.type,
          'transaction_date': raw['post_time'],
          'note': parsed.note,
          'source': 'auto_notification',
          'raw_notification_id': id,
          'needs_review': parsed.confidenceScore < AppConstants.minConfidenceScore ? 1 : 0,
        });
        created++;
      }

      // Đánh dấu đã xử lý dù parse thành công hay không
      await db.update(
        AppTables.rawNotifications,
        {'is_processed': 1},
        where: 'id = ?',
        whereArgs: [id],
      );
    }

    return created;
  }
}
