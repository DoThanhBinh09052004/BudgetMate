# BudgetMate - Quản Lý Thu Chi Tự Động & Bảo Mật 📱💰

<p align="center">
  <img src="assets/images/logo.png" alt="BudgetMate Logo" width="100" style="border-radius: 20px;" />
</p>

<p align="center">
  Ứng dụng theo dõi thu chi cá nhân tự động trên điện thoại, hoạt động <b>100% Offline (Local-First)</b>, không dùng server ngoài và đặt <b>quyền riêng tư dữ liệu tài chính</b> lên hàng đầu.
</p>

---

## 🎯 Chức Năng Chính

### 1. Tự động ghi nhận giao dịch từ ngân hàng & ví điện tử
* **Đọc thông báo tự động:** Nhận diện biến động số dư tức thời từ ứng dụng ngân hàng và tin nhắn SMS ngân hàng (Vietcombank, Techcombank, MB Bank, Sacombank, MoMo, ZaloPay...).
* **Bóc tách dữ liệu thông minh:** Tự động tách số tiền, loại giao dịch (thu / chi), số tài khoản và nội dung chuyển khoản bằng bộ quy tắc linh hoạt (`bank_rules.json`).
* **Tự động đồng bộ:** Dữ liệu mới được cập nhật ngay khi bạn mở lại ứng dụng hoặc vuốt màn hình xuống (Pull-to-refresh).

### 2. Lọc thông minh & chống trùng lặp dữ liệu
* **Chống trùng thông báo:** Tự động bỏ qua các thông báo bị đẩy lại nhiều lần từ hệ thống Android.
* **Nhận diện chuyển khoản nội bộ:** Tự động phát hiện khi bạn chuyển tiền qua lại giữa các tài khoản/ví của chính mình (trong khoảng thời gian gần nhau) để không tính nhầm thành chi tiêu thực tế.

### 3. Quản lý ngân sách & Khoản chi định kỳ
* **Kế hoạch ngân sách:** Đặt hạn mức chi tiêu theo tháng hoặc theo kỳ nhận lương thực tế.
* **Chi phí cố định:** Quản lý các khoản tiền định kỳ (tiền nhà, điện, nước, internet...) để dự toán số tiền còn lại có thể chi tiêu trong tháng mà không bị tính trùng lặp.

### 4. Nhập tay nhanh khi dùng tiền mặt (Quick Add)
* **Bàn phím nhập liệu chuyên dụng:** Hỗ trợ tính toán nhanh và phím tắt các mệnh giá tiền mặt phổ biến (50k, 100k, 200k, 500k) giúp ghi chép tiền mặt chỉ trong vài giây.

---

## 🔒 Bảo Mật & Quyền Riêng Tư

Dữ liệu tài chính là thông tin cực kỳ nhạy cảm. BudgetMate được thiết kế với triết lý bảo vệ người dùng:

* **100% Cục bộ (Local-First):** Toàn bộ giao dịch, tài khoản và lịch sử chi tiêu được lưu trữ trực tiếp trong cơ sở dữ liệu SQLite nằm trong bộ nhớ riêng (sandboxed) của thiết bị. Ứng dụng **không có server đám mây, không có hệ thống theo dõi (tracking/analytics)** và **không bao giờ gửi dữ liệu tài chính ra Internet**.
* **Không yêu cầu quyền đọc toàn bộ SMS (`READ_SMS`):** Thay vì yêu cầu quyền truy cập toàn bộ hộp thư tin nhắn riêng tư, ứng dụng chỉ sử dụng dịch vụ lắng nghe thông báo của hệ điều hành (`NotificationListenerService`).
* **Bộ lọc ứng dụng nghiêm ngặt (Package Whitelist):** Ứng dụng chỉ xử lý thông báo từ danh sách các ngân hàng, ví điện tử và tin nhắn ngân hàng được cấu hình. Mọi thông báo từ mạng xã hội, tin nhắn riêng tư hay các ứng dụng khác đều bị bỏ qua ngay tại tầng Native của hệ thống.
* **Mã nguồn minh bạch:** Toàn bộ mã nguồn mở hoàn toàn, cho phép bạn tự kiểm tra toàn bộ quy trình đọc, xử lý và lưu trữ dữ liệu.

---

## 🏦 Danh Sách Ngân Hàng & Ví Đã Hỗ Trợ

Hệ thống bóc tách giao dịch qua file cấu hình `assets/rules/bank_rules.json`, hiện đã hỗ trợ sẵn:
* **Ngân hàng:** Vietcombank, Techcombank, MB Bank, Sacombank (App & SMS)...
* **Ví điện tử:** MoMo, ZaloPay...

*(Bạn có thể dễ dàng bổ sung ngân hàng mới bằng cách thêm quy tắc regex vào file `bank_rules.json` mà không cần sửa mã nguồn ứng dụng).*

---

## 🚀 Hướng Dẫn Cài Đặt & Chạy Ứng Dụng

### Yêu cầu môi trường
* **Flutter SDK:** >= 3.19.0
* **Dart SDK:** >= 3.3.0
* **Thiết bị:** Điện thoại Android (Android 8.0 trở lên) hoặc máy ảo Android.

### Các bước chạy dự án

1. **Clone mã nguồn:**
   ```bash
   git clone https://github.com/DoThanhBinh09052004/BudgetMate.git
   cd BudgetMate
   ```

2. **Cài đặt thư viện:**
   ```bash
   flutter pub get
   ```

3. **Chạy thử ứng dụng trên điện thoại:**
   * Kết nối điện thoại qua cáp USB và bật **Gỡ lỗi qua USB (USB Debugging)**.
   * Chạy lệnh:
     ```bash
     flutter run
     ```

### Thiết lập quyền trên điện thoại (Quan trọng)
* Sau khi mở ứng dụng lần đầu, cấp quyền **Truy cập thông báo (Notification Access)** cho BudgetMate trong cài đặt của máy.
* **Lưu ý riêng cho máy Xiaomi / Redmi (MIUI & HyperOS):**
  * Vào *Cài đặt* -> *Ứng dụng* -> *Quản lý ứng dụng* -> *BudgetMate*: Bật **Tự khởi chạy (Autostart)** và đặt Tiết kiệm pin thành **Không hạn chế**.
  * Trong ứng dụng có sẵn màn hình **"Tối ưu MIUI / Xiaomi"** (nút khiên ở góc trên bên phải) để hỗ trợ bạn kiểm tra và kết nối lại dịch vụ nền khi cần.
