# StudyFlow 📚

> 智能学习计时与规划应用 · Flutter · Android

StudyFlow 是一款专为学生和备考人群打造的学习管理工具，集**计时器、学习计划、数据统计、AI 智能规划、联网搜索**于一体，帮助你高效管理每一分钟的学习时间。

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

### 🤖 AI 学习助手
- 流式实时输出，告别等待
- **自动识别计划请求**：发送备考需求，AI 自动判断并生成可导入的结构化计划
- **计划一键导入**：AI 生成的学习计划直接导入到计划列表
- 学习数据智能分析，给出改进建议
- 语义记忆系统：AI 记住你的学习偏好和历史
- 支持多模型：DeepSeek V3.2 / Doubao / Kimi / GLM / MiniMax 等

### 🔍 联网搜索
- **AI 回答前自动搜索网络**：获取最新信息，避免过时或错误回答
- 内置 Tavily 搜索 API Key，开箱即用
- 搜索结果自动注入 AI 上下文，回答更准确、更及时
- 搜索失败不影响聊天，AI 仍正常回答
- 搜索状态实时提示：蓝色已开启 / 红色未配 Key
- 支持多种搜索提供商：Tavily（推荐）/ Bing / 自定义
- AI 聊天页面一键开关联网搜索

### ⚙️ 个性化设置
- 深色模式
- 番茄钟时长自定义
- 支持多家 AI 服务商（火山方舟、DeepSeek、阿里云、智谱、Moonshot 等）
- 自定义 API Key 和模型
- 联网搜索开关 & 搜索 API Key 配置

---

## 技术栈

| 层级 | 技术 |
|------|------|
| 框架 | Flutter 3.x |
| 状态管理 | Riverpod |
| 本地数据库 | Drift (SQLite) |
| 网络请求 | Dio（支持 SSE 流式） |
| 图表 | fl_chart |
| AI 接入 | OpenAI 兼容接口 |
| 联网搜索 | Tavily / Bing Search API |
| 语义记忆 | Embedding 向量检索 |
| 持久化 | SharedPreferences |

---

## 快速开始

### 环境要求

- Flutter SDK `^3.5.0`
- Dart SDK `^3.5.0`
- Android Studio 或 VS Code

### 安装运行

```bash
# 克隆项目
git clone https://github.com/YIYIYI14736/-studyflow.git
cd -studyflow

# 安装依赖
flutter pub get

# 生成代码（数据库 & Provider）
dart run build_runner build --delete-conflicting-outputs

# 运行
flutter run
```

### AI 功能配置

应用默认内置了火山方舟 API，开箱即用。如需使用自己的 Key：

1. 打开应用 → 右上角「设置」
2. 进入「AI 配置」
3. 填入你的 API Key 和对应的 Base URL
4. 选择模型（推荐 DeepSeek V3.2）

支持的服务商：

| 服务商 | Base URL |
|--------|----------|
| 火山方舟（默认） | `https://ark.cn-beijing.volces.com/api/coding/v3` |
| DeepSeek | `https://api.deepseek.com` |
| 阿里云通义 | `https://dashscope.aliyuncs.com/compatible-mode/v1` |
| 智谱 AI | `https://open.bigmodel.cn/api/paas/v4` |
| Moonshot | `https://api.moonshot.cn/v1` |

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
├── main.dart                    # 入口
├── config/
│   └── api_keys.dart            # API Key 配置（git skip-worktree 保护）
├── models/
│   └── models.dart              # 数据模型（Subject / StudyPlan / StudySession 等）
├── database/
│   └── database.dart            # Drift 数据库定义
├── providers/
│   ├── providers.dart           # 全局状态（科目 / 计划 / 记录 / 设置）
│   └── timer_provider.dart      # 计时器状态机
├── screens/
│   ├── home_screen.dart         # 首页仪表盘
│   ├── timer_screen.dart        # 计时器页面
│   ├── plans_screen.dart        # 学习计划页面
│   ├── stats_screen.dart        # 统计页面
│   ├── ai_screen.dart           # AI 对话页面（含联网搜索开关）
│   └── settings_screen.dart     # 设置页面（含搜索配置）
├── services/
│   ├── ai_service.dart          # AI 请求 & 流式输出 & 计划提取 & 联网搜索集成
│   ├── web_search_service.dart  # 联网搜索服务（Tavily / Bing / 自定义）
│   ├── memory_service.dart      # Embedding 语义记忆
│   └── notification_service.dart # 本地通知
└── widgets/
    ├── study_card.dart          # 统计卡片组件
    └── subject_selector.dart    # 科目选择器组件
```

---

## 联网搜索工作流程

```
用户发送消息
    ↓
WebSearchService.search(query)  ← 调用 Tavily/Bing API
    ↓
搜索结果格式化 → 注入 AI 系统提示词
    ↓
AI 基于搜索结果 + 记忆上下文回答
    ↓
回答中引用来源，信息更准确
```

---

## License

MIT License © 2025 YIYIYI14736