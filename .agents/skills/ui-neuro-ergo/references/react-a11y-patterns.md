# React / Next.js — A11y Fix Patterns

Copy-paste ready ARIA and accessibility patterns for React/Next.js (TypeScript, Tailwind v4).

---

## Skip Navigation Link

Place before `<header>`, target `id="main-content"` on `<main>`.

```tsx
<a
  href="#main-content"
  className="sr-only focus:not-sr-only focus:absolute focus:top-4 focus:left-4 focus:z-50 focus:rounded-lg focus:bg-background focus:px-4 focus:py-2 focus:text-sm focus:font-medium focus:shadow-lg focus:ring-2 focus:ring-ring"
>
  Aller au contenu principal
</a>
```

---

## Live Region for Dynamic Count Updates

Use when a filter, search, or action changes the number of visible items.

```tsx
{
  /* Screen-reader-only live region — announced on change */
}
<div role="status" aria-live="polite" aria-atomic="true" className="sr-only">
  {filtered.length} résultat{filtered.length !== 1 ? "s" : ""}
</div>;

{
  /* Visible count — hide from SR to avoid double-announcement */
}
<p aria-hidden="true">
  {filtered.length} résultat{filtered.length !== 1 ? "s" : ""}
</p>;
```

---

## Article with `aria-labelledby`

Every `<article>` in a list must have an accessible name pointing to its heading.

```tsx
function ItemCard({ item }: { item: Item }) {
  const headingId = `item-heading-${item.id}`;
  return (
    <article aria-labelledby={headingId}>
      <h3 id={headingId}>{item.title}</h3>
      {/* rest of card */}
    </article>
  );
}
```

---

## Radio Group for Mutually Exclusive Filters

When only one option can be active at a time (status filter, type filter).

```tsx
<div role="radiogroup" aria-labelledby="status-filter-label">
  <h2 id="status-filter-label">
    <FilterIcon aria-hidden="true" />
    Statut
  </h2>
  {options.map((opt) => (
    <button
      key={opt.key}
      role="radio"
      aria-checked={activeFilter === opt.key}
      onClick={() => setActiveFilter(opt.key)}
    >
      {opt.label}
    </button>
  ))}
</div>
```

---

## Filter Group (non-exclusive) with `role="group"`

When multiple filters can be active simultaneously and are not radio-style.

```tsx
<div role="group" aria-labelledby="type-filter-label">
  <h2 id="type-filter-label">
    <BuildingIcon aria-hidden="true" />
    Type
  </h2>
  {options.map((opt) => (
    <button
      key={opt.key}
      aria-pressed={activeTypes.includes(opt.key)}
      onClick={() => toggleType(opt.key)}
    >
      {opt.label}
    </button>
  ))}
</div>
```

---

## Motion Guard

Wrap all animations with `motion-safe:` — respects `prefers-reduced-motion: reduce`.

```tsx
{/* Tailwind — preferred approach */}
className="motion-safe:animate-pulse"

{/* CSS — for custom animations */}
@media (prefers-reduced-motion: no-preference) {
  .my-animation { animation: spin 1s linear infinite; }
}
```

Decorative animated elements should also have `aria-hidden="true"`:

```tsx
<span className="motion-safe:animate-pulse" aria-hidden="true" />
```

---

## Minimum Touch Target (44×44px)

Wrap small icon buttons in a larger tap area without affecting visual size.

```tsx
<button
  className="p-2.5 min-h-11 min-w-11 flex items-center justify-center rounded-md"
  aria-label="Fermer le panneau"
>
  <XIcon className="h-4 w-4" aria-hidden="true" />
</button>
```

---

## Inputs with SR-Only Labels

When a visible label would clutter the UI (e.g., search inside a sidebar).

```tsx
<div className="relative">
  <label htmlFor="sidebar-search" className="sr-only">
    Rechercher des subventions
  </label>
  <SearchIcon
    className="absolute left-3 top-1/2 -translate-y-1/2 h-4 w-4 text-muted-foreground"
    aria-hidden="true"
  />
  <input
    id="sidebar-search"
    type="search"
    placeholder="Rechercher…"
    autoComplete="off"
    className="pl-9 w-full rounded-md border bg-background px-3 py-2 text-sm"
  />
</div>
```

---

## Icon Buttons — Accessible Names

Every `<button>` containing only an icon needs an accessible name.

```tsx
{
  /* Option 1: aria-label */
}
<button aria-label="Fermer">
  <XIcon className="h-4 w-4" aria-hidden="true" />
</button>;

{
  /* Option 2: sr-only text */
}
<button>
  <XIcon className="h-4 w-4" aria-hidden="true" />
  <span className="sr-only">Fermer</span>
</button>;
```

---

## Stat Buttons with Descriptive Labels

When a button combines a number + text (e.g., "14 Ouvert"), the SR label should be explicit.

```tsx
<button
  aria-label={`${count} subvention${count !== 1 ? "s" : ""} — statut ${label}${isActive ? " (actif)" : ""}`}
  aria-pressed={isActive}
>
  <span aria-hidden="true">{count}</span>
  <span aria-hidden="true">{label}</span>
</button>
```
