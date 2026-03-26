# Template: Data Processing Pipeline

Complete ETL workflow with validation, transformation, and enrichment.

## Overview

This template provides a production-ready data processing pipeline with:

- Input validation & schema checking
- Error-resilient data fetching
- Parallel transformation & enrichment
- Batch processing support
- Quality checks & metrics

## Template

```markdown
---
name: data-processing-pipeline
description: Process data through validation, transformation, and enrichment stages
version: 0.1.0
inputs:
  - name: data_source_url
    type: string
    required: true
    description: URL or path to data source
    default: null
  - name: batch_size
    type: number
    required: false
    description: Number of records to process per batch
    default: 100
  - name: format
    type: string
    required: false
    description: Data format (json, csv, xml)
    default: json
outputs:
  - name: processed_data
    type: array
    description: Successfully processed records
  - name: failed_records
    type: array
    description: Records that failed processing
  - name: validation_report
    type: object
    description: Schema validation report
  - name: metrics
    type: object
    description: Processing metrics
env:
  - DATA_API_KEY
  - PROCESSOR_ENDPOINT
tags:
  - etl
  - data-pipeline
  - production-ready
---

## Validate Input

@assert $data_source_url != ""
@assert $batch_size > 0 && $batch_size <= 1000
@env DATA_API_KEY

## Fetch Raw Data

@try:
@call mcp.fetch_data($data_source_url, $format) → $raw_data
@on-error: retry
  @repeat max:3 until $raw_data != null:
    @call mcp.fetch_data($data_source_url, $format) → $raw_data
@call shell.exec("sleep 2")

@if $raw_data == null:
@output: error="Failed to fetch data after retries"

## Validate Schema

@call mcp.validate_schema($raw_data) → $validation_report

@if $validation_report.valid == false:
@output: error="Invalid schema", $validation_report

## Process in Batches

@for $batch in $raw_data chunks of $batch_size:
@parallel:

### Transform Batch

@try:
@call mcp.transform_batch($batch) → $transformed_batch
@on-error: log and continue
@call shell.exec("echo 'Batch transform failed'")

### Validate Batch

@try:
@call mcp.validate_batch($batch) → $validated_batch
@on-error: log and continue
@call shell.exec("echo 'Batch validation failed'")

## Enrich Data in Parallel

@parallel:

### Add Metadata

@call mcp.enrich_metadata($raw_data_results) → $with_metadata

### Add Relationships

@call mcp.enrich_relationships($raw_data_results) → $with_relationships

### Add Computed Fields

@call mcp.compute_fields($raw_data_results) → $with_computed

## Merge Results

@call mcp.merge_enriched($with_metadata, $with_relationships, $with_computed) → $processed_data

## Extract Failed Records

@call mcp.filter_failed($raw_data_results) → $failed_records

## Compute Metrics

@call mcp.compute_metrics({
"total_records": $raw_data.length,
"processed": $processed_data.length,
"failed": $failed_records.length,
"batch_size": $batch_size
}) → $metrics

## Validate Output Quality

@assert $processed_data.length + $failed_records.length == $raw_data.length

## Declare Outputs

@output: $processed_data, $failed_records, $validation_report, $metrics
```

## Customization Points

### 1. Data Sources

Replace `mcp.fetch_data()` with your source:

```markdown
# API

@call mcp.http_get($data_source_url) → $raw_data

# Database

@call mcp.db_query("SELECT \* FROM table") → $raw_data

# File

@call mcp.read_file($data_source_url) → $raw_data
```

### 2. Transformation Logic

Customize `mcp.transform_batch()`:

```markdown
@call mcp.normalize_fields($batch) → $normalized
@call mcp.convert_types($normalized) → $converted
@call mcp.apply_business_rules($converted) → $transformed_batch
```

### 3. Enrichment Strategies

Add or remove enrichment steps:

```markdown
@parallel:

### Geocoding

@call mcp.geocode_addresses($data) → $with_geocoding

### Currency Conversion

@call mcp.convert_currencies($data) → $with_currencies

### External API Data

@call mcp.fetch_external_data($data) → $with_external
```

### 4. Quality Checks

Add custom validations:

```markdown
@assert $metrics.success_rate > 0.95
@assert $processed_data.length > 0

@if $metrics.error_rate > 0.1:
@agent reviewer: "High error rate detected: $metrics. Review failed records: $failed_records" → $review
```

## Usage Examples

### Example 1: CSV File Processing

```bash
chainskills run data-pipeline.workflow.md \
  --input data_source_url="./data/users.csv" \
  --input format=csv \
  --input batch_size=50
```

### Example 2: API Data Ingestion

```bash
chainskills run data-pipeline.workflow.md \
  --input data_source_url="https://api.example.com/v1/data" \
  --input format=json \
  --input batch_size=100
```

### Example 3: Database Export

```bash
DATA_SOURCE_URL="postgresql://host/db" \
DATA_API_KEY="secret" \
chainskills run data-pipeline.workflow.md \
  --input format=json
```

## Expected Output

```json
{
  "processed_data": [
    { "id": 1, "name": "Alice", "metadata": {...}, "computed": {...} },
    { "id": 2, "name": "Bob", "metadata": {...}, "computed": {...} }
  ],
  "failed_records": [
    { "id": 3, "error": "Invalid format" }
  ],
  "validation_report": {
    "valid": true,
    "schema_version": "1.0",
    "errors": []
  },
  "metrics": {
    "total_records": 3,
    "processed": 2,
    "failed": 1,
    "batch_size": 100,
    "success_rate": 0.67
  }
}
```

## Performance Tips

1. **Batch Size** — Adjust based on memory and API rate limits
   - Small files (< 1K records): `batch_size=100`
   - Medium files (1K-100K): `batch_size=500`
   - Large files (> 100K): `batch_size=1000`

2. **Parallelization** — Ensure enrichment steps are truly independent

3. **Error Handling** — Use `log and continue` for non-critical failures

## Monitoring

Add observability:

```markdown
@call mcp.emit_metric("pipeline.start", { source: $data_source_url })
@call mcp.emit_metric("pipeline.complete", $metrics)
```
