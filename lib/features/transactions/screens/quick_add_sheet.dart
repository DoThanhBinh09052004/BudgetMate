import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:bugdetmate/core/database/database_helper.dart';
import 'package:bugdetmate/core/theme/app_theme.dart';
import 'package:bugdetmate/core/theme/icon_resolver.dart';
import 'package:bugdetmate/core/widgets/app_widgets.dart';
import 'package:bugdetmate/features/transactions/services/transaction_service.dart';
import 'package:sqflite/sqflite.dart';

/// Bottom Sheet nhập thủ công 3 chạm với Numpad lớn, Cascade Chips 2 tầng và phím tắt tiền mặt phổ biến.
class QuickAddSheet extends StatefulWidget {
  final VoidCallback onSaved;
  final Database? db;
  final List<Map<String, dynamic>>? initialWallets;
  final List<Map<String, dynamic>>? initialCategories;
  final Future<void> Function(Map<String, dynamic> txData)? onSaveTransaction;

  const QuickAddSheet({
    super.key,
    required this.onSaved,
    this.db,
    this.initialWallets,
    this.initialCategories,
    this.onSaveTransaction,
  });

  @override
  State<QuickAddSheet> createState() => _QuickAddSheetState();
}

class _QuickAddSheetState extends State<QuickAddSheet> {
  String _amountString = '0';
  String _type = 'expense'; // 'expense' or 'income'
  int? _selectedWalletId;
  int? _selectedParentId;
  int? _selectedCategoryId;
  final TextEditingController _noteController = TextEditingController();

  List<Map<String, dynamic>> _wallets = [];
  List<Map<String, dynamic>> _parentCategories = [];
  List<Map<String, dynamic>> _childCategories = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    if (widget.initialWallets != null || widget.initialCategories != null) {
      _wallets = widget.initialWallets ?? [];
      final allCats = widget.initialCategories ?? [];
      _parentCategories = allCats
          .where((c) => c['parent_id'] == null && c['type'] == _type)
          .toList();
      final defaultParent = _parentCategories.isNotEmpty
          ? _parentCategories.first['id'] as int
          : null;
      _selectedParentId = defaultParent;
      _selectedCategoryId = defaultParent;
      _childCategories = defaultParent != null
          ? allCats.where((c) => c['parent_id'] == defaultParent).toList()
          : [];
      if (_wallets.isNotEmpty) {
        _selectedWalletId = _wallets.first['id'] as int;
      }
      _isLoading = false;
    } else {
      _loadMetadata();
    }
  }

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _loadMetadata() async {
    final db = widget.db ?? await DatabaseHelper.instance.database;
    final service = TransactionService(db: db);
    final wallets = await service.getWallets();
    final parents = await service.getCategories(type: _type, parentId: null);

    int? defaultParentId = parents.isNotEmpty
        ? parents.first['id'] as int
        : null;
    List<Map<String, dynamic>> children = [];
    if (defaultParentId != null) {
      children = await service.getCategories(parentId: defaultParentId);
    }

    if (mounted) {
      setState(() {
        _wallets = wallets;
        _parentCategories = parents;
        _childCategories = children;
        _selectedParentId = defaultParentId;
        _selectedCategoryId = defaultParentId;
        if (_wallets.isNotEmpty) {
          _selectedWalletId = _wallets.first['id'] as int;
        }
        _isLoading = false;
      });
    }
  }

  Future<void> _switchType(String newType) async {
    if (_type == newType) return;
    setState(() {
      _type = newType;
      _isLoading = true;
    });

    if (widget.initialCategories != null) {
      final allCats = widget.initialCategories!;
      final parents = allCats
          .where((c) => c['parent_id'] == null && c['type'] == _type)
          .toList();
      final defaultParentId = parents.isNotEmpty
          ? parents.first['id'] as int
          : null;
      final children = defaultParentId != null
          ? allCats.where((c) => c['parent_id'] == defaultParentId).toList()
          : <Map<String, dynamic>>[];
      setState(() {
        _parentCategories = parents;
        _childCategories = children;
        _selectedParentId = defaultParentId;
        _selectedCategoryId = defaultParentId;
        _isLoading = false;
      });
      return;
    }

    final db = widget.db ?? await DatabaseHelper.instance.database;
    final service = TransactionService(db: db);
    final parents = await service.getCategories(type: _type, parentId: null);

    int? defaultParentId = parents.isNotEmpty
        ? parents.first['id'] as int
        : null;
    List<Map<String, dynamic>> children = [];
    if (defaultParentId != null) {
      children = await service.getCategories(parentId: defaultParentId);
    }

    setState(() {
      _parentCategories = parents;
      _childCategories = children;
      _selectedParentId = defaultParentId;
      _selectedCategoryId = defaultParentId;
      _isLoading = false;
    });
  }

  Future<void> _selectParentCategory(int parentId) async {
    if (widget.initialCategories != null) {
      final children = widget.initialCategories!
          .where((c) => c['parent_id'] == parentId)
          .toList();
      setState(() {
        _selectedParentId = parentId;
        _childCategories = children;
        _selectedCategoryId = parentId;
      });
      return;
    }

    final db = widget.db ?? await DatabaseHelper.instance.database;
    final service = TransactionService(db: db);
    final children = await service.getCategories(parentId: parentId);

    setState(() {
      _selectedParentId = parentId;
      _childCategories = children;
      _selectedCategoryId = parentId;
    });
  }

  void _onKeyPress(String key) {
    setState(() {
      if (key == 'C') {
        _amountString = '0';
      } else if (key == '⌫') {
        if (_amountString.length > 1) {
          _amountString = _amountString.substring(0, _amountString.length - 1);
        } else {
          _amountString = '0';
        }
      } else if (key == '000') {
        if (_amountString != '0') {
          _amountString += '000';
        }
      } else {
        if (_amountString == '0') {
          _amountString = key;
        } else {
          if (_amountString.length < 12) {
            _amountString += key;
          }
        }
      }
    });
  }

  void _addQuickAmount(int amount) {
    final current = int.tryParse(_amountString) ?? 0;
    setState(() {
      _amountString = (current + amount).toString();
    });
  }

  Future<void> _saveTransaction() async {
    final amount = double.tryParse(_amountString) ?? 0.0;
    if (amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vui lòng nhập số tiền lớn hơn 0'),
          backgroundColor: AppTheme.expenseRed,
        ),
      );
      return;
    }

    if (_selectedWalletId == null) return;

    final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    final txData = {
      'wallet_id': _selectedWalletId,
      'category_id': _selectedCategoryId,
      'amount': amount,
      'type': _type,
      'transaction_date': now,
      'note': _noteController.text.trim().isEmpty
          ? null
          : _noteController.text.trim(),
      'source': 'manual',
      'needs_review': 0,
    };

    if (widget.onSaveTransaction != null) {
      await widget.onSaveTransaction!(txData);
    } else {
      final db = widget.db ?? await DatabaseHelper.instance.database;
      final service = TransactionService(db: db);
      await service.createTransaction(
        walletId: _selectedWalletId!,
        categoryId: _selectedCategoryId,
        amount: amount,
        type: _type,
        note: _noteController.text.trim().isEmpty
            ? null
            : _noteController.text.trim(),
        transactionDate: now,
        source: 'manual',
        needsReview: 0,
      );
    }

    widget.onSaved();
    if (mounted && Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final formatter = NumberFormat('#,###', 'vi_VN');
    final displayAmount = formatter.format(int.tryParse(_amountString) ?? 0);

    return Container(
      padding: EdgeInsets.only(
        top: 16,
        left: 16,
        right: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Drag handle
          Center(
            child: Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: AppTheme.darkBorder,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          // Header Type Segment
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildTypeButton('Chi tiêu', 'expense', AppTheme.expenseRed),
              const SizedBox(width: 8),
              _buildTypeButton('Thu nhập', 'income', AppTheme.primaryGreen),
            ],
          ),
          const SizedBox(height: 16),

          // Display Amount
          Center(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(
                  displayAmount,
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.w800,
                    color: _type == 'expense'
                        ? AppTheme.expenseRed
                        : AppTheme.primaryGreen,
                  ),
                ),
                const SizedBox(width: 6),
                const Text(
                  'VND',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textMutedDark,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Quick Amount Chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildQuickChip('50k', 50000),
                _buildQuickChip('100k', 100000),
                _buildQuickChip('200k', 200000),
                _buildQuickChip('500k', 500000),
                _buildQuickChip('1M', 1000000),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Cascade Category Selector (Tầng 1: Cha, Tầng 2: Con)
          if (_isLoading)
            const Center(child: CircularProgressIndicator())
          else ...[
            // Tầng 1: Cha
            SizedBox(
              height: 40,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: _parentCategories.length,
                separatorBuilder: (_, index) => const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  final cat = _parentCategories[index];
                  final isSelected = cat['id'] == _selectedParentId;
                  final icon = IconResolver.resolve(cat['icon'] as String?);
                  final color = IconResolver.resolveColor(
                    cat['color'] as String?,
                  );

                  return ChoiceChip(
                    avatar: Icon(
                      icon,
                      size: 16,
                      color: isSelected ? Colors.white : color,
                    ),
                    label: Text(cat['name'] as String),
                    selected: isSelected,
                    onSelected: (_) => _selectParentCategory(cat['id'] as int),
                    selectedColor: AppTheme.primaryGreen,
                    backgroundColor: AppTheme.darkSurfaceVariant,
                    labelStyle: TextStyle(
                      color: isSelected ? Colors.white : AppTheme.textMutedDark,
                      fontWeight: isSelected
                          ? FontWeight.w700
                          : FontWeight.w500,
                    ),
                  );
                },
              ),
            ),
            if (_childCategories.isNotEmpty) ...[
              const SizedBox(height: 8),
              // Tầng 2: Con
              SizedBox(
                height: 36,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: _childCategories.length,
                  separatorBuilder: (_, index) => const SizedBox(width: 6),
                  itemBuilder: (context, index) {
                    final child = _childCategories[index];
                    final isChildSelected = child['id'] == _selectedCategoryId;
                    final childIcon = IconResolver.resolve(
                      child['icon'] as String?,
                    );

                    return FilterChip(
                      avatar: Icon(
                        childIcon,
                        size: 14,
                        color: isChildSelected
                            ? Colors.white
                            : AppTheme.textMutedDark,
                      ),
                      label: Text(
                        child['name'] as String,
                        style: const TextStyle(fontSize: 12),
                      ),
                      selected: isChildSelected,
                      onSelected: (_) {
                        setState(() {
                          _selectedCategoryId = isChildSelected
                              ? _selectedParentId
                              : child['id'] as int;
                        });
                      },
                      selectedColor: AppTheme.primaryGreen,
                      backgroundColor: AppTheme.darkBackground,
                      labelStyle: TextStyle(
                        color: isChildSelected
                            ? Colors.white
                            : AppTheme.textMutedDark,
                        fontWeight: isChildSelected
                            ? FontWeight.w700
                            : FontWeight.w400,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                        side: BorderSide(
                          color: isChildSelected
                              ? AppTheme.primaryGreen
                              : AppTheme.darkBorder,
                          width: 1,
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ],
          const SizedBox(height: 12),

          // Note input
          TextField(
            controller: _noteController,
            decoration: InputDecoration(
              hintText: 'Ghi chú (Highlands, Ăn trưa...)',
              hintStyle: const TextStyle(
                color: AppTheme.textMutedDark,
                fontSize: 13,
              ),
              filled: true,
              fillColor: AppTheme.darkSurfaceVariant,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 10,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppTheme.darkBorder),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppTheme.darkBorder),
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Numpad Grid
          _buildNumpad(),
          const SizedBox(height: 12),

          // Submit CTA
          AppPrimaryButton(
            label: 'Lưu Giao Dịch',
            backgroundColor: _type == 'expense'
                ? const Color(0xFF3B82F6)
                : AppTheme.primaryGreen,
            onPressed: _saveTransaction,
          ),
        ],
      ),
    );
  }

  Widget _buildTypeButton(String title, String type, Color activeColor) {
    final isSelected = _type == type;
    return Expanded(
      child: GestureDetector(
        onTap: () => _switchType(type),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? activeColor.withAlpha(40) : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? activeColor : AppTheme.darkBorder,
              width: 1.5,
            ),
          ),
          child: Center(
            child: Text(
              title,
              style: TextStyle(
                color: isSelected ? activeColor : AppTheme.textMutedDark,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                fontSize: 14,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildQuickChip(String label, int amount) {
    return Container(
      margin: const EdgeInsets.only(right: 8),
      child: OutlinedButton(
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          side: const BorderSide(color: AppTheme.darkBorder),
          backgroundColor: AppTheme.darkSurfaceVariant,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        onPressed: () => _addQuickAmount(amount),
        child: Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _buildNumpad() {
    final keys = [
      ['1', '2', '3'],
      ['4', '5', '6'],
      ['7', '8', '9'],
      ['C', '0', '⌫'],
    ];

    return Column(
      children: keys.map((row) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Row(
            children: row.map((key) {
              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.darkSurfaceVariant,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      elevation: 0,
                    ),
                    onPressed: () => _onKeyPress(key),
                    child: Text(
                      key,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        );
      }).toList(),
    );
  }
}
