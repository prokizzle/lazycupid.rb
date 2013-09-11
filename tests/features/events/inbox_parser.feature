Feature: Inbox Scraper
In order to ensure I can track all incoming messages
I want to be make sure my regular expressions and CSS selectors survive site upgrades

@inbox @scraper
Scenario: Total inbox messages works
When I am on the messages page
Then the "total messages" regular expression should return an integer