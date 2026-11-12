@repo
Feature: The repo protects itself

  Housekeeping that keeps the repo safe to change: CI, the pull request template,
  owners, dependency updates, portable scripts, and an index of the decisions.

  Scenario: CI runs the suite as a job named "check", on pushes and on pull requests
    Given the CI workflow
    Then it runs on pushes
    And it runs on pull requests
    And it has a job named "check"
    And it checks out the repository
    And it runs the test suite

  Scenario: The pull request template asks this repo's own questions
    Given the pull request template
    Then it has a summary section
    And it asks whether the test suite is green
    And it asks whether the tests failed before the change
    And it asks for no project names in the diff
    And it asks for no session links
    And it has a box for release pull requests

  Scenario: The repo has an owner for every file
    Given the code owners file
    Then it makes "godrose" the owner of every file

  Scenario: GitHub Actions are kept up to date, weekly
    Given the Dependabot configuration
    Then it keeps the GitHub Actions up to date
    And it checks every week

  Scenario: No script uses sed in a way that fails on Linux
    Given the shell scripts of the tests, the installer and the plugin
    Then none of them uses sed -i with an empty suffix

  Scenario: The contributor guide describes releasing as a release pull request
    Given the contributor guide
    Then it has a releasing section
    And it no longer has the pre-launch section
    And it no longer says that every change needs a version bump

  Scenario: CI runs the release checks only for pull requests titled "release:"
    Given the CI workflow
    Then it runs the release check only for pull requests whose title starts with "release:"

  Scenario: The README says releases are tagged, and points to the changelog
    Given the README
    Then it does not say that every merge is a new version
    And it points to the changelog

  Scenario: Every discovery pack is listed in the docs index
    Given the docs index
    Then every discovery pack is listed in it
