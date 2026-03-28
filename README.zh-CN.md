# bb-browser-safe

这是 [`epiral/bb-browser`](https://github.com/epiral/bb-browser) 的一个加固 fork，面向 Codex、Claude Code 以及类似 MCP 客户端的本地 agent 使用场景。

这个 fork 保留了原项目“直接控制真实浏览器”的核心能力，但把默认信任模型改成了更保守的版本：

- 默认开启安全模式
- 高风险 MCP 工具默认关闭，只有显式启用才会暴露
- 社区 adapter 默认禁用
- 禁用后台静默 `git pull`
- Chrome 扩展移除了 `history` 权限
- CLI 优先走真实的 `daemon + extension` 主链路，而不是旧的受管浏览器 CDP 探测路径
- MCP 增加了一个只读 resource，避免 Codex 对 `resources/list` 打警告

## 为什么要做这个 fork

上游 `bb-browser` 很强，但它的默认假设更偏向“能力最大化”，而不是“边界收紧”：

- 它可以在真实登录态页面里执行任意 JavaScript
- 它可以查看网络请求与浏览器历史
- 它可以从远端仓库拉取并执行社区 adapter 代码
- 它的 CLI 同时混用了两条执行链路：直接 CDP 和 daemon + extension

对于 Codex 这种 agent 驱动环境，这套默认值过于宽松。这个 fork 的目标不是去掉能力，而是把默认值改成“先安全、再按需显式解锁”。

也就是说，这个 fork 的默认策略是不立刻信任：

- 远端 adapter 代码
- 历史记录推荐逻辑
- 任意页面 `eval`
- 抓包和 body 读取能力

## 与上游的主要差异

| 维度 | 上游 `bb-browser` | `bb-browser-safe` |
|---|---|---|
| MCP 默认值 | 暴露完整浏览器控制面 | 默认安全模式 |
| `browser_eval` | 默认启用 | 默认关闭 |
| `browser_network` | 默认启用 | 默认关闭 |
| `site_run` | 默认启用 | 默认关闭 |
| `site_update` | 默认启用 | 默认关闭 |
| 社区 adapter | 默认读取 `~/.bb-browser/bb-sites` | 除非显式启用，否则忽略 |
| 自动更新 | 后台静默 `git pull` | 禁用 |
| 扩展权限 | 包含 `history` | 移除 `history` |
| Codex resources | 不实现 resources，会对 `resources/list` 报警告 | 增加无害只读状态 resource |
| CLI 通信路径 | 经常回退到受管浏览器 CDP 探测 | 优先走 daemon + extension |

## 分支与提交说明

这个仓库被刻意拆成 3 个阶段，便于你按需对比、cherry-pick 或只使用其中一层。

### `phase-1-safe-defaults`

提交：`e0fe5c6`

这一阶段的改动：

- 在 MCP 里加入安全模式开关
- 默认关闭高风险工具
- 默认禁用社区 adapter
- 默认禁用历史推荐
- 禁用静默 adapter 更新
- 去掉扩展的 `history` 权限

如果你只想要“安全默认值收紧”，但暂时不关心 Codex 本地安装体验，可以只看这个分支。

### `phase-2-codex-installer`

提交：`85ea7d8`

在 phase 1 基础上增加：

- Codex 安装脚本
- Codex MCP 配置模板
- 本地 Codex 安装文档

如果你想要“安全默认值 + 一套干净的 Codex 接入方式”，可以看这个分支。

### `phase-3-daemon-first-cli`

提交：`11c9952`

在 phase 2 基础上增加：

- CLI 改成优先走 daemon
- 修正 `status` 对 daemon/extension 状态的识别
- 修复扩展链路已经存在时 CLI 还误走旧 CDP 路径的问题
- MCP 增加只读 resource，修掉 `resources/list` 的 WARN

如果你想要“真正可用的完整 fork”，这个分支已经够用。

### `main`

当前 `main` 在 phase 3 基础上继续补了完整 README 和分支说明，适合作为公开默认分支使用。

## 仓库布局

- `main`：完整可用版本，适合日常使用
- `phase-1-safe-defaults`：只做安全基线收紧
- `phase-2-codex-installer`：安全基线 + Codex 安装工具
- `phase-3-daemon-first-cli`：安全基线 + Codex 安装 + CLI/daemon/resource 修复

## 安装

### 前置要求

- Node.js 18+
- `pnpm`
- Google Chrome 或 Brave
- 从本仓库 `extension/` 目录加载的 Chrome 扩展

### 本地构建

```bash
git clone https://github.com/suxiaoxinggz/bb-browser-safe.git
cd bb-browser-safe
pnpm install --frozen-lockfile
pnpm build
```

## Chrome 扩展安装

把已解压扩展加载自：

```bash
./extension
```

在 Chrome 中：

1. 打开 `chrome://extensions/`
2. 开启开发者模式
3. 点击“加载已解压的扩展程序”
4. 选择本仓库的 `extension/` 目录

加载后，扩展应该连接本地 daemon：`localhost:19824`。

## 给 Codex 安装

这个仓库自带一个本地安装脚本：

```bash
cd /Users/suxiaoxing/bb-browser-safe
pnpm install --frozen-lockfile
pnpm build
bash scripts/install-codex-mcp.sh
```

脚本会往 `~/.codex/config.toml` 追加一个受管理配置块，形式如下：

```toml
[mcp_servers.bb_browser_safe]
command = "node"
args = ["/Users/suxiaoxing/bb-browser-safe/dist/mcp.js"]
startup_timeout_sec = 60.0

[mcp_servers.bb_browser_safe.env]
BB_BROWSER_SAFE_MODE = "1"
BB_BROWSER_ENABLE_EVAL = "0"
BB_BROWSER_ENABLE_NETWORK = "0"
BB_BROWSER_ENABLE_SITE_RUN = "0"
BB_BROWSER_ENABLE_SITE_RECOMMEND = "0"
BB_BROWSER_ENABLE_SITE_UPDATE = "0"
BB_BROWSER_ALLOW_COMMUNITY_SITES = "0"
BB_BROWSER_ALLOW_COMMUNITY_UPDATES = "0"
BB_BROWSER_ALLOW_HISTORY_RECOMMEND = "0"
```

安装完成后：

1. 重启 Codex
2. 确认扩展仍然已加载
3. 用低风险命令做一次验证，例如 `tab list` 或 `snapshot`

## 运行模型

这个 fork 预期使用的是下面这条链路：

```text
Codex / MCP 客户端
  -> 本地 MCP server
  -> bb-browser daemon (localhost:19824)
  -> Chrome 扩展
  -> 真实浏览器标签页
```

这个 fork 里的 CLI 已调整为优先走这条链路。直接 CDP 连接只保留为兜底回退路径。

## 默认安全模式行为

当 `BB_BROWSER_SAFE_MODE=1` 时：

- 默认启用：
  - `browser_snapshot`
  - `browser_click`
  - `browser_fill`
  - `browser_type`
  - `browser_open`
  - `browser_tab_list`
  - `browser_tab_new`
  - `browser_press`
  - `browser_scroll`
  - `browser_screenshot`
  - `browser_get`
  - `browser_close`
  - `browser_close_all`
  - `browser_hover`
  - `browser_wait`
  - `site_list`
  - `site_search`
  - `site_info`

- 默认关闭：
  - `browser_eval`
  - `browser_network`
  - `site_run`
  - `site_recommend`
  - `site_update`

## 如何重新开启受限功能

如果你明确要恢复原版那种更高风险的行为，可以在启动 MCP 前设置环境变量：

```bash
export BB_BROWSER_ENABLE_EVAL=1
export BB_BROWSER_ENABLE_NETWORK=1
export BB_BROWSER_ENABLE_SITE_RUN=1
export BB_BROWSER_ENABLE_SITE_RECOMMEND=1
export BB_BROWSER_ENABLE_SITE_UPDATE=1
export BB_BROWSER_ALLOW_COMMUNITY_SITES=1
export BB_BROWSER_ALLOW_COMMUNITY_UPDATES=1
export BB_BROWSER_ALLOW_HISTORY_RECOMMEND=1
```

建议规则：

- 一次只开启一种能力
- 社区 adapter 只有在你看过源码之后再启用

## 本地 reviewed adapter

审查过的 adapter 建议放在：

```bash
~/.bb-browser/sites/
```

这个 fork 把这个目录视为更合理的本地信任边界。

## 快速验证

当 daemon 和扩展都连接后，可以这样验证：

```bash
node dist/cli.js status --json
node dist/cli.js tab list --json
node dist/cli.js snapshot -i --json
```

预期行为：

- `status` 显示 `running: true`
- `tab list` 返回真实标签页
- `snapshot` 在普通网页上成功，在 `chrome://extensions` 这种受限页面上失败

## 安全说明

这个 fork 的默认值比上游安全，但它依然是高权限软件。

它仍然可以：

- 控制你的真实浏览器
- 使用你的真实登录态
- 点击、输入、导航、读取页面内容

所以正确的心智模型应该是：

- 默认更安全
- 但它不是沙箱

## 推送这个仓库

如果你本地最初是从 upstream 克隆过来的，想发布到自己的远端，可以这样做：

```bash
cd /Users/suxiaoxing/bb-browser-safe
git remote rename origin upstream
git remote add origin https://github.com/suxiaoxinggz/bb-browser-safe.git
git push -u origin main
git push origin phase-1-safe-defaults
git push origin phase-2-codex-installer
git push origin phase-3-daemon-first-cli
```

## 许可证

MIT，继承自上游项目。
