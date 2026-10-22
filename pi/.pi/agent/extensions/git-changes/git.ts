import { execFile } from "node:child_process";
import { lstat, readFile } from "node:fs/promises";
import { join } from "node:path";
import { promisify } from "node:util";

const exec = promisify(execFile);
export interface ChangedFile {
	path: string;
	oldPath?: string;
	status: string;
	added: number;
	removed: number;
	binary: boolean;
}
export interface GitState { root: string | null; files: ChangedFile[]; error?: string }
async function git(cwd: string, args: string[]) {
	return (await exec("git", ["--no-optional-locks", ...args], {
		cwd, encoding: "utf8", timeout: 4000, maxBuffer: 8 * 1024 * 1024,
		env: { ...process.env, GIT_TERMINAL_PROMPT: "0" },
	})).stdout;
}
export function parseStatus(text: string): ChangedFile[] {
	const entries = text.split("\0");
	const files: ChangedFile[] = [];
	for (let i = 0; i < entries.length; i++) {
		const entry = entries[i];
		if (!entry) continue;
		const status = entry.slice(0, 2);
		const file: ChangedFile = { path: entry.slice(3), status, added: 0, removed: 0, binary: false };
		if (/[RC]/.test(status)) file.oldPath = entries[++i];
		files.push(file);
	}
	return files;
}
export function addNumstat(files: ChangedFile[], text: string) {
	const byPath = new Map(files.flatMap((file) => [[file.path, file] as const, ...(file.oldPath ? [[file.oldPath, file] as const] : [])]));
	for (const entry of text.split("\0")) {
		if (!entry) continue;
		const first = entry.indexOf("\t"), second = entry.indexOf("\t", first + 1);
		if (first < 0 || second < 0) continue;
		const file = byPath.get(entry.slice(second + 1));
		if (!file) continue;
		const added = entry.slice(0, first), removed = entry.slice(first + 1, second);
		if (added === "-" || removed === "-") file.binary = true;
		else { file.added += Number(added) || 0; file.removed += Number(removed) || 0; }
	}
}
export async function getGitState(cwd: string): Promise<GitState> {
	let root: string;
	try { root = (await git(cwd, ["rev-parse", "--show-toplevel"])).trimEnd(); }
	catch { return { root: null, files: [] }; }
	try {
		const [status, unstaged, staged] = await Promise.all([
			git(root, ["status", "--porcelain=v1", "-z", "--untracked-files=all"]),
			git(root, ["diff", "--numstat", "-z", "--no-renames", "--no-ext-diff", "--no-textconv"]),
			git(root, ["diff", "--cached", "--numstat", "-z", "--no-renames", "--no-ext-diff", "--no-textconv"]),
		]);
		const files = parseStatus(status);
		addNumstat(files, unstaged); addNumstat(files, staged);
		await Promise.all(files.filter((file) => file.status === "??").map(async (file) => {
			try {
				const path = join(root, file.path), stat = await lstat(path);
				if (!stat.isFile() || stat.size > 2 * 1024 * 1024) { file.binary = true; return; }
				const data = await readFile(path);
				if (data.includes(0)) file.binary = true;
				else file.added = data.length ? data.toString("utf8").split("\n").length - (data.at(-1) === 10 ? 1 : 0) : 0;
			} catch { file.binary = true; }
		}));
		files.sort((a, b) => a.path.localeCompare(b.path));
		return { root, files };
	} catch { return { root, files: [], error: "Git status unavailable" }; }
}
