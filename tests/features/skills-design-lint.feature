@skills-text
Feature: The design command lints the draft before it shows it

  These scenarios read the text of the command. They check what it says and run nothing.

  Decision (2026-11-12): The checks of tests/test_skills.sh move here and none is added. Why: a migration adds no checks.

  Scenario: The command lints the draft before it is shown
    Given the plugin command "design"
    Then it contains:
      | before it is shown                    |
      | .bdd-draft-                           |
      | deleted before                        |
      | lint did not run                      |
      | The scenarios are unchecked           |
      | findings in existing files, not touched |
      | ask the user for the value            |
      | two rounds                            |
      | leftover                              |
      | its own name                          |
