# Implementation Plan: Sentinel SOC Operator Plugin

**Branch**: `001-sentinel-soc-plugin` | **Date**: 2026-03-12 | **Spec**: [spec.md](spec.md)
**Input**: Feature specification from `/specs/001-sentinel-soc-plugin/spec.md`

## Summary

Build a Copilot CLI plugin for Microsoft Sentinel SOC operators that
delivers the full core analytic workflow — triage, investigation,
hunting, detection engineering, and reporting — through declarative
Markdown skills, agent personas, lifecycle hooks, and externalized
MCP server configuration. The plugin is entirely declarative (no
runtime code): skills are `.md` files, agents are `.agent.md` files,
data access is through `.mcp.json`, and guardrails are in
`hooks.json`. It ships as a self-contained installable plugin
registered in the repository marketplace.

## Technical Context

**Language/Version**: Markdown (declarative); KQL for all Sentinel
queries. No runtime programming language — skills and agents are
Markdown files interpreted by the Copilot CLI runtime.
**Primary Dependencies**: Copilot CLI plugin system, MCP server
runtime (Sentinel, Log Analytics, Threat Intelligence, Security
Copilot)
**Storage**: N/A — all data is live-queried through MCP servers;
no local persistence
**Testing**: Manual validation against a live Sentinel workspace;
content linting for Markdown structure and plugin.json schema
**Target Platform**: Any OS running Copilot CLI (Windows, macOS,
Linux)
**Project Type**: Copilot CLI plugin (declarative Markdown content
package)
**Performance Goals**: N/A — plugin is declarative content; query
performance depends on underlying MCP servers and Sentinel workspace
**Constraints**: Read-only by default (constitution Principle VI);
no secrets in files; single-tenant Sentinel only (v1)
**Scale/Scope**: 1 plugin, 3 agents, 8 skills, 4 MCP server
configs, 1 hooks file, 1 plugin manifest, 1 marketplace entry

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1
design.*

| # | Principle | Requirement | Status |
|---|-----------|-------------|--------|
| I | Plugin-First Architecture | Plugin is self-contained, independently installable, targets single role (Sentinel SOC Operator), no cross-plugin dependencies | ✅ PASS |
| II | Role-Specialized Design | Purpose-built for Sentinel SOC persona; every skill/agent maps to a real daily SOC task (triage, investigate, hunt, detect, report) | ✅ PASS |
| III | Skills as Atomic Units | 8 skills defined, each self-contained with clear I/O; no inter-skill dependencies; all grounded in MCP tool output | ✅ PASS |
| IV | Agents as Workflow Orchestrators | 3 agents (Triage, Investigation, Hunter) with declared skills, persona scope, workflow guidance, non-overlapping responsibilities | ✅ PASS |
| V | MCP Servers as Data Backbone | All data access via 4 MCP servers in `.mcp.json`; no embedded API calls; auth delegated to MCP layer | ✅ PASS |
| VI | Security & Compliance | No secrets in files; read-only default; KQL safety hooks; MITRE ATT&CK taxonomy for threat classification | ✅ PASS |
| VII | Marketplace-Ready | Valid `plugin.json` manifest; registered in `marketplace.json`; discoverable via `copilot plugin marketplace browse` | ✅ PASS |

**Gate result**: ✅ ALL PASS — proceed to Phase 0.

## Project Structure

### Documentation (this feature)

```text
specs/001-sentinel-soc-plugin/
├── plan.md              # This file
├── research.md          # Phase 0 output
├── data-model.md        # Phase 1 output
├── quickstart.md        # Phase 1 output
├── contracts/           # Phase 1 output
└── tasks.md             # Phase 2 output (/speckit.tasks)
```

### Source Code (repository root)

```text
plugins/sentinel-soc-operator/
├── .github/
│   └── plugin.json              # Plugin manifest
├── agents/
│   ├── triage-analyst.agent.md  # Tier 1 triage workflow
│   ├── investigation-analyst.agent.md  # Tier 2 deep investigation
│   └── threat-hunter.agent.md   # Proactive hunting workflow
├── skills/
│   ├── summarize-incident.md    # Incident summarization
│   ├── enrich-entities.md       # TI entity enrichment
│   ├── generate-kql.md          # NL → KQL translation
│   ├── execute-kql.md           # KQL query execution via MCP
│   ├── extract-iocs.md          # IoC extraction
│   ├── author-detection.md      # Analytics rule authoring
│   ├── map-mitre.md             # MITRE ATT&CK mapping
│   └── generate-report.md       # Shift/SOC reporting
├── hooks.json                   # KQL safety + compliance guardrails
└── .mcp.json                    # Sentinel, Log Analytics, TI, SecCopilot
```

**Structure Decision**: Uses the constitution's Plugin Structure
Convention. A single plugin directory under `plugins/` with
`.github/plugin.json` manifest, `agents/`, `skills/`, and root-level
`hooks.json` and `.mcp.json`. No `src/` or `tests/` — this is a
declarative content plugin with no runtime code.

## Complexity Tracking

> No violations. All constitution gates pass without justification needed.
