@skills-text
Feature: The implement command passes the scenario tag as a selection and has tag defaults

  These scenarios read the text of the command. They check what it says and run nothing.

  Decision (2026-11-12): The checks of tests/test_skills.sh move here and none is added. Why: a migration adds no checks.

  Scenario: The command passes the scenario tag as a selection
    Given the plugin command "implement"
    Then it contains:
      | By: tag              |
      | Select: <scenario-tag> |
    And it does not contain "Tag: <scenario-tag>"

  Scenario: The command has tag defaults and reports which tags changed
    Given the plugin command "implement"
    Then it contains:
      | Defaults when config rows are absent                                   |
      | no tag changes                                                         |
      | Add the automated tag only when the unautomated tag was removed        |
      | which tags changed                                                     |
