@red-first
Feature: The implement command states the red-first check

  These scenarios read the text of the command. They check what it says and run nothing.

  Decision (2026-11-11): The checks of tests/test_red_first.sh move here and none is added. Why: a migration adds no checks.
  Decision (2026-11-11): The order check finds the first line that holds each heading. Why: that is what the old file did.

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
