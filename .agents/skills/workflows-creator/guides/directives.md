# Directive Patterns

Complete reference for all 17 chainskills directives with SOTA usage patterns.

## Control Flow

### @if / @else

**Conditional branching**

```markdown
@if $condition:
@call action_true()
@else:
@call action_false()
```

**Nested conditions:**

```markdown
@if $score > 90:
@call handle_excellent()
@else:
@if $score > 70:
@call handle_good()
@else:
@call handle_needs_improvement()
```

**Complex conditions:**

```markdown
@if $status == "active" && $count > 0:
@call process()
```

### @for

**Bounded iteration over collection**

```markdown
@for $item in $items:
  @call process($item) → $result
@call shell.exec("echo 'Processed: $item'")
```

**With index (implicit `$_iteration`):**

```markdown
@for $item in $items:
@call shell.exec("echo 'Processing item $\_iteration: $item'")
```

**Nested loops:**

```markdown
@for $category in $categories:
  @for $item in $category.items:
    @call process($category, $item)
```

### @repeat

**Loop with exit condition**

```markdown
@repeat max:5 until $quality_score > 0.9:
  @agent reviewer: "Improve: $draft" → $draft
  @call mcp.score_quality($draft) → $quality_score
```

**With retry logic:**

```markdown
@repeat max:3 until $success == true:
@try:
@call external_api() → $result
@call shell.exec("echo 'success'") → $success
@on-error: log and continue
@call shell.exec("sleep 2")
```

### @parallel

**Explicit parallel execution**

```markdown
@parallel:

### Task A

@call service_a() → $result_a

### Task B

@call service_b() → $result_b

### Task C

@call service_c() → $result_c
```

**Access results:**

```markdown
@parallel:

### Fetch User

@call api.get_user($id) → $user

### Fetch Orders

@call api.get_orders($id) → $orders

## Merge Results

@call merge($user, $orders) → $profile
```

---

## Error Handling

### @try / @on-error

**Graceful error handling**

```markdown
@try:
@call risky_operation() → $result
@on-error: log and continue
@call shell.exec("echo 'Operation failed, using fallback'")
@call fallback_operation() → $result
```

**Actions:**

- `log and continue` — Log error, continue execution
- `log and retry` — Log error, retry the operation
- `abort` — Stop workflow execution
- `abort with notification` — Stop + send alert

**Nested try:**

```markdown
@try:
@call primary_service() → $data
@on-error: log and continue
@try:
@call fallback_service() → $data
@on-error: abort
@output: error="All services failed"
```

---

## Validation & Assertions

### @assert

**Runtime validation checkpoint**

```markdown
@assert $target != ""
@assert $count > 0
@assert $status == "valid"
```

**Complex assertions:**

```markdown
@assert $budget.total == $budget.charges
@assert $items.length > 0 && $items.length <= 100
```

**Use cases:**

- Input validation (workflow entry)
- Postconditions (after processing)
- Invariants (data consistency checkpoints)

---

## I/O & State

### @env

**Load environment variable**

```markdown
@env API_KEY
@env BASE_URL
@env TIMEOUT_SECONDS
```

**Must be declared in frontmatter:**

```yaml
env:
  - API_KEY
  - BASE_URL
```

**Use in workflow:**

```markdown
@env API_KEY
@call api.authenticate($API_KEY) → $token
```

### @call

**Invoke tool and capture result**

```markdown
@call tool.method($arg) → $result
```

**MCP tools:**

```markdown
@call mcp.fetch_data($url) → $data
@call mcp.transform($data) → $transformed
```

**Shell commands:**

```markdown
@call shell.exec("echo 'Hello'") → $output
@call shell.exec("date +%s") → $timestamp
```

**Chaining:**

```markdown
@call fetch($url) → $raw_data
@call validate($raw_data) → $validated_data
@call transform($validated_data) → $final_data
```

### @output

**Declare workflow outputs**

```markdown
@output: $result, $metrics, $warnings
```

**Must match frontmatter outputs:**

```yaml
outputs:
  - name: result
  - name: metrics
  - name: warnings
```

---

## Composition

### @use

**Import skill or sub-workflow**

```markdown
@use ./common/validators
@use ./processors/enrich-data
```

**Access imported workflow:**

```markdown
@use ./common/validators
@workflow ./common/validators: $input → $validated
```

### @workflow

**Execute sub-workflow**

```markdown
@workflow ./path/to/workflow: $input → $output
```

**With complex inputs:**

```markdown
@workflow ./process-batch: {
data: $batch,
config: $config
} → $processed_batch
```

---

## Agent Integration

### @agent

**Delegate to AI agent**

```markdown
@agent copilot: "Analyze this data: $data" → $analysis
```

**With context variables:**

```markdown
@agent copilot: "Based on $context, provide recommendations for $target" → $recommendations
```

**Multi-turn:**

```markdown
@agent copilot: "Analyze: $data" → $analysis
@agent reviewer: "Critique: $analysis" → $critique
@agent copilot: "Improve based on: $critique" → $improved
```

### @handoff

**Transfer to another agent**

```markdown
@agent copilot: "Draft proposal for $project" → $draft

@if $confidence < 0.8:
@handoff reviewer: "Review and improve this draft: $draft" → $final_draft
```

**Use cases:**

- Low confidence → human review
- Specialized tasks → domain expert agent
- Quality checks → reviewer agent

---

## Advanced Patterns

### Circuit Breaker

```markdown
@repeat max:3 until $success == true:
  @try:
    @call external_service() → $result
    @call shell.exec("echo 'success'") → $success
  @on-error: log and continue
    @call shell.exec("sleep $(($\_iteration \* 2))")
```

### Map-Reduce

```markdown
## Map Phase

@for $item in $items:
  @call process($item) → $processed_item

## Reduce Phase

@call aggregate($items_results) → $final_result
```

### Error Recovery Cascade

```markdown
@try:
@call primary_service() → $data
@on-error: log and continue
@try:
@call fallback_service_1() → $data
@on-error: log and continue
@try:
@call fallback_service_2() → $data
@on-error: log and continue
@call get_cached_data() → $data
```

### Pipeline with Checkpoints

```markdown
@workflow validate-input: $input → $validated
@assert $validated.valid == true

@workflow transform-data: $validated → $transformed
@assert $transformed.errors.length == 0

@workflow enrich-data: $transformed → $enriched
@assert $enriched.quality_score > 0.9
```

### Parallel + Error Handling

```markdown
@parallel:

### Fetch User (critical)

@try:
@call api.get_user($id) → $user
@on-error: abort
@output: error="Cannot proceed without user"

### Fetch Preferences (optional)

@try:
@call api.get_preferences($id) → $preferences
@on-error: log and continue
@call shell.exec("echo '{}'") → $preferences
```

### Agent Chain of Thought

```markdown
@agent copilot: "Analyze: $problem" → $analysis

@agent critic: "Find flaws in: $analysis" → $critique

@agent copilot: "Address these critiques: $critique. Original: $analysis" → $improved_analysis

@if $improved_analysis.confidence > 0.9:
@output: $improved_analysis
@else:
@handoff human-expert: "Low confidence result needs review: $improved_analysis"
```

---

## Variable Scope

### Step-level Variables

```markdown
## Step 1

@call fetch() → $data # Available in this step and below
```

### Loop Variables

```markdown
@for $item in $items:

# $item available in loop body

# $\_iteration contains current index
```

### Error Variables

```markdown
@try:
@call risky() → $result
@on-error: log and continue

# $\_error contains error details

@call shell.exec("echo 'Error: $\_error'")
```

---

## Performance Tips

### Maximize Parallelism

```markdown
# ❌ Sequential (slow)

@call task_a() → $a
@call task_b() → $b

# ✅ Parallel (fast)

@parallel:

### Task A

@call task_a() → $a

### Task B

@call task_b() → $b
```

### Minimize Variable Dependencies

```markdown
# ❌ Creates dependency chain

@call step1() → $x
@call step2($x) → $y
@call step3($x) → $z

# ✅ DAG auto-detects parallelism

@call step1() → $x
@parallel:

### Step 2

@call step2($x) → $y

### Step 3

@call step3($x) → $z
```

### Early Validation

```markdown
# ✅ Fail fast at start

@assert $input != ""
@assert $config.valid == true

# Long processing...
```

---

## Anti-Patterns

### ❌ No Error Handling

```markdown
@call external_api() # What if it fails?
```

### ✅ Wrapped with Recovery

```markdown
@try:
@call external_api() → $result
@on-error: retry
@repeat max:3:
@call external_api() → $result
```

---

### ❌ Sequential When Parallel Possible

```markdown
@call fetch_users() → $users
@call fetch_products() → $products # No dependency
```

### ✅ Explicit Parallelization

```markdown
@parallel:

### Users

@call fetch_users() → $users

### Products

@call fetch_products() → $products
```

---

### ❌ Unclear Variable Names

```markdown
@call fetch() → $data
@call process($data) → $result
```

### ✅ Descriptive Names

```markdown
@call fetch() → $raw_user_data
@call process($raw_user_data) → $validated_user_profile
```

---

## Quick Reference Table

| Directive        | Purpose                  | Example                              |
| ---------------- | ------------------------ | ------------------------------------ |
| `@if/@else`      | Branch                   | `@if $x > 0:`                        |
| `@for`           | Loop over collection     | `@for $item in $items:`              |
| `@repeat`        | Loop with exit condition | `@repeat max:5 until $done:`         |
| `@parallel`      | Explicit parallel block  | `@parallel:`                         |
| `@try/@on-error` | Error handling           | `@try: ... @on-error: retry`         |
| `@assert`        | Validation checkpoint    | `@assert $x != ""`                   |
| `@env`           | Load env var             | `@env API_KEY`                       |
| `@call`          | Invoke tool              | `@call tool.method($arg) → $result`  |
| `@output`        | Declare outputs          | `@output: $result, $metrics`         |
| `@use`           | Import skill             | `@use ./path/to/skill`               |
| `@workflow`      | Execute sub-workflow     | `@workflow ./path: $in → $out`       |
| `@agent`         | Delegate to agent        | `@agent copilot: "prompt" → $result` |
| `@handoff`       | Transfer to agent        | `@handoff expert: "task" → $result`  |
