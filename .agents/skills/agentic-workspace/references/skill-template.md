# Skill Template — `SKILL.md` Format Reference (agentskills.io)

## Required Structure

```
skill-name/               ← directory name MUST match `name` field
├── SKILL.md              ← Required: frontmatter + instructions
├── scripts/              ← Optional: executable code (Python, Bash, JS)
├── references/           ← Optional: docs loaded into context on demand
└── assets/               ← Optional: templates, data files, images
```

## Minimal SKILL.md

```yaml
---
name: my-skill
description: "What this skill does. Use when: specific triggers. Mention key keywords for discovery."
---
# My Skill

Instructions for how to use this skill...
```

## Full SKILL.md

```yaml
---
name: my-skill
description: "Extract text and tables from PDF files, fill forms, merge documents. Use when working with PDF documents or when the user mentions PDFs, .pdf files, extracting text, or creating documents."
license: Apache-2.0
compatibility: "Requires Python 3.10+ and poppler-utils installed"
metadata:
  version: "1.0.0"
  author: your-org
  agent_support: [copilot, claude, cursor, goose]
  tags: [pdf, documents, extraction]
---

# Skill Title

Brief intro paragraph (1-3 lines).

## Protocol

Step-by-step instructions...

## Anti-patterns
- ❌ Never do X
- ❌ Never do Y

## Output Template
... (if applicable)
```

## Frontmatter Field Reference

| Field           | Required | Type   | Constraints                     | Notes                                        |
| --------------- | -------- | ------ | ------------------------------- | -------------------------------------------- |
| `name`          | ✅       | string | 1-64 chars, lowercase + hyphens | MUST match directory name exactly            |
| `description`   | ✅       | string | 1-1024 chars                    | Primary trigger mechanism — include keywords |
| `license`       | optional | string | SPDX identifier                 | e.g., `MIT`, `Apache-2.0`                    |
| `compatibility` | optional | string |                                 | Environment requirements                     |
| `metadata`      | optional | object |                                 | Arbitrary key-value for tooling              |
| `allowed-tools` | optional | string | experimental                    | e.g., `Bash(git:*) Read`                     |

## Progressive Disclosure Rules

The 3-tier model is mandatory for reusable skills:

```
Tier 1: SKILL.md frontmatter (~100 tokens)
  → Always in context for all skills
  → Only name + description evaluated for activation

Tier 2: SKILL.md body (<5000 tokens, recommended <500 lines)
  → Loaded when skill is activated
  → Write the protocol, rules, and output format here

Tier 3: references/, scripts/, assets/ (any size)
  → Loaded on demand when explicitly referenced
  → Keep each file focused (one topic)
```

**Challenge each piece:** "Does this content justify its token cost?"
Move anything that's only needed occasionally to `references/`.

## Description as Discovery Mechanism

The `description` field is HOW agents decide to activate a skill.
Include all relevant trigger keywords:

```yaml
# Good — covers all trigger scenarios
description: "Extract text, tables, and metadata from PDF files. Merge, split, rotate, watermark,
  encrypt, or fill PDF forms. Use when: working with .pdf files, extracting PDF content, creating
  PDF documents, OCR scanning, or pdf-related operations."

# Bad — too vague
description: "PDF operations"
```

## `scripts/` Directory

Scripts must be:

- **Self-contained** — install their own dependencies or document them
- **Documented** — include usage comment at top
- **Error-handled** — helpful error messages for all failure modes
- **Tested** — include example inputs in comments

```python
#!/usr/bin/env python3
"""
Extract text from a PDF file.
Usage: python extract_text.py <pdf_path> [--output markdown|text|json]
Requires: pip install pypdf2 pdfminer.six
"""
```

## `references/` Directory

- One file per topic/domain
- Keep files focused and small (< 200 lines each)
- Name files descriptively: `api-reference.md`, `error-codes.md`, `examples.md`
- Reference from SKILL.md body: "See `references/api-reference.md` for the full API"

## Skill vs Other Artifacts

| Use a Skill when...               | Use an Instruction when...      | Use a Prompt when...       | Use an Agent when...        |
| --------------------------------- | ------------------------------- | -------------------------- | --------------------------- |
| Reusable across projects          | Project/path-specific rules     | Reusable task template     | Full persona + tools needed |
| Needs scripts or data files       | Auto-activates by file path     | Manually invoked           | Requires tool access        |
| Domain capability (PDF, Excel...) | Coding style/architecture rules | Structured output template | Multi-turn workflow         |
| Cross-agent portable              | TypeScript/framework-specific   | Report/document template   | Handoffs to other agents    |

## Naming Convention

```
skill-name/SKILL.md          ← name field: "skill-name"
skill-name/scripts/run.py    ← executable
skill-name/references/api.md ← reference doc
skill-name/assets/template.docx ← asset
```

The `name` field in frontmatter MUST match the parent directory name exactly.

## Supported Agents (as of Feb 2026)

Skills using this format are supported by: Claude Code, VS Code (GitHub Copilot), Goose,
Cursor, Roo Code, Factory, Qodo, Firebender, Mistral AI Vibe, OpenCode.
