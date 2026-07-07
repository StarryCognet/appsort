import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/constants.dart';
import 'settings_provider.dart';

/// 主题模式提供者
///
/// 根据设置提供者的主题配置返回对应的 ThemeMode。
final themeModeProvider = Provider<ThemeMode>((ref) {
  final settings = ref.watch(settingsProvider);
  if (settings.isLoading) return ThemeMode.system;

  switch (settings.settings.themeMode) {
    case ThemeModeOption.system:
      return ThemeMode.system;
    case ThemeModeOption.light:
      return ThemeMode.light;
    case ThemeModeOption.dark:
      return ThemeMode.dark;
  }
});
