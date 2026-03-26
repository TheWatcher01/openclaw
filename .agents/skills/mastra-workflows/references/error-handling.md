# Mastra Error Handling — Complete Reference

## Table of Contents

- [Result Status](#result-status)
- [Retry Configuration](#retry-configuration)
- [Bail — Skip Retries](#bail--skip-retries)
- [Lifecycle Callbacks](#lifecycle-callbacks)
- [Conditional Error Branching](#conditional-error-branching)
- [Accessing Step Results](#accessing-step-results)
- [Error Patterns](#error-patterns)

---

## Result Status

Every workflow run returns a result object with status info per step:

```typescript
const run = workflow.createRun();
const result = await run.start({ inputData: {...} });

// Check overall status
if (result.status === "success") {
  const output = result.results["my-step"].output;
}

// Per-step statuses: "success" | "failed" | "suspended" | "skipped"
const stepResult = result.results["step-id"];
if (stepResult.status === "success") {
  console.log(stepResult.output);
} else if (stepResult.status === "failed") {
  console.error(stepResult.error);
}
```

---

## Retry Configuration

Add `retryConfig` to any step for automatic retry on failure:

```typescript
const fetchStep = createStep({
  id: "fetch-data",
  inputSchema: z.object({ url: z.string() }),
  outputSchema: z.object({ data: z.unknown() }),
  retryConfig: {
    attempts: 3, // Total attempts (1 initial + 2 retries)
    delay: 1000, // Delay between retries in ms
  },
  execute: async ({ inputData }) => {
    const res = await fetch(inputData.url);
    if (!res.ok) throw new Error(`HTTP ${res.status}`);
    return { data: await res.json() };
  },
});
```

**Behavior**:

- Step throws → waits `delay` ms → retries
- After all `attempts` exhausted → step marked as `failed`
- Delay is constant (not exponential by default)

---

## Bail — Skip Retries

Use `bail()` inside a step to immediately fail without retrying:

```typescript
const step = createStep({
  id: "validate",
  retryConfig: { attempts: 5, delay: 500 },
  execute: async ({ inputData, bail }) => {
    // Unrecoverable errors — don't waste retries
    if (!inputData.apiKey) {
      bail("Missing API key — no retry will fix this");
    }

    // Transient errors — let retries handle
    const res = await fetch(url, { headers: { Authorization: inputData.apiKey } });
    if (!res.ok) throw new Error("Transient failure, will retry");

    return { data: await res.json() };
  },
});
```

**Use `bail()` for**: missing config, auth failures, validation errors, malformed input.
**Use `throw` for**: network timeouts, rate limits, temporary unavailability.

---

## Lifecycle Callbacks

Attach callbacks when starting a workflow run:

```typescript
const result = await run.start({
  inputData: { query: "test" },

  onFinish: (result) => {
    // Called when workflow completes (success OR failure)
    console.log("Workflow finished with status:", result.status);
    // Use for: cleanup, metrics, notifications
  },

  onError: (error) => {
    // Called when workflow fails with an unhandled error
    console.error("Workflow error:", error.message);
    // Use for: alerting, error reporting, fallback logic
  },
});
```

**`onFinish`**: always called, receives the full result object.
**`onError`**: only called on failure, receives the error.

---

## Conditional Error Branching

Use `.branch()` to route based on success/failure of previous steps:

```typescript
workflow
  .then(riskyStep)
  .branch([
    [
      async ({ inputData, getStepResult }) => {
        const result = getStepResult<typeof riskyStep>("risky");
        return result.status === "success";
      },
      successPathStep,
    ],
    [
      async () => true, // default: error path
      errorRecoveryStep,
    ],
  ])
  .commit();
```

---

## Accessing Step Results

Use `getStepResult` to access output from any previously executed step:

```typescript
const laterStep = createStep({
  id: "later",
  execute: async ({ inputData, getStepResult, getInitData }) => {
    // Access a specific earlier step (type-safe)
    const earlyResult = getStepResult<typeof earlyStep>("early-step-id");

    // Access the original workflow input
    const initData = getInitData<typeof workflow>();

    return { combined: `${earlyResult.output.value} + ${initData.original}` };
  },
});
```

**Type safety**: pass the step type as generic parameter for typed access.
**Scope**: can access ANY step that has already executed in the current run.

---

## Error Patterns

### Pattern 1: Retry with Fallback

```typescript
const primaryStep = createStep({
  id: "primary",
  retryConfig: { attempts: 3, delay: 2000 },
  execute: async ({ inputData }) => {
    return await callPrimaryAPI(inputData);
  },
});

const fallbackStep = createStep({
  id: "fallback",
  execute: async ({ inputData }) => {
    return await callBackupAPI(inputData);
  },
});

workflow
  .then(primaryStep)
  .branch([
    [async ({ getStepResult }) => getStepResult("primary").status === "success", passThrough],
    [async () => true, fallbackStep],
  ])
  .commit();
```

### Pattern 2: Try-Catch Workflow

Wrap risky operations in a sub-workflow:

```typescript
const riskyWorkflow = createWorkflow({ id: "risky-op", inputSchema }).then(dangerousStep).commit();

// In the parent, check result status to decide next action
workflow
  .then(riskyWorkflow)
  .branch([
    [async ({ getStepResult }) => getStepResult("risky-op").status === "failed", recoveryStep],
    [async () => true, continueStep],
  ])
  .commit();
```

### Pattern 3: Graceful Degradation

```typescript
const step = createStep({
  id: "optional-enrichment",
  retryConfig: { attempts: 2, delay: 500 },
  execute: async ({ inputData, bail }) => {
    try {
      const enriched = await enrichData(inputData);
      return { ...inputData, enriched };
    } catch {
      // Return input as-is rather than failing
      return { ...inputData, enriched: null };
    }
  },
});
```
