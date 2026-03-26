---
name: context-engineering
description: >
  Optimize the AI context window for any task. USE when: agent has poor memory or forgets
  context, responses are imprecise, needing to compress long conversations, building RAG
  pipelines, designing multi-turn agent state, managing tool results in context, or when
  the user says "the AI doesn't remember" or "context too long". Implements Karpathy/Willison
  context engineering: right info, right time, right format, right size.
metadata:
  version: "1.0.0"
  category: "AI/Context Engineering"
  sources: ["Karpathy 2025", "Simon Willison 2025", "Anthropic docs"]
---

# Skill: Context Engineering

> "Context engineering is the art of filling the context window with just the right information,
> in the right format, at the right time — to reliably achieve the task." — Karpathy, 2025

## Decision Tree — What to put in context

```
What is the agent missing?

├── Task definition unclear → Add: task description + success criteria
├── No examples → Add: 2-5 few-shot examples (input→output pairs)
├── Background knowledge needed → Add: RAG results (top-3 chunks, not 20)
├── Tool results overwhelming → Compress: summarize, keep key values only
├── Long history → Compact: summarize past turns, keep last 3-5 turns raw
├── Multi-modal inputs → Add: image/file after text instruction
├── Agent "forgets" midway → Add: persistent summary at context top
└── Agent loses task focus → Add: explicit reminder at context bottom
```

## 6 Context Layers (fill in priority order)

| Layer           | What                           | When to include              |
| --------------- | ------------------------------ | ---------------------------- |
| 1. Instructions | System prompt, task definition | Always                       |
| 2. State        | Current task status, memory    | When multi-step              |
| 3. Background   | RAG results, docs              | When domain knowledge needed |
| 4. Examples     | Few-shot in-context demos      | For complex/ambiguous tasks  |
| 5. History      | Recent conversation turns      | Last 3-5 only                |
| 6. Tools        | Available tool specs           | On demand, not all at once   |

## Context Compression Techniques

### 1. Summarize long history

```
[CONTEXT SUMMARY — previous N turns]
User asked about X. Agent found Y. Current status: Z.
[END SUMMARY]

[RECENT TURNS — last 3]
User: ...
Assistant: ...
```

### 2. RAG result trimming

- Max 3 chunks, not everything retrieved
- Include: source, date, key sentence
- Exclude: full documents, duplicate info

### 3. Tool result compression

```
# Instead of dumping full JSON:
Tool result: Found 3 files. Relevant: config.toml (line 42: api_key), .env (line 7: SECRET)
```

### 4. Progressive context (for long tasks)

```
Phase 1 prompt: task + tools (no history)
Phase 2 prompt: phase 1 summary + new task + tools
Phase N prompt: compressed N-1 history + current step
```

## Context Window Budget (8K context model)

```
System prompt:      500-1000 tokens  (10-12%)
Task description:   200-400 tokens   (5%)
Examples (few-shot): 300-600 tokens  (7%)
RAG/background:     1000-2000 tokens (20%)
Tool specs:         500-1000 tokens  (10%)
Conversation:       remaining        (~45%)
Output buffer:      reserve 1000     (12%)
```

## Anti-Patterns

- ❌ Dump ALL retrieved docs → ✅ Top-3 most relevant chunks
- ❌ Keep full conversation history → ✅ Summarize after 5 turns
- ❌ Put examples at the END → ✅ Put examples just before the task
- ❌ All tools in every prompt → ✅ Inject tools relevant to current step
- ❌ No state management → ✅ Explicit state object in context

## For ZeroClaw/Agent Systems

```toml
# config.toml — enable context compaction
[agent]
compact_context = true

# Memory: store compressed summaries, not full history
[memory]
backend = "sqlite"
auto_save = true
```

Trigger `hint:smart` route for complex context operations (uses GPT-OSS-120B-free for better context reasoning).
