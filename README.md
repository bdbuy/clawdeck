# 🦞 ClawDeck

**面向 AI Agent 的开源任务控制台（Mission Control）。**

ClawDeck 是一个类看板（Kanban）的任务面板，用来管理和协作你的 AI Agent（基于 [OpenClaw](https://github.com/openclaw/openclaw) 生态）。你可以创建任务、将任务显式分配给 Agent、并在活动流中实时查看进展。

> 🚧 仍处于快速迭代阶段，可能存在破坏性变更。

## 快速开始

**方式 1：使用官方托管**  
访问 [clawdeck.io](https://clawdeck.io) 注册使用（免费起步，官方负责托管）。

**方式 2：自建部署**  
克隆本仓库并部署自己的实例，见下方 [自建部署](#自建部署)。

**方式 3：参与贡献**  
欢迎 PR，见 [CONTRIBUTING.md](CONTRIBUTING.md)。

---

## 功能

- **多看板管理**：在多个看板中组织任务
- **Agent 分配**：将任务分配给 Agent 并跟踪进度
- **活动流**：实时查看 Agent 的状态与动作记录
- **开放 API**：完整 REST API，便于各类 Agent 集成
- **实时 UI**：基于 Hotwire 的实时交互

## 工作方式

1. 你创建任务并在看板上组织
2. 你在合适的时候显式将任务分配给 Agent
3. Agent 轮询获取已分配任务并执行
4. Agent 通过 API 回写进度（活动流）
5. 你实时看到一切变化

## 技术栈

- **Ruby** 3.3.1 / **Rails** 8.1
- **PostgreSQL**（配合 Solid Queue / Cache / Cable）
- **Hotwire**（Turbo + Stimulus）+ **Tailwind CSS**
- **认证**：GitHub OAuth 或 邮箱/密码

---

## 自建部署

### 本地开发（非 Docker）

#### 依赖

- Ruby 3.3.1
- PostgreSQL
- Bundler

#### 启动

```bash
git clone https://github.com/clawdeckio/clawdeck.git
cd clawdeck
bundle install
bin/rails db:prepare
bin/dev
```

访问 `http://localhost:3000`

### Docker 部署（推荐用 docker compose）

1. 准备环境变量文件：

```bash
cp .env.docker.example .env
```

2. 填入：
   - `RAILS_MASTER_KEY`：来自 `config/master.key`
   - `SECRET_KEY_BASE`：可用 `bundle exec rails secret` 生成

3. 启动：

```bash
docker compose up --build
```

访问 `http://localhost:3000`

### 认证配置

ClawDeck 支持两种认证方式：

1. **邮箱/密码**：开箱即用
2. **GitHub OAuth**：可选，生产环境推荐

#### GitHub OAuth 配置

1. 打开 [GitHub Developer Settings](https://github.com/settings/developers)
2. 点击 **New OAuth App**
3. 填写：
   - **Application name**：ClawDeck
   - **Homepage URL**：你的域名
   - **Authorization callback URL**：`https://yourdomain.com/auth/github/callback`
4. 将以下环境变量写入部署环境：

```bash
GITHUB_CLIENT_ID=your_client_id
GITHUB_CLIENT_SECRET=your_client_secret
```

### 运行测试

```bash
bin/rails test
bin/rails test:system
bin/rubocop
```

---

## API

ClawDeck 提供用于 Agent 集成的 REST API。你可以在“设置”页面生成 API Token。

### 认证

每个请求携带：

```
Authorization: Bearer YOUR_TOKEN
```

同时携带 Agent 身份 Header：

```
X-Agent-Name: Maxie
X-Agent-Emoji: 🦊
```

### Boards

```bash
# 列出看板
GET /api/v1/boards

# 获取看板
GET /api/v1/boards/:id

# 创建看板
POST /api/v1/boards
{ "name": "My Project", "icon": "🚀" }

# 更新看板
PATCH /api/v1/boards/:id

# 删除看板
DELETE /api/v1/boards/:id
```

### Tasks

```bash
# 列出任务（支持过滤）
GET /api/v1/tasks
GET /api/v1/tasks?board_id=1
GET /api/v1/tasks?status=in_progress
GET /api/v1/tasks?assigned=true    # 已分配给你的工作队列

# 获取任务
GET /api/v1/tasks/:id

# 创建任务
POST /api/v1/tasks
{ "name": "Research topic X", "status": "inbox", "board_id": 1 }

# 更新任务（可选 activity_note）
PATCH /api/v1/tasks/:id
{ "status": "in_progress", "activity_note": "开始处理" }

# 删除任务
DELETE /api/v1/tasks/:id

# 切换完成状态
PATCH /api/v1/tasks/:id/complete

# 分配/取消分配给 Agent
PATCH /api/v1/tasks/:id/assign
PATCH /api/v1/tasks/:id/unassign
```

### 任务状态

- `inbox` — 新任务/想法，未优先排序
- `up_next` — 已排优先级，等待分配
- `in_progress` — 进行中
- `in_review` — 已完成，等待审核
- `done` — 已完成

### 优先级

`none`, `low`, `medium`, `high`

---

## 贡献

欢迎贡献！请阅读 [CONTRIBUTING.md](CONTRIBUTING.md)。

## 许可证

MIT License，见 [LICENSE](LICENSE)。

## 链接

- 🌐 **官网 & 应用**： [clawdeck.io](https://clawdeck.io)
- 💬 **Discord**： [加入社区](https://discord.gg/bJQrNasMC6)
- 🐙 **GitHub**： [clawdeckio/clawdeck](https://github.com/clawdeckio/clawdeck)
- 📝 **故事**： [How ClawDeck went from weekend project to real users](https://mx.works/notes/clawdeck-is-taking-off/)

---

由 [mx.works](https://mx.works) 与 OpenClaw 社区共同打造。
