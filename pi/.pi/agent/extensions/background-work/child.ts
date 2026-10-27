import type { ExtensionAPI } from "@earendil-works/pi-coding-agent";
import { Type } from "typebox";

// Explicitly loaded only in delegated RPC processes. No nested job tools.
export default function child(pi: ExtensionAPI) {
	pi.on("before_agent_start", (event) => {
		event.systemPromptOptions.sections.delegation = `You are an isolated delegated agent, not the user-facing coordinator.
Follow the assigned scope and tool capabilities. Do not spawn agents or unmanaged background processes.
For unresolved decisions, call parent_ask and wait. This overrides instructions to ask the user directly or avoid questions.
Only the parent may escalate to the user. A cancelled question is unanswered, never permission to guess. Report the blocker and stop dependent work; do not repeat a cancelled question.
Keep progress concise. Finish with findings, changed paths, tests/results, and remaining risks as applicable.
Your working directory is shared with the parent; context isolation is not filesystem isolation.`;
	});
	pi.registerTool({
		name: "parent_ask",
		label: "Ask parent",
		description: "Ask the coordinating agent a clarification question. Only this child waits; the parent remains available. Include alternatives and tradeoffs. Do not continue dependent work before an answer.",
		exposure: "model-only",
		executionMode: "sequential",
		parameters: Type.Object({ question: Type.String({ minLength: 1, maxLength: 8000 }) }),
		async execute(_id, { question }, signal, _update, ctx) {
			const answer = signal?.aborted ? undefined : await ctx.ui.input("parent_ask", question, { signal });
			const data = answer !== undefined && !signal?.aborted
				? { status: "answered", answer }
				: { status: "cancelled", instruction: "Unanswered. Do not guess or proceed with dependent work." };
			return { content: [{ type: "text", text: JSON.stringify(data) }], details: data };
		},
	});
}
