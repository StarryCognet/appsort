# AppSort 项目指南

## 项目概述

Android Flutter 应用，AI 智能分类手机应用。
用户手机安装 → AI 自动分类 → 按分类浏览/打开应用。

## 技术栈

- Flutter 3.41 + Dart 3.11 + Riverpod + sqflite + dio
- Android 平台通道（Kotlin）获取应用列表/图标/打开应用
- Material 3 设计，支持浅色/深色主题

## 核心数据模型

- `AppInfo`: packageName, appName, iconPath, categoryId, sortOrder, isHidden
- `AppCategory`: id, name, icon, color, sortOrder, isBuiltIn
- `AppSettings`: aiConfig (provider/apiKey/baseUrl/model), themeMode

## 状态管理（Riverpod）

| Provider | 类型 | 说明 |
|----------|------|------|
| `appListProvider` | StateNotifier | 应用列表 + 加载/刷新/搜索 |
| `categoryProvider` | StateNotifier | 分类 + 分组数据 |
| `classificationProvider` | StateNotifier | AI 分类进度/状态 |
| `settingsProvider` | StateNotifier | 设置（main 预加载） |
| `settingsProvider` 含 `initialSettingsProvider` | Provider | 启动时注入初始值 |
| `searchProvider` | StateNotifier | 300ms 去抖搜索 |
| `themeModeProvider` | Provider | 根据设置返回 ThemeMode |

## AI 服务

所有服务商通过 `AIService` 接口统一调用，工厂 `AIServiceFactory.create(AiConfig)` 返回具体实现。

支持的 AI 服务商：OpenAI、Anthropic、Gemini、DeepSeek、OpenAI 兼容自定义。
提示词模板统一，要求返回 JSON 数组格式的分类结果。

分类逻辑在 `classification_provider.dart`：
- 分批处理（每批 50 个应用）
- 失败自动重试（最多 2 次）
- 进度实时更新

## 数据库（sqflite）

三张表：
- `apps` — 已安装应用（主键 packageName）
- `categories` — 分类定义（含默认内置分类种子数据）
- `settings` — 键值对设置

## 平台通道

MethodChannel: `com.starryflow.appsort/apps`

| 方法 | 参数 | 说明 |
|------|------|------|
| `getInstalledApps` | includeSystemApps | 获取全部可启动应用列表 |
| `getAppIcon` | packageName | 获取单个应用图标字节 |
| `openApp` | packageName | 启动应用 |
| `openAppStore` | packageName | 在应用商店查看 |
| `openAppSettings` | packageName | 打开应用详情设置 |

## 常见问题

1. **MethodChannel 返回类型**：Kotlin 的 `Map<String, Any?>` 到 Dart 变成 `Map<Object?, Object?>`，需要用 `Map<String, dynamic>.from()` 转换，不能用 `as` 强转。
2. **SharedPreferences 测试**：测试前必须调用 `SharedPreferences.setMockInitialValues({})`。
3. **SettingsPage 不要调 loadSettings**：设置在 `main()` 中就预加载了，build 方法中调 async 操作会导致无限重建。
4. **图标缓存**：从平台获取的 iconBytes 先存文件（`{appDir}/icons/{package}.png`），内存 LRU 缓存 100 条。
