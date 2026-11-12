@skills-text
Feature: The deliver command keeps an untouched existing scenario out of the checklist

  These scenarios read the text of the command. They check what it says and run nothing.

  Decision (2026-11-12): An existing scenario that nobody asked about is not an example, and the report counts it on the Regression line. Why: a real run listed one as E0 and gave it no report line, so the report had a gap. The checklist is the behavior the product manager described and confirmed.
  Decision (2026-11-12): The rule is in the deliver command only. Why: standalone discover has no Regression line.
  Decision (2026-11-12): The phrases are checked as policy. Why: how the model follows the text is prompt behavior that only a flow run can test.

  Scenario: An untouched existing scenario is not an example
    Given the plugin command "deliver"
    Then it contains:
      | An existing scenario that nobody asked about is not an example |
      | leave it out of the checklist |
      | The report counts it on the Regression line |

  Scenario: An agreed behavior that an existing scenario covers stays an example
    Given the plugin command "deliver"
    Then it contains "An agreed example that an existing scenario already covers stays an example"

  Scenario: The discover command does not carry the rule
    Given the plugin command "discover"
    Then it does not contain "leave it out of the checklist"
