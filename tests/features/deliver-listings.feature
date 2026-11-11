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
    The installer replaces a file only when it recognises its own header. The README promises this, so the promise must stay in the text.

    Given the README
    Then it contains "only if its first lines carry the installer"

  Scenario: The known-gaps file lists gap G9
    G9 records that the deliver gate eval can fail on its one-question grader. The entry must stay, so the gap is not forgotten.

    Given the file "docs/known-gaps.md"
    Then it contains "### G9"

  Scenario: The design-check handoff names no local path and no project
    A handoff note is committed to a public repo. It must not carry a path from someone's machine or the name of a private trial project. The two strings below are the ones to keep out.

    Given the file "docs/handoff/2026-11-09-design-check.md"
    Then it does not contain "/Users/"
    And it does not contain "bdd-netcore"
