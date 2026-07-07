import 'package:flutter/material.dart';
import '../../providers/classification_provider.dart';

/// AI 分类进度组件
class ClassificationProgressWidget extends StatelessWidget {
  final ClassificationState state;
  final VoidCallback? onCancel;

  const ClassificationProgressWidget({
    super.key,
    required this.state,
    this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 动画图标
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.0, end: 1.0),
              duration: const Duration(milliseconds: 1200),
              builder: (context, value, child) {
                return Transform.scale(
                  scale: 0.8 + (0.2 * value),
                  child: Opacity(
                    opacity: value,
                    child: Icon(
                      Icons.auto_awesome,
                      size: 64,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 24),

            // 进度条
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: state.progress > 0 ? state.progress : null,
                minHeight: 8,
                backgroundColor: theme.colorScheme.surfaceContainerHighest,
                valueColor: AlwaysStoppedAnimation(theme.colorScheme.primary),
              ),
            ),
            const SizedBox(height: 16),

            // 进度文本
            Text(
              '${(state.progress * 100).toInt()}%',
              style: theme.textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.primary,
              ),
            ),
            const SizedBox(height: 8),

            // 处理计数
            Text(
              '${state.processedCount} / ${state.totalCount}',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 12),

            // 当前任务描述
            Text(
              state.currentTask,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 32),

            // 取消按钮
            if (state.isRunning)
              OutlinedButton.icon(
                onPressed: onCancel,
                icon: const Icon(Icons.stop),
                label: const Text('取消'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: theme.colorScheme.error,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
