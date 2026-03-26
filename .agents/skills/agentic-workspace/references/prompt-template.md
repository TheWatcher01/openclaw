# Prompt Template — `.prompt.md` Format Reference

Prompts are reusable templates for specific tasks. Unlike agents (persistent persona),
prompts are one-shot templates invoked explicitly.

---

## Minimal Prompt

```yaml
---
name: my-prompt
description: Brief description of what this prompt does
---
Prompt content here...
```

## Full Prompt

```yaml
---
name: smart-commit
description: Create conventional commits grouped by feature after code review and security audit
agent: agent
---

# Smart Commit Workflow

Analyze the staged changes and create well-structured commits following these rules:

## Step 1 — Pre-commit Audit

Before committing, verify:
- [ ] No secrets or credentials in the diff
- [ ] No `console.log` / debug code left in
- [ ] No commented-out code blocks
- [ ] TypeScript types are complete (no `any`)

## Step 2 — Group Changes by Feature

Group related changes into logical commit units. Each commit should be independently deployable.

## Step 3 — Write Conventional Commits

Format: `type(scope): description`

Types: `feat`, `fix`, `refactor`, `docs`, `test`, `chore`, `style`, `perf`, `ci`

Example output:
```

feat(parser): add @breakpoint directive support
fix(executor): handle missing env variable gracefully  
docs(readme): update installation instructions

```

## Step 4 — Execute

Create commits in reverse dependency order (foundation before features).
```

---

## Frontmatter Field Reference

| Field         | Required | Type   | Values                  | Notes                                                |
| ------------- | -------- | ------ | ----------------------- | ---------------------------------------------------- |
| `name`        | ✅       | string | kebab-case              | Unique identifier                                    |
| `description` | ✅       | string |                         | Shown in prompt picker                               |
| `agent`       | optional | string | agent name or `"agent"` | Which agent handles this prompt. `"agent"` = default |

## `agent` Field Values

| Value        | Meaning                                   |
| ------------ | ----------------------------------------- |
| `"agent"`    | Default — uses the currently active agent |
| `"Research"` | Routes to the Research agent              |
| `"Plan"`     | Routes to the Plan agent                  |
| `"Review"`   | Routes to the Review agent                |
| (omitted)    | Same as `"agent"`                         |

## Prompt Body Best Practices

1. **Structure with headings** — Numbered steps with `##` headings make it scannable
2. **Checklists for audits** — Use `- [ ]` for verification steps
3. **Concrete examples** — Show example output format
4. **Parameterize** — Reference context variables: `{filename}`, `{selection}`, etc.
5. **Keep focused** — One task per prompt. Multi-task → use an agent with handoffs instead
6. **Define output format** — Clearly specify what the response should look like

## Prompt vs Agent vs Skill

Use a **Prompt** when:

- You need a reusable template for a specific recurring task
- The task is stateless (no multi-turn needed)
- Output format needs to be consistent across uses
- You want manual control over when it runs

Use an **Agent** when:

- You need persistent role/persona across a conversation
- Multiple tools need to be available
- Handoffs to other agents are required
- Multi-turn reasoning loop is needed

Use a **Skill** when:

- Reusable across projects (not project-specific)
- Involves scripts, data files, or reference material
- Domain expertise (PDF, Excel, API integration...)
- Cross-agent portable

## Shared vs Project-Local Prompts

```
.github/prompts/                     ← Accessible from workspace sidebar
├── smart-commit.prompt.md           ← Shared: useful for all projects
├── smart-review.prompt.md           ← Shared: architecture + QA review
└── project-specific.prompt.md       ← Project: only relevant here

# Access via VS Code: Chat → Attach → Prompts
# Or type /smart-commit in the chat input
```

## File Naming Convention

```
{task-name}.prompt.md

smart-commit.prompt.md
smart-review.prompt.md
debug-workflow.prompt.md
api-documentation.prompt.md
```
