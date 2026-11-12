@known-gaps
Feature: The known-gaps file lists each gap with its parts

  Decision (2026-11-11): Each part is counted as lines equal to the number of gaps. Why: that is what the old test did, so a gap with a part twice could hide another with none.
  Decision (2026-11-11): A gap has three parts, not four. Why: the old test checked three, and its comment saying four was wrong.

  Scenario: The known-gaps file exists
    Given the repository
    Then the repo has these files:
      | docs/known-gaps.md |

  Scenario: The known-gaps file lists at least 5 gaps
    Given the file "docs/known-gaps.md"
    Then it lists at least 5 gaps

  Scenario: Every gap says what is not checked, why, and when it closes
    Given the file "docs/known-gaps.md"
    Then every gap in it has these parts:
      | **Not checked.** |
      | **Why.**         |
      | **Closed when.** |

  Scenario: No two gaps share an id
    Given the file "docs/known-gaps.md"
    Then no two gaps in it share an id

  Scenario: The README points to the known-gaps file
    Given the README
    Then it contains "docs/known-gaps.md"

  Scenario: The docs index lists the known-gaps file
    Given the docs index
    Then it contains "known-gaps.md"
