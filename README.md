# AnimeOne TV

> 专为 Android TV 设计的动漫观看应用，基于 Flutter 开发，全部代码均由AI编写(包括此readme.md的大部分内容)。
> 测试环境为安卓9版本的索尼4K分辨率电视，其他版本其他分辨率未测试，请自行测试

## 功能特性

- 📺 **TV 遥控器优化** - 完美支持方向键导航，焦点管理流畅
- 🎬 **番剧浏览** - 全部番剧、季度新番、搜索功能
- ⭐ **追番管理** - 收藏喜欢的番剧，快速访问
- 📝 **播放记录** - 自动记录观看进度，断点续播
- 🔍 **智能搜索** - 支持拼音首字母搜索，虚拟键盘输入
- 🎨 **精美 UI** - Material Design 3，深色主题
- ⚡ **性能优化** - 图片缓存、懒加载、流畅滚动

## 截图展示
<img width="1664" height="933" alt="image" src="https://github.com/user-attachments/assets/e3aeb8c2-bea9-4f29-8bb0-7784b6a16edd" />
<img width="1658" height="933" alt="image" src="https://github.com/user-attachments/assets/7f6b22e6-4472-47c3-8d73-d17254ccaaf5" />
<img width="1656" height="936" alt="image" src="https://github.com/user-attachments/assets/a95bb646-7e40-4cf5-8b55-3d5e48862fdf" />
<img width="1664" height="934" alt="image" src="https://github.com/user-attachments/assets/8604eb47-64ff-4cca-a805-9afd0d1f1425" />


## 技术栈

- **Flutter 3.x** - 跨平台 UI 框架
- **video_player** - 视频播放
- **cached_network_image** - 图片缓存
- **http** - 网络请求

## 快速开始

### 1. 环境要求

- Flutter SDK 3.0+
- Android Studio / VS Code
- Android TV 设备或模拟器

### 2. 安装依赖

```bash
flutter pub get
```

### 3. 配置后端地址

修改 `lib/services/api_client.dart`的_baseUrl为自己运行AnimeOne后端的地址

### 4. 构建 APK

```bash
# 开发版本
flutter build apk --debug

# 生产版本（优化体积）
flutter build apk --release --target-platform android-arm
```

APK 文件位于 `build/app/outputs/flutter-apk/`

### 5. 安装到 TV

```bash
adb install build/app/outputs/flutter-apk/app-release.apk
```

## 项目结构

```
lib/
├── main.dart                 # 应用入口
├── models/                   # 数据模型
│   ├── anime.dart
│   ├── episode.dart
│   └── playback_history.dart
├── services/                 # 服务层
│   ├── api_client.dart
│   ├── anime_service.dart
│   ├── favorites_service.dart
│   └── playback_history_service.dart
├── screens/                  # 页面
│   ├── home_screen.dart
│   ├── detail_screen.dart
│   ├── player_screen.dart
│   └── home/
│       ├── search_tab.dart
│       ├── schedule_tab.dart
│       ├── all_anime_tab.dart
│       ├── favorites_tab.dart
│       └── history_tab.dart
└── widgets/                  # 组件
    ├── tv_poster_card.dart
    ├── tv_keyboard_button.dart
    ├── tv_action_button.dart
    ├── tv_dropdown_button.dart
    └── tv_capsule_selector.dart
```

## 核心功能说明

### 焦点导航

应用针对 TV 遥控器进行了深度优化：

- ✅ 侧边栏与内容区域的智能焦点切换
- ✅ 列表自动滚动，防止内容被遮挡
- ✅ 按左键从内容区域精准返回当前选中的侧边栏图标
- ✅ 搜索键盘支持方向键输入

### 数据持久化

- 追番列表和播放记录存储在后端服务器
- 支持多设备同步（未实现账号系统，目前所有设备均读写同一份数据）

### 视频播放
- 自动记录播放进度

## 性能优化

- **APK 体积优化**：仅构建 `armeabi-v7a` 架构，体积 ~15MB
- **图片缓存**：使用 `cached_network_image` 缓存封面
- **懒加载**：列表滚动时按需加载数据
- **内存管理**：及时释放不用的资源

## 后续计划
暂无

## 配套后端

- [AnimeOne 后端服务](https://github.com/Hyper-Beast/AnimeOne_Server) - 必须先部署后端才能使用

## 开发说明

### 调试技巧

```bash
# 查看日志
adb logcat | grep flutter

# 热重载（开发模式）
flutter run
```

### 代码规范

- 使用 `dart format` 格式化代码
- 遵循 Flutter 官方命名规范
- 组件尽量复用，保持代码简洁

## License

MIT License

## 致谢

- Flutter 团队
- video_player 插件作者
- 所有贡献者

---

**注意**：本应用仅供学习交流使用，请勿用于商业用途。请尊重版权，支持正版。
