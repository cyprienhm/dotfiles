import type { ExtensionContext } from "@earendil-works/pi-coding-agent";
import { matchesKey, truncateToWidth, wrapTextWithAnsi } from "@earendil-works/pi-tui";
import { plainText } from "./activity.ts";
import type { JobManager } from "./manager.ts";
import { formatDuration } from "./widget.ts";

/** Temporary input ownership only: no session switch, agent messages, or process controls. */
export async function navigateAgents(ctx: ExtensionContext, manager: JobManager, valid: () => boolean) {
	await ctx.ui.custom<void>((tui, theme, keys, done) => {
		let selected = 0, opened: string | undefined, offset = 0, follow = true;
		let height = 1, maxOffset = 0, closed = false;
		let cachedKey = "", wrapped: string[] = [], lastPoll = "";
		const close = () => { if (closed) return; closed = true; clearInterval(timer); done(); };
		const timer = setInterval(() => {
			if (!valid()) { close(); return; }
			const jobs = agents();
			const signature = JSON.stringify([tui.terminal.rows, tui.terminal.columns, opened,
				opened ? manager.transcript(opened).version : Math.floor(Date.now() / 1000),
				jobs.map((job) => [job.id, job.name, job.state, job.error, job.exitCode, job.finishedAt])]);
			if (signature !== lastPoll) { lastPoll = signature; tui.requestRender(); }
		}, 150);
		timer.unref();
		const agents = () => manager.status().filter((job) => job.kind === "agent");
		return {
			render(width: number) {
				if (!valid() || width < 1) return [];
				const rows = Math.max(1, tui.terminal.rows - 2);
				height = Math.max(1, rows - 2);
				const jobs = agents();
				selected = Math.max(0, Math.min(selected, jobs.length - 1));
				let lines: string[];
				if (opened) {
					const job = jobs.find((job) => job.id === opened);
					if (!job) return [truncateToWidth("Agent unavailable — Escape returns to parent", width)];
					const transcript = manager.transcript(opened);
					const key = `${width}:${transcript.version}`;
					if (cachedKey !== key) {
						wrapped = transcript.text.split("\n").flatMap((line) => wrapTextWithAnsi(line, Math.max(1, width)));
						cachedKey = key;
					}
					maxOffset = Math.max(0, wrapped.length - height);
					offset = follow ? maxOffset : Math.min(offset, maxOffset);
					lines = [theme.fg("accent", plainText(`${job.name} [${job.id}] — ${job.state}${job.exitCode !== undefined ? ` · exit ${job.exitCode}` : ""}${job.error ? ` · ${job.error}` : ""}`).replace(/\s+/g, " ")),
						...wrapped.slice(offset, offset + height),
						theme.fg("dim", `Read-only · ↑↓ PgUp/PgDn · Home/End · Left: list · Esc: parent · ${follow ? "LIVE" : "PAUSED"} ${offset + 1}/${wrapped.length}`)];
				} else {
					const start = Math.max(0, selected - height + 1);
					lines = [theme.fg("accent", "Agents — Enter: history · Escape: parent · Stop: /agents-stop"),
						...jobs.slice(start, start + height).map((job, i) => `${start + i === selected ? "> " : "  "}${plainText(job.name).replace(/\s+/g, " ")} [${job.id}] · ${job.state} · ${formatDuration(((job.finishedAt ?? Date.now()) - job.assignmentStartedAt) / 1000)}`),
						...(!jobs.length ? ["No agent jobs in this runtime"] : []), theme.fg("dim", "↑↓ select · Enter view · Commands remain under /agents-stop")];
				}
				return lines.slice(0, rows).map((line) => truncateToWidth(line, width));
			},
			handleInput(data: string) {
				if (keys.matches(data, "tui.select.cancel")) { close(); return; }
				if (opened) {
					if (matchesKey(data, "left")) { opened = undefined; cachedKey = ""; }
					else if (matchesKey(data, "home")) { follow = false; offset = 0; }
					else if (matchesKey(data, "end")) follow = true;
					else if (keys.matches(data, "tui.select.up") || keys.matches(data, "tui.select.pageUp")) {
						follow = false; offset = Math.max(0, offset - (keys.matches(data, "tui.select.pageUp") ? height : 1));
					} else if (keys.matches(data, "tui.select.down") || keys.matches(data, "tui.select.pageDown")) {
						offset = Math.min(maxOffset, offset + (keys.matches(data, "tui.select.pageDown") ? height : 1)); follow = offset === maxOffset;
					}
				} else {
					if (keys.matches(data, "tui.select.up")) selected = Math.max(0, selected - 1);
					else if (keys.matches(data, "tui.select.down")) selected = Math.min(agents().length - 1, selected + 1);
					else if (keys.matches(data, "tui.select.confirm")) { opened = agents()[selected]?.id; cachedKey = ""; follow = true; offset = 0; }
				}
				tui.requestRender();
			},
			invalidate() { cachedKey = ""; },
			dispose() { closed = true; clearInterval(timer); },
		};
	});
}
