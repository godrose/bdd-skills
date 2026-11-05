Feature: Export

  Scenario: Export an empty list
    Given an empty list
    When I export it
    Then I get the header row only
