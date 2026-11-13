@readme @public
Feature: The README is written for a public repository

  Decision (2026-11-13): The README no longer says the repository is private, and it has no Access paragraph. Why: the repo goes public. This replaces the 2026-11-12 decision that the README says it is private for now.
  Decision (2026-11-13): No tracked text file names the trial project. Why: the rule is to keep project names out of this repo, and an audit before going public found eight files.

  Scenario: The README no longer says the repository is private
    Given the README
    Then it does not contain:
      | private for now                          |
      | read access                              |
      | ssh-agent                                |
      | gh auth setup-git                        |
      | only works once the repository is public |
      | **Access.**                              |

  Scenario: The README still shows the one-line install and the clone form
    Given the README
    Then it contains:
      | curl -sL https://raw.githubusercontent.com/godrose/bdd-skills/main/install.sh |
      | git clone https://github.com/godrose/bdd-skills.git                           |

  Scenario: No tracked text file names the trial project
    Given the tracked text files of the repo
    Then none of them names the trial project
