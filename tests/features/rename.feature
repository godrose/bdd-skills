Feature: The repo is named bdd-skills

  The repo was renamed from bdd to bdd-skills. The old name must not come back in a file
  that people read to install or find the plugin. The docs keep it, because they record history.

  Scenario: The old repo name is nowhere outside the docs
    Given the files of the repo, apart from the docs and the installed dependencies
    Then none of them names the repo by its old name

  Scenario: The README tells a reader that the repo and the plugin are named differently
    Then the README tells a reader the repo is bdd-skills and the plugin is bdd

  Scenario Outline: A place that points to the repo points to the new one
    Then <place> points to the repo bdd-skills

    Examples:
      | place                        |
      | the README install command   |
      | the installer                |
      | the plugin manifest          |
      | the init command's source line |
