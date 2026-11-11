@deliver-text
Feature: The pages that list the deliver command name it

  These scenarios read the text of the listing pages. They check what it says and run nothing.

  Decision (2026-11-11): The checks of tests/test_deliver.sh move here and none is added. Why: a migration adds no checks.
  Decision (2026-11-11): The README line about the installer, gap G9 and the handoff checks sit here. Why: the old file held them. They are not about deliver.md.

  Scenario: The README and the listing README name the command
    Given the README
    Then it contains "/bdd:deliver"
    Given the listing README
    Then it contains "/bdd:deliver"

  Scenario: The docs index lists the deliver pack and the trial record
    Given the docs index
    Then it contains:
      | 2026-11-09-deliver.md            |
      | 2026-11-09-deliver-pm-session.md |

  Scenario: The README says a file is replaced only if its first lines carry the installer
    Given the README
    Then it contains "only if its first lines carry the installer"

  Scenario: The known-gaps file lists gap G9
    Given the file "docs/known-gaps.md"
    Then it contains "### G9"

  Scenario: The design-check handoff names no local path and no project
    Given the file "docs/handoff/2026-11-09-design-check.md"
    Then it does not contain "/Users/"
    And it does not contain "bdd-netcore"
