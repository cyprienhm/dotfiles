import type { ExtensionAPI } from "@earendil-works/pi-coding-agent";
import { spawnSync } from "node:child_process";
import { existsSync, realpathSync } from "node:fs";
import { dirname, isAbsolute, relative, resolve, sep } from "node:path";
import { Input, Key, matchesKey, SelectList, truncateToWidth } from "@earendil-works/pi-tui";

export default function (pi: ExtensionAPI) {
  let mode: "normal" | "read-only" = "read-only";
  const grants = { read: new Set<string>(), write: new Set<string>() };
  const fileGrants = { read: new Set<string>(), write: new Set<string>() };
  const inside = (path: string, dir: string) => {
    const rel = relative(dir, path);
    return rel === "" || (rel !== ".." && !rel.startsWith(`..${sep}`) && !isAbsolute(rel));
  };
  const canonical = (path: string) => {
    let ancestor = path;
    while (!existsSync(ancestor) && dirname(ancestor) !== ancestor) ancestor = dirname(ancestor);
    return resolve(realpathSync(ancestor), relative(ancestor, path));
  };
  const ignored = (path: string) => {
    let dir = dirname(path);
    while (!existsSync(dir) && dirname(dir) !== dir) dir = dirname(dir);
    const root = spawnSync("git", ["-C", dir, "rev-parse", "--show-toplevel"], { encoding: "utf8" });
    if (root.status !== 0) return false;
    const result = spawnSync("git", ["-C", root.stdout.trim(), "check-ignore", "--no-index", "-q", "--", path]);
    return result.status === 0;
  };
  const approve = async (ctx: any, title: string, message: string) =>
    ctx.hasUI && await ctx.ui.confirm(title, message);

  pi.registerCommand("ro", {
    description: "Enable read-only mode (confirm non-read tool calls)",
    handler: async () => {
      mode = "read-only";
      pi.events.emit("access-guard:mode", mode);
    },
  });
  pi.registerCommand("ok", {
    description: "Enable normal mode",
    handler: async () => {
      mode = "normal";
      pi.events.emit("access-guard:mode", mode);
    },
  });
  pi.on("session_start", () => {
    grants.read.clear();
    grants.write.clear();
    fileGrants.read.clear();
    fileGrants.write.clear();
    mode = "read-only";
    pi.events.emit("access-guard:mode", mode);
  });
  pi.on("tool_call", async (event, ctx) => {
    if (event.toolName === "read" || event.toolName === "write" || event.toolName === "edit") {
      const action: "read" | "write" = event.toolName === "read" ? "read" : "write";
      const raw = event.input.path;
      if (typeof raw !== "string") return { block: true, reason: "Invalid file path" };
      const path = canonical(resolve(ctx.cwd, raw));
      const cwd = canonical(ctx.cwd);
      if (!inside(path, cwd) || ignored(path)) {
        if (!fileGrants[action].has(path) && ![...grants[action]].some((dir) => inside(path, dir))) {
          if (!ctx.hasUI) return { block: true, reason: `${action} access denied: ${path}` };
          const parent = dirname(path);
          const grandparent = dirname(parent);
          const choices = [
            `File: ${path}`,
            `Directory: ${parent}`,
            ...(grandparent !== parent ? [`Directory: ${grandparent}`] : []),
            "Deny",
          ];
          const title = `Grant ${action} access for this session? (${!inside(path, cwd) ? "outside working directory" : "git-ignored"})`;
          let decision: { choice?: string; reason?: string };
          if (ctx.mode === "tui") {
            decision = await ctx.ui.custom<{ choice?: string; reason?: string }>((tui, theme, _kb, done) => {
              const list = new SelectList(choices.map((label) => ({ value: label, label })), choices.length, {
                selectedPrefix: (text) => theme.fg("accent", text),
                selectedText: (text) => theme.fg("accent", text),
                description: (text) => theme.fg("muted", text),
                scrollInfo: (text) => theme.fg("dim", text),
                noMatch: (text) => theme.fg("muted", text),
              });
              const input = new Input({ prompt: "Reason: ", placeholder: "optional; Enter to deny" });
              const denying = () => list.getSelectedItem()?.value === "Deny";
              list.onSelectionChange = () => { input.focused = denying(); tui.requestRender(); };
              list.onSelect = (item) => done({ choice: item.value, reason: item.value === "Deny" ? input.getValue() : undefined });
              list.onCancel = () => done({ choice: "Deny" });
              input.onSubmit = (reason) => done({ choice: "Deny", reason });
              return {
                get focused() { return input.focused; },
                set focused(value: boolean) { input.focused = value && denying(); },
                render(width: number) {
                  return [truncateToWidth(theme.fg("accent", title), width), ...list.render(width), ...(denying() ? input.render(width) : [])];
                },
                invalidate() { list.invalidate(); input.invalidate(); },
                handleInput(data: string) {
                  if (denying() && !matchesKey(data, Key.up) && !matchesKey(data, Key.down) && !matchesKey(data, Key.escape)) input.handleInput(data);
                  else list.handleInput(data);
                  input.focused = denying();
                  tui.requestRender();
                },
              };
            }) ?? { choice: "Deny" };
          } else {
            const choice = await ctx.ui.select(title, choices);
            const reason = choice === "Deny" ? await ctx.ui.input("Reason for denial (optional)") : undefined;
            decision = { choice, reason };
          }
          if (decision.choice === choices[0]) fileGrants[action].add(path);
          else if (decision.choice === choices[1]) grants[action].add(parent);
          else if (decision.choice === choices[2] && grandparent !== parent) grants[action].add(grandparent);
          else return { block: true, reason: decision.reason?.trim() ? `${action} access denied: ${decision.reason.trim()}` : `${action} access denied` };
        }
      }
    }
    if (mode === "read-only" && event.toolName !== "read") {
      if (!await approve(ctx, `Allow ${event.toolName} in read-only mode?`, JSON.stringify(event.input).slice(0, 2000))) {
        return { block: true, reason: `Tool denied in read-only mode: ${event.toolName}` };
      }
    }
  });
}
