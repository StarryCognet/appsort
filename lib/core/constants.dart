/// AppSort 常量定义
class AppConstants {
  AppConstants._();

  /// 应用名
  static const String appName = 'AppSort';

  /// 数据库名
  static const String databaseName = 'appsort.db';

  /// 数据库版本
  static const int databaseVersion = 1;

  /// AI 服务超时时间（秒）
  static const int aiTimeoutSeconds = 30;

  /// AI 分类重试次数
  static const int aiMaxRetries = 2;

  /// 搜索去抖延迟（毫秒）
  static const int searchDebounceMs = 300;

  /// 图标缓存目录名
  static const String iconCacheDir = 'app_icons';

  /// 内存图标缓存上限
  static const int iconMemoryCacheLimit = 100;

  /// 默认分类列表
  static const List<Map<String, String>> defaultCategories = [
    {'name': '社交', 'icon': 'chat', 'color': '#4CAF50'},
    {'name': '效率', 'icon': 'work', 'color': '#2196F3'},
    {'name': '媒体', 'icon': 'play_circle', 'color': '#FF9800'},
    {'name': '游戏', 'icon': 'sports_esports', 'color': '#9C27B0'},
    {'name': '工具', 'icon': 'build', 'color': '#607D8B'},
    {'name': '教育', 'icon': 'school', 'color': '#00BCD4'},
    {'name': '购物', 'icon': 'shopping_cart', 'color': '#E91E63'},
    {'name': '健康', 'icon': 'favorite', 'color': '#F44336'},
    {'name': '出行', 'icon': 'directions_car', 'color': '#3F51B5'},
    {'name': '金融', 'icon': 'account_balance', 'color': '#FFC107'},
    {'name': '其他', 'icon': 'apps', 'color': '#9E9E9E'},
  ];

  /// AI 服务商默认配置
  static const Map<String, Map<String, String>> aiProviderDefaults = {
    'openai': {
      'baseUrl': 'https://api.openai.com',
      'model': 'gpt-4o-mini',
    },
    'anthropic': {
      'baseUrl': 'https://api.anthropic.com',
      'model': 'claude-3-haiku-20240307',
    },
    'gemini': {
      'baseUrl': 'https://generativelanguage.googleapis.com',
      'model': 'gemini-2.0-flash',
    },
    'deepseek': {
      'baseUrl': 'https://api.deepseek.com',
      'model': 'deepseek-chat',
    },
  };
}

/// AI 服务商枚举
enum AiProviderType {
  openai,
  anthropic,
  gemini,
  deepseek,
  custom;

  String get displayName {
    switch (this) {
      case AiProviderType.openai:
        return 'OpenAI';
      case AiProviderType.anthropic:
        return 'Anthropic';
      case AiProviderType.gemini:
        return 'Google Gemini';
      case AiProviderType.deepseek:
        return 'DeepSeek';
      case AiProviderType.custom:
        return '自定义(OpenAI 兼容)';
    }
  }

  String get defaultBaseUrl {
    switch (this) {
      case AiProviderType.openai:
        return 'https://api.openai.com';
      case AiProviderType.anthropic:
        return 'https://api.anthropic.com';
      case AiProviderType.gemini:
        return 'https://generativelanguage.googleapis.com';
      case AiProviderType.deepseek:
        return 'https://api.deepseek.com';
      case AiProviderType.custom:
        return '';
    }
  }

  String get defaultModel {
    switch (this) {
      case AiProviderType.openai:
        return 'gpt-4o-mini';
      case AiProviderType.anthropic:
        return 'claude-3-haiku-20240307';
      case AiProviderType.gemini:
        return 'gemini-2.0-flash';
      case AiProviderType.deepseek:
        return 'deepseek-chat';
      case AiProviderType.custom:
        return '';
    }
  }
}

/// 主题模式枚举
enum ThemeModeOption {
  system,
  light,
  dark;

  String get displayName {
    switch (this) {
      case ThemeModeOption.system:
        return '跟随系统';
      case ThemeModeOption.light:
        return '浅色';
      case ThemeModeOption.dark:
        return '深色';
    }
  }
}
