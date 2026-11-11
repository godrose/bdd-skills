@plugin-text
Feature: The plugin text uses plugin names and paths, and tells the user what to do without the log script

  These scenarios read files and text. They check what the files say and run nothing.

  Decision (2026-11-11): The checks of tests/test_plugin.sh move here and none is added. Why: a migration adds no checks.
  Decision (2026-11-11): The path and skill-name checks are outlines with one literal per row. Why: the old file used two regular expressions over fixed names, so a substring check is equal.
  Decision (2026-11-11): bdd-implement is checked by its own step that allows bdd-implement-scenario. Why: the old check removed that old install name before it looked.
  Decision (2026-11-11): The group steps read deliver.md again, and the deliver scenarios stay. Why: the group is the old check, and the deliver files already exist.
  Decision (2026-11-11): The template has its own em-dash scenario beside the repo-wide scan. Why: it is a separate old check, and the template is copied into user projects.

  Scenario Outline: The plugin text has no project-install path: <text>
    Given the commands, agents and config template of the plugin
    Then none of them contains "<text>"

    Examples:
      | text             |
      | .claude/scripts/ |
      | .claude/schemas/ |

  Scenario Outline: The plugin text has no project-install skill name: <text>
    Given the commands, agents and config template of the plugin
    Then none of them contains "<text>"

    Examples:
      | text          |
      | bdd-discover  |
      | bdd-design    |
      | bdd-run       |
      | bdd-triage    |
      | bdd-reconcile |
      | bdd-deliver   |
      | bdd-verifier  |

  Scenario: The implement name appears only inside the old install name
    Given the commands, agents and config template of the plugin
    Then none of them mentions "bdd-implement" except as part of "bdd-implement-scenario"

  Scenario Outline: The <command> command calls the decisions script by its plugin path
    Given the plugin command "<command>"
    Then it contains:
      | "${CLAUDE_PLUGIN_ROOT}"/scripts/decisions.sh |

    Examples:
      | command   |
      | design    |
      | triage    |
      | reconcile |

  Scenario Outline: The <command> command says the decision log script is not part of the plugin
    Given the plugin command "<command>"
    Then it contains:
      | > Plugin note:                                    |
      | the decision log script is not part of the plugin |

    Examples:
      | command   |
      | design    |
      | triage    |
      | reconcile |

  Scenario Outline: The <command> command tells the user to run init when the config is missing
    Given the plugin command "<command>"
    Then it contains "> Plugin note: if `.claude/bdd-config.md` is missing, tell the user to run `/bdd:init`"

    Examples:
      | command   |
      | design    |
      | implement |
      | run       |
      | triage    |
      | reconcile |

  Scenario: Without the script, design and triage go on without records and reconcile stops
    Given the plugin command "design"
    Then it contains "Nothing was recorded"
    Given the plugin command "triage"
    Then it contains:
      | Nothing was recorded  |
      | go on without records |
    Given the plugin command "reconcile"
    Then it contains "and stop"

  Scenario: The config template has no em-dash
    Given the file "plugin/bdd-config.template.md"
    Then it has no em-dash
