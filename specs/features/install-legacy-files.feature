@install
Feature: Command files from the old names are removed on install

  Decision (2026-11-12): One scenario for each legacy name, and one for a file that is not a legacy name. Why: a break that drops one name from the list, or removes too much, must fail.
  Decision (2026-11-12): The legacy files are written as plain text, not as installer copies. Why: the installer removes them by name and does not read them.

  Scenario Outline: A command file from an earlier install is removed
    Given a project with its own file "commands/<file>" that reads "OLD COPY"
    When the installer is run on it
    Then the project has none of these files in its .claude folder:
      | commands/<file> |
    And the output mentions "Removing legacy"

    Examples:
      | file                      |
      | bdd-scenario-design.md    |
      | bdd-implement-scenario.md |
      | test-feature.md           |

  Scenario: A command file with another name is left alone
    Given a project with its own file "commands/my-own.md" that reads "MINE"
    When the installer is run on it
    Then the installed file "commands/my-own.md" holds only the line "MINE"
    And the output does not mention "Removing legacy"
