# Frontmatter Standards

Complete YAML frontmatter specification for chainskills workflows.

## Required Fields

### name

```yaml
name: my-workflow-name
```

- **Type:** `string`
- **Format:** kebab-case
- **Rules:** Unique identifier, lowercase, hyphens only
- **Examples:** `data-pipeline`, `agent-research`, `fetch-and-transform`

### description

```yaml
description: Clear one-sentence description of what this workflow does
```

- **Type:** `string`
- **Length:** 60-120 characters
- **Style:** Action-oriented, starts with verb
- **Examples:**
  - "Process data through validation, transformation, and enrichment"
  - "AI-powered research with validation and synthesis"
  - "Fetch API data with circuit breaker and fallback"

### version

```yaml
version: 0.1.0
```

- **Type:** `string`
- **Format:** SemVer (major.minor.patch)
- **Rules:**
  - Start with `0.1.0` for new workflows
  - Bump patch for bug fixes
  - Bump minor for new features
  - Bump major for breaking changes

### inputs

```yaml
inputs:
  - name: target
    type: string
    required: true
    description: URL or identifier to process
    default: null
  - name: depth
    type: number
    required: false
    description: Processing depth level
    default: 3
```

- **Type:** `array of objects`
- **Fields per input:**
  - `name` (string, required) — Variable name (snake_case)
  - `type` (string, required) — `string`, `number`, `boolean`, `object`, `array`
  - `required` (boolean, required) — Whether input is mandatory
  - `description` (string, required) — What this input represents
  - `default` (any, required) — Default value (use `null` if none)

### outputs

```yaml
outputs:
  - name: result
    type: object
    description: Processed result with metadata
  - name: metrics
    type: object
    description: Execution metrics and performance data
```

- **Type:** `array of objects`
- **Fields per output:**
  - `name` (string, required) — Variable name (snake_case)
  - `type` (string, required) — `string`, `number`, `boolean`, `object`, `array`
  - `description` (string, required) — What this output contains

---

## Optional Fields (Recommended)

### env

```yaml
env:
  - API_KEY
  - BASE_URL
  - TIMEOUT_SECONDS
```

- **Type:** `array of strings`
- **Purpose:** Security & documentation — declare all env vars used
- **Rules:**
  - UPPERCASE_SNAKE_CASE
  - No secrets in this list (just names)
  - Workflow will fail if missing vars not declared

### tags

```yaml
tags:
  - data-processing
  - automation
  - production-ready
  - mcp-compatible
```

- **Type:** `array of strings`
- **Purpose:** Discovery, categorization, search
- **Suggested tags:**
  - **Category:** `data-processing`, `api-integration`, `agent-research`, `security-scan`
  - **Use case:** `ci-cd`, `etl`, `monitoring`, `reporting`
  - **Status:** `draft`, `beta`, `production-ready`
  - **Interop:** `mcp-compatible`, `agent-powered`, `parallel-optimized`

### metadata

```yaml
metadata:
  author: DataEng Team
  license: MIT
  repository: https://github.com/org/repo
  requires:
    - mcp-server-v2
    - agent-provider
  version_compatibility: ">=0.3.0"
```

- **Type:** `object`
- **Fields (all optional):**
  - `author` (string) — Author or team name
  - `license` (string) — License type (MIT, Apache-2.0, etc.)
  - `repository` (string) — Git repo URL
  - `requires` (array) — Dependencies (MCP servers, skills, etc.)
  - `version_compatibility` (string) — Minimum chainskills version

---

## Complete Example

```yaml
---
name: production-data-pipeline
description: Enterprise-grade data processing with full observability and error recovery
version: 1.0.0
inputs:
  - name: data_source_url
    type: string
    required: true
    description: URL to fetch data from
    default: null
  - name: batch_size
    type: number
    required: false
    description: Number of records per batch
    default: 100
  - name: max_retries
    type: number
    required: false
    description: Maximum retry attempts
    default: 3
outputs:
  - name: processed_records
    type: array
    description: Successfully processed records
  - name: failed_records
    type: array
    description: Records that failed processing
  - name: execution_metrics
    type: object
    description: Performance and error metrics
env:
  - DATA_API_KEY
  - MONITORING_ENDPOINT
  - ALERT_WEBHOOK_URL
tags:
  - production
  - data-pipeline
  - enterprise
  - observable
  - circuit-breaker
metadata:
  author: DataEng Team
  license: MIT
  repository: https://github.com/company/workflows
  requires:
    - mcp-server-v2
    - agent-provider
  version_compatibility: ">=0.3.0"
---
```

---

## Best Practices

### DO ✅

- Keep description action-oriented and concise
- Declare ALL env vars used in the workflow
- Provide defaults for optional inputs
- Use descriptive variable names
- Tag workflows for discoverability
- Document author & license for shared workflows

### DON'T ❌

- Use generic descriptions like "Process data"
- Hardcode values that should be inputs
- Forget to declare env vars (security risk)
- Use camelCase or PascalCase for names (use kebab-case)
- Leave inputs without descriptions

---

## Type Reference

### Input/Output Types

| Type      | Description   | Example              |
| --------- | ------------- | -------------------- |
| `string`  | Text data     | `"example.com"`      |
| `number`  | Numeric value | `42`, `3.14`         |
| `boolean` | True/false    | `true`, `false`      |
| `object`  | JSON object   | `{ "key": "value" }` |
| `array`   | List of items | `["item1", "item2"]` |

### Advanced Patterns

For complex types, use `object` or `array` and describe structure in `description`:

```yaml
inputs:
  - name: filters
    type: object
    required: false
    description: "Filter criteria as { status: 'active', category: 'tech' }"
    default: {}
  - name: targets
    type: array
    required: true
    description: "Array of target URLs to process"
    default: null
```

---

## Validation Rules

chainskills validates frontmatter at parse time:

1. **Required fields** — name, description, version, inputs, outputs must be present
2. **Version format** — Must be valid SemVer
3. **Name format** — Must be kebab-case
4. **Input/output names** — Must be valid variable names (no spaces, special chars except `_`)
5. **Types** — Must be one of: string, number, boolean, object, array
6. **Env vars** — Must be UPPERCASE_SNAKE_CASE

Run `chainskills validate workflow.md` to check compliance.

---

## Migration Guide

### From v0.1.0 to v0.2.0+

```diff
---
name: my-workflow
description: Do stuff
- version: 0.1.0
+ version: 0.2.0
inputs:
  - name: target
    type: string
    required: true
    description: Target to process
-   default: ""
+   default: null
+ env:
+   - API_KEY
+ tags:
+   - production-ready
---
```

Changes:

- Empty string defaults → `null` for required inputs (clearer intent)
- Add `env` array for security
- Add `tags` for discoverability
