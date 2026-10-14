import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:bugdetmate/core/theme/app_theme.dart';
import 'package:bugdetmate/core/theme/icon_resolver.dart';
import 'package:bugdetmate/core/widgets/app_widgets.dart';

/// Danh sách giao dịch gần đây được gom nhóm theo Ngày kèm Header và thông tin danh mục cha-con.
class RecentTransactionsSection extends StatelessWidget {
  final List<Map<String, dynamic>> transactions;
  final ValueChanged<Map<String, dynamic>> onTapTransaction;
  final NumberFormat? currencyFormat;

  const RecentTransactionsSection({
    super.key,
    required this.transactions,
    required this.onTapTransaction,
    this.currencyFormat,
  });

  String _formatWeekday(DateTime day) {
    switch (day.weekday) {
      case DateTime.monday:
        return 'Thứ Hai';
      case DateTime.tuesday:
        return 'Thứ Ba';
      case DateTime.wednesday:
        return 'Thứ Tư';
      case DateTime.thursday:
        return 'Thứ Năm';
      case DateTime.friday:
        return 'Thứ Sáu';
      case DateTime.saturday:
        return 'Thứ Bảy';
      case DateTime.sunday:
        return 'Chủ Nhật';
      default:
        return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    if (transactions.isEmpty) {
      return const AppEmptyState(
        title: 'Chưa có giao dịch nào',
        subtitle: 'Bấm nút (+) bên dưới để thêm giao dịch đầu tiên',
        icon: Icons.receipt_long_outlined,
      );
    }

    final format = currencyFormat ?? NumberFormat('#,###', 'vi_VN');

    // Gom nhóm giao dịch theo từng ngày (Date Grouping)
    final Map<DateTime, List<Map<String, dynamic>>> grouped = {};
    for (final tx in transactions) {
      final dateSec = tx['transaction_date'] as int;
      final d = DateTime.fromMillisecondsSinceEpoch(dateSec * 1000);
      final dayKey = DateTime(d.year, d.month, d.day);
      grouped.putIfAbsent(dayKey, () => []).add(tx);
    }

    final sortedDays = grouped.keys.toList()..sort((a, b) => b.compareTo(a));

    return Column(
      children: sortedDays.map((day) {
        final dayTxs = grouped[day]!;
        double dayTotal = 0;
        for (final tx in dayTxs) {
          final amount = (tx['amount'] as num?)?.toDouble() ?? 0.0;
          final type = tx['type'] as String? ?? 'expense';
          dayTotal += (type == 'expense' ? -amount : amount);
        }

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: Column(
            children: [
              // Day Header
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  children: [
                    Text(
                      DateFormat('dd').format(day),
                      style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(width: 10),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _formatWeekday(day),
                          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                        ),
                        Text(
                          'tháng ${day.month}, ${day.year}',
                          style: const TextStyle(color: AppTheme.textMutedDark, fontSize: 11),
                        ),
                      ],
                    ),
                    const Spacer(),
                    Text(
                      '${dayTotal < 0 ? '-' : (dayTotal > 0 ? '+' : '')}${format.format(dayTotal.abs().toInt())} đ',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                        color: dayTotal < 0
                            ? AppTheme.expenseRed
                            : (dayTotal > 0 ? AppTheme.incomeGreen : AppTheme.textMutedDark),
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(color: AppTheme.darkBorder, height: 1),

              // Transaction items of this day
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: dayTxs.length,
                separatorBuilder: (_, index) => const Divider(color: AppTheme.darkBorder, height: 1),
                itemBuilder: (context, index) {
                  final tx = dayTxs[index];
                  final type = tx['type'] as String? ?? 'expense';
                  final amount = (tx['amount'] as num?)?.toDouble() ?? 0.0;
                  final note = tx['note'] as String?;
                  final dateSec = tx['transaction_date'] as int;
                  final date = DateTime.fromMillisecondsSinceEpoch(dateSec * 1000);
                  final timeString = DateFormat('HH:mm').format(date);

                  final catName = tx['category_name'] as String?;
                  final parentName = tx['parent_name'] as String?;
                  final catIconStr = tx['category_icon'] as String?;
                  final catColorStr = tx['category_color'] as String?;

                  final catIcon = IconResolver.resolve(catIconStr);
                  final catColor = IconResolver.resolveColor(catColorStr);

                  String title;
                  if (parentName != null && parentName.isNotEmpty && catName != null && catName.isNotEmpty) {
                    title = '$parentName › $catName';
                  } else if (catName != null && catName.isNotEmpty) {
                    title = catName;
                  } else {
                    title = note ?? (type == 'expense' ? 'Chi tiêu' : 'Thu nhập');
                  }

                  final subtitle = note != null && note.isNotEmpty ? '$note • $timeString' : timeString;

                  final isExpense = type == 'expense';
                  final amountColor = isExpense ? AppTheme.expenseRed : AppTheme.incomeGreen;

                  return ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    onTap: () => onTapTransaction(tx),
                    leading: CircleAvatar(
                      backgroundColor: catColor.withAlpha(35),
                      child: Icon(catIcon, color: catColor, size: 18),
                    ),
                    title: Text(
                      title,
                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    subtitle: Text(
                      subtitle,
                      style: const TextStyle(color: AppTheme.textMutedDark, fontSize: 12),
                    ),
                    trailing: Text(
                      '${isExpense ? '-' : '+'}${format.format(amount)} VND',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                        color: amountColor,
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}
