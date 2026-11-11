@skills-text
Feature: A run of zero tests is never a pass

  These scenarios read the text of the command and of the agent. They check what it says and run nothing.

  Decision (2026-11-12): The checks of tests/test_skills.sh move here and none is added. Why: a migration adds no checks.
  Decision (2026-11-12): The implement command is not checked here. Why: it comes in the next pull request.

  Scenario Outline: The <file> text says that no tests ran is not a pass and skipped tests do not count
    Given the file "<file>"
    Then it contains:
      | no tests ran                                |
      | nothing to run                              |
      | Skipped tests do not count as executed      |

    Examples:
      | file                      |
      | plugin/commands/run.md    |
      | plugin/agents/verifier.md |

  Scenario: The run command counts what ran before it reports success
    Given the plugin command "run"
    Then it mentions these in this order:
      | Count what ran |
      | On success     |

  Scenario: The verifier agent reports the executed count and wants at least one executed test
    Given the file "plugin/agents/verifier.md"
    Then it contains:
      | executed count unknown       |
      | - Executed:                  |
      | at least one test executed   |
