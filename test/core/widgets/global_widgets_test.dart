import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:bugdetmate/core/theme/app_theme.dart';
import 'package:bugdetmate/core/widgets/app_widgets.dart';

void main() {
  Widget buildTestableWidget(Widget child) {
    return MaterialApp(
      theme: AppTheme.darkTheme,
      home: Scaffold(body: Center(child: child)),
    );
  }

  group('Global Widgets Tests', () {
    testWidgets('AppPrimaryButton renders label, handles tap, and shows loading', (tester) async {
      bool tapped = false;

      await tester.pumpWidget(
        buildTestableWidget(
          AppPrimaryButton(
            label: 'Lưu giao dịch',
            icon: Icons.check,
            onPressed: () => tapped = true,
          ),
        ),
      );

      expect(find.text('Lưu giao dịch'), findsOneWidget);
      expect(find.byIcon(Icons.check), findsOneWidget);

      await tester.tap(find.byType(AppPrimaryButton));
      expect(tapped, isTrue);

      // Test loading state
      await tester.pumpWidget(
        buildTestableWidget(
          AppPrimaryButton(
            label: 'Lưu giao dịch',
            isLoading: true,
            onPressed: () {},
          ),
        ),
      );

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text('Lưu giao dịch'), findsNothing);
    });

    testWidgets('AppSecondaryButton renders and responds to tap', (tester) async {
      bool tapped = false;

      await tester.pumpWidget(
        buildTestableWidget(
          AppSecondaryButton(
            label: 'Hủy',
            onPressed: () => tapped = true,
          ),
        ),
      );

      expect(find.text('Hủy'), findsOneWidget);
      await tester.tap(find.text('Hủy'));
      expect(tapped, isTrue);
    });

    testWidgets('AppTextField handles input, hint, and error', (tester) async {
      final controller = TextEditingController();

      await tester.pumpWidget(
        buildTestableWidget(
          AppTextField(
            controller: controller,
            label: 'Ghi chú',
            hintText: 'Nhập ghi chú...',
            errorText: 'Bắt buộc',
          ),
        ),
      );

      expect(find.text('Ghi chú'), findsOneWidget);
      expect(find.text('Nhập ghi chú...'), findsOneWidget);
      expect(find.text('Bắt buộc'), findsOneWidget);

      await tester.enterText(find.byType(TextFormField), 'Cơm trưa');
      expect(controller.text, 'Cơm trưa');
    });

    testWidgets('AppEmptyState displays title, icon, and triggers action', (tester) async {
      bool actionTriggered = false;

      await tester.pumpWidget(
        buildTestableWidget(
          AppEmptyState(
            title: 'Chưa có giao dịch',
            subtitle: 'Bấm nút để thêm giao dịch đầu tiên',
            actionLabel: 'Thêm ngay',
            onAction: () => actionTriggered = true,
          ),
        ),
      );

      expect(find.text('Chưa có giao dịch'), findsOneWidget);
      expect(find.text('Bấm nút để thêm giao dịch đầu tiên'), findsOneWidget);

      await tester.tap(find.text('Thêm ngay'));
      expect(actionTriggered, isTrue);
    });

    testWidgets('AppErrorState displays message and retry action', (tester) async {
      bool retried = false;

      await tester.pumpWidget(
        buildTestableWidget(
          AppErrorState(
            message: 'Không thể kết nối cơ sở dữ liệu',
            onRetry: () => retried = true,
          ),
        ),
      );

      expect(find.text('Đã có lỗi xảy ra'), findsOneWidget);
      expect(find.text('Không thể kết nối cơ sở dữ liệu'), findsOneWidget);

      await tester.tap(find.text('Thử lại'));
      expect(retried, isTrue);
    });

    testWidgets('AppCard renders child and triggers onTap', (tester) async {
      bool tapped = false;

      await tester.pumpWidget(
        buildTestableWidget(
          AppCard(
            onTap: () => tapped = true,
            child: const Text('Nội dung thẻ'),
          ),
        ),
      );

      expect(find.text('Nội dung thẻ'), findsOneWidget);
      await tester.tap(find.text('Nội dung thẻ'));
      expect(tapped, isTrue);
    });

    testWidgets('AppSectionHeader renders title and action', (tester) async {
      await tester.pumpWidget(
        buildTestableWidget(
          AppSectionHeader(
            title: 'Giao dịch gần đây',
            subtitle: 'Tháng 10',
            trailing: const Text('Xem tất cả'),
          ),
        ),
      );

      expect(find.text('Giao dịch gần đây'), findsOneWidget);
      expect(find.text('Tháng 10'), findsOneWidget);
      expect(find.text('Xem tất cả'), findsOneWidget);
    });
  });
}
