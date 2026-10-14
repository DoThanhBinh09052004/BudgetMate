import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';
import 'package:bugdetmate/core/theme/app_theme.dart';
import 'package:bugdetmate/core/widgets/app_widgets.dart';
import 'package:bugdetmate/features/budget/models/recurring_payment_model.dart';
import 'package:bugdetmate/features/home/controllers/home_controller.dart';
import 'package:bugdetmate/features/home/widgets/hero_balance_card.dart';
import 'package:bugdetmate/features/home/widgets/needs_review_section.dart';
import 'package:bugdetmate/features/home/widgets/recent_transactions_section.dart';
import 'package:bugdetmate/features/home/widgets/about_bottom_sheet.dart';
import 'package:bugdetmate/features/transactions/screens/quick_add_sheet.dart';
import 'package:bugdetmate/features/transactions/screens/edit_transaction_sheet.dart';
import 'package:bugdetmate/features/settings/screens/permission_guide_screen.dart';

/// Màn hình chính HomeScreen sau khi refactor theo Clean Architecture.
/// Giao diện mỏng (Thin View), điều phối state qua HomeController và các Sub-Widgets.
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
  late final HomeController _controller;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    _controller = HomeController(
      db: widget.db,
      initialTotalBalance: widget.initialTotalBalance,
      initialBudgetSummary: widget.initialBudgetSummary,
      initialRecentTransactions: widget.initialRecentTransactions,
      initialNeedsReviewTransactions: widget.initialNeedsReviewTransactions,
    );

    if (widget.initialTotalBalance == null &&
        widget.initialBudgetSummary == null &&
        widget.initialRecentTransactions == null &&
        widget.initialNeedsReviewTransactions == null) {
      _controller.loadData();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _controller.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _controller.onAppResumed();
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
      builder: (_) => QuickAddSheet(
        onSaved: () => _controller.loadData(forceSync: false),
        db: widget.db,
      ),
    );
  }

  void _openEditTransaction(Map<String, dynamic> tx) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.darkSurface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => EditTransactionSheet(
        transaction: tx,
        onSaved: () => _controller.loadData(forceSync: false),
        db: widget.db,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _controller,
      builder: (context, _) {
        final state = _controller.state;

        return Scaffold(
          appBar: AppBar(
            title: InkWell(
              borderRadius: BorderRadius.circular(8),
              onTap: () => AboutBottomSheet.show(context),
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
                tooltip: 'Cài đặt quyền & Chạy nền',
                icon: const Icon(
                  Icons.tune_rounded,
                  color: AppTheme.primaryEmerald,
                ),
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const PermissionGuideScreen(),
                    ),
                  );
                },
              ),
              IconButton(
                tooltip: 'Làm mới',
                icon: const Icon(Icons.refresh_rounded),
                onPressed: () => _controller.loadData(forceSync: true),
              ),
            ],
          ),
          floatingActionButton: FloatingActionButton(
            tooltip: 'Nhập giao dịch',
            onPressed: _openQuickAdd,
            child: const Icon(Icons.add, size: 28),
          ),
          body: state.isLoading
              ? const AppLoading()
              : RefreshIndicator(
                  onRefresh: () => _controller.loadData(forceSync: true),
                  child: ListView(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    children: [
                      HeroBalanceCard(
                        totalBalance: state.totalBalance,
                        budgetSummary: state.budgetSummary,
                      ),
                      const SizedBox(height: 16),
                      if (state.needsReviewTransactions.isNotEmpty) ...[
                        NeedsReviewSection(
                          needsReviewTransactions:
                              state.needsReviewTransactions,
                          onConfirm: _controller.confirmNeedsReview,
                        ),
                        const SizedBox(height: 16),
                      ],
                      const AppSectionHeader(title: 'Giao dịch gần đây'),
                      const SizedBox(height: 8),
                      RecentTransactionsSection(
                        transactions: state.recentTransactions,
                        onTapTransaction: _openEditTransaction,
                      ),
                      const SizedBox(height: 80), // Padding for FAB
                    ],
                  ),
                ),
        );
      },
    );
  }
}
