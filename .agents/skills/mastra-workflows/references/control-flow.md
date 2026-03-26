# Mastra Control Flow — Complete Reference

## Table of Contents

- [Sequential (.then)](#sequential-then)
- [Parallel (.parallel)](#parallel-parallel)
- [Branching (.branch)](#branching-branch)
- [Foreach (.foreach)](#foreach-foreach)
- [Loop Until (.dountil)](#loop-until-dountil)
- [Loop While (.dowhile)](#loop-while-dowhile)
- [Data Transform (.map)](#data-transform-map)
- [Composition Patterns](#composition-patterns)
- [Output Shapes Reference](#output-shapes-reference)

---

## Sequential (.then)

Chain steps one after another. Output of step N becomes input of step N+1.

```typescript
workflow
  .then(stepA) // stepA.outputSchema must be compatible with stepB.inputSchema
  .then(stepB)
  .then(stepC)
  .commit();
```

**Input wiring**: each step's `inputSchema` must match the previous step's `outputSchema`.

---

## Parallel (.parallel)

Execute multiple steps concurrently. All receive the same input.

```typescript
workflow
  .then(prepareStep)
  .parallel([analyzeStep, validateStep, enrichStep])
  .then(mergeStep)
  .commit();
```

**Output shape** — keyed by step ID:

```typescript
// mergeStep receives:
{
  "analyze": { /* analyzeStep output */ },
  "validate": { /* validateStep output */ },
  "enrich": { /* enrichStep output */ }
}
```

**mergeStep inputSchema** must declare all keys:

```typescript
const mergeStep = createStep({
  id: "merge",
  inputSchema: z.object({
    analyze: z.object({ score: z.number() }),
    validate: z.object({ valid: z.boolean() }),
    enrich: z.object({ data: z.string() }),
  }),
  // ...
});
```

---

## Branching (.branch)

Conditional execution — only ONE branch runs based on conditions.

```typescript
workflow
  .then(evaluateStep)
  .branch([
    [async ({ inputData }) => inputData.score > 80, highPathStep],
    [async ({ inputData }) => inputData.score > 50, medPathStep],
    [async ({ inputData }) => true, lowPathStep], // default/fallback
  ])
  .then(finalStep)
  .commit();
```

**Branch conditions**: async functions receiving `{ inputData }`, returning boolean. First truthy wins.

**Output shape** — only executed branch appears:

```typescript
// finalStep receives ONE of:
{ "high-path": { /* output */ } }  // OR
{ "med-path": { /* output */ } }   // OR
{ "low-path": { /* output */ } }
```

**finalStep inputSchema** must use `.optional()` for each possible branch:

```typescript
const finalStep = createStep({
  id: "final",
  inputSchema: z.object({
    "high-path": z.object({ result: z.string() }).optional(),
    "med-path": z.object({ result: z.string() }).optional(),
    "low-path": z.object({ result: z.string() }).optional(),
  }),
  execute: async ({ inputData }) => {
    const result = inputData["high-path"] ?? inputData["med-path"] ?? inputData["low-path"];
    return { finalResult: result!.result };
  },
});
```

---

## Foreach (.foreach)

Iterate a step over an array. Previous step must output an array-shaped field.

```typescript
const listStep = createStep({
  id: "list",
  outputSchema: z.object({ items: z.array(z.object({ id: z.string() })) }),
  execute: async () => ({ items: [{ id: "a" }, { id: "b" }, { id: "c" }] }),
});

const processItem = createStep({
  id: "process-item",
  inputSchema: z.object({ id: z.string() }), // receives single item
  outputSchema: z.object({ processed: z.boolean() }),
  execute: async ({ inputData }) => ({ processed: true }),
});

workflow
  .then(listStep)
  .foreach(processItem, { concurrency: 3 }) // process 3 items at a time
  .then(collectStep)
  .commit();
```

**Output shape** — array of step outputs:

```typescript
// collectStep receives:
{
  results: [
    { processed: true }, // item "a"
    { processed: true }, // item "b"
    { processed: true }, // item "c"
  ];
}
```

**Concurrency**: optional, defaults to 1 (sequential). Set higher for parallel processing.

---

## Loop Until (.dountil)

Execute a step repeatedly until a condition becomes true. Executes at least once.

```typescript
const refineStep = createStep({
  id: "refine",
  inputSchema: z.object({ quality: z.number() }),
  outputSchema: z.object({ quality: z.number() }),
  execute: async ({ inputData }) => ({
    quality: inputData.quality + Math.random() * 20,
  }),
});

workflow
  .then(initStep)
  .dountil(
    refineStep,
    async ({ inputData, getStepResult }) => inputData.quality >= 90, // stop when quality >= 90
  )
  .then(finalStep)
  .commit();
```

**Loop context**: the step's execute receives `iterationCount` in its params.

**Output**: the output from the LAST iteration.

---

## Loop While (.dowhile)

Execute a step while a condition remains true. Evaluates condition AFTER each execution.

```typescript
workflow
  .then(initStep)
  .dowhile(
    processStep,
    async ({ inputData }) => inputData.hasMore === true, // continue while hasMore
  )
  .then(finalStep)
  .commit();
```

Same semantics as `.dountil()` but inverted condition logic:

- `.dountil`: stops when condition is TRUE
- `.dowhile`: stops when condition is FALSE

---

## Data Transform (.map)

Transform data shape between steps without creating a full step.

```typescript
workflow
  .then(fetchStep) // outputs { users: [...], metadata: {...} }
  .map(async ({ inputData, getStepResult, getInitData }) => ({
    // reshape for next step
    userNames: inputData.users.map((u) => u.name),
    total: inputData.users.length,
  }))
  .then(displayStep) // receives { userNames: string[], total: number }
  .commit();
```

**Use cases**:

- Rename fields between incompatible step schemas
- Extract/flatten nested data
- Combine data from `getStepResult` with current input
- Inject original workflow input via `getInitData`

---

## Composition Patterns

### Parallel after Branch

```typescript
workflow
  .then(evaluateStep)
  .branch([
    [condition, pathA],
    [() => true, pathB],
  ])
  .parallel([processStep, logStep]) // both receive branch output
  .commit();
```

### Nested Foreach with Parallel

```typescript
workflow
  .then(getGroupsStep)
  .foreach(
    createWorkflow({ id: "process-group", inputSchema })
      .parallel([analyzeStep, validateStep])
      .then(mergeStep)
      .commit(),
    { concurrency: 2 },
  )
  .commit();
```

### Loop with Branch Inside

```typescript
const iterStep = createWorkflow({ id: "iteration", inputSchema })
  .then(processStep)
  .branch([
    [needsRetry, retryStep],
    [() => true, passStep],
  ])
  .commit();

workflow.then(initStep).dountil(iterStep, doneCondition).commit();
```

---

## Output Shapes Reference

| Method              | Output Shape                             | Next Step InputSchema          |
| ------------------- | ---------------------------------------- | ------------------------------ |
| `.then(step)`       | `step.outputSchema`                      | Must match `step.outputSchema` |
| `.parallel([a, b])` | `{ "a-id": a.output, "b-id": b.output }` | All keys required              |
| `.branch([[c, s]])` | `{ "s-id": s.output }` (one key)         | All branch keys `.optional()`  |
| `.foreach(step)`    | `{ results: step.output[] }`             | Wrap in `results` array        |
| `.dountil(step, c)` | `step.outputSchema`                      | Must match `step.outputSchema` |
| `.dowhile(step, c)` | `step.outputSchema`                      | Must match `step.outputSchema` |
| `.map(fn)`          | Return type of `fn`                      | Must match `fn` return         |
