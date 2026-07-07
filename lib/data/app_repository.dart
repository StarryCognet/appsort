import 'models/app_info.dart';
import 'database_helper.dart';
import '../services/icon_cache_service.dart';

/// 应用数据仓库 - 协调平台插件与本地数据库
class AppRepository {
  /// 加载已安装应用到数据库
  /// 返回新添加的应用数量
  static Future<int> loadInstalledApps({
    required List<AppInfo> platformApps,
    List<AppInfo>? existingApps,
  }) async {
    // 获取已有应用（保留分类信息）
    final existing = existingApps ?? await DatabaseHelper.getAllApps(includeHidden: true);
    final existingMap = {for (final app in existing) app.packageName: app};

    final appsToInsert = <AppInfo>[];
    for (final platformApp in platformApps) {
      final existingApp = existingMap[platformApp.packageName];
      if (existingApp != null) {
        // 应用已存在，保留原有分类和排序，更新名称和版本
        appsToInsert.add(platformApp.copyWith(
          categoryId: existingApp.categoryId,
          sortOrder: existingApp.sortOrder,
          isHidden: existingApp.isHidden,
        ));
      } else {
        // 新应用
        appsToInsert.add(platformApp);
      }
    }

    await DatabaseHelper.upsertApps(appsToInsert);

    // 返回新应用数量
    return appsToInsert.length - existing.length;
  }

  /// 更新应用分类
  static Future<void> updateCategory(String packageName, String? categoryId) async {
    await DatabaseHelper.updateAppCategory(packageName, categoryId);
  }

  /// 重排应用顺序
  static Future<void> reorderApps(String packageName, int newOrder) async {
    await DatabaseHelper.updateAppSortOrder(packageName, newOrder);
  }

  /// 批量重排
  static Future<void> reorderAppsBatch(List<Map<String, dynamic>> updates) async {
    await DatabaseHelper.updateAppSortOrders(updates);
  }

  /// 隐藏/显示应用
  static Future<void> toggleHidden(String packageName, bool hidden) async {
    await DatabaseHelper.setAppHidden(packageName, hidden);
  }

  /// 获取所有应用
  static Future<List<AppInfo>> getAllApps({bool includeHidden = false}) async {
    return await DatabaseHelper.getAllApps(includeHidden: includeHidden);
  }

  /// 获取未分类应用
  static Future<List<AppInfo>> getUncategorizedApps() async {
    return await DatabaseHelper.getUncategorizedApps();
  }

  /// 搜索应用
  static Future<List<AppInfo>> searchApps(String query) async {
    if (query.trim().isEmpty) return await DatabaseHelper.getAllApps();
    return await DatabaseHelper.searchApps(query.trim());
  }

  /// 重新扫描（清除所有应用并重新加载）
  static Future<void> rescanApps(List<AppInfo> platformApps) async {
    await DatabaseHelper.clearApps();
    await IconCacheService.clearCache();
    await DatabaseHelper.upsertApps(platformApps);
  }
}
