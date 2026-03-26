# Chrome DevTools MCP — Iteration Protocol

Step-by-step tool sequence for the autonomous see→fix→verify loop using the Chrome DevTools MCP server.

---

## Pre-Conditions

Before starting iteration:

1. Dev server must be running (`pnpm dev` at `http://localhost:3000`)
2. Chrome DevTools MCP server must be connected
3. Target URL must be known (e.g., `/calendar`, `/admin/subsidies`)

---

## Phase A — Initial Capture

```
1. mcp_io_github_chr_navigate_page  { type: "url", url: "http://localhost:3000/[target]" }
2. mcp_io_github_chr_take_screenshot { }           → save as mental "before" baseline
3. mcp_io_github_chr_take_snapshot   { }           → read the full a11y tree (roles, labels, structure)
4. mcp_io_github_chr_evaluate_script { function: auditFn } → run JS audit for ARIA violations
```

**JS Audit Function** (paste into evaluate_script):

```js
() => {
  const issues = [];
  // Images without alt
  document
    .querySelectorAll("img:not([alt])")
    .forEach((el) => issues.push({ type: "img-no-alt", el: el.outerHTML.slice(0, 80) }));
  // Buttons without accessible name
  document.querySelectorAll("button").forEach((b) => {
    const name =
      b.getAttribute("aria-label") || b.getAttribute("aria-labelledby") || b.textContent.trim();
    if (!name) issues.push({ type: "button-no-name", el: b.outerHTML.slice(0, 80) });
  });
  // Inputs without label
  document
    .querySelectorAll("input:not([aria-label]):not([id])")
    .forEach((i) => issues.push({ type: "input-no-label", el: i.outerHTML.slice(0, 80) }));
  // Articles without aria-labelledby
  document
    .querySelectorAll("article:not([aria-labelledby]):not([aria-label])")
    .forEach((a) => issues.push({ type: "article-no-name", el: a.outerHTML.slice(0, 100) }));
  // Unguarded animations
  document
    .querySelectorAll('[class*="animate-"]')
    .forEach((el) => issues.push({ type: "animation-check", cls: el.className }));
  // Live region presence
  const liveRegions = document.querySelectorAll('[aria-live], [role="status"], [role="alert"]');
  issues.push({ type: "live-regions-count", count: liveRegions.length });
  // Heading outline
  const headings = [...document.querySelectorAll("h1,h2,h3,h4,h5,h6")].map((h) => ({
    tag: h.tagName,
    text: h.textContent.trim().slice(0, 40),
  }));
  issues.push({ type: "heading-outline", headings });
  return issues;
};
```

---

## Phase B — Fix Loop

For each finding from the audit:

```
1. Edit source file (replace_string_in_file or multi_replace_string_in_file)
2. mcp_io_github_chr_navigate_page { type: "reload" }   → hot reload picks up Next.js changes
3. mcp_io_github_chr_take_screenshot { }                → verify fix visually
4. mcp_io_github_chr_take_snapshot   { }                → verify ARIA tree updated
5. mcp_io_github_chr_evaluate_script { function: ... }  → re-run targeted check for the fixed item
```

**Tip**: Apply batches of related fixes together (e.g., all input labels at once), then reload once. Use `multi_replace_string_in_file` for multiple edits in the same file.

---

## Phase C — Viewport Testing

After fixing all violations on desktop:

```
1. mcp_io_github_chr_emulate { viewport: { width: 375, height: 812 } }    → iPhone SE
2. mcp_io_github_chr_take_screenshot { }                                   → check mobile layout
3. Evaluate touch targets: querySelectorAll('button') → check min 44x44px
4. mcp_io_github_chr_emulate { viewport: { width: 768, height: 1024 } }   → tablet
5. mcp_io_github_chr_take_screenshot { }
6. mcp_io_github_chr_emulate { viewport: null }                            → reset to default
```

---

## Phase D — Dark Mode Check

```
1. mcp_io_github_chr_emulate { colorScheme: "dark" }
2. mcp_io_github_chr_take_screenshot { }    → check contrast, color-only cues, border visibility
3. mcp_io_github_chr_emulate { colorScheme: "auto" }  → reset
```

---

## Phase E — Keyboard Navigation Test

```
1. mcp_io_github_chr_navigate_page { type: "url", url: "http://localhost:3000/[target]" }
2. mcp_io_github_chr_press_key { key: "Tab" }           → first focus: should be skip link
3. mcp_io_github_chr_take_screenshot { }                → confirm focus ring visible
4. Keep pressing Tab through all interactive elements     → check logical order
5. mcp_io_github_chr_press_key { key: "Enter" }         → activate focused element
6. mcp_io_github_chr_take_screenshot { }                → check response
```

---

## Exit Criteria

Iteration is complete when ALL of the following pass:

| Check                  | Tool                       | Pass Condition                            |
| ---------------------- | -------------------------- | ----------------------------------------- |
| No a11y violations     | `evaluate_script`          | JS audit returns 0 critical items         |
| All inputs labelled    | `evaluate_script`          | `input-no-label` count = 0                |
| All articles named     | `evaluate_script`          | `article-no-name` count = 0               |
| Live region present    | `evaluate_script`          | `live-regions-count` ≥ 1                  |
| No unguarded animation | `evaluate_script` + visual | All `animate-*` wrapped in `motion-safe:` |
| Skip link present      | `take_snapshot` + Tab key  | First Tab lands on skip link              |
| Mobile layout OK       | screenshot at 375px        | No overflow, tap targets ≥ 44px           |
| Dark mode OK           | screenshot dark            | No color-only cues, contrast visible      |
| TypeScript clean       | `get_errors`               | 0 compile errors                          |

---

## Common Pitfalls

- **Next.js hot reload** may take 1–2 seconds — add a `wait_for` call if needed before screenshot
- **`aria-live` regions** only announce CHANGES — verify by actually changing the filter, not just checking presence
- **`motion-safe:`** in Tailwind requires the class to be in the same `className` string — not conditional
- **`role="radiogroup"`** requires `aria-labelledby` pointing to a visible heading, not just any element
- **Stale a11y tree** — always call `take_snapshot` AFTER the page has fully re-rendered
