import { execFile } from "node:child_process";
import { promisify } from "node:util";
import { lstat, mkdtemp, readFile, readlink, rm, writeFile } from "node:fs/promises";
import { tmpdir } from "node:os";
import { join } from "node:path";
import type { ExtensionAPI } from "@earendil-works/pi-coding-agent";
import { truncateToWidth } from "@earendil-works/pi-tui";

const exec = promisify(execFile);
const git = async (cwd: string, args: string[]) => (await exec("git", args, { cwd, maxBuffer: 64 * 1024 * 1024 })).stdout;
type Snapshot = { root: string; files: Map<string, Buffer> };

// Compare working-tree bytes, not HEAD: existing staged/unstaged changes are excluded.
export async function snapshot(cwd: string): Promise<Snapshot | undefined> {
	let root: string;
	try { root = (await git(cwd, ["rev-parse", "--show-toplevel"])).trimEnd(); }
	catch { return undefined; }
	const paths = await git(root, ["ls-files", "-z", "--cached", "--others", "--exclude-standard"]);
	const files = new Map<string, Buffer>();
	for (const path of new Set(paths.split("\0").filter(Boolean))) {
		try {
			const absolute = join(root, path), info = await lstat(absolute);
			if (info.isSymbolicLink()) files.set(path, Buffer.from(await readlink(absolute)));
			else if (info.isFile()) files.set(path, await readFile(absolute));
		} catch (error) {
			if ((error as NodeJS.ErrnoException).code !== "ENOENT") throw error;
		}
	}
	return { root, files };
}

export async function summarize(before: Snapshot, after: Snapshot): Promise<string[]> {
	if (before.root !== after.root) return [];
	const lines: string[] = [];
	const dir = await mkdtemp(join(tmpdir(), "pi-turn-changes-"));
	try {
		for (const path of [...new Set([...before.files.keys(), ...after.files.keys()])].sort()) {
			const a = before.files.get(path), b = after.files.get(path);
			if (a && b && a.equals(b)) continue;
			await writeFile(join(dir, "before"), a ?? Buffer.alloc(0));
			await writeFile(join(dir, "after"), b ?? Buffer.alloc(0));
			let output: string;
			try { output = await git(dir, ["diff", "--no-index", "--numstat", "--no-ext-diff", "--no-textconv", "--", "before", "after"]); }
			catch (error) {
				const result = error as { code?: number; stdout?: string };
				if (result.code !== 1 || typeof result.stdout !== "string") throw error;
				output = result.stdout;
			}
			const [added, removed] = output.split("\t");
			const name = /[\x00-\x1f\x7f-\x9f]/.test(path) ? JSON.stringify(path) : path;
			lines.push(`${added === "-" ? "binary" : `+${added || 0} -${removed || 0}`} ${name}`);
		}
	} finally { await rm(dir, { recursive: true, force: true }); }
	return lines;
}

export default function gitChanges(pi: ExtensionAPI) {
	let before: Snapshot | undefined;
	pi.registerMessageRenderer("git-changes", (message, _options, theme) => ({
		invalidate() {},
		render: (width: number) => String(message.content).split("\n").map((line) => truncateToWidth(theme.fg("dim", line), width)),
	}));
	pi.on("agent_start", async (_event, ctx) => { before = undefined; before = await snapshot(ctx.cwd); });
	pi.on("agent_end", async (_event, ctx) => {
		const start = before;
		before = undefined;
		if (!start) return;
		const end = await snapshot(ctx.cwd);
		if (!end) return;
		const lines = await summarize(start, end);
		if (lines.length) pi.sendMessage({ customType: "git-changes", content: lines.join("\n"), display: true });
	});
	pi.on("context", (event) => ({ messages: event.messages.filter((message) => !("customType" in message && message.customType === "git-changes")) }));
	pi.on("session_shutdown", () => { before = undefined; });
}
