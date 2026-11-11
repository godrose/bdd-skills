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

  Scenario: A passing scenario run and a passing bash file pass
    Given a copy of the test run whose scenarios pass
    And a bash test file that passes
    When the tests are run
    Then the run passes

  Scenario: A failing scenario fails the run
    Given a copy of the test run whose scenarios fail
    And a bash test file that passes
    When the tests are run
    Then the run fails

  Scenario: A failing bash file fails the run even when the scenarios pass
    Given a copy of the test run whose scenarios pass
    And a bash test file that fails
    When the tests are run
    Then the run fails
    And the bash test file still ran after the scenarios
