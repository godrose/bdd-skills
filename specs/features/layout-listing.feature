@layout
Feature: The directory listing shows a README, an icon and a licence

  Users get only the plugin folder. The listing README, the icon and the licence copy are
  inside it.

  Decision (2026-11-11): The permissions note sits with the listing README. Why: the maintainer groups had no home for it.

  Scenario: The listing README has enough words of its own
    Given the listing README
    Then it has at least 40 words outside code blocks

  Scenario: The listing README links the project on GitHub
    Given the listing README
    Then it contains "https://github.com/godrose/bdd-skills"

  Scenario: The listing README says what the commands do about permissions
    Given the listing README
    Then it contains:
      | ## Tool permissions |
      | known-gaps.md       |
      | pre-approve nothing |
    And it does not contain "pre-approve `Bash`"

  Scenario: The listing icon meets the portal's rules
    Given the listing icon
    Then it is a PNG
    And it is square
    And it is between 512 and 2048 pixels on each side
    And it is under 2 MB

  Scenario: The plugin carries its own copy of the licence
    Given the plugin licence copy
    Then it is identical to the root licence
