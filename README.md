# StudyFlow 📚

> 智能学习计时与规划应用 · Flutter · Android

StudyFlow 是一款专为学生和备考人群打造的学习管理工具，集**计时器、学习计划、数据统计、AI 智能规划、联网搜索、错题本、数据备份**于一体，帮助你高效管理每一分钟的学习时间。

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
- 记录错题：按**科目、页码、题号**结构化归档
- 错题列表：按科目标签、页码、题号排序，一目了然
- **多轮复习追踪**：每道错题可添加多轮复习记录，每轮标记「已掌握 / 模糊 / 仍错」状态，颜色区分
- **统计总览**：
  - 掌握率圆环（全局进度一览）
  - 科目分布饼图（哪些科目错题最多）
  - 状态统计（已掌握 vs 仍错比例）
  - 轮次通过率趋势（复习效果追踪）
- AI 辅助：错题数据可纳入 AI 分析上下文，给出针对性复习建议

### 🤖 AI 学习助手（基于 DeepSeek）
- 流式实时输出，告别等待
- **自动识别计划请求**：发送备考需求，AI 自动判断并生成可导入的结构化计划
- **计划一键导入**：AI 生成的学习计划直接导入到计划列表
- 学习数据智能分析，给出改进建议
- 语义记忆系统：AI 记住你的学习偏好和历史
- 默认模型：`deepseek-v4-flash`（快速高性价比），可切换 `deepseek-v4-pro`（强推理）

### 🔍 联网搜索
- **AI 回答前自动搜索网络**：获取最新信息，避免过时或错误回答
- 内置 Tavily 搜索 API Key，开箱即用
- 搜索结果自动注入 AI 上下文，回答更准确、更及时
- 搜索失败不影响聊天，AI 仍正常回答
- 搜索状态实时提示：蓝色已开启 / 红色未配 Key
- 支持多种搜索提供商：Tavily（推荐）/ Bing / 自定义
- AI 聊天页面一键开关联网搜索

### 💾 数据备份与恢复
- 一键导出全量数据为 JSON 备份文件
- 备份包含：科目、学习计划、学习记录、错题本、AI 记忆、设置
- 时间戳命名，支持多份备份并存
- 从备份文件一键恢复，换机无忧
- Android SAF 文件选择器，自由选择保存/导入位置

### ⚙️ 个性化设置
- 深色模式
- 番茄钟时长自定义
- **DeepSeek AI 配置**：自定义 API Key、Base URL、模型（deepseek-v4-flash / deepseek-v4-pro）
- 联网搜索开关 & 搜索 API Key 配置
- 数据备份手动触发
- 通知提醒开关

---

## 技术栈

| 层级 | 技术 |
|------|------|
| 框架 | Flutter 3.x |
| 状态管理 | Riverpod |
| 本地数据库 | Drift (SQLite) |
| 网络请求 | Dio（支持 SSE 流式） |
| 图表 | fl_chart |
| AI 接入 | DeepSeek（OpenAI 兼容接口） |
| 联网搜索 | Tavily / Bing Search API |
| 语义记忆 | Embedding 向量检索 |
| 持久化 | SharedPreferences |
| 文件备份 | path_provider + Android SAF |

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

### AI 功能配置

应用基于 **DeepSeek OpenAI 兼容接口**，默认模型为 `deepseek-v4-flash`。内置 API Key 可开箱即用，如需使用自己的 Key：

1. 打开应用 → 右上角「设置」→「DeepSeek AI 配置」
2. 填入你的 API Key（默认 Base URL: `https://api.deepseek.com`）
3. 选择可用模型：
   - `deepseek-v4-flash`（默认，快速版，高性价比）
   - `deepseek-v4-pro`（专业版，更强推理能力）

> 服务采用 OpenAI Compatible 接口协议，也可通过修改 Base URL 指向其他兼容服务。

### 联网搜索配置

应用默认内置了 Tavily 搜索 API Key，开启即可使用：

1. 打开 AI 聊天页面 → 点击 AppBar 的 🌐 按钮
2. 或在设置 → 联网搜索中开启

如需使用自己的搜索 Key：

1. 打开应用 → 设置 → 联网搜索
2. 填入你的搜索 API Key
3. 选择搜索提供商

支持的搜索提供商：

| 提供商 | 说明 |
|--------|------|
| Tavily（推荐） | 专为 AI Agent 设计，[免费注册](https://tavily.com)获取 Key |
| Bing Search API | 微软 Azure 认知服务 |
| 自定义 | 使用自定义搜索接口 |

> ⚠️ `lib/config/api_keys.dart` 中的 Key 已被 `git skip-worktree` 保护，不会被提交到仓库。克隆后请自行填入你的 Key。

---

## 项目结构

```
lib/
├── main.dart                        # 入口
├── config/
│   └── api_keys.dart                # API Key 配置（git skip-worktree 保护）
├── models/
│   └── models.dart                  # 数据模型
├── database/
│   ├── database.dart                # Drift 数据库定义
│   └── database.g.dart               # 自动生成代码
├── providers/
│   ├── providers.dart               # 全局状态（科目 / 计划 / 记录 / 设置）
│   └── timer_provider.dart          # 计时器状态机
├── screens/
│   ├── home_screen.dart             # 首页仪表盘
│   ├── timer_screen.dart            # 计时器页面
│   ├── plans_screen.dart            # 学习计划页面
│   ├── stats_screen.dart            # 统计页面
│   ├── ai_screen.dart               # AI 对话页面（含联网搜索开关）
│   ├── settings_screen.dart         # 设置页面（DeepSeek 配置 & 备份）
│   └── wrong_questions_screen.dart  # 错题本（错题列表 / 统计总览）
├── services/
│   ├── ai_service.dart              # AI 请求 & 流式输出 & 计划提取 & 联网搜索
│   ├── memory_service.dart          # Embedding 语义记忆
│   ├── notification_service.dart    # 本地通知
│   └── data_backup_service.dart     # 数据备份与恢复
└── widgets/
    └── subject_selector.dart        # 科目选择器组件
```

---

## AI 工作流程

```
用户发送消息
    ↓
联网搜索（可选）→ WebSearchService.search(query)
    ↓
搜索结果 + 记忆上下文 → 注入 AI 系统提示词
    ↓
DeepSeek API（streaming）→ 流式文本输出
    ↓
回答中引用来源 | 识别到计划请求 → 生成结构化计划 → 一键导入
```

---

## 数据备份工作流程

```
备份触发（手动）
    ↓
导出：科目 + 计划 + 记录 + 错题 + AI记忆 + 设置
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
