# MCP Browser Tools Guide

Patterns and usage for the three browser MCPs available in this workspace.

---

## 1. Playwright MCP (`@playwright/mcp`)

**Philosophy:** Accessibility tree-based, structured, token-efficient. No vision model needed.

### Core Tools (always available)

| Tool                       | Purpose                                     | Example                                                                             |
| -------------------------- | ------------------------------------------- | ----------------------------------------------------------------------------------- |
| `browser_navigate`         | Go to URL                                   | `browser_navigate({ url: "http://localhost:3000" })`                                |
| `browser_snapshot`         | Accessibility tree snapshot of current page | Returns structured tree with refs                                                   |
| `browser_click`            | Click element by ref (from snapshot)        | `browser_click({ element: "Submit button", ref: "e42" })`                           |
| `browser_type`             | Type text into focused element              | `browser_type({ text: "admin@asso-lea.fr", ref: "e15" })`                           |
| `browser_hover`            | Hover over element                          | `browser_hover({ element: "Menu item", ref: "e33" })`                               |
| `browser_select_option`    | Select dropdown option                      | `browser_select_option({ element: "Status filter", ref: "e20", values: ["OPEN"] })` |
| `browser_press_key`        | Press keyboard key                          | `browser_press_key({ key: "Enter" })`                                               |
| `browser_go_back`          | Navigate back                               | `browser_go_back()`                                                                 |
| `browser_go_forward`       | Navigate forward                            | `browser_go_forward()`                                                              |
| `browser_wait`             | Wait for condition                          | `browser_wait({ time: 2000 })`                                                      |
| `browser_close`            | Close browser                               | `browser_close()`                                                                   |
| `browser_console_messages` | Get console output                          | Returns array of console messages                                                   |
| `browser_tab_list`         | List open tabs                              | Returns tab list                                                                    |
| `browser_tab_new`          | Open new tab                                | `browser_tab_new({ url: "..." })`                                                   |
| `browser_tab_select`       | Switch tab                                  | `browser_tab_select({ index: 0 })`                                                  |
| `browser_tab_close`        | Close tab                                   | `browser_tab_close()`                                                               |

### Vision Tools (requires `--caps=vision`)

| Tool                   | Purpose                                |
| ---------------------- | -------------------------------------- |
| `browser_screenshot`   | Take visual screenshot of current page |
| `browser_move_mouse`   | Move mouse to coordinates              |
| `browser_drag`         | Drag from one position to another      |
| `browser_screen_click` | Click at specific coordinates          |
| `browser_screen_type`  | Type at specific coordinates           |

### Testing Tools (requires `--caps=testing`)

| Tool                      | Purpose                                    |
| ------------------------- | ------------------------------------------ |
| `browser_assert_snapshot` | Assert accessibility tree matches expected |
| `browser_assert_content`  | Assert page contains specific text content |

### Workflow Pattern — Structured Navigation

```
1. browser_navigate → go to page
2. browser_snapshot → read accessibility tree (get element refs)
3. browser_click(ref) → interact with element
4. browser_snapshot → verify new state
5. browser_type(ref, text) → fill form field
6. browser_press_key("Enter") → submit
7. browser_snapshot → verify result
```

---

## 2. Chrome DevTools MCP (`chrome-devtools-mcp`)

**Philosophy:** Pixel-based, vision-powered. Full browser control with JS evaluation.

### Core Tools

| Tool                    | Purpose                                   | Example                                           |
| ----------------------- | ----------------------------------------- | ------------------------------------------------- |
| `navigate_page`         | Navigate to URL                           | `navigate_page({ url: "http://localhost:3000" })` |
| `take_screenshot`       | Visual screenshot (full page or viewport) | Returns base64 image                              |
| `take_snapshot`         | DOM snapshot                              | Returns DOM tree                                  |
| `evaluate_script`       | Execute JavaScript in page context        | Any JS function                                   |
| `click`                 | Click element by CSS selector             | `click({ selector: "button.submit" })`            |
| `fill`                  | Fill input by selector                    | `fill({ selector: "#email", value: "..." })`      |
| `hover`                 | Hover element                             | `hover({ selector: ".menu-item" })`               |
| `emulate`               | Emulate device                            | `emulate({ device: "iPhone 15" })`                |
| `get_console_message`   | Get console logs                          | Returns messages                                  |
| `get_network_request`   | Inspect network                           | Returns request details                           |
| `list_network_requests` | List all network requests                 | Returns request list                              |
| `list_console_messages` | List all console messages                 | Returns message list                              |

### Workflow Pattern — Visual Audit

```
1. navigate_page → go to page
2. take_screenshot → capture visual state (before)
3. evaluate_script → run CWV metrics / a11y checks
4. take_snapshot → inspect DOM structure
5. [interact: click, fill, hover]
6. take_screenshot → capture new visual state (after)
7. Compare before/after for regressions
```

---

## 3. Next DevTools MCP (`next-devtools-mcp`)

**Philosophy:** Next.js-specific insights — route info, build metrics, config.

### Tools

| Tool              | Purpose                                           |
| ----------------- | ------------------------------------------------- |
| Route information | Get Next.js route details (RSC vs client, params) |
| Build metrics     | Bundle sizes, compilation details                 |
| Config inspection | next.config.ts values                             |

Use as complement to Playwright/Chrome for Next.js-specific analysis.

---

## Tool Selection Decision Tree

```
Need to read page structure?
  → Playwright browser_snapshot (structured, token-efficient)

Need a visual screenshot?
  → Chrome DevTools take_screenshot (pixel-perfect)
  → OR Playwright browser_screenshot (if --caps=vision enabled)

Need to click/type/interact?
  → Playwright browser_click/browser_type (by ref from snapshot — reliable)
  → Chrome DevTools click/fill (by CSS selector — fragile if selectors change)

Need to run custom JavaScript?
  → Chrome DevTools evaluate_script (only option)

Need network/console inspection?
  → Chrome DevTools list_network_requests / list_console_messages

Need to emulate a mobile device?
  → Playwright --device flag (at startup)
  → Chrome DevTools emulate (runtime)

Need test assertions?
  → Playwright browser_assert_content / browser_assert_snapshot (--caps=testing)

Need Next.js-specific info?
  → Next DevTools MCP
```

---

## Combined Strategy (Recommended)

For a complete user simulation session, interleave both MCPs:

1. **Playwright** for navigation + interaction (structured, reliable refs)
2. **Chrome DevTools** for screenshots + JS evaluation + network audit
3. **Next DevTools** for build/route metadata

This dual approach gives you both structured accessibility data AND visual pixel-level analysis — the most comprehensive audit possible.
