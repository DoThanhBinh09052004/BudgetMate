# BudgetMate

BudgetMate là ứng dụng quản lý chi tiêu cá nhân trên Android hoạt động theo mô hình **Local-First (hoàn toàn offline)**. Ứng dụng tự động ghi nhận thu chi bằng cách lắng nghe thông báo biến động số dư từ app ngân hàng và tin nhắn SMS, bóc tách dữ liệu theo quy tắc regex định sẵn và lưu trực tiếp vào cơ sở dữ liệu SQLite nội bộ trên máy.

Dự án được xây dựng với mục tiêu: **tiện lợi trong việc ghi chép nhưng không đánh đổi quyền riêng tư dữ liệu tài chính.**

---

## Luồng hoạt động (Architecture)

```
[Thông báo App Ngân hàng / SMS]
              │
              ▼
[Android NotificationListenerService] (Pure Java)
              │
              ├─ Lọc theo Package Whitelist (chỉ nhận app ngân hàng / SMS)
              ├─ Chống trùng lặp cấp Native (dựa trên sbn.getKey())
              ▼
[Bảng raw_notifications] (SQLite cục bộ)
              │
              ▼
[RegexParserService] (Engine bóc tách Dart + bank_rules.json)
              │
              ├─ Nhận diện số tiền, loại thu/chi, số tài khoản, nội dung
              ├─ Phát hiện chuyển tiền nội bộ giữa các ví (tránh tính trùng)
              ▼
[Bảng transactions] ──► [Giao diện Flutter]
```

---

## Tính năng

### 1. Tự động nhận diện biến động số dư
- Bắt thông báo trực tiếp từ ứng dụng ngân hàng và tin nhắn SMS từ tổng đài ngân hàng.
- Bóc tách tự động: số tiền giao dịch, loại giao dịch (tiền vào / tiền ra), số tài khoản nguồn và nội dung chuyển khoản.
- Tự động đồng bộ và hiển thị ngay khi người dùng quay lại ứng dụng hoặc vuốt màn hình (Pull-to-refresh).

### 2. Xử lý trùng lặp & Chuyển tiền nội bộ
- **Chống trùng lặp 2 lớp:**
  - Lớp 1 (Native Java): Khóa theo `sbnKey` để bỏ qua các thông báo bị hệ điều hành phát lại.
  - Lớp 2 (Database): Đối soát trong khung thời gian ngắn để tránh ghi nhận 2 lần khi cả app ngân hàng và SMS cùng báo một giao dịch.
- **Ghép cặp chuyển tiền nội bộ:** Khi bạn chuyển tiền giữa 2 tài khoản của chính mình (ví dụ từ Techcombank sang Sacombank), hệ thống tự nhận diện cặp giao dịch đối ứng (1 chi + 1 thu cùng số tiền trong khoảng thời gian ngắn) và ghi nhận là chuyển khoản nội bộ, không tính vào tổng chi tiêu.

### 3. Quản lý ngân sách & Khoản chi định kỳ
- Thiết lập ngân sách chi tiêu linh hoạt theo tháng hoặc theo kỳ nhận lương.
- Theo dõi các khoản chi cố định hàng tháng (tiền thuê nhà, internet, phí định kỳ) để tính toán chính xác số tiền khả dụng còn lại.

### 4. Nhập tay nhanh (Quick Add)
- Dành cho các giao dịch tiền mặt.
- Bàn phím số tích hợp sẵn các phím tắt mệnh giá tiền Việt (50k, 100k, 200k, 500k) và phép tính đơn giản, giúp nhập giao dịch chỉ với vài thao tác.

---

## Bảo mật & Quyền riêng tư

Dữ liệu tài chính là thông tin cá nhân quan trọng nhất trên điện thoại. BudgetMate áp dụng các nguyên tắc kỹ thuật sau:

- **Hoàn toàn Offline (Zero Network Transmission):** Ứng dụng không có server backend, không có hệ thống theo dõi (tracking/analytics), không tích hợp SDK quảng cáo. Cơ sở dữ liệu SQLite nằm hoàn toàn trong sandbox riêng của ứng dụng trên thiết bị (`/data/data/com.budgetmate.bugdetmate/databases/`).
- **Không yêu cầu quyền `READ_SMS`:** Ứng dụng không xin quyền đọc toàn bộ hộp thư SMS riêng tư của bạn. Việc đọc tin nhắn biến động số dư chỉ diễn ra khi ứng dụng tin nhắn đẩy thông báo lên thanh trạng thái (thông qua quyền `BIND_NOTIFICATION_LISTENER_SERVICE`).
- **Lọc gói tin nghiêm ngặt (Whitelist):** Dịch vụ nền kiểm tra package name trước khi đọc nội dung. Mọi thông báo từ mạng xã hội, tin nhắn cá nhân, ứng dụng OTT... bị hủy ngay từ tầng native và không bao giờ được ghi vào bộ nhớ hay database.
- **Mã nguồn mở:** Toàn bộ mã nguồn hiển thị minh bạch, bạn có thể tự build và kiểm tra trước khi cài đặt lên thiết bị cá nhân.

---

## Danh sách ngân hàng & ví hỗ trợ

Quy tắc bóc tách được quản lý qua file [assets/rules/bank_rules.json](assets/rules/bank_rules.json). Hiện tại đã cấu hình sẵn:

| Đơn vị | Loại | Định danh (Package / Brandname) |
|---|---|---|
| **Vietcombank** | App | `com.VCB` |
| **Techcombank** | App | `com.techcombank.mobile` |
| **MB Bank** | App | `com.mbmobile` |
| **Sacombank** | App & SMS | `com.sacombank.ewallet`, Brandname `SACOMBANK` |
| **MoMo** | Ví điện tử | `com.mservice.momotransfer` |
| **ZaloPay** | Ví điện tử | `vn.com.vng.zalopay` |
| **SMS Ngân hàng** | Tin nhắn | Hỗ trợ Google Messages (`com.google.android.apps.messaging`), MIUI SMS (`com.android.mms`), Samsung Messages |

### Thêm ngân hàng mới
Bạn có thể tự thêm ngân hàng vào `assets/rules/bank_rules.json` mà không cần viết lại logic:

```json
{
  "bankId": "sacombank",
  "packageName": "com.sacombank.ewallet",
  "displayName": "Sacombank",
  "amountPatterns": [
    "PS:\\s*[+-]?([\\d.,]+)\\s*(?:VND|đ|d)"
  ],
  "typeIndicators": {
    "expense": ["-", "PS: -"],
    "income": ["+", "PS: +"]
  },
  "notePattern": "(?:Nội dung|Noi dung|ND):\\s*(.+?)$",
  "accountPattern": "TK:\\s*(\\d+)"
}
```

---

## Cài đặt & Chạy ứng dụng

### Yêu cầu
- Flutter SDK >= 3.19.0
- Thiết bị Android chạy Android 8.0 (API 26) trở lên

### Khởi chạy từ source code
```bash
git clone https://github.com/DoThanhBinh09052004/BudgetMate.git
cd BudgetMate
flutter pub get
flutter run
```

### Cấp quyền trên thiết bị
1. Sau khi cài đặt, vào **Cài đặt hệ thống** $\rightarrow$ **Quyền truy cập thông báo (Notification Access)** $\rightarrow$ Bật cho **BudgetMate**.
2. **Đối với thiết bị Xiaomi / Redmi (MIUI & HyperOS):**
   - Vào *Cài đặt* $\rightarrow$ *Ứng dụng* $\rightarrow$ *Quản lý ứng dụng* $\rightarrow$ *BudgetMate*.
   - Bật **Tự khởi chạy (Autostart)**.
   - Mục *Tiết kiệm pin (Battery saver)*: Chọn **Không hạn chế (No restrictions)** để tránh hệ thống tự tắt dịch vụ ngầm.
