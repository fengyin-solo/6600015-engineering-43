# 分布式任务调度与监控平台

基于 Elixir/Phoenix GenServer 的分布式任务调度系统，配套 React + Ant Design 监控大屏。

## 功能

- 任务 CRUD + 状态管理（pending/running/success/failed）
- 失败任务自动重试（可配置最大重试次数）
- 集群节点健康监控（CPU/内存/任务数）
- 实时指标图表（运行中任务数、成功率、平均延迟）
- GenServer 状态管理 + PubSub 事件广播
- REST API（任务列表/创建/重试/取消/统计/节点）

## 技术栈

- 前端：React + TypeScript + Ant Design + Recharts + Zustand
- 后端：Elixir + Phoenix + GenServer + PubSub
- 数据库：PostgreSQL（Ecto）

## 快速开始

### 1. 安装依赖

```bash
npm run setup
# 或直接运行: bash scripts/setup.sh
```

自动检查 elixir / node / npm 工具链，并安装前后端全部依赖。

### 2. 启动开发环境

```bash
npm run dev
# 或直接运行: bash scripts/dev.sh
```

一条命令同时启动后端 (port 4000) 和前端 (port 5175)，自动等待服务就绪并验证 API 连通性。按 `Ctrl+C` 一键停止所有服务。

### 3. 健康检查

```bash
npm run check
# 或直接运行: bash scripts/check.sh
```

自动执行以下检查：

| 类别 | 检查项 |
|------|--------|
| 运行时 | 后端服务可达、前端服务可达、API 代理连通 |
| API | `/api/tasks`、`/api/stats`、`/api/nodes` 端点可用 |
| API | 响应 JSON 格式校验（tasks 数组、stats 字段） |
| 代码质量 | TypeScript 类型检查、前端生产构建、后端编译 |

### 其他命令

```bash
npm run dev:backend      # 仅启动后端
npm run dev:frontend     # 仅启动前端
npm run build:frontend   # 前端生产构建
npm run typecheck        # TypeScript 类型检查
npm run compile:backend  # 后端编译检查
```

### 手动启动（不使用脚本）

```bash
# 后端
cd backend && mix deps.get && mix run --no-halt

# 前端（另开终端）
cd frontend && npm install && npm run dev
```
