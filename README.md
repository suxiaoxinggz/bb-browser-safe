# bb-browser-safe

Hardened fork of [`epiral/bb-browser`](https://github.com/epiral/bb-browser) for local agent use in Codex, Claude Code, and similar MCP clients.

This fork keeps the original browser-control model, but changes the default trust model:

- Safe mode is on by default
- High-risk MCP tools are disabled unless explicitly re-enabled
- Community adapters are disabled by default
- Silent background `git pull` is disabled
- Chrome extension `history` permission is removed
- CLI now prefers the real `daemon + extension` path instead of stale managed-browser CDP detection
- MCP exposes a small read-only resource so Codex stops warning on `resources/list`

## Why this fork exists

Upstream `bb-browser` is powerful, but its default assumptions are optimized for capability, not containment:

- it can execute page-context JavaScript with your real login state
- it can inspect network traffic and browser history
- it can pull and execute community adapter code from a remote repo
- its CLI mixes two different execution paths: direct CDP and daemon + extension

For agent-driven environments like Codex, those defaults are too permissive. This fork changes the defaults so the system is usable without immediately trusting:

- remote adapter code
- history-based recommendation logic
- arbitrary page `eval`
- network/body inspection

## Main differences from upstream

| Area | Upstream `bb-browser` | `bb-browser-safe` |
|---|---|---|
| MCP defaults | full browser/control surface | safe mode by default |
| `browser_eval` | enabled | disabled by default |
| `browser_network` | enabled | disabled by default |
| `site_run` | enabled | disabled by default |
| `site_update` | enabled | disabled by default |
| community adapters | loaded from `~/.bb-browser/bb-sites` | ignored unless explicitly enabled |
| background auto-update | silent `git pull` | disabled |
| extension permissions | includes `history` | `history` removed |
| Codex resources | no resources, warns on `resources/list` | ships a harmless read-only status resource |
| CLI transport | often falls back to managed-browser CDP path | prefers daemon + extension first |

## Branches and commits

This repo is intentionally organized in 3 steps so you can diff or cherry-pick only the layer you want.

### `phase-1-safe-defaults`

Commit: `e0fe5c6`

What it changes:

- adds safe-mode gating in MCP
- disables risky tools by default
- disables community adapters by default
- disables history recommendation by default
- disables silent adapter updates
- removes extension `history` permission

Use this if you only want the hardening layer and do not care about Codex-specific setup yet.

### `phase-2-codex-installer`

Commit: `85ea7d8`

Adds on top of phase 1:

- Codex installer script
- Codex MCP config template
- updated docs for local Codex installation

Use this if you want safe defaults plus a clean local install path for Codex.

### `main`

Commit: `11c9952`

Adds on top of phase 2:

- daemon-first CLI request routing
- fixed `status` command to report daemon/extension state correctly
- fixed CLI behavior when extension flow is active
- MCP read-only resource for `resources/list`

Use this if you want the complete usable fork.

## Repository layout

- `main`: complete fork for everyday use
- `phase-1-safe-defaults`: security baseline only
- `phase-2-codex-installer`: security baseline + Codex install tooling

## Installation

### Requirements

- Node.js 18+
- `pnpm`
- Google Chrome or Brave
- Chrome extension loaded from this repo's `extension/` directory

### Build locally

```bash
git clone https://github.com/suxiaoxinggz/bb-browser-safe.git
cd bb-browser-safe
pnpm install --frozen-lockfile
pnpm build
```

## Chrome extension setup

Load the unpacked extension from:

```bash
./extension
```

In Chrome:

1. Open `chrome://extensions/`
2. Enable Developer Mode
3. Click `Load unpacked`
4. Select this repo's `extension/` directory

Once loaded, the extension should connect to the local daemon on `localhost:19824`.

## Codex installation

This repo includes a local installer:

```bash
cd /Users/suxiaoxing/bb-browser-safe
pnpm install --frozen-lockfile
pnpm build
bash scripts/install-codex-mcp.sh
```

The installer appends a managed block to `~/.codex/config.toml` like this:

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

After installation:

1. Restart Codex
2. Make sure the extension is still loaded
3. Verify with a low-risk call such as a tab list or snapshot

## Runtime model

The intended execution path in this fork is:

```text
Codex / MCP client
  -> local MCP server
  -> bb-browser daemon (localhost:19824)
  -> Chrome extension
  -> real browser tab
```

The CLI has been adjusted to prefer this path first. Direct CDP fallback remains only as a backup path.

## Default safe-mode behavior

When `BB_BROWSER_SAFE_MODE=1`:

- enabled:
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

- disabled by default:
  - `browser_eval`
  - `browser_network`
  - `site_run`
  - `site_recommend`
  - `site_update`

## Re-enabling restricted features

If you explicitly want the original higher-risk behavior, set env vars before launching the MCP server:

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

Recommended rule:

- only enable one capability at a time
- only enable community adapters after reviewing the adapter source

## Local reviewed adapters

Put reviewed adapters under:

```bash
~/.bb-browser/sites/
```

This fork treats that directory as the preferred trust boundary.

## Quick verification

With daemon and extension connected:

```bash
node dist/cli.js status --json
node dist/cli.js tab list --json
node dist/cli.js snapshot -i --json
```

Expected behavior:

- `status` shows `running: true`
- `tab list` returns real tabs
- `snapshot` works on normal web pages and fails on restricted pages like `chrome://extensions`

## Security notes

This fork is safer than upstream by default, but it is still high privilege software.

It can still:

- drive your real browser
- use your real login state
- click, type, navigate, and read page content

So the right mental model is:

- safer defaults
- not a sandbox

## Pushing this repo

If you cloned locally from upstream and want to publish your own remote:

```bash
cd /Users/suxiaoxing/bb-browser-safe
git remote rename origin upstream
git remote add origin https://github.com/suxiaoxinggz/bb-browser-safe.git
git push -u origin main
git push origin phase-1-safe-defaults
git push origin phase-2-codex-installer
```

## License

MIT, inherited from upstream.
