# BudgetMate - Sổ Thu Chi Thông Minh 📱💰

> Ứng dụng di động quản lý chi tiêu cá nhân 100% Local-First (Zero-Knowledge) trên nền tảng Flutter & Pure Java Android Native.

---

## ✨ Tính Năng Nổi Bật

1. **Tự động bắt biến động số dư ngân hàng:**
   * Sử dụng tầng Native Java `NotificationListenerService` đệm an toàn vào SQLite (`raw_notifications`).
   * Bóc tách Regex JSON động (`bank_rules.json`) hỗ trợ Techcombank, Vietcombank, MB Bank, MoMo, ZaloPay...
2. **Chống trùng lặp 2 lớp (Two-Tier Deduplication):**
   * Lớp 1 (Native Java): So khớp `sbn.getKey()` ngăn chặn trùng lặp ngay khi Android đẩy lại thông báo.
   * Lớp 2 (SQLite): Truy vấn cửa sổ thời gian $\pm 60$ giây, triệt tiêu hoàn toàn hiện tượng *Boundary Effect*.
3. **Ghép cặp Chuyển tiền nội bộ an toàn (Safe Transfer Matcher):**
   * Tự động phát hiện giao dịch chuyển tiền giữa các ví của chính mình trong $\pm 120$ giây để loại bỏ khỏi báo cáo thu chi, tránh tính trùng.
4. **Quản lý Ngân sách & Chi phí cố định (Anti Double-Counting):**
   * Chu kỳ ngân sách linh hoạt theo ngày nhận lương.
   * Quản lý trạng thái thanh toán chi phí định kỳ (`recurring_payments`) để không bị trừ 2 lần vào ngân sách khả dụng.
5. **Nhập thủ công siêu tốc (Quick Add 3 chạm):**
   * Bàn phím số lớn có phím tắt tiền mặt VN (`50k`, `100k`, `200k`, `500k`) và phép tính nhanh.
6. **Bảo mật tuyệt đối (100% Local-First):**
   * Toàn bộ dữ liệu tài chính lưu trên SQLite nội bộ thiết bị, không gửi dữ liệu lên bất kỳ máy chủ đám mây nào.

---

## 🛠️ Ngăn Xếp Công Nghệ (Tech Stack)

* **UI Framework:** Flutter 3.47.7 (Dart 3.13.5)
* **Android Native Layer:** 100% Pure Java (OpenJDK 17 LTS, Android API 36)
* **Cơ sở dữ liệu:** SQLite (`sqflite`)
* **Thiết kế:** UI/UX Pro Max Fintech Glassmorphism (Dark / Light mode)

---

## 📂 Cấu Trúc Dự Án

```
BudgetMate/
├── .agent/               # Workflows và Agent Skills
├── .agents/              # Agent customizations
├── bugdetmate/           # Mã nguồn ứng dụng Flutter
│   ├── android/          # Android Native (Pure Java Service)
│   ├── assets/           # Rules & static assets
│   ├── lib/              # Clean Architecture (Core & Features)
│   └── test/             # Unit tests & Widget tests
└── docs/plans/           # Tài liệu thiết kế kỹ thuật & Kế hoạch triển khai
```
