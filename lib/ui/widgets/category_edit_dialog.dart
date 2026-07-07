import 'package:flutter/material.dart';

/// 分类编辑对话框
///
/// 用于创建或编辑分类。
/// 支持输入名称、选择图标和颜色。
class CategoryEditDialog extends StatefulWidget {
  final String? initialName;
  final String? initialIcon;
  final String? initialColor;
  final Function(String name, String icon, String color) onSave;

  const CategoryEditDialog({
    super.key,
    this.initialName,
    this.initialIcon,
    this.initialColor,
    required this.onSave,
  });

  @override
  State<CategoryEditDialog> createState() => _CategoryEditDialogState();
}

class _CategoryEditDialogState extends State<CategoryEditDialog> {
  late final TextEditingController _nameController;
  String _selectedIcon = 'apps';
  String _selectedColor = '#6750A4';

  static const _colorOptions = [
    '#6750A4', '#4CAF50', '#2196F3', '#FF9800',
    '#9C27B0', '#607D8B', '#00BCD4', '#E91E63',
    '#F44336', '#3F51B5', '#FFC107', '#795548',
  ];

  static const _iconOptions = [
    'apps', 'chat', 'work', 'play_circle',
    'sports_esports', 'build', 'school', 'shopping_cart',
    'favorite', 'directions_car', 'account_balance', 'music_note',
    'photo_camera', 'book', 'flight', 'restaurant',
  ];

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.initialName ?? '');
    _selectedIcon = widget.initialIcon ?? 'apps';
    _selectedColor = widget.initialColor ?? '#6750A4';
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isEdit = widget.initialName != null;

    return AlertDialog(
      title: Text(isEdit ? '编辑分类' : '新建分类'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 分类名称
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: '分类名称',
                border: OutlineInputBorder(),
              ),
              autofocus: !isEdit,
            ),
            const SizedBox(height: 16),

            // 颜色选择
            Text('颜色', style: theme.textTheme.labelMedium),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _colorOptions.map((colorStr) {
                final color = Color(int.parse('FF${colorStr.replaceFirst('#', '')}', radix: 16));
                final isSelected = _selectedColor == colorStr;
                return GestureDetector(
                  onTap: () => setState(() => _selectedColor = colorStr),
                  child: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                      border: isSelected
                          ? Border.all(color: theme.colorScheme.onSurface, width: 3)
                          : null,
                      boxShadow: isSelected
                          ? [BoxShadow(color: color.withValues(alpha: 0.4), blurRadius: 6)]
                          : null,
                    ),
                    child: isSelected
                        ? const Icon(Icons.check, color: Colors.white, size: 18)
                        : null,
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),

            // 图标选择
            Text('图标', style: theme.textTheme.labelMedium),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _iconOptions.map((iconName) {
                final icon = _getIconData(iconName);
                final isSelected = _selectedIcon == iconName;
                return GestureDetector(
                  onTap: () => setState(() => _selectedIcon = iconName),
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: isSelected
                          ? Color(int.parse('FF${_selectedColor.replaceFirst('#', '')}',
                                  radix: 16))
                              .withValues(alpha: 0.15)
                          : theme.colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(10),
                      border: isSelected
                          ? Border.all(
                              color: Color(int.parse('FF${_selectedColor.replaceFirst('#', '')}',
                                  radix: 16)),
                              width: 2)
                          : null,
                    ),
                    child: Icon(
                      icon,
                      size: 20,
                      color: isSelected
                          ? Color(int.parse('FF${_selectedColor.replaceFirst('#', '')}',
                                  radix: 16))
                          : null,
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
          onPressed: () => Navigator.pop(context),
          child: const Text('取消'),
        ),
        FilledButton(
          onPressed: () {
            final name = _nameController.text.trim();
            if (name.isEmpty) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('请输入分类名称')),
              );
              return;
            }
            widget.onSave(name, _selectedIcon, _selectedColor);
            Navigator.pop(context);
          },
          child: Text(isEdit ? '保存' : '创建'),
        ),
      ],
    );
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
      case 'music_note':
        return Icons.music_note;
      case 'photo_camera':
        return Icons.photo_camera;
      case 'book':
        return Icons.book;
      case 'flight':
        return Icons.flight;
      case 'restaurant':
        return Icons.restaurant;
      default:
        return Icons.apps;
    }
  }
}
