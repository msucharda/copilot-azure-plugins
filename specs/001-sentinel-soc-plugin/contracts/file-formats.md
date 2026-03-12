# Contracts: Sentinel SOC Operator Plugin

**Branch**: `001-sentinel-soc-plugin`
**Date**: 2026-03-12

## Overview

This plugin is a declarative Markdown content package — it has no
runtime APIs, libraries, or programmatic interfaces. The "contracts"
for this project are the **file format specifications** that define
how each component must be structured so the Copilot CLI runtime
can discover and execute them.

## Contract 1: Plugin Manifest (`plugin.json`)

The plugin manifest is the entry point. The Copilot CLI reads this
file to discover all components.

```json
{
  "id": "<string, required>",
  "name": "<string, required>",
  "version": "<semver, required>",
  "description": "<string, required>",
  "author": "<string, required>",
  "license": "<string, optional>",
  "repository": "<url, optional>",
  "keywords": ["<string>"],
  "agents": [
    {
      "id": "<string>",
      "path": "<relative path to .agent.md>",
      "displayName": "<string>",
      "description": "<string>"
    }
  ],
  "skills": [
    {
      "id": "<string>",
      "path": "<relative path to .md>",
      "displayName": "<string>",
      "description": "<string>",
      "tags": ["<string>"]
    }
  ],
  "mcpServers": [
    {
      "id": "<string>",
      "name": "<string>",
      "configPath": "<relative path to .mcp.json>",
      "requiredEnv": ["<env var name>"]
    }
  ],
  "hooks": [
    {
      "id": "<string>",
      "path": "<relative path to hooks.json>"
    }
  ]
}
```

## Contract 2: Skill File Format (`.md`)

Each skill is a Markdown file with required sections. The Copilot
CLI parses these sections to understand skill capabilities.

```markdown
# <Skill Display Name>

## Purpose
<One paragraph: what this skill does>

## When to Use
<Bullet list: trigger conditions for invoking this skill>

## Instructions
<Numbered steps: exactly what the skill does, in order>
<Each step references specific MCP tools by name>

## Expected MCP Tools
<Bullet list: MCP tool names this skill requires>
- `<server_id>.<tool_name>` — <what it provides>

## Input
<What the skill expects to receive>

## Output
<What the skill produces — format and structure>
```

## Contract 3: Agent File Format (`.agent.md`)

Each agent is a Markdown file defining a workflow persona.

```markdown
# <Agent Display Name>

## Persona
<Paragraph: who this agent represents, their role, experience level>

## Skills
<Bullet list: skill IDs this agent orchestrates>
- `<skill-id>` — <when/why it's used in this agent's workflow>

## MCP Tools
<Bullet list: direct MCP tools beyond skill dependencies>

## Workflow
<Numbered steps: the opinionated workflow order>
<References skills by ID at each step>

## Scope — What This Agent Does
<Bullet list: responsibilities>

## Scope — What This Agent Does NOT Do
<Bullet list: explicit exclusions and handoff points>
```

## Contract 4: MCP Configuration (`.mcp.json`)

MCP server definitions for data access.

```json
{
  "servers": [
    {
      "id": "<string>",
      "name": "<string>",
      "type": "<string>",
      "config": {
        "<key>": "<value or env var reference>"
      },
      "auth": {
        "method": "<string>",
        "envVars": ["<env var name>"]
      },
      "tools": [
        {
          "name": "<tool_name>",
          "description": "<what it does>",
          "parameters": {}
        }
      ]
    }
  ]
}
```

## Contract 5: Hooks Configuration (`hooks.json`)

Lifecycle event handlers for guardrails.

```json
{
  "hooks": [
    {
      "id": "<string>",
      "trigger": "before-skill-execution | after-skill-execution",
      "action": "block | warn | suggest",
      "pattern": "<regex pattern to match>",
      "message": "<user-facing message>",
      "confirm": "<boolean, for warn action>"
    }
  ]
}
```

## Contract 6: Marketplace Registry (`marketplace.json`)

The repository-level registry for plugin discovery. Located at
repository root.

```json
{
  "plugins": [
    {
      "id": "<string>",
      "name": "<string>",
      "version": "<semver>",
      "description": "<string>",
      "path": "<relative path to plugin directory>",
      "author": "<string>",
      "category": "<string>",
      "tags": ["<string>"]
    }
  ]
}
```
