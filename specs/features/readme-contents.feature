@readme
Feature: The README's Contents links go somewhere

  Scenario: Every heading link in the README points at a heading that exists
    Given the README
    Then every heading link in it points at a level 2 or 3 heading

  Scenario: The README links Related projects, Contributing and License in its Contents
    Given the README
    Then it contains:
      | - [Related projects](#related-projects) |
      | - [Contributing](#contributing)         |
      | - [License](#license)                   |
