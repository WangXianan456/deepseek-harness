# DeepSeek Harness (`dsh`) 使用指南

> 本指南基于已克隆到本工作区（`f:\AAARepository\DSharness`）的源码编写，所有命令均已在 Windows 环境实测验证。

## 1. 这是什么

**DeepSeek Harness（`dsh`）** 是 DeepSeek AI 开源的智能体框架（agent harness）。
核心设计是 **一切皆插件（Everything is a Plugin）**，由 [Cordis](https://github.com/cordiverse/cordis) 驱动。
你可以在 Web 界面、命令行、Python SDK 中运行同一个 agent：它能够读写工作区文件、执行 shell 命令、委派子任务、维护计划等。

> ⚠️ 目前处于 **开发者预览版（0.1.0-rc.5）**，接口快速迭代，未来可能有破坏性变更。

---

## 2. 安装与构建（已完成 ✅）

本工作区已完成以下步骤：

| 步骤 | 命令 | 说明 |
|---|---|---|
| 克隆 | `git clone https://github.com/WangXianan456/deepseek-harness.git .` | 7412 个文件 |
| 环境 | 通过 corepack 切换到 `pnpm@11.7.0` | 项目要求（Node ≥ 22.19） |
| 装依赖 | `pnpm install` | 238 个 workspace 项目 |
| 构建 | `pnpm run build` | 编译 host/client 库 + Web 前端 |

**项目要求：** Node.js `^22.19.0 || >=24.0.0`，pnpm `11.7.0`。

### 不想用源码？用 npm 直接跑

```sh
npx @deepseek-ai/dsh web
```

---

## 3. 三种使用方式

### 方式一：Web UI（推荐，已验证 ✅）

```sh
pnpm dsh web
# 或
npx @deepseek-ai/dsh web
```

启动后访问 **http://127.0.0.1:3080**。

**首次使用四步：**

1. **关闭「内测声明」** 对话框（点击「继续」）。
2. **添加 API Key**：填入 DeepSeek API 密钥后「保存并继续」，或点「稍后配置」稍后再填。
3. **选择工作区**：点「选择工作区」→「添加工作区」，选中项目目录（默认是启动 `dsh` 时所在目录）。
4. **发送任务**：输入如 `Summarize this repository and identify its main packages.`

Web 界面支持读写工作区文件、运行命令、委派任务、维护计划；涉及需要审批的操作时会弹窗询问。

**常用参数：**

```sh
pnpm dsh web --port 8080              # 换端口
pnpm dsh web --host 0.0.0.0           # 绑定所有网卡（注意：CLI 目前不支持，会报用法错误）
pnpm dsh web --trusted-host myhost    # 添加 /api 浏览器信任的 authority（可重复）
pnpm dsh web --help                   # web 应用自己的帮助
```

### 方式二：Headless 无头模式（跑一次性任务）

```sh
# 先在 .env 或环境变量里设置密钥（仓库根 .env 已被 gitignore）
# DEEPSEEK_API_KEY=sk-...
# DEEPSEEK_BASE_URL=https://...   # 可选，默认公共 API

pnpm dsh --profile headless "fix the failing test in this workspace"
```

特点：接受一项非空任务 → 创建并持久化新会话 → 打印最终回答 → 退出（成功返回 0）。

### 方式三：Python SDK（程序化调用）

要求 Python 3.10+（注意：**持久 PTY 后端不支持 Windows**，官方建议 Linux/macOS）。

```sh
python -m venv .venv
. .venv/bin/activate
python -m pip install deepseek-harness-sdk
export DEEPSEEK_API_KEY=sk-your-key-here
python examples/jsonrpc-agent/minimal.py \
  --workspace /abs/path/to/workspace \
  --session-root /abs/path/to/sessions \
  --session-id example-001 \
  "Inspect the repository and fix the failing tests."
```

---

## 4. 配置模型

- **Web UI**：`设置(Settings) → Models` → 在 DeepSeek 卡片填入 API Key 保存。密钥只写不回显，存于 `$DSH_HOME/.credentials.yaml`。
- **其他厂商**：`Add provider` 选择 Anthropic / OpenAI 等；Bedrock / Vertex / Azure / Codex 需各自的原生凭据。
- **自定义网关/自托管**：`Add a custom provider`，填小写 Provider ID、Base URL、API 协议、凭据、至少一个模型。
- **手动加视觉模型**：在 `$DSH_HOME/settings.yaml` 给模型加 `input: [text, image]`。

**常见报错：**

| 错误 | 处理 |
|---|---|
| `MISSING_CREDENTIAL` | 在 Models 页存 key，或设置对应环境变量 |
| `UNKNOWN_MODEL` | 选择已配置的模型，或给自定义 provider 补上模型 |
| 获取模型列表 401 | 检查 key；不提供 `GET /models` 的端点需手动填模型 |

---

## 5. 常用命令速查

| 命令 | 作用 |
|---|---|
| `dsh web` | 启动 Web UI（`--profile web` 的别名） |
| `dsh --profile headless "任务"` | 一次性无头任务，打印结果后退出 |
| `dsh --profile <name>` | 启动指定 profile |
| `dsh plugin --profile <name> add <pkg>` | 安装插件（转发给 pnpm） |
| `dsh plugin --profile <name> remove <pkg>` | 移除插件 |
| `dsh --profile web --dump-config` | 查看组合后的完整配置树 |
| `dsh --profile web --dump-default-config` | 查看默认配置（不含用户 patch 层） |
| `dsh --help` | 启动器自身帮助 |
| `dsh web --help` | Web 应用参数帮助 |

> 启动器 flag 必须在应用参数之前：`dsh web --port 8080` 中 `--port` 属于 web 应用。

---

## 6. 关键环境变量

| 变量 | 作用 |
|---|---|
| `DEEPSEEK_API_KEY` | DeepSeek API 密钥 |
| `DEEPSEEK_BASE_URL` | 自定义 OpenAI 兼容端点（默认公共 API） |
| `DSH_MODEL` | 默认模型（如 `deepseek-v4-flash`） |
| `DSH_HOME` | 配置目录（默认 `~/.dsh`），含 `profiles/`、`.credentials.yaml`、`settings.yaml` |
| `DSH_PERMISSION_MODE` | 进程级权限后备值（默认新会话为 `workspace-write`） |
| `DSH_TOOLS_MODE` | `native` / `code` / `both` |
| `DSH_TELEMETRY_MODE` | 遥测：`FULL` / `FEEDBACK_ONLY`；`DSH_TELEMETRY_DISABLED` 非空则强制关闭 |
| `NODE_USE_ENV_PROXY=1` | 需要走 `HTTP_PROXY` / `HTTPS_PROXY` 时设置 |

凭据解析顺序：继承环境 → `$DSH_HOME/.credentials.yaml` → 调用目录 `.env` → `$DSH_HOME/.env`。

---

## 7. 插件体系（dsh 的核心）

- 内置组合包：`@deepseek-ai/dsh-base`、`@deepseek-ai/dsh-web-app`、`@deepseek-ai/dsh-headless`。
- 外部插件按 `dsh.profile.bundles` 顺序叠加 patch 层，用户覆盖在 `cordis.patch.yml`。
- 安装 Git 插件：`dsh plugin --profile tui add github:deepseek-harness/turtle-ui`（首次可能因 pnpm `allowBuilds` 提示失败，按提示把构建键加到 profile 的 `pnpm-workspace.yaml` 后重试）。
- 在 GitHub 给插件仓库打上 `dsh-plugin` 话题便于被发现。
- 开发插件从 [docs/user/develop/basic](docs/user/develop/basic/) 开始。

---

## 8. 官方示例（`examples/`）

| 目录 | 说明 | 启动方式 |
|---|---|---|
| `headless-agent` | 无头 coding agent（DeepSeek V4 + bash/FS + subagent） | `pnpm dsh --profile headless "任务"` |
| `jsonrpc-agent` | Python SDK + JSON-RPC 的无人值守 agent | Python SDK |
| `web-cordis` | 自指 agent，可检查和修改内存中的 Cordis 插件树 | — |
| `web-schedule` | Web 上的定时提醒 overlay | `dsh web --patch examples/web-schedule/cordis.yml` |
| `acp-agent` | ACP 自动化服务器（程序化客户端） | — |
| `mcp-memory` | MCP 客户端连外部记忆服务器 | — |

---

## 9. 排障

- **启动失败提示 `run pnpm run build`**：源码运行必须先构建（`pnpm run build`），且构建产物要最新。
- **端口被占用**：`dsh web --port 0` 让系统随机分配端口。
- **服务器打印 URL 但页面 404**：等 profile 初始化完成再刷新页面。
- **Web UI 修改不生效**：宿主每次请求都会重新读 `index.html` 与静态资源，改完构建产物后**刷新页面**即可，无需重启服务器。
- **更多文档**：`docs/user/`（用户）、`docs/development.md`（开发）、`docs/architecture.md`（架构）、`docs/cookbook/`。

---

## 10. 今日实测记录

- ✅ 克隆 + `pnpm install` + `pnpm run build` 全部成功（Windows，Node v22.23.1）
- ✅ `pnpm dsh web` 启动成功，打印 `dsh web: http://127.0.0.1:3080`
- ✅ Web UI 正常显示「内测声明」→「添加 API Key」→ 主界面（选择工作区 / 标准模式）
- ✅ `dsh web --help` 参数解析正常
