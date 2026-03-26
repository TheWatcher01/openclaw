# Integration Guidelines

How to integrate chainskills workflows with MCP tools, AI agents, and external skills.

## MCP Tool Integration

### Configuration

Declare MCP servers in frontmatter:

```yaml
env:
  - MCP_SERVERS
```

### Calling MCP Tools

```markdown
@call mcp.tool_name($param) → $result
```

**Namespace:** All MCP tools are under the `mcp.` namespace.

### Available MCP Operations

Workflows can invoke any MCP tool installed on the system:

```markdown
# Example: GitHub MCP

@call mcp.github_create_issue("owner/repo", "Bug report", "Description") → $issue

# Example: Filesystem MCP

@call mcp.read_file("/path/to/file") → $content

# Example: Database MCP

@call mcp.query("SELECT \* FROM users WHERE id = $user_id") → $rows
```

### Dynamic Tool Discovery

To list available MCP tools at runtime:

```markdown
@call mcp.list_tools() → $available_tools

@for $tool in $available_tools:
@call shell.exec("echo 'Available: $tool.name'")
```

### Error Handling with MCP

MCP calls can fail (network, auth, rate limits):

```markdown
@try:
@call mcp.external_service($arg) → $result
@on-error: retry
  @repeat max:3 until $result != null:
    @call mcp.external_service($arg) → $result
@call shell.exec("sleep 2")

@if $result == null:
@output: error="MCP service unavailable"
```

### MCP Server Configuration

Set up MCP servers in `.vscode/mcp.json` or via environment:

```json
{
  "mcpServers": {
    "github": {
      "command": "npx",
      "args": ["-y", "@modelcontextprotocol/server-github"],
      "env": {
        "GITHUB_TOKEN": "${GITHUB_TOKEN}"
      }
    },
    "filesystem": {
      "command": "npx",
      "args": ["-y", "@modelcontextprotocol/server-filesystem", "/workspace"]
    }
  }
}
```

Then in workflow:

```markdown
@env GITHUB_TOKEN
@call mcp.github_create_issue($owner, $repo, $title, $body) → $issue
```

---

## Agent Integration

### Configuration

Declare agent provider in frontmatter:

```yaml
env:
  - AGENT_API_KEY
  - AGENT_BASE_URL # Optional: for custom LLM endpoints
```

### Agent Providers

chainskills supports any **OpenAI-compatible API**:

- OpenAI (GPT-4, GPT-3.5)
- Anthropic Claude (via adapter)
- Azure OpenAI
- Local models (Ollama, LM Studio, text-generation-webui)
- Custom endpoints

### Basic Agent Call

```markdown
@agent copilot: "Analyze this data: $data" → $analysis
```

**Syntax:**

```
@agent <agent_name>: "<prompt with $variables>" → $output_variable
```

### Prompt with Variables

```markdown
@env AGENT_API_KEY
@agent copilot: "Given context: $context, provide recommendations for target: $target" → $recommendations
```

Variables are substituted before sending to the agent.

### Multi-Agent Workflows

```markdown
## Analysis Phase

@agent analyst: "Analyze the problem: $problem_description" → $initial_analysis

## Critique Phase

@agent critic: "Find flaws and edge cases in this analysis: $initial_analysis" → $critique

## Synthesis Phase

@agent writer: "Create a comprehensive report addressing these critiques: $critique. Original analysis: $initial_analysis" → $final_report
```

### Agent Handoff

Transfer to another agent when confidence is low or specialized expertise is needed:

```markdown
@agent copilot: "Draft a proposal for: $project" → $draft

@if $draft.confidence < 0.8:
  @handoff human-expert: "Review and improve this low-confidence draft: $draft" → $final_draft
@else:
  @call shell.exec("echo '$draft'") → $final_draft
```

### Agent Error Handling

Agents can fail (API outage, rate limits, invalid responses):

```markdown
@try:
@agent copilot: "Complex task: $input" → $result
@on-error: retry
@repeat max:2 until $result != null:
@agent copilot: "Complex task: $input" → $result

@if $result == null:
@output: error="Agent unavailable"
```

### Custom Agent Endpoints

```bash
# .env
AGENT_API_KEY=sk-...
AGENT_BASE_URL=https://api.openai.com/v1  # Default

# Or for local:
AGENT_BASE_URL=http://localhost:11434/v1  # Ollama
```

---

## Skill Composition

### Importing Skills

```markdown
@use ./common/validators
@use ./processors/data-enrichment
```

**Relative paths** are resolved from the workflow file location.

### Executing Sub-Workflows

```markdown
@workflow ./common/validators: $input → $validated_input

@if $validated_input.valid == false:
  @output: error=$validated_input.errors

@workflow ./processors/data-enrichment: $validated_input → $enriched_data
```

### Nested Workflows

```markdown
## Step 1: Validate

@workflow ./validators/schema-validator: $raw_data → $validated_data

## Step 2: Transform

@workflow ./transformers/json-to-csv: $validated_data → $csv_data

## Step 3: Enrich

@workflow ./enrichers/add-metadata: $csv_data → $final_data
```

### Workflow Composition Pattern

Create reusable building blocks:

**validators/email.workflow.md:**

```yaml
---
name: email-validator
inputs:
  - name: email
    type: string
    required: true
outputs:
  - name: valid
    type: boolean
  - name: normalized_email
    type: string
---

## Validate Email Format

@assert $email != ""
@if $email =~ /.+@.+\..+/:
  @call shell.exec("echo 'true'") → $valid
  @call normalize_email($email) → $normalized_email
@else:
  @call shell.exec("echo 'false'") → $valid
  @call shell.exec("echo ''") → $normalized_email

@output: $valid, $normalized_email
```

**Main workflow:**

```markdown
@workflow ./validators/email: $user_email → $email_result

@if $email_result.valid == false:
@output: error="Invalid email"

@call register_user($email_result.normalized_email)
```

---

## Shell Command Integration

### Basic Shell Execution

```markdown
@call shell.exec("echo 'Hello World'") → $output
@call shell.exec("date +%s") → $timestamp
@call shell.exec("ls -la") → $file_list
```

### With Variables

```markdown
@call shell.exec("echo 'Processing: $item_name'") → $log
@call shell.exec("curl -s $api_url") → $response
```

**Security:** chainskills automatically escapes variables to prevent shell injection.

### Command Chaining

```markdown
@call shell.exec("date +%Y-%m-%d") → $date
@call shell.exec("mkdir -p /tmp/reports/$date") → $mkdir_output
@call shell.exec("echo 'Report data' > /tmp/reports/$date/report.txt") → $write_output
```

### Allowed Commands

For security, shell execution is **whitelisted**:

- `echo` — Output text
- `sleep` — Delay execution
- `date` — Get timestamp
- `curl` — HTTP requests (if explicitly enabled)
- `jq` — JSON processing (if installed)

Check `CHAINSKILLS_SHELL_ALLOWLIST` env var for your system's configuration.

---

## Service Integration Patterns

### Pattern: Multi-Service Orchestration

```markdown
@parallel:

### Fetch from Service A

@try:
@call mcp.service_a_fetch($id) → $data_a
@on-error: log and continue
@call shell.exec("echo '{}'") → $data_a

### Fetch from Service B

@try:
@call mcp.service_b_fetch($id) → $data_b
@on-error: log and continue
@call shell.exec("echo '{}'") → $data_b

### Fetch from Service C

@try:
@call mcp.service_c_fetch($id) → $data_c
@on-error: log and continue
@call shell.exec("echo '{}'") → $data_c

## Merge Results

@call merge_data($data_a, $data_b, $data_c) → $merged_data
```

### Pattern: API Gateway

```markdown
@if $request.service == "github":
  @call mcp.github_api($request.method, $request.params) → $result
@else:
  @if $request.service == "slack":
    @call mcp.slack_api($request.method, $request.params) → $result
@else:
@output: error="Unknown service: $request.service"

@output: $result
```

### Pattern: Event-Driven Workflow

```markdown
@env WEBHOOK_ENDPOINT

## Trigger Agent Analysis

@agent copilot: "Analyze event: $event_data" → $analysis

## Post Result to Webhook

@try:
@call mcp.http_post($WEBHOOK_ENDPOINT, $analysis) → $webhook_response
@on-error: log and continue
@call shell.exec("echo 'Webhook failed'")

@output: $analysis
```

---

## Advanced Integration

### Combining MCP + Agent + Shell

```markdown
## Fetch Data (MCP)

@try:
@call mcp.fetch_data($source) → $raw_data
@on-error: abort
@output: error="Data fetch failed"

## Transform Data (Shell)

@call shell.exec("echo '$raw_data' | jq '.items[]'") → $items

## Analyze with Agent

@agent copilot: "Analyze these items and provide insights: $items" → $analysis

## Store Results (MCP)

@call mcp.store_analysis($analysis) → $stored_id

@output: $stored_id, $analysis
```

### Dynamic Tool Selection

```markdown
@if $tool_type == "mcp":
  @call mcp.dynamic_tool($params) → $result
@else:
  @if $tool_type == "agent":
    @agent copilot: "Execute: $params" → $result
  @else:
    @call shell.exec($params) → $result
```

### Workflow as MCP Tool

Workflows can be exposed as MCP tools via `chainskills serve`:

```bash
chainskills serve --port 3001
```

Then other workflows or apps can call:

```markdown
@call mcp.workflow_name($input) → $output
```

---

## Configuration Management

### Environment Variables

Declare all integrations in frontmatter:

```yaml
env:
  - MCP_SERVERS # MCP server config
  - AGENT_API_KEY # Agent authentication
  - AGENT_BASE_URL # Optional: custom endpoint
  - WEBHOOK_ENDPOINT # External webhooks
  - DATABASE_URL # Database connections
  - ALLOWED_SHELL_COMMANDS # Shell whitelist
```

### Runtime Configuration

Pass config as inputs:

```yaml
inputs:
  - name: config
    type: object
    required: false
    description: "Runtime config: { timeout: 30, retry: 3 }"
    default: { timeout: 30, retry: 3 }
```

```markdown
@repeat max:$config.retry until $result != null:
@call api.fetch() → $result
```

---

## Best Practices

### MCP Integration

- ✅ Wrap all MCP calls in `@try/@on-error`
- ✅ Use retry logic for transient failures
- ✅ Validate MCP responses before use
- ✅ Handle rate limits gracefully
- ❌ Don't assume MCP tools are always available

### Agent Integration

- ✅ Provide clear, specific prompts
- ✅ Include context variables in prompts
- ✅ Handle low-confidence responses with `@handoff`
- ✅ Use multi-agent patterns for quality
- ❌ Don't rely on agents for deterministic tasks (use tools instead)

### Skill Composition

- ✅ Extract reusable logic to sub-workflows
- ✅ Keep sub-workflows single-purpose
- ✅ Validate sub-workflow outputs with `@assert`
- ✅ Document dependencies in frontmatter
- ❌ Don't nest workflows >3 levels deep (complexity explosion)

### Shell Integration

- ✅ Use shell for simple text processing only
- ✅ Rely on chainskills escaping for safety
- ✅ Keep commands simple (1-2 operations max)
- ❌ Don't use shell for critical operations (use MCP tools instead)
- ❌ Don't assume shell commands succeed (wrap in `@try`)

---

## Troubleshooting

### MCP Connection Issues

```markdown
@try:
@call mcp.tool_name() → $result
@on-error: abort

# Check MCP server is running: chainskills serve

# Verify MCP_SERVERS env var is set

@output: error="MCP connection failed. Check server status."
```

### Agent API Failures

```markdown
@try:
@agent copilot: "Task" → $result
@on-error: log and continue

# Check AGENT_API_KEY is valid

# Verify AGENT_BASE_URL is reachable

@call shell.exec("echo 'Using fallback'")
@call fallback_deterministic_method() → $result
```

### Sub-Workflow Not Found

```markdown
@try:
@workflow ./path/to/workflow: $input → $output
@on-error: abort

# Verify file exists: ./path/to/workflow.workflow.md

# Check paths are relative to current workflow

@output: error="Sub-workflow not found at path"
```

---

## Testing Integration Points

### Mock MCP Tools

```bash
# dry-run automatically mocks MCP calls
chainskills run workflow.md --dry-run
```

### Mock Agents

```bash
# Set noop agent provider
AGENT_API_KEY=noop chainskills run workflow.md
```

### Test Sub-Workflows Independently

```bash
# Test each sub-workflow separately
chainskills validate ./validators/email.workflow.md
chainskills run ./validators/email.workflow.md --input email="test@example.com"
```

---

## Example: Full-Stack Integration

```markdown
---
name: full-stack-integration-example
description: Demonstrates MCP, agent, shell, and skill composition
version: 1.0.0
inputs:
  - name: user_id
    type: string
    required: true
outputs:
  - name: enriched_profile
    type: object
env:
  - DATABASE_URL
  - AGENT_API_KEY
  - MCP_SERVERS
tags:
  - integration
  - full-stack
---

## Validate Input

@use ./validators/user-id
@workflow ./validators/user-id: $user_id → $validation_result
@assert $validation_result.valid == true

## Fetch Data from Multiple Sources (MCP)

@parallel:

### Fetch User from Database

@call mcp.db_query("SELECT \* FROM users WHERE id = $user_id") → $user_data

### Fetch User Activity

@call mcp.api_fetch("/activity/$user_id") → $activity_data

### Fetch User Preferences

@call mcp.redis_get("prefs:$user_id") → $preferences

## Analyze with Agent

@agent copilot: "Analyze user profile: $user_data. Activity: $activity_data. Preferences: $preferences. Provide insights and recommendations." → $insights

## Enrich Profile (Shell + Custom Logic)

@call shell.exec("echo '$user_data' | jq '. + {insights: $insights}'") → $enriched_profile

## Store Results (MCP)

@call mcp.redis_set("profile:enriched:$user_id", $enriched_profile) → $stored

@output: $enriched_profile
```
