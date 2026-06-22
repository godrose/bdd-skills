#!/bin/bash
# Install BDD skills into a project's .claude/ directory.
#
# Usage:
#   # Remote install (no clone needed):
#   curl -sL https://raw.githubusercontent.com/godrose/bdd/main/install.sh | bash -s -- [target-dir]
#
#   # From a local clone:
#   ./install.sh [target-dir]
#
# What it does:
#   1. If no local source, clones godrose/bdd to a temp dir
#   2. Copies commands/ and agents/ into .claude/ with source header
#   3. Copies bdd-config.template.md as .claude/bdd-config.md (if not exists)
#   4. Prints next steps

set -e

REPO_URL="https://github.com/godrose/bdd"
REPO_BRANCH="main"

# Determine source directory
if [ -n "${BASH_SOURCE[0]}" ] && [ -f "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/.claude/commands/bdd-design.md" ]; then
  # Running from a local clone
  SOURCE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
  CLEANUP=""
else
  # Running via curl pipe — clone to temp dir
  SOURCE_DIR="$(mktemp -d)"
  CLEANUP="$SOURCE_DIR"
  echo "Cloning $REPO_URL ($REPO_BRANCH)..."
  git clone --depth 1 --branch "$REPO_BRANCH" "$REPO_URL" "$SOURCE_DIR" 2>&1 | grep -v "^$"
fi

TARGET="${1:-.}"
CLAUDE_DIR="$TARGET/.claude"
mkdir -p "$CLAUDE_DIR/commands" "$CLAUDE_DIR/agents"

# Resolve version from git
VERSION=""
if [ -d "$SOURCE_DIR/.git" ]; then
  VERSION=$(cd "$SOURCE_DIR" && git describe --tags --always 2>/dev/null || git rev-parse --short HEAD 2>/dev/null || echo "unknown")
fi
INSTALLED_AT=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

# Inject source header into a skill file and write to destination
install_skill() {
  local src="$1"
  local dst="$2"

  # Read the file, inject source comment after the frontmatter opening ---
  if head -1 "$src" | grep -q "^---"; then
    # Has frontmatter — inject after opening ---
    {
      head -1 "$src"
      echo "# Source: $REPO_URL (${VERSION:-unknown})"
      echo "# Installed: $INSTALLED_AT — update by re-running install.sh"
      tail -n +2 "$src"
    } > "$dst"
  else
    # No frontmatter — prepend as comment block
    {
      echo "<!-- Source: $REPO_URL (${VERSION:-unknown}) -->"
      echo "<!-- Installed: $INSTALLED_AT — update by re-running install.sh -->"
      echo ""
      cat "$src"
    } > "$dst"
  fi
}

# Clean legacy filenames from any prior install (rename pass 2026-06-22).
# Remove this block six months after PR-1 merges — by then every consumer
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
install_skill "$SOURCE_DIR/.claude/commands/bdd-design.md"    "$CLAUDE_DIR/commands/bdd-design.md"
install_skill "$SOURCE_DIR/.claude/commands/bdd-implement.md" "$CLAUDE_DIR/commands/bdd-implement.md"
install_skill "$SOURCE_DIR/.claude/commands/bdd-run.md"       "$CLAUDE_DIR/commands/bdd-run.md"
install_skill "$SOURCE_DIR/.claude/agents/bdd-verifier.md"    "$CLAUDE_DIR/agents/bdd-verifier.md"

echo "Installed BDD skills (from $REPO_URL ${VERSION:-}):"
echo "  $CLAUDE_DIR/commands/bdd-design.md"
echo "  $CLAUDE_DIR/commands/bdd-implement.md"
echo "  $CLAUDE_DIR/commands/bdd-run.md"
echo "  $CLAUDE_DIR/agents/bdd-verifier.md"

# Config template — only copy if no config exists yet
if [ ! -f "$CLAUDE_DIR/bdd-config.md" ]; then
  cp "$SOURCE_DIR/.claude/bdd-config.template.md" "$CLAUDE_DIR/bdd-config.md"
  echo "  $CLAUDE_DIR/bdd-config.md (from template — edit this for your project)"
else
  echo ""
  echo "bdd-config.md already exists — skipped (not overwritten)."
fi

# Cleanup temp dir if we cloned
if [ -n "$CLEANUP" ]; then
  rm -rf "$CLEANUP"
fi

echo ""
echo "Next steps:"
echo "  1. Edit .claude/bdd-config.md with your project's tooling commands"
echo "  2. Optionally add a domain-knowledge skill: .claude/commands/bdd-<project>-knowledge.md"
echo "  3. Commit the installed skills: git add .claude/"
echo "  4. Try: /bdd-design <issue-key-or-AC-text>"
