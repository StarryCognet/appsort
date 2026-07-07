import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/app_list_provider.dart';
import '../../providers/search_provider.dart';
import '../../services/installed_apps_service.dart';
import '../widgets/app_tile.dart';
import '../widgets/empty_state.dart';
import '../widgets/loading_state.dart';
import '../widgets/search_bar_widget.dart';

/// 全部应用页面
class AllAppsPage extends ConsumerWidget {
  const AllAppsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appListState = ref.watch(appListProvider);
    final searchState = ref.watch(searchProvider);

    // 首次加载
    if (appListState.isFirstLoad && !appListState.isLoading) {
      ref.read(appListProvider.notifier).loadApps();
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('全部应用'),
        actions: [
          if (appListState.apps.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.refresh),
              tooltip: '刷新',
              onPressed: () => ref.read(appListProvider.notifier).refreshApps(),
            ),
        ],
      ),
      body: Column(
        children: [
          // 搜索栏
          AppSearchBar(
            onChanged: (query) => ref.read(searchProvider.notifier).updateQuery(query),
            onClear: () => ref.read(searchProvider.notifier).clearSearch(),
          ),
          // 应用列表
          Expanded(
            child: _buildAppList(context, ref, appListState, searchState),
          ),
        ],
      ),
    );
  }

  Widget _buildAppList(
    BuildContext context,
    WidgetRef ref,
    AppListState appListState,
    SearchState searchState,
  ) {
    // 加载中
    if (appListState.isLoading) {
      return const LoadingState(message: '正在加载应用列表...');
    }

    // 错误
    if (appListState.error != null && appListState.apps.isEmpty) {
      return EmptyState(
        icon: Icons.error_outline,
        title: '加载失败',
        message: appListState.error!,
        actionLabel: '重试',
        onAction: () => ref.read(appListProvider.notifier).loadApps(),
      );
    }

    // 空列表
    if (appListState.apps.isEmpty) {
      return EmptyState(
        icon: Icons.phone_android,
        title: '没有找到应用',
        message: '请确保已授予应用列表权限',
        actionLabel: '扫描',
        onAction: () => ref.read(appListProvider.notifier).loadApps(),
      );
    }

    // 搜索中
    if (searchState.isSearching && searchState.query.isNotEmpty) {
      return const LoadingState(message: '搜索中...');
    }

    // 搜索结果
    final displayApps = searchState.query.isNotEmpty ? searchState.results : appListState.apps;

    if (searchState.query.isNotEmpty && searchState.results.isEmpty) {
      return EmptyState(
        icon: Icons.search_off,
        title: '没有找到匹配的应用',
        message: '尝试其他关键词',
      );
    }

    return RefreshIndicator(
      onRefresh: () => ref.read(appListProvider.notifier).refreshApps(),
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        itemCount: displayApps.length,
        itemBuilder: (context, index) {
          final app = displayApps[index];
          return AppTile(
            appName: app.appName,
            packageName: app.packageName,
            iconPath: app.iconPath,
            isSystemApp: app.isSystemApp,
            onTap: () => InstalledAppsService.openApp(app.packageName),
            onLongPress: () => _showAppOptions(context, app.packageName),
          );
        },
      ),
    );
  }

  void _showAppOptions(BuildContext context, String packageName) {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.open_in_new),
              title: const Text('打开应用'),
              onTap: () {
                Navigator.pop(ctx);
                InstalledAppsService.openApp(packageName);
              },
            ),
            ListTile(
              leading: const Icon(Icons.store),
              title: const Text('在应用商店查看'),
              onTap: () {
                Navigator.pop(ctx);
                InstalledAppsService.openAppStore(packageName);
              },
            ),
            ListTile(
              leading: const Icon(Icons.settings),
              title: const Text('应用详情设置'),
              onTap: () {
                Navigator.pop(ctx);
                InstalledAppsService.openAppSettings(packageName);
              },
            ),
          ],
        ),
      ),
    );
  }
}
