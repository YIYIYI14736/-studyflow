# StudyFlow 📚

> 学习规划与错题管理应用 · Flutter · Android

StudyFlow 是一款专为学生和备考人群打造的学习管理工具，集**学习计划、错题本、数据备份**于一体，帮助你高效管理学习进度、沉淀错题。

---

## 功能特性

### 📋 学习计划管理
- 创建计划，设置目标时长、截止日期、优先级（高/中/低）
- 列表视图 & 日历视图双模式
- 状态自动流转：待开始 → 进行中 → 已完成
- 子任务拆解，灵活拆分大目标

### 📝 错题本
- 记录错题：按**科目、页码、题号**结构化归档；添加页自动从上一次保存的页码题号开始，无需重复拨动滚轮
- 列表默认两级折叠：「学科 → 页码」，题号与信息收纳其中；点开页码即可展开该页所有错题详情
- **多轮复习追踪**：每道错题可添加多轮复习记录，每轮标记「未掌握 / 已纠正 / 已掌握」状态，颜色区分
- **统计总览**：
  - 掌握率圆环（全局进度一览）
  - 科目分布饼图（哪些科目错题最多）
  - 状态统计（已掌握 vs 仍错比例）
  - 轮次通过率趋势（复习效果追踪）

### 💾 数据备份与恢复
- 一键导出全量数据为 JSON 备份文件
- 备份包含：科目、学习计划、错题本、设置
- 时间戳命名，支持多份备份并存
- 从备份文件一键恢复，换机无忧

### ⚙️ 个性化设置
- 深色模式（淡雅青绿主题）
- 数据手动备份 / 恢复 / 清除

---

## 设计语言

- 主色：淡雅青绿色（备选羊皮纸黄，见 `lib/main.dart` 注释）
- Material 3，圆角 + 亮色 Apple 风 / 深色适配

---

## 技术栈

| 层级 | 技术 |
|------|------|
| 框架 | Flutter 3.x |
| 状态管理 | Riverpod |
| 本地数据库 | Drift (SQLite) |
| 图表 | fl_chart |
| 持久化 | SharedPreferences |
| 文件备份 | path_provider |

---

## 快速开始

> ⚠️ 本项目需要 Flutter SDK 3.5+。

### 环境要求

- Flutter SDK `^3.5.0`
- Dart SDK `^3.5.0`
- Android Studio 或 VS Code

### 安装运行

```bash
# 克隆项目
git clone https://github.com/YIYIYI14736/studyflow.git
cd studyflow

# 安装依赖
flutter pub get

# 生成代码（数据库 & Provider）
dart run build_runner build --delete-conflicting-outputs

# 运行
flutter run

# 打包发布版 APK
flutter build apk --release
```

输出：`build/app/outputs/flutter-apk/app-release.apk`

---

## 项目结构

```
lib/
├── main.dart                         # 入口 + 主题色
├── config/                           # （原 api_keys.dart 已移除）
├── models/
│   └── models.dart                   # 数据模型（科目 / 计划 / 子任务 / 错题 / 复习轮次 / 设置）
├── database/
│   ├── database.dart                 # Drift 数据库定义
│   └── database.g.dart               # 自动生成代码
├── providers/
│   └── providers.dart                # 全局状态（科目 / 计划 / 错题 / 设置）
├── screens/
│   ├── home_screen.dart              # 首页仪表盘（计划进度摘要 + 科目列表）
│   ├── plans_screen.dart             # 学习计划
│   ├── settings_screen.dart          # 设置（备份 / 恢复 / 清除）
│   └── wrong_questions_screen.dart   # 错题本（折叠列表 / 统计总览）
├── services/
│   └── data_backup_service.dart      # 数据备份与恢复
└── widgets/                          # （原 subject_selector.dart 已移除）
```

---

## 数据备份工作流程

```
备份触发（手动）
    ↓
导出：科目 + 计划 + 错题 + 设置
    ↓
生成 JSON 文件 → timestamp 命名
    ↓
用户选择保存位置
    ↓
恢复：读取 JSON → 写入数据库 + SharedPreferences
```

---

## License

MIT License © 2025 YIYIYI14736
