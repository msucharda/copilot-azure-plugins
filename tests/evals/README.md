# Plugin Evals

Two-layer evaluation system for plugin quality.

## Layer 1: Deterministic Content Assertions (CI)

Fast grep-based checks that run on every PR. Each assertion encodes a lesson from a real deployment failure.

```bash
# Run locally
bash tests/evals/run-evals.sh
```

### Adding new assertions

When you discover a deployment bug, add one line to the relevant `*-evals.sh` file:

```bash
# Pattern: assert_contains "plugin-name" "file-pattern" "required-pattern" "reason"
assert_contains "sovereign-landing-zone" "skills/new-skill/SKILL.md" \
  "critical-thing" "Session XYZ: deployment failed because this was missing"

# Pattern: assert_not_contains "plugin-name" "file-pattern" "forbidden-pattern" "reason"
assert_not_contains "sovereign-landing-zone" "skills/scaffold-landing-zone/SKILL.md" \
  "wrong-value" "Session XYZ: this value caused a deployment failure"
```

### Files

| File | Plugin | Assertions |
|------|--------|------------|
| `slz-evals.sh` | sovereign-landing-zone | ~30 (MG IDs, policies, modules, tfvars, bootstrap) |
| `ghe-evals.sh` | github-enterprise-setup | ~20 (OIDC, SCIM, billing, EMU, URLs) |

## Layer 2: LLM-Judged Scenario Evals (local, manual)

Pre-written scenarios that test agent behavior. Run in Copilot CLI — uses the session's LLM, no API keys needed.

### How to run

1. Open Copilot CLI in this repo
2. Load the relevant plugin agent
3. Copy the `prompt:` from a scenario YAML file and send it to the agent
4. Check the response against the `assertions:` (must_contain / must_not_contain)
5. Grade against the `rubric:` criteria

### Scenario files

| File | Agent | Tests |
|------|-------|-------|
| `scenarios/slz-basic-design.yaml` | slz-landing-zone-architect | MG hierarchy, policies, AVM modules, networking |
| `scenarios/ghe-entra-oidc-setup.yaml` | ghe-setup-operator | OIDC flow, 2FA, SCIM, billing, EMU limits |
| `scenarios/slz-ghe-bootstrap.yaml` | slz-bootstrap-operator | GHE.com domain, PATs, action access, bootstrap |

### Scenario format

```yaml
name: scenario-name
agent: agent-to-test
prompt: |
  The user message to send to the agent
rubric:
  - id: criterion-name
    weight: 1-3
    check: "What to look for in the response"
assertions:
  must_contain: ["required", "patterns"]
  must_not_contain: ["forbidden", "patterns"]
```

### Adding new scenarios

After finding issues during real deployments:
1. Create a new YAML file in `scenarios/`
2. Write the prompt that would have triggered the bug
3. Add assertions for the correct behavior
4. Add rubric criteria for grading
