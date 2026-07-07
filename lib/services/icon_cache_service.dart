import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import '../core/constants.dart';

/// 图标缓存服务
///
/// 将应用图标缓存到本地文件系统，
/// 加速后续启动时的加载速度。
class IconCacheService {
  static final Map<String, ImageProvider> _memoryCache = {};
  static String? _cacheDir;

  /// 初始化缓存目录
  static Future<String> get cacheDir async {
    if (_cacheDir != null) return _cacheDir!;
    final appDir = await getApplicationDocumentsDirectory();
    _cacheDir = p.join(appDir.path, AppConstants.iconCacheDir);
    final dir = Directory(_cacheDir!);
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    return _cacheDir!;
  }

  /// 保存图标到文件缓存
  ///
  /// [packageName] 应用包名
  /// [bytes] 图标 PNG 字节数据
  /// 返回缓存文件路径
  static Future<String?> saveIcon(String packageName, List<int> bytes) async {
    try {
      final dir = await cacheDir;
      final filePath = p.join(dir, '${packageName.replaceAll('.', '_')}.png');
      final file = File(filePath);
      await file.writeAsBytes(bytes);
      return filePath;
    } catch (e) {
      return null;
    }
  }

  /// 获取图标
  ///
  /// 优先从内存缓存加载，其次从文件缓存，最后返回默认图标。
  static ImageProvider getIcon(String? iconPath, {String? packageName}) {
    // 内存缓存命中
    if (iconPath != null && _memoryCache.containsKey(iconPath)) {
      return _memoryCache[iconPath]!;
    }

    // 文件缓存存在
    if (iconPath != null && File(iconPath).existsSync()) {
      final provider = FileImage(File(iconPath));
      // 写入内存缓存（如果没满）
      if (_memoryCache.length < AppConstants.iconMemoryCacheLimit) {
        _memoryCache[iconPath] = provider;
      }
      return provider;
    }

    // 返回默认图标
    return const AssetImage('assets/ic_launcher.png');
  }

  /// 从文件加载图标到内存缓存
  static ImageProvider? loadIconFromFile(String iconPath) {
    if (!File(iconPath).existsSync()) return null;
    final provider = FileImage(File(iconPath));
    if (_memoryCache.length < AppConstants.iconMemoryCacheLimit) {
      _memoryCache[iconPath] = provider;
    }
    return provider;
  }

  /// 预热图标（批量加载到内存）
  static Future<void> preloadIcons(List<String> iconPaths) async {
    for (final path in iconPaths) {
      if (path.isEmpty || _memoryCache.containsKey(path)) continue;
      if (_memoryCache.length >= AppConstants.iconMemoryCacheLimit) break;
      final file = File(path);
      if (await file.exists()) {
        _memoryCache[path] = FileImage(file);
      }
    }
  }

  /// 清除所有缓存
  static Future<void> clearCache() async {
    _memoryCache.clear();
    try {
      final dir = await cacheDir;
      final cacheDirObj = Directory(dir);
      if (await cacheDirObj.exists()) {
        await cacheDirObj.delete(recursive: true);
        await cacheDirObj.create(recursive: true);
      }
    } catch (_) {}
  }

  /// 清除单图标缓存
  static void clearIconCache(String? iconPath) {
    if (iconPath != null) {
      _memoryCache.remove(iconPath);
    }
  }
}
