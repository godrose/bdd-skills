@skills-text
Feature: The implement command does not go back to code newness or a plan message

  These scenarios read the text of the command. They check what it says and run nothing.

  Decision (2026-11-12): The checks of tests/test_skills.sh move here and none is added. Why: a migration adds no checks.
  Decision (2026-11-12): The old file reversed two rules: a step is classified by what needs a run to know, and the plan goes in the final report. Why: the model writes the report reliably, and code that is new can still be written by reading the repo.
  Decision (2026-11-12): After the approach review only the scenarios that check an earlier decision was not undone stay. Why: the wording checks pinned phrases, not outcomes.

  Scenario: A step is not classified by what code is new
    Given the plugin command "implement"
    Then it does not contain "needs a new element, endpoint, client method or fixture"

  Scenario: The group plan is not written as a message
    Given the plugin command "implement"
    Then it does not contain:
      | write the plan as a message                    |
      | Print one line per step before the first run   |
