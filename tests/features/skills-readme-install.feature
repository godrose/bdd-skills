@skills-text
Feature: The README puts the plugin install first and project files second

  These scenarios read the README. They check what it says and run nothing.

  Decision (2026-11-12): The checks of tests/test_skills.sh move here and none is added. Why: a migration adds no checks.
  Decision (2026-11-12): The marketplace add line is not checked here. Why: readme-order holds it.

  Scenario: The install section covers the plugin, project files and the move between them
    Given the README
    Then it contains:
      | ### As a plugin                                                   |
      | /plugin install bdd@gennadyverdel-plugins                         |
      | <summary><b>As project files</b></summary>                        |
      | use a hyphen                                                      |
      | `/bdd-design`                                                     |
      | <summary><b>Moving from project files to the plugin</b></summary> |
      | claude plugin update bdd@gennadyverdel-plugins                    |
      | `/bdd:discover <story>`                                           |
      | `/bdd:design`                                                     |
      | `/bdd:implement`                                                  |
    And it does not contain "`/bdd-discover <story>` asks"
