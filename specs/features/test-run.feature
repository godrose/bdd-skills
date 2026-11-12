Feature: The test run

  A contributor runs the whole suite with one command. The run must be honest:
  it says what is missing, and it never reports a pass for a run that checked nothing.

  Scenario: The run tells a contributor to install the scenario runner
    Given a copy of the test run with no scenario runner installed
    When the tests are run
    Then the run fails
    And it tells the contributor to run "npm ci"

  Scenario: A run in which no scenario ran is not a pass
    Given a copy of the test run whose scenario runner finds no scenario
    When the tests are run
    Then the run fails
    And it says that no scenario ran

  Scenario: A passing scenario run passes
    Given a copy of the test run whose scenarios pass
    When the tests are run
    Then the run passes

  Scenario: A failing scenario fails the run
    Given a copy of the test run whose scenarios fail
    When the tests are run
    Then the run fails
