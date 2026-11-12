@skills-text
Feature: The triage command keeps its approval rules

  These scenarios read the text of the command. They check what it says and run nothing.

  Decision (2026-11-12): The checks of tests/test_skills.sh move here and none is added. Why: a migration adds no checks.
  Decision (2026-11-12): The short words (approve, change, question, open) stay as the old file had them. Why: a migration does not tighten checks.

  Scenario: The triage command keeps its approval rules
    Given the plugin command "triage"
    Then it contains:
      | approve                                  |
      | change                                   |
      | question                                 |
      | unclear                                  |
      | Unclear never counts as approval         |
      | confirms                                 |
      | supersedes                               |
      | channel                                  |
      | writes nothing until                     |
      | rewords                                  |
      | decisions.sh fingerprint                 |
      | decision_log                             |
      | Nothing is committed without being asked |
      | objected                                 |
      | open                                     |
