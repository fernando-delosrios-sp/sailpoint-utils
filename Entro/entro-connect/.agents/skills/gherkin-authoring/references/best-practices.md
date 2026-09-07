# Gherkin Best Practices

BDD best practices for writing effective, maintainable Gherkin specifications.

## Core Principles

### 1. Behavior, Not Implementation

Focus on **what** the system does, not **how** it does it.

**Good - Behavior-focused:**

```gherkin
Scenario: User authenticates successfully
  Given a registered user
  When the user provides valid credentials
  Then the user is granted access
```

**Bad - Implementation-focused:**

```gherkin
Scenario: User authenticates successfully
  Given a user record exists in the users table
  When the user POSTs to /api/auth with JSON body
  Then the response code is 200
  And a JWT token is in the response body
```

### 2. Single Behavior Per Scenario

Each scenario should test exactly one behavior.

**Good - One behavior:**

```gherkin
Scenario: Add item to cart
  Given an empty cart
  When the customer adds a product
  Then the cart contains 1 item
```

**Bad - Multiple behaviors:**

```gherkin
Scenario: Shopping workflow
  Given an empty cart
  When the customer adds a product
  Then the cart contains 1 item
  When the customer proceeds to checkout
  Then the order form is displayed
  When the customer completes payment
  Then the order is confirmed
```

### 3. Declarative Over Imperative

Describe outcomes, not step-by-step procedures.

**Good - Declarative:**

```gherkin
Scenario: Search finds matching products
  Given the catalog contains matching products
  When the customer searches for "laptop"
  Then matching products are displayed
```

**Bad - Imperative:**

```gherkin
Scenario: Search finds matching products
  Given the customer is on the home page
  And the customer clicks the search icon
  And the customer types "laptop" in the search field
  And the customer presses Enter
  Then the search results page loads
  And the results contain "laptop"
```

## Writing Effective Steps

### Given Steps (Arrange)

Establish the context and preconditions.

**Guidelines:**

- Set up the "world" before the action
- Use past tense or present state
- Keep setup focused on what matters for the scenario
- Hide irrelevant setup details

**Patterns:**

```gherkin
# State establishment
Given a registered user
Given the product catalog contains 10 items
Given the user has admin privileges

# Named fixtures
Given a user "Alice" with role "manager"
Given an order "ORD-001" with status "pending"

# Quantified state
Given the cart contains 3 items
Given 5 products are in stock
```

### When Steps (Act)

Describe the action or event being tested.

**Guidelines:**

- One primary action per When
- Use present tense
- Focus on the user's action, not system internals
- Keep it simple and direct

**Patterns:**

```gherkin
# User actions
When the user submits the form
When the customer adds the product to cart
When the admin approves the request

# System events
When the payment is processed
When the timer expires
When the file is uploaded
```

### Then Steps (Assert)

Verify the expected outcomes.

**Guidelines:**

- Assert observable outcomes
- Be specific about what should happen
- Avoid testing implementation details
- Focus on user-visible results

**Patterns:**

```gherkin
# State verification
Then the order status is "confirmed"
Then the cart contains 2 items
Then the user is redirected to the dashboard

# Message verification
Then a success message is displayed
Then an email is sent to the user
Then the error "Invalid input" is shown

# Negation
Then no error is displayed
Then the item is not in the cart
```

### And/But Steps

Continue the previous step type logically.

**Guidelines:**

- Use And for additional conditions of same type
- Use But for negative conditions or exceptions
- Don't overuse - keep scenarios concise

**Patterns:**

```gherkin
# Additional preconditions
Given a registered user
And the user has verified their email
And the user has accepted the terms

# Additional assertions
Then the order is confirmed
And a confirmation email is sent
But the inventory is not updated yet
```

## Background Best Practices

### When to Use Background

**Good uses:**

- Common login/authentication state
- Standard data setup needed by all scenarios
- Environmental preconditions

**Avoid when:**

- Setup differs between scenarios
- Background would be more than 3-4 lines
- Setup is only needed by some scenarios

### Keep Background Minimal

```gherkin
Feature: Shopping Cart

  # Good - minimal, common setup
  Background:
    Given a logged-in customer
    And the store is open

  Scenario: Add item
    ...
  Scenario: Remove item
    ...
```

### Don't Hide Important Context

If a precondition is important for understanding the scenario, keep it in the scenario:

```gherkin
# Better - context is visible
Scenario: Premium member gets discount
  Given a premium member with active subscription
  When the member adds a product to cart
  Then a 10% discount is applied
```

## Scenario Outline Best Practices

### When to Use Scenario Outline

**Good for:**

- Same logic with different inputs
- Boundary testing (min, max, edge cases)
- Error message variations
- Multiple valid configurations

**Avoid when:**

- Scenarios have fundamentally different flows
- Only 1-2 examples (use separate scenarios)
- Examples obscure the behavior

### Organize Examples Logically

```gherkin
Scenario Outline: Validate password strength
  When the user enters password "<password>"
  Then the validation result is "<result>"

  Examples: Valid passwords
    | password       | result |
    | Str0ng!Pass    | valid  |
    | C0mpl3x#Pwd    | valid  |

  Examples: Too short
    | password | result  |
    | Ab1!     | invalid |
    | Xy2@     | invalid |

  Examples: Missing requirements
    | password   | result  |
    | lowercase  | invalid |
    | UPPERCASE  | invalid |
    | NoSpecial1 | invalid |
```

### Use Descriptive Placeholders

```gherkin
# Good - clear meaning
Given a user with role "<role>"
When the user accesses "<resource>"
Then access is "<expected_access>"

# Bad - unclear meaning
Given a user with "<x>"
When the user does "<y>"
Then "<z>" happens
```

## Tagging Strategy

### Tag Categories

```gherkin
# Priority
@critical @high @medium @low

# Test type
@smoke @regression @e2e @integration

# Feature area
@authentication @checkout @search @profile

# State
@wip @pending @manual @flaky

# Non-functional
@security @performance @accessibility

# Environment
@requires-database @requires-api @slow
```

### Tag Placement

```gherkin
@checkout @e2e
Feature: Checkout Process

  @smoke @critical
  Scenario: Complete checkout with valid payment
    ...

  @negative @validation
  Scenario: Checkout fails with invalid card
    ...

  @slow @requires-payment-gateway
  Scenario Outline: Multiple payment methods
    ...
```

### Tag Inheritance

Tags cascade down:

- Feature tags apply to all scenarios
- Rule tags apply to scenarios in that rule
- Scenario Outline tags apply to all examples

## Data Tables Best Practices

### Use Tables for Structured Data

```gherkin
# Good - structured data
Given the following products exist:
  | name    | price | category    |
  | Laptop  | 999   | Electronics |
  | Shirt   | 29    | Clothing    |

# Good - vertical table for single entity
Given a product with:
  | name     | Gaming Laptop   |
  | price    | 1299            |
  | category | Electronics     |
  | stock    | 50              |
```

### Keep Tables Readable

```gherkin
# Use consistent alignment
| name     | email              | role    |
| Alice    | alice@example.com  | admin   |
| Bob      | bob@example.com    | user    |
| Charlie  | charlie@test.com   | manager |

# Use meaningful headers
| username | password    | expected_result |
| valid    | Valid123!   | success         |
| invalid  | short       | failure         |
```

## Doc Strings Best Practices

### Use for Multi-line Content

```gherkin
# Good - JSON payload
When I send a POST request with:
  """json
  {
    "name": "New Product",
    "price": 99.99,
    "category": "Electronics"
  }
  """

# Good - expected response
Then the response body contains:
  """
  Thank you for your order.
  Your order number is: ORD-12345
  """
```

### Specify Content Type

```gherkin
# JSON
"""json
{ "key": "value" }
"""

# XML
"""xml
<root><element>value</element></root>
"""

# SQL
"""sql
SELECT * FROM users WHERE active = true
"""
```

## Anti-Patterns to Avoid

### 1. UI Coupling

**Bad:**

```gherkin
When I click the blue "Submit" button in the footer
Then the modal with id "success-modal" appears
```

**Good:**

```gherkin
When I submit the form
Then a success message is displayed
```

### 2. Technical Jargon

**Bad:**

```gherkin
When the HTTP POST returns 201
And the response contains JWT with exp claim
```

**Good:**

```gherkin
When the registration completes
Then the user receives authentication credentials
```

### 3. Incidental Details

**Bad:**

```gherkin
Given it is Monday, January 15, 2024 at 2:30 PM EST
And the user has ID 12345
And the session timeout is 30 minutes
```

**Good:**

```gherkin
Given a logged-in user
```

### 4. Long Scenarios

**Bad:**

```gherkin
Scenario: Complete user journey
  Given a new visitor
  When the visitor views the home page
  And the visitor clicks "Sign Up"
  And the visitor enters email "test@example.com"
  And the visitor enters password "Test123!"
  And the visitor clicks "Register"
  Then the confirmation page appears
  When the visitor checks their email
  And the visitor clicks the confirmation link
  Then the account is activated
  When the visitor logs in
  And the visitor navigates to profile
  # ... 20 more steps
```

**Good:** Split into focused scenarios or use higher-level steps.

### 5. Hardcoded Values

**Bad:**

```gherkin
Given a user with email "john.smith@company.com"
And password "SuperSecret123!"
```

**Good:**

```gherkin
Given a registered user with valid credentials
```

## Language and Readability

### Use Domain Language

```gherkin
# E-commerce domain
Given an active shopping cart
When the customer proceeds to checkout
Then the order summary is displayed

# Healthcare domain
Given a patient with an active prescription
When the pharmacist dispenses the medication
Then the prescription status updates to "filled"
```

### Third Person Perspective

```gherkin
# Preferred - third person
Given a customer is logged in
When the customer adds an item to cart

# Also acceptable - first person (for user stories)
Given I am logged in
When I add an item to cart
```

### Consistent Tense

```gherkin
# Given - past or present state
Given a user exists
Given the user is authenticated

# When - present tense
When the user submits the form

# Then - present or future
Then the confirmation appears
Then the user will be redirected
```

## Reqnroll (.NET) Specific Practices

### Step Definition Organization

```csharp
// Group by feature
[Binding]
public class ShoppingCartSteps { }

// Use dependency injection
public class CheckoutSteps
{
    private readonly ScenarioContext _context;
    private readonly ICartService _cartService;

    public CheckoutSteps(ScenarioContext context, ICartService cartService)
    {
        _context = context;
        _cartService = cartService;
    }
}
```

### Use Hooks Appropriately

```csharp
[BeforeScenario]
public void SetupTestData() { }

[AfterScenario]
public void CleanupTestData() { }

[BeforeScenario("@database")]
public void SetupDatabase() { }
```

### Context Sharing

```csharp
// Store in ScenarioContext
_context["user"] = createdUser;

// Retrieve from context
var user = _context.Get<User>("user");
```

## Maintenance Guidelines

### Review Regularly

- Remove obsolete scenarios
- Update language as domain evolves
- Consolidate duplicate scenarios
- Remove flaky or unreliable scenarios

### Version Control Practices

- Commit feature files with related code changes
- Review scenarios in pull requests
- Track scenario coverage

### Documentation

- Keep feature descriptions current
- Document complex Background setups
- Explain non-obvious tag usage
