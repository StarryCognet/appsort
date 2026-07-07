import 'package:equatable/equatable.dart';

/// AI 分类结果
class AppClassification extends Equatable {
  final String packageName;
  final String appName;
  final String categoryName;
  final String? reason;

  const AppClassification({
    required this.packageName,
    required this.appName,
    required this.categoryName,
    this.reason,
  });

  @override
  List<Object?> get props => [packageName, appName, categoryName, reason];

  /// 从 JSON 创建
  factory AppClassification.fromJson(Map<String, dynamic> json) {
    return AppClassification(
      packageName: (json['package'] ?? json['packageName'] ?? '') as String,
      appName: (json['appName'] ?? json['name'] ?? '') as String,
      categoryName: (json['category'] ?? json['categoryName'] ?? '其他') as String,
      reason: json['reason'] as String?,
    );
  }
}

/// AI 分类请求的结果包装
class ClassificationResult {
  final List<AppClassification> classifications;
  final bool isSuccess;
  final String? errorMessage;

  const ClassificationResult({
    required this.classifications,
    this.isSuccess = true,
    this.errorMessage,
  });

  const ClassificationResult.error(this.errorMessage)
      : classifications = const [],
        isSuccess = false;
}
