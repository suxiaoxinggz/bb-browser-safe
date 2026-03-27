#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"
CODEX_HOME="${CODEX_HOME:-$HOME/.codex}"
CONFIG_PATH="${CODEX_CONFIG_PATH:-$CODEX_HOME/config.toml}"
TEMPLATE_PATH="${REPO_DIR}/codex/bb-browser-safe.toml.template"
MCP_ENTRY="${REPO_DIR}/dist/mcp.js"
EXTENSION_DIR="${REPO_DIR}/extension"
BACKUP_DIR="${CODEX_CONFIG_BACKUP_DIR:-$REPO_DIR/.codex-config-backups}"
MARKER_BEGIN="# >>> bb-browser-safe >>>"
MARKER_END="# <<< bb-browser-safe <<<"

if ! command -v node >/dev/null 2>&1; then
  echo "node is required but not found in PATH" >&2
  exit 1
fi

if ! command -v pnpm >/dev/null 2>&1; then
  echo "pnpm is required but not found in PATH" >&2
  exit 1
fi

if [[ ! -f "$TEMPLATE_PATH" ]]; then
  echo "template not found: $TEMPLATE_PATH" >&2
  exit 1
fi

if [[ ! -f "$MCP_ENTRY" || ! -d "$EXTENSION_DIR" ]]; then
  echo "build artifacts missing, running pnpm build..."
  (cd "$REPO_DIR" && pnpm build)
fi

mkdir -p "$(dirname "$CONFIG_PATH")"
mkdir -p "$BACKUP_DIR"
if [[ -f "$CONFIG_PATH" ]]; then
  BACKUP_PATH="${BACKUP_DIR}/$(basename "$CONFIG_PATH").bak.$(date +%Y%m%d%H%M%S)"
  cat "$CONFIG_PATH" > "$BACKUP_PATH"
else
  : > "$CONFIG_PATH"
  BACKUP_PATH="(new file, no backup created)"
fi

SNIPPET_CONTENT="$(sed "s|__MCP_PATH__|${MCP_ENTRY}|g" "$TEMPLATE_PATH")"
TMP_FILE="$(mktemp)"

awk -v begin="$MARKER_BEGIN" -v end="$MARKER_END" '
  $0 == begin { skip = 1; next }
  $0 == end { skip = 0; next }
  !skip { print }
' "$CONFIG_PATH" > "$TMP_FILE"

{
  cat "$TMP_FILE"
  [[ -s "$TMP_FILE" ]] && printf '\n'
  printf '%s\n' "$MARKER_BEGIN"
  printf '%s\n' "$SNIPPET_CONTENT"
  printf '%s\n' "$MARKER_END"
} > "$CONFIG_PATH"

rm -f "$TMP_FILE"

cat <<EOF
Installed Codex MCP config into:
  $CONFIG_PATH

Backup:
  $BACKUP_PATH

Configured server:
  [mcp_servers.bb_browser_safe]
  command = "node"
  args = ["$MCP_ENTRY"]

Safe mode defaults:
  BB_BROWSER_SAFE_MODE=1
  community adapters disabled
  eval/network/site_run/site_update/site_recommend disabled

Next steps:
1. Restart Codex so it reloads MCP config.
2. Load the Chrome extension from:
   $EXTENSION_DIR
3. If you need a reviewed local adapter, place it under:
   ~/.bb-browser/sites/
EOF
