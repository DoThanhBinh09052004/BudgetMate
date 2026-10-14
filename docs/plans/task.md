# Transaction Display & QuickAdd Cleanup Execution Tracker

| Task | Detail | Status | Evidence |
| :---: | :--- | :---: | :--- |
| **1** | Làm gọn số tiền lớn & bỏ dấu '+' ở chip phím tắt (`QuickAddSheet`) | Pending | Đổi `+50k` -> `50k`, bỏ prefix `+/-` ở display amount, TDD test |
| **2** | Chuẩn hóa hiển thị tên danh mục rõ ràng trên `RecentTransactionsSection` | Pending | Ưu tiên `Cha › Con` > `Tên danh mục` > `Ghi chú`, chặn tiêu đề rỗng |
| **3** | Nâng cao bóc tách ghi chú & ánh xạ danh mục trong `RawSyncService` | Pending | Lưu sạch note và gán danh mục phù hợp cho thông báo tự động |
| **4** | Kiểm thử toàn diện, Static Analysis & Format codebase | Pending | 54/54+ tests passed, `flutter analyze` 0 warnings, `dart format` |
