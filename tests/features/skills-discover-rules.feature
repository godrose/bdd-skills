@skills-text
Feature: The discover command states its defaults, its stops and its size gate

  These scenarios read the text of the command. They check what it says and run nothing.

  Decision (2026-11-12): The checks of tests/test_skills.sh move here and none is added. Why: a migration adds no checks.
  Decision (2026-11-12): "stop and ask" is checked once. Why: the old file checked the same text twice.

  Scenario: The command names its defaults, its stops and its size gate
    Given the plugin command "discover"
    Then it contains:
      | Defaults when config rows are absent |
      | stop and ask                         |
      | requirements-sync                    |
      | nothing to mine                      |
      | size gate                            |
      | one question at a time               |

  Scenario: The command applies the size gate after the story and treats an empty story as none
    Given the plugin command "discover"
    Then it contains:
      | size gate once you have read the story |
      | ask the builder to paste the story     |
      | counts as empty                        |

  Scenario: A missing config does not stop discover
    Given the plugin command "discover"
    Then it does not contain "does not exist, say so and stop"

  Scenario: The steps folder takes several paths
    Given the plugin command "discover"
    Then it contains "comma-separated"
