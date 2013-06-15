Feature: Database interface
In order to make user data relevant and accessible
I want to be able to access and mutate db records effectively

Scenario: Add new user
Given Username "fake_user" is not in the database
When I add user "fake_user" to the database
Then The user exists check should return "true"


Scenario: Ignore user
Given Username "fake_user" exists
When I execute the ignore_user method on "fake_user"
Then is_ignored check on "fake_user" should return true


Scenario: Delete user
Given Username "fake_user" exists
When I execute the delete_user method on "fake_user"
Then the user exists check should return "false"

Scenario: Followup query returns accurate data
Given I execute a followup_query
When I query each result for additional info
Then Each result should obey config file rules