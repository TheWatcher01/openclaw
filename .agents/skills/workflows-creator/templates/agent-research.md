# Template: Agent Research Pipeline

AI-powered research workflow with validation and synthesis.

## Overview

This template provides an agent-driven research pipeline with:

- Multi-agent collaboration (analyst → critic → writer)
- Iterative quality improvement
- Source validation & citation
- Structured output generation
- Confidence-based handoff

## Template

```markdown
---
name: agent-research-pipeline
description: AI-powered research with validation and synthesis
version: 0.1.0
inputs:
  - name: research_topic
    type: string
    required: true
    description: Topic or question to research
    default: null
  - name: depth
    type: number
    required: false
    description: Research depth (number of sub-questions)
    default: 3
  - name: quality_threshold
    type: number
    required: false
    description: Minimum quality score (0.0 - 1.0)
    default: 0.85
outputs:
  - name: research_report
    type: object
    description: Final research report with findings
  - name: sources
    type: array
    description: List of sources and citations
  - name: confidence_score
    type: number
    description: Overall confidence in findings
env:
  - AGENT_API_KEY
  - SEARCH_API_KEY
tags:
  - research
  - ai
  - agent-powered
  - multi-agent
---

## Validate Input

@assert $research_topic != ""
@assert $depth > 0 && $depth <= 10
@assert $quality_threshold >= 0.0 && $quality_threshold <= 1.0
@env AGENT_API_KEY
@env SEARCH_API_KEY

## Generate Research Plan

@agent copilot: "Create a structured research plan for: $research_topic. Break down into $depth specific, actionable sub-questions. Format as JSON array." → $research_plan

@assert $research_plan.questions != null

## Execute Research in Parallel

@parallel:

### Research Each Question

@for $question in $research_plan.questions:
  @try:
    @agent analyst: "Research this question thoroughly: $question. Provide detailed findings with sources." → $finding
    @call mcp.store_finding($question, $finding) → $stored
@on-error: log and continue
@call shell.exec("echo 'Research failed for: $question'")

### Gather Authoritative Sources

@try:
@agent copilot: "Find 5-10 authoritative sources for: $research_topic. Prioritize academic, government, and reputable publications." → $sources
@on-error: log and continue
@call shell.exec("echo '[]'") → $sources

### Collect Background Context

@try:
@call mcp.search_context($research_topic, $SEARCH_API_KEY) → $context
@on-error: log and continue
@call shell.exec("echo '{}'") → $context

## Synthesize Findings

@call mcp.get_all_findings() → $all_findings

@agent writer: "Synthesize these research findings into a comprehensive report:

Findings: $all_findings
Sources: $sources
Context: $context
Topic: $research_topic

Format as structured report with: Executive Summary, Key Findings, Analysis, Recommendations, Sources." → $draft_report

## Quality Review Loop

@call mcp.score_quality($draft_report) → $quality_score

@repeat max:3 until $quality_score >= $quality_threshold:
@agent critic: "Review this research report for accuracy, completeness, and clarity. Identify specific improvements needed: $draft_report" → $critique

@agent writer: "Improve the report based on this critique: $critique. Original report: $draft_report" → $draft_report

@call mcp.score_quality($draft_report) → $quality_score

## Confidence Check

@call mcp.compute_confidence($draft_report, $sources, $all_findings) → $confidence_score

@if $confidence_score < 0.7:
  @handoff human-expert: "Low confidence research result (confidence: $confidence_score). Report: $draft_report. Please review and enhance." → $reviewed_report
  @call shell.exec("echo '$reviewed_report'") → $research_report
@else:
  @call shell.exec("echo '$draft_report'") → $research_report

## Format Final Output

@call mcp.format_report($research_report, $sources) → $formatted_report

## Declare Outputs

@output: $formatted_report, $sources, $confidence_score
```

## Customization Points

### 1. Research Agents

Customize agent roles:

```markdown
# Analyst: Deep research

@agent analyst: "Research deeply with academic rigor: $question" → $finding

# Domain Expert: Specialized knowledge

@agent domain-expert: "As a $domain expert, analyze: $question" → $expert_finding

# Fact Checker: Verification

@agent fact-checker: "Verify these claims with sources: $finding" → $verified_finding
```

### 2. Quality Metrics

Define custom quality scoring:

```markdown
@call mcp.score_quality($report, {
accuracy: 0.4,
completeness: 0.3,
clarity: 0.2,
citations: 0.1
}) → $quality_score
```

### 3. Multi-Pass Research

Add iterative refinement:

```markdown
@repeat max:2 until $coverage > 0.9:
@agent copilot: "Identify gaps in this research: $draft_report" → $gaps
@for $gap in $gaps:
@agent analyst: "Fill this research gap: $gap" → $additional_finding
```

### 4. Source Validation

Integrate fact-checking:

```markdown
@for $source in $sources:
  @call mcp.validate_source($source.url) → $validation
@if $validation.reliable == false:
@agent fact-checker: "Find alternative source for: $source.claim"
```

## Usage Examples

### Example 1: Technical Research

```bash
chainskills run agent-research.workflow.md \
  --input research_topic="Impact of quantum computing on cryptography" \
  --input depth=5 \
  --input quality_threshold=0.9
```

### Example 2: Market Research

```bash
chainskills run agent-research.workflow.md \
  --input research_topic="SaaS market trends in healthcare 2026" \
  --input depth=4 \
  --input quality_threshold=0.85
```

### Example 3: Competitive Analysis

```bash
chainskills run agent-research.workflow.md \
  --input research_topic="Competitors analysis for product X" \
  --input depth=3
```

## Expected Output

```json
{
  "research_report": {
    "executive_summary": "...",
    "key_findings": [{ "finding": "...", "evidence": "...", "source": "..." }],
    "analysis": "...",
    "recommendations": ["..."],
    "sources": [{ "title": "...", "url": "...", "type": "academic" }]
  },
  "sources": [
    {
      "title": "Research Paper on Quantum Cryptography",
      "url": "https://arxiv.org/...",
      "type": "academic",
      "year": 2025
    }
  ],
  "confidence_score": 0.87
}
```

## Quality Criteria

Reports are scored on:

1. **Accuracy** (40%) — Factual correctness, no hallucinations
2. **Completeness** (30%) — Covers all sub-questions
3. **Clarity** (20%) — Well-structured, readable
4. **Citations** (10%) — Properly sourced claims

## Performance Tips

1. **Depth** — Balance thoroughness vs. time
   - Quick overview: `depth=2`
   - Standard research: `depth=3-4`
   - Deep dive: `depth=5-7`

2. **Parallel Execution** — Maximize by running sub-questions in parallel

3. **Quality Threshold** — Adjust based on use case
   - Internal reports: `0.75`
   - Client deliverables: `0.85`
   - Published content: `0.90+`

## Agent Prompt Optimization

Improve agent prompts for better results:

```markdown
@agent analyst: "Research: $question

Requirements:

- Focus on recent data (2024-2026)
- Prioritize primary sources
- Include quantitative data where available
- Cite all claims

Format response as:
{
'finding': 'summary',
'evidence': ['...'],
'sources': ['...'],
'confidence': 0-1
}" → $finding
```
