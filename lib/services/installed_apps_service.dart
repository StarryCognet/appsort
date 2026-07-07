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
        // MethodChannel 返回 Map<Object?, Object?>, 需要用 Map.from 安全转换
        final rawMap = Map<String, dynamic>.from(item as Map);
        final packageName = rawMap['packageName'] as String? ?? '';
        if (packageName.isEmpty) continue;
        final appName = rawMap['appName'] as String? ?? packageName;

        // 处理图标字节（来自平台的 List<int>）
        final iconBytes = rawMap['iconBytes'];
        final bytesList = (iconBytes is List ? List<int>.from(iconBytes as List) : null);

        // 保存图标到缓存
        String? iconPath;
        if (bytesList != null && bytesList.isNotEmpty) {
          iconPath = await IconCacheService.saveIcon(packageName, bytesList);
        }

        apps.add(AppInfo(
          packageName: packageName,
          appName: appName,
          versionName: rawMap['versionName'] as String? ?? '',
          versionCode: (rawMap['versionCode'] as num?)?.toInt() ?? 0,
          isSystemApp: rawMap['isSystemApp'] is bool ? (rawMap['isSystemApp'] as bool) : false,
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
      final bytes = List<int>.from(result as List);
      return Uint8List.fromList(bytes);
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
