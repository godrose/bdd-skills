@skills-text
Feature: The init text names the steps entries, IDE generation and the audit's closing line

  These scenarios read the text of the command. They check what it says and run nothing.

  Decision (2026-11-12): The checks of tests/test_skills.sh move here and none is added. Why: a migration adds no checks.

  Scenario: The init text names the steps entries, IDE generation and the closing line
    Given the plugin command "init"
    Then it contains:
      | comma-separated                                         |
      | each entry                                              |
      | generates code in the IDE                               |
      | only for a framework that reads .feature files directly |
      | word for word                                           |
      | Nothing follows it                                      |
