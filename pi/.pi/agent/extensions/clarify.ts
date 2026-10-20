import type { ExtensionAPI, ExtensionContext } from "@earendil-works/pi-coding-agent";
import { Type } from "typebox";
import { askInline, type Answer } from "./clarify/ui.ts";

const STATE_TYPE = "clarify-mode";
const POLICY = `Clarification mode is enabled.
When a material implementation decision is unresolved, call ask_user instead of guessing or silently choosing a default.
Present concrete options and their tradeoffs. The tool supplies an Other entry for typed input.
Set multiple=true when the user may choose zero or more options; otherwise ask for a single answer.
Wait for the user's answer before making changes dependent on that decision.
Cancellation or unavailable interaction means unanswered, never approval. Do not proceed with dependent changes or repeatedly ask a cancelled question.
An explicitly submitted empty multiple selection is an answer, not cancellation.
Use ask_user for clarification even if other general style instructions discourage questions.
This mode does not require inspecting code or documentation before asking.`;

export default function clarify(pi: ExtensionAPI) {
	let enabled = false;

	function updateStatus(ctx: ExtensionContext) {
		ctx.ui.setStatus("clarify", enabled ? "clarify" : undefined);
	}

	function restore(_event: unknown, ctx: ExtensionContext) {
		enabled = false;
		for (const entry of ctx.sessionManager.getBranch()) {
			if (entry.type === "custom" && entry.customType === STATE_TYPE) {
				const data = entry.data as { enabled?: unknown } | undefined;
				if (typeof data?.enabled === "boolean") enabled = data.enabled;
			}
		}
		updateStatus(ctx);
	}

	pi.on("session_start", restore);
	pi.on("session_tree", restore);
	pi.registerCommand("clarify", {
		description: "Toggle clarification mode, or set it with on/off",
		handler: async (args, ctx) => {
			const value = args.trim().toLowerCase();
			if (value !== "" && value !== "on" && value !== "off") {
				ctx.ui.notify("Usage: /clarify [on|off]", "error");
				return;
			}
			enabled = value === "" ? !enabled : value === "on";
			pi.appendEntry(STATE_TYPE, { enabled });
			updateStatus(ctx);
			ctx.ui.notify(`Clarification mode: ${enabled ? "on" : "off"}`, "info");
		},
	});
	pi.on("before_agent_start", (event) => {
		if (enabled) event.systemPromptOptions.sections.clarification = POLICY;
		else delete event.systemPromptOptions.sections.clarification;
	});

	pi.registerTool({
		name: "ask_user",
		label: "Ask user",
		description:
			"Ask the user to resolve an implementation decision. Provide concrete options with tradeoffs; Other is added automatically for a typed answer. Set multiple=true to allow zero or more choices; default is single selection. Answers are editable. Wait for the result before dependent changes. Cancellation is not approval. Available even when clarification mode is off.",
		exposure: "model-only",
		executionMode: "sequential",
		parameters: Type.Object({
			question: Type.String({ minLength: 1, description: "The unresolved decision" }),
			multiple: Type.Optional(Type.Boolean({ description: "Allow zero or more selected answers. Default: false (single selection)." })),
			options: Type.Array(Type.Object({
				label: Type.String({ minLength: 1 }),
				description: Type.Optional(Type.String({ description: "Tradeoffs or consequences" })),
			}), { minItems: 1, description: "Proposed answers; do not include Other" }),
		}),
		async execute(_id, params, signal, _onUpdate, ctx) {
			function result(status: "answered" | "cancelled" | "unavailable", selections: Answer[] | null) {
				const first = selections?.[0];
				const data = {
					question: params.question, status, multiple: params.multiple ?? false,
					...(params.multiple ? { answers: selections?.map((item) => item.answer) ?? null, selections }
						: { answer: first?.answer ?? null, custom: first?.custom ?? false, index: first?.index }),
					...(status !== "answered" ? { instruction: "Unanswered. Do not guess or proceed with dependent changes." } : {}),
				};
				return { content: [{ type: "text" as const, text: JSON.stringify(data) }], details: { ...data, options: params.options } };
			}
			if (signal?.aborted) return result("cancelled", null);
			if (!ctx.hasUI) return result("unavailable", null);
			if (ctx.mode === "tui") {
				const answers = await askInline(ctx, params, signal);
				return answers !== null && answers !== undefined && !signal?.aborted
					? result("answered", answers) : result("cancelled", null);
			}

			// RPC clients use standard dialogs; repeated selection implements multi-select.
			const chosen = new Map<number, Answer>();
			const other = "Other…";
			const submit = "Submit selections";
			while (!signal?.aborted) {
				const labels = params.options.map((option, index) =>
					`${params.multiple ? `[${chosen.has(index) ? "x" : " "}] ` : ""}${index + 1}. ${option.label}${option.description ? ` — ${option.description}` : ""}`,
				);
				const selected = await ctx.ui.select(params.question, [...labels, other, ...(params.multiple ? [submit] : [])], { signal });
				if (selected === undefined || signal?.aborted) return result("cancelled", null);
				if (params.multiple && selected === submit) return result("answered", [...chosen.values()]);
				if (selected === other) {
					const answer = await ctx.ui.input(params.question, "Type your answer", { signal });
					if (signal?.aborted) return result("cancelled", null);
					if (!answer?.trim()) continue;
					const value = { answer: answer.trim(), custom: true };
					if (!params.multiple) return result("answered", [value]);
					chosen.set(params.options.length, value);
					continue;
				}
				const index = labels.indexOf(selected);
				if (index >= 0) {
					const value = { answer: params.options[index].label, custom: false, index: index + 1 };
					if (!params.multiple) return result("answered", [value]);
					if (chosen.has(index)) chosen.delete(index);
					else chosen.set(index, value);
				}
			}
			return result("cancelled", null);
		},
	});
}
