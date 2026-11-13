@readme
Feature: The README's reference notes say what they should

  Decision (2026-11-13): The tooling rows hold no build configuration of one project, and no command that its tool does not accept. Why: a trial project's configuration name sat in the .NET rows, and `mvn compile -Werror` is not a Maven option.

  Scenario: The prepare row is listed with the other optional rows
    Given the README
    Then it contains "| `prepare` | none |"

  Scenario: The .NET typecheck example forces a recompile and names no project configuration
    Given the README
    Then it contains "dotnet build -warnaserror --no-incremental"
    And it does not contain:
      | ServerWithFake |

  Scenario: The Maven rows use options that Maven accepts and run every scenario
    Given the README
    Then it contains "-Dmaven.compiler.failOnWarning=true"
    And it does not contain:
      | mvn compile -Werror        |
      | cucumber.filter.tags="@smoke" |

  Scenario: The Files tree matches the top of the repo
    Given the README
    Then its Files tree lists every top-level entry of the repo, and each entry it lists exists

  Scenario: The architecture and the Files tree know the feature-builder role and what implement does
    Given the README
    Then it contains:
      | Discovers: feature-builder skill                      |
      | Implement step definitions and build the feature      |

  Scenario: The generate hint names the setting that defers missing steps
    Given the README
    Then it contains:
      | missingSteps |
      | fail-on-run  |

  Scenario: The README says that the install asks whether to turn it on
    Given the README
    Then it contains "asks whether to turn it on"
