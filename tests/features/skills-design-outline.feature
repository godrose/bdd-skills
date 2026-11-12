@skills-text
Feature: The design command offers Outline against separate scenarios by name

  These scenarios read the text of the command. They check what it says and run nothing.

  Decision (2026-11-12): The checks of tests/test_skills.sh move here and none is added. Why: a migration adds no checks.

  Scenario: The command offers the choice by name and never merges cases
    Given the plugin command "design"
    Then it contains:
      | Outline + Examples against separate scenarios |
      | by those names                                |
      | let the person choose                         |
      | never merge cases into one scenario           |
