import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../core/constants.dart';
import 'models/app_info.dart';
import 'models/app_category.dart';

/// 数据库管理类（使用 sqflite）
class DatabaseHelper {
  static Database? _database;

  /// 获取数据库实例
  static Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  /// 初始化数据库
  static Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, AppConstants.databaseName);

    return await openDatabase(
      path,
      version: AppConstants.databaseVersion,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  /// 创建表
  static Future<void> _onCreate(Database db, int version) async {
    // 应用表
    await db.execute('''
      CREATE TABLE apps (
        packageName TEXT PRIMARY KEY,
        appName TEXT NOT NULL,
        versionName TEXT DEFAULT '',
        versionCode INTEGER DEFAULT 0,
        isSystemApp INTEGER DEFAULT 0,
        iconPath TEXT,
        categoryId TEXT,
        sortOrder INTEGER DEFAULT 0,
        isHidden INTEGER DEFAULT 0
      )
    ''');

    // 分类表
    await db.execute('''
      CREATE TABLE categories (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        icon TEXT DEFAULT 'apps',
        color TEXT DEFAULT '#9E9E9E',
        sortOrder INTEGER DEFAULT 0,
        isBuiltIn INTEGER DEFAULT 0
      )
    ''');

    // 设置表
    await db.execute('''
      CREATE TABLE settings (
        key TEXT PRIMARY KEY,
        value TEXT NOT NULL
      )
    ''');

    // 插入默认分类
    await _seedDefaultCategories(db);
  }

  /// 数据库升级
  static Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    // 预留迁移逻辑
  }

  /// 种子数据：默认分类
  static Future<void> _seedDefaultCategories(Database db) async {
    final batch = db.batch();
    for (int i = 0; i < AppConstants.defaultCategories.length; i++) {
      final cat = AppConstants.defaultCategories[i];
      batch.insert('categories', {
        'id': 'default_$i',
        'name': cat['name']!,
        'icon': cat['icon']!,
        'color': cat['color']!,
        'sortOrder': i,
        'isBuiltIn': 1,
      });
    }
    await batch.commit(noResult: true);
  }

  // ==================== 应用操作 ====================

  /// 批量插入/更新应用
  static Future<void> upsertApps(List<AppInfo> apps) async {
    final db = await database;
    final batch = db.batch();
    for (final app in apps) {
      batch.insert(
        'apps',
        app.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
    await batch.commit(noResult: true);
  }

  /// 获取所有应用
  static Future<List<AppInfo>> getAllApps({bool includeHidden = false}) async {
    final db = await database;
    final maps = includeHidden
        ? await db.query('apps', orderBy: 'sortOrder ASC, appName ASC')
        : await db.query('apps',
            where: 'isHidden = ?', whereArgs: [0], orderBy: 'sortOrder ASC, appName ASC');
    return maps.map((m) => AppInfo.fromMap(m)).toList();
  }

  /// 获取未分类的应用
  static Future<List<AppInfo>> getUncategorizedApps() async {
    final db = await database;
    final maps = await db.query('apps',
        where: 'categoryId IS NULL AND isHidden = ?', whereArgs: [0]);
    return maps.map((m) => AppInfo.fromMap(m)).toList();
  }

  /// 按分类获取应用
  static Future<List<AppInfo>> getAppsByCategory(String categoryId) async {
    final db = await database;
    final maps = await db.query('apps',
        where: 'categoryId = ? AND isHidden = ?',
        whereArgs: [categoryId, 0],
        orderBy: 'sortOrder ASC, appName ASC');
    return maps.map((m) => AppInfo.fromMap(m)).toList();
  }

  /// 更新应用分类
  static Future<void> updateAppCategory(String packageName, String? categoryId) async {
    final db = await database;
    await db.update(
      'apps',
      {'categoryId': categoryId},
      where: 'packageName = ?',
      whereArgs: [packageName],
    );
  }

  /// 更新应用排序
  static Future<void> updateAppSortOrder(String packageName, int sortOrder) async {
    final db = await database;
    await db.update(
      'apps',
      {'sortOrder': sortOrder},
      where: 'packageName = ?',
      whereArgs: [packageName],
    );
  }

  /// 批量更新排序
  static Future<void> updateAppSortOrders(List<Map<String, dynamic>> updates) async {
    final db = await database;
    final batch = db.batch();
    for (final update in updates) {
      batch.update(
        'apps',
        {'sortOrder': update['sortOrder']},
        where: 'packageName = ?',
        whereArgs: [update['packageName']],
      );
    }
    await batch.commit(noResult: true);
  }

  /// 隐藏/显示应用
  static Future<void> setAppHidden(String packageName, bool hidden) async {
    final db = await database;
    await db.update(
      'apps',
      {'isHidden': hidden ? 1 : 0},
      where: 'packageName = ?',
      whereArgs: [packageName],
    );
  }

  /// 搜索应用
  static Future<List<AppInfo>> searchApps(String query) async {
    final db = await database;
    final maps = await db.query(
      'apps',
      where: 'appName LIKE ? AND isHidden = ?',
      whereArgs: ['%$query%', 0],
      orderBy: 'sortOrder ASC, appName ASC',
    );
    return maps.map((m) => AppInfo.fromMap(m)).toList();
  }

  /// 删除所有应用（用于重新扫描）
  static Future<void> clearApps() async {
    final db = await database;
    await db.delete('apps');
  }

  // ==================== 分类操作 ====================

  /// 获取所有分类
  static Future<List<AppCategory>> getAllCategories() async {
    final db = await database;
    final maps = await db.query('categories', orderBy: 'sortOrder ASC');
    return maps.map((m) => AppCategory.fromMap(m)).toList();
  }

  /// 添加分类
  static Future<void> insertCategory(AppCategory category) async {
    final db = await database;
    await db.insert('categories', category.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  /// 更新分类
  static Future<void> updateCategory(AppCategory category) async {
    final db = await database;
    await db.update(
      'categories',
      category.toMap(),
      where: 'id = ?',
      whereArgs: [category.id],
    );
  }

  /// 删除分类（同时将属于该分类的应用置为未分类）
  static Future<void> deleteCategory(String categoryId) async {
    final db = await database;
    // 将属于该分类的应用的 categoryId 置为 null
    await db.update(
      'apps',
      {'categoryId': null},
      where: 'categoryId = ?',
      whereArgs: [categoryId],
    );
    await db.delete('categories', where: 'id = ?', whereArgs: [categoryId]);
  }

  /// 更新分类排序
  static Future<void> updateCategorySortOrder(String id, int sortOrder) async {
    final db = await database;
    await db.update(
      'categories',
      {'sortOrder': sortOrder},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// 获取分类中的应用数量
  static Future<int> getAppCountForCategory(String categoryId) async {
    final db = await database;
    final result = await db.rawQuery(
      'SELECT COUNT(*) as count FROM apps WHERE categoryId = ? AND isHidden = ?',
      [categoryId, 0],
    );
    return Sqflite.firstIntValue(result) ?? 0;
  }

  // ==================== 设置操作 ====================

  /// 获取设置值
  static Future<String?> getSetting(String key) async {
    final db = await database;
    final maps = await db.query('settings',
        where: 'key = ?', whereArgs: [key]);
    if (maps.isNotEmpty) {
      return maps.first['value'] as String?;
    }
    return null;
  }

  /// 设置值
  static Future<void> setSetting(String key, String value) async {
    final db = await database;
    await db.insert(
      'settings',
      {'key': key, 'value': value},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// 关闭数据库
  static Future<void> close() async {
    final db = await database;
    await db.close();
    _database = null;
  }
}
