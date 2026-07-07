import 'dart:convert';
import 'package:dio/dio.dart';
import '../../core/constants.dart';
import '../../data/models/app_info.dart';
import '../../data/models/app_category.dart';
import 'ai_service.dart';
import 'app_classification.dart';

/// OpenAI 兼容接口的 AI 服务实现
///
/// 适用于：
/// - OpenAI (GPT-4, GPT-3.5)
/// - DeepSeek
/// - 任何 OpenAI 兼容 API
class OpenAIService implements AIService {
  final String apiKey;
  final String baseUrl;
  final String model;
  final Dio _dio;

  OpenAIService({
    required this.apiKey,
    required this.baseUrl,
    required this.model,
  }) : _dio = Dio(BaseOptions(
          connectTimeout: const Duration(seconds: 15),
          receiveTimeout: const Duration(seconds: AppConstants.aiTimeoutSeconds),
          headers: {
            'Authorization': 'Bearer $apiKey',
            'Content-Type': 'application/json',
          },
        ));

  @override
  String get displayName => 'OpenAI ($model)';

  @override
  Future<List<AppClassification>> classifyApps(
    List<AppInfo> apps, {
    List<AppCategory>? categories,
  }) async {
    if (apps.isEmpty) return [];

    final categoryNames = categories
            ?.map((c) => c.name)
            .toList() ??
        AppConstants.defaultCategories.map((c) => c['name']!).toList();

    final prompt = buildPrompt(apps, categoryNames);

    try {
      final response = await _dio.post(
        '$baseUrl/v1/chat/completions',
        data: {
          'model': model,
          'messages': [
            {
              'role': 'system',
              'content':
                  '你是一个 Android 应用分类助手。请根据应用名称将应用分类到合适的类别中。'
                  '只返回 JSON 数组，不要包含其他文字。',
            },
            {'role': 'user', 'content': prompt},
          ],
          'temperature': 0.3,
          'max_tokens': 4096,
        },
      );

      final content = response.data['choices']?[0]?['message']?['content'] as String?;
      if (content == null) {
        return const ClassificationResult.error('AI 响应为空').classifications;
      }

      final result = parseResponse(content, apps);
      if (!result.isSuccess) {
        throw Exception(result.errorMessage);
      }
      return result.classifications;
    } on DioException catch (e) {
      throw Exception('AI 请求失败: ${e.message}');
    }
  }

  @override
  String buildPrompt(List<AppInfo> apps, List<String> categoryNames) {
    final categoriesStr = categoryNames.join('、');

    final appsStr = apps.map((app) {
      return '- ${app.packageName} (${app.appName})';
    }).join('\n');

    return '''请将以下 Android 应用分类到这些类别中：$categoriesStr

应用列表：
$appsStr

请为每个应用返回 JSON 数组，格式：
[
  {
    "package": "com.example.app",
    "appName": "应用名称",
    "category": "分类名",
    "reason": "简短分类原因"
  }
]

注意：
1. category 必须从给定的类别中选择
2. 如果某个应用不适合任何给定类别，请选择最接近的
3. 返回有效的 JSON，不要包含 markdown 代码块标记''';
  }

  @override
  ClassificationResult parseResponse(String responseBody, List<AppInfo> apps) {
    try {
      // 清理响应：去除 markdown 代码块标记
      var cleaned = responseBody.trim();
      if (cleaned.startsWith('```')) {
        cleaned = cleaned.replaceAll(RegExp(r'^```(?:json)?\s*', multiLine: true), '');
        cleaned = cleaned.replaceAll(RegExp(r'\s*```$', multiLine: true), '');
      }
      cleaned = cleaned.trim();

      final List<dynamic> jsonList = json.decode(cleaned) as List<dynamic>;
      final classifications = jsonList
          .map((item) => AppClassification.fromJson(item as Map<String, dynamic>))
          .toList();

      return ClassificationResult(classifications: classifications);
    } catch (e) {
      // 解析失败，尝试按应用逐行匹配
      try {
        final fallback = _fallbackParse(responseBody, apps);
        return ClassificationResult(classifications: fallback);
      } catch (_) {
        return ClassificationResult.error('AI 响应解析失败: $e');
      }
    }
  }

  /// 兜底解析：当 JSON 解析失败时尝试从文本中提取分类
  List<AppClassification> _fallbackParse(String text, List<AppInfo> apps) {
    final classifications = <AppClassification>[];
    final lines = text.split('\n');

    for (final app in apps) {
      String? category;
      for (final line in lines) {
        if (line.contains(app.packageName) || line.contains(app.appName)) {
          // 尝试提取冒号后的内容作为分类
          final parts = line.split(':');
          if (parts.length >= 2) {
            category = parts.last.trim().replaceAll(RegExp(r'[",\]}]'), '');
          }
          break;
        }
      }
      classifications.add(AppClassification(
        packageName: app.packageName,
        appName: app.appName,
        categoryName: category ?? '其他',
      ));
    }

    return classifications;
  }
}
