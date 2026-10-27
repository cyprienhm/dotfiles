import { stripVTControlCharacters } from "node:util";
import type { JobState } from "./manager.ts";

export interface JobActivity {
	id: string;
	kind: "agent" | "command";
	name: string;
	state: JobState;
	elapsedSeconds: number;
	tool: string;
	lines: string[];
}

/** Job output is untrusted terminal data. Preserve line breaks, not terminal commands. */
export function plainText(text: string): string {
	return stripVTControlCharacters(text).replace(/\r\n?|\u2028|\u2029/g, "\n")
		.replace(/[\x00-\x08\x0b-\x1f\x7f-\x9f\u202a-\u202e\u2066-\u2069]/g, "").replace(/\t/g, "  ");
}
const singleLine = (text: string) => plainText(text).replace(/\s+/g, " ").trim().slice(0, 300);
function toolSummary(name: unknown, args: any): string {
	const detail = args?.path ?? args?.command ?? args?.pattern ?? args?.query ?? "";
	return singleLine(`${String(name ?? "tool")} ${typeof detail === "string" ? detail : ""}`);
}

/** Bounded UI-only state. Never retains thinking, tool results, or a child transcript. */
export class ActivityTracker {
	private text = "";
	private streamingText = false;
	private tools = new Map<string, string>();
	private latest = "";
	reset() { this.text = ""; this.streamingText = false; this.tools.clear(); this.latest = ""; }
	settle() { this.tools.clear(); }
	record(event: any) {
		if (event.type === "message_start" && event.message?.role === "assistant") {
			this.streamingText = false;
		} else if (event.type === "message_update" && event.assistantMessageEvent?.type === "text_delta") {
			if (!this.streamingText) this.text = "";
			this.streamingText = true;
			this.text = (this.text + String(event.assistantMessageEvent.delta ?? "")).slice(-4000);
		} else if (event.type === "message_end" && event.message?.role === "assistant") {
			const text = (event.message.content ?? []).filter((b: any) => b.type === "text").map((b: any) => b.text).join("\n");
			if (text.trim()) this.text = text.slice(-4000);
			this.streamingText = false;
		} else if (event.type === "tool_execution_start") {
			const summary = toolSummary(event.toolName, event.args);
			if (this.tools.size >= 32) this.tools.delete(this.tools.keys().next().value!);
			this.tools.set(event.toolCallId, summary);
			this.latest = summary;
		} else if (event.type === "tool_execution_end") {
			const summary = this.tools.get(event.toolCallId) ?? toolSummary(event.toolName, event.args);
			this.tools.delete(event.toolCallId);
			this.latest = `${summary} [${event.isError ? "failed" : "done"}]`;
		}
	}
	snapshot(): Pick<JobActivity, "tool" | "lines"> {
		const running = [...this.tools.values()];
		return {
			tool: running.length ? `running: ${running.slice(0, 2).join("; ")}${running.length > 2 ? ` (+${running.length - 2})` : ""}`
				: this.latest ? `last: ${this.latest}` : "No tool activity yet",
			lines: plainText(this.text).split("\n").map((line) => line.trim()).filter(Boolean).slice(-2).map((line) => line.slice(-500)),
		};
	}
}
