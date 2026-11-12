@skills-text
Feature: The deliver command shows the second gate in plain words

  These scenarios read the text of the command. They check what it says and run nothing.

  Decision (2026-11-12): The old sentence that design "shows the scenarios in plain words and waits for the go-ahead", with nothing about the audit table, is replaced. Why: the table names step files, and the flow runs showed the product manager was shown them.
  Decision (2026-11-12): The rest is checked as policy, one scenario for what the product manager sees, one for where the technical remarks go one for the label on each remark, one for a finding question asked alone and one for how step 5 looks. Why: how the model follows the text is prompt behavior that only a flow run can test. The phrases are the contract with the harness rule, which reads a table under a developer line as developer text.

  Scenario: The old second gate text is gone
    Given the plugin command "deliver"
    Then it does not contain "audits step reuse and lints the draft, and then shows the scenarios in plain words and waits for the go-ahead"

  Scenario: The product manager sees a plain summary and the table goes under a developer line
    Given the plugin command "deliver"
    Then it contains:
      | plain sentence on reuse       |
      | then a blank line, then the table |
      | Take the fix the designer prefers |

  Scenario: Each technical remark has its own developer line
    Given the plugin command "deliver"
    Then it contains:
      | Put every other technical remark on its own line that starts "For the developer:" |
      | one line each, never in a list after the table |

  Scenario: A finding question is asked alone
    Given the plugin command "deliver"
    Then it contains:
      | Send that question alone, without the request for the go-ahead |
      | ask for the go-ahead in a later message |

  Scenario: Step 5 looks with the means the project has and never asks for a command to be approved
    Given the plugin command "deliver"
    Then it contains:
      | Look with the means the project already has |
      | and not with a command you write yourself |
      | Never ask the product manager to approve a command |

  Scenario: Technical remarks from the second gate reach the developer note
    Given the plugin command "deliver"
    Then it contains "and the technical remarks and fixes from the second gate"
