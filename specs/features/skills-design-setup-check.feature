@skills-text
Feature: The design command checks the setup that a scenario depends on

  These scenarios read the text of the command. They check what it says and run nothing.

  Decision (2026-11-12): The earlier rule that an out-of-band prerequisite is an empty step whose body is a no-op is reversed. Why: an empty step passes when the prerequisite is missing, and the scenario fails later with the cause hidden (issue 41).
  Decision (2026-11-12): The rest is checked as policy, one scenario for the setup error and the audit pass and one for the label the person approving sees. Why: the wording of the rule is prompt behavior that only a model run can test. The two names are the contract between the rule, the audit and the proposal.

  Scenario: The empty no-op step is no longer the rule
    Given the plugin command "design"
    Then it does not contain:
      | The body is intentionally a no-op                  |
      | body is a no-op, value is in self-documenting what |
      | declare an empty-bodied `Given <prerequisite> exists` step |

  Scenario: A missing prerequisite is a setup error, and reused Givens are audited
    Given the plugin command "design"
    Then it contains:
      | fails with a setup error  |
      | Pass E - setup check      |

  Scenario: What cannot be checked is shown to the person approving
    Given the plugin command "design"
    Then it contains "Assumed, not checked"
