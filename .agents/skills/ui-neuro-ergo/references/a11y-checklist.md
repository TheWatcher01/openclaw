# WCAG 2.2 AA — Actionable Checklist for React/Next.js UIs

> Loaded when auditing or fixing accessibility violations. Focus on AA-level required criteria.

## Quick Audit Script

```javascript
// Run in Chrome DevTools console
const report = [];
// 1. Inputs without labels
document.querySelectorAll("input, textarea, select").forEach((el) => {
  const label = el.id && document.querySelector(`label[for="${el.id}"]`);
  const aria = el.getAttribute("aria-label") || el.getAttribute("aria-labelledby");
  if (!label && !aria) report.push({ issue: "input-no-label", el: el.outerHTML.slice(0, 80) });
});
// 2. Buttons without names
document.querySelectorAll('button, [role="button"]').forEach((b) => {
  const name = b.getAttribute("aria-label") || b.textContent.trim() || b.getAttribute("title");
  if (!name) report.push({ issue: "button-no-name", el: b.outerHTML.slice(0, 80) });
});
// 3. Images without alt
document
  .querySelectorAll("img:not([alt])")
  .forEach((img) => report.push({ issue: "img-no-alt", src: img.src }));
// 4. Articles/sections without names
document.querySelectorAll('article, [role="article"]').forEach((a) => {
  if (!a.getAttribute("aria-label") && !a.getAttribute("aria-labelledby"))
    report.push({
      issue: "article-no-name",
      snippet: a.innerHTML.slice(0, 60),
    });
});
// 5. Skip link
if (!document.querySelector('a[href^="#"]')) report.push({ issue: "no-skip-link" });
// 6. Live regions for dynamic content
const dynCounts = document.querySelectorAll("[aria-live]");
report.push({ info: "live-regions", count: dynCounts.length });
console.table(report);
```

## WCAG 2.2 AA Checklist (UI-Relevant Only)

### Perceivable

| SC     | Level | Description                                               | React/Tailwind Fix                                                                    |
| ------ | ----- | --------------------------------------------------------- | ------------------------------------------------------------------------------------- |
| 1.1.1  | A     | Non-text content has text alternative                     | `aria-label` on icon buttons, `alt` on `<img>`, `aria-hidden` on decorative icons     |
| 1.3.1  | A     | Info and relationships programmatically determinable      | Use semantic HTML (`<nav>`, `<main>`, `<aside>`, `<article>`, `<header>`, `<footer>`) |
| 1.3.5  | AA    | Input purpose identifiable                                | `autoComplete="name"`, `autoComplete="email"` etc. on form fields                     |
| 1.4.1  | A     | Color not sole visual differentiator                      | Always pair color with icon or text label                                             |
| 1.4.3  | AA    | Contrast ≥ 4.5:1 for text (3:1 for large text)            | Check with browser DevTools accessibility panel                                       |
| 1.4.4  | AA    | Text resizable to 200%                                    | No fixed-height containers with overflow:hidden on text                               |
| 1.4.10 | AA    | Reflow — no horizontal scroll at 320px                    | Use responsive Tailwind classes, avoid fixed widths                                   |
| 1.4.11 | AA    | Non-text contrast ≥ 3:1                                   | Focus indicators, icon borders, UI component boundaries                               |
| 1.4.12 | AA    | Text spacing overrides don't break layout                 | Avoid fixed-height lines, use `min-h` instead of `h`                                  |
| 1.4.13 | AA    | Hover/focus content is dismissible, hoverable, persistent | Tooltips must stay on hover                                                           |

### Operable

| SC     | Level | Description                                   | React/Tailwind Fix                                                        |
| ------ | ----- | --------------------------------------------- | ------------------------------------------------------------------------- |
| 2.1.1  | A     | All functionality via keyboard                | Use `<button>`, `<a>`, `<input>` — never `<div onClick>`                  |
| 2.1.2  | A     | No keyboard trap                              | Test Tab/Shift+Tab through all interactive elements                       |
| 2.2.2  | A     | Pause/stop/hide animations with duration > 5s | `motion-safe:animate-*` on all animations                                 |
| 2.4.1  | A     | Skip blocks — bypass repeated content         | Skip-to-main-content link at page top                                     |
| 2.4.3  | A     | Focus order follows logical reading order     | Match DOM order to visual order                                           |
| 2.4.4  | A     | Link purpose determinable from context        | `aria-label` on icon links, descriptive button text                       |
| 2.4.6  | AA    | Headings and labels describe topic            | Every section/card needs a heading; h1→h2→h3 with no skips                |
| 2.4.7  | AA    | Focus visible                                 | `focus-visible:ring-2 focus-visible:ring-ring focus-visible:outline-none` |
| 2.4.11 | AA    | Focus not completely obscured                 | Sticky headers must not obscure focused elements                          |
| 2.5.3  | A     | Label in name                                 | Button aria-label must contain the visible text                           |
| 2.5.8  | AA    | Target size minimum 24×24px                   | `min-h-6 min-w-6` on small interactive elements                           |

### Understandable

| SC    | Level | Description                      | React/Tailwind Fix                                                |
| ----- | ----- | -------------------------------- | ----------------------------------------------------------------- |
| 3.1.1 | A     | Language of page                 | `<html lang="fr">` in layout.tsx                                  |
| 3.1.2 | AA    | Language of parts                | `lang="en"` on English phrases within French pages                |
| 3.2.1 | A     | No context change on focus       | Never trigger navigation on focus, only on click/Enter            |
| 3.2.2 | A     | No context change on input       | Search filters in real-time is fine; form submit on typing is NOT |
| 3.3.2 | A     | Labels or instructions on inputs | `<label>` on all form fields                                      |

### Robust

| SC    | Level | Description                                   | React/Tailwind Fix                                         |
| ----- | ----- | --------------------------------------------- | ---------------------------------------------------------- |
| 4.1.2 | A     | Name, role, value for all UI components       | Custom components need ARIA roles; buttons need names      |
| 4.1.3 | AA    | Status messages programmatically determinable | `role="status"` + `aria-live="polite"` for dynamic updates |

## Key React/Tailwind Patterns

### Skip Link (WCAG 2.4.1)

```tsx
<a
  href="#main-content"
  className="sr-only focus:not-sr-only focus:absolute focus:top-4 focus:left-4 focus:z-50 focus:rounded-lg focus:bg-background focus:px-4 focus:py-2 focus:text-sm focus:font-semibold focus:ring-2 focus:ring-ring focus:shadow-lg"
>
  Aller au contenu principal
</a>
<main id="main-content" tabIndex={-1}>
```

### Live Region for Dynamic Count (WCAG 4.1.3)

```tsx
// SR-only live region + visible aria-hidden duplicate (avoid double-reading)
<div role="status" aria-live="polite" aria-atomic="true" className="sr-only">
  {count} résultats affichés
</div>
<p aria-hidden="true">{count} résultats</p>
```

### Article landmark (WCAG 1.3.1 + 4.1.2)

```tsx
<article aria-labelledby={`card-${id}`}>
  <h3 id={`card-${id}`}>{title}</h3>
</article>
```

### Motion Guard (WCAG 2.2.2)

```tsx
// Tailwind: motion-safe: prefix
<span className="motion-safe:animate-pulse" />

// Or: prefers-reduced-motion in CSS
@media (prefers-reduced-motion: reduce) {
  .animate-pulse { animation: none; }
}
```

### Input with Label (WCAG 1.3.1 + 3.3.2)

```tsx
// Option 1: Visible label
<label htmlFor="search">Rechercher</label>
<input id="search" aria-label="Rechercher une subvention" />

// Option 2: SR-only label
<label htmlFor="search" className="sr-only">Rechercher une subvention</label>
<input id="search" />
```

### Filter Group Accessibility

```tsx
// Mutually exclusive filters → radiogroup pattern
<div role="radiogroup" aria-labelledby="filter-heading">
  <h2 id="filter-heading">Filtrer par statut</h2>
  {options.map(opt => (
    <button role="radio" aria-checked={active === opt.key}>
      {opt.label}
    </button>
  ))}
</div>

// OR: simpler group + aria-pressed (acceptable for WCAG AA)
<div role="group" aria-labelledby="filter-heading">
  {options.map(opt => (
    <button aria-pressed={active === opt.key}>
      {opt.label}
    </button>
  ))}
</div>
```

### Icon Buttons (WCAG 1.1.1 + 4.1.2)

```tsx
// Decorative icon inside labeled button
<button aria-label="Effacer la recherche">
  <X className="h-4 w-4" aria-hidden="true" />
</button>

// Decorative icons next to text — hide from AT
<Euro className="h-4 w-4" aria-hidden="true" />
<span>150 000 €</span>
```
