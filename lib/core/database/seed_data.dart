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

  static const List<Map<String, dynamic>> defaultExpenseCategories = [
    {
      'name': 'Ăn uống',
      'icon': 'utensils',
      'color': '#F97316',
      'children': [
        {'name': 'Cơm trưa / tối', 'icon': 'utensils'},
        {'name': 'Trà sữa & Cà phê', 'icon': 'coffee'},
        {'name': 'Ăn vặt', 'icon': 'utensils'},
        {'name': 'Đi chợ & Siêu thị', 'icon': 'shopping_bag'},
      ],
    },
    {
      'name': 'Di chuyển',
      'icon': 'car',
      'color': '#0EA5E9',
      'children': [
        {'name': 'Xăng xe', 'icon': 'fuel'},
        {'name': 'Taxi / Grab', 'icon': 'car'},
        {'name': 'Gửi xe', 'icon': 'car'},
        {'name': 'Bảo dưỡng xe', 'icon': 'wrench'},
      ],
    },
    {
      'name': 'Mua sắm',
      'icon': 'shopping_bag',
      'color': '#EC4899',
      'children': [
        {'name': 'Quần áo', 'icon': 'shirt'},
        {'name': 'Đồ công nghệ', 'icon': 'laptop'},
        {'name': 'Gia dụng & Đời sống', 'icon': 'home'},
        {'name': 'Mỹ phẩm', 'icon': 'sparkles'},
      ],
    },
    {
      'name': 'Hóa đơn & Dịch vụ',
      'icon': 'receipt',
      'color': '#3B82F6',
      'children': [
        {'name': 'Tiền điện', 'icon': 'zap'},
        {'name': 'Tiền nước', 'icon': 'droplets'},
        {'name': 'Internet & 4G', 'icon': 'wifi'},
        {'name': 'Dịch vụ trực tuyến', 'icon': 'film'},
      ],
    },
    {
      'name': 'Nhà cửa',
      'icon': 'home',
      'color': '#8B5CF6',
      'children': [
        {'name': 'Tiền thuê nhà', 'icon': 'home'},
        {'name': 'Sửa chữa nhà', 'icon': 'hammer'},
      ],
    },
    {
      'name': 'Chuyển tiền nội bộ',
      'icon': 'arrow_left_right',
      'color': '#64748B',
      'children': <Map<String, String>>[],
    },
  ];

  static const List<Map<String, dynamic>> defaultIncomeCategories = [
    {
      'name': 'Lương',
      'icon': 'wallet',
      'color': '#059669',
      'children': [
        {'name': 'Lương chính', 'icon': 'wallet'},
        {'name': 'Lương thêm giờ', 'icon': 'clock'},
      ],
    },
    {
      'name': 'Thưởng',
      'icon': 'gift',
      'color': '#10B981',
      'children': <Map<String, String>>[],
    },
    {
      'name': 'Thu nhập khác',
      'icon': 'circle_plus',
      'color': '#06B6D4',
      'children': [
        {'name': 'Bán đồ cũ', 'icon': 'tag'},
        {'name': 'Lãi tiết kiệm', 'icon': 'percent'},
      ],
    },
  ];
}
