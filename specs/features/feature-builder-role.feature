@skills-text @feature-builder
Feature: deliver and implement build the feature, and a company skill can do it

  Decision (2026-11-13): The checks are contracts between files and one reversed decision, not phrases of prose. Why: the approach review of 2026-11-12.
  Decision (2026-11-13): implement no longer says it handles execution only, and the README no longer says implement does not build the feature. Why: both builders now build the feature. This replaces the line of the README added in 2026-11-13 (#94).

  Scenario: The config template has an optional feature-builder role
    Given the file "plugin/bdd-config.template.md"
    Then it contains "| feature-builder | `<your-feature-builder-skill>` | no |"

  Scenario Outline: The <command> command names the feature-builder role and its default
    Given the plugin command "<command>"
    Then it contains:
      | **feature-builder**                    |
      | No **feature-builder**: build it yourself |

    Examples:
      | command   |
      | implement |
      | deliver   |

  Scenario: implement no longer handles execution only
    Given the plugin command "implement"
    Then it does not contain:
      | execution only |

  Scenario: The README no longer says implement does not build the feature
    Given the README
    Then it does not contain:
      | It does not build the feature |
