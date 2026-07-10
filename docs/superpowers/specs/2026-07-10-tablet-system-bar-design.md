# StudyFlow 平板底部系统栏适配设计

## 目标

消除平板三键导航或手势导航区域出现的黑色底边，使应用主题背景在视觉上铺满屏幕，同时保证底部导航按钮不被系统导航区域遮挡。

## 方案

- 保持 Flutter `SystemUiMode.edgeToEdge`。
- 将系统导航栏设为透明，并通过 `systemNavigationBarContrastEnforced: false` 关闭 Android 10 以上三键导航自动添加的黑色/半透明对比度遮罩。
- 在 `MaterialApp.builder` 中根据当前深浅主题动态选择系统栏图标亮度。
- 将底部导航栏的主题色背景放在 `SafeArea` 外层，使颜色覆盖底部 inset；`SafeArea(top: false)` 仅负责把按钮内容抬到系统导航区域上方。
- 不修改 Manifest 的方向、宽高比或可调整尺寸配置；当前项目不存在这些 letterbox 限制。

## 验证

- 先增加回归测试，确认遮罩被关闭、系统栏颜色透明、底部结构是“主题色容器包裹 SafeArea”。
- 运行聚焦测试、完整测试、静态分析和 release APK 构建。
- 此环境没有连接平板，最终设备视觉效果需要安装 APK 后确认。

## 边界

只修改 `lib/main.dart`、`lib/screens/home_screen.dart` 和对应测试；保留工作区内其他现有改动。
