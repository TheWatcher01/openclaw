# Agent Template — `.agent.md` Format Reference

## Minimal Agent

```markdown
---
name: my-agent
description: One-line description shown as chat input placeholder
---

# My Agent

You are a [role description]...
```

## Full Agent (All Fields)

```markdown
---
name: research-specialist
description: Deep research specialist — web + codebase + dependencies, sourced and timestamped
tools:
  - search
  - fetch
  - codebase
  - problems
agents: []
model: Claude Sonnet 4.5 (copilot)
user-invokable: true
disable-model-invocation: false
handoffs:
  - label: Plan Implementation
    agent: Plan
    prompt: Based on the research findings above, create an implementation plan.
    send: false
  - label: Re-verify Freshness
    agent: Research
    prompt: Re-run the research to verify all data is still current.
    send: false
---

# Research Specialist Agent

You are a deep research specialist. Your role: bridge external knowledge (web, GitHub, npm, docs)
with internal workspace context, producing sourced and timestamped findings for the Plan agent.
```

## Frontmatter Field Reference

| Field                      | Type               | Default          | Description                                                                                                              |
| -------------------------- | ------------------ | ---------------- | ------------------------------------------------------------------------------------------------------------------------ |
| `name`                     | string             | required         | Agent identifier (kebab-case)                                                                                            |
| `description`              | string             | required         | Shown as chat input placeholder. First line only is displayed.                                                           |
| `tools`                    | string[]           | all tools        | Built-in tools available: `search`, `fetch`, `codebase`, `editFile`, `createFile`, `terminal`, `problems`, `diagnostics` |
| `agents`                   | string[] \| `*`    | `*`              | Subagents this agent can invoke. `[]` = none, `*` = all, list = specific.                                                |
| `model`                    | string \| string[] | picker selection | AI model. Array = priority fallback list.                                                                                |
| `user-invokable`           | boolean            | `true`           | Whether agent appears in the agents dropdown                                                                             |
| `disable-model-invocation` | boolean            | `false`          | Prevents other agents from invoking this agent as a subagent                                                             |
| `handoffs`                 | Handoff[]          | none             | Guided transitions to other agents (shown as buttons)                                                                    |
| `target`                   | string             | auto             | Target environment: `vscode` or `github-copilot`                                                                         |

## Handoff Object

```yaml
handoffs:
  - label: "Button label (shown in UI)" # Required
    agent: "TargetAgent" # Required — target agent name
    prompt: "Context sent to target agent" # Required — prompt text
    send: false # false = show button, true = auto-send
```

## Tool Scoping by Role

| Role         | Tools                                                      | Reasoning                        |
| ------------ | ---------------------------------------------------------- | -------------------------------- |
| Research     | `search`, `fetch`, `codebase`, `problems`                  | Read-only — never modifies files |
| Plan         | `search`, `codebase`, `problems`                           | Read-only exploration            |
| Review       | `search`, `codebase`, `problems`, `diagnostics`            | Read-only QA                     |
| Implement    | `editFile`, `createFile`, `terminal`, `search`, `codebase` | Full access                      |
| Orchestrator | `search`, `codebase`                                       | Minimal — routing only           |

## Three Agent Archetypes

### Research Agent

```yaml
tools: [search, fetch, codebase, problems]
agents: []
disable-model-invocation: false
handoffs:
  - label: Plan Implementation → Plan
  - label: Re-verify Freshness → Research (self)
```

### Plan Agent (Read-Only)

```yaml
tools: [search, codebase, problems]
agents: []
disable-model-invocation: false
handoffs:
  - label: Start Implementation → default agent
  - label: Back to Research → Research
```

### Review Agent

```yaml
tools: [search, codebase, problems, diagnostics]
agents: []
disable-model-invocation: false
handoffs:
  - label: Fix Issues → Plan
  - label: Approve & Commit → default agent
```

## File Locations (Precedence Order)

VS Code discovers agents in these locations (first match wins per name):

1. User-level: `~/.config/Code/User/agents/` (VS Code global)
2. Workspace root: `.github/agents/*.agent.md`
3. Project subfolder: `project/.github/agents/*.agent.md`
4. Claude compatibility: `.claude/agents/*.agent.md`

## Agent Body Best Practices

1. **Single purpose** — One clear role per agent. Never combine Research + Implementation.
2. **System prompt** — The body is prepended to every user message. Write it as a system prompt.
3. **Reference other files** — Use Markdown links: `[See guidelines](../instructions/core.md)`
4. **Tool references** — Use `#tool:tool-name` in body to describe tool-specific behavior
5. **No code blocks for rules** — Write rules as prose or tables, not code
6. **Role clarity** — Start with "You are a [role]..." for clear identity
7. **Explicit constraints** — List what the agent NEVER does (e.g., "NEVER edit files")
