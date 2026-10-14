import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:bugdetmate/core/theme/app_theme.dart';

/// Danh sách giao dịch cần xác nhận (từ thông báo ngân hàng hoặc chuyển khoản).
class NeedsReviewSection extends StatelessWidget {
  final List<Map<String, dynamic>> needsReviewTransactions;
  final ValueChanged<int> onConfirm;
  final NumberFormat? currencyFormat;

  const NeedsReviewSection({
    super.key,
    required this.needsReviewTransactions,
    required this.onConfirm,
    this.currencyFormat,
  });

  @override
  Widget build(BuildContext context) {
    if (needsReviewTransactions.isEmpty) return const SizedBox.shrink();
    final format = currencyFormat ?? NumberFormat('#,###', 'vi_VN');

    return Card(
      color: AppTheme.warningAmber.withAlpha(25),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: AppTheme.warningAmber.withAlpha(90)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.assignment_late_outlined,
                  color: AppTheme.warningAmber,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  'Cần xác nhận (${needsReviewTransactions.length} giao dịch)',
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    color: AppTheme.warningAmber,
                    fontSize: 15,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            const Text(
              'Có giao dịch được nhận diện tự động hoặc chuyển tiền cần bạn kiểm tra:',
              style: TextStyle(color: AppTheme.textMutedDark, fontSize: 12),
            ),
            const SizedBox(height: 10),
            ...needsReviewTransactions.map((tx) {
              final amount = (tx['amount'] as num?)?.toDouble() ?? 0.0;
              final note = tx['note'] as String? ?? 'Giao dịch không tên';
              final id = tx['id'] as int;

              return Container(
                margin: const EdgeInsets.only(top: 8),
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: AppTheme.darkSurface,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            note,
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                            ),
                          ),
                          Text(
                            '${format.format(amount)} VND',
                            style: const TextStyle(
                              color: AppTheme.textMutedDark,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    TextButton(
                      style: TextButton.styleFrom(
                        foregroundColor: AppTheme.primaryEmerald,
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                      ),
                      onPressed: () => onConfirm(id),
                      child: const Text('Xác nhận'),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}
