import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'package:sqflite/sqflite.dart';
import 'package:bugdetmate/core/database/database_helper.dart';
import 'package:bugdetmate/features/home/models/home_ui_state.dart';
import 'package:bugdetmate/features/transactions/services/transaction_service.dart';
import 'package:bugdetmate/features/budget/services/budget_service.dart';
import 'package:bugdetmate/features/budget/models/recurring_payment_model.dart';
import 'package:bugdetmate/features/parser/services/regex_parser_service.dart';
import 'package:bugdetmate/features/parser/services/raw_sync_service.dart';

/// Controller điều phối dữ liệu cho HomeScreen với bảo vệ Concurrency, Debounce và Safe Async.
class HomeController extends ChangeNotifier {
  final Database? db;
  TransactionService? transactionService;
  BudgetService? budgetService;

  HomeUiState _state = const HomeUiState(isLoading: true);
  HomeUiState get state => _state;

  bool _disposed = false;
  bool get isDisposed => _disposed;

  bool _isFetching = false;
  DateTime? _lastSyncTime;

  HomeController({
    this.db,
    this.transactionService,
    this.budgetService,
    double? initialTotalBalance,
    BudgetSummary? initialBudgetSummary,
    List<Map<String, dynamic>>? initialRecentTransactions,
    List<Map<String, dynamic>>? initialNeedsReviewTransactions,
  }) {
    if (initialTotalBalance != null ||
        initialBudgetSummary != null ||
        initialRecentTransactions != null ||
        initialNeedsReviewTransactions != null) {
      final recent = initialRecentTransactions ?? [];
      _state = HomeUiState(
        isLoading: false,
        totalBalance: initialTotalBalance ?? 0.0,
        budgetSummary: initialBudgetSummary,
        recentTransactions: recent,
        needsReviewTransactions: initialNeedsReviewTransactions ?? [],
        groupedTransactions: groupTransactionsByDate(recent),
      );
    }
  }

  Future<void> _ensureServices() async {
    if (transactionService != null && budgetService != null) return;
    final activeDb = db ?? await DatabaseHelper.instance.database;
    transactionService ??= TransactionService(db: activeDb);
    budgetService ??= BudgetService(db: activeDb);
  }

  /// Tải dữ liệu chính với cơ chế chống race condition (concurrency lock).
  Future<void> loadData({bool forceSync = true}) async {
    if (_disposed || _isFetching) return;
    _isFetching = true;

    if (_state.recentTransactions.isEmpty && _state.budgetSummary == null) {
      _updateState(_state.copyWith(isLoading: true));
    }

    try {
      final activeDb = db ?? await DatabaseHelper.instance.database;
      await _ensureServices();

      // 0. Bóc tách và đồng bộ thông báo thô nếu cần
      if (forceSync) {
        try {
          final parser = RegexParserService();
          await parser.loadRulesFromAsset();
          final rawSync = RawSyncService(db: activeDb, parser: parser);
          await rawSync.syncUnprocessed();
          _lastSyncTime = DateTime.now();
        } catch (_) {}
      }

      // 1. Tổng số dư ví
      final totalBalance = await transactionService!.getTotalBalance();

      // 2. Budget summary
      final now = DateTime.now();
      final cycleMonth = DateFormat('yyyy-MM').format(now);
      final summary = await budgetService!.getBudgetSummary(
        cycleMonth: cycleMonth,
        now: now,
      );

      // 3. Needs review
      final needsReview = await transactionService!.getNeedsReviewTransactions(
        limit: 5,
      );

      // 4. Recent transactions
      final recent = await transactionService!.getRecentTransactions(limit: 40);
      final grouped = groupTransactionsByDate(recent);

      _updateState(
        HomeUiState(
          isLoading: false,
          isSyncing: false,
          totalBalance: totalBalance,
          budgetSummary: summary,
          needsReviewTransactions: needsReview,
          recentTransactions: recent,
          groupedTransactions: grouped,
        ),
      );
    } catch (e) {
      _updateState(
        _state.copyWith(isLoading: false, errorMessage: e.toString()),
      );
    } finally {
      _isFetching = false;
    }
  }

  /// Gọi khi app resumed từ notification / switch app, kèm debounce 3 giây.
  Future<void> onAppResumed() async {
    final now = DateTime.now();
    if (_lastSyncTime != null && now.difference(_lastSyncTime!).inSeconds < 3) {
      return; // Bỏ qua nếu vừa đồng bộ cách đây dưới 3 giây
    }
    await loadData(forceSync: true);
  }

  /// Xác nhận một giao dịch (bỏ cờ needs_review) và cập nhật state.
  Future<void> confirmNeedsReview(int txId) async {
    if (_disposed) return;
    try {
      await _ensureServices();
      await transactionService!.confirmTransaction(txId);
      await loadData(forceSync: false);
    } catch (_) {}
  }

  /// Gom nhóm danh sách giao dịch theo Ngày (Date Header).
  static Map<String, List<Map<String, dynamic>>> groupTransactionsByDate(
    List<Map<String, dynamic>> transactions,
  ) {
    final Map<String, List<Map<String, dynamic>>> grouped = {};
    for (final tx in transactions) {
      final timestamp = tx['transaction_date'] as int?;
      if (timestamp == null) continue;
      final date = DateTime.fromMillisecondsSinceEpoch(timestamp * 1000);
      final key = DateFormat('yyyy-MM-dd').format(date);
      grouped.putIfAbsent(key, () => []).add(tx);
    }
    return grouped;
  }

  void _updateState(HomeUiState newState) {
    if (_disposed) return;
    _state = newState;
    notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
