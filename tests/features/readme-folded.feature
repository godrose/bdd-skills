@readme
Feature: The README folds its reference material away

  Scenario: The README has at least 5 details blocks, each opened and closed
    Given the README
    Then it has at least 5 details blocks
    And its details blocks open and close in equal number

  Scenario: The Files, Architecture and Optional config rows blocks have their summaries
    Given the README
    Then it contains:
      | <summary><b>Files</b></summary>                |
      | <summary><b>Architecture</b></summary>         |
      | <summary><b>Optional config rows</b></summary> |
