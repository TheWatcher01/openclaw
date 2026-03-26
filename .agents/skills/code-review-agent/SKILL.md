---
name: code-review-agent
description: >
  Systematic AI-powered code review. USE when: reviewing PRs, auditing code quality,
  checking for security vulnerabilities, validating architecture, analyzing Rust/Python/JS/TS
  code, reviewing config files, or when the user says "review this code", "check this PR",
  "find bugs", "is this code safe". Covers: security (OWASP), performance, maintainability,
  correctness. Optimized for fast review with Haiku 4.5.
metadata:
  version: "1.0.0"
  category: "Dev/Code Review"
  sources: ["OWASP Top 10 2025", "Rust Book", "Clean Code principles"]
---

# Skill: Code Review Agent

## Review Checklist (priority order)

### P0 — Security (block PR)

- [ ] No hardcoded secrets, API keys, passwords, tokens
- [ ] No SQL injection: use parameterized queries, not string concatenation
- [ ] No command injection: no `os.system(user_input)`, shell=True with untrusted data
- [ ] No XSS: output is escaped for HTML contexts
- [ ] No path traversal: `../` in user-controlled paths
- [ ] No SSRF: user-controlled URLs fetched without allowlist
- [ ] No insecure deserialization of untrusted data
- [ ] Authentication/authorization checks present for sensitive operations
- [ ] No prompt injection vectors (for AI-integrated code)

### P1 — Correctness (block PR)

- [ ] Logic matches the stated intent
- [ ] Edge cases handled: empty inputs, None/null, overflow, concurrent access
- [ ] Error handling: errors don't swallow failures silently
- [ ] Tests cover the happy path + at least 2 edge cases
- [ ] No off-by-one errors in loops/slices

### P2 — Performance (flag, don't block)

- [ ] No N+1 queries (check loops with DB calls inside)
- [ ] No unnecessary allocations in hot paths
- [ ] Async/await used correctly (no blocking calls in async context)
- [ ] Indexes exist for queried columns

### P3 — Maintainability (suggest)

- [ ] Functions < 50 lines, single responsibility
- [ ] No magic numbers (use named constants)
- [ ] Meaningful names: `user_email` not `ue`, `calculate_tax` not `proc`
- [ ] Public APIs have docstrings/comments
- [ ] No dead code, no TODO without ticket reference

## Language-Specific Patterns

### Rust

```rust
// ❌ Unwrap in production code
let value = option.unwrap(); // panics on None

// ✅ Propagate errors properly
let value = option.context("value was None")?;

// ❌ String format for SQL
let query = format!("SELECT * FROM users WHERE id = {}", id);

// ✅ Parameterized (sqlx example)
let user = sqlx::query_as!(User, "SELECT * FROM users WHERE id = $1", id)
    .fetch_one(&pool).await?;
```

### Python

```python
# ❌ Shell injection
os.system(f"grep {user_input} file.txt")

# ✅ Safe subprocess
subprocess.run(["grep", user_input, "file.txt"], capture_output=True, text=True)

# ❌ Pickle with untrusted data
data = pickle.loads(untrusted_bytes)  # RCE vector

# ✅ Use json for untrusted data
data = json.loads(untrusted_string)
```

### TypeScript/JavaScript

```typescript
// ❌ XSS
element.innerHTML = userInput;

// ✅ Safe
element.textContent = userInput;
// or DOMPurify.sanitize(userInput) for rich HTML

// ❌ Prototype pollution
const merged = { ...defaultConfig, ...userInput }; // dangerous if userInput has __proto__

// ✅ Safe merge
const merged = Object.assign(Object.create(null), defaultConfig, userInput);
```

## Review Prompt Template

```
Review this [language] code for:
1. Security vulnerabilities (OWASP Top 10)
2. Logic errors and edge cases
3. Performance issues
4. Maintainability concerns

For each finding, provide:
- Severity: CRITICAL / HIGH / MEDIUM / LOW
- Location: file:line
- Issue: what's wrong
- Fix: specific corrected code

Code to review:
<code>
{code}
</code>
```

## PR Review Summary Format

```markdown
## Code Review Summary

**Risk Level**: 🔴 CRITICAL / 🟠 HIGH / 🟡 MEDIUM / 🟢 LOW

### 🔴 Security Issues (must fix before merge)

- [file.rs:42] Hardcoded API key — move to env var
- [auth.py:15] Missing authorization check

### 🟠 Correctness Issues

- [handler.ts:78] Off-by-one in pagination (use < not <=)

### 🟡 Performance Suggestions

- [db.rs:34] N+1 query pattern — use JOIN or batch fetch

### 🟢 Style/Maintainability

- [utils.py:12] Function too long (89 lines), split by responsibility

**Verdict**: ❌ Changes Required / ✅ Approved with suggestions / ✅ Approved
```
