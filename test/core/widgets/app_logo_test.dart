import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:bugdetmate/core/widgets/app_logo.dart';
import 'package:bugdetmate/core/constants/app_constants.dart';

void main() {
  testWidgets('AppLogo renders properly with custom size and constants', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: AppLogo(
            size: 48,
            borderRadius: 12,
            showShadow: true,
          ),
        ),
      ),
    );

    // Verify AppConstants defines the logo path
    expect(AppConstants.appLogo, 'assets/images/logo.png');

    // Verify AppLogo widget tree exists
    expect(find.byType(AppLogo), findsOneWidget);
    expect(find.byType(ClipRRect), findsOneWidget);
  });
}
