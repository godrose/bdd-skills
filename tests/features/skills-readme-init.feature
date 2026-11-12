@skills-text
Feature: The README says init copies the template and nothing more

  These scenarios read the README. They check what it says and run nothing.

  Decision (2026-11-12): The checks of tests/test_skills.sh move here and none is added. Why: a migration adds no checks.
  Decision (2026-11-12): The `/bdd:init` mention is not checked here. Why: readme-order holds it.

  Scenario: The README says init never overwrites and does not fill in
    Given the README
    Then it contains:
      | never overwrites       |
      | does not fill in       |
      | init.md                |
      | may ask you to approve |
    And it does not contain "mkdir -p .claude && curl"
