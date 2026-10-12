# Tài Liệu Thiết Kế Kỹ Thuật: bugdetmate - Sổ Thu Chi Thông Minh (Hardened Edition)
**Ngày cập nhật:** 12-10-2026  
**Trạng thái:** Bản thiết kế đã phản biện & phê duyệt (Approved Design)  
**Phạm vi:** Ứng dụng di động quản lý chi tiêu cá nhân độc lập (Local-First Mobile App)  
**Tên dự án & Package:** `bugdetmate` (Android org: `com.budgetmate`)

---

## 1. Tổng Quan Dự Án & Định Hướng Sản Phẩm

### 1.1. Mục Tiêu Cốt Lõi
`bugdetmate` giải quyết triệt để rào cản lớn nhất của quản lý tài chính cá nhân: **"Người dùng lười ghi chép chi tiêu thủ công"**. Ứng dụng vận hành theo triết lý:
1. **Tự động bắt biến động số dư 100% trên thiết bị (Raw Buffer Pattern):** Lắng nghe notification từ ngân hàng/ví điện tử bằng Java Native, đệm an toàn vào SQLite đệm, bóc tách và phân loại tự động khi mở app mà không lo tốn pin hay bị hệ thống tắt ngầm.
2. **Nhập thủ công siêu tốc (Quick Add 3 chạm):** Tối ưu cho các khoản chi tiêu tiền mặt hàng ngày với bàn phím số thông minh.
3. **Phát hiện chuyển tiền nội bộ an toàn (Safe Internal Transfer Matcher):** Ngăn chặn việc tính trùng thu chi khi chuyển tiền giữa các tài khoản của chính mình, có kiểm tra từ khóa và quyền sở hữu ví để loại trừ các trường hợp nhận/chi ngẫu nhiên.
4. **Dự báo dòng tiền & chi phí cố định (Anti-Double-Counting):** Quản lý chu kỳ ngân sách theo ngày nhận lương linh hoạt, có máy trạng thái (State Machine) quản lý chi phí cố định định kỳ để triệt tiêu hoàn toàn lỗi trừ kép ngân sách.
5. **Chống trùng lặp 2 lớp (Two-Tier Deduplication):** Lớp 1 chặn bằng `sbn.getKey()` tại tầng Native; Lớp 2 chặn bằng truy vấn thời gian thực trong SQLite trong cửa sổ $\pm 60$ giây. Triệt tiêu hoàn toàn lỗi Boundary Effect.
6. **Bảo mật tuyệt đối (100% Local-First / Zero-Knowledge):** Không gửi dữ liệu tài chính của người dùng lên bất kỳ server đám mây nào.

---

## 2. Ngăn Xếp Công Nghệ (Technology Stack)

* **UI Framework:** Flutter 3.47.7 (Dart 3.13.5).
* **Android Native Layer:** **100% Pure Java** (hoàn toàn không dùng Kotlin, tận dụng Microsoft OpenJDK 17 LTS sẵn có).
* **Cơ sở dữ liệu:** SQLite cục bộ thông qua `sqflite`.
* **State Management:** Clean Architecture với Service & Repository pattern.
* **Quy chuẩn UI/UX:** Tích hợp bộ tiêu chuẩn **UI/UX Pro Max** dành cho ứng dụng Fintech:
  * **Phong cách:** Glassmorphism hiện đại, hỗ trợ Dark Mode & Light Mode mượt mà.
  * **Bảng màu:** Trust Blue (`#1E40AF`), Profit Green (`#059669`), Cảnh báo (`#F59E0B`), Vượt ngưỡng/Chi tiêu (`#DC2626`), Nền tối (`#0F172A`), Thẻ (`#192134`).
  * **Tối ưu hiệu năng 60fps:** Tận dụng `const widgets` và `RepaintBoundary` cho các hiệu ứng biểu đồ/hoạt ảnh.
* **Môi trường & Thiết bị:** Android API 36, tối ưu hóa cho Xiaomi/MIUI (Redmi Note 11).

---

## 3. Kiến Trúc Hệ Thống (System Architecture)

```
┌────────────────────────────────────────────────────────────────────────┐
│                        Thiết bị di động Android                        │
│                                                                        │
│  ┌─────────────────────────┐           ┌────────────────────────────┐  │
│  │   App Ngân hàng/Ví      │           │    Giao diện người dùng    │  │
│  │  (VCB, TCB, MB, MoMo...)│           │  (Quick Add / Ngân sách)   │  │
│  └────────────┬────────────┘           └─────────────┬──────────────┘  │
│               │ (Push Notification)                  │                 │
│               ▼                                      ▼                 │
│  ┌─────────────────────────┐           ┌────────────────────────────┐  │
│  │ Notification Listener   │           │   Giao dịch thủ công       │  │
│  │ Service (Pure Java)     │           │   (Bàn phím Quick Add)     │  │
│  │ - Deduplication L1      │           └─────────────┬──────────────┘  │
│  │   (sbn.getKey())        │                         │                 │
│  └────────────┬────────────┘                         │                 │
│               │ (Ghi thô trực tiếp)                  │                 │
│               ▼                                      │                 │
│  ┌─────────────────────────┐                         │                 │
│  │ raw_notifications (Đệm) │                         │                 │
│  └────────────┬────────────┘                         │                 │
│               │ (App mở / Sync)                      │                 │
│               ▼                                      ▼                 │
│  ┌──────────────────────────────────────────────────────────────────┐  │
│  │                Tầng Nghiệp Vụ Xử Lý Dữ Liệu (Dart)               │  │
│  │  - JSON Regex Engine: Đọc cấu hình bank_rules.json động          │  │
│  │  - Deduplication L2: Query SQLite cửa sổ +- 60 giây              │  │
│  │  - Safe Transfer Matcher: Cửa sổ 120s + Wallet Check + Keywords  │  │
│  │  - Smart Categorizer: Nhận diện từ khóa & học từ lịch sử         │  │
│  └──────────────────────────────────┬───────────────────────────────┘  │
│                                     │                                  │
│                                     ▼                                  │
│  ┌──────────────────────────────────────────────────────────────────┐  │
│  │        Budget & Recurring Engine (Anti Double-Counting)          │  │
│  │  - Chu kỳ linh hoạt theo ngày nhận lương (VD: ngày 5, 10, 15)    │  │
│  │  - recurring_payments: Đánh dấu is_paid khi có giao dịch thật    │  │
│  │  - Dự báo tốc độ tiêu dùng (Burn-Rate Forecast)                  │  │
│  └──────────────────────────────────┬───────────────────────────────┘  │
│                                     │                                  │
│                                     ▼                                  │
│  ┌──────────────────────────────────────────────────────────────────┐  │
│  │                  Cơ Sở Dữ Liệu Cục Bộ (SQLite)                   │  │
│  │  wallets, categories, transactions, budgets, recurring_rules,    │  │
│  │  recurring_payments, raw_notifications, user_category_rules      │  │
│  └──────────────────────────────────────────────────────────────────┘  │
└────────────────────────────────────────────────────────────────────────┘
```

---

## 4. Chi Tiết Các Phân Hệ Cốt Lõi

### 4.1. Tầng Native Android (Pure Java) & Raw Buffer Pattern
* **Lớp Java:** `BudgetMateNotificationService.java` kế thừa `NotificationListenerService`:
  * Lọc thông báo dựa trên Whitelist các `packageName` ngân hàng/ví điện tử đã định cấu hình.
  * **Lớp chống trùng 1:** Kiểm tra `sbn.getKey()` để ngăn chặn việc ghi trùng nếu Android gửi lại cùng thông báo.
  * Ghi trực tiếp payload thô vào bảng `raw_notifications` trong SQLite cục bộ (hoặc truyền qua `EventChannel` nếu app đang mở).
* **Tối ưu hóa chạy nền cho MIUI/Xiaomi (Redmi Note 11):**
  * Tùy chọn Foreground Service với notification nhẹ nhàng hiển thị trạng thái *"BudgetMate đang hoạt động"*.
  * Cơ chế Java tự động kiểm tra và rebind service (`setComponentEnabledSetting`) mỗi khi người dùng mở lại app nếu MIUI âm thầm unbind service.

### 4.2. Bộ Bóc Tách Regex Động & Xử Lý Hàng Loạt (Batch Parser Engine)
* Đọc tập luật từ `assets/rules/bank_rules.json`.
* Khi mở app hoặc có thông báo mới: Lấy các bản ghi `is_processed = 0` từ `raw_notifications`, áp dụng Regex để bóc tách:
  * Số tiền (chuẩn hóa `50.000` -> `50000.0`).
  * Loại thu chi: `expense` hoặc `income`.
  * Nội dung thanh toán / người nhận.
  * Số tài khoản / 4 số cuối thẻ để tự động map vào `wallet_id`.
* Tính toán điểm tin cậy `confidenceScore`: Nếu $< 0.8$, tự động gán cờ `needs_review = 1`.

### 4.3. Bộ Chống Trùng Lặp 2 Lớp (Two-Tier Deduplication)
* **Lớp 1 (Native Java):** So khớp `sbn.getKey()`.
* **Lớp 2 (SQLite Dart):** Kiểm tra trong bảng `transactions`:
  ```sql
  SELECT id FROM transactions 
  WHERE wallet_id = ? AND amount = ? AND note = ? 
    AND ABS(transaction_date - ?) <= 60;
  ```
  Loại bỏ hoàn toàn rủi ro Boundary Effect của phương pháp băm `timestamp / 120`.

### 4.4. Bộ Ghép Cặp Chuyển Tiền Nội Bộ An Toàn (Safe Transfer Matcher)
* **Quy tắc an toàn:**
  1. Khoảng cách thời gian giữa 2 giao dịch: $\le 120$ giây.
  2. Số tiền tuyệt đối trùng khớp.
  3. **Bắt buộc cả 2 ví** (nguồn và đích) đều thuộc danh sách ví người dùng quản lý trong app.
  4. Nội dung giao dịch chứa từ khóa chuyển khoản (`CK`, `Chuyen tien`, `Nap tien`, `Transfer`, `MBVCB`, `IBFT`...).
  5. Nếu thỏa mãn cả 4 điều kiện: Tự động ghép cặp, gán `type = 'transfer'`, cập nhật `transfer_pair_id`.
  6. Nếu trùng tiền trong 120s nhưng không có từ khóa: Gắn cờ `needs_review = 1`, hiển thị thẻ gợi ý xác nhận 1 chạm trên màn hình Home.

### 4.5. Quản Lý Ngân Sách Định Kỳ Chống Trừ Kép (Anti Double-Counting)
* **Chu kỳ tháng linh hoạt:** Cho phép người dùng chọn ngày bắt đầu chu kỳ theo ngày nhận lương (ngày 1, 5, 10, 15...).
* **Bảng theo dõi `recurring_payments`:**
  * Mỗi chu kỳ tháng, các quy tắc trong `recurring_rules` ở trạng thái chờ (`is_paid = 0`).
  * Khi có giao dịch thực tế chi trả khớp hoặc người dùng xác nhận: Đánh dấu `is_paid = 1` và lưu `transaction_id`.
  * **Công thức số dư khả dụng thực tế:**
    $$\text{Khả dụng} = \text{Thu nhập dự kiến} - \sum \text{Chi phí cố định (CHƯA thanh toán)} - \sum \text{Chi tiêu thực tế (ĐÃ phát sinh)}$$
  * Ngăn ngừa hoàn toàn hiện tượng trừ kép (double-counting).

### 4.6. Nhập Thủ Công Nhanh (Quick Add 3 Chạm)
* Bottom Sheet mở tức thì từ nút FAB.
* Bàn phím số lớn có phím tắt giá trị tiền mặt phổ biến ở VN (`50k`, `100k`, `200k`, `500k`) và hỗ trợ tính toán cộng trừ cơ bản.
* Grid danh mục trực quan, ghi nhớ ví và danh mục gần nhất.

---

## 5. Cấu Trúc Cơ Sở Dữ Liệu (SQLite Schema)

```sql
-- 1. Bảng ví / tài khoản
CREATE TABLE wallets (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    name TEXT NOT NULL,
    type TEXT NOT NULL, -- 'bank', 'e_wallet', 'cash'
    balance REAL DEFAULT 0,
    account_number_suffix TEXT, -- 4 số cuối TK để tự động map thông báo
    icon TEXT,
    color TEXT
);

-- 2. Bảng danh mục
CREATE TABLE categories (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    name TEXT NOT NULL,
    type TEXT NOT NULL, -- 'expense', 'income'
    icon TEXT,
    color TEXT,
    is_default INTEGER DEFAULT 0
);

-- 3. Bảng đệm thông báo thô từ Native Java
CREATE TABLE raw_notifications (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    package_name TEXT NOT NULL,
    sbn_key TEXT UNIQUE NOT NULL,
    post_time INTEGER NOT NULL,
    title TEXT,
    text TEXT,
    is_processed INTEGER DEFAULT 0
);

-- 4. Bảng sổ giao dịch chính
CREATE TABLE transactions (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    wallet_id INTEGER NOT NULL,
    category_id INTEGER,
    amount REAL NOT NULL,
    type TEXT NOT NULL, -- 'expense', 'income', 'transfer'
    transaction_date INTEGER NOT NULL, -- Unix timestamp (giây)
    note TEXT,
    source TEXT NOT NULL, -- 'auto_notification', 'manual'
    raw_notification_id INTEGER,
    needs_review INTEGER DEFAULT 0,
    transfer_pair_id INTEGER,
    FOREIGN KEY (wallet_id) REFERENCES wallets (id),
    FOREIGN KEY (category_id) REFERENCES categories (id),
    FOREIGN KEY (transfer_pair_id) REFERENCES transactions (id),
    FOREIGN KEY (raw_notification_id) REFERENCES raw_notifications (id)
);

-- 5. Bảng học quy tắc phân loại cá nhân
CREATE TABLE user_category_rules (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    keyword TEXT NOT NULL UNIQUE,
    category_id INTEGER NOT NULL,
    FOREIGN KEY (category_id) REFERENCES categories (id)
);

-- 6. Bảng ngân sách
CREATE TABLE budgets (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    category_id INTEGER, -- NULL nếu là ngân sách tổng
    amount REAL NOT NULL,
    start_day INTEGER DEFAULT 1,
    FOREIGN KEY (category_id) REFERENCES categories (id)
);

-- 7. Bảng quy tắc chi phí định kỳ cố định
CREATE TABLE recurring_rules (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    title TEXT NOT NULL,
    amount REAL NOT NULL,
    category_id INTEGER NOT NULL,
    wallet_id INTEGER NOT NULL,
    due_day INTEGER NOT NULL, -- Ngày đến hạn trong tháng
    is_active INTEGER DEFAULT 1,
    FOREIGN KEY (category_id) REFERENCES categories (id),
    FOREIGN KEY (wallet_id) REFERENCES wallets (id)
);

-- 8. Bảng theo dõi trạng thái thanh toán chi phí định kỳ theo chu kỳ (Anti Double-Counting)
CREATE TABLE recurring_payments (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    rule_id INTEGER NOT NULL,
    cycle_month TEXT NOT NULL, -- Định dạng: YYYY-MM
    transaction_id INTEGER,
    is_paid INTEGER DEFAULT 0,
    paid_date INTEGER,
    FOREIGN KEY (rule_id) REFERENCES recurring_rules (id),
    FOREIGN KEY (transaction_id) REFERENCES transactions (id)
);
```

---

## 6. Lộ Trình Triển Khai Kỹ Thuật (7 Tasks)

1. **Task 1: Cấu hình Khởi tạo Dự án & Khai báo Dependencies**
2. **Task 2: Core Database Helper, Schema Migrations & Raw Notifications Buffer**
3. **Task 3: JSON-Driven Regex Parser Engine & Batch Sync Service**
4. **Task 4: Two-Tier Deduplication & Safe Internal Transfer Matcher Engine**
5. **Task 5: Android Native Java Notification Listener Service & MIUI Rebind Bridge**
6. **Task 6: Budgeting, Anti-Double-Counting Recurring Engine & Burn-rate Forecast**
7. **Task 7: Presentation Layer (UI/UX Pro Max Fintech Dark/Light Interface & Quick Add Sheet)**
