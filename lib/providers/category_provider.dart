import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/models/app_category.dart';
import '../data/models/app_info.dart';
import '../data/database_helper.dart';
import '../data/category_repository.dart';
import '../data/app_repository.dart';

/// 分类状态
class CategoryState {
  final List<AppCategory> categories;
  final Map<String, List<AppInfo>> categorizedApps;
  final List<AppInfo> uncategorizedApps;
  final Map<String, int> appCounts;
  final bool isLoading;

  const CategoryState({
    this.categories = const [],
    this.categorizedApps = const {},
    this.uncategorizedApps = const [],
    this.appCounts = const {},
    this.isLoading = true,
  });

  CategoryState copyWith({
    List<AppCategory>? categories,
    Map<String, List<AppInfo>>? categorizedApps,
    List<AppInfo>? uncategorizedApps,
    Map<String, int>? appCounts,
    bool? isLoading,
  }) {
    return CategoryState(
      categories: categories ?? this.categories,
      categorizedApps: categorizedApps ?? this.categorizedApps,
      uncategorizedApps: uncategorizedApps ?? this.uncategorizedApps,
      appCounts: appCounts ?? this.appCounts,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

/// 分类提供者
class CategoryNotifier extends StateNotifier<CategoryState> {
  CategoryNotifier() : super(const CategoryState());

  /// 加载分类数据
  Future<void> loadCategories() async {
    state = state.copyWith(isLoading: true);
    try {
      final categories = await CategoryRepository.getAllCategories();
      final appCounts = await CategoryRepository.getAppCounts();
      final allApps = await DatabaseHelper.getAllApps();
      final uncategorized = await DatabaseHelper.getUncategorizedApps();

      // 按分类分组
      final categorized = <String, List<AppInfo>>{};
      for (final app in allApps) {
        if (app.categoryId != null) {
          categorized.putIfAbsent(app.categoryId!, () => []);
          // 已按 sortOrder 排序
          categorized[app.categoryId!]!.add(app);
        }
      }

      state = CategoryState(
        categories: categories,
        categorizedApps: categorized,
        uncategorizedApps: uncategorized,
        appCounts: appCounts,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false);
    }
  }

  /// 移动应用到分类
  Future<void> moveAppToCategory(String packageName, String categoryId) async {
    await AppRepository.updateCategory(packageName, categoryId);
    await loadCategories();
  }

  /// 移除应用分类
  Future<void> removeAppCategory(String packageName) async {
    await AppRepository.updateCategory(packageName, null);
    await loadCategories();
  }

  /// 创建新分类
  Future<AppCategory> createCategory({
    required String name,
    String icon = 'apps',
    String color = '#9E9E9E',
  }) async {
    final category = await CategoryRepository.createCategory(
      name: name,
      icon: icon,
      color: color,
    );
    await loadCategories();
    return category;
  }

  /// 更新分类
  Future<void> updateCategory(AppCategory category) async {
    await CategoryRepository.updateCategory(category);
    await loadCategories();
  }

  /// 删除分类
  Future<void> deleteCategory(String categoryId) async {
    await CategoryRepository.deleteCategory(categoryId);
    await loadCategories();
  }
}

final categoryProvider = StateNotifierProvider<CategoryNotifier, CategoryState>((ref) {
  return CategoryNotifier();
});
