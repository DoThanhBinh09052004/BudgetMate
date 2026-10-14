import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// Bộ chuyển đổi mã biểu tượng (icon string) sang IconData.
/// Ưu tiên các biểu tượng hiện đại từ LucideIcons, tự động fallback sang Material Icons khi cần.
class IconResolver {
  IconResolver._();

  static IconData resolve(
    String? iconName, {
    IconData fallback = Icons.category_rounded,
  }) {
    if (iconName == null || iconName.isEmpty) return fallback;

    switch (iconName.toLowerCase().trim()) {
      // Ẩm thực & Đồ uống
      case 'utensils':
      case 'restaurant':
        return LucideIcons.utensils;
      case 'coffee':
      case 'local_cafe':
        return LucideIcons.coffee;

      // Di chuyển & Phương tiện
      case 'car':
      case 'directions_car':
        return LucideIcons.car;
      case 'fuel':
      case 'local_gas_station':
        return LucideIcons.fuel;
      case 'wrench':
      case 'build':
        return LucideIcons.wrench;

      // Mua sắm
      case 'shopping_bag':
      case 'shopping_cart':
        return LucideIcons.shoppingBag;
      case 'shirt':
        return LucideIcons.shirt;
      case 'laptop':
        return LucideIcons.laptop;
      case 'sparkles':
        return LucideIcons.sparkles;

      // Hóa đơn & Tiện ích
      case 'receipt':
      case 'receipt_long':
        return LucideIcons.receipt;
      case 'zap':
      case 'bolt':
        return LucideIcons.zap;
      case 'droplets':
      case 'water_drop':
        return LucideIcons.droplets;
      case 'wifi':
        return LucideIcons.wifi;
      case 'film':
        return LucideIcons.film;

      // Nhà cửa
      case 'home':
        return LucideIcons.home;
      case 'hammer':
        return LucideIcons.hammer;

      // Tài chính & Thu nhập
      case 'wallet':
      case 'payments':
      case 'cash':
      case 'account_balance_wallet':
        return LucideIcons.wallet;
      case 'gift':
      case 'card_giftcard':
        return LucideIcons.gift;
      case 'circle_plus':
      case 'add_circle':
        return LucideIcons.circlePlus;
      case 'clock':
        return LucideIcons.clock;
      case 'tag':
        return LucideIcons.tag;
      case 'percent':
        return LucideIcons.percent;
      case 'arrow_left_right':
      case 'swap_horiz':
        return LucideIcons.arrowLeftRight;

      default:
        return fallback;
    }
  }

  /// Chuyển đổi mã màu hex (#RRGGBB) sang Color với fallback an toàn.
  static Color resolveColor(
    String? hexString, {
    Color fallback = const Color(0xFF10B981),
  }) {
    if (hexString == null || hexString.isEmpty) return fallback;
    try {
      final clean = hexString.replaceAll('#', '').trim();
      if (clean.length == 6) {
        return Color(int.parse('FF$clean', radix: 16));
      } else if (clean.length == 8) {
        return Color(int.parse(clean, radix: 16));
      }
    } catch (_) {}
    return fallback;
  }
}
