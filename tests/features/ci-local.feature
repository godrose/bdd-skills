Feature: Running the CI checks locally

  Before a push, a contributor runs the same steps as CI, in the same order,
  and learns which step broke.

  Scenario: Every step passes
    Given a copy of the local CI script where every step passes
    When the local CI is run
    Then the local CI passes
    And the steps ran in this order:
      | validate the plugin          |
      | validate the marketplace     |
      | install the scenario runner  |
      | type-check the steps         |
      | run the tests                |

  Scenario: A failing step stops the run and is named
    Given a copy of the local CI script where the plugin validation fails
    When the local CI is run
    Then the local CI fails
    And it names the step "validate the plugin"
    And the step "run the tests" did not run

  Scenario: A type error in a step is named, and the tests do not run
    Given a copy of the local CI script where the type check fails
    When the local CI is run
    Then the local CI fails
    And it names the step "type-check the steps"
    And the step "run the tests" did not run

  Scenario: A failing test run is named
    Given a copy of the local CI script where the tests fail
    When the local CI is run
    Then the local CI fails
    And it names the step "run the tests"

  Scenario: A missing claude is said, not skipped
    Given a copy of the local CI script with no claude installed
    When the local CI is run
    Then the local CI fails
    And it names the step "validate the plugin"
    And it says that claude is not installed
