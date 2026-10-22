import type { ExtensionContext } from "@earendil-works/pi-coding-agent";
import { matchesKey, truncateToWidth } from "@earendil-works/pi-tui";

export async function showChanges(ctx: ExtensionContext, lines: string[]) {
	if (ctx.mode !== "tui") {
		await ctx.ui.select("Git changes", lines);
		return;
	}
	await ctx.ui.custom<void>((tui, theme, kb, done) => {
		let selected = 0;
		let first = 0;
		const pageSize = () => Math.max(1, Math.min(20, tui.terminal.rows - 8));
		return {
			invalidate() {},
			render(width: number) {
				const size = pageSize();
				// Scroll only enough to keep the selected row inside the viewport.
				first = Math.max(0, Math.min(first, Math.max(0, lines.length - size)));
				if (selected < first) first = selected;
				if (selected >= first + size) first = selected - size + 1;
				const result = [theme.fg("accent", `Git changes (${lines.length}) — staged + unstaged`)];
				for (let i = first; i < Math.min(lines.length, first + size); i++) {
					result.push(theme.fg(i === selected ? "accent" : "text", `${i === selected ? ">" : " "} ${lines[i]}`));
				}
				result.push(theme.fg("dim", `${selected + 1}/${lines.length} · ${kb.getKeys("tui.select.up").join("/")}/${kb.getKeys("tui.select.down").join("/")} move · PgUp/PgDn page · Home/End · Enter/Esc close`));
				return result.map((line) => truncateToWidth(line, Math.max(1, width)));
			},
			handleInput(data: string) {
				if (kb.matches(data, "tui.select.cancel") || kb.matches(data, "tui.select.confirm")) { done(); return; }
				if (kb.matches(data, "tui.select.up")) selected--;
				else if (kb.matches(data, "tui.select.down")) selected++;
				else if (kb.matches(data, "tui.select.pageUp")) selected -= pageSize();
				else if (kb.matches(data, "tui.select.pageDown")) selected += pageSize();
				else if (matchesKey(data, "home")) selected = 0;
				else if (matchesKey(data, "end")) selected = lines.length - 1;
				selected = Math.max(0, Math.min(lines.length - 1, selected));
				tui.requestRender();
			},
		};
	}, { overlay: true, overlayOptions: { width: "95%", anchor: "center" } });
}
