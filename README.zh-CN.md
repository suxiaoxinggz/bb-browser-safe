<div align="center">

# bb-browser

### 坏孩子浏览器 BadBoy Browser

**你的浏览器就是 API。不需要密钥，不需要爬虫，不需要模拟。**

[![npm](https://img.shields.io/npm/v/bb-browser?color=CB3837&logo=npm&logoColor=white)](https://www.npmjs.com/package/bb-browser)
[![Node.js](https://img.shields.io/badge/Node.js-18+-339933?logo=node.js&logoColor=white)](https://nodejs.org)
[![License](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)

[English](README.md) · [中文](README.zh-CN.md)

</div>

---

你已经登录了知乎、微博、B站、豆瓣、小红书、Reddit、Twitter、YouTube — bb-browser 让 AI Agent **直接用你的登录态**。

```bash
bb-browser site zhihu/hot                    # 知乎热榜
bb-browser site weibo/hot                    # 微博热搜
bb-browser site bilibili/popular             # B站热门
bb-browser site douban/top250                # 豆瓣 Top 250
bb-browser site youtube/transcript VIDEO_ID  # YouTube 字幕全文
bb-browser site reddit/thread URL            # Reddit 讨论树
bb-browser site twitter/user elonmusk        # Twitter 用户资料
bb-browser site xiaohongshu/search 美食       # 小红书搜索
```

**10 个平台，50+ 个命令，全部用你真实浏览器的登录态。** [完整列表 →](https://github.com/epiral/bb-sites)

## 为什么它不一样

所有浏览器自动化工具都能点按钮、填表单，bb-browser 也能。但真正的杀手锏是 **Site Adapters** — 预置命令把任何网站变成 CLI/API，直接用你的登录态。

原理：adapter 在你的浏览器 tab 里跑 `eval`，用你的 Cookie 调 `fetch()`，或者直接调用页面自己的 Vue/Pinia store action。网站以为是你在操作。因为**就是你**。

| | Playwright / Selenium | 爬虫库 | bb-browser |
|---|---|---|---|
| 浏览器 | 无头、隔离环境 | 没有浏览器 | 你的真实 Chrome |
| 登录态 | 没有，要重新登录 | 偷 Cookie | 已经在了 |
| 反爬检测 | 容易被识别 | 猫鼠游戏 | 无法检测 — 它就是用户 |
| 小红书签名 | 无法复制 | 需要逆向 | 页面自己签名 |

## 快速开始

### 安装

```bash
npm install -g bb-browser
```

### Chrome 扩展

1. 从 [Releases](https://github.com/epiral/bb-browser/releases/latest) 下载 zip
2. 解压 → `chrome://extensions/` → 开发者模式 → 加载已解压的扩展程序

### 使用

```bash
bb-browser site update    # 拉取 50+ 社区适配器
bb-browser site list      # 看看有什么
bb-browser site zhihu/hot # 开搞
```

### MCP 接入（Claude Code / Cursor）

```json
{
  "mcpServers": {
    "bb-browser": {
      "command": "npx",
      "args": ["-y", "bb-browser", "--mcp"]
    }
  }
}
```

## Site Adapters — 核心能力

社区驱动，通过 [bb-sites](https://github.com/epiral/bb-sites) 维护。每个命令一个 JS 文件。

| 平台 | 命令 | 认证方式 |
|------|------|----------|
| **知乎** | me, hot, question, search | Cookie |
| **B站** | me, popular, ranking, search, video, comments, feed, history, trending | Cookie |
| **微博** | me, hot, feed, user, user_posts, post, comments | Cookie |
| **豆瓣** | search, movie, movie-hot, movie-top, top250, comments | Cookie |
| **小红书** | me, feed, search, note, comments, user_posts | Pinia store |
| **YouTube** | search, video, comments, channel, feed, transcript | innertube |
| **Reddit** | me, posts, thread, context | Cookie |
| **Twitter/X** | user, thread | Bearer + CSRF |
| **GitHub** | me, repo, issues, issue-create, pr-create, fork | Cookie |
| **Hacker News** | top, thread | 公开 API |

### 自己做一个

```bash
bb-browser guide    # 完整教程
```

跟你的 AI Agent 说「帮我把 XX 网站 CLI 化」— 它会读 guide，用 `network --with-body` 抓包逆向 API，写 adapter，测试，然后自己提 PR 到社区仓库。全程自动。

## 同时也是完整的浏览器自动化工具

```bash
bb-browser open https://example.com
bb-browser snapshot -i                # 可访问性树
bb-browser click @3                   # 点击元素
bb-browser fill @5 "hello"            # 填写输入框
bb-browser eval "document.title"      # 执行 JS
bb-browser fetch URL --json           # 带登录态的 fetch
bb-browser network requests --with-body --json  # 抓包
bb-browser screenshot                 # 截图
```

所有命令支持 `--json` 输出和 `--tab <id>` 多标签页并发操作。

## 架构

```
AI Agent (Claude Code, Codex, Cursor 等)
       │ CLI 或 MCP (stdio)
       ▼
bb-browser CLI ──HTTP──▶ Daemon ──SSE──▶ Chrome 扩展
                                              │
                                              ▼ chrome.debugger (CDP)
                                         你的真实浏览器
```

## 许可证

[MIT](LICENSE)
