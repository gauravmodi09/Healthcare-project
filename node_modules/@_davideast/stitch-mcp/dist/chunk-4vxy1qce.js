import {
  clipboardy_default
} from "./chunk-384jmtpy.js";

// src/ui/copy-behaviors/clipboard.ts
import { writeFile, unlink } from "fs/promises";
import { spawn } from "child_process";
async function copyText(text) {
  await clipboardy_default.write(text);
}
async function copyJson(value) {
  const text = typeof value === "string" ? value : JSON.stringify(value, null, 2);
  await clipboardy_default.write(text);
}
function spawnAndWait(command, args) {
  return new Promise((resolve, reject) => {
    const proc = spawn(command, args, { stdio: "ignore" });
    proc.on("close", (code) => {
      if (code === 0) {
        resolve();
      } else {
        reject(new Error(`Process exited with code ${code}`));
      }
    });
    proc.on("error", reject);
  });
}
async function downloadImage(url) {
  const response = await fetch(url);
  if (!response.ok) {
    throw new Error(`Failed to download image: ${response.status}`);
  }
  return response.arrayBuffer();
}
async function downloadAndCopyImage(url) {
  const buffer = await downloadImage(url);
  const tempPath = `/tmp/stitch-clipboard-${Date.now()}.png`;
  await writeFile(tempPath, Buffer.from(buffer));
  const platform = process.platform;
  try {
    if (platform === "darwin") {
      await spawnAndWait("osascript", ["-e", `set the clipboard to (read (POSIX file "${tempPath}") as TIFF picture)`]);
    } else if (platform === "linux") {
      await spawnAndWait("xclip", ["-selection", "clipboard", "-t", "image/png", "-i", tempPath]);
    } else if (platform === "win32") {
      await spawnAndWait("powershell", ["-command", `Set-Clipboard -Path "${tempPath}"`]);
    }
  } finally {
    try {
      await unlink(tempPath);
    } catch {}
  }
}
async function downloadText(url) {
  const response = await fetch(url);
  if (!response.ok) {
    throw new Error(`Failed to download: ${response.status}`);
  }
  return response.text();
}
async function downloadAndCopyText(url) {
  const text = await downloadText(url);
  await clipboardy_default.write(text);
}

export { copyText, copyJson, downloadImage, downloadAndCopyImage, downloadText, downloadAndCopyText };

//# debugId=B0252088F86A7D0864756E2164756E21
