@skills-text @deliver-report
Feature: The deliver report puts each example in one place

  These scenarios read the text of the command. They check what it says and run nothing.

  Decision (2026-11-13): An example under the Not checked section carries "couldn't be checked" on its own line, never "passed", and a "passed" example is not named in that section. Why: a real run listed E2 to E4 as not checked and marked them passed, because their scenarios passed. The reader cannot tell which to trust. The harness rule parked-not-passed counts the clash.
  Decision (2026-11-13): The text says what to write when the scenario passed and the result was not looked at. Why: that is the case that produced the clash, and the line should say it plainly.

  Scenario: The report text keeps an example out of two places
    Given the plugin command "deliver"
    Then it contains:
      | has `couldn't be checked` on its own line, never `passed` |
      | the scenario passed, but the result was not looked at     |
