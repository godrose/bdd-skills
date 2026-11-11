@plugin-text
Feature: The init command proposes the two optional skill roles from the project's own skills

  These scenarios read the text of the command. They check what it says and run nothing.

  Decision (2026-11-11): The checks of tests/test_plugin.sh move here and none is added. Why: a migration adds no checks.

  Scenario: Detect proposes the domain-knowledge and requirements-sync roles
    Given the plugin command "init"
    Then it contains:
      | ### Skill roles      |
      | domain-knowledge     |
      | requirements-sync    |
      | .claude/skills/      |
      | one-line description |
      | runners-up           |
      | no local skill found |
      | never a candidate    |
      | # Source:            |
