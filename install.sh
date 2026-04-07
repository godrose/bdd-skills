#!/bin/bash
# Install BDD skills into the current project's .claude/ directory.
#
# Usage:
#   curl -sL https://raw.githubusercontent.com/godrose/bdd/main/install.sh | bash
#   # OR from a cloned copy:
#   ./install.sh [target-dir]
#
# What it does:
#   1. Copies commands/ and agents/ into .claude/
#   2. Copies bdd-config.template.md as .claude/bdd-config.md (if not exists)
#   3. Prints next steps

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TARGET="${1:-.}"

CLAUDE_DIR="$TARGET/.claude"
mkdir -p "$CLAUDE_DIR/commands" "$CLAUDE_DIR/agents"

# Copy skills (always overwrite — they're generic)
cp "$SCRIPT_DIR/commands/bdd-scenario-design.md" "$CLAUDE_DIR/commands/"
cp "$SCRIPT_DIR/commands/bdd-implement-scenario.md" "$CLAUDE_DIR/commands/"
cp "$SCRIPT_DIR/agents/bdd-verifier.md" "$CLAUDE_DIR/agents/"

echo "Installed BDD skills:"
echo "  $CLAUDE_DIR/commands/bdd-scenario-design.md"
echo "  $CLAUDE_DIR/commands/bdd-implement-scenario.md"
echo "  $CLAUDE_DIR/agents/bdd-verifier.md"

# Config template — only copy if no config exists yet
if [ ! -f "$CLAUDE_DIR/bdd-config.md" ]; then
  cp "$SCRIPT_DIR/bdd-config.template.md" "$CLAUDE_DIR/bdd-config.md"
  echo "  $CLAUDE_DIR/bdd-config.md (from template — edit this for your project)"
else
  echo ""
  echo "bdd-config.md already exists — skipped (not overwritten)."
  echo "Compare with template: diff $CLAUDE_DIR/bdd-config.md $SCRIPT_DIR/bdd-config.template.md"
fi

echo ""
echo "Next steps:"
echo "  1. Edit .claude/bdd-config.md with your project's tooling commands"
echo "  2. Optionally add a domain-knowledge skill: .claude/commands/bdd-<project>-knowledge.md"
echo "  3. Try: /bdd-scenario-design <issue-key-or-AC-text>"
