class AppTables {
  static const String wallets = 'wallets';
  static const String categories = 'categories';
  static const String rawNotifications = 'raw_notifications';
  static const String transactions = 'transactions';
  static const String userCategoryRules = 'user_category_rules';
  static const String budgets = 'budgets';
  static const String recurringRules = 'recurring_rules';
  static const String recurringPayments = 'recurring_payments';

  static const String createWallets = '''
    CREATE TABLE $wallets (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      name TEXT NOT NULL,
      type TEXT NOT NULL,
      balance REAL DEFAULT 0,
      account_number_suffix TEXT,
      icon TEXT,
      color TEXT,
      created_at INTEGER NOT NULL DEFAULT (strftime('%s','now'))
    );
  ''';

  static const String createCategories = '''
    CREATE TABLE $categories (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      name TEXT NOT NULL,
      type TEXT NOT NULL,
      icon TEXT,
      color TEXT,
      parent_id INTEGER,
      is_default INTEGER DEFAULT 0,
      created_at INTEGER NOT NULL DEFAULT (strftime('%s','now')),
      FOREIGN KEY (parent_id) REFERENCES $categories (id) ON DELETE CASCADE
    );
  ''';

  static const String createRawNotifications = '''
    CREATE TABLE $rawNotifications (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      package_name TEXT NOT NULL,
      sbn_key TEXT UNIQUE NOT NULL,
      post_time INTEGER NOT NULL,
      title TEXT,
      text TEXT,
      is_processed INTEGER DEFAULT 0
    );
  ''';

  static const String createTransactions = '''
    CREATE TABLE $transactions (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      wallet_id INTEGER NOT NULL,
      category_id INTEGER,
      amount REAL NOT NULL,
      type TEXT NOT NULL,
      transaction_date INTEGER NOT NULL,
      note TEXT,
      source TEXT NOT NULL,
      raw_notification_id INTEGER,
      needs_review INTEGER DEFAULT 0,
      transfer_pair_id INTEGER,
      FOREIGN KEY (wallet_id) REFERENCES $wallets (id),
      FOREIGN KEY (category_id) REFERENCES $categories (id),
      FOREIGN KEY (transfer_pair_id) REFERENCES $transactions (id),
      FOREIGN KEY (raw_notification_id) REFERENCES $rawNotifications (id)
    );
  ''';

  static const String createUserCategoryRules = '''
    CREATE TABLE $userCategoryRules (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      keyword TEXT NOT NULL UNIQUE,
      category_id INTEGER NOT NULL,
      FOREIGN KEY (category_id) REFERENCES $categories (id)
    );
  ''';

  static const String createBudgets = '''
    CREATE TABLE $budgets (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      category_id INTEGER,
      amount REAL NOT NULL,
      start_day INTEGER DEFAULT 1,
      FOREIGN KEY (category_id) REFERENCES $categories (id)
    );
  ''';

  static const String createRecurringRules = '''
    CREATE TABLE $recurringRules (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      title TEXT NOT NULL,
      amount REAL NOT NULL,
      category_id INTEGER NOT NULL,
      wallet_id INTEGER NOT NULL,
      due_day INTEGER NOT NULL,
      is_active INTEGER DEFAULT 1,
      FOREIGN KEY (category_id) REFERENCES $categories (id),
      FOREIGN KEY (wallet_id) REFERENCES $wallets (id)
    );
  ''';

  static const String createRecurringPayments = '''
    CREATE TABLE $recurringPayments (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      rule_id INTEGER NOT NULL,
      cycle_month TEXT NOT NULL,
      transaction_id INTEGER,
      is_paid INTEGER DEFAULT 0,
      paid_date INTEGER,
      FOREIGN KEY (rule_id) REFERENCES $recurringRules (id),
      FOREIGN KEY (transaction_id) REFERENCES $transactions (id)
    );
  ''';

  // ── Performance Indexes ──

  /// Tối ưu cho Dedup Layer 2 query
  static const String createIndexTransactionsDedup = '''
    CREATE INDEX idx_transactions_dedup ON $transactions(wallet_id, amount, transaction_date);
  ''';

  /// Tối ưu cho truy vấn giao dịch theo ví và thời gian
  static const String createIndexTransactionsWalletDate = '''
    CREATE INDEX idx_transactions_wallet_date ON $transactions(wallet_id, transaction_date);
  ''';

  /// Partial index: chỉ index các bản ghi chưa xử lý
  static const String createIndexRawNotificationsUnprocessed = '''
    CREATE INDEX idx_raw_notifications_unprocessed ON $rawNotifications(is_processed) WHERE is_processed = 0;
  ''';

  /// Tối ưu cho truy vấn recurring payments theo chu kỳ
  static const String createIndexRecurringPaymentsCycle = '''
    CREATE INDEX idx_recurring_payments_cycle ON $recurringPayments(rule_id, cycle_month);
  ''';

  /// Danh sách tất cả CREATE TABLE statements theo thứ tự dependency
  static const List<String> allCreateTableStatements = [
    createWallets,
    createCategories,
    createRawNotifications,
    createTransactions,
    createUserCategoryRules,
    createBudgets,
    createRecurringRules,
    createRecurringPayments,
  ];

  /// Danh sách tất cả CREATE INDEX statements
  static const List<String> allCreateIndexStatements = [
    createIndexTransactionsDedup,
    createIndexTransactionsWalletDate,
    createIndexRawNotificationsUnprocessed,
    createIndexRecurringPaymentsCycle,
  ];
}
