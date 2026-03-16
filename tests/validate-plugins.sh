#!/usr/bin/env bash
set -euo pipefail

# Plugin Structure Validator
# Validates all plugins in the repository for structural correctness.
# Exit code 0 = all checks pass, non-zero = failures found.

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
PLUGINS_DIR="$REPO_ROOT/plugins"
MARKETPLACE="$REPO_ROOT/.github/plugin/marketplace.json"
ERRORS=0

fail() { echo "  ❌ $1"; ERRORS=$((ERRORS + 1)); }
pass() { echo "  ✅ $1"; }
info() { echo "  ℹ️  $1"; }

echo "=== Plugin Structure Validation ==="
echo ""

# --- Marketplace validation ---
echo "📋 Checking marketplace.json..."
if [ ! -f "$MARKETPLACE" ]; then
  fail "marketplace.json not found at $MARKETPLACE"
else
  if ! python3 -c "import json; json.load(open('$MARKETPLACE'))" 2>/dev/null; then
    fail "marketplace.json is not valid JSON"
  else
    pass "marketplace.json is valid JSON"
  fi
fi

# --- Per-plugin validation ---
for plugin_dir in "$PLUGINS_DIR"/*/; do
  plugin_name=$(basename "$plugin_dir")
  echo ""
  echo "🔌 Plugin: $plugin_name"

  # Check plugin.json exists and is valid
  pjson="$plugin_dir/.github/plugin/plugin.json"
  if [ ! -f "$pjson" ]; then
    fail "plugin.json not found at $pjson"
    continue
  fi

  if ! python3 -c "import json; json.load(open('$pjson'))" 2>/dev/null; then
    fail "plugin.json is not valid JSON"
    continue
  fi
  pass "plugin.json is valid JSON"

  # Check required fields
  for field in name version description; do
    val=$(python3 -c "import json; d=json.load(open('$pjson')); print(d.get('$field',''))")
    if [ -z "$val" ]; then
      fail "plugin.json missing required field: $field"
    fi
  done

  plugin_version=$(python3 -c "import json; print(json.load(open('$pjson')).get('version',''))")
  pass "plugin.json version: $plugin_version"

  # Check marketplace.json version matches
  if [ -f "$MARKETPLACE" ]; then
    mp_version=$(python3 -c "
import json
m=json.load(open('$MARKETPLACE'))
for p in m.get('plugins',[]):
    if p['name']=='$plugin_name': print(p.get('version','')); break
else: print('')
")
    if [ -n "$mp_version" ] && [ "$mp_version" != "$plugin_version" ]; then
      fail "marketplace.json version ($mp_version) != plugin.json version ($plugin_version)"
    elif [ -z "$mp_version" ]; then
      fail "Plugin '$plugin_name' not found in marketplace.json"
    else
      pass "marketplace.json version matches ($mp_version)"
    fi
  fi

  # Check skill paths exist
  echo "  📝 Checking skills..."
  skill_paths=$(python3 -c "
import json
d=json.load(open('$pjson'))
skills=d.get('skills',[])
for s in skills:
    if isinstance(s, str): print(s)
    elif isinstance(s, dict): print(s.get('path', s.get('source','')))
")
  skill_count=0
  for skill_path in $skill_paths; do
    skill_count=$((skill_count + 1))
    # Resolve relative path
    resolved="$plugin_dir/$skill_path"
    if [ ! -d "$resolved" ]; then
      fail "Skill directory not found: $skill_path"
      continue
    fi
    skill_md="$resolved/SKILL.md"
    if [ ! -f "$skill_md" ]; then
      fail "SKILL.md not found in $skill_path"
      continue
    fi
    # Check YAML frontmatter
    if ! head -1 "$skill_md" | grep -q '^---$'; then
      fail "SKILL.md missing YAML frontmatter: $skill_path"
      continue
    fi
    # Check required frontmatter fields
    fm_name=$(sed -n '/^---$/,/^---$/p' "$skill_md" | grep '^name:' | head -1 | sed 's/name: *//' | tr -d "'\"")
    fm_desc=$(sed -n '/^---$/,/^---$/p' "$skill_md" | grep '^description:' | head -1)
    if [ -z "$fm_name" ]; then
      fail "SKILL.md missing 'name' in frontmatter: $skill_path"
    fi
    if [ -z "$fm_desc" ]; then
      fail "SKILL.md missing 'description' in frontmatter: $skill_path"
    fi
    # Check required sections
    for section in "## Purpose" "## Input" "## Output"; do
      if ! grep -q "^$section" "$skill_md"; then
        fail "SKILL.md missing '$section' section: $skill_path"
      fi
    done
  done
  pass "$skill_count skills validated"

  # Check agents
  echo "  🤖 Checking agents..."
  agents_dir="$plugin_dir/agents"
  if [ ! -d "$agents_dir" ]; then
    fail "agents/ directory not found"
  else
    agent_count=0
    for agent_md in "$agents_dir"/*.md; do
      [ -f "$agent_md" ] || continue
      agent_count=$((agent_count + 1))
      agent_file=$(basename "$agent_md")
      # Check YAML frontmatter
      if ! head -1 "$agent_md" | grep -q '^---$'; then
        fail "Agent missing YAML frontmatter: $agent_file"
        continue
      fi
      # Check required fields
      fm_name=$(sed -n '/^---$/,/^---$/p' "$agent_md" | grep '^name:' | head -1 | sed 's/name: *//' | tr -d "'\"")
      fm_tools=$(sed -n '/^---$/,/^---$/p' "$agent_md" | grep -c '  - ')
      if [ -z "$fm_name" ]; then
        fail "Agent missing 'name' in frontmatter: $agent_file"
      fi
      # Check naming convention (should have a prefix)
      if ! echo "$fm_name" | grep -qE '^(arc|slz|ghe)-'; then
        fail "Agent name '$fm_name' missing prefix (expected arc-/slz-/ghe-): $agent_file"
      fi
      if [ "$fm_tools" -eq 0 ]; then
        fail "Agent has no tools declared: $agent_file"
      fi
    done
    pass "$agent_count agents validated"
  fi

  # Check hooks
  if [ -f "$plugin_dir/hooks.json" ]; then
    if ! python3 -c "import json; json.load(open('$plugin_dir/hooks.json'))" 2>/dev/null; then
      fail "hooks.json is not valid JSON"
    else
      pass "hooks.json is valid JSON"
    fi
    # Check referenced hook scripts exist and are executable
    hook_scripts=$(python3 -c "
import json
h=json.load(open('$plugin_dir/hooks.json'))
for hook_list in h.get('hooks',{}).values():
    if isinstance(hook_list, list):
        for hook in hook_list:
            if 'bash' in hook: print(hook['bash'])
    elif isinstance(hook_list, dict):
        for hook in hook_list.values():
            if isinstance(hook, dict) and 'bash' in hook: print(hook['bash'])
" 2>/dev/null)
    for script in $hook_scripts; do
      resolved="$plugin_dir/$script"
      if [ ! -f "$resolved" ]; then
        fail "Hook script not found: $script"
      elif [ ! -x "$resolved" ]; then
        fail "Hook script not executable: $script"
      else
        # Validate bash syntax
        if bash -n "$resolved" 2>/dev/null; then
          pass "Hook script valid: $script"
        else
          fail "Hook script has syntax errors: $script"
        fi
      fi
    done
  fi

  # Check .mcp.json
  if [ -f "$plugin_dir/.mcp.json" ]; then
    if ! python3 -c "import json; json.load(open('$plugin_dir/.mcp.json'))" 2>/dev/null; then
      fail ".mcp.json is not valid JSON"
    else
      pass ".mcp.json is valid JSON"
    fi
  fi
done

echo ""
echo "=== Results ==="
if [ $ERRORS -eq 0 ]; then
  echo "✅ All checks passed!"
  exit 0
else
  echo "❌ $ERRORS check(s) failed"
  exit 1
fi
