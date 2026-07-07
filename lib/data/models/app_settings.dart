import 'package:equatable/equatable.dart';
import '../../core/constants.dart';

/// AI 配置
class AiConfig extends Equatable {
  final AiProviderType provider;
  final String apiKey;
  final String baseUrl;
  final String model;

  const AiConfig({
    this.provider = AiProviderType.openai,
    this.apiKey = '',
    this.baseUrl = '',
    this.model = '',
  });

  @override
  List<Object?> get props => [provider, apiKey, baseUrl, model];

  /// 获取有效的 baseUrl
  String get effectiveBaseUrl => baseUrl.isNotEmpty ? baseUrl : provider.defaultBaseUrl;

  /// 获取有效的 model
  String get effectiveModel => model.isNotEmpty ? model : provider.defaultModel;

  /// 是否为有效的配置
  bool get isValid => apiKey.isNotEmpty;

  /// 创建副本
  AiConfig copyWith({
    AiProviderType? provider,
    String? apiKey,
    String? baseUrl,
    String? model,
  }) {
    return AiConfig(
      provider: provider ?? this.provider,
      apiKey: apiKey ?? this.apiKey,
      baseUrl: baseUrl ?? this.baseUrl,
      model: model ?? this.model,
    );
  }

  /// 从 JSON 创建
  factory AiConfig.fromJson(Map<String, dynamic> json) {
    return AiConfig(
      provider: AiProviderType.values.firstWhere(
        (e) => e.name == json['provider'],
        orElse: () => AiProviderType.openai,
      ),
      apiKey: json['apiKey'] as String? ?? '',
      baseUrl: json['baseUrl'] as String? ?? '',
      model: json['model'] as String? ?? '',
    );
  }

  /// 转为 JSON
  Map<String, dynamic> toJson() {
    return {
      'provider': provider.name,
      'apiKey': apiKey,
      'baseUrl': baseUrl,
      'model': model,
    };
  }
}

/// 应用设置
class AppSettings extends Equatable {
  final AiConfig aiConfig;
  final ThemeModeOption themeMode;
  final bool includeSystemApps;
  final bool firstLaunchDone;

  const AppSettings({
    this.aiConfig = const AiConfig(),
    this.themeMode = ThemeModeOption.system,
    this.includeSystemApps = false,
    this.firstLaunchDone = false,
  });

  @override
  List<Object?> get props => [aiConfig, themeMode, includeSystemApps, firstLaunchDone];

  /// 创建副本
  AppSettings copyWith({
    AiConfig? aiConfig,
    ThemeModeOption? themeMode,
    bool? includeSystemApps,
    bool? firstLaunchDone,
  }) {
    return AppSettings(
      aiConfig: aiConfig ?? this.aiConfig,
      themeMode: themeMode ?? this.themeMode,
      includeSystemApps: includeSystemApps ?? this.includeSystemApps,
      firstLaunchDone: firstLaunchDone ?? this.firstLaunchDone,
    );
  }
}
