import 'package:flutter/services.dart';
import 'package:bugdetmate/core/constants/app_constants.dart';

/// Bridge Flutter ↔ Java Native qua MethodChannel.
class NotificationBridge {
  static const _channel = MethodChannel(AppConstants.notificationChannelName);

  /// Kiểm tra quyền Notification Listener đã được cấp chưa.
  static Future<bool> checkPermission() async {
    final result = await _channel.invokeMethod<bool>(
      'checkNotificationPermission',
    );
    return result ?? false;
  }

  /// Mở màn hình cài đặt để user cấp quyền Notification Listener.
  static Future<void> requestPermission() async {
    await _channel.invokeMethod('requestNotificationPermission');
  }

  /// Rebind service sau khi MIUI silent-kill.
  static Future<void> rebindService() async {
    await _channel.invokeMethod('rebindService');
  }

  /// Cập nhật whitelist packageName cho Java service.
  /// Gọi sau khi load bank_rules.json.
  static Future<void> updateWhitelist(List<String> packageNames) async {
    await _channel.invokeMethod('updateWhitelist', {'packages': packageNames});
  }
}
