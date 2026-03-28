#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"
MODE="${1:-}"
WITH_HISTORY=0

if [[ -z "$MODE" ]]; then
  echo "usage: $0 <safe|power> [--with-history]" >&2
  exit 1
fi

shift || true
while [[ $# -gt 0 ]]; do
  case "$1" in
    --with-history)
      WITH_HISTORY=1
      ;;
    *)
      echo "unknown argument: $1" >&2
      exit 1
      ;;
  esac
  shift
done

case "$MODE" in
  safe|power)
    ;;
  *)
    echo "mode must be 'safe' or 'power'" >&2
    exit 1
    ;;
esac

CODEX_HOME="${CODEX_HOME:-$HOME/.codex}"
CONFIG_PATH="${CODEX_CONFIG_PATH:-$CODEX_HOME/config.toml}"
INSTALL_SCRIPT="${REPO_DIR}/scripts/install-codex-mcp.sh"
MARKER_BEGIN="# >>> bb-browser-safe >>>"
BEGIN_LINE="[mcp_servers.bb_browser_safe]"

if [[ ! -f "$CONFIG_PATH" ]] || ! grep -Fq "$MARKER_BEGIN" "$CONFIG_PATH"; then
  echo "Codex MCP block not found, installing it first..."
  bash "$INSTALL_SCRIPT" >/dev/null
fi

if ! grep -Fq "$BEGIN_LINE" "$CONFIG_PATH"; then
  echo "bb_browser_safe config block not found in $CONFIG_PATH" >&2
  exit 1
fi

if [[ "$MODE" == "safe" ]]; then
  SAFE_MODE_VALUE="1"
  ENABLE_VALUE="0"
else
  SAFE_MODE_VALUE="0"
  ENABLE_VALUE="1"
fi

TMP_FILE="$(mktemp)"

awk \
  -v safe="$SAFE_MODE_VALUE" \
  -v enabled="$ENABLE_VALUE" '
  function replace_safe(line) {
    sub(/=.*/, "= \"" safe "\"", line)
    return line
  }
  function replace_enabled(line) {
    sub(/=.*/, "= \"" enabled "\"", line)
    return line
  }
  {
    if ($0 ~ /^BB_BROWSER_SAFE_MODE[[:space:]]*=/) {
      print replace_safe($0)
      next
    }
    if ($0 ~ /^BB_BROWSER_ENABLE_EVAL[[:space:]]*=/) {
      print replace_enabled($0)
      next
    }
    if ($0 ~ /^BB_BROWSER_ENABLE_NETWORK[[:space:]]*=/) {
      print replace_enabled($0)
      next
    }
    if ($0 ~ /^BB_BROWSER_ENABLE_SITE_RUN[[:space:]]*=/) {
      print replace_enabled($0)
      next
    }
    if ($0 ~ /^BB_BROWSER_ENABLE_SITE_RECOMMEND[[:space:]]*=/) {
      print replace_enabled($0)
      next
    }
    if ($0 ~ /^BB_BROWSER_ENABLE_SITE_UPDATE[[:space:]]*=/) {
      print replace_enabled($0)
      next
    }
    if ($0 ~ /^BB_BROWSER_ALLOW_COMMUNITY_SITES[[:space:]]*=/) {
      print replace_enabled($0)
      next
    }
    if ($0 ~ /^BB_BROWSER_ALLOW_COMMUNITY_UPDATES[[:space:]]*=/) {
      print replace_enabled($0)
      next
    }
    if ($0 ~ /^BB_BROWSER_ALLOW_HISTORY_RECOMMEND[[:space:]]*=/) {
      print replace_enabled($0)
      next
    }

    print
  }
' "$CONFIG_PATH" > "$TMP_FILE"

cat "$TMP_FILE" > "$CONFIG_PATH"
rm -f "$TMP_FILE"

if [[ "$WITH_HISTORY" == "1" ]]; then
  node - "$MODE" "$REPO_DIR/packages/extension/manifest.json" "$REPO_DIR/extension/manifest.json" <<'EOF'
const fs = require("node:fs");
const [, , mode, ...manifestPaths] = process.argv;

for (const manifestPath of manifestPaths) {
  if (!fs.existsSync(manifestPath)) {
    continue;
  }

  const manifest = JSON.parse(fs.readFileSync(manifestPath, "utf8"));
  const permissions = Array.isArray(manifest.permissions) ? [...manifest.permissions] : [];
  const nextPermissions = permissions.filter((permission) => permission !== "history");

  if (mode === "power") {
    nextPermissions.push("history");
  }

  manifest.permissions = nextPermissions;
  fs.writeFileSync(manifestPath, `${JSON.stringify(manifest, null, 2)}\n`);
}
EOF
fi

cat <<EOF
Switched Codex MCP config to ${MODE} mode:
  $CONFIG_PATH

MCP behavior:
  BB_BROWSER_SAFE_MODE=${SAFE_MODE_VALUE}
  eval/network/site_run/site_recommend/site_update/community adapters=${ENABLE_VALUE}
EOF

if [[ "$WITH_HISTORY" == "1" ]]; then
  cat <<EOF

Extension behavior:
  history permission $( [[ "$MODE" == "power" ]] && printf 'enabled' || printf 'disabled' )

Next step:
  Reload the unpacked extension in chrome://extensions/
EOF
else
  cat <<'EOF'

Extension behavior:
  unchanged

Note:
  Browser history access is the only power-mode feature that also needs an extension permission change.
  If you want it, rerun with --with-history and then reload the unpacked extension in chrome://extensions/
EOF
fi

cat <<'EOF'

Final step:
  Restart Codex so it reloads MCP config.
EOF
