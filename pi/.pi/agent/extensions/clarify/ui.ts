import { spawn } from "node:child_process";
import { mkdtemp, readFile, rm, writeFile } from "node:fs/promises";
import { tmpdir } from "node:os";
import { join } from "node:path";
import { SettingsManager, type ExtensionToolContext } from "@earendil-works/pi-coding-agent";
import { Editor, matchesKey, wrapTextWithAnsi } from "@earendil-works/pi-tui";

export interface Answer {
	answer: string;
	custom: boolean;
	index?: number;
}
export interface Question {
	question: string;
	options: { label: string; description?: string }[];
	multiple?: boolean;
}

// Same command precedence, terminal handoff, and temporary Markdown file as Pi's main editor.
async function externalEdit(content: string, cwd: string, signal?: AbortSignal): Promise<string | undefined> {
	const command = SettingsManager.create(cwd).getExternalEditorCommand()
		|| process.env.VISUAL || process.env.EDITOR || (process.platform === "win32" ? "notepad" : "nano");
	const directory = await mkdtemp(join(tmpdir(), "pi-clarify-"));
	try {
		const path = join(directory, "answer.md");
		await writeFile(path, content, "utf8");
		if (signal?.aborted) return undefined;
		const [program, ...args] = command.split(" ");
		const code = await new Promise<number | null>((resolve) => {
			const child = spawn(program, [...args, path], { cwd, stdio: "inherit", shell: process.platform === "win32", signal });
			child.once("error", () => resolve(null));
			child.once("close", resolve);
		});
		if (code !== 0 || signal?.aborted) return undefined;
		return (await readFile(path, "utf8")).replace(/^\uFEFF/, "").replace(/\r?\n$/, "");
	} finally {
		await rm(directory, { recursive: true, force: true });
	}
}

export async function askInline(ctx: ExtensionToolContext, params: Question, signal?: AbortSignal) {
	return ctx.ui.custom<Answer[] | null>((tui, theme, kb, done) => {
		let selected = 0;
		let editing = false;
		let focused = false;
		let closed = false;
		let external = false;
		const checked = new Set<number>();
		const drafts = params.options.map((option) => option.label).concat("");
		const editor = new Editor(tui, {
			borderColor: (s) => theme.fg("accent", s),
			selectList: {
				selectedPrefix: (s) => theme.fg("accent", s), selectedText: (s) => theme.fg("accent", s),
				description: (s) => theme.fg("muted", s), scrollInfo: (s) => theme.fg("dim", s), noMatch: (s) => theme.fg("warning", s),
			},
		});
		function finish(value: Answer[] | null) {
			if (closed) return;
			closed = true;
			signal?.removeEventListener("abort", abort);
			done(value);
		}
		function abort() { if (!external) finish(null); }
		signal?.addEventListener("abort", abort, { once: true });
		function answer(index: number): Answer {
			return { answer: drafts[index].trim(), custom: !params.options[index] || drafts[index].trim() !== params.options[index].label, index: index < params.options.length ? index + 1 : undefined };
		}
		function edit() {
			editing = true;
			editor.setText(drafts[selected]);
			editor.focused = focused;
		}
		function save() {
			drafts[selected] = editor.getText().trim() || params.options[selected]?.label || "";
			editing = false;
			editor.focused = false;
			if (!drafts[selected].trim()) checked.delete(selected);
		}
		editor.onSubmit = (value) => {
			const restored = value.trim() || params.options[selected]?.label || "";
			if (!restored) return;
			drafts[selected] = restored;
			if (params.multiple) {
				checked.add(selected);
				editing = false;
				editor.focused = false;
			} else finish([answer(selected)]);
		};
		async function openExternal() {
			if (external) return;
			external = true;
			let failure = false;
			tui.stop();
			try {
				const text = await externalEdit(editor.getText(), ctx.cwd, signal);
				if (text !== undefined) editor.setText(text);
				else failure = !signal?.aborted;
			} catch {
				failure = !signal?.aborted;
			} finally {
				external = false;
				tui.start();
				tui.requestRender(true);
				if (signal?.aborted) finish(null);
				else if (failure) ctx.ui.notify("External editor failed; answer preserved.", "error");
			}
		}
		if (signal?.aborted) abort();
		return {
			get focused() { return focused; },
			set focused(value: boolean) { focused = value; editor.focused = value && editing; },
			render(width: number) {
				const w = Math.max(1, width);
				const lines = wrapTextWithAnsi(theme.fg("accent", params.question), w);
				for (let i = 0; i < drafts.length; i++) {
					const option = params.options[i];
					const label = drafts[i] || option?.label || "Other…";
					const marker = params.multiple ? `[${checked.has(i) ? "x" : " "}] ` : "";
					lines.push(...wrapTextWithAnsi(theme.fg(i === selected ? "accent" : "text", `${i === selected ? ">" : " "} ${marker}${i + 1}. ${label}`), w));
					if (option?.description) lines.push(...wrapTextWithAnsi(theme.fg("muted", option.description), w));
					if (i === selected && editing) lines.push(...editor.render(w));
				}
				const keys = (action: string) => kb.getKeys(action).join("/");
				const navigation = `${keys("tui.select.up")} up · ${keys("tui.select.down")} down`;
				const hint = editing
					? `Enter ${params.multiple ? "save & select" : "submit"} · ${keys("tui.input.tab")}/${keys("tui.select.cancel")} back · Ctrl-G external editor`
					: `${navigation} · ${params.multiple ? "Space toggle · " : ""}${keys("tui.select.confirm")} ${params.multiple ? "submit (zero or more)" : "select"} · ${keys("tui.input.tab")} edit · ${keys("tui.select.cancel")} cancel`;
				lines.push(...wrapTextWithAnsi(theme.fg("dim", hint), w));
				return lines;
			},
			invalidate() { editor.invalidate(); },
			dispose() { signal?.removeEventListener("abort", abort); },
			handleInput(data: string) {
				if (closed || external) return;
				if (editing) {
					if (kb.matches(data, "tui.select.cancel") || kb.matches(data, "tui.input.tab")) save();
					else if (kb.matches(data, "app.editor.external") || matchesKey(data, "ctrl+g")) void openExternal();
					else editor.handleInput(data);
				} else if (kb.matches(data, "tui.select.cancel")) finish(null);
				else if (kb.matches(data, "tui.select.up")) selected = Math.max(0, selected - 1);
				else if (kb.matches(data, "tui.select.down")) selected = Math.min(drafts.length - 1, selected + 1);
				else if (kb.matches(data, "tui.input.tab")) edit();
				else if (params.multiple && matchesKey(data, "space")) {
					if (checked.has(selected)) checked.delete(selected);
					else if (!drafts[selected].trim()) edit();
					else checked.add(selected);
				} else if (kb.matches(data, "tui.select.confirm")) {
					if (params.multiple) finish([...checked].sort((a, b) => a - b).map(answer));
					else if (!drafts[selected].trim()) edit();
					else finish([answer(selected)]);
				}
				tui.requestRender();
			},
		};
	});
}
