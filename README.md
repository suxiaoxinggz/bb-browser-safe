<div align="center">

# bb-browser hardened

### BadBoy Browser

**Your browser is the API. No keys. No bots. No scrapers.**

[![npm](https://img.shields.io/npm/v/bb-browser?color=CB3837&logo=npm&logoColor=white)](https://www.npmjs.com/package/bb-browser)
[![Node.js](https://img.shields.io/badge/Node.js-18+-339933?logo=node.js&logoColor=white)](https://nodejs.org)
[![License](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)

[English](README.md) · [中文](README.zh-CN.md)

</div>

---

This fork keeps the browser-control core, but changes the trust model for agent use:

- MCP safe mode is on by default
- `browser_eval`, `browser_network`, `site_run`, `site_recommend`, and `site_update` are disabled unless explicitly re-enabled with env vars
- Community adapters are disabled by default
- Automatic background `git pull` is disabled
- The Chrome extension drops the `history` permission

You're already logged into Twitter, Reddit, YouTube, Zhihu, Bilibili, LinkedIn, GitHub — bb-browser lets AI agents **use that directly**.

```bash
bb-browser site twitter/search "AI agent"       # search tweets
bb-browser site zhihu/hot                        # trending on Zhihu
bb-browser site arxiv/search "transformer"       # search papers
bb-browser site eastmoney/stock "茅台"            # real-time stock quote
bb-browser site boss/search "AI engineer"        # search jobs
bb-browser site wikipedia/summary "Python"       # Wikipedia summary
bb-browser site youtube/transcript VIDEO_ID      # full transcript
bb-browser site stackoverflow/search "async"     # search SO questions
```

**103 commands across 36 platforms.** All using your real browser's login state. [Full list →](https://github.com/epiral/bb-sites)

## The idea

The internet was built for browsers. AI agents have been trying to access it through APIs — but 99% of websites don't offer one.

bb-browser flips this: **instead of forcing websites to provide machine interfaces, let machines use the human interface directly.** The adapter runs `eval` inside your browser tab, calls `fetch()` with your cookies, or invokes the page's own webpack modules. The website thinks it's you. Because it **is** you.

| | Playwright / Selenium | Scraping libs | bb-browser |
|---|---|---|---|
| Browser | Headless, isolated | No browser | Your real Chrome |
| Login state | None, must re-login | Cookie extraction | Already there |
| Anti-bot | Detected easily | Cat-and-mouse | Invisible — it IS the user |
| Complex auth | Can't replicate | Reverse engineer | Page handles it itself |

## Quick Start

### Install

```bash
npm install -g bb-browser
```

### Use

This hardened fork defaults to local-only, reviewed adapters:

```bash
bb-browser site list          # local adapters only
bb-browser site info foo/bar  # inspect a reviewed adapter
bb-browser site foo/bar       # run a reviewed local adapter
```

### OpenClaw (no extension needed)

If you use [OpenClaw](https://openclaw.ai), bb-browser runs directly through OpenClaw's built-in browser — no Chrome extension or daemon required:

```bash
bb-browser site reddit/hot --openclaw
bb-browser site xueqiu/hot-stock 5 --openclaw --jq '.items[] | {name, changePercent}'
```

Skill on ClawHub: [bb-browser-openclaw](https://clawhub.ai/yan5xu/bb-browser)

### Chrome Extension (standalone mode)

For use without OpenClaw (Claude Code MCP, standalone CLI):

1. Download from [Releases](https://github.com/epiral/bb-browser/releases/latest)
2. Unzip → `chrome://extensions/` → Developer Mode → Load unpacked

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

By default, the MCP server exposes only lower-risk browser tools plus `site_list`, `site_search`, and `site_info`.

To re-enable restricted capabilities, set env vars before launching:

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

### Codex install

This repo includes a local installer for Codex:

```bash
cd /Users/suxiaoxing/bb-browser-safe
pnpm install --frozen-lockfile
pnpm build
bash scripts/install-codex-mcp.sh
```

The installer appends a managed block to `~/.codex/config.toml` and points Codex at the local built MCP entry:

```toml
[mcp_servers.bb_browser_safe]
command = "node"
args = ["/Users/suxiaoxing/bb-browser-safe/dist/mcp.js"]
startup_timeout_sec = 60.0
```

After that, reload Codex and load the unpacked Chrome extension from `./extension`.

## 36 platforms, 103 commands

Community-driven via [bb-sites](https://github.com/epiral/bb-sites). One JS file per command.

In this hardened fork, community adapters are intentionally disabled by default. Copy reviewed adapters into `~/.bb-browser/sites/` or opt in explicitly with `BB_BROWSER_ALLOW_COMMUNITY_SITES=1`.

| Category | Platforms | Commands |
|----------|-----------|----------|
| **Search** | Google, Baidu, Bing, DuckDuckGo, Sogou WeChat | search |
| **Social** | Twitter/X, Reddit, Weibo, Xiaohongshu, Jike, LinkedIn, Hupu | search, feed, thread, user, notifications, hot |
| **News** | BBC, Reuters, 36kr, Toutiao, Eastmoney | headlines, search, newsflash, hot |
| **Dev** | GitHub, StackOverflow, HackerNews, CSDN, cnblogs, V2EX, Dev.to, npm, PyPI, arXiv | search, issues, repo, top, thread, package |
| **Video** | YouTube, Bilibili | search, video, transcript, popular, comments, feed |
| **Entertainment** | Douban, IMDb, Genius, Qidian | movie, search, top250 |
| **Finance** | Xueqiu, Eastmoney, Yahoo Finance | stock, hot stocks, feed, watchlist, search |
| **Jobs** | BOSS Zhipin, LinkedIn | search, detail, profile |
| **Knowledge** | Wikipedia, Zhihu, Open Library | search, summary, hot, question |
| **Shopping** | SMZDM | search deals |
| **Tools** | Youdao, GSMArena, Product Hunt, Ctrip | translate, phone specs, trending products |

## 10 minutes to add any website

```bash
bb-browser guide    # full tutorial
```

Tell your AI agent: *"turn XX website into a CLI"*. It reads the guide, reverse-engineers the API with `network --with-body`, writes the adapter, tests it, and submits a PR. All autonomously.

Three tiers of adapter complexity:

| Tier | Auth method | Example | Time |
|------|-------------|---------|------|
| **1** | Cookie (fetch directly) | Reddit, GitHub, V2EX | ~1 min |
| **2** | Bearer + CSRF token | Twitter, Zhihu | ~3 min |
| **3** | Webpack injection / Pinia store | Twitter search, Xiaohongshu | ~10 min |

We tested this: **20 AI agents ran in parallel, each independently reverse-engineered a website and produced a working adapter.** The marginal cost of adding a new website to the agent-accessible internet is approaching zero.

## What this means for AI agents

Without bb-browser, an AI agent's world is: **files + terminal + a few APIs with keys.**

With bb-browser: **files + terminal + the entire internet.**

An agent can now, in under a minute:

```bash
# Cross-platform research on any topic
bb-browser site arxiv/search "retrieval augmented generation"
bb-browser site twitter/search "RAG"
bb-browser site github search rag-framework
bb-browser site stackoverflow/search "RAG implementation"
bb-browser site zhihu/search "RAG"
bb-browser site 36kr/newsflash
```

Six platforms, six dimensions, structured JSON. Faster and broader than any human researcher.

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

All commands support `--json` output, `--jq <expr>` for inline filtering, and `--tab <id>` for concurrent multi-tab operations.

```bash
bb-browser site xueqiu/hot-stock 5 --jq '.items[] | {name, changePercent}'
# {"name":"云天化","changePercent":"2.08%"}
# {"name":"东芯股份","changePercent":"-7.60%"}

bb-browser site info xueqiu/stock   # view adapter args, example, domain
```

## Daemon configuration

The daemon binds to `localhost:19824` by default. You can customize the host with `--host`:

```bash
bb-browser daemon --host 127.0.0.1    # IPv4 only (fix macOS IPv6 issues)
bb-browser daemon --host 0.0.0.0      # listen on all interfaces (for Tailscale / ZeroTier remote access)
```

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
