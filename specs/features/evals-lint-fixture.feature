@evals
Feature: The lint script of the design-lint-draft fixture enforces the ticket tag

  The case asks the agent to lint its draft with this script. The agent must see a finding for an untagged scenario and a clean run for a tagged one, in a file in the folder or in a draft file.

  Decision (2026-11-12): The script is run on small projects built in a scenario. Why: the old file checked only that the script mentions "@TKT-", so a script with no rule passed.
  Decision (2026-11-12): The draft file is named like the one the case tells the agent to delete, `.bdd-draft-<name>.feature`. Why: the lint must read it, and a hidden file is the easiest one to skip.

  Scenario: The old scenario of the fixture is a finding
    Given a project with the lint script and the feature files of the lint fixture
    When the lint script is run
    Then the script exits with status 1
    And the output mentions "features/reports.feature:3: scenario needs a @TKT-<n> tag"

  Scenario: A scenario with the ticket tag on the line above passes
    Given a project with the lint script of the lint fixture and no feature files
    And the lint project has the feature file "archive.feature" that reads:
      """
      Feature: Archive
        @TKT-42
        Scenario: A user can archive an open report
          Given an open report
      """
    When the lint script is run
    Then the script exits with status 0
    And the output mentions "lint: no findings"

  Scenario: A ticket tag next to another tag passes
    Given a project with the lint script of the lint fixture and no feature files
    And the lint project has the feature file "archive.feature" that reads:
      """
      Feature: Archive
        @smoke @TKT-42 @web
        Scenario: A user can archive an open report
          Given an open report
      """
    When the lint script is run
    Then the script exits with status 0

  Scenario: A tag that is not on the line above is a finding
    Given a project with the lint script of the lint fixture and no feature files
    And the lint project has the feature file "archive.feature" that reads:
      """
      Feature: Archive
        @TKT-42

        Scenario: A user can archive an open report
          Given an open report
      """
    When the lint script is run
    Then the script exits with status 1

  Scenario: A tag that is not a ticket tag is a finding
    Given a project with the lint script of the lint fixture and no feature files
    And the lint project has the feature file "archive.feature" that reads:
      """
      Feature: Archive
        @smoke
        Scenario: A user can archive an open report
          Given an open report
      """
    When the lint script is run
    Then the script exits with status 1

  Scenario: A ticket tag with no number is a finding
    Given a project with the lint script of the lint fixture and no feature files
    And the lint project has the feature file "archive.feature" that reads:
      """
      Feature: Archive
        @TKT-abc
        Scenario: A user can archive an open report
          Given an open report
      """
    When the lint script is run
    Then the script exits with status 1

  Scenario: Every untagged scenario is named, an outline too
    Given a project with the lint script of the lint fixture and no feature files
    And the lint project has the feature file "archive.feature" that reads:
      """
      Feature: Archive
        Scenario: A user can archive an open report
          Given an open report
        Scenario Outline: A user can archive a <kind> report
          Given a <kind> report
      """
    When the lint script is run
    Then the script exits with status 1
    And the output has 2 lines mentioning "scenario needs a @TKT-<n> tag"

  Scenario: A draft file with an untagged scenario is a finding
    Given a project with the lint script of the lint fixture and no feature files
    And the lint project has the feature file ".bdd-draft-reports-archive.feature" that reads:
      """
      Feature: Archive
        Scenario: A user can archive an open report
          Given an open report
      """
    When the lint script is run
    Then the script exits with status 1
    And the output mentions ".bdd-draft-reports-archive.feature:2"

  Scenario: A draft file with a tagged scenario passes
    Given a project with the lint script of the lint fixture and no feature files
    And the lint project has the feature file ".bdd-draft-reports-archive.feature" that reads:
      """
      Feature: Archive
        @TKT-42
        Scenario: A user can archive an open report
          Given an open report
      """
    When the lint script is run
    Then the script exits with status 0

  Scenario: The case checks that no draft and no feature file are left behind
    Given the file "evals/design-lint-draft/case.yaml"
    Then it contains:
      | path: features/.bdd-draft-*              |
      | path: features/reports-archive*.feature |
    And it has 2 lines containing "exists: false"
