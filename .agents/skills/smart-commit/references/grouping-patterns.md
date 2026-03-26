# Grouping Patterns — Framework-Specific

The smart-commit skill auto-detects project type and adapts grouping. This reference provides detailed patterns per ecosystem.

## Detection Strategy

Inspect the project root to identify the stack:

```bash
# Package managers & manifests
[ -f package.json ]         && echo "node"
[ -f requirements.txt ]     && echo "python"
[ -f Pipfile ]              && echo "python"
[ -f pyproject.toml ]       && echo "python"
[ -f go.mod ]               && echo "go"
[ -f Cargo.toml ]           && echo "rust"
[ -f pom.xml ]              && echo "java-maven"
[ -f build.gradle* ]        && echo "java-gradle"
[ -f Gemfile ]              && echo "ruby"
[ -f composer.json ]        && echo "php"
[ -f mix.exs ]              && echo "elixir"
[ -f pubspec.yaml ]         && echo "dart"

# Framework detection (Node.js)
grep -q '"next"' package.json 2>/dev/null   && echo "nextjs"
grep -q '"react"' package.json 2>/dev/null  && echo "react"
grep -q '"vue"' package.json 2>/dev/null    && echo "vue"
grep -q '"svelte"' package.json 2>/dev/null && echo "svelte"
grep -q '"angular"' package.json 2>/dev/null && echo "angular"
grep -q '"express"' package.json 2>/dev/null && echo "express"
grep -q '"fastify"' package.json 2>/dev/null && echo "fastify"

# Framework detection (Python)
grep -q 'django' requirements.txt 2>/dev/null && echo "django"
grep -q 'flask' requirements.txt 2>/dev/null  && echo "flask"
grep -q 'fastapi' requirements.txt 2>/dev/null && echo "fastapi"

# Monorepo detection
[ -f pnpm-workspace.yaml ] && echo "monorepo-pnpm"
[ -f lerna.json ]          && echo "monorepo-lerna"
[ -d packages/ ]           && echo "monorepo"
```

## Universal Grouping (Any Project)

These categories apply to ALL project types:

| Priority | Group         | File Patterns                                                              |
| -------- | ------------- | -------------------------------------------------------------------------- |
| 1        | Config        | `*.config.*`, `*rc`, `*rc.*`, manifests, lockfiles, `.gitignore`, CI files |
| 2        | Types/Schemas | `*.d.ts`, `types/`, `schemas/`, `models/`, `*.graphql`, `*.proto`          |
| 3        | Shared/Lib    | `lib/`, `utils/`, `helpers/`, `common/`, `shared/`                         |
| 4        | Core          | Main source files (framework-specific, see below)                          |
| 5        | Styles        | `*.css`, `*.scss`, `*.less`, `*.styl`, theme files                         |
| 6        | Tests         | `*.test.*`, `*.spec.*`, `__tests__/`, `test/`, `tests/`                    |
| 7        | Docs          | `*.md`, `docs/`, `*.txt`, `LICENSE*`                                       |
| 8        | Assets        | `public/`, `static/`, `assets/`, images, fonts                             |
| 9        | Infra         | `Dockerfile*`, `docker-compose*`, `*.tf`, `.github/workflows/`, `Makefile` |

## Next.js / React

```
Group: Pages & Routes
  → app/**/page.tsx, app/**/layout.tsx, app/**/loading.tsx
  → app/**/error.tsx, app/**/not-found.tsx
  → pages/**/*.tsx (Pages Router)

Group: API Routes
  → app/api/**/route.ts
  → pages/api/**/*.ts

Group: Components (UI library)
  → components/ui/**

Group: Components (feature/domain)
  → components/**  (excluding ui/)

Group: Hooks
  → hooks/**, use*.ts

Group: Server Actions
  → app/**/actions.ts, lib/actions/**

Group: Middleware
  → middleware.ts
```

**Scope mapping:** Use the top-level directory or feature name.

- `app/dashboard/page.tsx` → `feat(dashboard): add dashboard page`
- `components/ui/button.tsx` → `feat(ui): add button component`
- `app/api/auth/route.ts` → `feat(api): add auth endpoint`

## Vue / Nuxt

```
Group: Pages
  → pages/**/*.vue

Group: Components
  → components/**/*.vue

Group: Composables
  → composables/**, use*.ts

Group: Store
  → stores/**/*.ts (Pinia)
  → store/**/*.ts (Vuex)

Group: Plugins
  → plugins/**

Group: Server (Nuxt)
  → server/api/**
  → server/middleware/**
```

## Python (Django/FastAPI/Flask)

```
Group: Models
  → models.py, models/**, schemas.py

Group: Views/Routes
  → views.py, routes.py, endpoints.py, api/**

Group: Services
  → services/**, tasks.py

Group: Migrations
  → migrations/**, alembic/**

Group: Config
  → settings.py, config.py, .env.example
```

## Go

```
Group: Handlers
  → *_handler.go, handlers/**

Group: Models
  → *_model.go, models/**

Group: Services
  → *_service.go, services/**

Group: Middleware
  → middleware/**

Group: Proto/API
  → *.proto, api/**
```

## Rust

```
Group: Library
  → src/lib.rs, src/lib/**

Group: Binary
  → src/main.rs, src/bin/**

Group: Modules
  → src/**, grouped by mod.rs boundaries
```

## Monorepo Patterns

For monorepos, prefix the scope with the package name:

```
feat(packages/ui): add button component
fix(apps/web): resolve hydration error
chore(packages/config): update eslint rules
```

Group files by package first, then by concern within each package.

```bash
# Detect changed packages
git status --porcelain | sed 's/^...//' | cut -d'/' -f1-2 | sort -u
```

## Smart Grouping Rules

1. **Related files together** — A component + its test + its styles = one commit
2. **Feature cohesion** — If ≤5 files form a complete feature, commit as one
3. **Rename chains** — File renames + import updates = one commit
4. **Migration + model** — Schema changes + migration files = one commit
5. **Config clusters** — Related configs together (e.g., ESLint + Prettier + tsconfig)

## Splitting Large Changesets

If >30 files changed:

1. First, separate config/infra changes
2. Then group by feature/domain boundary
3. Finally, handle documentation and tests
4. Aim for 3-10 files per commit (guideline, not strict rule)
