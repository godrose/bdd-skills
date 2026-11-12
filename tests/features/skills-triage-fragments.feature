@skills-text
Feature: The triage command shows the record fragments and the date form

  These scenarios read the text of the command. They check what it says and run nothing.

  Decision (2026-11-12): The checks of tests/test_skills.sh move here and none is added. Why: a migration adds no checks.

  Scenario: The triage command shows the JSON fragments and the date form
    Given the plugin command "triage"
    Then it contains:
      | "op":"adds"       |
      | "scenario":"spec- |
      | "role":"agreed"   |
      | "kind":"slack"    |
      | "ref":            |
      | YYYY-MM-DD        |
