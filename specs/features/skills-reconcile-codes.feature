@skills-text
Feature: The reconcile command names the script's codes

  These scenarios read the text of the command. They check what it says and run nothing.

  Decision (2026-11-12): The checks of tests/test_skills.sh move here and none is added. Why: a migration adds no checks.

  Scenario Outline: The reconcile text names <code>
    Given the plugin command "reconcile"
    Then it contains "<code>"

    Examples:
      | code                 |
      | E-JSON               |
      | E-SCHEMA             |
      | E-VERSION            |
      | E-DUP-ID             |
      | E-REF                |
      | I-EMPTY              |
      | decisions.sh status  |
      | never fails on status |
