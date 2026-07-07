import 'package:flutter/services.dart';
import '../data/models/app_info.dart';
import 'icon_cache_service.dart';

/// 已安装应用服务
///
/// 通过 MethodChannel 与 Android 原生通信，
/// 获取已安装应用列表、图标并打开应用。
class InstalledAppsService {
  static const _channel = MethodChannel('com.starryflow.appsort/apps');

  /// 获取所有已安装应用
  ///
  /// [includeSystemApps] 是否包含系统应用
  /// 返回 [AppInfo] 列表
  static Future<List<AppInfo>> getInstalledApps({
    bool includeSystemApps = false,
  }) async {
    try {
      final result = await _channel.invokeMethod('getInstalledApps', {
        'includeSystemApps': includeSystemApps,
      });

      if (result == null) return [];

      final List<dynamic> appsList = result as List<dynamic>;
      final apps = <AppInfo>[];

      for (final item in appsList) {
        final map = item as Map<String, dynamic>;
        final packageName = map['packageName'] as String;
        final appName = map['appName'] as String? ?? packageName;
        final iconBytes = map['iconBytes'] as List<dynamic>?;

        // 保存图标到缓存
        String? iconPath;
        if (iconBytes != null && iconBytes.isNotEmpty) {
          iconPath = await IconCacheService.saveIcon(
            packageName,
            iconBytes.cast<int>(),
          );
        }

        apps.add(AppInfo(
          packageName: packageName,
          appName: appName,
          versionName: map['versionName'] as String? ?? '',
          versionCode: (map['versionCode'] as num?)?.toInt() ?? 0,
          isSystemApp: map['isSystemApp'] as bool? ?? false,
          iconPath: iconPath,
        ));
      }

      return apps;
    } on MissingPluginException {
      // 非 Android 平台或插件未注册
      return [];
    } catch (e) {
      throw Exception('获取已安装应用失败: $e');
    }
  }

  /// 获取单个应用图标字节
  static Future<Uint8List?> getAppIcon(String packageName) async {
    try {
      final result = await _channel.invokeMethod('getAppIcon', {
        'packageName': packageName,
      });
      if (result == null) return null;
      return (result as List<dynamic>).cast<int>().toList() as Uint8List?;
    } catch (e) {
      return null;
    }
  }

  /// 打开应用
  static Future<bool> openApp(String packageName) async {
    try {
      await _channel.invokeMethod('openApp', {
        'packageName': packageName,
      });
      return true;
    } catch (e) {
      return false;
    }
  }

  /// 在应用商店查看应用
  static Future<bool> openAppStore(String packageName) async {
    try {
      await _channel.invokeMethod('openAppStore', {
        'packageName': packageName,
      });
      return true;
    } catch (e) {
      return false;
    }
  }

  /// 打开应用详情设置
  static Future<bool> openAppSettings(String packageName) async {
    try {
      await _channel.invokeMethod('openAppSettings', {
        'packageName': packageName,
      });
      return true;
    } catch (e) {
      return false;
    }
  }
}
