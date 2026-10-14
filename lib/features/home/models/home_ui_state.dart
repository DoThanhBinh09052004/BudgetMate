import 'package:bugdetmate/features/budget/models/recurring_payment_model.dart';

/// Trạng thái bất biến của màn hình HomeScreen.
class HomeUiState {
  final bool isLoading;
  final bool isSyncing;
  final String? errorMessage;
  final double totalBalance;
  final BudgetSummary? budgetSummary;
  final List<Map<String, dynamic>> needsReviewTransactions;
  final List<Map<String, dynamic>> recentTransactions;
  final Map<String, List<Map<String, dynamic>>> groupedTransactions;

  const HomeUiState({
    this.isLoading = false,
    this.isSyncing = false,
    this.errorMessage,
    this.totalBalance = 0.0,
    this.budgetSummary,
    this.needsReviewTransactions = const [],
    this.recentTransactions = const [],
    this.groupedTransactions = const {},
  });

  HomeUiState copyWith({
    bool? isLoading,
    bool? isSyncing,
    String? errorMessage,
    double? totalBalance,
    BudgetSummary? budgetSummary,
    List<Map<String, dynamic>>? needsReviewTransactions,
    List<Map<String, dynamic>>? recentTransactions,
    Map<String, List<Map<String, dynamic>>>? groupedTransactions,
  }) {
    return HomeUiState(
      isLoading: isLoading ?? this.isLoading,
      isSyncing: isSyncing ?? this.isSyncing,
      errorMessage: errorMessage,
      totalBalance: totalBalance ?? this.totalBalance,
      budgetSummary: budgetSummary ?? this.budgetSummary,
      needsReviewTransactions:
          needsReviewTransactions ?? this.needsReviewTransactions,
      recentTransactions: recentTransactions ?? this.recentTransactions,
      groupedTransactions: groupedTransactions ?? this.groupedTransactions,
    );
  }
}
