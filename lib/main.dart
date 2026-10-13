import 'package:flutter/material.dart';
import 'package:bugdetmate/core/database/database_helper.dart';
import 'package:bugdetmate/core/theme/app_theme.dart';
import 'package:bugdetmate/core/native_bridge/notification_bridge.dart';
import 'package:bugdetmate/features/home/screens/home_screen.dart';
import 'package:bugdetmate/features/parser/services/regex_parser_service.dart';
import 'package:bugdetmate/features/parser/services/raw_sync_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 1. Khởi tạo SQLite Database
  final db = await DatabaseHelper.instance.database;

  // 2. Load JSON Regex Bank Rules động từ Assets
  final parser = RegexParserService();
  try {
    await parser.loadRulesFromAsset();
  } catch (_) {
    // Dự phòng khi chạy trong môi trường test không có asset bundle
  }

  // 3. Đẩy Whitelist packageName sang Java Native SharedPreferences
  try {
    final packageNames = parser.getPackageNames();
    if (packageNames.isNotEmpty) {
      await NotificationBridge.updateWhitelist(packageNames);
    }
  } catch (_) {
    // Bỏ qua trên môi trường desktop/testing không có Android runtime
  }

  // 4. Batch Sync các thông báo thô chưa xử lý trong Raw Buffer
  try {
    final rawSyncService = RawSyncService(db: db, parser: parser);
    await rawSyncService.syncUnprocessed();
  } catch (_) {}

  runApp(const BudgetMateApp());
}

class BudgetMateApp extends StatelessWidget {
  const BudgetMateApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'BudgetMate',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.dark, // Mặc định Dark Theme fintech
      home: const HomeScreen(),
    );
  }
}
