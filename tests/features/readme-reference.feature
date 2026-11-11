@readme
Feature: The README's reference notes say what they should

  Scenario: The prepare row is listed with the other optional rows
    Given the README
    Then it contains "| `prepare` | none |"

  Scenario: The .NET typecheck example forces a recompile
    Given the README
    Then it contains "dotnet build -c ServerWithFake -warnaserror --no-incremental"

  Scenario: The generate hint names the setting that defers missing steps
    Given the README
    Then it contains:
      | missingSteps |
      | fail-on-run  |

  Scenario: The README says that the install asks whether to turn it on
    Given the README
    Then it contains "asks whether to turn it on"
