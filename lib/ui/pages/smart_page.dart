import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/app_list_provider.dart';
import '../../providers/category_provider.dart';
import '../../providers/classification_provider.dart';
import '../../providers/settings_provider.dart';
import '../widgets/category_section.dart';
import '../widgets/classification_progress.dart';
import '../widgets/empty_state.dart';
import '../widgets/loading_state.dart';

/// 智能分类主页
class SmartPage extends ConsumerWidget {
  const SmartPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appListState = ref.watch(appListProvider);
    final categoryState = ref.watch(categoryProvider);
    final classificationState = ref.watch(classificationProvider);
    final settingsState = ref.watch(settingsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('AppSort'),
        actions: [
          // 重新分类按钮
          if (appListState.apps.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.refresh),
              tooltip: '重新扫描',
              onPressed: () => ref.read(appListProvider.notifier).refreshApps(),
            ),
        ],
      ),
      body: _buildBody(context, ref, appListState, categoryState, classificationState),
      floatingActionButton: _buildFab(context, ref, appListState, settingsState, classificationState),
    );
  }

  Widget _buildBody(
    BuildContext context,
    WidgetRef ref,
    AppListState appListState,
    CategoryState categoryState,
    ClassificationState classificationState,
  ) {
    // 加载中
    if (appListState.isLoading) {
      return const LoadingState(message: '正在扫描已安装应用...');
    }

    // 错误状态
    if (appListState.error != null && appListState.apps.isEmpty) {
      return EmptyState(
        icon: Icons.error_outline,
        title: '加载失败',
        message: appListState.error!,
        actionLabel: '重试',
        onAction: () => ref.read(appListProvider.notifier).loadApps(),
      );
    }

    // 没有应用
    if (appListState.apps.isEmpty) {
      return EmptyState(
        icon: Icons.phone_android,
        title: '没有找到应用',
        message: '请确保已授予应用列表权限',
        actionLabel: '刷新',
        onAction: () => ref.read(appListProvider.notifier).loadApps(),
      );
    }

    // 首次启动，显示欢迎和分类进度
    if (categoryState.isLoading) {
      ref.read(categoryProvider.notifier).loadCategories();
      return const LoadingState(message: '正在加载分类...');
    }

    // 显示分类进度遮罩
    if (classificationState.isRunning) {
      return ClassificationProgressWidget(
        state: classificationState,
        onCancel: () => ref.read(classificationProvider.notifier).cancel(),
      );
    }

    // 正常显示分类内容
    return _buildCategoryContent(context, ref, categoryState, classificationState);
  }

  Widget _buildCategoryContent(
    BuildContext context,
    WidgetRef ref,
    CategoryState categoryState,
    ClassificationState classificationState,
  ) {
    final hasApps = categoryState.categories.any(
      (cat) => categoryState.categorizedApps[cat.id]?.isNotEmpty ?? false,
    );
    final hasUncategorized = categoryState.uncategorizedApps.isNotEmpty;

    if (!hasApps && !hasUncategorized) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.smart_toy,
              size: 80,
              color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.3),
            ),
            const SizedBox(height: 16),
            Text(
              '应用已全部整理',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              '点击下方按钮使用 AI 重新分类',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
            const SizedBox(height: 24),
            FilledButton.tonalIcon(
              onPressed: () => _startClassification(ref),
              icon: const Icon(Icons.auto_awesome),
              label: const Text('AI 重新分类'),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => ref.read(appListProvider.notifier).refreshApps(),
      child: ListView.builder(
        padding: const EdgeInsets.only(top: 8, bottom: 88),
        itemCount: categoryState.categories.length + (hasUncategorized ? 1 : 0),
        itemBuilder: (context, index) {
          // 未分类应用
          if (hasUncategorized && index == categoryState.categories.length) {
            return CategorySection(
              categoryName: '未分类',
              icon: Icons.help_outline,
              color: Colors.grey,
              apps: categoryState.uncategorizedApps,
              onTap: (app) => _showAppOptions(context, ref, app.packageName),
            );
          }

          if (index >= categoryState.categories.length) {
            return const SizedBox.shrink();
          }

          final category = categoryState.categories[index];
          final apps = categoryState.categorizedApps[category.id] ?? [];

          if (apps.isEmpty) return const SizedBox.shrink();

          return CategorySection(
            categoryName: category.name,
            icon: _getIconData(category.icon),
            color: Color(category.colorValue),
            apps: apps,
            appCount: apps.length,
            onTap: (app) => _showAppOptions(context, ref, app.packageName),
            onReorder: (oldIndex, newIndex) {
              // 拖拽排序
            },
          );
        },
      ),
    );
  }

  Widget? _buildFab(
    BuildContext context,
    WidgetRef ref,
    AppListState appListState,
    SettingsState settingsState,
    ClassificationState classificationState,
  ) {
    if (appListState.apps.isEmpty) return null;

    // 分类进行中，不显示 FAB（显示进度覆盖层）
    if (classificationState.isRunning) return null;

    return FloatingActionButton.extended(
      onPressed: () => _startClassification(ref),
      icon: const Icon(Icons.auto_awesome),
      label: const Text('AI 分类'),
    );
  }

  void _startClassification(WidgetRef ref) {
    final settings = ref.read(settingsProvider).settings;
    final appList = ref.read(appListProvider).apps;
    final categories = ref.read(categoryProvider).categories;

    if (!settings.aiConfig.isValid) return;

    ref.read(classificationProvider.notifier).startClassification(
          appList,
          settings.aiConfig,
          categories,
        );
  }

  void _showAppOptions(BuildContext context, WidgetRef ref, String packageName) {
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
                _openApp(packageName);
              },
            ),
            ListTile(
              leading: const Icon(Icons.category),
              title: const Text('移动分类'),
              onTap: () {
                Navigator.pop(ctx);
                _showCategoryPicker(context, ref, packageName);
              },
            ),
            ListTile(
              leading: const Icon(Icons.info_outline),
              title: const Text('应用详情'),
              onTap: () {
                Navigator.pop(ctx);
                _openAppSettings(packageName);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showCategoryPicker(BuildContext context, WidgetRef ref, String packageName) {
    final categories = ref.read(categoryProvider).categories;
    showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text('选择分类', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ),
            ...categories.map((cat) => ListTile(
                  leading: Icon(_getIconData(cat.icon), color: Color(cat.colorValue)),
                  title: Text(cat.name),
                  onTap: () {
                    Navigator.pop(ctx);
                    ref.read(categoryProvider.notifier).moveAppToCategory(packageName, cat.id);
                  },
                )),
            ListTile(
              leading: const Icon(Icons.clear),
              title: const Text('移除分类'),
              onTap: () {
                Navigator.pop(ctx);
                ref.read(categoryProvider.notifier).removeAppCategory(packageName);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _openApp(String packageName) {
    // 通过平台通道打开应用
  }

  void _openAppSettings(String packageName) {
    // 打开应用详情设置
  }

  IconData _getIconData(String iconName) {
    switch (iconName) {
      case 'chat':
        return Icons.chat;
      case 'work':
        return Icons.work;
      case 'play_circle':
        return Icons.play_circle;
      case 'sports_esports':
        return Icons.sports_esports;
      case 'build':
        return Icons.build;
      case 'school':
        return Icons.school;
      case 'shopping_cart':
        return Icons.shopping_cart;
      case 'favorite':
        return Icons.favorite;
      case 'directions_car':
        return Icons.directions_car;
      case 'account_balance':
        return Icons.account_balance;
      default:
        return Icons.apps;
    }
  }
}
