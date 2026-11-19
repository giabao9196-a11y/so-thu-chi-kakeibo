import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../models/models.dart';
import '../services/database_helper.dart';
import '../utils/currency_formatter.dart';

class InputScreen extends StatefulWidget {
  final VoidCallback onTransactionSaved;

  const InputScreen({super.key, required this.onTransactionSaved});

  @override
  State<InputScreen> createState() => _InputScreenState();
}

class _InputScreenState extends State<InputScreen> {
  TransactionType _selectedType = TransactionType.expense;
  DateTime _selectedDate = DateTime.now();
  String _amountText = '0';
  final TextEditingController _noteController = TextEditingController();

  List<CategoryModel> _categories = [];
  CategoryModel? _selectedCategory;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _loadCategories() async {
    setState(() => _isLoading = true);
    final cats = await DatabaseHelper.instance.getCategories(type: _selectedType);
    if (!mounted) return;
    setState(() {
      _categories = cats;
      _selectedCategory = cats.isNotEmpty ? cats.first : null;
      _isLoading = false;
    });
  }

  void _onTypeChanged(TransactionType type) {
    if (_selectedType == type) return;
    setState(() => _selectedType = type);
    _loadCategories();
  }

  void _changeDate(int days) {
    setState(() {
      _selectedDate = _selectedDate.add(Duration(days: days));
    });
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  void _onKeyTap(String key) {
    HapticFeedback.lightImpact();
    setState(() {
      if (key == 'AC') {
        _amountText = '0';
      } else if (key == 'DEL') {
        if (_amountText.length > 1) {
          _amountText = _amountText.substring(0, _amountText.length - 1);
        } else {
          _amountText = '0';
        }
      } else if (key == '000') {
        if (_amountText != '0' && _amountText.length <= 9) {
          _amountText += '000';
        }
      } else if (key == '00') {
        if (_amountText != '0' && _amountText.length <= 10) {
          _amountText += '00';
        }
      } else {
        if (_amountText == '0') {
          _amountText = key;
        } else if (_amountText.length < 12) {
          _amountText += key;
        }
      }
    });
  }

  Future<void> _saveTransaction() async {
    final amount = double.tryParse(_amountText) ?? 0;
    if (amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vui lòng nhập số tiền lớn hơn 0 ₫'),
          behavior: SnackBarBehavior.floating,
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    if (_selectedCategory == null) return;

    final tx = TransactionModel(
      amount: amount,
      note: _noteController.text.trim(),
      date: _selectedDate,
      categoryId: _selectedCategory!.id!,
      type: _selectedType,
    );

    await DatabaseHelper.instance.insertTransaction(tx);
    HapticFeedback.mediumImpact();

    if (!mounted) return;
    setState(() {
      _amountText = '0';
      _noteController.clear();
    });

    widget.onTransactionSaved();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Đã lưu ${_selectedType == TransactionType.expense ? "Khoản chi" : "Khoản thu"}: ${CurrencyFormatter.format(amount)} (${_selectedCategory!.name})',
        ),
        backgroundColor: Colors.teal.shade700,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(milliseconds: 1500),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isExpense = _selectedType == TransactionType.expense;
    final primaryColor = isExpense ? const Color(0xFFE65100) : const Color(0xFF2E7D32);
    final amountValue = double.tryParse(_amountText) ?? 0;

    return Scaffold(
      appBar: AppBar(
        title: _buildTypeToggle(primaryColor),
        centerTitle: true,
        elevation: 0,
      ),
      body: Column(
        children: [
          // 1. Date & Amount & Note Card
          Container(
            margin: const EdgeInsets.fromLTRB(12, 4, 12, 8),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: theme.cardColor,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              children: [
                // Date Row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.chevron_left),
                      onPressed: () => _changeDate(-1),
                      visualDensity: VisualDensity.compact,
                    ),
                    InkWell(
                      onTap: _pickDate,
                      borderRadius: BorderRadius.circular(8),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        child: Row(
                          children: [
                            Icon(Icons.calendar_today, size: 16, color: primaryColor),
                            const SizedBox(width: 8),
                            Text(
                              DateFormat('dd/MM/yyyy (EEEE)', 'vi').format(_selectedDate),
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 15,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.chevron_right),
                      onPressed: () => _changeDate(1),
                      visualDensity: VisualDensity.compact,
                    ),
                  ],
                ),
                const Divider(height: 12),
                // Amount Display
                Row(
                  children: [
                    Text(
                      isExpense ? 'Số tiền chi' : 'Số tiền thu',
                      style: TextStyle(
                        color: theme.textTheme.bodySmall?.color,
                        fontSize: 14,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      CurrencyFormatter.format(amountValue),
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        color: primaryColor,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                // Note Input
                TextField(
                  controller: _noteController,
                  decoration: InputDecoration(
                    hintText: 'Ghi chú (VD: Ăn trưa, Đổ xăng, Tiền điện...)',
                    hintStyle: const TextStyle(fontSize: 13.5),
                    prefixIcon: const Icon(Icons.edit_note, size: 20),
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                    filled: true,
                    fillColor: theme.scaffoldBackgroundColor,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // 2. Category Grid
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: GridView.builder(
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 3,
                        childAspectRatio: 1.45,
                        crossAxisSpacing: 8,
                        mainAxisSpacing: 8,
                      ),
                      itemCount: _categories.length,
                      itemBuilder: (context, index) {
                        final cat = _categories[index];
                        final isSelected = _selectedCategory?.id == cat.id;
                        return InkWell(
                          onTap: () {
                            HapticFeedback.selectionClick();
                            setState(() => _selectedCategory = cat);
                          },
                          borderRadius: BorderRadius.circular(12),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 150),
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? cat.color.withOpacity(0.14)
                                  : theme.cardColor,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: isSelected ? cat.color : Colors.grey.withOpacity(0.2),
                                width: isSelected ? 2 : 1,
                              ),
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(cat.icon, color: cat.color, size: 24),
                                const SizedBox(height: 4),
                                Text(
                                  cat.name,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight:
                                        isSelected ? FontWeight.bold : FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
          ),

          // 3. Built-in Kakeibo Calculator Keypad
          _buildCalculatorKeypad(primaryColor),
        ],
      ),
    );
  }

  Widget _buildTypeToggle(Color activeColor) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey.withOpacity(0.15),
        borderRadius: BorderRadius.circular(24),
      ),
      padding: const EdgeInsets.all(3),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildToggleButton('Tiền chi', TransactionType.expense, const Color(0xFFE65100)),
          _buildToggleButton('Tiền thu', TransactionType.income, const Color(0xFF2E7D32)),
        ],
      ),
    );
  }

  Widget _buildToggleButton(String label, TransactionType type, Color color) {
    final isSelected = _selectedType == type;
    return GestureDetector(
      onTap: () => _onTypeChanged(type),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected ? color : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: isSelected ? Colors.white : Colors.grey.shade700,
          ),
        ),
      ),
    );
  }

  Widget _buildCalculatorKeypad(Color primaryColor) {
    final keys = [
      ['7', '8', '9', 'DEL'],
      ['4', '5', '6', 'AC'],
      ['1', '2', '3', '000'],
      ['0', '00', 'SAVE'],
    ];

    return Container(
      padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Column(
        children: keys.map((row) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 3),
            child: Row(
              children: row.map((key) {
                final isSave = key == 'SAVE';
                final isAction = key == 'DEL' || key == 'AC';
                return Expanded(
                  flex: isSave ? 2 : 1,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 3),
                    child: SizedBox(
                      height: 46,
                      child: ElevatedButton(
                        onPressed: isSave ? _saveTransaction : () => _onKeyTap(key),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: isSave
                              ? primaryColor
                              : isAction
                                  ? Colors.grey.withOpacity(0.18)
                                  : Theme.of(context).scaffoldBackgroundColor,
                          foregroundColor: isSave
                              ? Colors.white
                              : Theme.of(context).textTheme.bodyLarge?.color,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: isSave
                            ? const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.check_circle_outline, size: 18),
                                  SizedBox(width: 6),
                                  Text(
                                    'LƯU KHOẢN NÀY',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13.5,
                                    ),
                                  ),
                                ],
                              )
                            : key == 'DEL'
                                ? const Icon(Icons.backspace_outlined, size: 19)
                                : Text(
                                    key,
                                    style: const TextStyle(
                                      fontSize: 17,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          );
        }).toList(),
      ),
    );
  }
}
