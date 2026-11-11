@skills-text
Feature: The run command and the verifier agent know the manual tags and do not mention deliver

  These scenarios read the text of the command and of the agent. They check what it says and run nothing.

  Decision (2026-11-12): The checks of tests/test_skills.sh move here and none is added. Why: a migration adds no checks.

  Scenario Outline: The <file> text names the unautomated and manual-only tags and says a skip is never an error
    Given the file "<file>"
    Then it contains:
      | unautomated_tag |
      | manual_only_tag |
      | never an error  |

    Examples:
      | file                      |
      | plugin/commands/run.md    |
      | plugin/agents/verifier.md |

  Scenario Outline: The <file> text does not mention deliver
    Given the file "<file>"
    Then it does not contain "deliver"

    Examples:
      | file                      |
      | plugin/commands/run.md    |
      | plugin/agents/verifier.md |
