# User Journey Simulation Report

## Meta

| Field | Value |
|-------|-------|
| **Date** | {DATE} |
| **Persona** | {PERSONA_NAME} |
| **Device** | {DEVICE} ({VIEWPORT}) |
| **Base URL** | {BASE_URL} |
| **Scope** | {SCOPE} (full / focused on {ROUTE}) |
| **App Version** | {VERSION} |
| **Feature Flags** | {FLAGS_STATE} |

---

## Executive Summary

**SXO Score: {SCORE}/100 (Grade {GRADE})**

| Category | Score | Max |
|----------|-------|-----|
| Core Web Vitals | /20 | 20 |
| Nielsen Heuristics | /20 | 20 |
| Cognitive Science | /20 | 20 |
| Accessibility WCAG 2.2 AA | /20 | 20 |
| Mobile & PWA | /20 | 20 |

**Key findings:** {SUMMARY}

---

## Route-by-Route Analysis

### Route: {ROUTE_PATH}

**Screenshot:** {SCREENSHOT_REF}

**Accessibility Snapshot Summary:**
- Landmarks: {LANDMARKS}
- Interactive elements: {COUNT}
- ARIA labels coverage: {COVERAGE}%

**Findings:**

| # | Severity | Category | Description | Affected Element | Fix Approach | Handoff |
|---|----------|----------|-------------|-----------------|-------------|---------|
| 1 | P0 | {CAT} | {DESC} | {ELEMENT} | {FIX} | {AGENT} |
| 2 | P1 | {CAT} | {DESC} | {ELEMENT} | {FIX} | {AGENT} |
| 3 | P2 | {CAT} | {DESC} | {ELEMENT} | {FIX} | {AGENT} |

---

## Findings Summary by Severity

### P0 — Blockers (fix immediately)

| # | Route | Finding | Handoff |
|---|-------|---------|---------|
| | | | |

### P1 — Major (fix before release)

| # | Route | Finding | Handoff |
|---|-------|---------|---------|
| | | | |

### P2 — Minor (backlog)

| # | Route | Finding | Handoff |
|---|-------|---------|---------|
| | | | |

---

## Handoff Recommendations

| Target Agent | Findings Count | Priority Items |
|-------------|---------------|----------------|
| **UI** | {N} | {LIST} |
| **Backend** | {N} | {LIST} |
| **Review** | {N} | {LIST} |

---

## Performance Metrics

| Metric | Value | Threshold | Status |
|--------|-------|-----------|--------|
| First Paint | {FP}ms | < 1000ms | {STATUS} |
| FCP | {FCP}ms | < 1800ms | {STATUS} |
| LCP | {LCP}ms | < 2500ms | {STATUS} |
| CLS | {CLS} | < 0.1 | {STATUS} |
| Resource Count | {RC} | < 50 | {STATUS} |
| DOM Content Loaded | {DCL}ms | < 1500ms | {STATUS} |

---

## Console Errors

| Level | Message | Route | Impact |
|-------|---------|-------|--------|
| | | | |

---

## Network Issues

| Request | Status | Duration | Issue |
|---------|--------|----------|-------|
| | | | |
