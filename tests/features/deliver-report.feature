@deliver-text
Feature: The deliver command ends with a report for a pull request description

  These scenarios read the text of the command. They check what it says and run nothing.

  Decision (2026-11-11): The checks of tests/test_deliver.sh move here and none is added. Why: a migration adds no checks.

  Scenario: The report has a line for passed, failed and couldn't be checked
    Given the plugin command "deliver"
    Then it contains:
      | : passed                   |
      | : failed - <what happened> |
      | couldn't be checked        |

  Scenario: The report has a regression line and can go into a pull request description
    Given the plugin command "deliver"
    Then it contains:
      | regression line          |
      | pull request description |

  Scenario Outline: Couldn't be checked covers <case>
    Given the plugin command "deliver"
    Then it contains "<case>"

    Examples:
      | case                        |
      | @pending                    |
      | manual-only                 |
      | not seen red                |
      | zero tests                  |
      | was not looked at in step 5 |

  Scenario: The affected feature includes a feature whose step code changed
    Given the plugin command "deliver"
    Then it contains "a step whose code the increment changed"
