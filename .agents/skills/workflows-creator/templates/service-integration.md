# Template: Resilient Service Integration

Service integration with circuit breaker, fallback, and cache.

## Overview

This template provides production-grade service integration with:

- Circuit breaker pattern (retry with exponential backoff)
- Fallback service cascade
- Cache-based recovery
- Error telemetry & alerting
- Health check mechanisms

## Template

```markdown
---
name: resilient-service-integration
description: Call external service with circuit breaker, fallback, and cache
version: 0.1.0
inputs:
  - name: service_endpoint
    type: string
    required: true
    description: Primary service URL or identifier
    default: null
  - name: payload
    type: object
    required: true
    description: Request payload
    default: null
  - name: timeout_seconds
    type: number
    required: false
    description: Request timeout in seconds
    default: 30
outputs:
  - name: response
    type: object
    description: Service response data
  - name: source
    type: string
    description: Response source (primary, fallback_1, fallback_2, cache)
  - name: latency_ms
    type: number
    description: Response latency in milliseconds
  - name: status
    type: string
    description: Operation status (success, partial, failed)
env:
  - SERVICE_API_KEY
  - FALLBACK_ENDPOINT_1
  - FALLBACK_ENDPOINT_2
  - CACHE_ENDPOINT
  - ALERT_WEBHOOK_URL
tags:
  - integration
  - resilience
  - circuit-breaker
  - production-ready
---

## Initialize

@assert $service_endpoint != ""
@assert $payload != null
@env SERVICE_API_KEY
@env FALLBACK_ENDPOINT_1
@env FALLBACK_ENDPOINT_2

@call shell.exec("date +%s%3N") → $start_time

## Primary Service Call with Circuit Breaker

@try:
@repeat max:3 until $response != null:
    @try:
      @call mcp.http_post($service_endpoint, $payload, {
        headers: { "Authorization": "Bearer $SERVICE_API_KEY" },
        timeout: $timeout_seconds
      }) → $response
      @call shell.exec("echo 'primary'") → $source
    @on-error: log and continue
      @call shell.exec("echo 'Primary attempt $_iteration failed'")
      @call shell.exec("sleep $(($\_iteration \* 2))") # Exponential backoff
@on-error: log and continue
@call shell.exec("echo 'Primary service exhausted retries'")
@call mcp.emit_metric("service.primary.failed", { endpoint: $service_endpoint })

## Fallback Cascade

@if $response == null:
  @try:
    @call mcp.http_post($FALLBACK_ENDPOINT_1, $payload, {
timeout: $timeout_seconds
}) → $response
@call shell.exec("echo 'fallback_1'") → $source
@on-error: log and continue
@call shell.exec("echo 'Fallback 1 failed, trying fallback 2'")

    @try:
      @call mcp.http_post($FALLBACK_ENDPOINT_2, $payload, {
        timeout: $timeout_seconds
      }) → $response
      @call shell.exec("echo 'fallback_2'") → $source
    @on-error: log and continue
      @call shell.exec("echo 'Fallback 2 failed, trying cache'")

## Cache Recovery

@if $response == null:
  @env CACHE_ENDPOINT
  @try:
    @call mcp.cache_get($CACHE_ENDPOINT, $payload.cache_key) → $cached_response
    @if $cached_response != null:
      @call shell.exec("echo '$cached_response'") → $response
@call shell.exec("echo 'cache'") → $source
@call shell.exec("echo 'Cache hit - serving stale data'")
@on-error: log and continue
@call shell.exec("echo 'Cache lookup failed'")

## Compute Latency

@call shell.exec("date +%s%3N") → $end_time
@call shell.exec("echo $(($end_time - $start_time))") → $latency_ms

## Determine Status

@if $response != null:
@if $source == "primary":
@call shell.exec("echo 'success'") → $status
@else:
@call shell.exec("echo 'partial'") → $status
@else:
@call shell.exec("echo 'failed'") → $status

## Alert on Failure

@if $status == "failed":
  @env ALERT_WEBHOOK_URL
  @try:
    @call mcp.http_post($ALERT_WEBHOOK_URL, {
alert: "Service integration failed",
endpoint: $service_endpoint,
payload: $payload,
timestamp: $end_time
}) → $alert_response
@on-error: log and continue
@call shell.exec("echo 'Alert webhook failed'")

## Emit Metrics

@call mcp.emit_metric("service.latency", {
value: $latency_ms,
source: $source,
status: $status
})

## Update Cache (if successful)

@if $response != null && $payload.cache_key != null:
  @try:
    @call mcp.cache_set($CACHE_ENDPOINT, $payload.cache_key, $response, { ttl: 3600 }) → $cache_stored
@on-error: log and continue
@call shell.exec("echo 'Cache update failed'")

## Declare Outputs

@output: $response, $source, $latency_ms, $status
```

## Customization Points

### 1. Retry Strategy

Customize backoff algorithm:

```markdown
# Linear backoff

@call shell.exec("sleep $\_iteration")

# Exponential backoff (default)

@call shell.exec("sleep $(($\_iteration \* 2))")

# Fibonacci backoff

@call shell.exec("sleep $(fib($\_iteration))")

# Jittered exponential

@call shell.exec("sleep $(( ($\_iteration \* 2) + (RANDOM % 3) ))")
```

### 2. Fallback Priority

Configure fallback hierarchy:

```markdown
# Geographic fallback

Primary → Same Region Fallback → Cross Region Fallback → Cache

# Service tier fallback

Premium Service → Standard Service → Basic Service → Cache

# Protocol fallback

gRPC → HTTP/2 → HTTP/1.1 → Cache
```

### 3. Cache Strategy

Customize cache behavior:

```markdown
# Write-through

@call mcp.cache_set($key, $response) → $cached

# Write-behind

@call mcp.cache_set_async($key, $response) → $queued

# Time-based expiry

@call mcp.cache_set($key, $response, { ttl: 3600 }) → $cached

# Content-based expiry

@call mcp.cache_set($key, $response, { ttl: $response.cache_duration }) → $cached
```

### 4. Error Handling

Add custom error logic:

```markdown
@if $\_error.type == "timeout":

# Immediate fallback on timeout

@call fallback_service() → $response
@else:
@if $\_error.type == "rate_limit": # Wait and retry on rate limit
@call shell.exec("sleep 60")
@call primary_service() → $response
```

## Usage Examples

### Example 1: API Gateway

```bash
chainskills run service-integration.workflow.md \
  --input service_endpoint="https://api.example.com/v1/process" \
  --input payload='{"user_id": 123, "action": "fetch"}' \
  --input timeout_seconds=10
```

### Example 2: Payment Processing

```bash
SERVICE_API_KEY="pk_live_..." \
FALLBACK_ENDPOINT_1="https://backup.payments.com" \
CACHE_ENDPOINT="redis://localhost:6379" \
chainskills run service-integration.workflow.md \
  --input service_endpoint="https://primary.payments.com/charge" \
  --input payload='{"amount": 100, "currency": "USD", "cache_key": "payment:123"}'
```

### Example 3: Data Enrichment

```bash
chainskills run service-integration.workflow.md \
  --input service_endpoint="https://enrichment.service.com/enrich" \
  --input payload='{"email": "user@example.com", "cache_key": "enrich:user@example.com"}'
```

## Expected Output

### Success Case (Primary)

```json
{
  "response": {
    "data": "...",
    "metadata": "..."
  },
  "source": "primary",
  "latency_ms": 245,
  "status": "success"
}
```

### Partial Success (Fallback)

```json
{
  "response": {
    "data": "...",
    "metadata": "..."
  },
  "source": "fallback_1",
  "latency_ms": 1823,
  "status": "partial"
}
```

### Cache Hit

```json
{
  "response": {
    "data": "...",
    "metadata": "...",
    "cached_at": "2026-02-13T10:30:00Z"
  },
  "source": "cache",
  "latency_ms": 15,
  "status": "partial"
}
```

### Total Failure

```json
{
  "response": null,
  "source": null,
  "latency_ms": 3420,
  "status": "failed"
}
```

## Performance Tips

1. **Timeout Configuration**
   - Internal services: `timeout=5s`
   - External APIs: `timeout=30s`
   - Heavy computation: `timeout=60s`

2. **Retry Budget**
   - Critical path: `max:2` retries
   - Background jobs: `max:5` retries
   - User-facing: `max:1` retry (fail fast)

3. **Cache TTL**
   - Static data: `ttl=86400` (24h)
   - Dynamic data: `ttl=300` (5min)
   - Real-time data: `ttl=10` (10s)

## Monitoring

Track these metrics:

```markdown
# Success rate

@call mcp.emit_metric("service.success_rate", {
total: $\_total_requests,
succeeded: $\_successful_requests
})

# Latency percentiles

@call mcp.emit_metric("service.latency.p95", $latency_p95_ms)

# Source distribution

@call mcp.emit_metric("service.source.primary", $primary_count)
@call mcp.emit_metric("service.source.fallback", $fallback_count)
@call mcp.emit_metric("service.source.cache", $cache_count)
```

## Health Checks

Add health check endpoint:

```markdown
## Health Check

@try:
@call mcp.http_get($service_endpoint + "/health") → $health
@on-error: log and continue
@call shell.exec("echo 'unhealthy'") → $health

@if $health.status != "healthy":

# Switch to fallback

@call shell.exec("echo 'Primary unhealthy, using fallback'")
```

## Circuit Breaker State

Track circuit state:

```markdown
# Open: Stop trying primary, go straight to fallback

# Half-Open: Try primary once, switch based on result

# Closed: Primary is healthy, use normally

@call mcp.circuit_breaker_state($service_endpoint) → $circuit_state

@if $circuit_state == "open":
@call fallback_service() → $response
@else:
@call primary_service() → $response
```
