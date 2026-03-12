# Tasks: Sentinel SOC Operator Plugin

**Input**: Design documents from `/specs/001-sentinel-soc-plugin/`
**Prerequisites**: plan.md (required), spec.md (required), research.md, data-model.md, contracts/

**Tests**: No tests explicitly requested in spec. This is a declarative Markdown content plugin — validation is manual against a live Sentinel workspace.

**Organization**: Tasks are grouped by user story to enable independent implementation and testing of each story.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies)
- **[Story]**: Which user story this task belongs to (e.g., US1, US2, US3)
- Include exact file paths in descriptions

## Path Conventions

All paths are relative to the plugin root:
`plugins/sentinel-soc-operator/`

---

## Phase 1: Setup (Shared Infrastructure)

**Purpose**: Create plugin directory structure and manifest

- [ ] T001 Create plugin directory structure per plan.md at plugins/sentinel-soc-operator/ with subdirectories .github/, agents/, skills/
- [ ] T002 Create plugin manifest at plugins/sentinel-soc-operator/.github/plugin.json with id, name, version (1.0.0), description, author, and references to all 3 agents, 8 skills, 4 MCP servers, and hooks per contracts/file-formats.md Contract 1
- [ ] T003 [P] Create marketplace entry in marketplace.json at repository root, registering sentinel-soc-operator plugin with id, name, version, description, path, author, category ("security"), and tags per contracts/file-formats.md Contract 6

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: MCP server configuration and safety hooks that ALL user stories depend on

**⚠️ CRITICAL**: No skill or agent work can begin until MCP servers and hooks are configured

- [ ] T004 Create MCP server configuration at plugins/sentinel-soc-operator/.mcp.json with all 4 server definitions (sentinel, loganalytics, threat-intel, security-copilot) including server id, name, type, config with env var references, auth method, and tool definitions per research.md R3 and contracts/file-formats.md Contract 4
- [ ] T005 [P] Create KQL safety hooks at plugins/sentinel-soc-operator/hooks.json with 3-tier guardrail system: block (.purge, | delete, .drop table, .drop function), warn+confirm (.set-or-replace, externaldata(, http_request(, workspace()), and suggest (unbounded sort, join without hint, unbounded time range) per research.md R4 and contracts/file-formats.md Contract 5

**Checkpoint**: Plugin infrastructure ready — skill and agent authoring can begin

---

## Phase 3: User Story 1 — Incident Triage (Priority: P1) 🎯 MVP

**Goal**: A Tier 1 SOC analyst can triage a Sentinel incident in under 5 minutes — retrieve incident, summarize alerts/entities, enrich via TI, extract IoCs, map to MITRE ATT&CK, and produce a triage recommendation

**Independent Test**: Install plugin, point .mcp.json at a Sentinel workspace with open incidents, invoke triage-analyst agent, verify end-to-end triage workflow produces structured recommendation

### Skills for User Story 1

- [ ] T006 [P] [US1] Create summarize-incident skill at plugins/sentinel-soc-operator/skills/summarize-incident.md with Purpose (retrieve and summarize a Sentinel incident and its alerts), When to Use (operator selects an incident for triage), Instructions (step-by-step: list incidents via sentinel_list_incidents, get incident details via sentinel_get_incident, get alerts via sentinel_get_incident_alerts, get entities via sentinel_get_incident_entities, produce structured summary with severity, alert count, entity list, timeline), Expected MCP Tools (sentinel_list_incidents, sentinel_get_incident, sentinel_get_incident_alerts, sentinel_get_incident_entities), Input/Output sections per contracts/file-formats.md Contract 2
- [ ] T007 [P] [US1] Create enrich-entities skill at plugins/sentinel-soc-operator/skills/enrich-entities.md with Purpose (look up IPs, domains, users, and file hashes against threat intelligence), When to Use (entities extracted from incident need TI context), Instructions (step-by-step: for each entity type call appropriate TI tool — ti_lookup_ip for IPs, ti_lookup_domain for domains, ti_lookup_file_hash for hashes, ti_lookup_url for URLs; aggregate results with confidence scores; flag known-malicious indicators), Expected MCP Tools (ti_lookup_ip, ti_lookup_domain, ti_lookup_file_hash, ti_lookup_url), Input/Output sections per contracts/file-formats.md Contract 2
- [ ] T008 [P] [US1] Create extract-iocs skill at plugins/sentinel-soc-operator/skills/extract-iocs.md with Purpose (identify indicators of compromise from incident data or free text), When to Use (during triage to identify actionable indicators from alert details), Instructions (step-by-step: parse incident/alert data for IP addresses via regex, extract domain names, identify file hashes MD5/SHA1/SHA256, extract URLs, deduplicate and categorize by type, output structured IoC list), Expected MCP Tools (none — text processing only), Input/Output sections per contracts/file-formats.md Contract 2
- [ ] T009 [P] [US1] Create map-mitre skill at plugins/sentinel-soc-operator/skills/map-mitre.md with Purpose (classify alerts, incidents, or findings by MITRE ATT&CK tactic and technique), When to Use (after incident summarization or hunting to categorize threat activity), Instructions (step-by-step: Layer 1 — pattern-match alert names against tactic keywords per research.md R2; Layer 2 — query analytics rule metadata via sentinel_get_analytics_rule for authoritative mappings; Layer 3 — apply raw event heuristics for hunting findings; output mapping table with tactic ID, technique ID, technique name, confidence, and source evidence), Expected MCP Tools (sentinel_get_incident_alerts, sentinel_get_analytics_rule), Input/Output sections per contracts/file-formats.md Contract 2. All tactic/technique references MUST use official IDs (e.g., TA0001, T1566.001) per FR-022

### Agent for User Story 1

- [ ] T010 [US1] Create triage-analyst agent at plugins/sentinel-soc-operator/agents/triage-analyst.agent.md with Persona (Tier 1 SOC Triage Analyst — experienced security analyst who performs initial incident assessment), Skills (summarize-incident, enrich-entities, extract-iocs, map-mitre), Workflow (1. Retrieve recent incidents via summarize-incident, 2. Present prioritized incident list, 3. On incident selection: summarize alerts and entities, 4. Extract IoCs via extract-iocs, 5. Enrich entities via enrich-entities, 6. Map to MITRE ATT&CK via map-mitre, 7. Produce triage recommendation with confidence and next action, 8. If escalation: format Tier 2 handoff summary), Scope In (incident triage, initial assessment, entity enrichment, escalation formatting), Scope Out (deep investigation, KQL query authoring, active response/containment, detection rule changes) per contracts/file-formats.md Contract 3 and FR-012/FR-024

**Checkpoint**: Triage workflow is fully functional — install plugin, invoke triage-analyst, complete end-to-end triage. This is the MVP.

---

## Phase 4: User Story 2 — Incident Investigation (Priority: P2)

**Goal**: A Tier 2 analyst can perform deep investigation — generate and execute KQL queries across log sources, build attack timeline, produce investigation report with MITRE mapping

**Independent Test**: Starting from a triaged incident, invoke investigation-analyst agent, verify it generates KQL queries for entity activity, executes them, builds chronological timeline, and produces structured report

### Skills for User Story 2

- [ ] T011 [P] [US2] Create generate-kql skill at plugins/sentinel-soc-operator/skills/generate-kql.md with Purpose (translate natural language investigation questions into syntactically valid KQL queries), When to Use (analyst needs to query Sentinel for entity activity or event patterns), Instructions (step-by-step: identify target entities and time range, determine relevant tables from research.md R1 Tier 1/Tier 2 inventory, validate table availability via loganalytics_list_tables, get schema via loganalytics_get_table_schema, generate KQL query with appropriate filters/projections/time bounds, add inline comments explaining query logic, validate syntax), Expected MCP Tools (loganalytics_list_tables, loganalytics_get_table_schema), Input/Output sections per contracts/file-formats.md Contract 2. Generated queries MUST include TimeGenerated filter and row limits per research.md R4 suggestions
- [ ] T012 [P] [US2] Create execute-kql skill at plugins/sentinel-soc-operator/skills/execute-kql.md with Purpose (run a KQL query against Log Analytics and return structured results), When to Use (after generate-kql produces a query, or analyst provides a manual query), Instructions (step-by-step: validate query against hooks.json safety patterns before execution, execute via loganalytics_execute_query, handle zero-result case with suggestions per edge case spec, handle table-not-found with alternative table suggestions per edge case spec, format results as structured table, summarize row count and notable findings), Expected MCP Tools (loganalytics_execute_query), Input/Output sections per contracts/file-formats.md Contract 2

### Agent for User Story 2

- [ ] T013 [US2] Create investigation-analyst agent at plugins/sentinel-soc-operator/agents/investigation-analyst.agent.md with Persona (Tier 2 Investigation Analyst — senior analyst who performs deep incident investigation and root cause analysis), Skills (generate-kql, execute-kql, map-mitre, enrich-entities), Workflow (1. Accept incident ID or entity set from triage handoff, 2. Generate entity-activity KQL queries via generate-kql for each entity across relevant tables — SigninLogs, SecurityEvent, CommonSecurityLog, AuditLogs, CloudAppEvents, 3. Execute queries via execute-kql, 4. Correlate findings chronologically to build attack timeline, 5. Map timeline events to MITRE ATT&CK via map-mitre, 6. Enrich any newly discovered entities via enrich-entities, 7. Assess scope of compromise — affected users/hosts/data, 8. Produce structured investigation report with findings, timeline, scope, root cause, and remediation recommendations), Scope In (deep investigation, KQL query generation/execution, timeline construction, scope assessment, investigation reporting), Scope Out (initial triage, active response/containment, detection rule creation, shift reporting) per contracts/file-formats.md Contract 3 and FR-013/FR-024

**Checkpoint**: Investigation workflow is fully functional — triage-analyst hands off to investigation-analyst for deep analysis

---

## Phase 5: User Story 3 — Threat Hunting (Priority: P3)

**Goal**: A threat hunter can translate a natural language hypothesis into KQL hunting queries, execute them, analyze results with MITRE mapping, and optionally generate detection rules from confirmed findings

**Independent Test**: Invoke threat-hunter agent with hypothesis (e.g., "lateral movement via RDP"), verify it generates hunting KQL, executes queries, identifies findings, maps to MITRE, and can produce a detection rule template

### Agent for User Story 3

- [ ] T014 [US3] Create threat-hunter agent at plugins/sentinel-soc-operator/agents/threat-hunter.agent.md with Persona (Proactive Threat Hunter — experienced analyst who searches for threats that bypass automated detections), Skills (generate-kql, execute-kql, map-mitre, author-detection), Workflow (1. Accept threat hypothesis in natural language, 2. Decompose hypothesis into searchable patterns and target tables from research.md R1 — prioritize DeviceProcessEvents, DeviceNetworkEvents, SecurityEvent, SigninLogs for hunting, 3. Generate hunting KQL queries via generate-kql with comments explaining detection logic, 4. Execute queries via execute-kql, 5. Analyze results for notable/anomalous findings, 6. Map findings to MITRE ATT&CK via map-mitre, 7. If confirmed findings: recommend follow-up investigation or generate detection rule via author-detection, 8. Document hunt with hypothesis, queries run, findings, and conclusions), Scope In (hypothesis-driven hunting, KQL query crafting, finding analysis, detection rule recommendation), Scope Out (incident triage, deep investigation, active response, shift reporting) per contracts/file-formats.md Contract 3 and FR-014/FR-024

**Checkpoint**: Hunting workflow is functional — hunter can go from hypothesis to findings to detection rule recommendation

---

## Phase 6: User Story 4 — Detection Engineering (Priority: P4)

**Goal**: A detection engineer can author new KQL analytics rules, validate them against historical data, and assess MITRE ATT&CK coverage across all active rules

**Independent Test**: Invoke author-detection skill with a detection requirement, verify it produces valid KQL rule template with MITRE mapping; invoke map-mitre for coverage report across active rules

### Skills for User Story 4

- [ ] T015 [US4] Create author-detection skill at plugins/sentinel-soc-operator/skills/author-detection.md with Purpose (generate KQL analytics rule templates from natural language detection requirements), When to Use (detection engineer wants to create a new Sentinel analytics rule, or hunting findings need to be operationalized), Instructions (step-by-step: parse detection requirement into target behavior and entities, identify relevant tables from research.md R1, generate KQL detection query with appropriate filters and thresholds, assign severity classification based on MITRE tactic, map to MITRE ATT&CK technique IDs per research.md R2, define entity mappings for Sentinel, validate query by executing against historical data via loganalytics_execute_query for last 7 days, report match count and estimated false positive rate, suggest tuning parameters, output complete analytics rule template with query/severity/MITRE/entity mappings/schedule), Expected MCP Tools (loganalytics_execute_query, sentinel_list_analytics_rules), Input/Output sections per contracts/file-formats.md Contract 2

**Checkpoint**: Detection engineering skills are functional — can create, validate, and assess detection coverage

---

## Phase 7: User Story 5 — SOC Reporting (Priority: P5)

**Goal**: A SOC lead or analyst can generate a shift report summarizing incident activity, key findings, and operational metrics for a given time range

**Independent Test**: Invoke generate-report skill with "last 8 hours" time range, verify it queries Sentinel and produces formatted report with counts by severity/status/MITRE tactic

### Skills for User Story 5

- [ ] T016 [US5] Create generate-report skill at plugins/sentinel-soc-operator/skills/generate-report.md with Purpose (query Sentinel operational data and produce formatted shift/SOC reports), When to Use (end of shift, management reporting, handoff documentation), Instructions (step-by-step: accept time range parameter, query incidents via sentinel_list_incidents filtered by time range, query alert volume via loganalytics_execute_query against SecurityIncident and SecurityAlert tables, aggregate by severity/status/MITRE tactic, for each incident include triage decision/escalation status/key entities, compute metrics — total incidents, mean time to triage, incidents by classification, produce formatted Markdown report with summary section, per-incident details, and metrics dashboard), Expected MCP Tools (loganalytics_execute_query, sentinel_list_incidents), Input/Output sections per contracts/file-formats.md Contract 2

**Checkpoint**: Reporting workflow is functional — full SOC lifecycle (triage → investigate → hunt → detect → report) is complete

---

## Phase 8: Polish & Cross-Cutting Concerns

**Purpose**: Final quality validation and documentation

- [ ] T017 Validate all 8 skill files against constitution quality standards — every skill MUST have Purpose, When to Use, Instructions, Expected MCP Tools sections with actionable content and no placeholder/TODO text per FR-023/FR-025
- [ ] T018 [P] Validate all 3 agent files against constitution quality standards — every agent MUST have Persona, Skills, Workflow, Scope In, Scope Out sections with actionable content and no placeholder/TODO text per FR-024/FR-025
- [ ] T019 [P] Validate plugin.json manifest references — all agent paths, skill paths, MCP server configs, and hook paths MUST resolve to existing files per FR-002
- [ ] T020 [P] Validate .mcp.json — all 4 server definitions MUST include id, name, purpose, required env vars, and auth method per constitution Quality Standards
- [ ] T021 [P] Validate hooks.json — all guardrail patterns MUST be valid regex; block/warn/suggest tiers MUST match research.md R4 per FR-021
- [ ] T022 [P] Validate zero secrets — scan all plugin files for credentials, tokens, API keys, connection strings; MUST find zero per FR-019/SC-007
- [ ] T023 [P] Validate MITRE ATT&CK references — all tactic/technique IDs across all skills and agents MUST use official format (TAxxxx, Txxxx.xxx) per FR-022/SC-006
- [ ] T024 Run quickstart.md validation — walk through install and each workflow section to verify documentation accuracy against actual plugin structure

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: No dependencies — start immediately
- **Foundational (Phase 2)**: Depends on Phase 1 (T001 creates directory structure) — BLOCKS all user stories
- **User Story 1 (Phase 3)**: Depends on Phase 2 (MCP config + hooks must exist)
- **User Story 2 (Phase 4)**: Depends on Phase 2; uses skills created in US1 (enrich-entities, map-mitre)
- **User Story 3 (Phase 5)**: Depends on Phase 2; uses skills from US2 (generate-kql, execute-kql) and US4 (author-detection)
- **User Story 4 (Phase 6)**: Depends on Phase 2; no agent dependency but author-detection is used by US3
- **User Story 5 (Phase 7)**: Depends on Phase 2; standalone skill
- **Polish (Phase 8)**: Depends on all user stories being complete

### User Story Dependencies

- **US1 (P1)**: Independent after Foundational — creates 4 skills + triage agent
- **US2 (P2)**: Creates 2 new skills (generate-kql, execute-kql) + investigation agent. Agent reuses US1's enrich-entities and map-mitre skills
- **US3 (P3)**: Creates threat-hunter agent. Reuses US2's generate-kql/execute-kql, US1's map-mitre, and US4's author-detection
- **US4 (P4)**: Creates 1 new skill (author-detection). Can be built independently but US3 agent depends on it
- **US5 (P5)**: Creates 1 new skill (generate-report). Fully independent

### Recommended Execution Order

Build US4 before US3 (author-detection skill is used by threat-hunter agent):

```
Phase 1 → Phase 2 → US1 (Phase 3) → US2 (Phase 4) → US4 (Phase 6) → US3 (Phase 5) → US5 (Phase 7) → Polish (Phase 8)
```

### Within Each User Story

- Skills before agents (agents reference skills)
- Skills marked [P] can be written in parallel within a phase
- Agent MUST be written after all its skills exist

### Parallel Opportunities

- T002 and T003 can run in parallel (different files)
- T004 and T005 can run in parallel (different files)
- T006, T007, T008, T009 can ALL run in parallel (4 independent skill files)
- T011 and T012 can run in parallel (2 independent skill files)
- T017–T023 validation tasks can ALL run in parallel

---

## Parallel Example: User Story 1

```bash
# Launch all 4 triage skills in parallel (different files, no deps):
Task T006: "summarize-incident.md"
Task T007: "enrich-entities.md"
Task T008: "extract-iocs.md"
Task T009: "map-mitre.md"

# Then create the agent (depends on all 4 skills):
Task T010: "triage-analyst.agent.md"
```

---

## Implementation Strategy

### MVP First (User Story 1 Only)

1. Complete Phase 1: Setup (T001–T003)
2. Complete Phase 2: Foundational (T004–T005)
3. Complete Phase 3: User Story 1 — Incident Triage (T006–T010)
4. **STOP and VALIDATE**: Install plugin, invoke triage-analyst agent against live Sentinel workspace
5. Demo/ship triage-only plugin if ready

### Incremental Delivery

1. Setup + Foundational → Plugin infrastructure ready
2. US1 (Triage) → MVP! Test independently → Demo
3. US2 (Investigation) → Test triage-to-investigation handoff → Demo
4. US4 (Detection) → Test rule authoring → Demo
5. US3 (Hunting) → Test hypothesis-to-detection flow → Demo
6. US5 (Reporting) → Test shift report generation → Demo
7. Polish → Validate all quality gates → Ship v1.0.0

### Parallel Team Strategy

With multiple authors:

1. Team completes Setup + Foundational together
2. Once Foundational is done:
   - Author A: US1 skills (T006–T009) → US1 agent (T010)
   - Author B: US2 skills (T011–T012) + US4 skill (T015)
   - Author C: US5 skill (T016)
3. After A + B complete: Author B creates US2 agent (T013), Author A creates US3 agent (T014)
4. Team runs Polish validation together

---

## Notes

- [P] tasks = different files, no dependencies
- [Story] label maps task to specific user story for traceability
- All files are declarative Markdown — no compilation or build step
- Each skill/agent file MUST be complete and actionable (no TODOs)
- Commit after each task or logical group of parallel tasks
- Stop at any checkpoint to validate the story independently
- Refer to contracts/file-formats.md for exact section requirements
- Refer to research.md for KQL table inventory and MITRE mapping approach
