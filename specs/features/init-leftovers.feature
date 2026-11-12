@plugin-text
Feature: The init text and the README do not go back to the old leftover wording

  These scenarios read the text of the command and of the README. They check what they say and run nothing.

  Decision (2026-11-11): The checks of tests/test_plugin.sh move here and none is added. Why: a migration adds no checks.
  Decision (2026-11-11): The install.sh source line check is not written. Why: install-fresh-files.feature already runs the installer and checks the line.
  Decision (2026-11-12): After the approach review only the scenarios that check an earlier decision was not undone stay. Why: the wording checks pinned phrases, not outcomes.

  Scenario: An unknown origin is not called your own skill
    Given the plugin command "init"
    Then it does not contain "is your own skill: say it stays"

  Scenario: The README does not say own bdd skills are told apart
    Given the README
    Then it does not contain "Your own `bdd-*` skills are told apart"
