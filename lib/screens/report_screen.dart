import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../models/models.dart';
import '../services/database_helper.dart';
import '../utils/currency_formatter.dart';

class ReportScreen extends StatefulWidget {
  final int refreshTrigger;

  const ReportScreen({super.key, required this.refreshTrigger});

  @override
  State<ReportScreen> createState() => _ReportScreenState();
}

class _CategoryStat {
  final CategoryModel category;
  double totalAmount;

  _CategoryStat({required this.category, required this.totalAmount});
}

class _ReportScreenState extends State<ReportScreen> {
  DateTime _currentMonth = DateTime(DateTime.now().year, DateTime.now().month, 1);
  TransactionType _selectedType = TransactionType.expense;
  List<TransactionModel> _transactions = [];
  List<CategoryModel> _categories = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void didUpdateWidget(covariant ReportScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.refreshTrigger != widget.refreshTrigger) {
      _loadData();
    }
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final txs = await DatabaseHelper.instance.getTransactionsByMonth(
      _currentMonth.year,
      _currentMonth.month,
    );
    final cats = await DatabaseHelper.instance.getCategories();
    if (!mounted) return;
    setState(() {
      _transactions = txs;
      _categories = cats;
      _isLoading = false;
    });
  }

  void _changeMonth(int delta) {
    setState(() {
      _currentMonth = DateTime(_currentMonth.year, _currentMonth.month + delta, 1);
    });
    _loadData();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isExpense = _selectedType == TransactionType.expense;

    final Map<int, _CategoryStat> statsMap = {};
    for (final cat in _categories.where((c) => c.type == _selectedType)) {
      if (cat.id != null) {
        statsMap[cat.id!] = _CategoryStat(category: cat, totalAmount: 0);
      }
    }

    double grandTotal = 0;
    for (final tx in _transactions.where((t) => t.type == _selectedType)) {
      grandTotal += tx.amount;
      if (statsMap.containsKey(tx.categoryId)) {
        statsMap[tx.categoryId]!.totalAmount += tx.amount;
      }
    }

    final activeStats = statsMap.values
        .where((s) => s.totalAmount > 0 || (isExpense && s.category.monthlyBudget > 0))
        .toList()
      ..sort((a, b) => b.totalAmount.compareTo(a.totalAmount));

    final chartStats = statsMap.values.where((s) => s.totalAmount > 0).toList()
      ..sort((a, b) => b.totalAmount.compareTo(a.totalAmount));

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
              'Báo cáo T${_currentMonth.month}/${_currentMonth.year}',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
            ),
            IconButton(
              icon: const Icon(Icons.chevron_right),
              onPressed: () => _changeMonth(1),
            ),
          ],
        ),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Type Switcher
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  child: Row(
                    children: [
                      Expanded(
                        child: _buildTabButton(
                          'Phân tích Chi tiêu',
                          TransactionType.expense,
                          const Color(0xFFE65100),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _buildTabButton(
                          'Phân tích Thu nhập',
                          TransactionType.income,
                          const Color(0xFF2E7D32),
                        ),
                      ),
                    ],
                  ),
                ),

                // Pie Chart Card
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  padding: const EdgeInsets.all(16),
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
                  child: chartStats.isEmpty
                      ? SizedBox(
                          height: 180,
                          child: Center(
                            child: Text(
                              'Chưa có dữ liệu ${isExpense ? "chi tiêu" : "thu nhập"} trong tháng này',
                              style: TextStyle(color: Colors.grey.shade500),
                            ),
                          ),
                        )
                      : Column(
                          children: [
                            SizedBox(
                              height: 190,
                              child: Stack(
                                alignment: Alignment.center,
                                children: [
                                  PieChart(
                                    PieChartData(
                                      sectionsSpace: 2,
                                      centerSpaceRadius: 54,
                                      sections: chartStats.map((stat) {
                                        final pct = grandTotal > 0
                                            ? (stat.totalAmount / grandTotal) * 100
                                            : 0.0;
                                        return PieChartSectionData(
                                          color: stat.category.color,
                                          value: stat.totalAmount,
                                          title: pct >= 6 ? '${pct.toStringAsFixed(0)}%' : '',
                                          radius: 36,
                                          titleStyle: const TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.white,
                                          ),
                                        );
                                      }).toList(),
                                    ),
                                  ),
                                  Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        isExpense ? 'Tổng chi' : 'Tổng thu',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey.shade500,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        CurrencyFormatter.formatCompact(grandTotal),
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          color: isExpense
                                              ? const Color(0xFFE65100)
                                              : const Color(0xFF2E7D32),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                ),

                // Category breakdown & Kakeibo monthly budget progress
                Expanded(
                  child: ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    itemCount: activeStats.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final stat = activeStats[index];
                      final cat = stat.category;
                      final pct = grandTotal > 0 ? (stat.totalAmount / grandTotal) : 0.0;
                      final hasBudget = isExpense && cat.monthlyBudget > 0;
                      final budgetRatio =
                          hasBudget ? (stat.totalAmount / cat.monthlyBudget) : 0.0;
                      final isOverBudget = budgetRatio > 1.0;

                      return Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: theme.cardColor,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                CircleAvatar(
                                  radius: 18,
                                  backgroundColor: cat.color.withOpacity(0.15),
                                  child: Icon(cat.icon, color: cat.color, size: 19),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    cat.name,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14.5,
                                    ),
                                  ),
                                ),
                                Text(
                                  '${(pct * 100).toStringAsFixed(1)}%',
                                  style: TextStyle(
                                    fontSize: 12.5,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Text(
                                  CurrencyFormatter.format(stat.totalAmount),
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14.5,
                                  ),
                                ),
                              ],
                            ),
                            if (hasBudget) ...[
                              const SizedBox(height: 8),
                              ClipRRect(
                                borderRadius: BorderRadius.circular(6),
                                child: LinearProgressIndicator(
                                  value: budgetRatio.clamp(0.0, 1.0),
                                  minHeight: 7,
                                  backgroundColor: Colors.grey.withOpacity(0.15),
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    isOverBudget ? Colors.red.shade600 : cat.color,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Ngân sách: ${CurrencyFormatter.format(cat.monthlyBudget)}',
                                    style: TextStyle(
                                      fontSize: 11.5,
                                      color: Colors.grey.shade600,
                                    ),
                                  ),
                                  Text(
                                    isOverBudget
                                        ? 'Vượt hạn mức: ${CurrencyFormatter.format(stat.totalAmount - cat.monthlyBudget)}'
                                        : 'Còn lại: ${CurrencyFormatter.format(cat.monthlyBudget - stat.totalAmount)}',
                                    style: TextStyle(
                                      fontSize: 11.5,
                                      fontWeight: FontWeight.w600,
                                      color: isOverBudget
                                          ? Colors.red.shade600
                                          : Colors.teal.shade700,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildTabButton(String title, TransactionType type, Color color) {
    final isSelected = _selectedType == type;
    return InkWell(
      onTap: () => setState(() => _selectedType = type),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? color : Colors.grey.withOpacity(0.12),
          borderRadius: BorderRadius.circular(12),
        ),
        alignment: Alignment.center,
        child: Text(
          title,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 13.5,
            color: isSelected ? Colors.white : Colors.grey.shade700,
          ),
        ),
      ),
    );
  }
}
