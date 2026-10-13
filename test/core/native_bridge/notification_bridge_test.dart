import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:bugdetmate/core/native_bridge/notification_bridge.dart';
import 'package:bugdetmate/core/constants/app_constants.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final List<MethodCall> log = <MethodCall>[];

  setUp(() {
    log.clear();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel(AppConstants.notificationChannelName),
      (MethodCall methodCall) async {
        log.add(methodCall);
        switch (methodCall.method) {
          case 'checkNotificationPermission':
            return true;
          case 'requestNotificationPermission':
          case 'rebindService':
          case 'updateWhitelist':
            return true;
          default:
            return null;
        }
      },
    );
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel(AppConstants.notificationChannelName),
      null,
    );
  });

  test('checkPermission invokes checkNotificationPermission method', () async {
    final result = await NotificationBridge.checkPermission();
    expect(result, true);
    expect(log.length, 1);
    expect(log.first.method, 'checkNotificationPermission');
  });

  test('requestPermission invokes requestNotificationPermission method', () async {
    await NotificationBridge.requestPermission();
    expect(log.length, 1);
    expect(log.first.method, 'requestNotificationPermission');
  });

  test('rebindService invokes rebindService method', () async {
    await NotificationBridge.rebindService();
    expect(log.length, 1);
    expect(log.first.method, 'rebindService');
  });

  test('updateWhitelist sends package names to native side', () async {
    final packages = ['com.techcombank.mobile', 'com.VCB'];
    await NotificationBridge.updateWhitelist(packages);
    expect(log.length, 1);
    expect(log.first.method, 'updateWhitelist');
    expect(log.first.arguments, {'packages': packages});
  });
}
