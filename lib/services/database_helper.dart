import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import '../models/models.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('kakeibo_money_note.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    if (!kIsWeb && (Platform.isWindows || Platform.isLinux || Platform.isMacOS)) {
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
      final supportDir = await getApplicationSupportDirectory();
      final dbDir = Directory(join(supportDir.path, 'databases'));
      if (!await dbDir.exists()) {
        await dbDir.create(recursive: true);
      }
      final path = join(dbDir.path, filePath);
      return await databaseFactory.openDatabase(
        path,
        options: OpenDatabaseOptions(
          version: 1,
          onCreate: _createDB,
        ),
      );
    }

    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 1,
      onCreate: _createDB,
    );
  }
  Future<void> _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE categories (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        icon_code INTEGER NOT NULL,
        color_value INTEGER NOT NULL,
        type TEXT NOT NULL,
        monthly_budget REAL DEFAULT 0,
        sort_order INTEGER DEFAULT 0
      )
    ''');

    await db.execute('''
      CREATE TABLE transactions (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        amount REAL NOT NULL,
        note TEXT,
        date TEXT NOT NULL,
        category_id INTEGER NOT NULL,
        type TEXT NOT NULL,
        FOREIGN KEY (category_id) REFERENCES categories (id) ON DELETE CASCADE
      )
    ''');

    await _seedDefaultCategories(db);
  }

  Future<void> _seedDefaultCategories(Database db) async {
    final defaultCategories = [
      // Expense categories (Kakeibo style)
      CategoryModel(
        name: 'Ăn uống',
        iconCodePoint: Icons.restaurant.codePoint,
        colorValue: 0xFFFF7043,
        type: TransactionType.expense,
        monthlyBudget: 3000000,
        sortOrder: 1,
      ),
      CategoryModel(
        name: 'Đi chợ / Siêu thị',
        iconCodePoint: Icons.shopping_basket.codePoint,
        colorValue: 0xFF66BB6A,
        type: TransactionType.expense,
        monthlyBudget: 2500000,
        sortOrder: 2,
      ),
      CategoryModel(
        name: 'Di chuyển / Xăng xe',
        iconCodePoint: Icons.directions_bus.codePoint,
        colorValue: 0xFF42A5F5,
        type: TransactionType.expense,
        monthlyBudget: 800000,
        sortOrder: 3,
      ),
      CategoryModel(
        name: 'Cà phê / Giải trí',
        iconCodePoint: Icons.local_cafe.codePoint,
        colorValue: 0xFFAB47BC,
        type: TransactionType.expense,
        monthlyBudget: 1000000,
        sortOrder: 4,
      ),
      CategoryModel(
        name: 'Mua sắm / Quần áo',
        iconCodePoint: Icons.checkroom.codePoint,
        colorValue: 0xFFEC407A,
        type: TransactionType.expense,
        monthlyBudget: 1500000,
        sortOrder: 5,
      ),
      CategoryModel(
        name: 'Nhà cửa / Điện nước',
        iconCodePoint: Icons.home.codePoint,
        colorValue: 0xFFFFA726,
        type: TransactionType.expense,
        monthlyBudget: 4000000,
        sortOrder: 6,
      ),
      CategoryModel(
        name: 'Y tế / Sức khỏe',
        iconCodePoint: Icons.medical_services.codePoint,
        colorValue: 0xFFEF5350,
        type: TransactionType.expense,
        monthlyBudget: 500000,
        sortOrder: 7,
      ),
      CategoryModel(
        name: 'Giáo dục / Sách vở',
        iconCodePoint: Icons.menu_book.codePoint,
        colorValue: 0xFF26A69A,
        type: TransactionType.expense,
        monthlyBudget: 500000,
        sortOrder: 8,
      ),
      CategoryModel(
        name: 'Giao lưu / Hiếu hỉ',
        iconCodePoint: Icons.card_giftcard.codePoint,
        colorValue: 0xFFFFCA28,
        type: TransactionType.expense,
        monthlyBudget: 1000000,
        sortOrder: 9,
      ),
      // Income categories
      CategoryModel(
        name: 'Tiền lương',
        iconCodePoint: Icons.payments.codePoint,
        colorValue: 0xFF43A047,
        type: TransactionType.income,
        sortOrder: 1,
      ),
      CategoryModel(
        name: 'Thưởng / Phụ cấp',
        iconCodePoint: Icons.stars.codePoint,
        colorValue: 0xFFFDD835,
        type: TransactionType.income,
        sortOrder: 2,
      ),
      CategoryModel(
        name: 'Đầu tư / Kinh doanh',
        iconCodePoint: Icons.trending_up.codePoint,
        colorValue: 0xFF1E88E5,
        type: TransactionType.income,
        sortOrder: 3,
      ),
      CategoryModel(
        name: 'Thu nhập khác',
        iconCodePoint: Icons.account_balance_wallet.codePoint,
        colorValue: 0xFF8E24AA,
        type: TransactionType.income,
        sortOrder: 4,
      ),
    ];

    for (final cat in defaultCategories) {
      await db.insert('categories', cat.toMap());
    }
  }

  // Category CRUD
  Future<List<CategoryModel>> getCategories({TransactionType? type}) async {
    final db = await instance.database;
    String? whereClause;
    List<dynamic>? whereArgs;

    if (type != null) {
      whereClause = 'type = ?';
      whereArgs = [type == TransactionType.expense ? 'expense' : 'income'];
    }

    final result = await db.query(
      'categories',
      where: whereClause,
      whereArgs: whereArgs,
      orderBy: 'sort_order ASC, id ASC',
    );

    return result.map((json) => CategoryModel.fromMap(json)).toList();
  }

  Future<int> insertCategory(CategoryModel category) async {
    final db = await instance.database;
    return await db.insert('categories', category.toMap());
  }

  Future<int> updateCategory(CategoryModel category) async {
    final db = await instance.database;
    return await db.update(
      'categories',
      category.toMap(),
      where: 'id = ?',
      whereArgs: [category.id],
    );
  }

  Future<int> deleteCategory(int id) async {
    final db = await instance.database;
    return await db.delete('categories', where: 'id = ?', whereArgs: [id]);
  }

  // Transaction CRUD
  Future<int> insertTransaction(TransactionModel tx) async {
    final db = await instance.database;
    return await db.insert('transactions', tx.toMap());
  }

  Future<int> deleteTransaction(int id) async {
    final db = await instance.database;
    return await db.delete('transactions', where: 'id = ?', whereArgs: [id]);
  }

  Future<List<TransactionModel>> getTransactionsByMonth(int year, int month) async {
    final db = await instance.database;
    final startDate = DateTime(year, month, 1).toIso8601String();
    final endDate = DateTime(year, month + 1, 0, 23, 59, 59).toIso8601String();

    final result = await db.rawQuery('''
      SELECT t.*, 
             c.name as category_name, 
             c.icon_code as category_icon, 
             c.color_value as category_color
      FROM transactions t
      LEFT JOIN categories c ON t.category_id = c.id
      WHERE t.date >= ? AND t.date <= ?
      ORDER BY t.date DESC, t.id DESC
    ''', [startDate, endDate]);

    return result.map((json) => TransactionModel.fromMap(json)).toList();
  }

  Future<List<TransactionModel>> getAllTransactions() async {
    final db = await instance.database;
    final result = await db.rawQuery('''
      SELECT t.*, 
             c.name as category_name, 
             c.icon_code as category_icon, 
             c.color_value as category_color
      FROM transactions t
      LEFT JOIN categories c ON t.category_id = c.id
      ORDER BY t.date DESC, t.id DESC
    ''');
    return result.map((json) => TransactionModel.fromMap(json)).toList();
  }
}
