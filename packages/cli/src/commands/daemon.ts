import { getDaemonStatus, isDaemonRunning } from "../daemon-manager.js";

export interface DaemonOptions {
  json?: boolean;
  host?: string;
}

export async function statusCommand(
  options: DaemonOptions = {}
): Promise<void> {
  const running = await isDaemonRunning();
  const status = await getDaemonStatus();

  if (options.json) {
    console.log(JSON.stringify(status ?? { running, extensionConnected: false, pendingRequests: 0, uptime: 0 }));
  } else {
    if (status?.running) {
      const extText = status.extensionConnected ? "已连接扩展" : "扩展未连接";
      console.log(`Daemon 运行中，${extText}`);
    } else {
      console.log("浏览器未运行");
    }
  }
}
