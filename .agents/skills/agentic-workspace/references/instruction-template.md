# Instruction Template — `.instructions.md` Format Reference

Instructions auto-activate based on `applyTo` glob patterns. They are the most token-efficient
way to provide path-specific context — only loaded when working on matching files.

---

## Minimal Instruction

```yaml
---
description: Brief description of what these instructions cover
applyTo: "src/core/**"
---
# Core Domain Rules

Rules here...
```

## Full Instruction

````yaml
---
description: Instructions for the domain core module — zero dependencies, Result pattern
applyTo: "src/core/**"
---

# Core Domain Instructions

## Key Rules

1. **Zero external imports** — Only imports from within `src/core/` are allowed.
2. **Result pattern** — Use cases return `Result<T, E>`, never `throw` for business logic.
3. **Immutability** — Entities use `readonly` properties.
4. **Ports = interfaces only** — Never implement logic in a port file.

## Anti-patterns
- ❌ `import { z } from 'zod'` in `src/core/`
- ❌ `throw new Error()` in a use case
- ❌ Mutable state in entity objects

## Correct Pattern

```typescript
// src/core/use-cases/my-use-case.ts
export function myUseCase(input: Input): Result<Output, MyError> {
  // ... pure domain logic, no external deps
}
````

```

---

## `applyTo` Glob Pattern Reference

| Pattern | Activates For |
|---------|-------------|
| `"**"` | All files (global — use sparingly) |
| `"src/core/**"` | All files under src/core/ |
| `"src/**/*.ts"` | All TypeScript files under src/ |
| `"**/tests/**"` | All files in any tests/ directory |
| `"**/*.test.ts"` | All test files |
| `"**/*.test.{ts,js}"` | All test files (TS and JS) |
| `"vscode-extension/**"` | All files in VS Code extension package |
| `"cli-mcp-core/src/adapters/**"` | Adapters in specific package |
| `"packages/api/src/**"` | Specific package, src directory |
| `"**/{package,tsconfig}.json"` | Config files only |

## Standard Instruction Set for TypeScript/Hexagonal Projects

```

.github/instructions/
├── core.instructions.md applyTo: "src/core/**"
│ → Zero deps, Result pattern, immutability, ports = interfaces
│
├── adapters.instructions.md applyTo: "src/adapters/**"
│ → Implements port, DI injection only, no domain logic, integration tests
│
├── cli.instructions.md applyTo: "src/cli/**"
│ → CLI framework conventions, one-file-per-command, DI not direct instantiation
│
├── tests.instructions.md applyTo: "**/tests/**"
│ → Vitest, describe/it structure, no infra deps for unit, fixtures in **fixtures**/
│
└── extension.instructions.md applyTo: "vscode-extension/**"
→ VS Code API conventions, Disposable pattern, activation events, webpack

```

## Priority Order (Most to Least Specific)

When multiple instructions match the same file:
1. Workspace `instructions` (`applyTo: "src/core/**"` matches `src/core/entities/foo.ts`)
2. Repository `copilot-instructions.md` (global, always active)
3. User-level instructions (in VS Code userdata)

More specific `applyTo` patterns take priority over less specific ones.

## Instruction Body Best Practices

1. **Concrete rules over abstract principles** — "Use `Result<T,E>` not `throw`" beats "Handle errors properly"
2. **Anti-patterns table** — Show what NOT to do with a ❌ icon
3. **Code examples** — Short snippets showing the correct pattern
4. **Keep < 100 lines** — Instructions should be scannable in 30 seconds
5. **No duplication with AGENTS.md** — Instructions = how to write code, AGENTS.md = project context
6. **File path context** — Reference specific files/directories in the project

## File Naming Convention

```

{domain|layer|scope}.instructions.md

```

Examples:
- `core.instructions.md`
- `adapters.instructions.md`
- `tests.instructions.md`
- `extension.instructions.md`
- `api.instructions.md`
- `database.instructions.md`
```
