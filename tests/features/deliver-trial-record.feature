@deliver-text
Feature: The trial record names no local path and has no em-dash

  These scenarios read the text of the trial record. They check what it says and run nothing.

  Decision (2026-11-11): The checks of tests/test_deliver.sh move here and none is added. Why: a migration adds no checks.
  Decision (2026-11-12): After the approach review only the scenarios that check an earlier decision was not undone stay. Why: the wording checks pinned phrases, not outcomes.

  Scenario: It has no local path and no em-dash
    Given the file "docs/trials/2026-11-09-deliver-pm-session.md"
    Then it does not contain "/Users/"
    And it has no em-dash
