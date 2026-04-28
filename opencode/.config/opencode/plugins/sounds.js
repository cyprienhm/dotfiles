import { readdirSync } from "node:fs";
import { spawn } from "node:child_process";
import { homedir } from "node:os";
import { join } from "node:path";

const SOUNDS_DIR = join(homedir(), ".config/opencode/sounds/sc2_toss_probe");
const VOLUME = "0.2";

const EVENT_TO_CATEGORY = {
  "session.created": "session-start",
  "session.idle": "task-complete",
  "permission.asked": "input-required",
  "session.error": "task-error",
  "session.compacted": "resource-limit",
};

let currentProc = null;

const play = (category) => {
  const dir = join(SOUNDS_DIR, category);
  let files;
  try {
    files = readdirSync(dir).filter((f) => /\.(mp3|ogg|wav)$/i.test(f));
  } catch {
    return;
  }
  if (files.length === 0) return;

  const sound = join(dir, files[Math.floor(Math.random() * files.length)]);

  if (currentProc && !currentProc.killed) {
    try {
      currentProc.kill();
    } catch {}
  }
  currentProc = spawn("afplay", ["-v", VOLUME, sound], {
    detached: true,
    stdio: "ignore",
  });
  currentProc.unref();
};

export const SoundsPlugin = async () => {
  return {
    event: async ({ event }) => {
      const category = EVENT_TO_CATEGORY[event.type];
      if (category) play(category);
    },
  };
};
