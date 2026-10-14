# Transaction Display Clarification & QuickAddSheet Clean Implementation Plan

> **For Antigravity:** REQUIRED WORKFLOW: Use `.agent/workflows/execute-plan.md` to execute this plan in single-flow mode.

**Goal:** Hiển thị chính xác tên danh mục chi tiêu (ví dụ: "Ăn uống", "Ăn uống › Cơm trưa", hoặc ghi chú rõ ràng, loại bỏ hoàn toàn tình trạng tiêu đề rỗng/chung chung) trên `RecentTransactionsSection` của `HomeScreen`, đồng thời làm gọn màn hình `QuickAddSheet` bằng cách loại bỏ dấu cộng/trừ ở số tiền lớn và các phím tắt nhanh (`50k`, `100k` thay vì `+50k`, `+100k`).

**Architecture:** 
1. `QuickAddSheet`: Đơn giản hóa hiển thị số tiền (`$displayAmount` thuần số, không prefix `+` hoặc `-`) và đổi nhãn chip phím tắt từ `+50k` thành `50k`. Đảm bảo danh mục được chọn luôn gán vào `_selectedCategoryId`.
2. `RecentTransactionsSection`: Tinh chỉnh logic trích xuất `title` và `subtitle` để ưu tiên `parentName › catName` > `catName` > `note` > mặc định loại giao dịch, ngăn chặn triệt để trường hợp `note` rỗng `""` làm rỗng tiêu đề.
3. Đồng bộ hóa kiểm thử Widget test (`quick_add_sheet_test.dart`, `home_screen_grouped_test.dart`) theo TDD.

**Tech Stack:** Flutter 3, Dart, SQLite (`sqflite`), `intl`.

---

### Task 1: Làm gọn số tiền và phím tắt nhanh trong `QuickAddSheet` (Bỏ dấu +/-)

**Files:**
- Modify: `lib/features/transactions/screens/quick_add_sheet.dart`
- Test: `test/features/transactions/quick_add_sheet_test.dart`

**Step 1: Cập nhật failing test `quick_add_sheet_test.dart`**
Đổi tìm kiếm chip phím tắt từ `+50k` sang `50k` và xác nhận hiển thị số tiền thuần túy:

```dart
// test/features/transactions/quick_add_sheet_test.dart
// Thay đổi tại bước nhấn chip:
await tester.tap(find.text('50k'));
await tester.pump();
```

**Step 2: Chạy test để xác nhận FAIL**
Run: `flutter test test/features/transactions/quick_add_sheet_test.dart`
Expected: FAIL với lỗi `findsNothing` đối với text `'50k'`.

**Step 3: Triển khai trong `QuickAddSheet`**
1. Đổi hiển thị số tiền chính tại dòng 295-300:
   - Trước: `_type == 'expense' ? '-$displayAmount' : '+$displayAmount'`
   - Sau: `displayAmount` (vẫn giữ màu `expenseRed` hoặc `primaryGreen` để phân biệt trực quan).
2. Đổi các chip phím tắt nhanh tại dòng 321-325:
   - `_buildQuickChip('50k', 50000)`
   - `_buildQuickChip('100k', 100000)`
   - `_buildQuickChip('200k', 200000)`
   - `_buildQuickChip('500k', 500000)`
   - `_buildQuickChip('1M', 1000000)`

**Step 4: Chạy test để xác nhận PASS**
Run: `flutter test test/features/transactions/quick_add_sheet_test.dart`
Expected: PASS.

**Step 5: Commit**
```bash
git add lib/features/transactions/screens/quick_add_sheet.dart test/features/transactions/quick_add_sheet_test.dart
git commit -m "style: remove +/- prefix from amount display and quick chips in QuickAddSheet"
```

---

### Task 2: Chuẩn hóa hiển thị tên danh mục giao dịch trên `RecentTransactionsSection`

**Files:**
- Modify: `lib/features/home/widgets/recent_transactions_section.dart`
- Test: `test/features/home/home_screen_grouped_test.dart`

**Step 1: Viết test cho trường hợp hiển thị danh mục chính xác và chống rỗng tiêu đề**

Bổ sung test case trong `test/features/home/home_screen_grouped_test.dart`:
- Giao dịch có `category_name` = 'Ăn uống' -> hiển thị tiêu đề 'Ăn uống'.
- Giao dịch có `parent_name` = 'Ăn uống' và `category_name` = 'Cơm trưa' -> hiển thị 'Ăn uống › Cơm trưa'.
- Giao dịch có `note` = 'Highlands' và không có danh mục -> hiển thị tiêu đề 'Highlands'.
- Giao dịch có `note` = '' (chuỗi rỗng) và không có danh mục -> fallback 'Chi tiêu' hoặc 'Thu nhập', không để rỗng tiêu đề.

**Step 2: Chạy test để xác nhận trạng thái hiện tại**
Run: `flutter test test/features/home/home_screen_grouped_test.dart`

**Step 3: Cập nhật logic trích xuất tiêu đề trong `RecentTransactionsSection`**

```dart
// lib/features/home/widgets/recent_transactions_section.dart
final trimmedCat = catName?.trim();
final trimmedParent = parentName?.trim();
final trimmedNote = note?.trim();

String title;
if (trimmedParent != null && trimmedParent.isNotEmpty &&
    trimmedCat != null && trimmedCat.isNotEmpty) {
  title = '$trimmedParent › $trimmedCat';
} else if (trimmedCat != null && trimmedCat.isNotEmpty) {
  title = trimmedCat;
} else if (trimmedNote != null && trimmedNote.isNotEmpty) {
  title = trimmedNote;
} else {
  title = type == 'expense' ? 'Chi tiêu' : 'Thu nhập';
}

final hasNote = trimmedNote != null && trimmedNote.isNotEmpty;
final isTitleSameAsNote = hasNote && title == trimmedNote;
final subtitle = (hasNote && !isTitleSameAsNote)
    ? '$trimmedNote • $timeString'
    : timeString;
```

**Step 4: Chạy test để xác nhận PASS**
Run: `flutter test test/features/home/home_screen_grouped_test.dart`
Expected: PASS.

**Step 5: Commit**
```bash
git add lib/features/home/widgets/recent_transactions_section.dart test/features/home/home_screen_grouped_test.dart
git commit -m "fix: ensure explicit category display and guard against blank titles in recent transactions"
```

---

### Task 3: Đảm bảo tự động gán danh mục khi đồng bộ thông báo ngân hàng (`RawSyncService`)

**Files:**
- Modify: `lib/features/parser/services/raw_sync_service.dart`
- Test: `test/features/parser/raw_sync_service_test.dart`

**Step 1: Viết test kiểm tra gán danh mục mặc định hoặc bóc tách từ note**
Kiểm tra khi đồng bộ thông báo, nếu không tìm thấy danh mục cụ thể thì gán danh mục mặc định (hoặc lưu `note` sạch sẽ để `HomeScreen` luôn hiển thị được nội dung giao dịch thay vì chữ "Chi tiêu" chung chung).

**Step 2: Chạy test để xác nhận kết quả**
Run: `flutter test test/features/parser/raw_sync_service_test.dart`

**Step 3: Cập nhật `RawSyncService`**
Đảm bảo trường `note` khi bóc tách từ ngân hàng luôn được trim sạch và nếu có rule danh mục tương ứng thì map tự động `category_id`.

**Step 4: Chạy test để xác nhận PASS**
Run: `flutter test test/features/parser/raw_sync_service_test.dart`
Expected: PASS.

**Step 5: Commit**
```bash
git add lib/features/parser/services/raw_sync_service.dart test/features/parser/raw_sync_service_test.dart
git commit -m "feat: enhance transaction note and category mapping during bank notification sync"
```

---

### Task 4: Kiểm thử toàn diện & Đảm bảo 0 Warnings

**Files:**
- Toàn bộ dự án.

**Step 1: Chạy format**
Run: `dart format lib/ test/`

**Step 2: Chạy static analysis**
Run: `flutter analyze`
Expected: `No issues found!`

**Step 3: Chạy toàn bộ test suite**
Run: `flutter test`
Expected: 100% tests PASS (54/54+ tests).

**Step 4: Cập nhật task tracking và commit**
```bash
git add docs/plans/task.md
git commit -m "chore: complete transaction display refinement and quick add cleanup"
```
