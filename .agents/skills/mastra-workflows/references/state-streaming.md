# Mastra State & Streaming — Complete Reference

## Table of Contents

- [Workflow State](#workflow-state)
- [State Schema](#state-schema)
- [Reading & Writing State](#reading--writing-state)
- [State in Nested Workflows](#state-in-nested-workflows)
- [Streaming](#streaming)
- [Stream Events](#stream-events)
- [Patterns](#patterns)

---

## Workflow State

Workflow state is shared mutable data accessible by ALL steps in a workflow run.
Unlike step outputs (which flow forward through the DAG), state is a side-channel.

```typescript
const workflow = createWorkflow({
  id: "stateful-workflow",
  inputSchema: z.object({ query: z.string() }),
  stateSchema: z.object({
    processedCount: z.number(),
    errors: z.array(z.string()),
    metadata: z.record(z.unknown()),
  }),
});
```

**State vs Step Output**:

- **Step output**: flows through DAG edges, typed per step, immutable once produced
- **State**: shared across all steps, mutable via `setState`, for cross-cutting concerns

---

## State Schema

Define with `stateSchema` at workflow creation. Zod validates all state mutations.

```typescript
const workflow = createWorkflow({
  id: "tracking",
  inputSchema: z.object({ items: z.array(z.string()) }),
  stateSchema: z.object({
    totalProcessed: z.number().default(0),
    startTime: z.number().default(0),
    log: z.array(z.string()).default([]),
  }),
});
```

**Defaults**: use `.default()` on schema fields for initial state values.

---

## Reading & Writing State

Access via `state` (read) and `setState` (write) in step execute:

```typescript
const trackingStep = createStep({
  id: "track",
  inputSchema: z.object({ item: z.string() }),
  outputSchema: z.object({ processed: z.boolean() }),
  execute: async ({ inputData, state, setState }) => {
    // Read current state
    const count = state.totalProcessed;

    // Process item...
    const result = await processItem(inputData.item);

    // Update state (immutable pattern — always spread)
    setState({
      ...state,
      totalProcessed: count + 1,
      log: [...state.log, `Processed: ${inputData.item}`],
    });

    return { processed: true };
  },
});
```

**Critical**: `setState` replaces the ENTIRE state. Always spread `...state` to preserve other fields.

---

## State in Nested Workflows

Each workflow has its OWN state scope. Nested workflows don't share state with parents.

```typescript
const innerWorkflow = createWorkflow({
  id: "inner",
  inputSchema,
  stateSchema: z.object({ innerCount: z.number().default(0) }),
  // ^^^ separate state from parent
})
  .then(innerStep)
  .commit();

const outerWorkflow = createWorkflow({
  id: "outer",
  inputSchema,
  stateSchema: z.object({ outerCount: z.number().default(0) }),
  // ^^^ not visible to inner steps
})
  .then(outerStep)
  .then(innerWorkflow) // innerWorkflow uses its own stateSchema
  .commit();
```

**To share data between scopes**: use step output/input (DAG edges), not state.

---

## Streaming

Get real-time events as a workflow executes:

```typescript
const run = workflow.createRun();
const stream = run.stream({ inputData: { query: "test" } });

for await (const chunk of stream) {
  console.log(chunk.type, chunk.payload);
}
```

**Alternative**: use `run.start()` for batch (wait for completion), `run.stream()` for real-time.

---

## Stream Events

The stream emits typed event chunks:

| Event Type          | Payload                   | When                       |
| ------------------- | ------------------------- | -------------------------- |
| `step-start`        | `{ stepId, inputData }`   | Step begins execution      |
| `step-complete`     | `{ stepId, output }`      | Step finishes successfully |
| `step-error`        | `{ stepId, error }`       | Step fails                 |
| `step-suspend`      | `{ stepId, suspendData }` | Step suspends              |
| `workflow-start`    | `{ workflowId }`          | Workflow begins            |
| `workflow-complete` | `{ workflowId, results }` | Workflow finishes          |
| `workflow-error`    | `{ workflowId, error }`   | Workflow fails             |
| `state-change`      | `{ state }`               | State updated via setState |

```typescript
for await (const chunk of stream) {
  switch (chunk.type) {
    case "step-start":
      console.log(`▶ Starting: ${chunk.payload.stepId}`);
      break;
    case "step-complete":
      console.log(`✓ Done: ${chunk.payload.stepId}`);
      break;
    case "step-error":
      console.error(`✗ Failed: ${chunk.payload.stepId}`, chunk.payload.error);
      break;
    case "workflow-complete":
      console.log("Workflow done!", chunk.payload.results);
      break;
  }
}
```

---

## Patterns

### Pattern 1: Progress Tracking with State

```typescript
const workflow = createWorkflow({
  id: "batch-processor",
  inputSchema: z.object({ items: z.array(z.string()) }),
  stateSchema: z.object({
    total: z.number().default(0),
    completed: z.number().default(0),
    failed: z.number().default(0),
  }),
});

const processStep = createStep({
  id: "process",
  execute: async ({ inputData, state, setState }) => {
    try {
      await processItem(inputData);
      setState({ ...state, completed: state.completed + 1 });
    } catch {
      setState({ ...state, failed: state.failed + 1 });
    }
    return { done: true };
  },
});
```

### Pattern 2: Streaming with CLI Display

```typescript
import { spinner } from "@clack/prompts";

const s = spinner();
const run = workflow.createRun();
const stream = run.stream({ inputData });

for await (const chunk of stream) {
  if (chunk.type === "step-start") {
    s.start(`Running: ${chunk.payload.stepId}`);
  }
  if (chunk.type === "step-complete") {
    s.stop(`✓ ${chunk.payload.stepId}`);
  }
  if (chunk.type === "step-error") {
    s.stop(`✗ ${chunk.payload.stepId}: ${chunk.payload.error}`);
  }
}
```

### Pattern 3: Accumulator State

```typescript
const workflow = createWorkflow({
  id: "collector",
  inputSchema: z.object({ sources: z.array(z.string()) }),
  stateSchema: z.object({
    results: z
      .array(
        z.object({
          source: z.string(),
          data: z.unknown(),
        }),
      )
      .default([]),
  }),
});

const collectStep = createStep({
  id: "collect",
  execute: async ({ inputData, state, setState }) => {
    const data = await fetchFromSource(inputData.source);
    setState({
      ...state,
      results: [...state.results, { source: inputData.source, data }],
    });
    return { collected: true };
  },
});
```
