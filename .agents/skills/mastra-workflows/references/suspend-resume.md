# Mastra Suspend & Resume — Complete Reference

## Table of Contents

- [Basic Suspend/Resume](#basic-suspendresume)
- [Resume Schema](#resume-schema)
- [Suspend Data](#suspend-data)
- [Multi-Step Suspend](#multi-step-suspend)
- [Suspend in Nested Workflows](#suspend-in-nested-workflows)
- [Sleep (Time-Based Suspend)](#sleep-time-based-suspend)
- [Patterns](#patterns)

---

## Basic Suspend/Resume

Suspend pauses workflow execution at a step, allowing later resumption with external data.

```typescript
const approvalStep = createStep({
  id: "approval",
  inputSchema: z.object({ request: z.string() }),
  outputSchema: z.object({ approved: z.boolean(), approver: z.string() }),
  resumeSchema: z.object({
    decision: z.enum(["approve", "reject"]),
    approver: z.string(),
  }),
  execute: async ({ inputData, suspend, resumeData }) => {
    // First execution: no resumeData → suspend
    if (!resumeData) {
      await suspend({ message: `Approval needed for: ${inputData.request}` });
      return undefined as never; // Never reached — suspend throws internally
    }

    // After resume: resumeData is populated
    return {
      approved: resumeData.decision === "approve",
      approver: resumeData.approver,
    };
  },
});
```

**Flow**:

1. Step executes → `resumeData` is `undefined` → calls `suspend()`
2. Workflow pauses, returns status `"suspended"`
3. External system calls `run.resume(...)` with data matching `resumeSchema`
4. Step re-executes → `resumeData` is now populated → returns output

---

## Resume Schema

Define the Zod schema for data expected on resume:

```typescript
const step = createStep({
  // ...
  resumeSchema: z.object({
    userInput: z.string(),
    confirmed: z.boolean(),
  }),
  execute: async ({ resumeData, suspend }) => {
    if (!resumeData) {
      await suspend();
      return undefined as never;
    }
    // resumeData is typed: { userInput: string, confirmed: boolean }
    return { result: resumeData.userInput };
  },
});
```

**Type safety**: `resumeData` is automatically typed from `resumeSchema`.

---

## Suspend Data

Pass contextual data when suspending to inform the external system:

```typescript
execute: async ({ inputData, suspend, resumeData }) => {
  if (!resumeData) {
    await suspend({
      // This data is available in the suspended run result
      prompt: "Please review the following items",
      items: inputData.items,
      deadline: new Date(Date.now() + 86400000).toISOString(),
    });
    return undefined as never;
  }
  return { reviewed: true };
};
```

**Accessing suspend data** from the run result:

```typescript
const result = await run.start({ inputData });
if (result.status === "suspended") {
  const suspendData = result.results["step-id"].suspendData;
  // { prompt: "...", items: [...], deadline: "..." }
}
```

---

## Multi-Step Suspend

Multiple steps in a workflow can independently suspend:

```typescript
const reviewStep = createStep({
  id: "review",
  resumeSchema: z.object({ feedback: z.string() }),
  execute: async ({ suspend, resumeData }) => {
    if (!resumeData) {
      await suspend();
      return undefined as never;
    }
    return { feedback: resumeData.feedback };
  },
});

const signoffStep = createStep({
  id: "signoff",
  resumeSchema: z.object({ signed: z.boolean() }),
  execute: async ({ suspend, resumeData }) => {
    if (!resumeData) {
      await suspend();
      return undefined as never;
    }
    return { signed: resumeData.signed };
  },
});

workflow.then(reviewStep).then(signoffStep).commit();

// Resume each step in order:
const run1 = workflow.createRun();
let result = await run1.start({ inputData });
// status: "suspended" at "review"

result = await run1.resume({ step: reviewStep, resumeData: { feedback: "LGTM" } });
// status: "suspended" at "signoff"

result = await run1.resume({ step: signoffStep, resumeData: { signed: true } });
// status: "success"
```

---

## Suspend in Nested Workflows

Suspend works in sub-workflows. Resume targets the specific step:

```typescript
const innerWorkflow = createWorkflow({ id: "inner", inputSchema })
  .then(humanStep)  // this step suspends
  .commit();

const outerWorkflow = createWorkflow({ id: "outer", inputSchema })
  .then(prepStep)
  .then(innerWorkflow)
  .then(finalStep)
  .commit();

const run = outerWorkflow.createRun();
let result = await run.start({ inputData });
// Suspended at inner > humanStep

// Resume targets the step directly, even if nested
result = await run.resume({ step: humanStep, resumeData: {...} });
```

---

## Sleep (Time-Based Suspend)

Use built-in sleep for time-based delays:

```typescript
import { sleep } from "@mastra/core/workflows";

const waitStep = createStep({
  id: "wait",
  execute: async ({ inputData }) => {
    await sleep(5000); // Pause 5 seconds
    return { waited: true };
  },
});
```

**Note**: `sleep` is NOT a suspend — it blocks the step execution. For true time-based suspension with persistence, combine `suspend()` with an external scheduler that calls `resume()`.

---

## Patterns

### Pattern 1: Human-in-the-Loop Approval

```typescript
const workflow = createWorkflow({ id: "approval-flow", inputSchema })
  .then(generateProposal)
  .then(
    createStep({
      id: "human-review",
      resumeSchema: z.object({
        approved: z.boolean(),
        comments: z.string().optional(),
      }),
      execute: async ({ inputData, suspend, resumeData }) => {
        if (!resumeData) {
          await suspend({ proposal: inputData.proposal, reviewUrl: "/review/123" });
          return undefined as never;
        }
        if (!resumeData.approved) {
          throw new Error(`Rejected: ${resumeData.comments}`);
        }
        return { approved: true, proposal: inputData.proposal };
      },
    }),
  )
  .then(executeProposal)
  .commit();
```

### Pattern 2: External API Webhook

```typescript
// 1. Start workflow — suspends waiting for webhook
const run = workflow.createRun();
const result = await run.start({ inputData: { orderId: "123" } });
// Store run ID for later: result.runId

// 2. Webhook handler (e.g., Express route)
app.post("/webhook/payment", async (req, res) => {
  const { runId, status } = req.body;
  const run = workflow.getRunById(runId);
  await run.resume({
    step: paymentStep,
    resumeData: { paymentStatus: status },
  });
  res.sendStatus(200);
});
```

### Pattern 3: Iterative Refinement with Human Feedback

```typescript
const refineStep = createStep({
  id: "refine",
  resumeSchema: z.object({ feedback: z.string(), satisfactory: z.boolean() }),
  execute: async ({ inputData, suspend, resumeData }) => {
    const draft = resumeData
      ? await refineWithFeedback(inputData.draft, resumeData.feedback)
      : inputData.draft;

    if (!resumeData?.satisfactory) {
      await suspend({ currentDraft: draft });
      return undefined as never;
    }
    return { finalDraft: draft };
  },
});

workflow
  .then(generateDraft)
  .dountil(
    refineStep,
    async ({ getStepResult }) => getStepResult("refine").output?.finalDraft != null,
  )
  .commit();
```
