@skills-text
Feature: The design command gives the generate row no tag filter

  These scenarios read the text of the command. They check what it says and run nothing.

  Decision (2026-11-12): The checks of tests/test_skills.sh move here and none is added. Why: a migration adds no checks.
  Decision (2026-11-12): The old file reversed an earlier hint that filtered the generate row by the unautomated tag. Why: implement needs the scenario it is implementing, so the hint names the framework setting instead.
  Decision (2026-11-12): After the approach review only the scenarios that check an earlier decision was not undone stay. Why: the wording checks pinned phrases, not outcomes.

  Scenario: The earlier tag filter is gone
    Given the plugin command "design"
    Then it does not contain "excluding the unautomated tag"
