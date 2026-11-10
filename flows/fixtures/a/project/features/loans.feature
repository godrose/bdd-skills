Feature: Loans

  Scenario: A loan older than 14 days is marked overdue
    Given a member borrowed a book 15 days ago
    When the nightly check runs
    Then the loan status is "overdue"
