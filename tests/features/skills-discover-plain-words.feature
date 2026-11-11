@skills-text
Feature: The discover command writes the pack in plain words and asks the product manager one question

  These scenarios read the text of the command. They check what it says and run nothing.

  Decision (2026-11-12): The checks of tests/test_skills.sh move here and none is added. Why: a migration adds no checks.

  Scenario: The whole pack is in plain words
    Given the plugin command "discover"
    Then it contains:
      | Write the whole pack in plain words                      |
      | except Vocabulary check                                  |
      | paths go on one "For the developer" line                 |

  Scenario: Unknown words are tried nearby and unknowns are recorded
    Given the plugin command "discover"
    Then it contains:
      | try the words nearby                                                   |
      | Say which words you tried                                              |
      | Keep field names, status names and log names out of these sentences    |
      | are roles                                                              |
      | nobody can check it                                                    |
      | record the unknown as an assumption                                    |
      | Put one question to the product manager in a message                   |

  Scenario: Step 1 comes before Step 3b
    Given the plugin command "discover"
    Then it mentions these in this order:
      | #### Step 1: Understand the story |
      | #### Step 3b                      |
