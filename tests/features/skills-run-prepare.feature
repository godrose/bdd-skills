@skills-text
Feature: The prepare row builds what the tests launch, before generate and test

  These scenarios read the text of the command and of the agent. They check what it says and run nothing.

  Decision (2026-11-12): The checks of tests/test_skills.sh move here and none is added. Why: a migration adds no checks.
  Decision (2026-11-12): The implement command is not checked here. Why: it comes in the next pull request.

  Scenario Outline: The <file> text runs the prepare row when it has a command and stops when it fails
    Given the file "<file>"
    Then it contains:
      | **prepare**                                   |
      | If the row is absent, empty                   |
      | If **prepare** fails, report the error and stop |
      | Do not run generate or test                   |

    Examples:
      | file                      |
      | plugin/commands/run.md    |
      | plugin/agents/verifier.md |

  Scenario: The run command lists prepare, runs it before generate and does not point at an install command
    Given the plugin command "run"
    Then it contains:
      | - **prepare** command |
      | step 2 (**prepare**)  |
    And it does not contain "Run the install command if missing"
    And it mentions these in this order:
      | run the **prepare** command  |
      | run the **generate** command |

  Scenario: The verifier agent runs prepare before generate and does not retry it
    Given the file "plugin/agents/verifier.md"
    Then it mentions these in this order:
      | Run the **prepare** command  |
      | Run the **generate** command |
    And it contains "Do not retry it"
