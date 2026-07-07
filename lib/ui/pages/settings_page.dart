import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants.dart';
import '../../data/models/app_settings.dart';
import '../../providers/settings_provider.dart';
import '../widgets/category_edit_dialog.dart';
import '../../providers/category_provider.dart';
import '../../providers/app_list_provider.dart';

/// 设置页面
class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settingsState = ref.watch(settingsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('设置'),
      ),
      body: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // AI 配置卡片
                _buildSectionHeader(context, 'AI 服务配置'),
                const SizedBox(height: 8),
                _buildAiConfigCard(context, ref, settingsState),
                const SizedBox(height: 24),

                // 外观设置
                _buildSectionHeader(context, '外观'),
                const SizedBox(height: 8),
                _buildThemeCard(context, ref, settingsState),
                const SizedBox(height: 24),

                // 应用管理
                _buildSectionHeader(context, '应用管理'),
                const SizedBox(height: 8),
                _buildAppManagementCard(context, ref, settingsState),
                const SizedBox(height: 24),

                // 分类管理
                _buildSectionHeader(context, '分类管理'),
                const SizedBox(height: 8),
                _buildCategoryCard(context, ref),
                const SizedBox(height: 24),

                // 关于
                _buildSectionHeader(context, '关于'),
                const SizedBox(height: 8),
                _buildAboutCard(context),
              ],
            ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    return Text(
      title,
      style: Theme.of(context).textTheme.titleMedium?.copyWith(
            color: Theme.of(context).colorScheme.primary,
            fontWeight: FontWeight.w600,
          ),
    );
  }

  Widget _buildAiConfigCard(BuildContext context, WidgetRef ref, SettingsState state) {
    final aiConfig = state.settings.aiConfig;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // AI 服务商选择
            DropdownButtonFormField<AiProviderType>(
              initialValue: aiConfig.provider,
              decoration: const InputDecoration(
                labelText: 'AI 服务商',
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
              items: AiProviderType.values.map((provider) {
                return DropdownMenuItem(
                  value: provider,
                  child: Text(provider.displayName),
                );
              }).toList(),
              onChanged: (value) {
                if (value != null) {
                  final newConfig = AiConfig(
                    provider: value,
                    apiKey: aiConfig.apiKey,
                    baseUrl: value.defaultBaseUrl,
                    model: value.defaultModel,
                  );
                  ref.read(settingsProvider.notifier).updateAiConfig(newConfig);
                }
              },
            ),
            const SizedBox(height: 12),

            // API Key
            TextFormField(
              initialValue: aiConfig.apiKey,
              decoration: InputDecoration(
                labelText: 'API Key',
                border: const OutlineInputBorder(),
                hintText: '输入 ${aiConfig.provider.displayName} API Key',
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                suffixIcon: aiConfig.apiKey.isNotEmpty
                    ? Icon(Icons.check_circle, color: Colors.green)
                    : Icon(Icons.warning, color: Colors.orange),
              ),
              obscureText: true,
              onChanged: (value) {
                final newConfig = aiConfig.copyWith(apiKey: value);
                ref.read(settingsProvider.notifier).updateAiConfig(newConfig);
              },
            ),
            const SizedBox(height: 12),

            // Base URL
            TextFormField(
              initialValue: aiConfig.baseUrl,
              decoration: const InputDecoration(
                labelText: 'Base URL',
                border: OutlineInputBorder(),
                hintText: 'API 基础地址（可选）',
                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
              onChanged: (value) {
                final newConfig = aiConfig.copyWith(baseUrl: value);
                ref.read(settingsProvider.notifier).updateAiConfig(newConfig);
              },
            ),
            const SizedBox(height: 12),

            // 模型名
            TextFormField(
              initialValue: aiConfig.model,
              decoration: const InputDecoration(
                labelText: '模型',
                border: OutlineInputBorder(),
                hintText: '模型名称（可选）',
                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
              onChanged: (value) {
                final newConfig = aiConfig.copyWith(model: value);
                ref.read(settingsProvider.notifier).updateAiConfig(newConfig);
              },
            ),
            const SizedBox(height: 12),

            // 测试连接按钮
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: aiConfig.isValid
                    ? () => _testConnection(context, aiConfig)
                    : null,
                icon: const Icon(Icons.wifi_tethering),
                label: const Text('测试连接'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildThemeCard(BuildContext context, WidgetRef ref, SettingsState state) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 主题选择
            DropdownButtonFormField<ThemeModeOption>(
              initialValue: state.settings.themeMode,
              decoration: const InputDecoration(
                labelText: '主题模式',
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
              items: ThemeModeOption.values.map((mode) {
                return DropdownMenuItem(
                  value: mode,
                  child: Row(
                    children: [
                      Icon(
                        mode == ThemeModeOption.light
                            ? Icons.light_mode
                            : mode == ThemeModeOption.dark
                                ? Icons.dark_mode
                                : Icons.settings_brightness,
                        size: 18,
                      ),
                      const SizedBox(width: 8),
                      Text(mode.displayName),
                    ],
                  ),
                );
              }).toList(),
              onChanged: (value) {
                if (value != null) {
                  ref.read(settingsProvider.notifier).updateThemeMode(value);
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAppManagementCard(BuildContext context, WidgetRef ref, SettingsState state) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 是否显示系统应用
            SwitchListTile(
              title: const Text('显示系统应用'),
              subtitle: const Text('显示 Android 系统预装应用'),
              value: state.settings.includeSystemApps,
              contentPadding: EdgeInsets.zero,
              onChanged: (value) {
                ref.read(settingsProvider.notifier).updateIncludeSystemApps(value);
              },
            ),
            const Divider(),
            // 重新扫描
            ListTile(
              leading: const Icon(Icons.refresh),
              title: const Text('重新扫描应用'),
              subtitle: const Text('重新获取已安装应用列表'),
              contentPadding: EdgeInsets.zero,
              onTap: () {
                ref.read(appListProvider.notifier).refreshApps();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('正在重新扫描应用...')),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryCard(BuildContext context, WidgetRef ref) {
    return Card(
      child: ListTile(
        leading: const Icon(Icons.category),
        title: const Text('管理分类'),
        subtitle: const Text('创建、编辑、删除应用分类'),
        trailing: const Icon(Icons.chevron_right),
        onTap: () => _showCategoryManager(context, ref),
      ),
    );
  }

  Widget _buildAboutCard(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.info_outline),
                SizedBox(width: 8),
                Text('AppSort', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                Spacer(),
                Text('v1.0.0'),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'AI 智能应用分类启动器\n使用 AI 自动整理你的手机应用',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
          ],
        ),
      ),
    );
  }

  void _testConnection(BuildContext context, AiConfig config) {
    // 实际测试连接逻辑
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('测试连接功能需要 Android 环境运行')),
    );
  }

  void _showCategoryManager(BuildContext context, WidgetRef ref) {
    final categories = ref.read(categoryProvider).categories;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        maxChildSize: 0.85,
        minChildSize: 0.3,
        expand: false,
        builder: (ctx, scrollController) => Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('管理分类', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  IconButton(
                    icon: const Icon(Icons.add),
                    onPressed: () => _showCreateCategoryDialog(context, ref),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: ListView.builder(
                controller: scrollController,
                itemCount: categories.length,
                itemBuilder: (ctx, index) {
                  final cat = categories[index];
                  return ListTile(
                    leading: CircleAvatar(
                      backgroundColor: Color(cat.colorValue).withValues(alpha: 0.2),
                      child: Icon(Icons.category, color: Color(cat.colorValue), size: 20),
                    ),
                    title: Text(cat.name),
                    subtitle: Text(cat.isBuiltIn ? '内置分类' : '自定义分类'),
                    trailing: cat.isBuiltIn
                        ? null
                        : IconButton(
                            icon: const Icon(Icons.delete_outline),
                            onPressed: () async {
                              await ref.read(categoryProvider.notifier).deleteCategory(cat.id);
                              if (ctx.mounted) {
                                ScaffoldMessenger.of(ctx).showSnackBar(
                                  SnackBar(content: Text('已删除分类「${cat.name}」')),
                                );
                              }
                            },
                          ),
                    onTap: () => _showEditCategoryDialog(context, ref, cat),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showCreateCategoryDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (ctx) => CategoryEditDialog(
        onSave: (name, icon, color) async {
          await ref.read(categoryProvider.notifier).createCategory(
                name: name,
                icon: icon,
                color: color,
              );
          if (ctx.mounted) {
            ScaffoldMessenger.of(ctx).showSnackBar(
              SnackBar(content: Text('已创建分类「$name」')),
            );
          }
        },
      ),
    );
  }

  void _showEditCategoryDialog(BuildContext context, WidgetRef ref, dynamic category) {
    showDialog(
      context: context,
      builder: (ctx) => CategoryEditDialog(
        initialName: category.name,
        initialIcon: category.icon,
        initialColor: category.color,
        onSave: (name, icon, color) async {
          await ref.read(categoryProvider.notifier).updateCategory(
                category.copyWith(name: name, icon: icon, color: color),
              );
          if (ctx.mounted) {
            ScaffoldMessenger.of(ctx).showSnackBar(
              SnackBar(content: Text('已更新分类「$name」')),
            );
          }
        },
      ),
    );
  }
}
