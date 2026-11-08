#!/bin/bash
# Install BDD skills into a project's .claude/ directory.
#
# Usage:
#   # Remote install (no clone needed):
#   curl -sL https://raw.githubusercontent.com/godrose/bdd-skills/main/install.sh | bash -s -- [target-dir]
#
#   # From a local clone:
#   ./install.sh [target-dir]
#
# What it does:
#   1. If no local source, clones godrose/bdd-skills to a temp dir
#   2. Copies plugin/commands/ and plugin/agents/ into .claude/ with a source header and project names (bdd-design),
#      plus scripts/ and schemas/ for the decision log, and puts back the pre-approved tools
#      the plugin does not carry
#   3. Copies plugin/bdd-config.template.md as .claude/bdd-config.md (if not exists)
#   4. Prints next steps

set -e

REPO_URL="https://github.com/godrose/bdd-skills"
REPO_BRANCH="main"

# Determine source directory
if [ -n "${BASH_SOURCE[0]}" ] && [ -f "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/plugin/commands/design.md" ]; then
  # Running from a local clone
  SOURCE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
  CLEANUP=""
else
  # Running via curl pipe - clone to temp dir
  SOURCE_DIR="$(mktemp -d)"
  CLEANUP="$SOURCE_DIR"
  echo "Cloning $REPO_URL ($REPO_BRANCH)..."
  if ! clone_out=$(git clone --depth 1 --branch "$REPO_BRANCH" "$REPO_URL" "$SOURCE_DIR" 2>&1); then
    echo "$clone_out" >&2
    echo "install.sh: could not clone $REPO_URL. Check your network and your git access to the repository." >&2
    rm -rf "$CLEANUP"
    exit 1
  fi
  echo "$clone_out" | grep -v "^$" || true
fi

# The plugin files live in plugin/. A source without that folder cannot be installed.
PLUGIN_DIR="$SOURCE_DIR/plugin"
SCRIPTS_DIR="$SOURCE_DIR/scripts"
SCHEMAS_DIR="$SOURCE_DIR/schemas"
if [ ! -f "$PLUGIN_DIR/commands/design.md" ]; then
  echo "install.sh: no plugin/ folder in $SOURCE_DIR. Use a current copy of the repo." >&2
  [ -n "$CLEANUP" ] && rm -rf "$CLEANUP"
  exit 1
fi

TARGET="${1:-.}"
CLAUDE_DIR="$TARGET/.claude"
mkdir -p "$CLAUDE_DIR/commands" "$CLAUDE_DIR/agents" "$CLAUDE_DIR/scripts" "$CLAUDE_DIR/schemas"

# Resolve version from git
VERSION=""
if [ -d "$SOURCE_DIR/.git" ]; then
  VERSION=$(cd "$SOURCE_DIR" && git describe --tags --always 2>/dev/null || git rev-parse --short HEAD 2>/dev/null || echo "unknown")
fi
INSTALLED_AT=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

# The source tree holds plugin text (bdd:design, ${CLAUDE_PLUGIN_ROOT}). A project install uses
# prefixed file names and .claude/ paths, so convert the text back.
to_project() {
  sed -E '/^> Plugin note:/{N;d;}; s#"\$\{CLAUDE_PLUGIN_ROOT\}"/scripts/decisions\.sh#.claude/scripts/decisions.sh#g; s/bdd:(discover|design|implement|run|triage|reconcile|verifier)/bdd-\1/g; s/^name: verifier(\r?)$/name: bdd-verifier\1/'
}

# The plugin carries no pre-approved tools, because the directory refuses them. A project install is not scanned,
# so each command gets back the list it had up to 0.5.0.
tools_for() {
  case "$1" in
    discover|design) echo '["Agent", "Bash", "Read", "Grep", "Glob", "AskUserQuestion"]' ;;
    implement) echo '["Agent", "Bash", "Read", "Write", "Edit", "Grep", "Glob"]' ;;
    run) echo '["Agent", "Bash", "Read", "Write", "Grep", "Glob", "AskUserQuestion"]' ;;
    triage) echo '["Agent", "Bash", "Read", "Edit", "Write", "Grep", "Glob", "AskUserQuestion"]' ;;
    reconcile) echo '["Bash", "Read", "Grep", "Glob"]' ;;
    *) echo "" ;;
  esac
}

# Inject source header into a skill file and write to destination
install_skill() {
  local src="$1"
  local dst="$2"
  local body
  body=$(mktemp)
  local tools
  tools=$(tools_for "$(basename "$dst" .md | sed "s/^bdd-//")")
  to_project < "$src" | awk -v t="$tools" '{print} t != "" && !d && /^description:/ {cr = ($0 ~ /\r$/) ? "\r" : ""; printf "allowed-tools: %s%s\n", t, cr; d=1}' > "$body"
  src="$body"

  # Read the file, inject source comment after the frontmatter opening ---
  if head -1 "$src" | grep -q "^---"; then
    # Has frontmatter - inject after opening ---
    {
      head -1 "$src"
      echo "# Source: $REPO_URL (${VERSION:-unknown})"
      echo "# Installed: $INSTALLED_AT - update by re-running install.sh"
      tail -n +2 "$src"
    } > "$dst"
  else
    # No frontmatter - prepend as comment block
    {
      echo "<!-- Source: $REPO_URL (${VERSION:-unknown}) -->"
      echo "<!-- Installed: $INSTALLED_AT - update by re-running install.sh -->"
      echo ""
      cat "$src"
    } > "$dst"
  fi
  rm -f "$body"
}

# Clean legacy filenames from any prior install (rename pass 2026-06-22).
# Remove this block six months after PR-1 merges - by then every consumer
# has re-installed and the legacy files no longer exist anywhere.
for legacy in \
  "$CLAUDE_DIR/commands/bdd-scenario-design.md" \
  "$CLAUDE_DIR/commands/bdd-implement-scenario.md" \
  "$CLAUDE_DIR/commands/test-feature.md"; do
  if [ -f "$legacy" ]; then
    echo "Removing legacy: $legacy"
    rm "$legacy"
  fi
done

# Install skills with source headers
for s in discover design implement run triage reconcile; do
  install_skill "$PLUGIN_DIR/commands/$s.md" "$CLAUDE_DIR/commands/bdd-$s.md"
done
cp "$SCRIPTS_DIR/decisions.sh" "$CLAUDE_DIR/scripts/decisions.sh"
chmod +x "$CLAUDE_DIR/scripts/decisions.sh"
cp "$SCHEMAS_DIR/decision.schema.json" "$CLAUDE_DIR/schemas/decision.schema.json"
install_skill "$PLUGIN_DIR/agents/verifier.md" "$CLAUDE_DIR/agents/bdd-verifier.md"

echo "Installed BDD skills (from $REPO_URL ${VERSION:-}):"
echo "  $CLAUDE_DIR/commands/bdd-discover.md"
echo "  $CLAUDE_DIR/commands/bdd-design.md"
echo "  $CLAUDE_DIR/commands/bdd-implement.md"
echo "  $CLAUDE_DIR/commands/bdd-run.md"
echo "  $CLAUDE_DIR/commands/bdd-triage.md"
echo "  $CLAUDE_DIR/commands/bdd-reconcile.md"
echo "  $CLAUDE_DIR/scripts/decisions.sh"
echo "  $CLAUDE_DIR/schemas/decision.schema.json"
echo "  $CLAUDE_DIR/agents/bdd-verifier.md"

# Config template - only copy if no config exists yet
if [ ! -f "$CLAUDE_DIR/bdd-config.md" ]; then
  to_project < "$PLUGIN_DIR/bdd-config.template.md" > "$CLAUDE_DIR/bdd-config.md"
  echo "  $CLAUDE_DIR/bdd-config.md (from template - edit this for your project)"
else
  echo ""
  echo "bdd-config.md already exists - skipped (not overwritten)."
fi

# Report newer config rows that an older bdd-config.md does not have yet
report_missing_row() {
  local row="$1" default="$2"
  if ! grep -qE "^\|[[:space:]]*$row[[:space:]]*\|" "$CLAUDE_DIR/bdd-config.md"; then
    echo "  note: bdd-config.md has no '$row' row - default: $default"
  fi
}
report_missing_row workflow_mode "specify-and-implement"
report_missing_row glossary_file "skipped"
report_missing_row discovery_dir "docs/discovery"
report_missing_row lint "skipped"
report_missing_row prepare "skipped"
report_missing_row step_batch "auto"
report_missing_row discoverer "bdd-discover"
report_missing_row unautomated_tag "@pending (v1 default was @manual; set the row to keep the old tag)"
report_missing_row automated_tag "skipped"
report_missing_row decision_log "off"
report_missing_row decisions_dir "docs/decisions"
report_missing_row scenario_id_prefix "spec-"
report_missing_row status_scope "scenario"
report_missing_row manual_only_tag "@manual-only"
report_missing_row planned_dir "none (used with status_scope directory)"
report_missing_row manual_only_dir "none (used with status_scope directory)"
report_missing_row blocked_tag "none"
report_missing_row reconciler "bdd-reconcile"
report_missing_row feedback-intake "bdd-triage"

# Cleanup temp dir if we cloned
if [ -n "$CLEANUP" ]; then
  rm -rf "$CLEANUP"
fi

echo ""
echo "Next steps:"
echo "  1. Edit .claude/bdd-config.md with your project's tooling commands"
echo "  2. Optionally add a domain-knowledge skill: .claude/commands/bdd-<project>-knowledge.md"
echo "  3. Commit the installed skills: git add .claude/"
echo "  4. Try: /bdd-discover <story> to find what to build, then /bdd-design"
echo "  5. Decision log (optional): set decision_log to on. It needs jq. Add this line to .gitattributes so parallel branches merge:"
echo "       docs/decisions/*.jsonl merge=union"
