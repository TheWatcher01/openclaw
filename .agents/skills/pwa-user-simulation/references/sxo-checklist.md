# SXO Audit Checklist

Search eXperience Optimization = SEO + UX + Performance + Accessibility.
Score each item 0 (fail), 1 (partial), 2 (pass). Total /100.

---

## 1. Core Web Vitals (20 points)

| Metric                                  | Good    | Needs Work | Poor    | How to measure                                             |
| --------------------------------------- | ------- | ---------- | ------- | ---------------------------------------------------------- |
| **LCP** (Largest Contentful Paint)      | ≤ 2.5s  | ≤ 4.0s     | > 4.0s  | Chrome DevTools `evaluate_script` with PerformanceObserver |
| **FID/INP** (Interaction to Next Paint) | ≤ 200ms | ≤ 500ms    | > 500ms | Observe interaction delay on click/type                    |
| **CLS** (Cumulative Layout Shift)       | ≤ 0.1   | ≤ 0.25     | > 0.25  | Visual: content jumps during load?                         |

**Quick CWV script** (run via `evaluate_script`):

```js
() => {
  const entries = performance.getEntriesByType("navigation");
  const paint = performance.getEntriesByType("paint");
  return {
    domContentLoaded: entries[0]?.domContentLoadedEventEnd,
    loadComplete: entries[0]?.loadEventEnd,
    firstPaint: paint.find((p) => p.name === "first-paint")?.startTime,
    firstContentfulPaint: paint.find((p) => p.name === "first-contentful-paint")?.startTime,
    resourceCount: performance.getEntriesByType("resource").length,
  };
};
```

- [ ] LCP ≤ 2.5s on target page (2pts)
- [ ] No visible layout shift on load (2pts)
- [ ] First paint < 1s (2pts)
- [ ] Resource count reasonable (< 50 on initial load) (2pts)
- [ ] No render-blocking resources detected (2pts)

---

## 2. Nielsen Heuristics (20 points)

- [ ] **Visibility of system status** — Loading indicators, progress bars, toast feedback (2pts)
- [ ] **Match with real world** — Language matches user expectations, no jargon (2pts)
- [ ] **User control & freedom** — Undo, cancel, back navigation available (2pts)
- [ ] **Consistency** — Same patterns across pages (buttons, spacing, colors) (2pts)
- [ ] **Error prevention** — Form validation before submit, confirmation dialogs for destructive actions (2pts)
- [ ] **Recognition over recall** — Labels visible, no hidden actions, clear CTAs (2pts)
- [ ] **Flexibility** — Keyboard shortcuts, bulk actions, filters (2pts)
- [ ] **Aesthetic & minimal design** — No clutter, clear visual hierarchy (2pts)
- [ ] **Error recovery** — Clear error messages with actionable guidance (2pts)
- [ ] **Help & documentation** — Tooltips, help text, empty states with guidance (2pts)

---

## 3. Cognitive Science (20 points)

### Fitts' Law

- [ ] Primary CTA is the largest clickable element in its context (2pts)
- [ ] Click targets ≥ 44×44px on mobile, ≥ 32×32px on desktop (2pts)
- [ ] Related actions are spatially grouped (2pts)

### Cognitive Load Theory (CLT)

- [ ] Max 5-7 items in any navigation group (Miller's Law) (2pts)
- [ ] Progressive disclosure — advanced options hidden by default (2pts)
- [ ] Chunking — long forms split into logical sections (2pts)

### Gestalt Principles

- [ ] Proximity — related elements visually grouped (2pts)
- [ ] Similarity — same-type elements share visual style (2pts)
- [ ] Hierarchy — information importance reflected in visual weight (2pts)
- [ ] Common region — cards/containers delineate groups (1pt)

---

## 4. Accessibility WCAG 2.2 AA (20 points)

- [ ] Color contrast ≥ 4.5:1 body text, ≥ 3:1 large text/UI components (2pts)
- [ ] All images have `alt` text (or `alt=""` for decorative) (2pts)
- [ ] All form inputs have associated labels (2pts)
- [ ] Focus indicator visible on all interactive elements (2pts)
- [ ] Keyboard navigation works for all interactive elements (2pts)
- [ ] Skip navigation link present (1pt)
- [ ] ARIA landmarks defined (header, main, nav, footer) (2pts)
- [ ] Error messages programmatically associated with fields (2pts)
- [ ] No content relies solely on color to convey meaning (2pts)
- [ ] Touch targets ≥ 44×44px on mobile (2pts)
- [ ] `prefers-reduced-motion` respected for animations (1pt)

---

## 5. Mobile & PWA (20 points)

- [ ] Responsive layout — no horizontal scroll on 390px viewport (2pts)
- [ ] Touch-friendly — adequate spacing between tap targets (2pts)
- [ ] Offline capability — service worker registered, basic offline page (2pts)
- [ ] Manifest valid — name, icons, theme_color, start_url (2pts)
- [ ] Add to home screen — installable PWA (2pts)
- [ ] Viewport meta tag correct (2pts)
- [ ] Text readable without zoom (min 16px body) (2pts)
- [ ] Forms use appropriate input types (email, tel, number) (2pts)
- [ ] No fixed position elements blocking content on small screens (2pts)
- [ ] Smooth scrolling, no janky animations (2pts)

---

## Scoring

| Range  | Grade | Interpretation                      |
| ------ | ----- | ----------------------------------- |
| 90-100 | A     | Production-ready, excellent UX      |
| 80-89  | B     | Good, minor polish needed           |
| 70-79  | C     | Acceptable, several friction points |
| 60-69  | D     | Needs significant work              |
| < 60   | F     | Major UX issues, not shippable      |

## Severity Classification

| Level  | Label   | Criteria                                                    | Action             |
| ------ | ------- | ----------------------------------------------------------- | ------------------ |
| **P0** | Blocker | Prevents task completion, a11y violation level A, data loss | Fix immediately    |
| **P1** | Major   | Significant friction, WCAG AA violation, poor CWV           | Fix before release |
| **P2** | Minor   | Polish, enhancement, optional improvement                   | Backlog            |
