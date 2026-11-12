@skills-text
Feature: The reconcile command stops when the config is missing

  These scenarios read the text of the command. They check what it says and run nothing.

  Decision (2026-11-12): The checks of tests/test_skills.sh move here and none is added. Why: a migration adds no checks.

  Scenario: A missing config stops it and the template is named
    Given the plugin command "reconcile"
    Then it contains:
      | does not exist, say so and stop |
      | `bdd-config.template.md`        |
