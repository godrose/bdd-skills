@skills-text
Feature: The discover command looks at what exists before the first question

  These scenarios read the text of the command. They check what it says and run nothing.

  Decision (2026-11-12): The checks of tests/test_skills.sh move here and none is added. Why: a migration adds no checks.

  Scenario: The command has a Step 0 that looks first
    Given the plugin command "discover"
    Then it contains:
      | Step 0: Look first                           |
      | before the first question                    |
      | For the developer:                           |
      | found nothing                                |
      | not looked at:                               |
      | Shown values and their source                |
      | ## What exists                               |
      | Where is this set                            |
      | without the user doing it in the same moment |
      | only about what it means for them            |

  Scenario: Step 0 comes before Step 1
    Given the plugin command "discover"
    Then it mentions these in this order:
      | Step 0: Look first                |
      | #### Step 1: Understand the story |
