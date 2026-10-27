import { truncateToWidth, visibleWidth } from "@earendil-works/pi-tui";
import { plainText, type JobActivity } from "./activity.ts";

type Color = "accent" | "muted" | "dim" | "success" | "warning" | "error";
type Theme = { fg: (color: Color, text: string) => string };
const unstyled: Theme = { fg: (_color, text) => text };
const stateLabel = { running: "running", waiting: "waiting for parent", completed: "idle / completed", failed: "failed", stopped: "stopped" };
const priority = { waiting: 0, running: 1, failed: 2, completed: 3, stopped: 4 };
const clean = (text: string) => plainText(text).replace(/\s+/g, " ");
export function agentHeader(job: JobActivity, width: number): string {
	const time = formatDuration(job.elapsedSeconds);
	let state = stateLabel[job.state];
	if (visibleWidth(`${state} ${time}`) > width) state = job.state;
	const suffix = `${state} ${time}`;
	if (visibleWidth(suffix) >= width) {
		if (visibleWidth(time) >= width) return truncateToWidth(time, width);
		const stateWidth = width - visibleWidth(time) - 1;
		return stateWidth > 0 ? `${truncateToWidth(state, stateWidth)} ${time}` : time;
	}
	const budget = width - visibleWidth(suffix) - 1;
	return `${truncateToWidth(`${clean(job.name)} [${clean(job.id)}]`, budget)} ${suffix}`;
}
export function formatDuration(seconds: number): string {
	const total = Number.isFinite(seconds) ? Math.max(0, Math.floor(seconds)) : 0;
	const hours = Math.floor(total / 3600), minutes = Math.floor(total / 60) % 60;
	const pad = (value: number) => String(value).padStart(2, "0");
	return `${hours ? `${hours}:` : ""}${pad(minutes)}:${pad(total % 60)}`;
}

/** Two lines per agent; commands retain bounded output previews. */
export function renderActivity(jobs: JobActivity[], width: number, maxLines = 34, theme: Theme = unstyled): string[] {
	maxLines = Math.max(0, Math.floor(maxLines));
	if (!jobs.length || width < 1 || !maxLines) return [];
	const groups = (["agent", "command"] as const).map((kind) => ({
		label: kind === "agent" ? "Agents" : "Commands",
		jobs: jobs.filter((job) => job.kind === kind).sort((a, b) => priority[a.state] - priority[b.state]),
		cards: [] as string[][],
	})).filter((group) => group.jobs.length);
	const fit = (lines: string[]) => lines.map((line) => truncateToWidth(line, width));
	if (maxLines < groups.length) return fit([theme.fg("muted", groups.map((g) => `${g.label}: ${g.jobs.length}`).join(" | "))]);
	let remaining = maxLines - groups.length;
	for (;;) {
		let added = false;
		for (const group of groups) {
			const job = group.jobs[group.cards.length];
			const minimum = job?.kind === "agent" ? 2 : 3;
			if (!job || remaining < minimum) continue;
			const color: Color = job.state === "failed" ? "error" : job.state === "waiting" ? "warning"
				: job.state === "completed" ? "success" : "accent";
			const output = job.lines.length ? job.lines.slice(-2) : [job.kind === "agent" ? "No assistant output yet" : "No command output yet"];
			const reserve = groups.filter((other) => other !== group && !other.cards.length).length * 3;
			const budget = remaining >= 3 + reserve ? remaining - reserve : remaining;
			const card = job.kind === "agent" ? [
				theme.fg(color, agentHeader(job, width)),
				theme.fg("muted", `  ${clean(job.tool)}`),
			] : [
				theme.fg(color, `${clean(job.name)} [${clean(job.id)}] ${stateLabel[job.state]} ${formatDuration(job.elapsedSeconds)}`),
				theme.fg("muted", `  ${clean(job.tool)}`),
				...output.map((line) => theme.fg("dim", `  ${clean(line)}`)),
			].slice(0, Math.min(4, budget));
			group.cards.push(card); remaining -= card.length; added = true;
		}
		if (!added) break;
	}
	return fit(groups.flatMap((group) => {
		const hidden = group.jobs.length - group.cards.length;
		return [theme.fg("accent", `${group.label} (${group.jobs.length}${hidden ? `; ${hidden} hidden` : ""}) — /agents · Ctrl+Alt+A · /agents-stop`), ...group.cards.flat()];
	}));
}
