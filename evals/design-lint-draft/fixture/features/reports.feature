Feature: Reports list

  Scenario: An open report can be shared
    Given the report "Q1" is open
    When I share "Q1"
    Then "Q1" shows as shared
