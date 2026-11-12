@skills-text
Feature: The implement command works from an approved spec and changes the tags

  These scenarios read the text of the command. They check what it says and run nothing.

  Decision (2026-11-12): The checks of tests/test_skills.sh move here and none is added. Why: a migration adds no checks.
  Decision (2026-11-12): The old file reversed a rule that removed the unautomated tag when a scenario passes. Why: the tag is removed only after the verifier passes.

  Scenario: The command works from an approved spec and reports step status
    Given the plugin command "implement"
    Then it contains:
      | approved spec                  |
      | Step status                    |
      | remove the unautomated tag     |

  Scenario: The command names the summary file, both tags and when the tag changes
    Given the plugin command "implement"
    Then it contains:
      | existing (not yet automated)    |
      | .spec-summary.md                |
      | unautomated_tag                 |
      | automated_tag                   |
      | Do this only after the verifier |
    And it does not contain "When a scenario from an approved spec passes, remove the unautomated tag"

  Scenario: A manual-only scenario stays manual and a reworded one is checked by fingerprint
    Given the plugin command "implement"
    Then it contains:
      | manual_only_tag  |
      | stays manual     |
      | fingerprint      |
      | rewords          |
      | default `@pending` |

  Scenario: The command does not default to the manual tag
    Given the plugin command "implement"
    Then it does not contain "default `@manual`"
