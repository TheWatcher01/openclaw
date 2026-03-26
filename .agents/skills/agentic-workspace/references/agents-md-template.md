# AGENTS.md Templates

`AGENTS.md` follows the nearest-file-wins convention: the closest file in the directory tree
takes precedence. Think of it as "a README for agents."

---

## Template 1 — Monorepo Root AGENTS.md

Use at the root of a monorepo with multiple packages/projects.
This is the SHARED context index — link to project-specific AGENTS.md for details.

````markdown
# AGENTS.md — {monorepo-name}

> Universal entry point for all AI agents. Indexes all packages and shared agentic infrastructure.

## Monorepo Structure

| Package       | Path          | Description       | AGENTS.md                                   |
| ------------- | ------------- | ----------------- | ------------------------------------------- |
| **package-a** | `packages/a/` | Brief description | [→ AGENTS.md](packages/a/.github/AGENTS.md) |
| **package-b** | `packages/b/` | Brief description | [→ AGENTS.md](packages/b/.github/AGENTS.md) |

## Shared Agents

Located in `.github/agents/` — available across all packages.

| Agent            | Role                                          |
| ---------------- | --------------------------------------------- |
| **Orchestrator** | Task analysis + routing to specialists        |
| **Research**     | Web + codebase research, freshness validation |
| **Plan**         | Read-only exploration + structured planning   |
| **Review**       | QA, architecture compliance, testing          |

## Architecture Overview

{TL;DR architecture diagram or description}

## Shared Stack

| Layer    | Technology          |
| -------- | ------------------- |
| Language | TypeScript (strict) |
| ...      | ...                 |

## Build & Test

```bash
# All packages
pnpm build
pnpm test

# Specific package
cd packages/a && pnpm build
```
````

## Roadmap

[Portfolio Roadmap](ROADMAP.md)

````

---

## Template 2 — Project AGENTS.md

Use inside a specific project/package. Contains project-specific details.
Links to root AGENTS.md for shared agents.

```markdown
# AGENTS.md — {project-name}

> Indexes the agentic infrastructure for this specific project.
> Shared agents: [../../.github/agents/](../../.github/agents/)

## Project

**{project-name}** is {one-sentence description}.

| Key | Value |
|-----|-------|
| **Language** | TypeScript (strict) |
| **Framework** | {framework} |
| **Tests** | {test framework} |
| **Build** | {build tool} |

## Agents

Shared: Research, Plan, Review, Orchestrator (see root `.github/agents/`)

Project-specific:
| Agent | File | Purpose |
|-------|------|---------|
| **SpecialistAgent** | `.github/agents/specialist.agent.md` | Project-specific role |

## Skills

### Global (`~/.agents/skills/`)
| Skill | Purpose |
|-------|---------|
| **skill-name** | When it's used |

### Project-local (`.github/skills/`)
| Skill | Purpose |
|-------|---------|
| **smart** | Auto-learning from errors |

## Prompts

| Prompt | Purpose |
|--------|---------|
| **smart-commit** | Grouped commits with audit |

## Instructions

| Pattern | File | Purpose |
|---------|------|---------|
| `src/core/**` | [core.instructions.md](.github/instructions/core.instructions.md) | Domain rules |
| `src/adapters/**` | [adapters.instructions.md](.github/instructions/adapters.instructions.md) | Adapter rules |

## Architecture

{Architecture diagram or description}

## Commands

```bash
pnpm build      # Build
pnpm test       # Tests
pnpm lint       # Lint
````

## Roadmap

[Detailed Roadmap](.github/ROADMAP.md)

````

---

## Template 3 — Standalone Repo AGENTS.md

Use for a single-project repository (no monorepo).

```markdown
# AGENTS.md — {project-name}

> Universal entry point for all AI agents.

## Project

**{project-name}** is {one-sentence description}.

## Agents (3)

| Agent | File | Role |
|-------|------|------|
| **Research** | `.github/agents/Research.agent.md` | Deep research specialist |
| **Plan** | `.github/agents/Plan.agent.md` | Read-only planning |
| **Review** | `.github/agents/Review.agent.md` | QA & validation |

**Handoff graph:**
````

[Research] → [Plan] → (implementation) → [Review]
↑ │
└──────────── re-research if needed ─────┘

````

## Skills, Prompts, Instructions

... (same structure as Template 2)

## Architecture

... (project-specific)

## Commands

```bash
# Build, test, run
````

## Roadmap

[ROADMAP.md](.github/ROADMAP.md)

```

---

## Key Rules

1. **Nearest-file-wins**: When Copilot reads context, the nearest `AGENTS.md` takes precedence.
   Root AGENTS.md is the fallback; project AGENTS.md is the override.

2. **No duplication**: Root = shared/common context. Project = project-specific additions.
   Never copy the same content into both.

3. **Keep it scannable**: Tables > prose. Links > inline content. ~100-300 lines max.

4. **Always include commands**: Build, test, lint, run — the most useful context for agents.

5. **Link, don't embed**: Link to ROADMAP.md, instructions, architecture docs rather than
   inline all content. AGENTS.md is an index, not an encyclopedia.
```
