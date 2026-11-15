@skills-text @implement-test-side
Feature: implement writes test code, and deliver builds the feature

  These scenarios read the text of the commands, the config template and the README. They check what the files say to each other and run nothing.

  Decision (2026-11-15): implement writes test code only and never builds the feature. Why: a command with two meanings of "implement" confuses users, and application code is not the plugin's expertise. This reverses the decision of 2026-11-13 that both implement and deliver build the feature.
  Decision (2026-11-15): deliver is the one command that builds the feature. It uses the feature-builder role when set, a skill named in the request for that run, and builds it itself when neither is there. Why: the README sends a newcomer to deliver first, and stopping at red scenarios would be a poor first run.
  Decision (2026-11-15): A missing feature is a thing the scenario names that is not in the system at all. A wrong locator or call for something that exists is a step problem. Why: exploring the real system is test expertise, and "locator not found" must not mean two things.
  Decision (2026-11-15): implement may add a test hook to the application, such as a test id or an accessible label, when it does not change what the application does. Why: a hook is part of making the scenario executable, and it is a small, safe edit.
  Decision (2026-11-15): One rule for every application edit, from implement and deliver: on the default branch, create bdd/<story-slug> first and say so in one line. On another branch, stay. Never a worktree. Why: the user expects the plugin to be autonomous, and has to know what it did.
  Decision (2026-11-15): A new Workflow row build_order, all-first (default) or per-scenario, with a flag on deliver that wins for one run. Why: the best order varies by team, and a row with a flag is the pattern of workflow_mode.
  Decision (2026-11-15): The build rule is written once, in deliver. Why: two copies drift, as the review of 2026-11-13 noted.

  Scenario: The config template has the build order row
    Given the file "plugin/bdd-config.template.md"
    Then it contains:
      | build_order |
      | all-first   |
      | per-scenario |

  Scenario: deliver names the build order, its flag and its default
    Given the plugin command "deliver"
    Then it contains:
      | **build_order**                |
      | --build-order                  |
      | No **build_order**: `all-first` |

  Scenario: deliver builds the feature and creates a branch on the default branch
    Given the plugin command "deliver"
    Then it contains:
      | bdd/<story-slug>  |
      | **feature-builder** |
      | No **feature-builder**: build it yourself |

  Scenario: implement stops at red for the right reason and points to deliver
    Given the plugin command "implement"
    Then it contains:
      | red for the right reason |
      | /bdd:deliver             |
      | bdd/<story-slug>         |

  Scenario: implement no longer builds the feature
    Given the plugin command "implement"
    Then it does not contain:
      | Building the feature                      |
      | No **feature-builder**: build it yourself |

  Scenario: The README says deliver builds the feature and implement does not
    Given the README
    Then it contains:
      | build_order |
    And it does not contain:
      | `/bdd:implement` and `/bdd:deliver` write the step definitions and the support code, run the scenarios, and build the feature |
      | Implement step definitions and build the feature |
