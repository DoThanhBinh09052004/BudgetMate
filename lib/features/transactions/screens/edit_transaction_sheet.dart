import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:bugdetmate/core/database/database_helper.dart';
import 'package:bugdetmate/core/database/tables.dart';
import 'package:bugdetmate/core/theme/app_theme.dart';
import 'package:bugdetmate/core/theme/icon_resolver.dart';
import 'package:sqflite/sqflite.dart';

/// Modal BottomSheet chỉnh sửa toàn diện giao dịch:
/// Cho phép sửa Danh mục/Danh mục con, Đổi số tiền, Sửa ghi chú, Đổi ngày giờ và Xóa giao dịch.
/// Tự động cập nhật / hoàn tác số dư ví chính xác 100%.
class EditTransactionSheet extends StatefulWidget {
  final Map<String, dynamic> transaction;
  final VoidCallback onSaved;
  final Database? db;

  const EditTransactionSheet({
    super.key,
    required this.transaction,
    required this.onSaved,
    this.db,
  });

  /// Logic nghiệp vụ: Cập nhật giao dịch và cân bằng lại số dư ví trong transaction atomic
  static Future<void> executeEditTransaction({
    required Database db,
    required int txId,
    required int oldWalletId,
    required int newWalletId,
    required String oldType,
    required String newType,
    required double oldAmount,
    required double newAmount,
    required int? categoryId,
    required String? note,
    required int transactionDate,
  }) async {
    await db.transaction((txn) async {
      // 1. Hoàn tác tác động số dư cũ ở ví cũ
      final oldImpact = oldType == 'expense' ? -oldAmount : oldAmount;
      await txn.rawUpdate(
        'UPDATE ${AppTables.wallets} SET balance = balance - ? WHERE id = ?',
        [oldImpact, oldWalletId],
      );

      // 2. Áp dụng tác động số dư mới ở ví mới
      final newImpact = newType == 'expense' ? -newAmount : newAmount;
      await txn.rawUpdate(
        'UPDATE ${AppTables.wallets} SET balance = balance + ? WHERE id = ?',
        [newImpact, newWalletId],
      );

      // 3. Cập nhật bản ghi giao dịch
      await txn.update(
        AppTables.transactions,
        {
          'wallet_id': newWalletId,
          'category_id': categoryId,
          'amount': newAmount,
          'type': newType,
          'note': note,
          'transaction_date': transactionDate,
        },
        where: 'id = ?',
        whereArgs: [txId],
      );
    });
  }

  /// Logic nghiệp vụ: Xóa giao dịch và hoàn trả số dư ví về trạng thái ban đầu
  static Future<void> executeDeleteTransaction({
    required Database db,
    required int txId,
    required int walletId,
    required String type,
    required double amount,
  }) async {
    await db.transaction((txn) async {
      // Hoàn tác số tiền lại cho ví (nếu là chi tiêu thì cộng lại ví, nếu là thu nhập thì trừ lại)
      final impact = type == 'expense' ? -amount : amount;
      await txn.rawUpdate(
        'UPDATE ${AppTables.wallets} SET balance = balance - ? WHERE id = ?',
        [impact, walletId],
      );

      // Xóa giao dịch
      await txn.delete(
        AppTables.transactions,
        where: 'id = ?',
        whereArgs: [txId],
      );
    });
  }

  @override
  State<EditTransactionSheet> createState() => _EditTransactionSheetState();
}

class _EditTransactionSheetState extends State<EditTransactionSheet> {
  late String _type;
  late TextEditingController _amountController;
  late TextEditingController _noteController;
  late DateTime _selectedDate;
  int? _selectedWalletId;
  int? _selectedParentId;
  int? _selectedCategoryId;

  List<Map<String, dynamic>> _wallets = [];
  List<Map<String, dynamic>> _parentCategories = [];
  List<Map<String, dynamic>> _childCategories = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    final tx = widget.transaction;
    _type = tx['type'] as String? ?? 'expense';
    final amount = (tx['amount'] as num?)?.toDouble() ?? 0.0;
    _amountController = TextEditingController(text: amount.toInt().toString());
    _noteController = TextEditingController(text: tx['note'] as String? ?? '');
    final dateSec = tx['transaction_date'] as int? ?? DateTime.now().millisecondsSinceEpoch ~/ 1000;
    _selectedDate = DateTime.fromMillisecondsSinceEpoch(dateSec * 1000);
    _selectedWalletId = tx['wallet_id'] as int?;
    _selectedCategoryId = tx['category_id'] as int?;

    _loadMetadata();
  }

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _loadMetadata() async {
    final db = widget.db ?? await DatabaseHelper.instance.database;
    final wallets = await db.query(AppTables.wallets);
    final parents = await db.query(
      AppTables.categories,
      where: 'type = ? AND parent_id IS NULL',
      whereArgs: [_type],
    );

    // Xác định parent_id của category hiện tại nếu category_id là con
    int? parentId;
    if (_selectedCategoryId != null) {
      final currentCat = await db.query(
        AppTables.categories,
        where: 'id = ?',
        whereArgs: [_selectedCategoryId],
      );
      if (currentCat.isNotEmpty) {
        final cat = currentCat.first;
        if (cat['parent_id'] != null) {
          parentId = cat['parent_id'] as int;
        } else {
          parentId = cat['id'] as int;
        }
      }
    }

    parentId ??= parents.isNotEmpty ? parents.first['id'] as int : null;

    List<Map<String, dynamic>> children = [];
    if (parentId != null) {
      children = await db.query(
        AppTables.categories,
        where: 'parent_id = ?',
        whereArgs: [parentId],
      );
    }

    if (mounted) {
      setState(() {
        _wallets = wallets;
        _parentCategories = parents;
        _childCategories = children;
        _selectedParentId = parentId;
        _selectedWalletId ??= wallets.isNotEmpty ? wallets.first['id'] as int : null;
        _isLoading = false;
      });
    }
  }

  Future<void> _selectParentCategory(int parentId) async {
    final db = widget.db ?? await DatabaseHelper.instance.database;
    final children = await db.query(
      AppTables.categories,
      where: 'parent_id = ?',
      whereArgs: [parentId],
    );

    setState(() {
      _selectedParentId = parentId;
      _childCategories = children;
      _selectedCategoryId = parentId;
    });
  }

  Future<void> _pickDateTime() async {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      builder: (context, child) {
        return Theme(
          data: AppTheme.darkTheme.copyWith(
            colorScheme: const ColorScheme.dark(
              primary: AppTheme.primaryGreen,
              surface: AppTheme.darkSurface,
            ),
          ),
          child: child!,
        );
      },
    );

    if (pickedDate == null) return;

    if (!mounted) return;
    final pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_selectedDate),
    );

    if (pickedTime == null) return;

    setState(() {
      _selectedDate = DateTime(
        pickedDate.year,
        pickedDate.month,
        pickedDate.day,
        pickedTime.hour,
        pickedTime.minute,
      );
    });
  }

  Future<void> _saveChanges() async {
    final newAmount = double.tryParse(_amountController.text.trim()) ?? 0.0;
    if (newAmount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vui lòng nhập số tiền hợp lệ (> 0)'),
          backgroundColor: AppTheme.expenseRed,
        ),
      );
      return;
    }

    if (_selectedWalletId == null) return;

    final db = widget.db ?? await DatabaseHelper.instance.database;
    final tx = widget.transaction;

    await EditTransactionSheet.executeEditTransaction(
      db: db,
      txId: tx['id'] as int,
      oldWalletId: tx['wallet_id'] as int,
      newWalletId: _selectedWalletId!,
      oldType: tx['type'] as String,
      newType: _type,
      oldAmount: (tx['amount'] as num).toDouble(),
      newAmount: newAmount,
      categoryId: _selectedCategoryId,
      note: _noteController.text.trim().isEmpty ? null : _noteController.text.trim(),
      transactionDate: _selectedDate.millisecondsSinceEpoch ~/ 1000,
    );

    widget.onSaved();
    if (mounted && Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    }
  }

  Future<void> _confirmDelete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.darkSurface,
        title: const Text('Xóa giao dịch này?'),
        content: const Text(
          'Giao dịch sẽ bị xóa vĩnh viễn và số dư ví liên quan sẽ được tự động hoàn trả lại số tiền này.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Hủy', style: TextStyle(color: AppTheme.textMutedDark)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.expenseRed,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Xóa Ngay'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    final db = widget.db ?? await DatabaseHelper.instance.database;
    final tx = widget.transaction;

    await EditTransactionSheet.executeDeleteTransaction(
      db: db,
      txId: tx['id'] as int,
      walletId: tx['wallet_id'] as int,
      type: tx['type'] as String,
      amount: (tx['amount'] as num).toDouble(),
    );

    widget.onSaved();
    if (mounted && Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final dateStr = DateFormat('dd/MM/yyyy HH:mm').format(_selectedDate);

    return Container(
      padding: EdgeInsets.only(
        top: 16,
        left: 16,
        right: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
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

          // Header Title
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Sửa Giao Dịch',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
              ),
              IconButton(
                icon: const Icon(Icons.close, color: AppTheme.textMutedDark),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Type Selector
          Row(
            children: [
              _buildTypeChoice('Chi tiêu', 'expense', AppTheme.expenseRed),
              const SizedBox(width: 8),
              _buildTypeChoice('Thu nhập', 'income', AppTheme.primaryGreen),
            ],
          ),
          const SizedBox(height: 14),

          // Amount input
          TextField(
            controller: _amountController,
            keyboardType: TextInputType.number,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: _type == 'expense' ? AppTheme.expenseRed : AppTheme.primaryGreen,
            ),
            decoration: InputDecoration(
              labelText: 'Số tiền (VND)',
              labelStyle: const TextStyle(color: AppTheme.textMutedDark),
              filled: true,
              fillColor: AppTheme.darkSurfaceVariant,
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

          // Cascade Category Selector
          if (_isLoading)
            const Center(child: CircularProgressIndicator())
          else ...[
            const Text(
              'Danh mục',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppTheme.textMutedDark),
            ),
            const SizedBox(height: 6),
            SizedBox(
              height: 38,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: _parentCategories.length,
                separatorBuilder: (_, index) => const SizedBox(width: 6),
                itemBuilder: (context, index) {
                  final cat = _parentCategories[index];
                  final isSelected = cat['id'] == _selectedParentId;
                  final icon = IconResolver.resolve(cat['icon'] as String?);
                  final color = IconResolver.resolveColor(cat['color'] as String?);

                  return ChoiceChip(
                    avatar: Icon(icon, size: 15, color: isSelected ? Colors.white : color),
                    label: Text(cat['name'] as String),
                    selected: isSelected,
                    onSelected: (_) => _selectParentCategory(cat['id'] as int),
                    selectedColor: AppTheme.primaryGreen,
                    backgroundColor: AppTheme.darkSurfaceVariant,
                    labelStyle: TextStyle(
                      color: isSelected ? Colors.white : AppTheme.textMutedDark,
                      fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                      fontSize: 12,
                    ),
                  );
                },
              ),
            ),
            if (_childCategories.isNotEmpty) ...[
              const SizedBox(height: 6),
              SizedBox(
                height: 34,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: _childCategories.length,
                  separatorBuilder: (_, index) => const SizedBox(width: 6),
                  itemBuilder: (context, index) {
                    final child = _childCategories[index];
                    final isChildSelected = child['id'] == _selectedCategoryId;
                    final childIcon = IconResolver.resolve(child['icon'] as String?);

                    return FilterChip(
                      avatar: Icon(childIcon, size: 13, color: isChildSelected ? Colors.white : AppTheme.textMutedDark),
                      label: Text(child['name'] as String, style: const TextStyle(fontSize: 11)),
                      selected: isChildSelected,
                      onSelected: (_) {
                        setState(() {
                          _selectedCategoryId = isChildSelected ? _selectedParentId : child['id'] as int;
                        });
                      },
                      selectedColor: AppTheme.primaryGreen,
                      backgroundColor: AppTheme.darkBackground,
                      labelStyle: TextStyle(
                        color: isChildSelected ? Colors.white : AppTheme.textMutedDark,
                        fontWeight: isChildSelected ? FontWeight.w700 : FontWeight.w400,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                        side: BorderSide(
                          color: isChildSelected ? AppTheme.primaryGreen : AppTheme.darkBorder,
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ],
          const SizedBox(height: 12),

          // Date & Time Row
          InkWell(
            onTap: _pickDateTime,
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: AppTheme.darkSurfaceVariant,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTheme.darkBorder),
              ),
              child: Row(
                children: [
                  const Icon(Icons.calendar_today_rounded, size: 18, color: AppTheme.primaryGreen),
                  const SizedBox(width: 10),
                  Text('Thời gian: $dateStr', style: const TextStyle(fontSize: 13)),
                  const Spacer(),
                  const Icon(Icons.arrow_forward_ios_rounded, size: 13, color: AppTheme.textMutedDark),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Note Input
          TextField(
            controller: _noteController,
            decoration: InputDecoration(
              labelText: 'Ghi chú',
              labelStyle: const TextStyle(color: AppTheme.textMutedDark, fontSize: 13),
              filled: true,
              fillColor: AppTheme.darkSurfaceVariant,
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
          const SizedBox(height: 16),

          // Action Buttons: Save & Delete
          Row(
            children: [
              Expanded(
                flex: 1,
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppTheme.expenseRed,
                    side: const BorderSide(color: AppTheme.expenseRed),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  icon: const Icon(Icons.delete_outline_rounded, size: 20),
                  label: const Text('Xóa'),
                  onPressed: _confirmDelete,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryGreen,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  icon: const Icon(Icons.check_circle_outline_rounded, size: 20),
                  label: const Text('Lưu Thay Đổi', style: TextStyle(fontWeight: FontWeight.w700)),
                  onPressed: _saveChanges,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTypeChoice(String title, String type, Color activeColor) {
    final isSelected = _type == type;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          if (_type == type) return;
          setState(() {
            _type = type;
            _isLoading = true;
          });
          _loadMetadata();
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? activeColor.withAlpha(35) : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: isSelected ? activeColor : AppTheme.darkBorder),
          ),
          child: Center(
            child: Text(
              title,
              style: TextStyle(
                color: isSelected ? activeColor : AppTheme.textMutedDark,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
