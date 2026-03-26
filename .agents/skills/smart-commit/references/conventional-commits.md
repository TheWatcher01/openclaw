# Conventional Commits — Quick Reference

Based on the [Conventional Commits v1.0.0](https://www.conventionalcommits.org/en/v1.0.0/) specification.

## Format

```
<type>(<scope>): <description>

[optional body]

[optional footer(s)]
```

### Subject Line (required)

- **Max 72 characters** (hard limit for clean `git log`)
- **Imperative mood**: "add", "fix", "remove" (not "added", "fixed", "removed")
- **Lowercase** first letter after type
- **No period** at the end

### Type (required)

| Type       | SemVer | When to Use                                             |
| ---------- | ------ | ------------------------------------------------------- |
| `feat`     | MINOR  | New feature visible to end users                        |
| `fix`      | PATCH  | Bug fix                                                 |
| `docs`     | —      | Documentation only changes                              |
| `style`    | —      | Formatting, whitespace, semicolons (no logic change)    |
| `refactor` | —      | Code change that neither fixes a bug nor adds a feature |
| `perf`     | PATCH  | Performance improvement                                 |
| `test`     | —      | Adding/correcting tests                                 |
| `chore`    | —      | Build process, dependencies, tooling                    |
| `ci`       | —      | CI/CD configuration changes                             |
| `build`    | —      | Build system or external dependencies                   |
| `revert`   | —      | Reverts a previous commit                               |

### Scope (optional)

Parenthetical word after type indicating the module affected:

```
feat(auth): add OAuth2 login flow
fix(parser): handle escaped quotes
chore(deps): update lodash to 4.17.21
```

Common scopes: `api`, `ui`, `auth`, `db`, `config`, `core`, `deps`, `ci`

### Breaking Changes

Append `!` after type/scope OR add `BREAKING CHANGE:` footer:

```
feat(api)!: remove deprecated /v1 endpoints

BREAKING CHANGE: The /v1/* endpoints are no longer available.
Use /v2/* instead.
```

## Examples

### Good Messages

```
feat(ui): add accordion and badge components
fix(auth): prevent token refresh race condition
docs: add API authentication guide
style: format files with prettier
refactor(db): extract query builder into module
perf(images): lazy-load below-the-fold images
test(auth): add login flow integration tests
chore: update TypeScript to 5.4
ci: add Node 20 to test matrix
build: migrate from webpack to vite
```

### Bad Messages (and fixes)

| Bad                    | Problem                   | Good                                       |
| ---------------------- | ------------------------- | ------------------------------------------ |
| `update stuff`         | Vague, no type            | `feat(ui): add dark mode toggle`           |
| `feat: Add Button`     | Capital, not imperative   | `feat(ui): add button component`           |
| `fix bug`              | No type prefix, vague     | `fix(auth): handle expired JWT gracefully` |
| `WIP`                  | Never commit WIP          | Stage changes or use `git stash`           |
| `feat: add everything` | Too broad                 | Split into multiple commits                |
| `Fixed the thing.`     | Past tense, period, vague | `fix(api): resolve null response on 404`   |

## Multi-Line Commits

For complex changes, add a body:

```
refactor(auth): migrate from JWT to session-based auth

Replace jsonwebtoken with express-session and connect-redis.
This simplifies token management and improves security by
keeping sessions server-side.

Closes #142
```

## Combining with Smart Commit

The smart-commit skill generates messages following these conventions. When grouping multiple files into one commit:

- **List what was added**: `feat(ui): add button, card, and dialog components`
- **Describe the feature**: `feat: implement user registration with email verification`
- **Be specific about fixes**: `fix(api): return 404 instead of 500 for missing users`

The commit type is determined by the nature of the changes, not the file location:

- New component file → `feat`
- Modified component fixing a bug → `fix`
- Restructured without behavior change → `refactor`
