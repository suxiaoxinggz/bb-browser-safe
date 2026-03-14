<div align="center">

# bb-browser

### BadBoy Browser

**Your browser is the API. No keys. No bots. No scrapers.**

[![npm](https://img.shields.io/npm/v/bb-browser?color=CB3837&logo=npm&logoColor=white)](https://www.npmjs.com/package/bb-browser)
[![Node.js](https://img.shields.io/badge/Node.js-18+-339933?logo=node.js&logoColor=white)](https://nodejs.org)
[![License](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)

[English](README.md) · [中文](README.zh-CN.md)

</div>

---

You're already logged into Reddit, Twitter, YouTube, Zhihu, Bilibili, Weibo, Douban, Xiaohongshu — bb-browser lets AI agents **use that directly**.

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

**50+ commands across 10 platforms.** All using your real browser's login state. [Full list →](https://github.com/epiral/bb-sites)

## Why this is different

Every browser automation tool can click buttons and fill forms. bb-browser does that too. But the real power is **site adapters** — pre-built commands that turn any website into a CLI/API, using your browser's login state.

How it works under the hood: the adapter runs `eval` inside your browser tab. It calls `fetch()` with your cookies, or invokes the page's own Vue/Pinia store actions. The website thinks it's you. Because it **is** you.

| | Playwright / Selenium | Scraping libs | bb-browser |
|---|---|---|---|
| Browser | Headless, isolated | No browser | Your real Chrome |
| Login state | None, must re-login | Cookie extraction | Already there |
| Anti-bot | Detected easily | Cat-and-mouse | Invisible — it IS the user |
| XHS signing | Can't replicate | Reverse engineer | Page signs it itself |

## Quick Start

### Install

```bash
npm install -g bb-browser
```

### Chrome Extension

1. Download from [Releases](https://github.com/epiral/bb-browser/releases/latest)
2. Unzip → `chrome://extensions/` → Developer Mode → Load unpacked

### Use

```bash
bb-browser site update    # pull 50+ community adapters
bb-browser site list      # see what's available
bb-browser site zhihu/hot # go
```

### MCP (Claude Code / Cursor)

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

## Site Adapters — the core feature

Community-driven via [bb-sites](https://github.com/epiral/bb-sites). One JS file per command.

| Platform | Commands | Auth |
|----------|----------|------|
| **Reddit** | me, posts, thread, context | Cookie |
| **Twitter/X** | user, thread | Bearer + CSRF |
| **GitHub** | me, repo, issues, issue-create, pr-create, fork | Cookie |
| **Hacker News** | top, thread | Public API |
| **Zhihu** | me, hot, question, search | Cookie |
| **Bilibili** | me, popular, ranking, search, video, comments, feed, history, trending | Cookie |
| **Weibo** | me, hot, feed, user, user_posts, post, comments | Cookie |
| **Douban** | search, movie, movie-hot, movie-top, top250, comments | Cookie |
| **YouTube** | search, video, comments, channel, feed, transcript | innertube |
| **Xiaohongshu** | me, feed, search, note, comments, user_posts | Pinia store |

### Create your own

```bash
bb-browser guide    # full tutorial
```

Tell your AI agent "turn XX website into a CLI" — it reads the guide, reverse-engineers the API with `network --with-body`, writes the adapter, tests it, and submits a PR. All autonomously.

## Also a full browser automation tool

```bash
bb-browser open https://example.com
bb-browser snapshot -i                # accessibility tree
bb-browser click @3                   # click element
bb-browser fill @5 "hello"            # fill input
bb-browser eval "document.title"      # run JS
bb-browser fetch URL --json           # authenticated fetch
bb-browser network requests --with-body --json  # capture traffic
bb-browser screenshot                 # take screenshot
```

All commands support `--json` output and `--tab <id>` for concurrent multi-tab operations.

## Architecture

```
AI Agent (Claude Code, Codex, Cursor, etc.)
       │ CLI or MCP (stdio)
       ▼
bb-browser CLI ──HTTP──▶ Daemon ──SSE──▶ Chrome Extension
                                              │
                                              ▼ chrome.debugger (CDP)
                                         Your Real Browser
```

## License

[MIT](LICENSE)
