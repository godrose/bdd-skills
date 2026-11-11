@deliver-text
Feature: The deliver command handles behavior that exists, asks before it acts and keeps plugin names

  These scenarios read the text of the command. They check what it says and run nothing.

  Decision (2026-11-11): The checks of tests/test_deliver.sh move here and none is added. Why: a migration adds no checks.
  Decision (2026-11-11): The path and skill-name checks are one outline with one literal per row. Why: the old file used two regular expressions over fixed names, so a substring check is equal.

  Scenario: Behavior that exists becomes scenarios marked from code
    Given the plugin command "deliver"
    Then it contains:
      | from code     |
      | already works |

  Scenario: The command pre-approves nothing and needs the person to approve
    Given the plugin command "deliver"
    Then it contains:
      | pre-approves nothing                                    |
      | the person running it must be there to approve each one |
    And it does not contain "a developer must be there"

  Scenario: There is no resume file, and nothing is written on an early end
    Given the plugin command "deliver"
    Then it contains:
      | There is no resume file                                                  |
      | If the session ends before the examples are approved, nothing is written |

  Scenario Outline: The plugin text has no project-install form: <text>
    Given the plugin command "deliver"
    Then it does not contain "<text>"

    Examples:
      | text             |
      | .claude/scripts/ |
      | .claude/schemas/ |
      | bdd-discover     |
      | bdd-design       |
      | bdd-implement    |
      | bdd-run          |
      | bdd-triage       |
      | bdd-reconcile    |
      | bdd-verifier     |
