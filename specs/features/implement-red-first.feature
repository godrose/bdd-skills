@red-first
Feature: The implement command states the red-first check

  These scenarios read the text of the command. They check what it says and run nothing.

  Decision (2026-11-11): The checks of tests/test_red_first.sh move here and none is added. Why: a migration adds no checks.
  Decision (2026-11-11): The order check finds the first line that holds each heading. Why: that is what the old file did.

  Decision (2026-11-15): The forced red breaks what the step observes and leaves the expected value alone. Why: a break of the expected value shows that the assertion runs, not that it reads the behavior the scenario names. Chosen by the builder. Replaces the earlier forced red, which changed the expected value.
  Decision (2026-11-15): When the observed side cannot be broken, the expected-value break is the fallback, the scenario still loses its unautomated tag, and the line says "on the expected side". Why: a project with generated or shared readers must still be able to automate a scenario, and the weaker proof stays visible. Chosen by the builder.

  Scenario: The command names the red-first check and its phase
    Given the plugin command "implement"
    Then it contains:
      | red-first check                 |
      | #### Phase 2.5: Red-first check |

  Scenario: The red-first phase comes before the full verification phase
    Given the plugin command "implement"
    Then it mentions these in this order:
      | #### Phase 2.5: Red-first check          |
      | #### Phase 3: Full Scenario Verification |

  Scenario: The command names the natural red and the forced red
    Given the plugin command "implement"
    Then it contains:
      | natural red |
      | forced red  |

  Scenario: The command says what is not a red
    Given the plugin command "implement"
    Then it contains "An undefined step, a timeout, a setup or auth error, or a compile or type error is not a red."

  Scenario: The command keeps the break out of feature and data files and restores the original
    Given the plugin command "implement"
    Then it contains:
      | Never break a `.feature` file or a data file.                         |
      | restore the original text and check that the diff against it is empty |

  Scenario: The command reports a Red-first line with not seen red as an outcome
    Given the plugin command "implement"
    Then it contains:
      | Red-first:   |
      | not seen red |

  Scenario: A scenario not seen red keeps the unautomated tag
    Given the plugin command "implement"
    Then it contains:
      | keeps the unautomated tag                   |
      | a red-first line that is not "not seen red" |

  Scenario: The command warns about a break left behind by an interrupted run
    Given the plugin command "implement"
    Then it contains "a break left behind by an interrupted run"

  Scenario: The forced red breaks what the step observes
    Given the plugin command "implement"
    Then it contains:
      | on the actual side                          |
      | Red-first: forced on the actual side        |
      | Leave the expected value as it is           |

  Scenario: The expected side is the fallback, and the line says so
    Given the plugin command "implement"
    Then it contains:
      | Red-first: forced on the expected side |
      | the read is in generated code          |

  Scenario: The forced red line of the earlier kind is gone
    Given the plugin command "implement"
    Then it does not contain "Red-first: forced, failed in"

  Scenario: A break that gives no value is not a red
    Given the plugin command "implement"
    Then it contains "The break must give a different value, not a missing one."
