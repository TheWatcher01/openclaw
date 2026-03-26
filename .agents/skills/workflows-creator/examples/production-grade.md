# Example: Production-Grade Workflow

Enterprise data pipeline with full observability, error recovery, and quality checks.

## Overview

This complete example demonstrates SOTA workflow design with:

- ✅ Input validation & security
- ✅ Circuit breaker & retry logic
- ✅ Batch processing with parallelization
- ✅ Error recovery strategies
- ✅ Quality checks & agent review
- ✅ Full observability (metrics, logging, alerting)
- ✅ Graceful degradation

## Complete Workflow

```markdown
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
    description: Maximum retry attempts per operation
    default: 3
  - name: quality_threshold
    type: number
    required: false
    description: Minimum acceptable quality score (0.0-1.0)
    default: 0.95
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
  - name: quality_report
    type: object
    description: Quality assessment report
env:
  - DATA_API_KEY
  - MONITORING_ENDPOINT
  - ALERT_WEBHOOK_URL
  - AGENT_API_KEY
tags:
  - production
  - data-pipeline
  - enterprise
  - observable
  - circuit-breaker
  - agent-powered
metadata:
  author: DataEng Team
  license: MIT
  version_compatibility: ">=0.3.0"
---

## 1. Initialize Pipeline

@env DATA_API_KEY
@env MONITORING_ENDPOINT
@env ALERT_WEBHOOK_URL
@assert $data_source_url != ""
@assert $batch_size > 0 && $batch_size <= 1000
@assert $max_retries > 0

@call shell.exec("date +%s%3N") → $pipeline_start_time
@call shell.exec("echo 'Starting pipeline at $(date)'")

@call mcp.emit_metric($MONITORING_ENDPOINT, "pipeline.start", {
source: $data_source_url,
batch_size: $batch_size,
timestamp: $pipeline_start_time
})

## 2. Fetch Data with Circuit Breaker

@try:
@repeat max:$max_retries until $raw_data != null:
    @try:
      @call mcp.fetch_data($data_source_url, {
headers: { "Authorization": "Bearer $DATA_API_KEY" },
timeout: 30
}) → $raw_data

      @call shell.exec("echo 'Data fetched successfully'")

    @on-error: log and continue
      @call shell.exec("echo 'Fetch attempt $_iteration failed, retrying...'")
      @call shell.exec("sleep $(($_iteration * 2))")  # Exponential backoff

@on-error: abort with notification
@call mcp.http_post($ALERT_WEBHOOK_URL, {
severity: "critical",
message: "Data fetch failed after $max_retries attempts",
source: $data_source_url,
timestamp: $pipeline_start_time
})
@output: error="Data fetch failed after retries"

@call mcp.emit_metric($MONITORING_ENDPOINT, "pipeline.fetch.success", {
records_count: $raw_data.length
})

## 3. Validate Data Schema

@call mcp.validate_schema($raw_data, {
schema_version: "1.0",
strict: true
}) → $schema_validation

@if $schema_validation.valid == false:
  @call mcp.emit_metric($MONITORING_ENDPOINT, "pipeline.validation.failed", {
errors: $schema_validation.errors
})

@call mcp.http_post($ALERT_WEBHOOK_URL, {
severity: "high",
message: "Schema validation failed",
errors: $schema_validation.errors
})

@output: error="Invalid schema", validation_report=$schema_validation

@call shell.exec("echo 'Schema validation passed'")

## 4. Batch Processing with Parallel Execution

@call shell.exec("echo 'Processing $raw_data.length records in batches of $batch_size'")

@for $batch in $raw_data chunks of $batch_size:
@call shell.exec("echo 'Processing batch $\_iteration of $total_batches'")

@try:
@parallel:

    ### Validate Batch
    @try:
      @call mcp.validate_batch($batch) → $validated_batch
    @on-error: log and continue
      @call shell.exec("echo 'Batch validation failed'")
      @call mcp.emit_metric($MONITORING_ENDPOINT, "batch.validation.failed", {
        batch_index: $_iteration
      })

    ### Enrich Batch
    @try:
      @call mcp.enrich_batch($batch) → $enriched_batch
    @on-error: log and continue
      @call shell.exec("echo 'Batch enrichment failed'")
      @call mcp.emit_metric($MONITORING_ENDPOINT, "batch.enrichment.failed", {
        batch_index: $_iteration
      })

    ### Transform Batch
    @try:
      @call mcp.transform_batch($batch) → $transformed_batch
    @on-error: log and continue
      @call shell.exec("echo 'Batch transformation failed'")
      @call mcp.emit_metric($MONITORING_ENDPOINT, "batch.transform.failed", {
        batch_index: $_iteration
      })

@on-error: log and continue
@call shell.exec("echo 'Batch processing failed, continuing with next batch'")
@call mcp.log_failed_batch($batch, $\_error)

## 5. Aggregate Results

@call mcp.merge_results($raw_data_results) → $all_processed_records
@call mcp.get_failed_records($raw_data_results) → $failed_records

@call shell.exec("echo 'Processed: $all_processed_records.length records'")
@call shell.exec("echo 'Failed: $failed_records.length records'")

## 6. Quality Checks

@call mcp.compute_quality_score($all_processed_records, {
check_completeness: true,
check_accuracy: true,
check_consistency: true
}) → $quality_score

@call shell.exec("echo 'Quality score: $quality_score'")

@if $quality_score < $quality_threshold:
  @call shell.exec("echo 'Quality below threshold ($quality_threshold), initiating agent review'")

@env AGENT_API_KEY

@agent reviewer: "Analyze quality issues in this data processing run:

Quality Score: $quality_score (threshold: $quality_threshold)
Processed Records: $all_processed_records.length
Failed Records: $failed_records.length
Failed Details: $failed_records

Provide:

1. Root cause analysis
2. Specific quality issues found
3. Recommendations for improvement" → $quality_analysis

@call mcp.emit_metric($MONITORING_ENDPOINT, "pipeline.quality.below_threshold", {
score: $quality_score,
threshold: $quality_threshold,
analysis: $quality_analysis
})

@call mcp.http_post($ALERT_WEBHOOK_URL, {
severity: "medium",
message: "Quality below threshold",
quality_score: $quality_score,
analysis: $quality_analysis
})

## 7. Data Consistency Checks

@assert $all_processed_records.length + $failed_records.length == $raw_data.length

@call shell.exec("echo 'Data consistency verified'")

## 8. Compute Execution Metrics

@call shell.exec("date +%s%3N") → $pipeline_end_time
@call shell.exec("echo $(($pipeline_end_time - $pipeline_start_time))") → $execution_time_ms

@call mcp.compute_metrics({
total_records: $raw_data.length,
processed_records: $all_processed_records.length,
failed_records: $failed_records.length,
execution_time_ms: $execution_time_ms,
batch_size: $batch_size,
quality_score: $quality_score
}) → $execution_metrics

@call shell.exec("echo 'Pipeline completed in $(($execution_time_ms / 1000)) seconds'")

## 9. Emit Final Metrics

@call mcp.emit_metric($MONITORING_ENDPOINT, "pipeline.complete", {
  metrics: $execution_metrics,
  quality_score: $quality_score,
  success_rate: $(($all_processed_records.length / $raw_data.length))
})

## 10. Generate Quality Report

@call mcp.generate_quality_report({
quality_score: $quality_score,
threshold: $quality_threshold,
processed_count: $all_processed_records.length,
failed_count: $failed_records.length,
failed_records: $failed_records,
analysis: $quality_analysis
}) → $quality_report

## 11. Declare Outputs

@output: $all_processed_records, $failed_records, $execution_metrics, $quality_report
```

## Architecture Highlights

### 1. Defense in Depth

**Multiple validation layers:**

- Input validation (Step 1)
- Schema validation (Step 3)
- Batch validation (Step 4)
- Consistency checks (Step 7)

### 2. Resilience Patterns

**Circuit breaker (Step 2):**

```markdown
@repeat max:$max_retries until $raw_data != null:
  @try:
    @call mcp.fetch_data() → $raw_data
  @on-error: log and continue
    @call shell.exec("sleep $(($\_iteration \* 2))")
```

**Graceful degradation:**

- Batch failures don't stop pipeline
- Quality issues trigger review, not abort
- Failed records tracked for retry

### 3. Observability

**Metrics at every stage:**

- `pipeline.start` — Pipeline initiated
- `pipeline.fetch.success` — Data fetched
- `pipeline.validation.failed` — Schema errors
- `batch.*.failed` — Batch-level failures
- `pipeline.quality.below_threshold` — Quality issues
- `pipeline.complete` — Final metrics

**Structured logging:**

```markdown
@call shell.exec("echo '[INFO] Processing batch $\_iteration'")
@call shell.exec("echo '[WARN] Quality below threshold'")
@call shell.exec("echo '[ERROR] Schema validation failed'")
```

**Alerting:**

- Critical: Data fetch failed → immediate alert
- High: Schema validation failed → alert
- Medium: Quality below threshold → alert + analysis

### 4. Agent Integration

**Quality Review Agent:**

```markdown
@agent reviewer: "Analyze quality issues..." → $quality_analysis
```

Triggered when:

- Quality score < threshold
- Provides root cause analysis
- Actionable recommendations

### 5. Performance Optimization

**Parallel batch processing:**

```markdown
@parallel:

### Validate Batch

### Enrich Batch

### Transform Batch
```

Independent operations run concurrently.

**Batch size tuning:**

- Small batches: Better parallelism, more overhead
- Large batches: Less overhead, less parallelism
- Default: 100 (balanced)

## Execution Flow

```
Initialize → Fetch (Circuit Breaker) → Validate Schema
                                              ↓
                       Consistency Check ← Batch Process (Parallel)
                              ↓
                       Quality Check → Agent Review (if needed)
                              ↓
                       Compute Metrics → Emit Observability
                              ↓
                         Output Results
```

## Usage

```bash
# Standard execution
DATA_API_KEY="secret" \
MONITORING_ENDPOINT="https://metrics.example.com" \
ALERT_WEBHOOK_URL="https://alerts.example.com/webhook" \
AGENT_API_KEY="sk-..." \
chainskills run production-pipeline.workflow.md \
  --input data_source_url="https://api.example.com/data" \
  --input batch_size=100 \
  --input max_retries=3 \
  --input quality_threshold=0.95
```

## Expected Output

```json
{
  "processed_records": [
    { "id": 1, "data": "...", "enriched": true },
    { "id": 2, "data": "...", "enriched": true }
  ],
  "failed_records": [
    { "id": 3, "error": "Invalid format", "raw": "..." }
  ],
  "execution_metrics": {
    "total_records": 1000,
    "processed_records": 987,
    "failed_records": 13,
    "execution_time_ms": 45230,
    "batch_size": 100,
    "quality_score": 0.97,
    "success_rate": 0.987
  },
  "quality_report": {
    "quality_score": 0.97,
    "threshold": 0.95,
    "passed": true,
    "processed_count": 987,
    "failed_count": 13,
    "failed_records": [...],
    "analysis": null
  }
}
```

## Monitoring Dashboard

Track these KPIs:

1. **Success Rate** — `processed / total`
2. **Error Rate** — `failed / total`
3. **Quality Score** — `0.0 - 1.0`
4. **Latency** — `execution_time_ms`
5. **Throughput** — `records / second`

## Alerting Rules

| Condition                | Severity | Action                       |
| ------------------------ | -------- | ---------------------------- |
| Data fetch failed        | Critical | Page on-call, abort pipeline |
| Schema validation failed | High     | Alert team, abort pipeline   |
| Quality < threshold      | Medium   | Alert + agent analysis       |
| Error rate > 10%         | Medium   | Alert team                   |
| Latency > SLA            | Low      | Monitor, no alert            |

## Best Practices Demonstrated

✅ **Input validation** — First step always
✅ **Error handling** — `@try/@on-error` on all external calls
✅ **Retry logic** — Circuit breaker with exponential backoff
✅ **Parallelization** — Batch operations run concurrently
✅ **Assertions** — Consistency checks throughout
✅ **Observability** — Metrics at every stage
✅ **Agent delegation** — Quality analysis when needed
✅ **Graceful degradation** — Pipeline continues despite batch failures
✅ **Structured outputs** — Clear, typed return values

## Extending the Pipeline

### Add Data Deduplication

```markdown
## 5.5. Deduplicate Records

@call mcp.deduplicate($all_processed_records, {
key: "id",
strategy: "keep_latest"
}) → $deduplicated_records
```

### Add Data Validation Rules

```markdown
## 3.5. Apply Business Rules

@call mcp.apply_business_rules($validated_data, {
rules: ["age >= 18", "email != null", "country in allowed_countries"]
}) → $rule_validation
```

### Add Incremental Processing

```markdown
## 2.5. Check Processed State

@call mcp.get_last_processed_id($data_source_url) → $last_id

@if $last_id != null:
  @call mcp.fetch_data($data_source_url + "?since=$last_id") → $raw_data
```

## Production Checklist

Before deploying:

- [ ] All env vars configured
- [ ] Monitoring endpoint reachable
- [ ] Alert webhook tested
- [ ] Agent API key valid
- [ ] Batch size tuned for dataset
- [ ] Quality threshold calibrated
- [ ] Error budget defined
- [ ] Rollback plan documented
- [ ] Load tested with production volume
- [ ] Metrics dashboard configured
