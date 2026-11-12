@skills-text
Feature: The deliver command shows the second gate in plain words

  These scenarios read the text of the command. They check what it says and run nothing.

  Decision (2026-11-12): The old sentence that design "shows the scenarios in plain words and waits for the go-ahead", with nothing about the audit table, is replaced. Why: the table names step files, and the flow runs showed the product manager was shown them.
  Decision (2026-11-12): The rest is checked as policy, one scenario for what the product manager sees and one for where the technical remarks go. Why: how the model follows the text is prompt behavior that only a flow run can test. The phrases are the contract with the harness rule, which reads a table under a developer line as developer text.

  Scenario: The old second gate text is gone
    Given the plugin command "deliver"
    Then it does not contain "audits step reuse and lints the draft, and then shows the scenarios in plain words and waits for the go-ahead"

  Scenario: The product manager sees a plain summary and the table goes under a developer line
    Given the plugin command "deliver"
    Then it contains:
      | plain sentence on reuse       |
      | then a blank line, then the table |
      | Take the fix the designer prefers |

  Scenario: Technical remarks from the second gate reach the developer note
    Given the plugin command "deliver"
    Then it contains "and the technical remarks and fixes from the second gate"
