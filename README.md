# MyDesktop

基于 Flutter 的桌面面板工具，支持无边框窗口、浮动/边缘两种模式、尺寸与位置记忆。当前为功能骨架阶段，面板内容区域预留扩展。

## 功能特性

- **自定义窗口** — 无边框 + 自定义标题栏（拖拽、关闭）
- **两种模式** — 浮动模式 / 边缘吸附模式（顶、左、右）
- **尺寸记忆** — 各模式独立记忆尺寸，调整后自动保存
- **位置记忆** — 浮动模式记忆窗口位置
- **启动恢复** — 重启后恢复上次的模式、尺寸与位置
- **面板工具** — 便签、剪贴板历史、文本片段、番茄钟（可配置时长/提示音/今日统计）
- **跨平台** — 支持 Windows 与 macOS

## 技术栈

| 类别 | 技术 |
|------|------|
| 框架 | Flutter 3.x（Dart SDK ^3.11.1） |
| UI | Material 3 |
| 窗口控制 | [window_manager](https://pub.dev/packages/window_manager) ^0.4.3 |
| 本地存储 | [shared_preferences](https://pub.dev/packages/shared_preferences) ^2.3.2 |
| 代码规范 | flutter_lints ^6.0.0 |

## 项目结构

```
MyDesktop/
├── lib/
│   ├── main.dart              # 应用入口、窗口壳
│   ├── panel/                 # 面板内容与工具
│   │   ├── panel_shell.dart   # 底部导航 + 工具路由
│   │   ├── notes_store.dart   # 便签持久化
│   │   ├── pages/             # 首页、设置、便签等
│   │   └── widgets/
│   └── window/
│       ├── panel_window.dart  # 无边框窗口壳 + 吸附逻辑
│       ├── window_state.dart  # 窗口状态模型
│       └── window_scope.dart  # 面板访问窗口 API
├── windows/                   # Windows 平台原生工程
├── macos/                     # macOS 平台原生工程
├── test/
│   ├── widget_test.dart       # UI 冒烟测试
│   └── window_state_test.dart # 窗口状态单元测试
├── pubspec.yaml
└── analysis_options.yaml
```

## 快速开始

### 环境要求

- [Flutter SDK](https://docs.flutter.dev/get-started/install)（stable 通道）
- Windows：Visual Studio（含「使用 C++ 的桌面开发」工作负载）
- macOS：Xcode

### 安装与运行

```bash
flutter pub get
flutter run -d windows   # Windows
flutter run -d macos       # macOS
```

### 测试

```bash
flutter test
```

## 使用说明

| 操作 | 效果 |
|------|------|
| 拖拽标题栏 | 移动窗口 |
| 浮动模式下拖到屏幕边缘松手 | 进入边缘模式并恢复该方向的记忆尺寸 |
| 边缘模式下拖动窗口 | 切回浮动模式并恢复记忆的浮动尺寸/位置 |
| 边缘模式下双击标题栏 | 切回浮动模式 |
| 调整窗口大小 | 按当前模式保存对应尺寸 |
| 点击关闭按钮 | 退出应用 |

### 模式与尺寸

| 模式 | 可调整维度 | 默认值 |
|------|-----------|--------|
| 浮动 | 宽 × 高 + 位置 | 320×560 |
| 边缘·顶 | 高度（宽=屏宽） | h=80 |
| 边缘·左 | 宽度（高=屏高） | w=320 |
| 边缘·右 | 宽度（高=屏高） | w=320 |

左/右边缘宽度独立记忆。吸附判定阈值：**20 逻辑像素**。

### 缩放方向

| 模式 | 可拖拽缩放边缘 |
|------|---------------|
| 浮动 | 四边 + 四角 |
| 边缘·顶 | 底边 |
| 边缘·左 | 右边 |
| 边缘·右 | 左边 |

## 架构概览

```
main()
  ├── windowManager 初始化
  └── MyApp → PanelWindow (WindowListener)

PanelWindow
  ├── WindowState          # 持久化模型 (lib/window/)
  ├── _enterFloating()     # 进入浮动 → 恢复记忆尺寸/位置
  ├── _enterEdge()         # 进入边缘 → 恢复记忆尺寸
  ├── onWindowResized      # 保存当前模式尺寸
  └── DragToResizeArea     # 按模式开放缩放方向
```

### 持久化

- 存储键：`mydesktop_window_state_v2`（兼容读取 v1）
- 格式：JSON（浮动尺寸/位置、三种边缘尺寸、上次模式）
- 存储：`shared_preferences` 平台本地目录

## 版本历史

| 版本 | 说明 |
|------|------|
| 1.0.0+1 | 窗口吸附、尺寸记忆、自定义标题栏 |
| 开发中 | 浮动/边缘双模式、位置记忆、左右独立宽度、按模式缩放 |

## 许可证

私有项目（`publish_to: 'none'`），未指定开源许可证。
