import 'package:flutter/material.dart';
import 'package:bugdetmate/core/native_bridge/notification_bridge.dart';
import 'package:bugdetmate/core/theme/app_theme.dart';

/// Màn hình hướng dẫn thiết lập nền chuyên sâu cho Xiaomi/Redmi (MIUI & HyperOS).
class MiuiGuideScreen extends StatefulWidget {
  const MiuiGuideScreen({super.key});

  @override
  State<MiuiGuideScreen> createState() => _MiuiGuideScreenState();
}

class _MiuiGuideScreenState extends State<MiuiGuideScreen> {
  bool _hasPermission = false;

  @override
  void initState() {
    super.initState();
    _checkStatus();
  }

  Future<void> _checkStatus() async {
    try {
      final granted = await NotificationBridge.checkPermission();
      setState(() => _hasPermission = granted);
    } catch (_) {
      // Ignored for testing environments
    }
  }

  Future<void> _handleRebind() async {
    try {
      await NotificationBridge.rebindService();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Đã gửi lệnh kích hoạt lại Notification Service!'),
            backgroundColor: AppTheme.successGreen,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi kích hoạt service: $e'),
            backgroundColor: AppTheme.dangerRed,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tối ưu MIUI / Xiaomi'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildStatusBanner(),
          const SizedBox(height: 16),
          const Text(
            'Các bước cấu hình chống ngắt nền trên Redmi Note 11:',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 12),
          _buildStepCard(
            stepNumber: '1',
            title: 'Quyền Đọc Thông Báo (Bắt buộc)',
            description:
                'Cho phép BudgetMate lắng nghe thông báo biến động số dư từ ứng dụng ngân hàng.',
            actionLabel: 'Mở Cài Đặt Quyền',
            onAction: () async {
              await NotificationBridge.requestPermission();
              await _checkStatus();
            },
          ),
          _buildStepCard(
            stepNumber: '2',
            title: 'Tự Khởi Chạy (Autostart)',
            description:
                'Vào Cài đặt > Ứng dụng > Quyền > Tự khởi chạy > Bật [BudgetMate] để app tự chạy khi nhận thông báo.',
          ),
          _buildStepCard(
            stepNumber: '3',
            title: 'Tiết Kiệm Pin (Battery Saver)',
            description:
                'Vào Thông tin ứng dụng BudgetMate > Tiết kiệm pin > Chọn [Không giới hạn] (No restrictions). Tránh bị MIUI đóng ngầm.',
          ),
          _buildStepCard(
            stepNumber: '4',
            title: 'Khóa Ứng Dụng Trong Đa Nhiệm',
            description:
                'Mở màn hình Đa nhiệm (Recent apps) > Nhấn giữ cửa sổ BudgetMate > Nhấn biểu tượng Ổ Khóa 🔒.',
          ),
          const SizedBox(height: 20),
          Card(
            color: AppTheme.darkSurfaceVariant,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'Khôi phục kết nối (Rebind Bridge)',
                    style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Nếu bạn vừa đổi cài đặt hệ thống hoặc nghi ngờ MIUI làm ngắt kết nối đọc thông báo, hãy bấm nút dưới để rebind lại service ngay lập tức.',
                    style: TextStyle(color: AppTheme.textMutedDark, fontSize: 13),
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryBlue,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    icon: const Icon(Icons.refresh_rounded),
                    label: const Text('Kích Hoạt Lại Service Ngay'),
                    onPressed: _handleRebind,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBanner() {
    return Card(
      color: _hasPermission
          ? AppTheme.successGreen.withAlpha(35)
          : AppTheme.warningAmber.withAlpha(35),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: _hasPermission ? AppTheme.successGreen : AppTheme.warningAmber,
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(
              _hasPermission ? Icons.check_circle_rounded : Icons.warning_amber_rounded,
              color: _hasPermission ? AppTheme.successGreen : AppTheme.warningAmber,
              size: 32,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _hasPermission ? 'Đã Cấp Quyền Đọc Thông Báo' : 'Chưa Cấp Quyền Đọc Thông Báo',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      color: _hasPermission ? AppTheme.successGreen : AppTheme.warningAmber,
                      fontSize: 15,
                    ),
                  ),
                  Text(
                    _hasPermission
                        ? 'Service đang sẵn sàng bóc tách biến động số dư tự động.'
                        : 'Vui lòng nhấn nút bên dưới để cấp quyền truy cập thông báo.',
                    style: const TextStyle(fontSize: 12, color: AppTheme.textMutedDark),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStepCard({
    required String stepNumber,
    required String title,
    required String description,
    String? actionLabel,
    VoidCallback? onAction,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 12,
                  backgroundColor: AppTheme.primaryBlue,
                  child: Text(
                    stepNumber,
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Colors.white),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              description,
              style: const TextStyle(color: AppTheme.textMutedDark, fontSize: 13, height: 1.4),
            ),
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: 10),
              OutlinedButton(
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppTheme.primaryBlue,
                  side: const BorderSide(color: AppTheme.primaryBlue),
                ),
                onPressed: onAction,
                child: Text(actionLabel),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
