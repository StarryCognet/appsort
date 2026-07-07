import '../../data/models/app_info.dart';
import '../../data/models/app_category.dart';
import 'app_classification.dart';

/// AI 服务抽象接口
///
/// 所有 AI 服务商需实现此接口。
/// 支持 OpenAI、Anthropic、Gemini、DeepSeek 等。
abstract class AIService {
  /// 服务商显示名称
  String get displayName;

  /// 对应用列表进行分类
  ///
  /// [apps] - 需要分类的应用列表
  /// [categories] - 可选的分类列表，如不提供则使用默认分类
  /// 返回 [AppClassification] 列表
  Future<List<AppClassification>> classifyApps(
    List<AppInfo> apps, {
    List<AppCategory>? categories,
  });

  /// 构建分类提示词
  String buildPrompt(List<AppInfo> apps, List<String> categoryNames);

  /// 解析 AI 响应为分类结果
  ClassificationResult parseResponse(String responseBody, List<AppInfo> apps);
}
