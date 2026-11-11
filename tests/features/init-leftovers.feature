@plugin-text
Feature: The init command reports leftover project-file copies and deletes nothing

  These scenarios read the text of the command and of the README. They check what they say and run nothing.

  Decision (2026-11-11): The checks of tests/test_plugin.sh move here and none is added. Why: a migration adds no checks.
  Decision (2026-11-11): The install.sh source line check is not written. Why: install-fresh-files.feature already runs the installer and checks the line.

  Scenario: Init reports leftover project-file copies and deletes nothing
    Given the plugin command "init"
    Then it contains:
      | ### Leftovers                                   |
      | # Source: https://github.com/godrose/bdd-skills |
      | bdd-<name>.md                                   |
      | your own                                        |
      | Do not delete                                   |
      | duplicate commands                              |
      | bdd:                                            |

  Scenario: Only files that exist on disk count as leftovers
    Given the plugin command "init"
    Then it contains:
      | only if it exists on disk              |
      | git shows as deleted is not a leftover |

  Scenario: Old install names count by name alone, and an unknown origin is not "your own"
    Given the plugin command "init"
    Then it contains:
      | bdd-scenario-design        |
      | bdd-implement-scenario     |
      | test-feature               |
      | origin unknown, left alone |
      | .claude/.gitignore         |
      | hint only                  |
    And it does not contain "is your own skill: say it stays"

  Scenario: The README says init lists leftovers and audits
    Given the README
    Then it contains:
      | lists leftover           |
      | proposes your own skills |
      | origin unknown           |
      | audits                   |
    And it does not contain "Your own `bdd-*` skills are told apart"
