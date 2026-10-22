import { constants } from "node:fs";
import { open, realpath, unlink, writeFile } from "node:fs/promises";
import { dirname } from "node:path";
import { withFileMutationQueue } from "@earendil-works/pi-coding-agent";

const MAX_FILE = 2 * 1024 * 1024;
const MAX_TOTAL = 32 * 1024 * 1024;
interface Snapshot { data: Buffer; mode: number; ino: number; dev: number }
export interface Mutation {
	id: number;
	path: string;
	parent: string;
	tool: "edit" | "write";
	before: Snapshot | null;
	after: Snapshot;
	time: Date;
}
async function snapshot(path: string): Promise<Snapshot | null> {
	try {
		const file = await open(path, constants.O_RDONLY | constants.O_NOFOLLOW);
		try {
			const stat = await file.stat();
			if (!stat.isFile() || stat.size > MAX_FILE) throw new Error("Undo supports regular files up to 2 MiB only");
			const data = await file.readFile();
			if (data.length > MAX_FILE) throw new Error("File grew beyond the undo limit");
			return { data, mode: stat.mode & 0o7777, ino: stat.ino, dev: stat.dev };
		} finally { await file.close(); }
	} catch (error) {
		if ((error as NodeJS.ErrnoException).code === "ENOENT") return null;
		throw error;
	}
}
function same(actual: Snapshot | null, expected: Snapshot) {
	return actual !== null && actual.mode === expected.mode && actual.ino === expected.ino && actual.dev === expected.dev && actual.data.equals(expected.data);
}
export class UndoHistory {
	entries: Mutation[] = [];
	private nextId = 1;
	private generation = 0;
	clear() { this.entries = []; this.generation++; }

	// Called by the built-in tool's write operation while it owns Pi's file mutation queue.
	async write(path: string, content: string, tool: "edit" | "write", warn: (message: string) => void) {
		const generation = this.generation;
		let before: Snapshot | null = null, parent = "", track = true;
		try {
			if (Buffer.byteLength(content) > MAX_FILE) throw new Error("File exceeds the 2 MiB undo limit");
			before = await snapshot(path);
			parent = await realpath(dirname(path));
		} catch { track = false; }
		await writeFile(path, content, "utf8");
		if (generation !== this.generation) return;
		if (!track) { warn(`Undo not recorded for ${path}: file too large or not a regular local file.`); return; }
		try {
			const after = await snapshot(path);
			if (generation !== this.generation) return;
			if (!after || !after.data.equals(Buffer.from(content))) throw new Error("File changed during snapshot");
			if (before && before.data.equals(after.data) && before.mode === after.mode) return;
			this.entries.push({ id: this.nextId++, path, parent, tool, before, after, time: new Date() });
			let bytes = this.entries.reduce((sum, entry) => sum + (entry.before?.data.length ?? 0) + entry.after.data.length, 0);
			while (this.entries.length > 50 || bytes > MAX_TOTAL) {
				const old = this.entries.shift()!;
				bytes -= (old.before?.data.length ?? 0) + old.after.data.length;
			}
		} catch { warn(`Undo not recorded for ${path}: snapshot unavailable.`); }
	}
	async undo(entry: Mutation) {
		await withFileMutationQueue(entry.path, async () => {
			if (!this.entries.includes(entry)) throw new Error("Undo entry is no longer available");
			if (this.entries.some((other) => other.id > entry.id && (other.path === entry.path || (other.after.ino === entry.after.ino && other.after.dev === entry.after.dev)))) throw new Error("Undo the newer mutation on this file first");
			if (await realpath(dirname(entry.path)) !== entry.parent) throw new Error("File parent changed; refusing undo");
			if (!same(await snapshot(entry.path), entry.after)) throw new Error("File changed since Pi's mutation; refusing undo");
			if (entry.before === null) {
				// Parent directories created by write are deliberately left intact.
				await unlink(entry.path);
			} else {
				const file = await open(entry.path, constants.O_RDWR | constants.O_NOFOLLOW);
				try {
					const stat = await file.stat();
					if (stat.ino !== entry.after.ino || stat.dev !== entry.after.dev || (stat.mode & 0o7777) !== entry.after.mode
						|| !(await file.readFile()).equals(entry.after.data)) throw new Error("File changed during undo; refusing overwrite");
					await file.write(entry.before.data, 0, entry.before.data.length, 0);
					await file.truncate(entry.before.data.length);
					await file.chmod(entry.before.mode);
				} finally { await file.close(); }
			}
			this.entries = this.entries.filter((other) => other !== entry);
		});
	}
}
