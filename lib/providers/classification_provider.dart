import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/models/app_info.dart';
import '../data/models/app_category.dart';
import '../data/models/app_settings.dart';
import '../data/database_helper.dart';
import '../services/ai/ai_service_factory.dart';

/// AI 分类状态
enum ClassificationStatus { idle, running, done, error }

/// 分类进度状态
class ClassificationState {
  final ClassificationStatus status;
  final double progress;
  final String currentTask;
  final String? errorMessage;
  final int processedCount;
  final int totalCount;
  final bool isCancelled;

  const ClassificationState({
    this.status = ClassificationStatus.idle,
    this.progress = 0.0,
    this.currentTask = '',
    this.errorMessage,
    this.processedCount = 0,
    this.totalCount = 0,
    this.isCancelled = false,
  });

  ClassificationState copyWith({
    ClassificationStatus? status,
    double? progress,
    String? currentTask,
    String? errorMessage,
    int? processedCount,
    int? totalCount,
    bool? isCancelled,
  }) {
    return ClassificationState(
      status: status ?? this.status,
      progress: progress ?? this.progress,
      currentTask: currentTask ?? this.currentTask,
      errorMessage: errorMessage,
      processedCount: processedCount ?? this.processedCount,
      totalCount: totalCount ?? this.totalCount,
      isCancelled: isCancelled ?? this.isCancelled,
    );
  }

  /// 是否正在运行
  bool get isRunning => status == ClassificationStatus.running;
}

/// AI 分类提供者
class ClassificationNotifier extends StateNotifier<ClassificationState> {
  ClassificationNotifier() : super(const ClassificationState());

  /// 开始分类
  Future<void> startClassification(
    List<AppInfo> apps,
    AiConfig aiConfig,
    List<AppCategory> categories,
  ) async {
    if (apps.isEmpty) {
      state = state.copyWith(
        status: ClassificationStatus.done,
        progress: 1.0,
      );
      return;
    }

    state = ClassificationState(
      status: ClassificationStatus.running,
      totalCount: apps.length,
      currentTask: '正在初始化 AI 服务...',
    );

    try {
      // 创建 AI 服务
      final aiService = AIServiceFactory.create(aiConfig);

      state = state.copyWith(
        currentTask: '正在发送 ${apps.length} 个应用到 AI 进行分类...',
      );

      // 分批处理（AI 有 token 限制，每次最多处理 50 个应用）
      const batchSize = 50;
      final totalBatches = (apps.length / batchSize).ceil();
      var processedCount = 0;
      var lastError = '';

      for (int i = 0; i < apps.length; i += batchSize) {
        // 检查是否取消
        if (state.isCancelled) {
          state = state.copyWith(status: ClassificationStatus.idle, currentTask: '已取消');
          return;
        }

        final end = (i + batchSize > apps.length) ? apps.length : i + batchSize;
        final batch = apps.sublist(i, end);
        final batchNum = (i ~/ batchSize) + 1;
        const retryCount = 2; // 最大重试次数

        // 重试循环
        for (int attempt = 0; attempt <= retryCount; attempt++) {
          try {
            if (state.isCancelled) {
              state = state.copyWith(status: ClassificationStatus.idle, currentTask: '已取消');
              return;
            }

            state = state.copyWith(
              currentTask: attempt > 0
                  ? '第 $batchNum/$totalBatches 批处理中（第 ${attempt + 1} 次重试）...'
                  : '正在处理第 $batchNum/$totalBatches 批 (${batch.first.appName}~${batch.last.appName})...',
            );

            final classifications = await aiService.classifyApps(
              batch,
              categories: categories,
            );

            // 保存分类结果
            for (final classification in classifications) {
              // 根据分类名查找对应的 categoryId
              final categoryId = _findCategoryId(classification.categoryName, categories);
              await DatabaseHelper.updateAppCategory(
                classification.packageName,
                categoryId,
              );
            }

            processedCount += batch.length;
            state = state.copyWith(
              progress: processedCount / apps.length,
              processedCount: processedCount,
            );

            lastError = '';
            break; // 成功，跳出重试循环
          } catch (e) {
            lastError = e.toString();
            if (attempt < retryCount) {
              // 短暂等待后重试
              await Future.delayed(const Duration(seconds: 2));
            }
          }
        }

        // 如果所有重试都失败
        if (lastError.isNotEmpty) {
          // 继续处理下一批，但记录错误
          processedCount += batch.length;
          state = state.copyWith(
            progress: processedCount / apps.length,
            processedCount: processedCount,
          );
        }
      }

      state = ClassificationState(
        status: ClassificationStatus.done,
        progress: 1.0,
        totalCount: apps.length,
        processedCount: processedCount,
        currentTask: lastError.isNotEmpty
            ? '分类完成（部分分类可能失败: $lastError）'
            : '分类完成！',
      );
    } catch (e) {
      state = ClassificationState(
        status: ClassificationStatus.error,
        errorMessage: e.toString(),
        currentTask: '分类失败: $e',
        totalCount: apps.length,
        processedCount: state.processedCount,
      );
    }
  }

  /// 根据分类名查找 categoryId
  String? _findCategoryId(String categoryName, List<AppCategory> categories) {
    for (final cat in categories) {
      if (cat.name == categoryName) {
        return cat.id;
      }
    }
    return null;
  }

  /// 取消分类
  void cancel() {
    state = state.copyWith(isCancelled: true);
  }

  /// 重置状态
  void reset() {
    state = const ClassificationState();
  }
}

final classificationProvider =
    StateNotifierProvider<ClassificationNotifier, ClassificationState>((ref) {
  return ClassificationNotifier();
});
