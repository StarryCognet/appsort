import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/models/app_settings.dart';
import '../services/settings_service.dart';
import '../core/constants.dart';

/// 初始设置值（在 main() 中注入）
final initialSettingsProvider = Provider<AppSettings>((ref) {
  return const AppSettings();
});

/// 设置状态
class SettingsState {
  final AppSettings settings;
  final bool isLoading;
  final String? error;

  const SettingsState({
    this.settings = const AppSettings(),
    this.isLoading = false,
    this.error,
  });

  SettingsState copyWith({
    AppSettings? settings,
    bool? isLoading,
    String? error,
  }) {
    return SettingsState(
      settings: settings ?? this.settings,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

/// 设置提供者
class SettingsNotifier extends StateNotifier<SettingsState> {
  SettingsNotifier() : super(const SettingsState());

  /// 使用初始值初始化（从 main() 传入）
  void init(AppSettings settings) {
    state = SettingsState(settings: settings, isLoading: false);
  }

  /// 更新 AI 配置
  Future<void> updateAiConfig(AiConfig config) async {
    final newSettings = state.settings.copyWith(aiConfig: config);
    await SettingsService.saveSettings(newSettings);
    state = state.copyWith(settings: newSettings);
  }

  /// 更新主题模式
  Future<void> updateThemeMode(ThemeModeOption mode) async {
    final newSettings = state.settings.copyWith(themeMode: mode);
    await SettingsService.saveSettings(newSettings);
    state = state.copyWith(settings: newSettings);
  }

  /// 更新系统应用显示
  Future<void> updateIncludeSystemApps(bool value) async {
    final newSettings = state.settings.copyWith(includeSystemApps: value);
    await SettingsService.saveSettings(newSettings);
    state = state.copyWith(settings: newSettings);
  }

  /// 标记首次启动完成
  Future<void> completeFirstLaunch() async {
    await SettingsService.setFirstLaunchDone();
    final newSettings = state.settings.copyWith(firstLaunchDone: true);
    state = state.copyWith(settings: newSettings);
  }
}

final settingsProvider = StateNotifierProvider<SettingsNotifier, SettingsState>((ref) {
  final notifier = SettingsNotifier();
  // 从 main() 注入的初始值初始化
  final initial = ref.read(initialSettingsProvider);
  notifier.init(initial);
  return notifier;
});
