/**
 * CDP 客户端 - 与 Chrome DevTools Protocol 通信
 */

import type { Request, Response } from "@bb-browser/shared";
import { COMMAND_TIMEOUT, DAEMON_BASE_URL } from "@bb-browser/shared";
import { applyJq } from "./jq.js";
import { sendCommand as sendCdpCommand } from "./cdp-client.js";
import { monitorCommand } from "./monitor-manager.js";

const MONITOR_ACTIONS = new Set(["network", "console", "errors", "trace"]);

let jqExpression: string | undefined;

export function setJqExpression(expression?: string): void {
  jqExpression = expression;
}

function printJqResults(response: Response): never {
  const target = response.data ?? response;
  const results = applyJq(target, jqExpression || ".");
  for (const result of results) {
    console.log(typeof result === "string" ? result : JSON.stringify(result));
  }
  process.exit(0);
}

export function handleJqResponse(response: Response): void {
  if (jqExpression) {
    printJqResults(response);
  }
}

async function sendDaemonCommand(request: Request): Promise<Response> {
  const controller = new AbortController();
  const timeoutId = setTimeout(() => controller.abort(), COMMAND_TIMEOUT);

  try {
    const response = await fetch(`${DAEMON_BASE_URL}/command`, {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify(request),
      signal: controller.signal,
    });

    const payload = await response.json() as Response;
    if (!response.ok && !payload) {
      throw new Error(`Daemon returned HTTP ${response.status}`);
    }

    return payload;
  } finally {
    clearTimeout(timeoutId);
  }
}

export async function sendCommand(request: Request): Promise<Response> {
  try {
    return await sendDaemonCommand(request);
  } catch {
    // Fall back for users still relying on direct CDP mode.
  }

  if (MONITOR_ACTIONS.has(request.action)) {
    try {
      return await monitorCommand(request);
    } catch {
      // Fallback to direct CDP if monitor is unavailable
      return sendCdpCommand(request);
    }
  }
  return sendCdpCommand(request);
}
