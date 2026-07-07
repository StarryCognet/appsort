import 'package:equatable/equatable.dart';

/// 已安装应用的实体模型
class AppInfo extends Equatable {
  final String packageName;
  final String appName;
  final String versionName;
  final int versionCode;
  final bool isSystemApp;
  final String? iconPath;
  final String? categoryId;
  final int sortOrder;
  final bool isHidden;

  const AppInfo({
    required this.packageName,
    required this.appName,
    this.versionName = '',
    this.versionCode = 0,
    this.isSystemApp = false,
    this.iconPath,
    this.categoryId,
    this.sortOrder = 0,
    this.isHidden = false,
  });

  @override
  List<Object?> get props => [
        packageName,
        appName,
        versionName,
        versionCode,
        isSystemApp,
        iconPath,
        categoryId,
        sortOrder,
        isHidden,
      ];

  /// 从数据库 Map 创建
  factory AppInfo.fromMap(Map<String, dynamic> map) {
    return AppInfo(
      packageName: map['packageName'] as String,
      appName: map['appName'] as String? ?? '',
      versionName: map['versionName'] as String? ?? '',
      versionCode: (map['versionCode'] as int?) ?? 0,
      isSystemApp: (map['isSystemApp'] as int?) == 1,
      iconPath: map['iconPath'] as String?,
      categoryId: map['categoryId'] as String?,
      sortOrder: (map['sortOrder'] as int?) ?? 0,
      isHidden: (map['isHidden'] as int?) == 1,
    );
  }

  /// 转换为数据库 Map
  Map<String, dynamic> toMap() {
    return {
      'packageName': packageName,
      'appName': appName,
      'versionName': versionName,
      'versionCode': versionCode,
      'isSystemApp': isSystemApp ? 1 : 0,
      'iconPath': iconPath,
      'categoryId': categoryId,
      'sortOrder': sortOrder,
      'isHidden': isHidden ? 1 : 0,
    };
  }

  /// 创建副本
  AppInfo copyWith({
    String? packageName,
    String? appName,
    String? versionName,
    int? versionCode,
    bool? isSystemApp,
    String? iconPath,
    String? categoryId,
    int? sortOrder,
    bool? isHidden,
  }) {
    return AppInfo(
      packageName: packageName ?? this.packageName,
      appName: appName ?? this.appName,
      versionName: versionName ?? this.versionName,
      versionCode: versionCode ?? this.versionCode,
      isSystemApp: isSystemApp ?? this.isSystemApp,
      iconPath: iconPath ?? this.iconPath,
      categoryId: categoryId ?? this.categoryId,
      sortOrder: sortOrder ?? this.sortOrder,
      isHidden: isHidden ?? this.isHidden,
    );
  }
}
