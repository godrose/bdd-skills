@skills-text
Feature: The README's migration text never tells users to delete with the bdd glob

  These scenarios read the README. They check what it says and run nothing.

  Decision (2026-11-12): The checks of tests/test_skills.sh move here and none is added. Why: a migration adds no checks.

  Scenario: The migration text names the files and keeps the user's own
    Given the README
    Then it does not contain ".claude/commands/bdd-*.md"
    And it contains:
      | bdd-discover                     |
      | bdd-reconcile                    |
      | `.claude/agents/bdd-verifier.md` |
      | bdd-<project>-knowledge          |
      | Keep your own                    |
      | older installs                   |
