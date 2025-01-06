Feature: Exposing endpoint with a custom domain

  Scenario: Calling an unsecured API endpoint with custom domain
    Given there is a httpbin service
    Given there is an unsecured endpoint
    Then calling the "/headers" endpoint without a token should result in status between 200 and 299
    And calling the "/headers" endpoint with any token should result in status between 200 and 299
    And teardown httpbin service

  Scenario: Calling a secured API with OAuth2 with custom domain
    Given there is a httpbin service
    Given endpoint is secured with OAuth2
    Then calling the "/headers" endpoint without a token should result in status between 400 and 403
    And calling the "/headers" endpoint with an invalid token should result in status between 400 and 403
    And calling the "/headers" endpoint with a valid token should result in status between 200 and 299
    And teardown httpbin service
