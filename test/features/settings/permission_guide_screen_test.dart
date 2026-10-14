import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:bugdetmate/features/settings/screens/permission_guide_screen.dart';
import 'package:bugdetmate/core/theme/app_theme.dart';

void main() {
  testWidgets(
    'PermissionGuideScreen displays universal Android guide without device-specific labels',
    (tester) async {
      // Set realistic phone screen size
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.darkTheme,
          home: const PermissionGuideScreen(),
        ),
      );

      await tester.pumpAndSettle();

      // Verify Title
      expect(find.text('Cài đặt Quyền & Hoạt động nền'), findsOneWidget);

      // Verify universal Android guide steps
      expect(find.textContaining('Quyền Đọc Thông Báo'), findsWidgets);
      expect(find.textContaining('Tắt Tối Ưu Hóa Pin'), findsOneWidget);
      expect(find.textContaining('Cho Phép Chạy Nền'), findsOneWidget);
      expect(
        find.textContaining('Khóa Ứng Dụng Trong Đa Nhiệm'),
        findsOneWidget,
      );

      // Verify NO device-specific hardcoded strings
      expect(find.textContaining('MIUI'), findsNothing);
      expect(find.textContaining('Xiaomi'), findsNothing);
      expect(find.textContaining('Redmi Note 11'), findsNothing);
    },
  );
}
