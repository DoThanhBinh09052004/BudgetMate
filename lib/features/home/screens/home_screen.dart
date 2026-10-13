import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:bugdetmate/core/database/database_helper.dart';
import 'package:bugdetmate/core/database/tables.dart';
import 'package:bugdetmate/core/theme/app_theme.dart';
import 'package:bugdetmate/features/budget/services/budget_service.dart';
import 'package:bugdetmate/features/budget/models/recurring_payment_model.dart';
import 'package:bugdetmate/features/transactions/screens/quick_add_sheet.dart';
import 'package:bugdetmate/features/settings/screens/miui_guide_screen.dart';

import 'package:bugdetmate/core/widgets/app_logo.dart';
import 'package:bugdetmate/features/parser/services/regex_parser_service.dart';
import 'package:bugdetmate/features/parser/services/raw_sync_service.dart';
import 'package:sqflite/sqflite.dart';

/// Màn hình chính HomeScreen với giao diện Fintech UI/UX Pro Max.
class HomeScreen extends StatefulWidget {
  final Database? db;
  final double? initialTotalBalance;
  final BudgetSummary? initialBudgetSummary;
  final List<Map<String, dynamic>>? initialRecentTransactions;
  final List<Map<String, dynamic>>? initialNeedsReviewTransactions;

  const HomeScreen({
    super.key,
    this.db,
    this.initialTotalBalance,
    this.initialBudgetSummary,
    this.initialRecentTransactions,
    this.initialNeedsReviewTransactions,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  late bool _isLoading;
  double _totalBalance = 0.0;
  BudgetSummary? _budgetSummary;
  List<Map<String, dynamic>> _recentTransactions = [];
  List<Map<String, dynamic>> _needsReviewTransactions = [];

  final NumberFormat _currencyFormat = NumberFormat('#,###', 'vi_VN');

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    if (widget.initialTotalBalance != null ||
        widget.initialBudgetSummary != null ||
        widget.initialNeedsReviewTransactions != null) {
      _isLoading = false;
      _totalBalance = widget.initialTotalBalance ?? 0.0;
      _budgetSummary = widget.initialBudgetSummary;
      _recentTransactions = widget.initialRecentTransactions ?? [];
      _needsReviewTransactions = widget.initialNeedsReviewTransactions ?? [];
    } else {
      _isLoading = true;
      _loadData();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // Khi quay lại app từ màn hình SMS/Notification, tự động refresh và bóc tách dữ liệu mới
      _loadData();
    }
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    try {
      final db = widget.db ?? await DatabaseHelper.instance.database;

      // 0. Tự động bóc tách và đồng bộ các thông báo SMS/App mới trong bộ đệm raw_notifications
      try {
        final parser = RegexParserService();
        await parser.loadRulesFromAsset();
        final rawSync = RawSyncService(db: db, parser: parser);
        await rawSync.syncUnprocessed();
      } catch (_) {}

      // 1. Calculate total balance across wallets
      final walletRows = await db.rawQuery('SELECT SUM(balance) as total FROM ${AppTables.wallets}');
      final totalBalance = (walletRows.first['total'] as num?)?.toDouble() ?? 0.0;

      // 2. Budget & Burn-rate summary
      final now = DateTime.now();
      final cycleMonth = DateFormat('yyyy-MM').format(now);
      final budgetService = BudgetService(db: db);
      final summary = await budgetService.getBudgetSummary(cycleMonth: cycleMonth, now: now);

      // 3. Needs review transactions
      final needsReview = await db.query(
        AppTables.transactions,
        where: 'needs_review = ?',
        whereArgs: [1],
        orderBy: 'transaction_date DESC',
        limit: 5,
      );

      // 4. Recent transactions
      final recent = await db.query(
        AppTables.transactions,
        orderBy: 'transaction_date DESC',
        limit: 20,
      );

      setState(() {
        _totalBalance = totalBalance;
        _budgetSummary = summary;
        _needsReviewTransactions = needsReview;
        _recentTransactions = recent;
        _isLoading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _openQuickAdd() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.darkSurface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => QuickAddSheet(onSaved: _loadData, db: widget.db),
    );
  }

  Future<void> _confirmNeedsReview(int txId) async {
    final db = widget.db ?? await DatabaseHelper.instance.database;
    await db.update(
      AppTables.transactions,
      {'needs_review': 0},
      where: 'id = ?',
      whereArgs: [txId],
    );
    await _loadData();
  }

  void _showAboutBudgetMate() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.darkSurface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            const AppLogo(size: 72, borderRadius: 16, showShadow: true),
            const SizedBox(height: 14),
            const Text(
              'BudgetMate',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'Phiên bản 1.0.0 (Build 1)',
              style: TextStyle(
                fontSize: 13,
                color: AppTheme.textMutedDark,
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppTheme.darkSurfaceVariant,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.white12),
              ),
              child: const Column(
                children: [
                  Row(
                    children: [
                      Icon(Icons.lock_outline_rounded, size: 18, color: AppTheme.successGreen),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          '100% Offline & Bảo mật: Toàn bộ dữ liệu tài chính lưu trên máy của bạn.',
                          style: TextStyle(fontSize: 13, color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(Icons.bolt_rounded, size: 18, color: AppTheme.warningAmber),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Tự động bắt biến động số dư SMS / Notification ngân hàng thông minh.',
                          style: TextStyle(fontSize: 13, color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryBlue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Đóng', style: TextStyle(fontWeight: FontWeight.w600)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: _showAboutBudgetMate,
          child: const Padding(
            padding: EdgeInsets.symmetric(vertical: 4, horizontal: 2),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                AppLogo(size: 32, borderRadius: 8),
                SizedBox(width: 12),
                Text('BudgetMate'),
              ],
            ),
          ),
        ),
        actions: [
          IconButton(
            tooltip: 'Hướng dẫn MIUI',
            icon: const Icon(Icons.shield_outlined, color: AppTheme.warningAmber),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const MiuiGuideScreen()),
              );
            },
          ),
          IconButton(
            tooltip: 'Làm mới',
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _loadData,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        tooltip: 'Nhập giao dịch',
        onPressed: _openQuickAdd,
        child: const Icon(Icons.add, size: 28),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadData,
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                children: [
                  _buildHeroBalanceCard(),
                  const SizedBox(height: 16),
                  if (_needsReviewTransactions.isNotEmpty) ...[
                    _buildNeedsReviewBanner(),
                    const SizedBox(height: 16),
                  ],
                  _buildRecentTransactionsHeader(),
                  const SizedBox(height: 8),
                  _buildRecentTransactionsList(),
                  const SizedBox(height: 80), // Padding for FAB
                ],
              ),
            ),
    );
  }

  Widget _buildHeroBalanceCard() {
    final available = _budgetSummary?.availableBalance ?? 0.0;
    final isWarning = _budgetSummary?.isBurnRateWarning ?? false;
    final burnRate = _budgetSummary?.dailyBurnRate ?? 0.0;

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
                  style: TextStyle(color: AppTheme.textMutedDark, fontSize: 13, fontWeight: FontWeight.w600),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppTheme.successGreen.withAlpha(35),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.check_circle, size: 12, color: AppTheme.successGreen),
                      SizedBox(width: 4),
                      Text(
                        'Local-First',
                        style: TextStyle(color: AppTheme.successGreen, fontSize: 11, fontWeight: FontWeight.w700),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              '${_currencyFormat.format(_totalBalance)} VND',
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
                        style: TextStyle(color: AppTheme.textMutedDark, fontSize: 12),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${_currencyFormat.format(available)} VND',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: available >= 0 ? AppTheme.primaryBlue : AppTheme.dangerRed,
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
                            style: TextStyle(color: AppTheme.textMutedDark, fontSize: 12),
                          ),
                          if (isWarning) ...[
                            const SizedBox(width: 4),
                            const Icon(Icons.warning_amber_rounded, size: 14, color: AppTheme.dangerRed),
                          ],
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${_currencyFormat.format(burnRate.toInt())} đ/ngày',
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
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: AppTheme.dangerRed.withAlpha(30),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppTheme.dangerRed.withAlpha(80)),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.info_outline, size: 14, color: AppTheme.dangerRed),
                    SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        'Cảnh báo: Tốc độ chi tiêu dự kiến vượt ngân sách chu kỳ!',
                        style: TextStyle(color: AppTheme.dangerRed, fontSize: 11, fontWeight: FontWeight.w600),
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

  Widget _buildNeedsReviewBanner() {
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
                const Icon(Icons.assignment_late_outlined, color: AppTheme.warningAmber, size: 20),
                const SizedBox(width: 8),
                Text(
                  'Cần xác nhận (${_needsReviewTransactions.length} giao dịch)',
                  style: const TextStyle(fontWeight: FontWeight.w700, color: AppTheme.warningAmber, fontSize: 15),
                ),
              ],
            ),
            const SizedBox(height: 6),
            const Text(
              'Có giao dịch được nhận diện tự động hoặc chuyển tiền cần bạn kiểm tra:',
              style: TextStyle(color: AppTheme.textMutedDark, fontSize: 12),
            ),
            const SizedBox(height: 10),
            ..._needsReviewTransactions.map((tx) {
              final amount = (tx['amount'] as num).toDouble();
              final note = tx['note'] as String? ?? 'Giao dịch không tên';
              final id = tx['id'] as int;
              return Container(
                margin: const EdgeInsets.only(top: 8),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
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
                          Text(note, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                          Text(
                            '${_currencyFormat.format(amount)} VND',
                            style: const TextStyle(color: AppTheme.textMutedDark, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                    TextButton(
                      style: TextButton.styleFrom(
                        foregroundColor: AppTheme.primaryBlue,
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                      ),
                      onPressed: () => _confirmNeedsReview(id),
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

  Widget _buildRecentTransactionsHeader() {
    return const Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          'Giao dịch gần đây',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
        ),
      ],
    );
  }

  Widget _buildRecentTransactionsList() {
    if (_recentTransactions.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            children: [
              Icon(Icons.receipt_long_outlined, size: 40, color: AppTheme.textMutedDark.withAlpha(120)),
              const SizedBox(height: 8),
              const Text(
                'Chưa có giao dịch nào',
                style: TextStyle(color: AppTheme.textMutedDark, fontSize: 14),
              ),
              const SizedBox(height: 4),
              const Text(
                'Bấm nút (+) bên dưới để thêm giao dịch đầu tiên',
                style: TextStyle(color: AppTheme.textMutedDark, fontSize: 12),
              ),
            ],
          ),
        ),
      );
    }

    return Card(
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: _recentTransactions.length,
        separatorBuilder: (_, index) => const Divider(color: AppTheme.darkBorder, height: 1),
        itemBuilder: (context, index) {
          final tx = _recentTransactions[index];
          final type = tx['type'] as String;
          final amount = (tx['amount'] as num).toDouble();
          final note = tx['note'] as String? ?? (type == 'expense' ? 'Chi tiêu' : 'Thu nhập');
          final dateSec = tx['transaction_date'] as int;
          final date = DateTime.fromMillisecondsSinceEpoch(dateSec * 1000);
          final dateString = DateFormat('dd/MM HH:mm').format(date);

          final isExpense = type == 'expense';
          final color = isExpense
              ? AppTheme.dangerRed
              : (type == 'income' ? AppTheme.successGreen : AppTheme.purpleAccent);

          return ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            leading: CircleAvatar(
              backgroundColor: color.withAlpha(35),
              child: Icon(
                isExpense
                    ? Icons.arrow_upward_rounded
                    : (type == 'income' ? Icons.arrow_downward_rounded : Icons.swap_horiz_rounded),
                color: color,
                size: 20,
              ),
            ),
            title: Text(
              note,
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            subtitle: Text(
              dateString,
              style: const TextStyle(color: AppTheme.textMutedDark, fontSize: 12),
            ),
            trailing: Text(
              '${isExpense ? '-' : '+'}${_currencyFormat.format(amount)} VND',
              style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 14,
                color: color,
              ),
            ),
          );
        },
      ),
    );
  }
}
