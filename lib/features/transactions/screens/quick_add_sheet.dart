import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:bugdetmate/core/database/database_helper.dart';
import 'package:bugdetmate/core/database/tables.dart';
import 'package:bugdetmate/core/theme/app_theme.dart';

import 'package:sqflite/sqflite.dart';

/// Bottom Sheet nhập thủ công 3 chạm với Numpad lớn và phím tắt tiền mặt phổ biến.
class QuickAddSheet extends StatefulWidget {
  final VoidCallback onSaved;
  final Database? db;

  const QuickAddSheet({super.key, required this.onSaved, this.db});

  @override
  State<QuickAddSheet> createState() => _QuickAddSheetState();
}

class _QuickAddSheetState extends State<QuickAddSheet> {
  String _amountString = '0';
  String _type = 'expense'; // 'expense' or 'income'
  int? _selectedWalletId;
  int? _selectedCategoryId;
  final TextEditingController _noteController = TextEditingController();

  List<Map<String, dynamic>> _wallets = [];
  List<Map<String, dynamic>> _categories = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadMetadata();
  }

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _loadMetadata() async {
    final db = widget.db ?? await DatabaseHelper.instance.database;
    final wallets = await db.query(AppTables.wallets);
    final categories = await db.query(
      AppTables.categories,
      where: 'type = ?',
      whereArgs: [_type],
    );

    setState(() {
      _wallets = wallets;
      _categories = categories;
      if (_wallets.isNotEmpty) {
        _selectedWalletId = _wallets.first['id'] as int;
      }
      if (_categories.isNotEmpty) {
        _selectedCategoryId = _categories.first['id'] as int;
      }
      _isLoading = false;
    });
  }

  Future<void> _switchType(String newType) async {
    if (_type == newType) return;
    setState(() {
      _type = newType;
      _isLoading = true;
    });

    final db = widget.db ?? await DatabaseHelper.instance.database;
    final categories = await db.query(
      AppTables.categories,
      where: 'type = ?',
      whereArgs: [_type],
    );

    setState(() {
      _categories = categories;
      _selectedCategoryId = _categories.isNotEmpty ? _categories.first['id'] as int : null;
      _isLoading = false;
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
          backgroundColor: AppTheme.dangerRed,
        ),
      );
      return;
    }

    if (_selectedWalletId == null) return;

    final db = widget.db ?? await DatabaseHelper.instance.database;
    final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;

    await db.insert(AppTables.transactions, {
      'wallet_id': _selectedWalletId,
      'category_id': _selectedCategoryId,
      'amount': amount,
      'type': _type,
      'transaction_date': now,
      'note': _noteController.text.trim().isEmpty ? null : _noteController.text.trim(),
      'source': 'manual',
      'needs_review': 0,
    });

    // Update wallet balance
    final balanceChange = _type == 'expense' ? -amount : amount;
    await db.rawUpdate('''
      UPDATE ${AppTables.wallets}
      SET balance = balance + ?
      WHERE id = ?
    ''', [balanceChange, _selectedWalletId]);

    widget.onSaved();
    if (mounted) {
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
              _buildTypeButton('Chi tiêu', 'expense', AppTheme.dangerRed),
              const SizedBox(width: 8),
              _buildTypeButton('Thu nhập', 'income', AppTheme.successGreen),
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
                  _type == 'expense' ? '-$displayAmount' : '+$displayAmount',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.w800,
                    color: _type == 'expense' ? AppTheme.dangerRed : AppTheme.successGreen,
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
                _buildQuickChip('+50k', 50000),
                _buildQuickChip('+100k', 100000),
                _buildQuickChip('+200k', 200000),
                _buildQuickChip('+500k', 500000),
                _buildQuickChip('+1M', 1000000),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Category Selector
          if (_isLoading)
            const Center(child: CircularProgressIndicator())
          else ...[
            SizedBox(
              height: 40,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: _categories.length,
                separatorBuilder: (_, index) => const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  final cat = _categories[index];
                  final isSelected = cat['id'] == _selectedCategoryId;
                  return ChoiceChip(
                    label: Text(cat['name'] as String),
                    selected: isSelected,
                    onSelected: (_) {
                      setState(() => _selectedCategoryId = cat['id'] as int);
                    },
                    selectedColor: AppTheme.primaryBlue,
                    labelStyle: TextStyle(
                      color: isSelected ? Colors.white : AppTheme.textMutedDark,
                      fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                    ),
                  );
                },
              ),
            ),
          ],
          const SizedBox(height: 12),

          // Note input
          TextField(
            controller: _noteController,
            decoration: InputDecoration(
              hintText: 'Ghi chú (Highlands, Ăn trưa...)',
              hintStyle: const TextStyle(color: AppTheme.textMutedDark, fontSize: 13),
              filled: true,
              fillColor: AppTheme.darkSurfaceVariant,
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
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

          // Save Button
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: _type == 'expense' ? AppTheme.primaryBlue : AppTheme.successGreen,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
            onPressed: _saveTransaction,
            child: const Text(
              'Lưu Giao Dịch',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTypeButton(String label, String typeValue, Color activeColor) {
    final isSelected = _type == typeValue;
    return InkWell(
      onTap: () => _switchType(typeValue),
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? activeColor.withAlpha(40) : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? activeColor : AppTheme.darkBorder,
            width: 1.5,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? activeColor : AppTheme.textMutedDark,
            fontWeight: FontWeight.w700,
            fontSize: 14,
          ),
        ),
      ),
    );
  }

  Widget _buildQuickChip(String label, int amount) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ActionChip(
        label: Text(label),
        onPressed: () => _addQuickAmount(amount),
        backgroundColor: AppTheme.darkSurfaceVariant,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        side: const BorderSide(color: AppTheme.darkBorder),
      ),
    );
  }

  Widget _buildNumpad() {
    final rows = [
      ['1', '2', '3'],
      ['4', '5', '6'],
      ['7', '8', '9'],
      ['C', '0', '⌫'],
    ];

    return Column(
      children: rows.map((row) {
        return Row(
          children: row.map((key) {
            return Expanded(
              child: Padding(
                padding: const EdgeInsets.all(4),
                child: Material(
                  color: AppTheme.darkSurfaceVariant,
                  borderRadius: BorderRadius.circular(12),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: () => _onKeyPress(key),
                    child: Container(
                      height: 48,
                      alignment: Alignment.center,
                      child: Text(
                        key,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        );
      }).toList(),
    );
  }
}
