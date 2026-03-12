<!--
  Sync Impact Report
  ===================
  Version change: 0.0.0 (template) → 1.0.0
  Bump rationale: MAJOR — initial ratification of project constitution.

  Modified principles: N/A (initial ratification)

  Added sections:
    - Core Principles (7 principles):
        I. Plugin-First Architecture
        II. Role-Specialized Design
        III. Skills as Atomic Units
        IV. Agents as Workflow Orchestrators
        V. MCP Servers as Data Backbone
        VI. Security and Compliance by Default
        VII. Marketplace-Ready Distribution
    - Technology Choices
    - Plugin Structure Convention
    - Quality Standards
    - Governance (with Amendment Procedure and Compliance Review)

  Removed sections: None

  Templates requiring updates:
    - .specify/templates/plan-template.md ✅ No update needed
      (Constitution Check section dynamically references constitution)
    - .specify/templates/spec-template.md ✅ No update needed
      (No hard-coded constitution references)
    - .specify/templates/tasks-template.md ✅ No update needed
      (Phase structure is generic and compatible)
    - .specify/templates/checklist-template.md ✅ No update needed
      (Template is generic)
    - .specify/templates/agent-file-template.md ✅ No update needed
      (Template is generic)

  Follow-up TODOs: None
-->
# Copilot Azure Plugins Constitution

## Core Principles

### I. Plugin-First Architecture

Every capability is delivered as a self-contained Copilot CLI plugin.
Plugins are the unit of distribution, installation, and versioning.
Each plugin targets a single Azure operator role (e.g., Sentinel SOC
Operator, AKS Operator, Azure Architect). Plugins MUST be installable
independently — no cross-plugin runtime dependencies.

### II. Role-Specialized Design

Each plugin is purpose-built for a specific Azure persona and their
daily workflows. Skills, agents, MCP servers, and hooks are selected
based on real operational tasks — not generic tooling. Every component
MUST answer: "What does this role actually do day-to-day, and how
does this help them do it faster or better?"

### III. Skills as Atomic Units

Skills are the fundamental building blocks. Each skill represents one
discrete capability (e.g., "write a KQL hunting query", "triage an
incident", "extract IoCs"). Skills MUST be:

- Self-contained with clear input/output expectations
- Composable — agents combine multiple skills; skills MUST NOT depend
  on other skills
- Documented with explicit instructions, not vague guidance
- Grounded in real tool output (MCP servers, CLI commands, APIs) —
  not hallucinated knowledge

### IV. Agents as Workflow Orchestrators

Agents represent operator personas (e.g., Tier 1 Triage Analyst,
Threat Hunter). Agents MUST:

- Declare which skills and MCP tools they use
- Define a clear persona with scope boundaries (what they do AND
  what they don't do)
- Be opinionated about workflow order and best practices for their
  role
- Never overlap responsibilities — each agent owns a distinct part
  of the operator workflow

### V. MCP Servers as Data Backbone

All live data access flows through MCP servers. Skills and agents
MUST NOT embed direct API calls, hardcoded endpoints, or credential
handling. MCP server configuration is externalized in `.mcp.json` so
users can point to their own tenants, workspaces, and subscriptions.
Authentication MUST be delegated to the MCP server layer.

### VI. Security and Compliance by Default

This is security tooling — it MUST practice what it preaches:

- No credentials, tokens, or secrets in any plugin file
- Read-only by default; any write/mutate operation MUST be explicitly
  called out
- All Sentinel queries MUST be auditable
- Hooks enforce guardrails (e.g., block destructive KQL, inject
  compliance reminders)
- MITRE ATT&CK framework is the shared taxonomy for threat
  classification

### VII. Marketplace-Ready Distribution

The repository is a Copilot CLI plugin marketplace. All plugins are
discoverable and installable via `copilot plugin marketplace browse`
and `copilot plugin install`. The `marketplace.json` is the single
registry. Every plugin MUST have a valid `plugin.json` manifest with
name, description, version, author, and component paths.

## Technology Choices

- **Plugin format**: Copilot CLI plugin system (`plugin.json` +
  `marketplace.json`)
- **Skills format**: Markdown skill files (`.md`) following Copilot
  CLI conventions
- **Agent format**: Agent markdown files (`.agent.md`) with persona,
  tools, instructions
- **MCP config**: `.mcp.json` with server definitions (Sentinel,
  Security Copilot, Log Analytics, TI)
- **Hooks config**: `hooks.json` for lifecycle event handlers
- **No runtime code in PoC**: Skills and agents are declarative
  markdown; no `extension.mjs` unless custom tooling is required
- **KQL**: Kusto Query Language is the primary query language for
  all Sentinel data access

## Plugin Structure Convention

```text
plugins/<plugin-name>/
├── .github/
│   └── plugin.json          # Plugin manifest (required)
├── agents/                  # Agent persona files
│   └── <name>.agent.md
├── skills/                  # Skill definition files
│   └── <name>.md
├── hooks.json               # Lifecycle hooks (optional)
└── .mcp.json                # MCP server config (optional)
```

## Quality Standards

- Every skill MUST include: purpose, when to use, step-by-step
  instructions, expected MCP tools
- Every agent MUST include: persona description, owned skills list,
  workflow guidance, scope boundaries
- MCP server entries MUST include: server name, purpose, required
  environment variables, auth method
- No placeholder or "TODO" content in shipped skills/agents — every
  file MUST be actionable

## Governance

This constitution governs all plugins in the `copilot-azure-plugins`
marketplace repository. New plugins MUST follow these principles.
Amendments require documentation and review. The constitution
supersedes per-plugin decisions when conflicts arise.

### Amendment Procedure

1. Propose changes via pull request with rationale
2. Changes MUST be reviewed by at least one maintainer
3. Update version according to semantic versioning:
   - MAJOR: Backward-incompatible principle removals or redefinitions
   - MINOR: New principle/section added or materially expanded
   - PATCH: Clarifications, wording, or non-semantic refinements
4. Update `LAST_AMENDED_DATE` on every change

### Compliance Review

All pull requests MUST verify alignment with these principles. The
Constitution Check section in implementation plans MUST gate work
against applicable principles before development begins.

**Version**: 1.0.0 | **Ratified**: 2026-03-12 | **Last Amended**: 2026-03-12
