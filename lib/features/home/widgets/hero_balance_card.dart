import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:bugdetmate/core/theme/app_theme.dart';
import 'package:bugdetmate/features/budget/models/recurring_payment_model.dart';

/// Thẻ tổng quan số dư ví, khả dụng thực tế và tốc độ chi tiêu (Burn-Rate).
class HeroBalanceCard extends StatelessWidget {
  final double totalBalance;
  final BudgetSummary? budgetSummary;
  final NumberFormat? currencyFormat;

  const HeroBalanceCard({
    super.key,
    required this.totalBalance,
    this.budgetSummary,
    this.currencyFormat,
  });

  @override
  Widget build(BuildContext context) {
    final format = currencyFormat ?? NumberFormat('#,###', 'vi_VN');
    final available = budgetSummary?.availableBalance ?? 0.0;
    final isWarning = budgetSummary?.isBurnRateWarning ?? false;
    final burnRate = budgetSummary?.dailyBurnRate ?? 0.0;

    return Card(
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: const LinearGradient(
            colors: [Color(0xFF1E293B), Color(0xFF0F172A)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Tổng số dư ví',
                  style: TextStyle(
                    color: AppTheme.textMutedDark,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppTheme.successGreen.withAlpha(35),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.check_circle,
                        size: 12,
                        color: AppTheme.successGreen,
                      ),
                      SizedBox(width: 4),
                      Text(
                        'Local-First',
                        style: TextStyle(
                          color: AppTheme.successGreen,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              '${format.format(totalBalance)} VND',
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w800,
                color: Colors.white,
                letterSpacing: -0.5,
              ),
            ),
            const Divider(color: AppTheme.darkBorder, height: 28),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Khả dụng thực tế',
                        style: TextStyle(
                          color: AppTheme.textMutedDark,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${format.format(available)} VND',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: available >= 0
                              ? AppTheme.primaryEmerald
                              : AppTheme.dangerRed,
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Text(
                            'Tốc độ tiêu',
                            style: TextStyle(
                              color: AppTheme.textMutedDark,
                              fontSize: 12,
                            ),
                          ),
                          if (isWarning) ...[
                            const SizedBox(width: 4),
                            const Icon(
                              Icons.warning_amber_rounded,
                              size: 14,
                              color: AppTheme.dangerRed,
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${format.format(burnRate.toInt())} đ/ngày',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: isWarning ? AppTheme.dangerRed : Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (isWarning) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: AppTheme.dangerRed.withAlpha(30),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppTheme.dangerRed.withAlpha(80)),
                ),
                child: const Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      size: 14,
                      color: AppTheme.dangerRed,
                    ),
                    SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        'Cảnh báo: Tốc độ chi tiêu dự kiến vượt ngân sách chu kỳ!',
                        style: TextStyle(
                          color: AppTheme.dangerRed,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
