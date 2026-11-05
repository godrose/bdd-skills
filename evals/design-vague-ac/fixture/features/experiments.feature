Feature: Experiments list

  Scenario: A Draft experiment can be deleted
    Given the experiment "Alpha" is Draft
    When I delete "Alpha"
    Then "Alpha" is no longer listed

  Scenario: A Running experiment cannot be deleted
    Given the experiment "Bravo" is Running
    When I try to delete "Bravo"
    Then the delete is refused
