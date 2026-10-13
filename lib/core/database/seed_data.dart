/// Dữ liệu mặc định seed vào database khi tạo mới.
/// Tập trung tại đây để dễ bảo trì, không rải rác trong DatabaseHelper.
class SeedData {
  SeedData._();

  static const List<Map<String, Object?>> defaultWallets = [
    {
      'name': 'Tiền mặt',
      'type': 'cash',
      'balance': 0.0,
      'account_number_suffix': null,
      'icon': 'cash',
      'color': '#10B981',
    },
    {
      'name': 'Tài khoản ngân hàng',
      'type': 'bank',
      'balance': 0.0,
      'account_number_suffix': null,
      'icon': 'account_balance',
      'color': '#1E40AF',
    },
  ];

  static const List<Map<String, String>> defaultExpenseCategories = [
    {'name': 'Ăn uống', 'icon': 'restaurant', 'color': '#EF4444'},
    {'name': 'Di chuyển', 'icon': 'directions_car', 'color': '#F59E0B'},
    {'name': 'Mua sắm', 'icon': 'shopping_bag', 'color': '#EC4899'},
    {'name': 'Hóa đơn & Dịch vụ', 'icon': 'receipt_long', 'color': '#3B82F6'},
    {'name': 'Nhà cửa', 'icon': 'home', 'color': '#8B5CF6'},
    {'name': 'Chuyển tiền nội bộ', 'icon': 'swap_horiz', 'color': '#64748B'},
  ];

  static const List<Map<String, String>> defaultIncomeCategories = [
    {'name': 'Lương', 'icon': 'payments', 'color': '#059669'},
    {'name': 'Thưởng', 'icon': 'card_giftcard', 'color': '#10B981'},
    {'name': 'Thu nhập khác', 'icon': 'add_circle', 'color': '#06B6D4'},
  ];
}
