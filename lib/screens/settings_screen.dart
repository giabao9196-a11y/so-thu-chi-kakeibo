import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../models/models.dart';
import '../services/database_helper.dart';
import '../utils/currency_formatter.dart';

class SettingsScreen extends StatefulWidget {
  final bool isDarkMode;
  final ValueChanged<bool> onThemeChanged;
  final VoidCallback onCategoriesUpdated;

  const SettingsScreen({
    super.key,
    required this.isDarkMode,
    required this.onThemeChanged,
    required this.onCategoriesUpdated,
  });

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  List<CategoryModel> _expenseCategories = [];
  List<CategoryModel> _incomeCategories = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    setState(() => _isLoading = true);
    final exp = await DatabaseHelper.instance.getCategories(
      type: TransactionType.expense,
    );
    final inc = await DatabaseHelper.instance.getCategories(
      type: TransactionType.income,
    );
    if (!mounted) return;
    setState(() {
      _expenseCategories = exp;
      _incomeCategories = inc;
      _isLoading = false;
    });
  }

  Future<void> _exportCsv() async {
    final txs = await DatabaseHelper.instance.getAllTransactions();
    if (txs.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Chưa có giao dịch nào để xuất file CSV')),
      );
      return;
    }

    final buffer = StringBuffer();
    buffer.writeln('ID,Ngay,Loai,Danh_Muc,So_Tien,Ghi_Chu');
    for (final tx in txs) {
      final dateStr = DateFormat('yyyy-MM-dd').format(tx.date);
      final typeStr = tx.type == TransactionType.expense ? 'Chi tieu' : 'Thu nhap';
      final safeNote = tx.note.replaceAll(',', ' ');
      buffer.writeln(
        '${tx.id},$dateStr,$typeStr,${tx.categoryName ?? ""},${tx.amount.toStringAsFixed(0)},$safeNote',
      );
    }

    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/so_thu_chi_kakeibo.csv');
    await file.writeAsString(buffer.toString());

    await Share.shareXFiles(
      [XFile(file.path)],
      text: 'Dữ liệu Sổ Thu Chi Kakeibo (CSV)',
    );
  }

  Future<void> _showCategoryDialog({
    CategoryModel? existing,
    required TransactionType defaultType,
  }) async {
    final nameCtrl = TextEditingController(text: existing?.name ?? '');
    final budgetCtrl = TextEditingController(
      text: existing != null && existing.monthlyBudget > 0
          ? existing.monthlyBudget.toStringAsFixed(0)
          : '',
    );

    final availableIcons = [
      Icons.restaurant,
      Icons.shopping_basket,
      Icons.directions_bus,
      Icons.local_cafe,
      Icons.checkroom,
      Icons.home,
      Icons.medical_services,
      Icons.menu_book,
      Icons.card_giftcard,
      Icons.payments,
      Icons.stars,
      Icons.trending_up,
      Icons.pets,
      Icons.sports_esports,
      Icons.flight,
      Icons.fact_check,
    ];

    final availableColors = [
      0xFFFF7043,
      0xFF66BB6A,
      0xFF42A5F5,
      0xFFAB47BC,
      0xFFEC407A,
      0xFFFFA726,
      0xFFEF5350,
      0xFF26A69A,
      0xFF7E57C2,
      0xFF5C6BC0,
    ];

    int selectedIcon = existing?.iconCodePoint ?? Icons.restaurant.codePoint;
    int selectedColor = existing?.colorValue ?? availableColors.first;

    await showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setDialogState) {
            return AlertDialog(
              title: Text(existing == null ? 'Thêm danh mục mới' : 'Chỉnh sửa danh mục'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextField(
                      controller: nameCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Tên danh mục',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    if (defaultType == TransactionType.expense) ...[
                      const SizedBox(height: 12),
                      TextField(
                        controller: budgetCtrl,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Hạn mức ngân sách tháng (₫)',
                          hintText: 'VD: 3000000 (Để trống nếu không giới hạn)',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ],
                    const SizedBox(height: 14),
                    const Text(
                      'Chọn màu sắc:',
                      style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: availableColors.map((colorVal) {
                        final isSelected = selectedColor == colorVal;
                        return GestureDetector(
                          onTap: () => setDialogState(() => selectedColor = colorVal),
                          child: CircleAvatar(
                            radius: 15,
                            backgroundColor: Color(colorVal),
                            child: isSelected
                                ? const Icon(Icons.check, color: Colors.white, size: 16)
                                : null,
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 14),
                    const Text(
                      'Chọn biểu tượng:',
                      style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: availableIcons.map((iconData) {
                        final isSelected = selectedIcon == iconData.codePoint;
                        return GestureDetector(
                          onTap: () =>
                              setDialogState(() => selectedIcon = iconData.codePoint),
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? Color(selectedColor).withOpacity(0.2)
                                  : Colors.grey.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: isSelected
                                    ? Color(selectedColor)
                                    : Colors.transparent,
                              ),
                            ),
                            child: Icon(
                              iconData,
                              color: Color(selectedColor),
                              size: 22,
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Hủy'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    final name = nameCtrl.text.trim();
                    if (name.isEmpty) return;
                    final budget = double.tryParse(budgetCtrl.text.trim()) ?? 0;

                    if (existing == null) {
                      await DatabaseHelper.instance.insertCategory(
                        CategoryModel(
                          name: name,
                          iconCodePoint: selectedIcon,
                          colorValue: selectedColor,
                          type: defaultType,
                          monthlyBudget: budget,
                        ),
                      );
                    } else {
                      await DatabaseHelper.instance.updateCategory(
                        existing.copyWith(
                          name: name,
                          iconCodePoint: selectedIcon,
                          colorValue: selectedColor,
                          monthlyBudget: budget,
                        ),
                      );
                    }

                    if (!ctx.mounted) return;
                    Navigator.pop(ctx);
                    _loadCategories();
                    widget.onCategoriesUpdated();
                  },
                  child: const Text('Lưu'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Cài đặt & Danh mục',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
        ),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(14),
              children: [
                // General Preferences Card
                Container(
                  decoration: BoxDecoration(
                    color: theme.cardColor,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Column(
                    children: [
                      SwitchListTile(
                        secondary: const Icon(Icons.dark_mode_outlined),
                        title: const Text('Giao diện tối (Dark Mode)'),
                        subtitle: const Text('Bảo vệ mắt khi ghi chép ban đêm'),
                        value: widget.isDarkMode,
                        onChanged: widget.onThemeChanged,
                      ),
                      const Divider(height: 1),
                      ListTile(
                        leading: const Icon(Icons.file_download_outlined),
                        title: const Text('Xuất dữ liệu ra file Excel / CSV'),
                        subtitle: const Text('Sao lưu hoặc mở trên bảng tính'),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: _exportCsv,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // Expense Categories Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'DANH MỤC CHI TIÊU & HẠN MỨC',
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.6,
                      ),
                    ),
                    TextButton.icon(
                      onPressed: () => _showCategoryDialog(
                        defaultType: TransactionType.expense,
                      ),
                      icon: const Icon(Icons.add, size: 18),
                      label: const Text('Thêm mới'),
                    ),
                  ],
                ),

                Container(
                  decoration: BoxDecoration(
                    color: theme.cardColor,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _expenseCategories.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final cat = _expenseCategories[index];
                      return ListTile(
                        leading: CircleAvatar(
                          backgroundColor: cat.color.withOpacity(0.15),
                          child: Icon(cat.icon, color: cat.color, size: 20),
                        ),
                        title: Text(
                          cat.name,
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        subtitle: Text(
                          cat.monthlyBudget > 0
                              ? 'Ngân sách: ${CurrencyFormatter.format(cat.monthlyBudget)}/tháng'
                              : 'Chưa đặt hạn mức ngân sách',
                          style: const TextStyle(fontSize: 12),
                        ),
                        trailing: IconButton(
                          icon: const Icon(Icons.edit_outlined, size: 20),
                          onPressed: () => _showCategoryDialog(
                            existing: cat,
                            defaultType: TransactionType.expense,
                          ),
                        ),
                      );
                    },
                  ),
                ),

                const SizedBox(height: 20),

                // Income Categories Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'DANH MỤC THU NHẬP',
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.6,
                      ),
                    ),
                    TextButton.icon(
                      onPressed: () => _showCategoryDialog(
                        defaultType: TransactionType.income,
                      ),
                      icon: const Icon(Icons.add, size: 18),
                      label: const Text('Thêm mới'),
                    ),
                  ],
                ),

                Container(
                  decoration: BoxDecoration(
                    color: theme.cardColor,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _incomeCategories.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final cat = _incomeCategories[index];
                      return ListTile(
                        leading: CircleAvatar(
                          backgroundColor: cat.color.withOpacity(0.15),
                          child: Icon(cat.icon, color: cat.color, size: 20),
                        ),
                        title: Text(
                          cat.name,
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        trailing: IconButton(
                          icon: const Icon(Icons.edit_outlined, size: 20),
                          onPressed: () => _showCategoryDialog(
                            existing: cat,
                            defaultType: TransactionType.income,
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
}
