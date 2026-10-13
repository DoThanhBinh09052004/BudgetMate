/// Tập trung toàn bộ magic numbers và config values.
/// Không hardcode giá trị rải rác trong logic nghiệp vụ.
class AppConstants {
  AppConstants._();

  // ── Database ──
  static const String dbName = 'budgetmate.db';
  static const int dbVersion = 1;

  // ── Deduplication ──
  /// Cửa sổ thời gian (giây) cho Dedup Layer 2: giao dịch trong khoảng này
  /// có cùng wallet_id, amount, note sẽ bị coi là trùng lặp.
  static const int deduplicationWindowSeconds = 60;

  // ── Transfer Matcher ──
  /// Cửa sổ thời gian (giây) để ghép cặp chuyển tiền nội bộ.
  static const int transferMatchWindowSeconds = 120;

  /// Từ khóa nhận diện giao dịch chuyển khoản nội bộ.
  /// Thêm từ khóa mới = thêm 1 dòng vào list, không sửa logic.
  static const List<String> transferKeywords = [
    'CK',
    'Chuyen tien',
    'chuyen tien',
    'Chuyển tiền',
    'chuyen khoan',
    'Chuyển khoản',
    'Nap tien',
    'nap tien',
    'Transfer',
    'transfer',
    'MBVCB',
    'IBFT',
  ];

  // ── Parser Confidence ──
  /// Ngưỡng tin cậy tối thiểu. Giao dịch parse được có score < giá trị này
  /// sẽ được gán cờ needs_review = 1.
  static const double minConfidenceScore = 0.8;

  // ── MethodChannel ──
  static const String notificationChannelName =
      'com.budgetmate.bugdetmate/notification_service';

  // ── Branding & Assets ──
  static const String appLogo = 'assets/images/logo.png';
  static const String appLogoJpeg = 'assets/images/logo.jpeg';
}
