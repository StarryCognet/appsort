import '../../data/models/app_settings.dart';
import '../../core/constants.dart';
import 'ai_service.dart';
import 'openai_service.dart';
import 'anthropic_service.dart';
import 'gemini_service.dart';

/// AI 服务工厂
///
/// 根据配置返回对应的 AI 服务实现。
/// DeepSeek 和自定义服务使用 OpenAI 兼容接口。
class AIServiceFactory {
  /// 根据配置创建 AI 服务实例
  static AIService create(AiConfig config) {
    switch (config.provider) {
      case AiProviderType.openai:
      case AiProviderType.deepseek:
      case AiProviderType.custom:
        // OpenAI、DeepSeek、自定义都使用 OpenAI 兼容接口
        return OpenAIService(
          apiKey: config.apiKey,
          baseUrl: config.effectiveBaseUrl,
          model: config.effectiveModel,
        );
      case AiProviderType.anthropic:
        return AnthropicService(
          apiKey: config.apiKey,
          baseUrl: config.effectiveBaseUrl,
          model: config.effectiveModel,
        );
      case AiProviderType.gemini:
        return GeminiService(
          apiKey: config.apiKey,
          baseUrl: config.effectiveBaseUrl,
          model: config.effectiveModel,
        );
    }
  }
}
