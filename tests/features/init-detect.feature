@plugin-text
Feature: The init command copies the template and, with --detect, proposes values before it writes

  These scenarios read the text of the command. They check what it says and run nothing.

  Decision (2026-11-11): The checks of tests/test_plugin.sh move here and none is added. Why: a migration adds no checks.
  Decision (2026-11-11): The init basics sit in this file, not in a file of their own. Why: the builder asked for ten files.

  Scenario: The init command copies the template, never overwrites and does not fill in
    Given the plugin command "init"
    Then it contains:
      | "${CLAUDE_PLUGIN_ROOT}"/bdd-config.template.md |
      | never overwrite                                |
      | does not fill in                               |
      | run, triage or reconcile                       |

  Scenario: Detect proposes first and writes only what is approved
    Given the plugin command "init"
    Then it contains:
      | --detect                                    |
      | "AskUserQuestion"                           |
      | "Edit"                                      |
      | never change a row that already has a value |
      | still in `<...>` form                       |
      | Do not run the project's commands           |
      | writes nothing until                        |
      | evidence                                    |
      | confidence                                  |
      | unknown                                     |
      | full path                                   |
      | never an abbreviation                       |
      | ask which                                   |
      | CI workflow                                 |
      | another platform                            |
      | _(not needed                                |
      | Do not guess                                |

  Scenario: Detect searches the feature files for tag rows and says what it searched
    Given the plugin command "init"
    Then it contains:
      | count how often each tag is used                     |
      | in the `.feature` files                              |
      | Do not report a tag row as unknown without searching |
      | name the files you searched                          |
      | does not exist                                       |
      | not found in a project file is your own suggestion   |
      | literal glob                                         |
      | never a value in `<...>` form                        |

  Scenario: Step 1 counts the two role rows, so a config with only those placeholders gets proposals
    Given the plugin command "init"
    Then it contains "or the two placeholder roles in the Skill Roles table"
