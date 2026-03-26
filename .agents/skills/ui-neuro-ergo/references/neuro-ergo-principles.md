# Neuro-Ergonomic Principles for UI Design

> Loaded when applying cognitive science to UI layout, interactions, and information architecture.

## 1. Cognitive Load Theory (CLT)

Reduce **extraneous cognitive load** (irrelevant to the task) to free working memory for **germane load** (learning/task).

| Type       | Definition                         | UI Tactic                                                        |
| ---------- | ---------------------------------- | ---------------------------------------------------------------- |
| Intrinsic  | Complexity of the content itself   | Can't reduce; chunk into digestible units                        |
| Extraneous | Caused by poor design/presentation | Eliminate: redundant labels, visual noise, inconsistent patterns |
| Germane    | Building mental schemas            | Reinforce with consistent patterns, progressive disclosure       |

**Actionable rules:**

- Max 7±2 items per group (Miller's Law) — break long lists into sections
- One primary action per view (CTA hierarchy: primary > secondary > tertiary)
- Remove decorative elements that don't convey information
- Group related items (proximity/Gestalt) to reduce visual scanning effort

## 2. Fitts' Law — Target Acquisition

**Time = a + b × log₂(2D/W)** where D = distance, W = target width.

- Make interactive targets larger (min 44×44px for touch per WCAG 2.5.5)
- Place frequently-used actions closest to the user's natural eye scan path
- Avoid small icon-only buttons without adequate hit padding
- Stack-adjacent buttons risk mis-taps — add gap ≥ 8px between touch targets

## 3. F-Pattern & Z-Pattern Scanning

Users scan in **F-pattern** (information-dense pages) or **Z-pattern** (sparse marketing pages).

- Place the most critical information in the top-left (primary horizontal scan)
- Status badges, amounts, and deadlines should align to the F-scan path
- Hero CTAs benefit from Z-pattern: headline → subtext → CTA in diagonal

## 4. Visual Hierarchy — The 3-Level Rule

Every screen needs exactly **3 visual weight levels**:

1. **Primary** — The one thing you most want users to notice (h1, CTA)
2. **Secondary** — Supporting information (h2, subheading, key data)
3. **Tertiary** — Meta/contextual info (labels, timestamps, codes)

Never exceed 3 levels — more creates confusion. Enforce with font size, weight, and color contrast (never shape alone).

## 5. Gestalt Principles

| Principle         | Rule                                                                    |
| ----------------- | ----------------------------------------------------------------------- |
| **Proximity**     | Items close together = related. Use gap/spacing consistently            |
| **Similarity**    | Items that look alike = same category. Consistency in card structure    |
| **Enclosure**     | Items in a container = grouped. Cards, panels, sections                 |
| **Continuity**    | Eye follows lines/rows. Align to grid strictly                          |
| **Figure/Ground** | Foreground content vs background. High contrast text on low-contrast bg |

## 6. Progressive Disclosure

Show only what's needed now; reveal complexity on demand.

- Hero: search + primary CTA (2 actions max)
- Sidebar: filters (collapsed by default on mobile)
- Cards: title + amount + deadline (3 data points) — details on click/expand
- Never show all 60 items as equal priority — sort by urgency (deadline proximity)

## 7. Color & Attention

- Use **saturation** to indicate urgency (red > amber > green)
- Never use color as the ONLY differentiator (+ icon or pattern required)
- For status indicators: always pair color with a text label or icon
- Urgent items: use animation ONLY with `prefers-reduced-motion` guard

## 8. Working Memory & Chunking

- Users can hold 4±1 items in working memory (Cowan 2001 — revised from Miller)
- Chunk filter options: "Tous / Ouvert / Annoncé / Permanent / Non vérifié / Fermé" = 6 items ✓
- Chunk card data into 3 rows: [status + urgency] [name] [amount + deadline]
- Avoid making users scroll to see filter results

## 9. Error Prevention (Norman's Design Principles)

- Filters should show counts to prevent empty-state frustration
- Show "Aucun résultat" immediately with actionable recovery (reset button)
- Never silently clear search on navigation
- Confirm destructive actions (not applicable here, but key for admin UI)

## 10. Typography for Cognition

- Minimum 16px body text for comfortable sustained reading
- Line height 1.5–1.6 for body, 1.1–1.2 for headings
- Max 75 characters per line (optimal reading width)
- Use weight contrast (700 bold vs 400 normal) for hierarchy — avoid italic for emphasis
