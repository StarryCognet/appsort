import 'database_helper.dart';
import 'models/app_category.dart';

/// 简单的 UUID 生成器
String _generateId() {
  final timestamp = DateTime.now().millisecondsSinceEpoch;
  final random = (timestamp % 100000).toString().padLeft(5, '0');
  return 'cat_${timestamp}_$random';
}

/// 分类数据仓库
class CategoryRepository {

  /// 获取所有分类
  static Future<List<AppCategory>> getAllCategories() async {
    return await DatabaseHelper.getAllCategories();
  }

  /// 创建自定义分类
  static Future<AppCategory> createCategory({
    required String name,
    String icon = 'apps',
    String color = '#9E9E9E',
  }) async {
    final categories = await DatabaseHelper.getAllCategories();
    final category = AppCategory(
      id: _generateId(),
      name: name,
      icon: icon,
      color: color,
      sortOrder: categories.length,
      isBuiltIn: false,
    );
    await DatabaseHelper.insertCategory(category);
    return category;
  }

  /// 更新分类
  static Future<void> updateCategory(AppCategory category) async {
    await DatabaseHelper.updateCategory(category);
  }

  /// 删除分类
  static Future<void> deleteCategory(String categoryId) async {
    await DatabaseHelper.deleteCategory(categoryId);
  }

  /// 重排分类
  static Future<void> reorderCategories(List<AppCategory> categories) async {
    for (int i = 0; i < categories.length; i++) {
      await DatabaseHelper.updateCategorySortOrder(categories[i].id, i);
    }
  }

  /// 获取分类中的应用数量
  static Future<Map<String, int>> getAppCounts() async {
    final categories = await DatabaseHelper.getAllCategories();
    final counts = <String, int>{};
    for (final cat in categories) {
      counts[cat.id] = await DatabaseHelper.getAppCountForCategory(cat.id);
    }
    return counts;
  }
}
