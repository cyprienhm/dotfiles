import { plainText } from "./activity.ts";

const content = (value: any): string => {
	if (typeof value === "string") return plainText(value);
	if (!Array.isArray(value)) return "";
	return value.map((block) => block.type === "text" ? plainText(String(block.text ?? ""))
		: block.type === "thinking" ? `[thinking]\n${plainText(String(block.thinking ?? ""))}`
		: block.type === "toolCall" ? `[tool call ${plainText(String(block.name))}]\n${plainText(JSON.stringify(block.arguments ?? {}, null, 2))}`
		: `[${plainText(String(block.type ?? "attachment"))}]`).join("\n");
};

/** UI-only transcript. Never added to the parent model context. */
export class Transcript {
	private entries: string[] = [];
	private messageIndex: number | undefined;
	private cachedSnapshot: { text: string; version: number } | undefined;
	private assistant(text: string) {
		if (this.messageIndex === undefined) { this.messageIndex = this.entries.length; this.entries.push(text); }
		else this.entries[this.messageIndex] = text;
	}
	private tools = new Map<string, string>();
	private results = new Set<string>();
	version = 0;
	record(event: any) {
		const msg = event.message;
		if ((event.type === "message_start" || event.type === "message_update") && msg?.role === "assistant") {
			this.assistant(`ASSISTANT\n${content(msg.content)}`);
		} else if (event.type === "message_update" && event.assistantMessageEvent?.type === "text_delta") {
			this.assistant((this.messageIndex === undefined ? "ASSISTANT\n" : this.entries[this.messageIndex]) + plainText(String(event.assistantMessageEvent.delta ?? "")));
		} else if (event.type === "message_end" && msg) {
			if (msg.toolCallId && this.results.has(msg.toolCallId)) return;
			if (msg.toolCallId) this.results.add(msg.toolCallId);
			const text = `${plainText(String(msg.role)).toUpperCase()}${msg.toolName ? ` ${plainText(String(msg.toolName))}` : ""}\n${content(msg.content)}${msg.errorMessage ? `\nERROR: ${plainText(String(msg.errorMessage))}` : ""}`;
			if (msg.role === "assistant") { this.assistant(text); this.messageIndex = undefined; }
			else this.entries.push(text);
			if (msg.toolCallId) this.tools.delete(msg.toolCallId);
		} else if (event.type === "tool_execution_start") {
			this.tools.set(event.toolCallId, `TOOL ${plainText(String(event.toolName))}\n${plainText(JSON.stringify(event.args ?? {}, null, 2))}`);
		} else if (event.type === "tool_execution_update") {
			this.tools.set(event.toolCallId, `TOOL ${plainText(String(event.toolName))} [running]\n${content(event.partialResult?.content)}`);
		} else if (event.type === "tool_execution_end") {
			this.tools.delete(event.toolCallId);
			if (this.results.has(event.toolCallId)) return;
			this.results.add(event.toolCallId);
			this.entries.push(`TOOL ${plainText(String(event.toolName))} [${event.isError ? "error" : "done"}]\n${content(event.result?.content)}`);
		} else if (event.type === "extension_ui_request" && event.title === "parent_ask") {
			this.entries.push(`QUESTION TO PARENT\n${plainText(String(event.placeholder ?? ""))}`);
		} else return;
		this.version++;
	}
	snapshot() {
		if (!this.cachedSnapshot || this.cachedSnapshot.version !== this.version) {
			this.cachedSnapshot = { text: [...this.entries, ...this.tools.values()].join("\n\n"), version: this.version };
		}
		return this.cachedSnapshot;
	}
	text() { return this.snapshot().text; }
}
