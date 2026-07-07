import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/models/app_info.dart';
import '../data/app_repository.dart';
import '../data/database_helper.dart';
import '../services/installed_apps_service.dart';

/// 应用列表状态
class AppListState {
  final List<AppInfo> apps;
  final bool isLoading;
  final bool isFirstLoad;
  final String? error;
  final int newAppCount;

  const AppListState({
    this.apps = const [],
    this.isLoading = true,
    this.isFirstLoad = true,
    this.error,
    this.newAppCount = 0,
  });

  AppListState copyWith({
    List<AppInfo>? apps,
    bool? isLoading,
    bool? isFirstLoad,
    String? error,
    int? newAppCount,
  }) {
    return AppListState(
      apps: apps ?? this.apps,
      isLoading: isLoading ?? this.isLoading,
      isFirstLoad: isFirstLoad ?? this.isFirstLoad,
      error: error,
      newAppCount: newAppCount ?? this.newAppCount,
    );
  }
}

/// 应用列表提供者
class AppListNotifier extends StateNotifier<AppListState> {
  AppListNotifier() : super(const AppListState());

  /// 加载应用（首次从平台获取，后续从数据库加载）
  Future<void> loadApps({bool forceRefresh = false}) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      if (forceRefresh || state.isFirstLoad) {
        // 从平台获取新应用列表
        if (forceRefresh) {
          // 强制刷新：清除所有数据后重新加载
          final settings = await _getSettings();
          final platformApps = await InstalledAppsService.getInstalledApps(
            includeSystemApps: settings?.includeSystemApps ?? false,
          );
          await AppRepository.rescanApps(platformApps);
        } else {
          // 首次加载：从平台获取并合并到数据库
          final settings = await _getSettings();
          final platformApps = await InstalledAppsService.getInstalledApps(
            includeSystemApps: settings?.includeSystemApps ?? false,
          );
          final existingApps = await DatabaseHelper.getAllApps(includeHidden: true);
          await AppRepository.loadInstalledApps(
            platformApps: platformApps,
            existingApps: existingApps,
          );
        }
      }

      // 从数据库读取
      final apps = await AppRepository.getAllApps();
      state = AppListState(
        apps: apps,
        isLoading: false,
        isFirstLoad: false,
      );
    } catch (e) {
      // 如果首次加载失败，尝试从数据库读取缓存
      try {
        final cached = await DatabaseHelper.getAllApps();
        if (cached.isNotEmpty) {
          state = AppListState(
            apps: cached,
            isLoading: false,
            isFirstLoad: false,
            error: '部分数据可能不是最新的: $e',
          );
          return;
        }
      } catch (_) {}

      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  /// 强制重新扫描
  Future<void> refreshApps() async {
    await loadApps(forceRefresh: true);
  }

  /// 获取设置（临时方法）
  Future<dynamic> _getSettings() async {
    try {
      // 通过 Riverpod 上下文获取设置较复杂，此处简化
      return null;
    } catch (_) {
      return null;
    }
  }

  /// 更新应用分类
  Future<void> updateAppCategory(String packageName, String? categoryId) async {
    await AppRepository.updateCategory(packageName, categoryId);
    // 刷新列表
    final apps = await AppRepository.getAllApps();
    state = state.copyWith(apps: apps);
  }

  /// 搜索应用
  Future<List<AppInfo>> searchApps(String query) async {
    return await AppRepository.searchApps(query);
  }
}

final appListProvider = StateNotifierProvider<AppListNotifier, AppListState>((ref) {
  return AppListNotifier();
});
