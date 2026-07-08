# StudyFlow 📚

> 智能学习计时与规划应用 · Flutter · Android

StudyFlow 是一款专为学生和备考人群打造的学习管理工具，集**计时器、学习计划、数据统计、错题本、数据备份**于一体，帮助你高效管理每一分钟的学习时间。

---

## 功能特性

### ⏱️ 多模式学习计时器
- **番茄钟**：专注工作 + 自动休息，时长可自定义
- **倒计时**：设定目标时长，专注完成
- **正计时**：无上限自由计时，自动记录

### 📋 学习计划管理
- 创建计划，设置目标时长、截止日期、优先级（高/中/低）
- 计时结束自动累加计划进度
- 列表视图 & 日历视图双模式
- 状态自动流转：待开始 → 进行中 → 已完成

### 📊 学习数据统计
- **今日**：总时长 + 科目分布饼图
- **本周**：每日时长柱状图
- **本月**：学习热力日历

### 📝 错题本
- 记录错题：按**科目、页码、题号**结构化归档；添加页自动从上一次保存的页码题号开始
- 错题列表两级折叠：默认只显示「学科 → 页码」，题号信息收纳其中；点开页码即可展开该页所有题号与详情
- **多轮复习追踪**：每道错题可添加多轮复习记录，每轮标记「已掌握 / 模糊 / 仍错」状态，颜色区分
- **统计总览**：
  - 掌握率圆环（全局进度一览）
  - 科目分布饼图（哪些科目错题最多）
  - 状态统计（已掌握 vs 仍错比例）
  - 轮次通过率趋势（复习效果追踪）

### 💾 数据备份与恢复
- 一键导出全量数据为 JSON 备份文件
- 备份包含：科目、学习计划、学习记录、错题本、设置
- 时间戳命名，支持多份备份并存
- 从备份文件一键恢复，换机无忧
- Android SAF 文件选择器，自由选择保存/导入位置

### ⚙️ 个性化设置
- 深色模式
- 番茄钟时长自定义
- 数据备份手动触发
- 通知提醒开关

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

> ⚠️ 本项目需要 Flutter SDK 3.5+，服务器环境无 Flutter，请在本地编译运行。

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
```

---

## 项目结构

```
lib/
├── main.dart                        # 入口
├── models/
│   └── models.dart                  # 数据模型
├── database/
│   ├── database.dart                # Drift 数据库定义
│   └── database.g.dart               # 自动生成代码
├── providers/
│   ├── providers.dart               # 全局状态（科目 / 计划 / 记录 / 设置 / 错题）
│   └── timer_provider.dart          # 计时器状态机
├── screens/
│   ├── home_screen.dart             # 首页仪表盘
│   ├── timer_screen.dart            # 计时器页面
│   ├── plans_screen.dart            # 学习计划页面
│   ├── stats_screen.dart            # 统计页面
│   ├── settings_screen.dart         # 设置页面（备份 / 恢复）
│   └── wrong_questions_screen.dart  # 错题本（错题列表 / 统计总览）
├── services/
│   ├── notification_service.dart    # 本地通知
│   └── data_backup_service.dart     # 数据备份与恢复
└── widgets/
    └── subject_selector.dart        # 科目选择器组件
```

---

## 数据备份工作流程

```
备份触发（手动）
    ↓
导出：科目 + 计划 + 记录 + 错题 + 设置
    ↓
生成 JSON 文件 → timestamp 命名
    ↓
用户选择保存位置（SAF 文件选择器）
    ↓
恢复：读取 JSON → 写入数据库 + SharedPreferences
```

---

## License

MIT License © 2025 YIYIYI14736
