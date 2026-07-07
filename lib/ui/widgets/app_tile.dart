import 'package:flutter/material.dart';
import '../../services/icon_cache_service.dart';

/// 应用列表图块
class AppTile extends StatelessWidget {
  final String appName;
  final String packageName;
  final String? iconPath;
  final bool isSystemApp;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;

  const AppTile({
    super.key,
    required this.appName,
    required this.packageName,
    this.iconPath,
    this.isSystemApp = false,
    this.onTap,
    this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 2, horizontal: 4),
      child: ListTile(
        leading: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: SizedBox(
            width: 44,
            height: 44,
            child: Image(
            image: IconCacheService.getIcon(iconPath, packageName: packageName),
            width: 44,
            height: 44,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) => Icon(
              Icons.android,
              size: 28,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          ),
        ),
        title: Text(
          appName,
          overflow: TextOverflow.ellipsis,
          maxLines: 1,
        ),
        subtitle: Text(
          packageName,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
          overflow: TextOverflow.ellipsis,
          maxLines: 1,
        ),
        trailing: isSystemApp
            ? Icon(Icons.build, size: 16, color: Theme.of(context).colorScheme.onSurfaceVariant)
            : null,
        onTap: onTap,
        onLongPress: onLongPress,
      ),
    );
  }
}
