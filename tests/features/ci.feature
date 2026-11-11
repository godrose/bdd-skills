Feature: The CI job

  Scenario: CI installs the scenario runner before it runs the tests
    Given the CI workflow
    Then it installs the scenario runner before it runs the tests

  Scenario: CI still validates the plugin and the marketplace first
    Given the CI workflow
    Then it validates the plugin strictly before it runs the tests
    And it validates the marketplace before it runs the tests

  Scenario: CI runs on every pull request, so a pull request to a base branch is checked too
    Given the CI workflow
    Then it runs on every pull request
