import 'dart:convert';
import 'package:dio/dio.dart';
import '../../core/constants.dart';
import '../../data/models/app_info.dart';
import '../../data/models/app_category.dart';
import 'ai_service.dart';
import 'app_classification.dart';

/// Anthropic Claude API 服务实现
class AnthropicService implements AIService {
  final String apiKey;
  final String baseUrl;
  final String model;
  final Dio _dio;

  AnthropicService({
    required this.apiKey,
    required this.baseUrl,
    required this.model,
  }) : _dio = Dio(BaseOptions(
          connectTimeout: const Duration(seconds: 15),
          receiveTimeout: const Duration(seconds: AppConstants.aiTimeoutSeconds),
          headers: {
            'x-api-key': apiKey,
            'anthropic-version': '2023-06-01',
            'Content-Type': 'application/json',
          },
        ));

  @override
  String get displayName => 'Anthropic ($model)';

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
        '$baseUrl/v1/messages',
        data: {
          'model': model,
          'max_tokens': 4096,
          'system': '你是一个 Android 应用分类助手。请根据应用名称将应用分类到合适的类别中。只返回 JSON 数组。',
          'messages': [
            {'role': 'user', 'content': prompt},
          ],
        },
      );

      final content = response.data['content'] as List<dynamic>?;
      if (content == null || content.isEmpty) {
        return const ClassificationResult.error('AI 响应为空').classifications;
      }

      final text = content
          .whereType<Map<String, dynamic>>()
          .map((c) => c['text'] as String?)
          .where((t) => t != null)
          .join('\n');

      if (text.isEmpty) {
        return const ClassificationResult.error('AI 响应文本为空').classifications;
      }

      final result = parseResponse(text, apps);
      if (!result.isSuccess) {
        throw Exception(result.errorMessage);
      }
      return result.classifications;
    } on DioException catch (e) {
      throw Exception('Anthropic 请求失败: ${e.message}');
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
3. 只返回 JSON 数组，不要包含其他文字''';
  }

  @override
  ClassificationResult parseResponse(String responseBody, List<AppInfo> apps) {
    try {
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
      return ClassificationResult.error('Anthropic 响应解析失败: $e');
    }
  }
}
