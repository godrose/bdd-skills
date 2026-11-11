@deliver-text
Feature: The deliver command looks at the result before the report

  These scenarios read the text of the command. They check what it says and run nothing.

  Decision (2026-11-11): The checks of tests/test_deliver.sh move here and none is added. Why: a migration adds no checks.

  Scenario: Looking at the result sits between running and the report
    Given the plugin command "deliver"
    Then it mentions these in this order:
      | #### Step 4: Run                |
      | #### Step 5: Look at the result |
      | ### The report                  |

  Scenario: Passing is not proof of what a person sees
    Given the plugin command "deliver"
    Then it contains:
      | then looks at the result                                                    |
      | Passing scenarios do not show that they describe what a person sees         |
      | A passing run shows that the scenarios and the system agree with each other |
    And it does not contain "tells you whether passing means anything"

  Scenario: A screen is looked at, with a screenshot, for more than the scenarios name
    Given the plugin command "deliver"
    Then it contains:
      | **A screen.**                                  |
      | screenshot                                     |
      | anything the page shows that no scenario names |

  Scenario: With no screen, a real request or the stored record is read
    Given the plugin command "deliver"
    Then it contains:
      | **No screen.**         |
      | make a real request    |
      | read the stored record |

  Scenario: A declared state is checked against the running system
    Given the plugin command "deliver"
    Then it contains:
      | **Declared against seen.**                                    |
      | A fixture can declare a state that the system changes at once |

  Scenario: This step does not run the suite again
    Given the plugin command "deliver"
    Then it contains:
      | This step looks at the system itself and does not run the suite again |
      | Run a scenario again only to take a screenshot during it              |

  Scenario: An example that could be looked at is never reported passed unless it was
    Given the plugin command "deliver"
    Then it contains:
      | Never report an example as passed when its result could be looked at and was not |
      | Seen: <                                                                          |
      | not looked at                                                                    |
