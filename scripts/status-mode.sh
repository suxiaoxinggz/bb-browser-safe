#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"
CODEX_HOME="${CODEX_HOME:-$HOME/.codex}"
CONFIG_PATH="${CODEX_CONFIG_PATH:-$CODEX_HOME/config.toml}"
PACKAGE_MANIFEST="${REPO_DIR}/packages/extension/manifest.json"
BUILT_MANIFEST="${REPO_DIR}/extension/manifest.json"

read_config_value() {
  local key="$1"

  if [[ ! -f "$CONFIG_PATH" ]]; then
    return 1
  fi

  awk -F'"' -v wanted="$key" '
    $1 ~ ("^" wanted "[[:space:]]*=") {
      print $2
      found = 1
      exit
    }
    END {
      if (!found) {
        exit 1
      }
    }
  ' "$CONFIG_PATH"
}

manifest_history_status() {
  local manifest_path="$1"

  if [[ ! -f "$manifest_path" ]]; then
    echo "missing"
    return 0
  fi

  node - "$manifest_path" <<'EOF'
const fs = require("node:fs");
const manifestPath = process.argv[2];
const manifest = JSON.parse(fs.readFileSync(manifestPath, "utf8"));
const permissions = Array.isArray(manifest.permissions) ? manifest.permissions : [];
process.stdout.write(permissions.includes("history") ? "enabled" : "disabled");
EOF
}

SAFE_MODE="$(read_config_value "BB_BROWSER_SAFE_MODE" || true)"
ENABLE_EVAL="$(read_config_value "BB_BROWSER_ENABLE_EVAL" || true)"
ENABLE_NETWORK="$(read_config_value "BB_BROWSER_ENABLE_NETWORK" || true)"
ENABLE_SITE_RUN="$(read_config_value "BB_BROWSER_ENABLE_SITE_RUN" || true)"
ENABLE_SITE_RECOMMEND="$(read_config_value "BB_BROWSER_ENABLE_SITE_RECOMMEND" || true)"
ENABLE_SITE_UPDATE="$(read_config_value "BB_BROWSER_ENABLE_SITE_UPDATE" || true)"
ALLOW_COMMUNITY_SITES="$(read_config_value "BB_BROWSER_ALLOW_COMMUNITY_SITES" || true)"
ALLOW_COMMUNITY_UPDATES="$(read_config_value "BB_BROWSER_ALLOW_COMMUNITY_UPDATES" || true)"
ALLOW_HISTORY_RECOMMEND="$(read_config_value "BB_BROWSER_ALLOW_HISTORY_RECOMMEND" || true)"

if [[ -z "${SAFE_MODE:-}" ]]; then
  MODE="unknown"
elif [[ "$SAFE_MODE" == "0" ]]; then
  MODE="power"
else
  MODE="safe"
fi

PACKAGE_HISTORY="$(manifest_history_status "$PACKAGE_MANIFEST")"
BUILT_HISTORY="$(manifest_history_status "$BUILT_MANIFEST")"

cat <<EOF
bb-browser-safe mode status

Codex config:
  path: $CONFIG_PATH
  mode: $MODE
  BB_BROWSER_SAFE_MODE=${SAFE_MODE:-unset}
  BB_BROWSER_ENABLE_EVAL=${ENABLE_EVAL:-unset}
  BB_BROWSER_ENABLE_NETWORK=${ENABLE_NETWORK:-unset}
  BB_BROWSER_ENABLE_SITE_RUN=${ENABLE_SITE_RUN:-unset}
  BB_BROWSER_ENABLE_SITE_RECOMMEND=${ENABLE_SITE_RECOMMEND:-unset}
  BB_BROWSER_ENABLE_SITE_UPDATE=${ENABLE_SITE_UPDATE:-unset}
  BB_BROWSER_ALLOW_COMMUNITY_SITES=${ALLOW_COMMUNITY_SITES:-unset}
  BB_BROWSER_ALLOW_COMMUNITY_UPDATES=${ALLOW_COMMUNITY_UPDATES:-unset}
  BB_BROWSER_ALLOW_HISTORY_RECOMMEND=${ALLOW_HISTORY_RECOMMEND:-unset}

Extension manifests:
  packages/extension/manifest.json: history ${PACKAGE_HISTORY}
  extension/manifest.json: history ${BUILT_HISTORY}
EOF
