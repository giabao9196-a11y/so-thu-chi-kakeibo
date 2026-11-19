import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/models.dart';
import '../services/database_helper.dart';
import '../utils/currency_formatter.dart';

class CalendarScreen extends StatefulWidget {
  final int refreshTrigger;

  const CalendarScreen({super.key, required this.refreshTrigger});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  DateTime _currentMonth = DateTime(DateTime.now().year, DateTime.now().month, 1);
  DateTime? _selectedDay;
  List<TransactionModel> _transactions = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadMonthTransactions();
  }

  @override
  void didUpdateWidget(covariant CalendarScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.refreshTrigger != widget.refreshTrigger) {
      _loadMonthTransactions();
    }
  }

  Future<void> _loadMonthTransactions() async {
    setState(() => _isLoading = true);
    final txs = await DatabaseHelper.instance.getTransactionsByMonth(
      _currentMonth.year,
      _currentMonth.month,
    );
    if (!mounted) return;
    setState(() {
      _transactions = txs;
      _isLoading = false;
    });
  }

  void _changeMonth(int delta) {
    setState(() {
      _currentMonth = DateTime(_currentMonth.year, _currentMonth.month + delta, 1);
      _selectedDay = null;
    });
    _loadMonthTransactions();
  }

  Future<void> _deleteTransaction(TransactionModel tx) async {
    if (tx.id == null) return;
    await DatabaseHelper.instance.deleteTransaction(tx.id!);
    _loadMonthTransactions();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    double totalIncome = 0;
    double totalExpense = 0;
    final Map<int, double> dailyIncome = {};
    final Map<int, double> dailyExpense = {};

    for (final tx in _transactions) {
      final day = tx.date.day;
      if (tx.type == TransactionType.income) {
        totalIncome += tx.amount;
        dailyIncome[day] = (dailyIncome[day] ?? 0) + tx.amount;
      } else {
        totalExpense += tx.amount;
        dailyExpense[day] = (dailyExpense[day] ?? 0) + tx.amount;
      }
    }

    final balance = totalIncome - totalExpense;
    final filteredList = _selectedDay == null
        ? _transactions
        : _transactions.where((t) => t.date.day == _selectedDay!.day).toList();

    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.chevron_left),
              onPressed: () => _changeMonth(-1),
            ),
            Text(
              'Tháng ${_currentMonth.month}/${_currentMonth.year}',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
            ),
            IconButton(
              icon: const Icon(Icons.chevron_right),
              onPressed: () => _changeMonth(1),
            ),
          ],
        ),
        centerTitle: true,
        actions: [
          if (_selectedDay != null)
            TextButton(
              onPressed: () => setState(() => _selectedDay = null),
              child: const Text('Xem cả tháng'),
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // 1. Summary Bar (Income | Expense | Balance)
                Container(
                  margin: const EdgeInsets.fromLTRB(12, 4, 12, 8),
                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                  decoration: BoxDecoration(
                    color: theme.cardColor,
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.04),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      _buildSummaryColumn(
                        'Thu nhập',
                        totalIncome,
                        const Color(0xFF2E7D32),
                      ),
                      Container(width: 1, height: 32, color: Colors.grey.withOpacity(0.2)),
                      _buildSummaryColumn(
                        'Chi tiêu',
                        totalExpense,
                        const Color(0xFFE65100),
                      ),
                      Container(width: 1, height: 32, color: Colors.grey.withOpacity(0.2)),
                      _buildSummaryColumn(
                        'Số dư',
                        balance,
                        balance >= 0 ? Colors.blue.shade700 : Colors.red.shade700,
                      ),
                    ],
                  ),
                ),

                // 2. Calendar Month Grid
                _buildCalendarGrid(dailyIncome, dailyExpense),

                const Divider(height: 1),

                // 3. Transaction List
                Expanded(
                  child: filteredList.isEmpty
                      ? Center(
                          child: Text(
                            _selectedDay == null
                                ? 'Chưa có giao dịch nào trong tháng này'
                                : 'Không có giao dịch ngày ${_selectedDay!.day}/${_currentMonth.month}',
                            style: TextStyle(color: Colors.grey.shade500),
                          ),
                        )
                      : ListView.separated(
                          padding: const EdgeInsets.all(12),
                          itemCount: filteredList.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 8),
                          itemBuilder: (context, index) {
                            final tx = filteredList[index];
                            final isExpense = tx.type == TransactionType.expense;
                            return Dismissible(
                              key: ValueKey(tx.id ?? index),
                              direction: DismissDirection.endToStart,
                              background: Container(
                                alignment: Alignment.centerRight,
                                padding: const EdgeInsets.symmetric(horizontal: 20),
                                decoration: BoxDecoration(
                                  color: Colors.red.shade600,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Icon(Icons.delete_outline, color: Colors.white),
                              ),
                              onDismissed: (_) => _deleteTransaction(tx),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 10,
                                ),
                                decoration: BoxDecoration(
                                  color: theme.cardColor,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Row(
                                  children: [
                                    CircleAvatar(
                                      backgroundColor: tx.categoryColor.withOpacity(0.15),
                                      child: Icon(
                                        tx.categoryIcon,
                                        color: tx.categoryColor,
                                        size: 20,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            tx.categoryName ?? 'Danh mục',
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 14.5,
                                            ),
                                          ),
                                          if (tx.note.isNotEmpty)
                                            Text(
                                              tx.note,
                                              style: TextStyle(
                                                fontSize: 12.5,
                                                color: Colors.grey.shade600,
                                              ),
                                            ),
                                          Text(
                                            DateFormat('dd/MM/yyyy').format(tx.date),
                                            style: TextStyle(
                                              fontSize: 11,
                                              color: Colors.grey.shade400,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Text(
                                      '${isExpense ? "-" : "+"}${CurrencyFormatter.format(tx.amount)}',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 15,
                                        color: isExpense
                                            ? const Color(0xFFE65100)
                                            : const Color(0xFF2E7D32),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
    );
  }

  Widget _buildSummaryColumn(String label, double amount, Color color) {
    return Expanded(
      child: Column(
        children: [
          Text(
            label,
            style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
          ),
          const SizedBox(height: 4),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              CurrencyFormatter.format(amount),
              style: TextStyle(
                fontSize: 14.5,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCalendarGrid(
    Map<int, double> dailyIncome,
    Map<int, double> dailyExpense,
  ) {
    final daysInMonth = DateTime(_currentMonth.year, _currentMonth.month + 1, 0).day;
    // Monday = 1 ... Sunday = 7
    final firstWeekday = DateTime(_currentMonth.year, _currentMonth.month, 1).weekday;
    final leadingSpaces = firstWeekday - 1;
    final totalCells = leadingSpaces + daysInMonth;
    final weekDays = ['T2', 'T3', 'T4', 'T5', 'T6', 'T7', 'CN'];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      child: Column(
        children: [
          Row(
            children: weekDays.map((d) {
              final isWeekend = d == 'T7' || d == 'CN';
              return Expanded(
                child: Center(
                  child: Text(
                    d,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: isWeekend ? Colors.red.shade400 : Colors.grey.shade600,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 4),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              childAspectRatio: 0.92,
              crossAxisSpacing: 2,
              mainAxisSpacing: 2,
            ),
            itemCount: totalCells,
            itemBuilder: (context, index) {
              if (index < leadingSpaces) {
                return const SizedBox.shrink();
              }
              final day = index - leadingSpaces + 1;
              final inc = dailyIncome[day] ?? 0;
              final exp = dailyExpense[day] ?? 0;
              final isSelected = _selectedDay?.day == day;
              final now = DateTime.now();
              final isToday = now.year == _currentMonth.year &&
                  now.month == _currentMonth.month &&
                  now.day == day;

              return InkWell(
                onTap: () {
                  setState(() {
                    if (isSelected) {
                      _selectedDay = null;
                    } else {
                      _selectedDay = DateTime(_currentMonth.year, _currentMonth.month, day);
                    }
                  });
                },
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? const Color(0xFFE65100).withOpacity(0.15)
                        : isToday
                            ? Colors.amber.withOpacity(0.12)
                            : Colors.transparent,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isSelected
                          ? const Color(0xFFE65100)
                          : isToday
                              ? Colors.amber.shade700
                              : Colors.grey.withOpacity(0.15),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text(
                        '$day',
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight:
                              isToday || isSelected ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                      const Spacer(),
                      if (inc > 0)
                        FittedBox(
                          child: Text(
                            '+${CurrencyFormatter.formatCompact(inc)}',
                            style: const TextStyle(
                              fontSize: 9.5,
                              color: Color(0xFF2E7D32),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      if (exp > 0)
                        FittedBox(
                          child: Text(
                            '-${CurrencyFormatter.formatCompact(exp)}',
                            style: const TextStyle(
                              fontSize: 9.5,
                              color: Color(0xFFE65100),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
