# StudyFlow Android 桌面图标修复设计

## 目标

使用项目根目录的 `ChatGPT Image 2026年7月9日 00_43_02.png` 作为唯一视觉来源，生成在普通 Android APK、圆形桌面和自适应/主题图标桌面上都能正确显示的 StudyFlow 图标，避免缩小后近似黑块或被主题引擎渲染成实心色块。

## 方案

- 传统图标：从原图中心裁取书本、清单和时钟主体，适度提亮并导出 mdpi、hdpi、xhdpi、xxhdpi、xxxhdpi 的 `ic_launcher.png` 与 `ic_launcher_round.png`。
- 自适应图标：使用深蓝背景层和带透明通道的中心主体前景层；主体限制在 Android 66/108 安全区内，外圈保留裁剪余量。
- 主题图标：增加清晰的单色书本/清单/时钟轮廓，并在 v33 自适应图标 XML 中声明 `monochrome` 层。
- 资源引用：Manifest 继续使用 `@mipmap/ic_launcher` 和 `@mipmap/ic_launcher_round`，不引入额外运行时依赖。
- 源图标准化：所有导出 PNG 转换为 8-bit sRGB/RGBA，去除原图的非标准附加数据，避免设备图片解码差异。

## 验证

- 测试先验证当前资源缺少合格单色层、前景完全不透明，并观察失败。
- 修复后验证所有密度资源尺寸、透明度、XML 三层引用和 Manifest 引用。
- 运行 Flutter 测试、静态分析和 release APK 构建。
- 使用 `aapt2` 检查最终 APK 中的普通、自适应和单色资源均已打包。

## 边界

只修改图标资源、图标相关 XML、对应测试和必要的版本资源配置；保留工作区内其他现有改动，不做无关重构。
