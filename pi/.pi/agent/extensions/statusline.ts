/**
 * Welds the status line into the editor's horizontal rules instead of
 * hanging it below on its own row.
 *
 *   --[ ~/dotfiles :: main !? +9 -3 ]------------------------------[ ^2 ]--
 *   prompt text
 *   -------------------------[ opus-5 high | $0.104 | 12% 200k ]-----------
 *
 * Top rule    = where you are   (cwd, git)
 * Bottom rule = what you're on  (model, thinking, cost, context)
 * ASCII only. The default footer row is reduced to extension statuses.
 */

import { execFileSync } from "node:child_process";
import { homedir } from "node:os";
import type { AssistantMessage } from "@earendil-works/pi-ai";
import {
	CustomEditor,
	type ExtensionAPI,
	type KeybindingsManager,
	type Theme,
	type ThemeColor,
} from "@earendil-works/pi-coding-agent";
import type { EditorTheme, TUI } from "@earendil-works/pi-tui";
import { truncateToWidth, visibleWidth } from "@earendil-works/pi-tui";

// ── glyph set ────────────────────────────────────────────────────────────
const FILL = "-";
const CAP_L = "[";
const CAP_R = "]";
const SEP = "::";
const PIPE = "|";

// ── git ──────────────────────────────────────────────────────────────────
function git(args: string[], cwd: string): string | null {
	try {
		return execFileSync("git", args, { cwd, encoding: "utf8", stdio: ["ignore", "pipe", "ignore"], timeout: 500 }).trim();
	} catch {
		return null;
	}
}

type GitInfo = {
	branch: string;
	flags: string;
	ahead: number;
	behind: number;
	added: number;
	removed: number;
} | null;

let cached: GitInfo = null;
let cachedAt = 0;
let cachedCwd = "";
const CACHE_MS = 1500;

function getGitInfo(cwd: string): GitInfo {
	const now = Date.now();
	if (cwd === cachedCwd && now - cachedAt < CACHE_MS) return cached;
	cachedAt = now;
	cachedCwd = cwd;

	const branch = git(["symbolic-ref", "--short", "-q", "HEAD"], cwd) ?? git(["rev-parse", "--short", "HEAD"], cwd);
	if (branch === null) {
		cached = null;
		return null;
	}

	let conflicted = false;
	let untracked = false;
	let modified = false;
	let staged = false;
	for (const line of (git(["status", "--porcelain=v1"], cwd) ?? "").split("\n")) {
		if (!line) continue;
		const x = line[0];
		const y = line[1];
		if (x === "U" || y === "U") conflicted = true;
		if (x === "?") {
			untracked = true;
			continue;
		}
		if (y !== " ") modified = true;
		if (x !== " ") staged = true;
	}
	let flags = "";
	if (conflicted) flags += "=";
	if (staged) flags += "+";
	if (modified) flags += "!";
	if (untracked) flags += "?";

	let ahead = 0;
	let behind = 0;
	const counts = git(["rev-list", "--left-right", "--count", "HEAD...@{u}"], cwd);
	if (counts) {
		const [a, b] = counts.split(/\s+/).map((n) => Number.parseInt(n, 10));
		ahead = a || 0;
		behind = b || 0;
	}

	let added = 0;
	let removed = 0;
	for (const args of [
		["diff", "--numstat"],
		["diff", "--cached", "--numstat"],
	]) {
		for (const line of (git(args, cwd) ?? "").split("\n")) {
			if (!line) continue;
			const [a, r] = line.split(/\s+/);
			added += Number.parseInt(a ?? "", 10) || 0;
			removed += Number.parseInt(r ?? "", 10) || 0;
		}
	}

	cached = { branch, flags, ahead, behind, added, removed };
	return cached;
}

// ── segment assembly ─────────────────────────────────────────────────────
type Piece = { text: string; color: ThemeColor };

function width(pieces: Piece[]): number {
	let w = 0;
	for (const p of pieces) w += visibleWidth(p.text);
	return w;
}

function paint(pieces: Piece[], theme: Theme): string {
	return pieces.map((p) => theme.fg(p.color, p.text)).join("");
}

function homePath(cwd: string): string {
	const home = homedir();
	if (cwd === home) return "~";
	if (cwd.startsWith(`${home}/`)) return `~${cwd.slice(home.length)}`;
	return cwd;
}

function tokens(n: number): string {
	if (n >= 1_000_000) return `${(n / 1_000_000).toFixed(1)}M`;
	if (n >= 1_000) return `${Math.round(n / 1_000)}k`;
	return `${n}`;
}

/**
 * `--[ left ]--------[ right ]--`, filling the slack between the two caps.
 * An empty `left` therefore right-aligns; an empty `right` left-aligns.
 * Over-wide content is dropped rather than wrapped: a plain rule is drawn.
 */
function rule(w: number, theme: Theme, left: Piece[], right: Piece[]): string {
	const dim = (s: string) => theme.fg("dim", s);
	const cap = (inner: Piece[]) => (inner.length === 0 ? "" : dim(`${CAP_L} `) + paint(inner, theme) + dim(` ${CAP_R}`));
	const capW = (inner: Piece[]) => (inner.length === 0 ? 0 : width(inner) + 4);

	const lead = 2;
	const trail = 2;
	const used = lead + capW(left) + capW(right) + trail;
	if (used > w) return dim(FILL.repeat(Math.max(0, w)));

	return dim(FILL.repeat(lead)) + cap(left) + dim(FILL.repeat(w - used)) + cap(right) + dim(FILL.repeat(trail));
}

export default function (pi: ExtensionAPI) {
	pi.on("session_start", (_event, ctx) => {
		const theme = () => ctx.ui.theme;

		class RuleEditor extends CustomEditor {
			protected renderTopBorder(w: number, hidden: number): string {
				const t = theme();
				const info = getGitInfo(ctx.cwd);
				const left: Piece[] = [{ text: homePath(ctx.cwd), color: "accent" }];
				if (info) {
					left.push({ text: ` ${SEP} `, color: "dim" });
					left.push({ text: info.branch, color: "muted" });
					if (info.flags) left.push({ text: info.flags, color: "warning" });
					if (info.ahead) left.push({ text: ` ^${info.ahead}`, color: "muted" });
					if (info.behind) left.push({ text: ` v${info.behind}`, color: "muted" });
					if (info.added) left.push({ text: ` +${info.added}`, color: "success" });
					if (info.removed) left.push({ text: ` -${info.removed}`, color: "error" });
				}
				const right: Piece[] = hidden > 0 ? [{ text: `^ ${hidden} more`, color: "dim" }] : [];
				return rule(w, t, left, right);
			}

			protected renderBottomBorder(w: number, hidden: number): string {
				const t = theme();

				let cost = 0;
				for (const e of ctx.sessionManager.getBranch()) {
					if (e.type === "message" && e.message.role === "assistant") {
						cost += (e.message as AssistantMessage).usage.cost.total;
					}
				}
				const usage = ctx.getContextUsage();
				const pct = usage?.percent ?? null;

				const right: Piece[] = [
					{ text: ctx.model?.id ?? "no-model", color: "muted" },
				];
				if (ctx.thinkingLevel) {
					const key =
						`thinking${ctx.thinkingLevel[0]!.toUpperCase()}${ctx.thinkingLevel.slice(1)}` as ThemeColor;
					right.push({ text: " ", color: "dim" }, { text: ctx.thinkingLevel, color: key });
				}
				right.push({ text: ` ${PIPE} `, color: "dim" }, { text: `$${cost.toFixed(3)}`, color: "muted" });
				right.push(
					{ text: ` ${PIPE} `, color: "dim" },
					{
						text: pct === null ? "--" : `${pct.toFixed(0)}%`,
						color: pct !== null && pct > 80 ? "error" : pct !== null && pct > 60 ? "warning" : "muted",
					},
					{ text: usage ? ` ${tokens(usage.contextWindow)}` : "", color: "dim" },
				);

				const left: Piece[] = hidden > 0 ? [{ text: `v ${hidden} more`, color: "dim" }] : [];
				return rule(w, t, left, right);
			}
		}

		ctx.ui.setEditorComponent(
			(tui: TUI, editorTheme: EditorTheme, keybindings: KeybindingsManager) =>
				new RuleEditor(tui, editorTheme, keybindings),
		);

		// The rules carry everything; the footer row keeps only extension statuses.
		ctx.ui.setFooter((tui, t, footerData) => ({
			dispose: footerData.onBranchChange(() => tui.requestRender()),
			invalidate() {},
			render(w: number): string[] {
				const statuses = [...footerData.getExtensionStatuses().values()].filter(Boolean);
				if (statuses.length === 0) return [];
				return [truncateToWidth(` ${statuses.join(t.fg("dim", ` ${PIPE} `))}`, w)];
			},
		}));
	});
}
