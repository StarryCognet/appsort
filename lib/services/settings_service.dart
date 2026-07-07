import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../data/models/app_settings.dart';
import '../core/constants.dart';

/// 设置服务
///
/// 使用 SharedPreferences 存储应用设置。
class SettingsService {
  static const _keyAiConfig = 'ai_config';
  static const _keyThemeMode = 'theme_mode';
  static const _keyIncludeSystemApps = 'include_system_apps';
  static const _keyFirstLaunchDone = 'first_launch_done';

  /// 获取所有设置
  static Future<AppSettings> getSettings() async {
    final prefs = await SharedPreferences.getInstance();

    // AI 配置
    final aiConfigJson = prefs.getString(_keyAiConfig);
    final aiConfig = aiConfigJson != null
        ? AiConfig.fromJson(json.decode(aiConfigJson) as Map<String, dynamic>)
        : const AiConfig();

    // 主题模式
    final themeModeStr = prefs.getString(_keyThemeMode) ?? 'system';
    final themeMode = ThemeModeOption.values.firstWhere(
      (e) => e.name == themeModeStr,
      orElse: () => ThemeModeOption.system,
    );

    return AppSettings(
      aiConfig: aiConfig,
      themeMode: themeMode,
      includeSystemApps: prefs.getBool(_keyIncludeSystemApps) ?? false,
      firstLaunchDone: prefs.getBool(_keyFirstLaunchDone) ?? false,
    );
  }

  /// 保存完整设置
  static Future<void> saveSettings(AppSettings settings) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyAiConfig, json.encode(settings.aiConfig.toJson()));
    await prefs.setString(_keyThemeMode, settings.themeMode.name);
    await prefs.setBool(_keyIncludeSystemApps, settings.includeSystemApps);
    await prefs.setBool(_keyFirstLaunchDone, settings.firstLaunchDone);
  }

  /// 保存 AI 配置
  static Future<void> saveAiConfig(AiConfig config) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyAiConfig, json.encode(config.toJson()));
  }

  /// 获取 AI 配置
  static Future<AiConfig> getAiConfig() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonStr = prefs.getString(_keyAiConfig);
    if (jsonStr == null) return const AiConfig();
    return AiConfig.fromJson(json.decode(jsonStr) as Map<String, dynamic>);
  }

  /// 保存主题模式
  static Future<void> saveThemeMode(ThemeModeOption mode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyThemeMode, mode.name);
  }

  /// 获取主题模式
  static Future<ThemeModeOption> getThemeMode() async {
    final prefs = await SharedPreferences.getInstance();
    final str = prefs.getString(_keyThemeMode) ?? 'system';
    return ThemeModeOption.values.firstWhere(
      (e) => e.name == str,
      orElse: () => ThemeModeOption.system,
    );
  }

  /// 设置首次启动完成
  static Future<void> setFirstLaunchDone() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyFirstLaunchDone, true);
  }
}
