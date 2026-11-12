@skills-text
Feature: The dry-run doc, the packaging design doc and known gaps G10 and G12 are listed

  These scenarios read files of the repo. They check what the text says and run nothing.

  Decision (2026-11-12): The checks of tests/test_skills.sh move here and none is added. Why: a migration adds no checks.

  Scenario: The dry-run doc exists
    Given the repository
    Then the repo has these files:
      | docs/superpowers/dry-runs/2026-10-24-discover-and-specify-only.md |

  Scenario: The packaging design doc documents init --detect
    Given the file "docs/superpowers/specs/2026-11-01-plugin-packaging-design.md"
    Then it contains "/bdd:init --detect"

  Scenario: Known gaps G10 and G12 are listed
    Given the file "docs/known-gaps.md"
    Then it contains:
      | ### G10 |
      | ### G12 |
