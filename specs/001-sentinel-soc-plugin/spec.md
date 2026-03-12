# Feature Specification: Sentinel SOC Operator Plugin

**Feature Branch**: `001-sentinel-soc-plugin`
**Created**: 2026-03-12
**Status**: Draft
**Input**: User description: "Create a Copilot CLI plugin for Microsoft Sentinel SOC operators with skills and agents covering the full security operations workflow — triage, investigation, hunting, detection engineering, and reporting — backed by MCP servers for Sentinel, Security Copilot, Log Analytics, and Threat Intelligence."

## User Scenarios & Testing *(mandatory)*

### User Story 1 — Incident Triage (Priority: P1)

A Tier 1 SOC analyst receives a new Sentinel incident notification
and needs to quickly assess severity, gather context, and make a
triage decision (escalate, close as false positive, or investigate
further). Today this requires manually opening multiple Sentinel
blades, running ad-hoc KQL queries, and cross-referencing threat
intelligence — a process that takes 15–30 minutes per incident. The
plugin provides a triage agent and supporting skills that walk the
analyst through a structured triage workflow directly in the terminal.

**Why this priority**: Incident triage is the single highest-volume
SOC task. Every Sentinel SOC operator triages incidents daily. Faster
triage directly reduces mean-time-to-respond (MTTR) and is the
foundation all other workflows build upon.

**Independent Test**: Install the plugin, point `.mcp.json` at a
Sentinel workspace with existing incidents, and invoke the triage
agent. Verify it retrieves an incident, summarizes alerts and
entities, enriches with threat intelligence, and produces a triage
recommendation — all without leaving the terminal.

**Acceptance Scenarios**:

1. **Given** a Sentinel workspace with open incidents, **When** the
   operator invokes the triage agent, **Then** the agent retrieves
   the most recent incidents and presents a prioritized summary
   including severity, alert count, and affected entities.
2. **Given** a selected incident, **When** the operator asks to
   triage it, **Then** the agent runs entity enrichment (IP, domain,
   user, file hash) against threat intelligence, correlates related
   alerts, and produces a structured triage recommendation with
   confidence level and suggested next action.
3. **Given** a triaged incident, **When** the operator decides to
   escalate, **Then** the agent produces a formatted escalation
   summary suitable for a Tier 2 handoff, including timeline,
   affected entities, MITRE ATT&CK tactics, and enrichment results.

---

### User Story 2 — Incident Investigation (Priority: P2)

A Tier 2 analyst receives an escalated incident and needs to
perform a deep investigation — correlating events across multiple
log sources, building an attack timeline, identifying scope of
compromise, and documenting findings. The plugin provides an
investigation agent that guides the analyst through a structured
investigation workflow, generating and executing KQL queries against
Log Analytics to trace attacker activity.

**Why this priority**: Investigation is the natural follow-on from
triage and represents the core analytical work of a SOC. Without
investigation capabilities, the plugin only covers the intake step.

**Independent Test**: Starting from a triaged incident, invoke the
investigation agent. Verify it generates targeted KQL queries for
entity activity, correlates findings across log sources, builds an
attack timeline, and summarizes the scope of impact.

**Acceptance Scenarios**:

1. **Given** an escalated incident with known entities (IPs, users,
   hosts), **When** the operator invokes the investigation agent,
   **Then** it generates and runs KQL queries to retrieve all
   related activity for those entities across relevant log tables
   (SigninLogs, SecurityEvent, CommonSecurityLog, etc.).
2. **Given** investigation query results, **When** the operator asks
   for a timeline, **Then** the agent constructs a chronological
   attack narrative mapping events to MITRE ATT&CK techniques.
3. **Given** a completed investigation, **When** the operator
   requests a summary, **Then** the agent produces a structured
   investigation report with findings, affected scope, root cause
   analysis, and recommended remediation actions.

---

### User Story 3 — Threat Hunting (Priority: P3)

A threat hunter wants to proactively search for signs of compromise
that existing detection rules may have missed. They have a
hypothesis (e.g., "lateral movement via RDP from a compromised
host") and need help translating it into effective KQL hunting
queries, executing them, and interpreting results. The plugin
provides a hunting agent and KQL-generation skills that accelerate
hypothesis-driven hunting.

**Why this priority**: Proactive hunting finds threats that bypass
automated detections. It is a distinct workflow from reactive triage
and exercises the KQL generation and threat intelligence skills in a
different operational context.

**Independent Test**: Invoke the hunting agent with a threat
hypothesis. Verify it generates appropriate KQL hunting queries,
executes them against the workspace, and summarizes findings with
MITRE ATT&CK mapping.

**Acceptance Scenarios**:

1. **Given** a threat hypothesis described in natural language,
   **When** the operator invokes the hunting agent, **Then** it
   generates one or more KQL hunting queries targeting relevant
   Sentinel tables, with comments explaining the detection logic.
2. **Given** hunting query results with matches, **When** the
   operator asks for analysis, **Then** the agent identifies
   notable findings, maps them to MITRE ATT&CK techniques, and
   recommends follow-up investigation or new detection rules.
3. **Given** a completed hunt with confirmed findings, **When** the
   operator requests a detection rule, **Then** the agent produces
   a KQL analytics rule template suitable for import into Sentinel.

---

### User Story 4 — Detection Engineering (Priority: P4)

A detection engineer needs to create, review, or tune Sentinel
analytics rules. They want help writing KQL detection logic,
validating it against historical data, and ensuring coverage maps to
the MITRE ATT&CK framework. The plugin provides skills for
detection rule authoring, validation, and gap analysis.

**Why this priority**: Detection engineering ensures the SOC's
automated coverage improves over time. It naturally follows hunting
(hunt findings become detection rules) and is a distinct persona
workflow.

**Independent Test**: Invoke the detection engineering skills to
create a new analytics rule. Verify it produces valid KQL logic,
runs a validation query against historical data, and maps the
detection to MITRE ATT&CK technique IDs.

**Acceptance Scenarios**:

1. **Given** a detection requirement described in natural language,
   **When** the operator invokes the detection authoring skill,
   **Then** it produces a KQL analytics rule with query logic,
   severity classification, MITRE ATT&CK mapping, and entity
   mappings.
2. **Given** an existing analytics rule, **When** the operator asks
   to validate it, **Then** the skill executes the rule query
   against historical data (e.g., last 7 days) and reports match
   count, false positive rate estimate, and suggested tuning.
3. **Given** the operator asks for a MITRE ATT&CK coverage report,
   **Then** the skill queries all active analytics rules and
   produces a matrix showing covered vs. uncovered techniques.

---

### User Story 5 — SOC Reporting (Priority: P5)

A SOC team lead or analyst at end-of-shift needs to generate a
summary of security operations activity — incidents handled, key
findings, open items, and metrics. The plugin provides a reporting
skill that queries Sentinel for operational data and produces
structured reports.

**Why this priority**: Reporting is essential for SOC governance and
handoffs but is the least time-sensitive workflow. It rounds out the
full operational lifecycle without blocking higher-priority work.

**Independent Test**: Invoke the reporting skill with a time range.
Verify it retrieves incident and alert data from Sentinel and
produces a formatted shift report with key metrics.

**Acceptance Scenarios**:

1. **Given** a specified time range (e.g., "last 8 hours"), **When**
   the operator invokes the shift report skill, **Then** it queries
   Sentinel for all incidents and alerts in that window and produces
   a summary with counts by severity, status, and MITRE tactic.
2. **Given** a generated report, **When** the operator requests
   detailed findings, **Then** the report includes per-incident
   summaries with triage decisions, escalation status, and key
   entities involved.

---

### Edge Cases

- What happens when the MCP server connection to Sentinel fails or
  credentials are expired? The plugin MUST surface a clear error
  message identifying which MCP server failed and what the operator
  should check (e.g., environment variables, token expiry).
- What happens when a KQL query returns zero results? Skills MUST
  report "no results found" with suggestions (broaden time range,
  check table availability, verify data connector status).
- What happens when an incident has no associated entities? The
  triage agent MUST still produce a triage summary using available
  alert metadata and note that entity enrichment was not possible.
- What happens when threat intelligence lookups return no matches?
  Skills MUST clearly state "no TI matches found" rather than
  silently omitting enrichment, so the operator knows the check
  was performed.
- What happens when a generated KQL query targets a log table that
  does not exist in the workspace? Skills MUST validate table
  availability before execution and suggest alternative tables or
  data connectors if the expected table is missing.

## Requirements *(mandatory)*

### Functional Requirements

**Plugin Structure**

- **FR-001**: The plugin MUST be a self-contained Copilot CLI plugin
  installable via `copilot plugin install` with no dependencies on
  other plugins.
- **FR-002**: The plugin MUST include a valid `plugin.json` manifest
  with name, description, version, author, and paths to all agents,
  skills, hooks, and MCP configuration.
- **FR-003**: The plugin MUST be registered in the repository's
  `marketplace.json` for discoverability.

**Skills**

- **FR-004**: The plugin MUST provide a skill for incident
  summarization — retrieving an incident and its alerts from
  Sentinel and producing a structured summary.
- **FR-005**: The plugin MUST provide a skill for entity enrichment
  — looking up IPs, domains, users, and file hashes against threat
  intelligence sources.
- **FR-006**: The plugin MUST provide a skill for KQL query
  generation — translating natural language descriptions into
  syntactically valid KQL queries targeting appropriate Sentinel
  tables.
- **FR-007**: The plugin MUST provide a skill for KQL query
  execution — running a KQL query against Log Analytics via MCP
  and returning structured results.
- **FR-008**: The plugin MUST provide a skill for IoC extraction —
  identifying indicators of compromise (IPs, domains, hashes, URLs)
  from incident data or free text.
- **FR-009**: The plugin MUST provide a skill for detection rule
  authoring — generating KQL analytics rule templates from natural
  language detection requirements.
- **FR-010**: The plugin MUST provide a skill for MITRE ATT&CK
  mapping — classifying alerts, incidents, or hunting findings by
  tactic and technique.
- **FR-011**: The plugin MUST provide a skill for shift report
  generation — querying Sentinel operational data and producing a
  formatted summary for a given time range.

**Agents**

- **FR-012**: The plugin MUST provide a Triage Analyst agent that
  orchestrates incident summarization, entity enrichment, IoC
  extraction, and MITRE mapping into a guided triage workflow.
- **FR-013**: The plugin MUST provide an Investigation Analyst agent
  that orchestrates KQL query generation, execution, and timeline
  construction into a guided investigation workflow.
- **FR-014**: The plugin MUST provide a Threat Hunter agent that
  orchestrates hypothesis-driven KQL generation, execution,
  analysis, and detection rule recommendations.

**MCP Server Configuration**

- **FR-015**: The plugin MUST include `.mcp.json` configuration for
  a Microsoft Sentinel MCP server (incident and analytics rule
  access).
- **FR-016**: The plugin MUST include `.mcp.json` configuration for
  a Log Analytics MCP server (KQL query execution).
- **FR-017**: The plugin MUST include `.mcp.json` configuration for
  a Threat Intelligence MCP server (IoC lookups and enrichment).
- **FR-018**: The plugin MUST include `.mcp.json` configuration for
  a Security Copilot MCP server (AI-assisted analysis).

**Security & Guardrails**

- **FR-019**: The plugin MUST NOT contain any credentials, tokens,
  API keys, or secrets in any file. All authentication MUST be
  delegated to MCP server configuration.
- **FR-020**: All skills and agents MUST be read-only by default.
  Any skill that modifies Sentinel state (e.g., closing an incident,
  creating a rule) MUST explicitly declare this in its instructions
  and require operator confirmation.
- **FR-021**: The plugin MUST include hooks that enforce KQL safety
  guardrails — blocking or warning on destructive queries (e.g.,
  `.purge`, bulk deletions).
- **FR-022**: All MITRE ATT&CK references MUST use official tactic
  and technique IDs (e.g., TA0001, T1566.001).

**Quality**

- **FR-023**: Every skill file MUST include: purpose, when to use,
  step-by-step instructions, and expected MCP tools.
- **FR-024**: Every agent file MUST include: persona description,
  owned skills list, workflow guidance, and scope boundaries
  (what the agent does and does NOT do).
- **FR-025**: No skill or agent file MUST contain placeholder or
  TODO content — every file MUST be actionable on installation.

### Key Entities

- **Plugin**: The top-level distributable unit. Contains a manifest
  (`plugin.json`), one or more agents, multiple skills, MCP
  configuration, and optional hooks. Identified by name and version.
- **Skill**: An atomic capability file (Markdown). Represents one
  discrete SOC task (e.g., "summarize incident", "generate KQL
  query"). Has a purpose, trigger conditions, step-by-step
  instructions, and declares which MCP tools it requires.
- **Agent**: A workflow orchestrator file (Markdown). Represents an
  operator persona (e.g., Triage Analyst, Threat Hunter). Declares
  which skills it uses, defines scope boundaries, and provides
  opinionated workflow guidance.
- **MCP Server**: An external data access endpoint configured in
  `.mcp.json`. Provides live access to Sentinel, Log Analytics,
  Threat Intelligence, or Security Copilot. Defines connection
  parameters, required environment variables, and auth method.
- **Hook**: A lifecycle event handler defined in `hooks.json`.
  Enforces guardrails (e.g., KQL safety checks, compliance
  reminders) that trigger before or after skill execution.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: A SOC analyst can complete initial incident triage
  (from alert notification to triage decision) in under 5 minutes
  using the triage agent, compared to the current 15–30 minute
  manual process.
- **SC-002**: The plugin covers all five core SOC workflows (triage,
  investigation, hunting, detection engineering, reporting) with at
  least one dedicated agent or skill per workflow.
- **SC-003**: 100% of skills produce actionable output grounded in
  live Sentinel/Log Analytics data — no skill relies on static or
  hallucinated information.
- **SC-004**: The plugin installs successfully via
  `copilot plugin install` with zero additional setup beyond
  configuring MCP server environment variables.
- **SC-005**: All generated KQL queries are syntactically valid and
  target tables that exist in a standard Sentinel workspace with
  common data connectors enabled.
- **SC-006**: Every MITRE ATT&CK mapping uses official tactic/
  technique IDs and is traceable to the referenced alert or event
  data.
- **SC-007**: Zero credentials, tokens, or secrets exist in any
  plugin file — verified by automated scanning of all plugin
  contents.
- **SC-008**: The plugin passes all constitution quality standards:
  every skill has purpose/instructions/MCP tools, every agent has
  persona/skills/scope, every MCP entry has name/purpose/env vars.

## Assumptions

- The target user has an active Microsoft Sentinel workspace with at
  least one data connector enabled (e.g., Azure AD Sign-in Logs,
  SecurityEvent, CommonSecurityLog).
- MCP servers for Sentinel, Log Analytics, Security Copilot, and
  Threat Intelligence are available and accessible when the plugin
  is used. The plugin documents required environment variables but
  does not provision or manage these services.
- The Copilot CLI plugin system supports the `plugin.json` manifest
  format, `.agent.md` agent files, `.md` skill files, `.mcp.json`
  configuration, and `hooks.json` lifecycle hooks as described in
  the project constitution.
- Detection engineering skills generate analytics rule templates but
  do not directly deploy rules to Sentinel — deployment is a manual
  operator action or handled by a separate CI/CD process.
- The initial plugin targets a single-tenant Sentinel deployment.
  Multi-tenant/Lighthouse scenarios are out of scope for this
  version.
