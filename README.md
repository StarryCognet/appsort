# AppSort — AI 智能应用分类启动器

> 用 AI 自动整理你的手机应用，一键分类、随心排序。

## 功能

- **📱 扫描已安装应用** — 获取手机所有可启动应用列表
- **🤖 AI 智能分类** — 接入 AI 自动将应用分到社交、效率、游戏等类别
- **🎨 自定义分类** — 创建/编辑/删除分类，选图标选颜色
- **🔄 拖拽排序** — 长按拖动调整应用和分类顺序
- **🔍 搜索过滤** — 实时搜索，快速找到应用
- **🚀 一键打开** — 在 App 内直接打开其他应用
- **🌓 Material 3** — 浅色/深色/跟随系统主题

## 支持的 AI 服务商

| 服务商 | API 端点 | 默认模型 |
|--------|----------|----------|
| **OpenAI** | `api.openai.com` | `gpt-4o-mini` |
| **Anthropic** | `api.anthropic.com` | `claude-3-haiku` |
| **Google Gemini** | `generativelanguage.googleapis.com` | `gemini-2.0-flash` |
| **DeepSeek** | `api.deepseek.com` | `deepseek-chat` |
| **自定义** | 任意 OpenAI 兼容端点 | 自由配置 |

> ⚠️ 使用前需在设置页填写对应服务的 API Key。

## 技术架构

```
appsort/
├── lib/
│   ├── main.dart                 # 入口：预加载设置后启动
│   ├── app.dart                  # MaterialApp + 主题
│   ├── core/constants.dart       # 常量、AI 提供商枚举、默认分类
│   ├── data/
│   │   ├── models/               # AppInfo, AppCategory, AppSettings
│   │   ├── database_helper.dart  # sqflite 数据库（3 表 + CRUD）
│   │   ├── app_repository.dart   # 应用数据仓库
│   │   └── category_repository.dart # 分类数据仓库
│   ├── services/
│   │   ├── ai/                   # AI 服务抽象层（接口 + 工厂）
│   │   │   ├── ai_service.dart   # 抽象接口
│   │   │   ├── ai_service_factory.dart
│   │   │   ├── openai_service.dart     # OpenAI + DeepSeek + 自定义
│   │   │   ├── anthropic_service.dart  # Claude
│   │   │   └── gemini_service.dart     # Gemini
│   │   ├── installed_apps_service.dart # 平台通道客户端
│   │   ├── settings_service.dart       # SharedPreferences
│   │   └── icon_cache_service.dart     # 图标文件缓存 + LRU
│   ├── providers/                # Riverpod 状态管理
│   │   ├── app_list_provider.dart
│   │   ├── category_provider.dart
│   │   ├── classification_provider.dart # 分批 + 重试 + 进度
│   │   ├── search_provider.dart
│   │   ├── settings_provider.dart
│   │   └── theme_provider.dart
│   └── ui/
│       ├── theme/app_theme.dart
│       ├── shell/app_shell.dart
│       ├── pages/
│       │   ├── smart_page.dart        # 分类网格主页
│       │   ├── all_apps_page.dart     # 全部应用 + 搜索
│       │   └── settings_page.dart     # AI 配置 + 主题 + 分类
│       └── widgets/                   # 7 个可复用组件
├── android/…/MainActivity.kt   # 平台通道（获取应用/图标/打开应用）
└── pubspec.yaml
```

### 关键依赖

| 包 | 用途 |
|----|------|
| `flutter_riverpod` | 状态管理 |
| `sqflite` | 本地数据库（应用/分类存储） |
| `dio` | HTTP 客户端（AI API 调用） |
| `shared_preferences` | 设置存储 |
| `path_provider` | 图标缓存路径 |

## 快速开始

### 前置要求

- Flutter 3.41+（已安装）
- Android SDK（需安装）
- Java 17+（已安装）

### 安装 Android SDK

```bash
# 1. 下载命令行工具
#    https://developer.android.com/studio#command-line-tools-only
#    解压到: E:\IDE\Android\Sdk\cmdline-tools\latest\

# 2. 安装 SDK 组件
E:\IDE\Android\Sdk\cmdline-tools\latest\bin\sdkmanager.bat "platforms;android-35" "build-tools;35.0.0"

# 3. 配置 Flutter
flutter config --android-sdk "E:\IDE\Android\Sdk"

# 4. 构建 APK
cd E:\Git\appsort
flutter build apk --debug
```

APK 位置：`build/app/outputs/flutter-apk/app-debug.apk`

### 使用

1. 安装 APK 到手机
2. 打开 AppSort，授予「应用列表」权限
3. 首次加载会自动扫描已安装应用
4. 在设置页配置 AI 服务商和 API Key
5. 返回首页点击「AI 分类」按钮
6. 等待 AI 完成分类，即可按分类浏览应用

## 构建

```bash
# 调试
flutter build apk --debug

# 发布（需签名配置）
flutter build apk --release
```

GitHub Actions 自动构建：推送后进入 **Actions** 标签下载 APK。

## 许可证

MIT
