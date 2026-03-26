# SOTA Agent Architecture Patterns — Decision Reference

8 patterns ranked by complexity. **Start simple — add complexity only when it improves outcomes.**

> Source: Anthropic "Building Effective Agents" (Dec 2024), OpenAI Agents SDK (2025)

---

## Pattern 1 — Prompt Chaining (Sequential Pipeline)

**What:** Fixed sequence of LLM calls; each processes output of previous.
**When:** Task cleanly decomposes into fixed, ordered subtasks.
**Pros:** Simple, predictable, easy to debug, each step is focused.
**Cons:** Rigid — can't adapt to unexpected inputs.

```
Input → [Step A] → [Step B] → [Step C] → Output
```

**Example:** Generate code → lint → write tests → document.

---

## Pattern 2 — Routing (Classifier-Dispatch)

**What:** An LLM/classifier categorizes input and routes to a specialized handler.
**When:** Complex tasks with distinct categories requiring different expertise.
**Pros:** Each path is optimized; can use different models per path.
**Cons:** Classification errors cascade; requires well-defined categories upfront.

```
Input → [Classifier] ─→ [Handler A]
                      ─→ [Handler B]
                      ─→ [Handler C]
```

**Example:** Support ticket → FAQ bot | refund handler | tech specialist.

---

## Pattern 3 — Parallelization (Sectioning + Voting)

**What:** Multiple LLMs work simultaneously (sectioning = different tasks; voting = same task).
**When:** Independent subtasks can run in parallel; multiple perspectives needed.
**Pros:** Speed; higher confidence via voting; better focus per subtask.
**Cons:** Higher cost; aggregation logic complexity.

```
Input → ┌→ [Worker A] ─┐
        ├→ [Worker B] ─┤→ [Aggregator] → Output
        └→ [Worker C] ─┘
```

**Example:** Code security review across multiple dimensions simultaneously.

---

## Pattern 4 — Orchestrator-Workers ⭐ SOTA

**What:** Central LLM dynamically breaks tasks → delegates to specialists → synthesizes results.
Key difference from Parallelization: **subtasks are determined dynamically, not pre-defined**.
**When:** Complex tasks where subtasks can't be predicted upfront (e.g., multi-file changes).
**Pros:** Highly flexible; adapts to any input; handles open-ended problems.
**Cons:** Orchestrator = bottleneck; errors affect all workers; higher latency.

```
Input → [Orchestrator] → analyzes task
               ↓           ↓           ↓
         [Worker A]  [Worker B]  [Worker C]
               ↓           ↓           ↓
         [Orchestrator] ← synthesizes results → Output
```

**Example:** Multi-source research gathering; complex codebase changes across many files.

---

## Pattern 5 — Evaluator-Optimizer (Reflection Loop)

**What:** Generator produces output; Evaluator critiques; loop until quality criteria met.
**When:** Clear evaluation criteria exist; iterative refinement provides measurable value.
**Pros:** Output quality improves iteratively; analogous to human review.
**Cons:** Multiple iterations = higher cost + latency; may loop without good stopping criteria.

```
Input → [Generator] → [Evaluator] → feedback
            ↑               |
            └── iterate ────┘
                            ↓ (when quality met)
                          Output
```

**Example:** Research → Review → Revise cycle; literary translation with nuance checks.

---

## Pattern 6 — Swarm / Handoffs ⭐ SOTA

**What:** Lightweight handoffs between specialized agents. Each agent has clear role + tools;
control transfers transparently via handoff declarations. Evolved from OpenAI Swarm → Agents SDK.
**When:** Multi-step workflows with distinct specialist roles; multi-turn complex tasks.
**Pros:** Simple mental model; each agent independently testable; clean separation of concerns.
**Cons:** Handoff logic complexity; context management across handoffs.

```
[Agent A] ──handoff──→ [Agent B] ──handoff──→ [Agent C]
    ↑                                              │
    └────────────── re-handoff if needed ──────────┘
```

**Example (chainskills):**

```
[Research] → [Plan] → (implement) → [Review] → [Research] (if issues found)
```

---

## Pattern 7 — ReAct (Reasoning + Acting)

**What:** Agent alternates: Reason (think about what to do) → Act (tool call) → Observe → loop.
The canonical agent loop for tool-using agents.
**When:** Open-ended problems with unpredictable number of steps.
**Pros:** Transparent reasoning chain; self-correcting; flexible.
**Cons:** Can loop; compounding errors; expensive for long chains.

```
Input → Think → Act (tool) → Observe → Think → Act → ... → Output
```

---

## Pattern 8 — Plan-and-Execute

**What:** Separate planning from execution. Planner creates detailed plan → Executor runs each step.
**When:** Complex tasks benefiting from upfront planning; human review of plan desired.
**Pros:** Better oversight; plan reviewable before execution; clear separation.
**Cons:** Plan may become stale; re-planning overhead; two-phase latency.

```
Input → [Planner] → Plan (reviewable) → [Executor] → Output
```

**Example (VS Code):** Plan agent creates implementation plan → user reviews → Copilot implements.

---

## Decision Matrix

| Pattern                  | Complexity | Cost     | Flexibility | Latency        | Best For                      |
| ------------------------ | ---------- | -------- | ----------- | -------------- | ----------------------------- |
| Prompt Chaining          | Low        | Low      | Low         | Low            | Fixed sequential tasks        |
| Routing                  | Low        | Low-Med  | Medium      | Low            | Multi-category classification |
| Parallelization          | Medium     | High     | Medium      | Low (parallel) | Speed + confidence            |
| **Orchestrator-Workers** | High       | High     | **High**    | Medium         | Unpredictable subtasks        |
| Evaluator-Optimizer      | Medium     | High     | Medium      | High           | Quality-critical output       |
| **Swarm/Handoffs**       | Medium     | Medium   | **High**    | Medium         | Multi-role workflows          |
| ReAct                    | Medium     | Variable | High        | Variable       | Open-ended exploration        |
| Plan-and-Execute         | Medium     | Medium   | High        | Medium         | Oversight-needed tasks        |

---

## Context Engineering Stack (5 Layers)

Token-efficiency ranking. Lower layer = always active. Higher layer = on-demand.

```
Layer 5  Prompts           .prompt.md         Manually invoked     ~500-2000 tokens
Layer 4  Agents            .agent.md          When selected        ~200-1000 tokens
Layer 3  Skills            SKILL.md           Task-triggered       ~100 (meta) + up to 5K
Layer 2  Instructions      .instructions.md   File path match      ~200-500 tokens
Layer 1  AGENTS.md +       project root       Always included      ~500-2000 tokens
         copilot-instruct.
```

**Key insight:** Path-specific instructions (Layer 2) are the most efficient — they add rich context
only when working on relevant files, with zero cost when working elsewhere.

---

## 3 Principles from Anthropic (Dec 2024)

1. **Simplicity** — Start with the simplest pattern that works. Add complexity only when needed.
2. **Transparency** — Show planning steps. Agents that explain their reasoning are more trustworthy.
3. **Good ACI (Agent-Computer Interface)** — _"We spent more time optimizing our tools than the
   overall prompt."_ Well-documented tools with examples, edge cases, and clear boundaries are
   more impactful than clever prompting.
