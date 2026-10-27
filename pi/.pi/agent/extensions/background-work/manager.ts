import { spawn, type ChildProcess } from "node:child_process";
import { appendFileSync, closeSync, constants, fstatSync, mkdirSync, openSync, readSync, statSync, writeFileSync } from "node:fs";
import { isAbsolute, join } from "node:path";
import { randomUUID } from "node:crypto";
import { StringDecoder } from "node:string_decoder";
import { Transcript } from "./transcript.ts";
import { ActivityTracker, plainText, type JobActivity } from "./activity.ts";

export type JobState = "running" | "waiting" | "completed" | "failed" | "stopped";
export interface Watch { completion?: boolean; everySeconds?: number; idleSeconds?: number }
export interface JobEvent { jobId: string; reason: string; state: JobState; detail?: string; requestId?: string; directory: string }
export interface Start {
	kind: "command" | "agent";
	name: string;
	cwd: string;
	command?: string;
	task?: string;
	role?: "explore" | "implement";
	model?: string;
	provider?: string;
	thinking?: string;
}
interface Pending { resolve: (value: any) => void; reject: (error: Error) => void; timer: ReturnType<typeof setTimeout> }
interface Job {
	id: string; name: string; kind: Start["kind"]; cwd: string; state: JobState; command?: string;
	directory: string; stdout: string; stderr: string; output: string;
	startedAt: number; assignmentStartedAt: number; lastActivity: number; finishedAt?: number; exitCode?: number | null;
	signal?: string | null; error?: string; report?: string;
	activity: ActivityTracker; transcript: Transcript;
	watch: Watch; reviewedAt: number; idleNotified: boolean; sizes: number;
	process: ChildProcess; closed: boolean; stopped: boolean; terminating: boolean; pending: Map<string, Pending>;
	question?: { requestId: string; question: string };
}
const excerpt = (text: string, max = 4000) => text.length > max ? `${text.slice(0, max)}\n[truncated; inspect logs]` : text;
/** Read only a bounded regular-file tail. A replaced log must not block the UI. */
function tailLines(path: string): string[] {
	let fd: number | undefined;
	try {
		fd = openSync(path, constants.O_RDONLY | constants.O_NONBLOCK | constants.O_NOFOLLOW);
		const stat = fstatSync(fd);
		if (!stat.isFile()) return [];
		const start = Math.max(0, stat.size - 4096), buffer = Buffer.alloc(Math.min(4096, stat.size));
		const bytes = readSync(fd, buffer, 0, buffer.length, start);
		return plainText(buffer.subarray(0, bytes).toString("utf8")).split("\n").map((line) => line.trim()).filter(Boolean).slice(-2).map((line) => line.slice(-500));
	} catch { return []; }
	finally { if (fd !== undefined) closeSync(fd); }
}
export function agentArgs(options: Start, childExtension: string): string[] {
	const args = ["--mode", "rpc", "--no-session", "--no-extensions", "--no-mcp", "--no-skills", "--no-prompt-templates",
		"--no-approve", "--extension", childExtension, "--tools",
		options.role === "explore" ? "read,grep,find,ls,parent_ask" : "read,bash,edit,write,grep,find,ls,parent_ask"];
	if (options.model) args.push("--model", options.model);
	if (options.provider) args.push("--provider", options.provider);
	if (options.thinking) args.push("--thinking", options.thinking);
	return args;
}

/** Session-owned processes. Logs are private ordinary files, never injected wholesale. */
export class JobManager {
	private jobs = new Map<string, Job>();
	private directory?: string;
	private disposed = false;
	private timer?: ReturnType<typeof setInterval>;
	private killers = new Set<ReturnType<typeof setTimeout>>();
	constructor(private options: {
		childExtension: string;
		root: string;
		sessionId: string;
		onEvent: (event: JobEvent) => void;
		// Injection points allow protocol tests without models or credentials.
		piCommand?: string;
		piPrefix?: string[];
		now?: () => number;
	}) {
		if (!isAbsolute(options.root)) throw new Error("Job storage root must be absolute");
		if (!/^[A-Za-z0-9][A-Za-z0-9._-]*$/.test(options.sessionId)) throw new Error("Invalid job session ID");
	}
	private now() { return this.options.now?.() ?? Date.now(); }
	private get(id: string) {
		const job = this.jobs.get(id);
		if (!job) throw new Error(`Unknown job: ${id}. Jobs belong to the current session/branch only.`);
		return job;
	}
	private emit(job: Job, reason: string, detail?: string, requestId?: string) {
		if (!this.disposed) this.options.onEvent({ jobId: job.id, reason, state: job.state,
			detail: detail ? excerpt(detail) : undefined, requestId, directory: job.directory });
	}
	private save(job: Job) {
		try { writeFileSync(join(job.directory, "status.json"), JSON.stringify(this.view(job), null, 2), { mode: 0o600 }); }
		catch (error) { this.emit(job, "log-error", String(error)); }
	}
	private view(job: Job) {
		return { id: job.id, name: job.name, kind: job.kind, cwd: job.cwd, state: job.state,
			pid: job.closed ? undefined : job.process.pid, startedAt: job.startedAt, assignmentStartedAt: job.assignmentStartedAt, lastActivity: job.lastActivity,
			finishedAt: job.finishedAt, exitCode: job.exitCode, signal: job.signal, error: job.error,
			directory: job.directory, stdout: job.stdout, stderr: job.stderr, output: job.output,
			watch: job.watch, question: job.question, report: job.report };
	}
	transcript(id: string) { const job = this.get(id); return job.transcript.snapshot(); }
	status(id?: string) { return id ? this.view(this.get(id)) : [...this.jobs.values()].map((job) => this.view(job)); }
	/** Live processes include idle agent sessions, but exclude finished commands. */
	live() { return [...this.jobs.values()].filter((job) => !job.closed && !job.stopped).map((job) => this.view(job)); }
	/** UI-only snapshots. Command previews read at most 4 KiB per output file. */
	activity(): JobActivity[] {
		return [...this.jobs.values()].filter((job) => !job.closed && !job.stopped).map((job) => {
			const preview = job.kind === "agent" ? job.activity.snapshot() : {
				tool: `bash: ${plainText(job.command ?? "").replace(/\s+/g, " ").slice(0, 300)}`,
				lines: [...tailLines(job.stdout), ...tailLines(job.stderr).slice(-1).map((line) => `[stderr] ${line}`)].slice(-2),
			};
			const elapsedSeconds = Math.max(0, Math.floor(((job.finishedAt ?? this.now()) - job.assignmentStartedAt) / 1000));
			return { id: job.id, kind: job.kind, name: job.name, state: job.state, elapsedSeconds, ...preview };
		});
	}

	start(options: Start) {
		if (this.disposed) throw new Error("Job manager is closed");
		if (process.platform === "win32") throw new Error("Background jobs require POSIX process groups");
		if (this.jobs.size >= 128) throw new Error("Session limit: 128 jobs. Start a new session after stopping existing jobs.");
		if ([...this.jobs.values()].filter((j) => !j.closed).length >= 8) throw new Error("At most 8 live jobs, including idle agent sessions. Stop an agent to release a slot.");
		if (!options.name?.trim()) throw new Error("A job name is required");
		if (options.kind === "command" && !options.command?.trim()) throw new Error("A command is required");
		if (options.kind === "agent" && (!options.task?.trim() || !["explore", "implement"].includes(options.role ?? ""))) throw new Error("Agent jobs require a task and an explore/implement role");
		if (!isAbsolute(options.cwd) || !statSync(options.cwd).isDirectory()) throw new Error("cwd must be an existing absolute directory");
		if (!this.directory) {
			this.directory = join(this.options.root, this.options.sessionId);
			mkdirSync(this.directory, { recursive: true, mode: 0o700 });
			this.timer = setInterval(() => this.tick(), 1000);
			this.timer.unref();
		}
		let id: string, directory: string;
		for (;;) {
			id = randomUUID().slice(0, 8);
			directory = join(this.directory, id);
			try { mkdirSync(directory, { mode: 0o700 }); break; }
			catch (error: any) { if (error.code !== "EEXIST") throw error; }
		}
		const stdout = join(directory, options.kind === "agent" ? "events.jsonl" : "stdout.log");
		const stderr = join(directory, "stderr.log");
		const output = options.kind === "agent" ? join(directory, "output.log") : stdout;
		const outFd = openSync(stdout, "a", 0o600), errFd = openSync(stderr, "a", 0o600);
		if (options.kind === "agent") closeSync(openSync(output, "a", 0o600));
		writeFileSync(join(directory, "input.json"), JSON.stringify(options, null, 2), { mode: 0o600 });
		let proc: ChildProcess;
		try {
			proc = options.kind === "command"
				? spawn("/bin/bash", ["-c", options.command!], { cwd: options.cwd, detached: true, stdio: ["ignore", outFd, errFd] })
				: spawn(this.options.piCommand ?? "pi", [...(this.options.piPrefix ?? []), ...agentArgs(options, this.options.childExtension)],
					{ cwd: options.cwd, detached: true, stdio: ["pipe", "pipe", errFd] });
		} finally { closeSync(outFd); closeSync(errFd); }
		const now = this.now();
		const job: Job = { id, name: options.name, kind: options.kind, cwd: options.cwd, state: "running", directory, stdout, stderr, output,
			startedAt: now, assignmentStartedAt: now, lastActivity: now, watch: { completion: true }, reviewedAt: now, idleNotified: false, sizes: 0,
			process: proc, closed: false, stopped: false, terminating: false, pending: new Map(), activity: new ActivityTracker(), transcript: new Transcript(), command: options.command };
		this.jobs.set(id, job);
		proc.on("error", (error) => this.fail(job, error.message));
		proc.on("close", (code, signal) => {
			job.closed = true;
			for (const pending of job.pending.values()) { clearTimeout(pending.timer); pending.reject(new Error("Agent process exited")); }
			job.pending.clear();
			job.exitCode = code; job.signal = signal;
			if (!job.stopped && (job.kind === "command" || job.state === "running" || job.state === "waiting")) {
				this.finish(job, code === 0 && job.kind === "command" ? "completed" : "failed", job.error ?? (job.kind === "agent" ? "Agent exited before settling" : undefined));
			}
			// Background grandchildren must not outlive the managed leader.
			this.terminateGroup(job);
			this.save(job);
		});
		if (options.kind === "agent") {
			const decoder = new StringDecoder("utf8");
			let buffer = "";
			proc.stdout!.on("data", (chunk: Buffer) => {
				try {
					appendFileSync(stdout, chunk);
					job.lastActivity = this.now(); job.idleNotified = false;
					buffer += decoder.write(chunk);
					let newline: number;
					while ((newline = buffer.indexOf("\n")) >= 0) {
						const line = buffer.slice(0, newline).replace(/\r$/, ""); buffer = buffer.slice(newline + 1);
						if (line.length > 16 * 1024 * 1024) throw new Error("RPC record exceeded 16 MiB");
						if (line) this.record(job, JSON.parse(line));
					}
					if (buffer.length > 16 * 1024 * 1024) throw new Error("RPC record exceeded 16 MiB");
				} catch (error) { this.fail(job, `RPC/log failure: ${error}`); this.terminateGroup(job); }
			});
			proc.stdin!.on("error", (error) => {
				if (!job.stopped) { this.fail(job, `Agent input: ${error.message}`); this.terminateGroup(job); }
			});
			proc.once("spawn", () => {
				void this.request(job, { type: "prompt", message: options.task }).catch((error) => {
					this.fail(job, error.message); this.terminateGroup(job);
				});
			});
		}
		this.save(job);
		return this.view(job);
	}
	private record(job: Job, event: any) {
		if (job.stopped || job.terminating) return;
		job.activity.record(event);
		job.transcript.record(event);
		if (event.type === "response") {
			const pending = job.pending.get(event.id);
			if (pending) {
				clearTimeout(pending.timer); job.pending.delete(event.id);
				if (event.success) pending.resolve(event.data);
				else pending.reject(new Error(event.error ?? "RPC command failed"));
			}
		} else if (event.type === "extension_ui_request") {
			if (event.method === "input" && event.title === "parent_ask" && typeof event.id === "string") {
				job.question = { requestId: event.id, question: excerpt(String(event.placeholder ?? ""), 8000) };
				job.state = "waiting";
				this.emit(job, "clarification", job.question.question, event.id);
				this.save(job);
			} else if (["select", "confirm", "input", "editor"].includes(event.method)) {
				// No unattended approvals. Unexpected child dialogs fail closed.
				this.write(job, { type: "extension_ui_response", id: event.id, cancelled: true });
				this.emit(job, "dialog-denied", `Unexpected child dialog: ${event.method}`);
			}
		} else if (event.type === "tool_execution_start") {
			appendFileSync(job.output, `\nTOOL ${event.toolName} ${excerpt(JSON.stringify(event.args), 2000)}\n`);
		} else if (event.type === "message_end" && event.message?.role === "assistant") {
			const message = event.message;
			const text = (message.content ?? []).filter((b: any) => b.type === "text").map((b: any) => b.text).join("\n");
			if (text) { appendFileSync(job.output, `${text}\n`); job.report = excerpt(text); }
			job.error = message.stopReason === "error" || message.stopReason === "aborted" ? (message.errorMessage ?? message.stopReason) : undefined;
		} else if (event.type === "agent_settled") {
			this.finish(job, event.aborted || job.error ? "failed" : "completed", job.error);
		}
	}
	private write(job: Job, record: object) {
		if (job.closed || job.stopped || !job.process.stdin?.writable) throw new Error("Agent is not available");
		job.process.stdin.write(`${JSON.stringify(record)}\n`);
	}
	private request(job: Job, record: object): Promise<any> {
		const id = randomUUID();
		return new Promise((resolve, reject) => {
			const timer = setTimeout(() => { job.pending.delete(id); reject(new Error("RPC acceptance timed out after 15 seconds")); }, 15000);
			job.pending.set(id, { resolve, reject, timer });
			try { this.write(job, { ...record, id }); }
			catch (error) { clearTimeout(timer); job.pending.delete(id); reject(error); }
		});
	}
	async send(id: string, message: string, requestId?: string, cancel = false) {
		const job = this.get(id);
		if (job.kind !== "agent" || job.closed || job.stopped) throw new Error("Messaging requires a live agent job");
		if (job.question) {
			if (requestId !== job.question.requestId) throw new Error(`Reply requires requestId=${job.question.requestId}`);
			this.write(job, { type: "extension_ui_response", id: requestId, ...(cancel ? { cancelled: true } : { value: message }) });
			job.question = undefined; job.state = "running";
		} else {
			if (requestId || cancel) throw new Error("No matching clarification is pending");
			if (job.state === "failed") throw new Error("Stop failed agents and start a new job");
			const prior = job.state, priorStartedAt = job.assignmentStartedAt, priorFinishedAt = job.finishedAt;
			if (prior === "completed") { job.activity.reset(); job.assignmentStartedAt = this.now(); }
			job.state = "running"; job.report = undefined; job.error = undefined; job.finishedAt = undefined;
			try { await this.request(job, { type: "prompt", message, streamingBehavior: "steer" }); }
			catch (error) {
				if (error instanceof Error && error.message.includes("acceptance timed out")) {
					this.fail(job, error.message); this.terminateGroup(job);
				} else if (!job.closed && !job.stopped && job.state === "running") {
					job.state = prior; job.assignmentStartedAt = priorStartedAt; job.finishedAt = priorFinishedAt;
				}
				this.save(job); throw error;
			}
		}
		job.lastActivity = this.now(); job.idleNotified = false;
		this.save(job);
		return this.view(job);
	}
	watch(id: string, watch: Watch | null) {
		const job = this.get(id);
		for (const value of [watch?.everySeconds, watch?.idleSeconds]) {
			if (value !== undefined && (!Number.isFinite(value) || value < 10)) throw new Error("Watch intervals must be at least 10 seconds");
		}
		job.watch = watch === null ? {} : { completion: true, ...watch };
		job.reviewedAt = this.now(); job.idleNotified = false;
		this.save(job);
		return this.view(job);
	}
	/** Deterministic sampling; the model does semantic inspection only on wake-up. */
	tick() {
		if (this.disposed) return;
		const now = this.now();
		for (const job of this.jobs.values()) {
			if (!["running", "waiting"].includes(job.state)) continue;
			try {
				const sizes = statSync(job.stdout).size + statSync(job.stderr).size;
				if (sizes !== job.sizes) { job.sizes = sizes; job.lastActivity = now; job.idleNotified = false; }
			} catch (error) { this.fail(job, `Cannot monitor logs: ${error}`); this.terminateGroup(job); continue; }
			if (job.state === "waiting") continue; // Already notified; do not nag a pending question.
			const reasons: string[] = [];
			if (job.watch.idleSeconds && !job.idleNotified && now - job.lastActivity >= job.watch.idleSeconds * 1000) {
				reasons.push("inactivity"); job.idleNotified = true;
			}
			if (job.watch.everySeconds && now - job.reviewedAt >= job.watch.everySeconds * 1000) reasons.push("review");
			if (reasons.length) { job.reviewedAt = now; this.emit(job, reasons.join("+"), "Inspect logs/status. Silence alone does not establish failure."); }
		}
	}
	private finish(job: Job, state: "completed" | "failed", error?: string) {
		if (job.stopped) return;
		const changed = job.state !== state;
		job.state = state; job.finishedAt = this.now(); job.error = error; job.question = undefined;
		job.activity.settle();
		this.save(job);
		if (changed && job.watch.completion) this.emit(job, state, error ?? job.report);
	}
	private fail(job: Job, error: string) { this.finish(job, "failed", error); }
	private terminateGroup(job: Job) {
		if (!job.process.pid || job.terminating) return;
		job.terminating = true;
		const pid = job.process.pid;
		const signal = (name: NodeJS.Signals) => {
			try { process.kill(-pid, name); return true; }
			catch (error: any) { if (error.code !== "ESRCH") this.emit(job, "stop-error", error.message); return false; }
		};
		if (!signal("SIGTERM")) return;
		const timer = setTimeout(() => { signal("SIGKILL"); this.killers.delete(timer); }, 1500);
		this.killers.add(timer);
	}
	stop(id: string) {
		const job = this.get(id);
		if (!job.closed && !job.stopped) {
			job.stopped = true; job.state = "stopped"; job.finishedAt = this.now(); job.question = undefined;
			for (const pending of job.pending.values()) { clearTimeout(pending.timer); pending.reject(new Error("Job stopped")); }
			job.pending.clear();
			this.terminateGroup(job);
			this.save(job);
		}
		return this.view(job);
	}
	async dispose() {
		if (this.disposed) return;
		this.disposed = true;
		clearInterval(this.timer);
		for (const job of this.jobs.values()) this.stop(job.id);
		// Keep escalation alive until it has signalled stubborn process groups.
		await new Promise((resolve) => setTimeout(resolve, this.killers.size ? 1600 : 0));
	}
}
