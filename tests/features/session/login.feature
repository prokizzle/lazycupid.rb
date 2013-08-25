Feature: Login Handler
In order to ensure proper okcupid login
I want to be able to be able to initiate sessions and detect successes or failures

@login
Scenario: Login with valid credentials
When I login with a valid credentials
Then I should get login status "Logged in"

@login
Scenario: Login with invalid credentials
When I login with invalid credentials
Then I should get login status "Incorrect username or password"

@login
Scenario: Login with deleted account
When I login with an account that has been deleted
Then I should get login status "Account has been deleted"

@login
Scenario: Login with deactivated account
When I login with an account that has been deactivated
Then I should get login status "Account has been deactivated"

@login @captcha
Scenario: User needs to enter CAPTCHA to login
When I login with a valid credentials
And a CAPTCHA is present
Then I should get login status "Recaptcha has been detected. Login via browser first"