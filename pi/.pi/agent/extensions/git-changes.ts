import { access, mkdir, readFile } from "node:fs/promises";
import { constants } from "node:fs";
import { relative } from "node:path";
import {
	createEditToolDefinition, createWriteToolDefinition,
	type ExtensionAPI, type ExtensionContext,
} from "@earendil-works/pi-coding-agent";
import { truncateToWidth } from "@earendil-works/pi-tui";
import { getGitState, type ChangedFile, type GitState } from "./git-changes/git.ts";
import { UndoHistory } from "./git-changes/history.ts";
import { showChanges } from "./git-changes/viewer.ts";

// JSON quoting keeps newlines, tabs, and terminal control characters in paths inert.
const displayPath = (path: string) => /[\x00-\x1f\x7f]/.test(path) ? JSON.stringify(path) : path;
const counts = (file: ChangedFile) => file.binary ? "binary/large" : `+${file.added} -${file.removed}`;
const fileLine = (file: ChangedFile) => `${file.status} ${counts(file)} ${file.oldPath ? `${displayPath(file.oldPath)} -> ` : ""}${displayPath(file.path)}`;

export default function gitChanges(pi: ExtensionAPI) {
	const history = new UndoHistory();
	let current: ExtensionContext | undefined;
	let state: GitState = { root: null, files: [] };
	let timer: ReturnType<typeof setInterval> | undefined;
	let epoch = 0;
	let busy = false;
	let again = false;
	let visible = true;

	function render(ctx: ExtensionContext) {
		if (ctx.mode !== "tui") return;
		if (!visible) { ctx.ui.setWidget("git-changes", undefined); return; }
		ctx.ui.setWidget("git-changes", (_tui, theme) => ({
			invalidate() {},
			render(width: number) {
				if (!state.root) return [truncateToWidth(theme.fg("dim", "Git: not a repository"), width)];
				if (state.error) return [truncateToWidth(theme.fg("warning", state.error), width)];
				const lines = [theme.fg("muted", state.files.length
					? `Git changes (${state.files.length}) · staged + unstaged · /changes · /undo (${history.entries.length})`
					: `Git clean · /undo (${history.entries.length})`)];
				for (const file of state.files.slice(0, 8)) {
					const status = theme.fg(/[DU]/.test(file.status) ? "error" : /[A?]/.test(file.status) ? "success" : "warning", file.status);
					const delta = file.binary ? theme.fg("dim", counts(file))
						: `${theme.fg("success", `+${file.added}`)} ${theme.fg("error", `-${file.removed}`)}`;
					lines.push(`${status} ${delta} ${theme.fg("text", `${file.oldPath ? `${displayPath(file.oldPath)} -> ` : ""}${displayPath(file.path)}`)}`);
				}
				if (state.files.length > 8) lines.push(theme.fg("dim", `… ${state.files.length - 8} more; /changes for all`));
				return lines.map((line) => truncateToWidth(line, width));
			},
		}), { placement: "aboveEditor" });
	}
	async function refresh() {
		if (!current) return;
		if (busy) { again = true; return; }
		busy = true;
		const version = epoch, ctx = current;
		try {
			const next = await getGitState(ctx.cwd);
			if (version === epoch) { state = next; render(ctx); }
		} finally {
			busy = false;
			if (again) { again = false; void refresh(); }
		}
	}
	function stop() {
		if (timer) clearInterval(timer);
		timer = undefined;
		epoch++;
		current = undefined;
		history.clear();
	}
	pi.on("session_start", async (_event, ctx) => {
		stop();
		current = ctx;
		visible = true;
		state = { root: null, files: [] };
		await refresh();
		if (current === ctx && ctx.mode === "tui") timer = setInterval(() => { void refresh(); }, 2000);
	});
	pi.on("session_shutdown", stop);
	pi.on("session_tree", async (_event, ctx) => {
		// Disk does not follow conversation branches. Do not offer abandoned-branch mutations.
		history.clear(); current = ctx; await refresh();
	});
	pi.on("tool_execution_end", async () => { await refresh(); });
	pi.on("agent_end", async () => { await refresh(); });

	const warn = (ctx: ExtensionContext) => (message: string) => ctx.ui.notify(message, "warning");
	// Preserve Pi's schemas, renderers, exact replacement semantics, path resolution,
	// and per-file mutation queues. Capture at the actual filesystem write, not tool_call.
	pi.registerTool({
		...createEditToolDefinition(process.cwd()),
		async execute(id, params, signal, onUpdate, ctx) {
			return createEditToolDefinition(ctx.cwd, { operations: {
				readFile: (path) => readFile(path),
				access: (path) => access(path, constants.R_OK | constants.W_OK),
				writeFile: (path, content) => history.write(path, content, "edit", warn(ctx)),
			} }).execute(id, params, signal, onUpdate, ctx);
		},
	});
	pi.registerTool({
		...createWriteToolDefinition(process.cwd()),
		async execute(id, params, signal, onUpdate, ctx) {
			return createWriteToolDefinition(ctx.cwd, { operations: {
				mkdir: async (dir) => { await mkdir(dir, { recursive: true }); },
				writeFile: (path, content) => history.write(path, content, "write", warn(ctx)),
			} }).execute(id, params, signal, onUpdate, ctx);
		},
	});
	pi.registerCommand("changes", {
		description: "Show all Git changes, or hide/show the widget: /changes [hide|show]",
		handler: async (args, ctx) => {
			const action = args.trim().toLowerCase();
			if (action === "hide" || action === "show") {
				visible = action === "show";
				render(ctx);
				if (visible) await refresh();
				return;
			}
			if (action !== "") { ctx.ui.notify("Usage: /changes [hide|show]", "error"); return; }
			const latest = await getGitState(ctx.cwd);
			if (!latest.root || latest.error || !latest.files.length) {
				ctx.ui.notify(latest.error ?? (latest.root ? "Git clean" : "Not a Git repository"), "info");
				return;
			}
			await showChanges(ctx, latest.files.map(fileLine));
		},
	});
	pi.registerCommand("undo", {
		description: "Undo a recorded edit/write mutation; refuse to overwrite later changes",
		handler: async (_args, ctx) => {
			if (!ctx.hasUI) return;
			await ctx.waitForIdle();
			const entries = [...history.entries].reverse();
			if (!entries.length) { ctx.ui.notify("No undo history. History is runtime-only; shell mutations are not recorded.", "info"); return; }
			const labels = entries.map((entry) => `#${entry.id} ${entry.tool} ${displayPath(relative(ctx.cwd, entry.path))} · ${entry.time.toLocaleTimeString()}${entry.before === null ? " (new file)" : ""}`);
			const choice = await ctx.ui.select("Undo one mutation — newest per file first", labels);
			if (choice === undefined) return;
			const entry = entries[labels.indexOf(choice)];
			if (!entry) return;
			await ctx.waitForIdle();
			try {
				await history.undo(entry);
				const message = `Undid ${entry.tool} #${entry.id} on ${JSON.stringify(relative(ctx.cwd, entry.path))}.${entry.before === null ? " Removed the file created by that call." : " Restored its previous contents."}`;
				pi.sendMessage({ customType: "file-undo", content: message, display: true });
				await refresh();
			} catch (error) { ctx.ui.notify((error as Error).message, "error"); }
		},
	});
}
