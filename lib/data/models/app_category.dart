import 'package:equatable/equatable.dart';

/// 应用分类模型
class AppCategory extends Equatable {
  final String id;
  final String name;
  final String icon;
  final String color;
  final int sortOrder;
  final bool isBuiltIn;

  const AppCategory({
    required this.id,
    required this.name,
    this.icon = 'apps',
    this.color = '#9E9E9E',
    this.sortOrder = 0,
    this.isBuiltIn = false,
  });

  @override
  List<Object?> get props => [id, name, icon, color, sortOrder, isBuiltIn];

  /// 从数据库 Map 创建
  factory AppCategory.fromMap(Map<String, dynamic> map) {
    return AppCategory(
      id: map['id'] as String,
      name: map['name'] as String? ?? '',
      icon: map['icon'] as String? ?? 'apps',
      color: map['color'] as String? ?? '#9E9E9E',
      sortOrder: (map['sortOrder'] as int?) ?? 0,
      isBuiltIn: (map['isBuiltIn'] as int?) == 1,
    );
  }

  /// 转换为数据库 Map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'icon': icon,
      'color': color,
      'sortOrder': sortOrder,
      'isBuiltIn': isBuiltIn ? 1 : 0,
    };
  }

  /// 创建副本
  AppCategory copyWith({
    String? id,
    String? name,
    String? icon,
    String? color,
    int? sortOrder,
    bool? isBuiltIn,
  }) {
    return AppCategory(
      id: id ?? this.id,
      name: name ?? this.name,
      icon: icon ?? this.icon,
      color: color ?? this.color,
      sortOrder: sortOrder ?? this.sortOrder,
      isBuiltIn: isBuiltIn ?? this.isBuiltIn,
    );
  }

  /// 将十六进制颜色转换为 Flutter Color
  int get colorValue {
    final hex = color.replaceFirst('#', '');
    return int.parse('FF$hex', radix: 16);
  }
}
