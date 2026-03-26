# Best Practices

Comprehensive checklist, conventions, and anti-patterns for chainskills workflows.

## Pre-Creation Checklist

### ✅ Planning Phase

- [ ] **Single Responsibility** — Workflow has ONE clear purpose
- [ ] **Inputs identified** — Know what data flows in
- [ ] **Outputs identified** — Know what data flows out
- [ ] **Dependencies mapped** — External services, MCP tools, agents
- [ ] **Error scenarios** — What can fail and how to handle
- [ ] **Performance needs** — Latency requirements, parallelization opportunities

### ✅ Design Phase

- [ ] **Frontmatter complete** — name, description, version, inputs, outputs
- [ ] **Env vars declared** — All environment variables listed
- [ ] **Tags added** — For discovery and categorization
- [ ] **Steps outlined** — Clear sequence with action verbs
- [ ] **Validation points** — Where to assert invariants

---

## During Creation Checklist

### ✅ Structure

- [ ] **Input validation first** — Always first step with `@assert` + `@env`
- [ ] **Clear step boundaries** — Each heading = one logical operation
- [ ] **Output declaration last** — Final step with `@output`
- [ ] **Modular design** — Extract reusable logic to sub-workflows

### ✅ Error Handling

- [ ] **@try/@on-error** around all external calls (API, MCP, shell)
- [ ] **Retry logic** for transient failures (`@repeat` + `@try`)
- [ ] **Fallback strategies** for critical operations
- [ ] **Error context** captured in variables

### ✅ Performance

- [ ] **@parallel** for independent operations
- [ ] **Minimize variable dependencies** to maximize DAG parallelization
- [ ] **Early exits** with `@if` + `@output` for invalid inputs
- [ ] **Batch processing** for large datasets (`@for` with batching)

### ✅ Variables

- [ ] **Descriptive names** with prefixes (`$validated_*`, `$processed_*`)
- [ ] **No generic names** (`$data`, `$result`, `$temp`)
- [ ] **Type clarity** in comments if ambiguous
- [ ] **Scope management** (step-level, loop-level)

---

## Post-Creation Checklist

### ✅ Validation

- [ ] `chainskills validate workflow.md` passes with no errors
- [ ] All referenced files exist (sub-workflows, skills)
- [ ] Frontmatter matches actual inputs/outputs used
- [ ] Variable names are consistent

### ✅ Inspection

- [ ] `chainskills inspect workflow.md` shows expected DAG
- [ ] Parallel blocks are correctly identified
- [ ] Dependencies make sense visually

### ✅ Testing

- [ ] `--dry-run` executes without errors
- [ ] Test with valid inputs → expected outputs
- [ ] Test with invalid inputs → proper error handling
- [ ] Test edge cases (empty arrays, null values, etc.)

### ✅ Documentation

- [ ] README or inline comments explain workflow purpose
- [ ] Usage examples with real input values
- [ ] Environment variables documented with examples
- [ ] Known limitations or constraints listed

---

## Naming Conventions

### Workflow Names

```yaml
# ✅ Good
name: user-data-enrichment
name: security-vulnerability-scan
name: multi-stage-approval-flow

# ❌ Bad
name: workflow1
name: MyWorkflow
name: process_data
```

**Rules:**

- kebab-case only
- Descriptive, not generic
- Action-oriented (verb + noun)

### Variable Names

```markdown
# ✅ Good

$input_user_id
$validated_email_address
$processed_transaction_batch
$final_report_pdf

# ❌ Bad

$data
$result
$temp
$x
```

**Rules:**

- snake_case only
- Prefix with lifecycle stage: `$input_*`, `$validated_*`, `$processed_*`, `$final_*`
- Avoid abbreviations unless universally known (URL, API, ID)

### Step Titles

```markdown
# ✅ Good

## Validate User Registration Data

## Fetch External API Data with Retry

## Transform and Enrich Records in Parallel

# ❌ Bad

## Step 1

## Do Stuff

## Process
```

**Rules:**

- Start with action verb
- Describe WHAT and (briefly) WHY
- Clear scope boundaries

---

## Architecture Patterns

### Pattern: Input Validation Gateway

```markdown
## Validate Inputs

@assert $email != ""
@assert $age >= 18
@env API_KEY
@env BASE_URL

@if $email !~ /.+@.+\..+/:
@output: error="Invalid email format"
```

### Pattern: Error Recovery Cascade

```markdown
@try:
@call primary_service($arg) → $result
@on-error: log and continue
  @try:
    @call fallback_service_1($arg) → $result
  @on-error: log and continue
    @try:
      @call fallback_service_2($arg) → $result
@on-error: abort
@output: error="All services failed"
```

### Pattern: Circuit Breaker

```markdown
@repeat max:3 until $success == true:
  @try:
    @call external_api($arg) → $result
    @call shell.exec("echo 'true'") → $success
  @on-error: log and continue
    @call shell.exec("sleep $(($\_iteration \* 2))")

@if $success != true:
@output: error="Service unavailable after retries"
```

### Pattern: Pipeline with Checkpoints

```markdown
@workflow validate-schema: $input → $validated
@assert $validated.valid == true

@workflow transform-data: $validated → $transformed
@assert $transformed.errors.length == 0

@workflow enrich-data: $transformed → $enriched
@assert $enriched.quality_score > 0.9

@output: $enriched
```

### Pattern: Map-Reduce

```markdown
## Map Phase: Process Each Item

@for $item in $items:
  @try:
    @call process_item($item) → $processed_item
@on-error: log and continue
@call shell.exec("echo 'Failed: $item.id'")

## Reduce Phase: Aggregate Results

@call aggregate($items_results) → $final_result
@assert $final_result.total == $items.length
```

### Pattern: Agent Chain of Thought

```markdown
@agent copilot: "Analyze: $problem" → $initial_analysis

@agent critic: "Find flaws in: $initial_analysis" → $critique

@agent copilot: "Address critiques: $critique" → $improved_analysis

@if $improved_analysis.confidence > 0.9:
@output: $improved_analysis
@else:
@handoff human-expert: "Low confidence: $improved_analysis"
```

---

## Anti-Patterns

### ❌ No Input Validation

```markdown
## Process Data

@call process($data) # What if $data is invalid/missing?
```

### ✅ Always Validate First

```markdown
## Validate Input

@assert $data != ""
@assert $data.type == "expected"

## Process Data

@call process($data)
```

---

### ❌ Bare External Calls

```markdown
@call external_api($param)  # What if it fails?
@call another_api($result)
```

### ✅ Wrapped with Error Handling

```markdown
@try:
@call external_api($param) → $result
@on-error: retry
  @repeat max:3:
    @call external_api($param) → $result

@if $result == null:
@output: error="API call failed"
```

---

### ❌ Sequential When Parallel Possible

```markdown
@call fetch_users() → $users
@call fetch_products() → $products # No dependency on $users
@call fetch_categories() → $categories # No dependency
```

### ✅ Explicit Parallelization

```markdown
@parallel:

### Fetch Users

@call fetch_users() → $users

### Fetch Products

@call fetch_products() → $products

### Fetch Categories

@call fetch_categories() → $categories
```

---

### ❌ Unclear Variable Names

```markdown
@call fetch() → $data
@call process($data) → $result
@call format($result) → $output
```

### ✅ Descriptive Names

```markdown
@call fetch() → $raw_user_data
@call process($raw_user_data) → $validated_user_profile
@call format($validated_user_profile) → $formatted_json_response
```

---

### ❌ No Error Context

```markdown
@try:
@call risky_operation()
@on-error: abort
@output: error="Failed" # What failed? Why?
```

### ✅ Rich Error Context

```markdown
@try:
@call risky_operation($param) → $result
@on-error: abort
@output: error="risky_operation failed for param: $param. Reason: $\_error"
```

---

### ❌ Missing Assertions

```markdown
@call calculate_total($items) → $total
@call charge_payment($total) # What if $total is 0 or negative?
```

### ✅ Assert Invariants

```markdown
@call calculate_total($items) → $total
@assert $total > 0
@assert $total <= 1000000

@call charge_payment($total)
```

---

### ❌ Hardcoded Values

```markdown
@call api.fetch("https://api.example.com/data") # Hardcoded URL
@repeat max:5 # Magic number
```

### ✅ Externalized Config

```markdown
@env API_BASE_URL
@env MAX_RETRIES

@call api.fetch($API_BASE_URL + "/data")
@repeat max:$MAX_RETRIES
```

---

## Performance Best Practices

### Maximize Parallelism

```markdown
# DAG will auto-detect this as parallel (no explicit @parallel needed):

@call task_a() → $a
@call task_b() → $b # No dependency on $a

# But explicit is clearer for complex workflows:

@parallel:

### Task A

@call task_a() → $a

### Task B

@call task_b() → $b
```

### Minimize Dependencies

```markdown
# ❌ Creates unnecessary dependency

@call fetch_data() → $data
@call compute_hash($data) → $hash
@call validate_data($data) → $valid # Could run parallel with hash

# ✅ Independent operations

@call fetch_data() → $data
@parallel:

### Compute Hash

@call compute_hash($data) → $hash

### Validate

@call validate_data($data) → $valid
```

### Early Exits

```markdown
## Validate Input

@if $input == "" || $input.length > 10000:
@output: error="Invalid input" # Exit early, don't waste resources

## Expensive Processing

@call heavy_computation($input)
```

### Batch Processing

```markdown
# ❌ Process one at a time (slow)

@for $item in $large_array:
  @call api.process($item)

# ✅ Process in batches

@for $batch in $large_array chunks of 100:
@parallel:

### Process Batch

@for $item in $batch:
    @call api.process($item)
```

---

## Security Best Practices

### Environment Variables

```yaml
# ✅ Declare all env vars
env:
  - DATABASE_URL
  - API_KEY
  - SECRET_TOKEN
```

```markdown
# ✅ Load explicitly

@env DATABASE_URL
@env API_KEY

# ❌ Never hardcode

@call api.connect("postgresql://user:pass@host/db") # NO!
```

### Input Sanitization

```markdown
## Validate and Sanitize

@assert $user_input != ""
@assert $user_input.length <= 1000

# Sanitize for shell injection

@call shell.exec("echo 'Processing: $user_input'") # Safe: chainskills escapes
```

### Secrets

```markdown
# ✅ Use env vars

@env SECRET_KEY
@call api.authenticate($SECRET_KEY)

# ❌ Never in workflow

@call api.authenticate("sk-1234567890abcdef") # NO!
```

---

## Documentation Standards

### Inline Comments

```markdown
## Fetch External Data

<!-- Retry up to 3 times with exponential backoff for transient network errors -->

@repeat max:3 until $data != null:
  @try:
    @call api.fetch($endpoint) → $data
  @on-error: log and continue
    @call shell.exec("sleep $(($\_iteration \* 2))")
```

### Usage Examples in README

````markdown
# User Registration Workflow

## Usage

\```bash
chainskills run user-registration.workflow.md \\
--input email="user@example.com" \\
--input age=25 \\
--input country="US"
\```

## Expected Output

\```json
{
"user_id": "usr_abc123",
"status": "registered",
"verification_sent": true
}
\```
````

---

## Versioning Strategy

### SemVer Rules

- **Patch (0.1.0 → 0.1.1)** — Bug fixes, no behavior change
- **Minor (0.1.x → 0.2.0)** — New optional inputs/outputs, backward compatible
- **Major (0.x.y → 1.0.0)** — Breaking changes (removed inputs, changed behavior, incompatible outputs)

### Changelog

Keep a `CHANGELOG.md` for shared workflows:

```markdown
# Changelog

## [0.2.0] - 2026-02-13

### Added

- New optional input `max_retries` with default 3
- Parallel processing for validation step

### Changed

- Improved error messages with context

## [0.1.0] - 2026-02-01

### Added

- Initial release
```

---

## Testing Strategy

### Unit Test (Step-Level)

```bash
# Test individual steps by calling sub-workflows
chainskills run validate-step.workflow.md --input data='...'
```

### Integration Test (Full Workflow)

```bash
# Test with sample inputs
chainskills run workflow.md \\
  --input target="test.example.com" \\
  --dry-run
```

### Edge Case Matrix

| Test Case      | Input                  | Expected Output         |
| -------------- | ---------------------- | ----------------------- |
| Valid input    | `target="example.com"` | Success                 |
| Empty input    | `target=""`            | Error: "Invalid input"  |
| Invalid format | `target="not-a-url"`   | Error: "Invalid format" |
| API failure    | Network down           | Retry → Fallback        |

---

## Common Mistakes

| Mistake                | Impact           | Fix                       |
| ---------------------- | ---------------- | ------------------------- |
| No input validation    | Runtime errors   | Add `@assert` first       |
| No error handling      | Workflow crashes | Wrap in `@try/@on-error`  |
| Sequential processing  | Slow execution   | Use `@parallel`           |
| Generic variable names | Hard to debug    | Use descriptive names     |
| Hardcoded values       | Not reusable     | Use env vars/inputs       |
| Missing assertions     | Silent failures  | Add `@assert` checkpoints |
| No documentation       | Hard to use      | Add README + comments     |

---

## Quick Decision Tree

**Should I parallelize?**

- Are operations independent? → YES, use `@parallel`
- Do they depend on each other? → NO, keep sequential

**Should I retry?**

- Is failure transient (network, rate limit)? → YES, use `@repeat` + `@try`
- Is failure permanent (auth, not found)? → NO, abort and report

**Should I assert?**

- Is this a critical invariant? → YES, use `@assert`
- Is this optional/informational? → NO, use `@if` for conditional logic

**Should I extract to sub-workflow?**

- Is logic reused >2 times? → YES, extract with `@workflow`
- Is it single-use? → NO, keep inline

**Should I use an agent?**

- Does task require LLM reasoning? → YES, use `@agent`
- Is it deterministic computation? → NO, use `@call` tool
