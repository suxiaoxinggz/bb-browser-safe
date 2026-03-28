/**
 * 浏览器连接管理器 - 检测并连接 CDP
 */

import { DAEMON_BASE_URL, COMMAND_TIMEOUT, type DaemonStatus } from "@bb-browser/shared";
import { spawn } from "node:child_process";
import { fileURLToPath } from "node:url";
import { dirname, resolve } from "node:path";
import { existsSync } from "node:fs";
import { ensureCdpConnection } from "./cdp-client.js";
import { isManagedBrowserRunning } from "./cdp-discovery.js";

export function getDaemonPath(): string {
  const currentFile = fileURLToPath(import.meta.url);
  const currentDir = dirname(currentFile);
  const sameDirPath = resolve(currentDir, "daemon.js");
  if (existsSync(sameDirPath)) {
    return sameDirPath;
  }
  return resolve(currentDir, "../../daemon/dist/index.js");
}

export async function getDaemonStatus(): Promise<DaemonStatus | null> {
  const controller = new AbortController();
  const timeout = setTimeout(() => controller.abort(), 2000);

  try {
    const response = await fetch(`${DAEMON_BASE_URL}/status`, {
      signal: controller.signal,
    });

    if (!response.ok) {
      return null;
    }

    return await response.json() as DaemonStatus;
  } catch {
    return null;
  } finally {
    clearTimeout(timeout);
  }
}

export async function isDaemonRunning(): Promise<boolean> {
  const status = await getDaemonStatus();
  return !!status?.running;
}

export async function stopDaemon(): Promise<boolean> {
  return false;
}

export async function ensureDaemonRunning(): Promise<void> {
  const daemonStatus = await getDaemonStatus();
  if (daemonStatus?.running) {
    return;
  }

  const daemonPath = getDaemonPath();
  const child = spawn(process.execPath, [daemonPath], {
    detached: true,
    stdio: "ignore",
    env: { ...process.env },
  });
  child.unref();

  const deadline = Date.now() + Math.min(COMMAND_TIMEOUT, 5000);
  while (Date.now() < deadline) {
    const status = await getDaemonStatus();
    if (status?.running) {
      return;
    }
    await new Promise((resolve) => setTimeout(resolve, 200));
  }

  // Fallback to direct CDP for users still relying on managed browser mode.
  try {
    await ensureCdpConnection();
  } catch (error) {
    if (error instanceof Error && error.message.includes("No browser connection found")) {
      throw new Error([
        "bb-browser: Could not connect to daemon or managed browser.",
        "",
        "If you use the Chrome extension flow, make sure the bb-browser extension is loaded and connected.",
        "If you use managed browser mode, make sure Chrome is installed, then try again.",
        "Or specify a CDP port manually: bb-browser --port 9222",
      ].join("\n"));
    }
    throw error;
  }
}
