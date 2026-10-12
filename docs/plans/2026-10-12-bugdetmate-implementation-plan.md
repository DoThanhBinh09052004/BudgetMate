# bugdetmate Implementation Plan (Hardened Edition)

> **For Antigravity:** REQUIRED WORKFLOW: Use `.agent/workflows/execute-plan.md` to execute this plan in single-flow mode.

**Goal:** Xây dựng ứng dụng di động quản lý tài chính cá nhân local-first `bugdetmate` trên nền tảng Flutter 3.47.7 và Pure Java Android Native, tích hợp kiến trúc Raw Buffer chống tràn nền, Deduplication 2 lớp, ghép cặp chuyển tiền nội bộ an toàn và quản lý chi phí cố định chống trừ kép.

**Architecture:** Clean Architecture phân tầng: Core Database (SQLite `sqflite` với 8 bảng dữ liệu), Android Native Java Bridge (`BudgetMateNotificationService.java` & MIUI Rebind), Feature Parser (Dynamic JSON Regex Engine & Raw Notification Batch Sync), Feature Transaction (Two-Tier Deduplication & Safe Transfer Matcher), Feature Budget (Anti-Double-Counting State Machine & Burn-Rate Forecast), và Feature Presentation (UI/UX Pro Max Fintech Dark/Light Theme).

**Tech Stack:** Flutter 3.47.7 (Dart 3.13.5), Pure Java (OpenJDK 17 LTS, Android API 36), SQLite (`sqflite`), `path`, `crypto`, `intl`.

---

### Task 1: Cấu hình Khởi tạo Dự án & Khai báo Dependencies

**Files:**
- Modify: `bugdetmate/pubspec.yaml`
- Modify: `bugdetmate/test/widget_test.dart`

**Step 1: Cập nhật file `pubspec.yaml` với các dependencies cần thiết**

Thêm các package: `sqflite: ^2.4.1`, `path: ^1.9.0`, `intl: ^0.20.2`, `crypto: ^3.0.6` và khai báo thư mục assets `assets/rules/`.

```yaml
dependencies:
  flutter:
    sdk: flutter
  cupertino_icons: ^1.0.8
  sqflite: ^2.4.1
  path: ^1.9.0
  intl: ^0.20.2
  crypto: ^3.0.6

dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^6.0.0
  sqflite_common_ffi: ^2.3.4+4

flutter:
  uses-material-design: true
  assets:
    - assets/rules/
```

**Step 2: Chạy lệnh tải dependencies**

Run:
```bash
flutter pub get
```
Expected: Exit code 0, không có conflict dependency.

**Step 3: Cập nhật widget_test.dart cơ bản để đảm bảo test runner sẵn sàng**

Run:
```bash
flutter test test/widget_test.dart
```
Expected: PASS.

**Step 4: Commit**

```bash
git add pubspec.yaml test/widget_test.dart
git commit -m "chore: setup dependencies and assets configuration"
```

---

### Task 2: Core Database Helper, Schema Migrations & Raw Buffer

**Files:**
- Create: `bugdetmate/lib/core/database/tables.dart`
- Create: `bugdetmate/lib/core/database/database_helper.dart`
- Create: `bugdetmate/test/core/database/database_helper_test.dart`

**Step 1: Viết failing test kiểm tra khởi tạo 8 bảng và seed data**

File: `bugdetmate/test/core/database/database_helper_test.dart`
```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:bugdetmate/core/database/database_helper.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  test('DatabaseHelper creates all 8 tables and seeds default categories and wallets', () async {
    final helper = DatabaseHelper.instance;
    final db = await helper.getDatabase(inMemory: true);

    final tables = await db.rawQuery("SELECT name FROM sqlite_master WHERE type='table';");
    final tableNames = tables.map((t) => t['name'] as String).toList();

    expect(tableNames, contains('wallets'));
    expect(tableNames, contains('categories'));
    expect(tableNames, contains('raw_notifications'));
    expect(tableNames, contains('transactions'));
    expect(tableNames, contains('user_category_rules'));
    expect(tableNames, contains('budgets'));
    expect(tableNames, contains('recurring_rules'));
    expect(tableNames, contains('recurring_payments'));

    final categories = await db.query('categories');
    expect(categories.isNotEmpty, true);

    final wallets = await db.query('wallets');
    expect(wallets.isNotEmpty, true);

    await db.close();
  });
}
```

**Step 2: Chạy test để xác nhận FAIL**

Run: `flutter test test/core/database/database_helper_test.dart`  
Expected: FAIL vì `DatabaseHelper` chưa tồn tại.

**Step 3: Triển khai Tables và DatabaseHelper**

File: `bugdetmate/lib/core/database/tables.dart` định nghĩa schema cho 8 bảng: `wallets`, `categories`, `raw_notifications`, `transactions`, `user_category_rules`, `budgets`, `recurring_rules`, `recurring_payments`.  
File: `bugdetmate/lib/core/database/database_helper.dart` triển khai Singleton pattern, hỗ trợ tham số `inMemory: true` cho testing và mở file SQLite cục bộ khi chạy app thật, cùng hàm seed categories (Ăn uống, Di chuyển, Mua sắm...) và ví mặc định (Tiền mặt, Tài khoản ngân hàng).

**Step 4: Chạy test để xác nhận PASS**

Run: `flutter test test/core/database/database_helper_test.dart`  
Expected: PASS (Exit code 0).

**Step 5: Commit**

```bash
git add lib/core/database/ test/core/database/
git commit -m "feat(database): implement DatabaseHelper with 8 tables schema and seed data"
```

---

### Task 3: Dynamic JSON Regex Parser Engine & Batch Sync Service

**Files:**
- Create: `bugdetmate/assets/rules/bank_rules.json`
- Create: `bugdetmate/lib/features/parser/models/bank_rule_model.dart`
- Create: `bugdetmate/lib/features/parser/services/regex_parser_service.dart`
- Create: `bugdetmate/lib/features/parser/services/raw_sync_service.dart`
- Create: `bugdetmate/test/features/parser/regex_parser_service_test.dart`

**Step 1: Viết failing test cho RegexParserService**

File: `bugdetmate/test/features/parser/regex_parser_service_test.dart`
```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:bugdetmate/features/parser/services/regex_parser_service.dart';

void main() {
  late RegexParserService parser;

  setUp(() {
    parser = RegexParserService();
  });

  test('Parse Techcombank expense notification correctly', () {
    const rawText = "TK 1903xxx890: -50,000 VND luc 12/10/2026 14:30. ND: Highlands Coffee. SD: 12,500,000 VND";
    final result = parser.parse(packageName: 'com.techcombank.mobile', text: rawText);

    expect(result, isNotNull);
    expect(result!.amount, 50000.0);
    expect(result.type, 'expense');
    expect(result.note.toLowerCase(), contains('highlands'));
    expect(result.confidenceScore, greaterThanOrEqualTo(0.8));
  });

  test('Parse Vietcombank income notification correctly', () {
    const rawText = "VCB: +2,000,000 VND vao TK 0011xxx tại 12/10/2026. Ref: Luong thang 10. SD: 15,000,000 VND";
    final result = parser.parse(packageName: 'com.VCB', text: rawText);

    expect(result, isNotNull);
    expect(result!.amount, 2000000.0);
    expect(result.type, 'income');
    expect(result.note.toLowerCase(), contains('luong'));
  });
}
```

**Step 2: Chạy test để xác nhận FAIL**

Run: `flutter test test/features/parser/regex_parser_service_test.dart`  
Expected: FAIL.

**Step 3: Triển khai bank_rules.json, BankRuleModel, RegexParserService và RawSyncService**

- `assets/rules/bank_rules.json`: Chứa patterns cho TCB, VCB, MB, MoMo, ZaloPay.
- `regex_parser_service.dart`: Xử lý Regex bóc tách `amount`, chuẩn hóa định dạng số tiền Việt Nam (`.` và `,`), xác định dấu `+`/`-`, trích xuất note và tính điểm tin cậy `confidenceScore`.
- `raw_sync_service.dart`: Đọc các bản ghi `is_processed = 0` từ bảng `raw_notifications`, gọi `RegexParserService` bóc tách và đẩy sang bảng `transactions`, sau đó đánh dấu `is_processed = 1`.

**Step 4: Chạy test để xác nhận PASS**

Run: `flutter test test/features/parser/regex_parser_service_test.dart`  
Expected: PASS.

**Step 5: Commit**

```bash
git add assets/rules/ lib/features/parser/ test/features/parser/
git commit -m "feat(parser): add json-driven regex parser engine and raw sync service"
```

---

### Task 4: Two-Tier Deduplication & Safe Internal Transfer Matcher Engine

**Files:**
- Create: `bugdetmate/lib/features/transactions/services/deduplication_service.dart`
- Create: `bugdetmate/lib/features/transactions/services/transfer_matcher_service.dart`
- Create: `bugdetmate/test/features/transactions/transfer_matcher_test.dart`
- Create: `bugdetmate/test/features/transactions/deduplication_test.dart`

**Step 1: Viết failing test cho Deduplication (Lớp 2 SQLite) & Transfer Matcher An Toàn**

Test kịch bản:
- Giao dịch có cùng `wallet_id`, `amount`, `note` phát sinh trong vòng 45s $\rightarrow$ Deduplication đánh dấu trùng, không tạo thêm bản ghi.
- 1 giao dịch `-500.000đ` (Ví A) và 1 giao dịch `+500.000đ` (Ví B) phát sinh cách nhau 30s, có từ khóa "Chuyển tiền nội bộ", cả Ví A & Ví B đều là ví của người dùng $\rightarrow$ Tự động ghép cặp chuyển sang `type = 'transfer'` và gắn `transfer_pair_id`.
- 1 giao dịch `-500.000đ` và 1 giao dịch `+500.000đ` nhưng không có từ khóa chuyển khoản $\rightarrow$ Giữ nguyên thu/chi và gắn cờ `needs_review = 1`.

**Step 2: Chạy test để xác nhận FAIL**

Run: `flutter test test/features/transactions/transfer_matcher_test.dart test/features/transactions/deduplication_test.dart`  
Expected: FAIL.

**Step 3: Triển khai DeduplicationService & TransferMatcherService**

Triển khai logic kiểm tra truy vấn SQLite theo khoảng thời gian $\pm 60$ giây và thuật toán đối soát 4 tiêu chí an toàn cho chuyển tiền nội bộ.

**Step 4: Chạy test để xác nhận PASS**

Run: `flutter test test/features/transactions/transfer_matcher_test.dart test/features/transactions/deduplication_test.dart`  
Expected: PASS.

**Step 5: Commit**

```bash
git add lib/features/transactions/ test/features/transactions/
git commit -m "feat(transactions): implement two-tier deduplication and safe transfer matcher"
```

---

### Task 5: Android Native Java Notification Listener Service & MIUI Rebind Bridge

**Files:**
- Create: `bugdetmate/android/app/src/main/java/com/budgetmate/bugdetmate/BudgetMateNotificationService.java`
- Modify: `bugdetmate/android/app/src/main/java/com/budgetmate/bugdetmate/MainActivity.java`
- Modify: `bugdetmate/android/app/src/main/AndroidManifest.xml`
- Create: `bugdetmate/lib/core/native_bridge/notification_bridge.dart`

**Step 1: Cấu hình `AndroidManifest.xml`**

Thêm quyền và khai báo Service thuần Java:
```xml
<uses-permission android:name="android.permission.POST_NOTIFICATIONS"/>

<service
    android:name=".BudgetMateNotificationService"
    android:label="BudgetMate Notification Listener"
    android:permission="android.permission.BIND_NOTIFICATION_LISTENER_SERVICE"
    android:exported="true">
    <intent-filter>
        <action android:name="android.service.notification.NotificationListenerService" />
    </intent-filter>
</service>
```

**Step 2: Triển khai `BudgetMateNotificationService.java` thuần Java**

- Kế thừa `NotificationListenerService`.
- Whitelist các package ngân hàng (`com.techcombank.mobile`, `com.VCB`, `com.mbmobile`, `com.mservice.momopay`...).
- Kiểm tra `sbn.getKey()` để chặn trùng lặp Lớp 1.
- Mở SQLite database trực tiếp (hoặc buffer SharedPreferences) để ghi vào bảng `raw_notifications`.

**Step 3: Triển khai `MainActivity.java` với MethodChannel**

- Cung cấp method `checkNotificationPermission()`: Kiểm tra quyền Listener.
- Cung cấp method `requestNotificationPermission()`: Mở thẳng màn hình cài đặt cấp quyền thông báo.
- Cung cấp method `rebindService()`: Tự động kích hoạt lại service bằng `PackageManager.setComponentEnabledSetting` để chống MIUI silent-kill.

**Step 4: Triển khai `notification_bridge.dart` trong Flutter**

Gọi MethodChannel `com.budgetmate.bugdetmate/notification_service` để kết nối Flutter và Java.

**Step 5: Commit**

```bash
git add android/ lib/core/native_bridge/
git commit -m "feat(android): implement pure Java BudgetMateNotificationService and MIUI rebind bridge"
```

---

### Task 6: Budgeting, Recurring Payments State Machine (Anti-Double-Counting) & Burn-rate

**Files:**
- Create: `bugdetmate/lib/features/budget/models/budget_model.dart`
- Create: `bugdetmate/lib/features/budget/models/recurring_payment_model.dart`
- Create: `bugdetmate/lib/features/budget/services/budget_service.dart`
- Create: `bugdetmate/test/features/budget/budget_service_test.dart`

**Step 1: Viết failing test cho BudgetService**

Kiểm tra:
- Chu kỳ lương linh hoạt (bắt đầu ngày 5, 10, 15...).
- Công thức số dư khả dụng thực tế với bảng `recurring_payments`: Khi chi phí cố định (vd: Tiền nhà 5tr) được đánh dấu `is_paid = 1`, hệ thống loại bỏ khỏi "chi phí cố định chờ trừ" và tính vào chi tiêu thực tế, không bị trừ 2 lần.
- Tính toán Burn-rate và cảnh báo nguy cơ vượt ngân sách trước ngày nhận lương tiếp theo.

**Step 2: Chạy test để xác nhận FAIL**

Run: `flutter test test/features/budget/budget_service_test.dart`  
Expected: FAIL.

**Step 3: Triển khai BudgetService và Models**

Xây dựng logic truy vấn tính tổng chi tiêu thực tế, tổng chi phí cố định chưa thanh toán trong chu kỳ và tốc độ tiêu dùng hàng ngày.

**Step 4: Chạy test để xác nhận PASS**

Run: `flutter test test/features/budget/budget_service_test.dart`  
Expected: PASS.

**Step 5: Commit**

```bash
git add lib/features/budget/ test/features/budget/
git commit -m "feat(budget): implement budget engine with anti-double-counting recurring payments state machine"
```

---

### Task 7: Presentation Layer (UI/UX Pro Max Fintech Dark/Light, Quick Add & MIUI Setup)

**Files:**
- Create: `bugdetmate/lib/core/theme/app_theme.dart`
- Create: `bugdetmate/lib/features/home/screens/home_screen.dart`
- Create: `bugdetmate/lib/features/transactions/screens/quick_add_sheet.dart`
- Create: `bugdetmate/lib/features/settings/screens/miui_guide_screen.dart`
- Modify: `bugdetmate/lib/main.dart`
- Create: `bugdetmate/test/features/home/home_screen_test.dart`

**Step 1: Viết UI test cho Home Screen**

Kiểm tra hiển thị:
- Card Tổng số dư và Ngân sách khả dụng.
- Nút bấm Quick Add (FAB).
- Banner/Card cảnh báo giao dịch `needs_review` nếu có.

**Step 2: Chạy test để xác nhận FAIL**

Run: `flutter test test/features/home/home_screen_test.dart`  
Expected: FAIL.

**Step 3: Triển khai AppTheme, HomeScreen, QuickAddSheet và MiuiGuideScreen**

- `app_theme.dart`: Chuẩn UI/UX Pro Max Fintech (Bảng màu Trust Blue, Thẻ Glassmorphic nền tối `0F172A`, font chữ rõ ràng, độ tương phản cao).
- `quick_add_sheet.dart`: Numpad kích thước lớn, các phím tắt nhanh `50k`, `100k`, `200k`, `500k`, hỗ trợ phép tính `+`, `-`, grid danh mục 4 cột.
- `miui_guide_screen.dart`: Hướng dẫn trực quan từng bước cho người dùng Redmi Note 11 (Cấp quyền Truy cập thông báo, Bật Tự khởi chạy, Tắt Tiết kiệm pin cho ứng dụng).
- `main.dart`: Kết nối theme, khởi tạo SQLite và gọi đồng bộ nền khi mở app.

**Step 4: Chạy toàn bộ test suites của dự án**

Run: `flutter test`  
Expected: 100% tests PASS.

**Step 5: Commit**

```bash
git add lib/ test/
git commit -m "feat(ui): implement fintech dark/light UI, quick add sheet and MIUI guide screen"
```
