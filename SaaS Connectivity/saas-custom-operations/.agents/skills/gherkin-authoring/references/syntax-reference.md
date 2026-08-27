# Gherkin Syntax Reference

Complete Gherkin syntax for feature files and BDD specifications.

## File Structure

### Feature File (.feature)

```gherkin
# language: en
@feature-tag
Feature: Feature Name
  As a <role>
  I want <goal>
  So that <benefit>

  Background:
    Given <common setup>

  Rule: Business Rule Name

    @scenario-tag
    Scenario: Scenario Name
      Given <precondition>
      When <action>
      Then <outcome>

    Scenario Outline: Parameterized Scenario
      Given <precondition with <param>>
      When <action with <param>>
      Then <outcome with <param>>

      Examples: Example Set Name
        | param  |
        | value1 |
        | value2 |
```

## Keywords

### Primary Keywords

| Keyword | Purpose | Usage |
| --- | --- | --- |
| `Feature` | Declares a feature | Once per file, at top |
| `Rule` | Groups scenarios by business rule | Optional, multiple allowed |
| `Background` | Common setup for all scenarios | Once per Feature/Rule |
| `Scenario` | Defines a test case | Multiple per feature |
| `Scenario Outline` | Parameterized scenario | With Examples table |
| `Examples` | Data table for Scenario Outline | Required with Outline |

### Step Keywords

| Keyword | Purpose | Order |
| --- | --- | --- |
| `Given` | Establish preconditions | First (setup) |
| `When` | Describe action under test | Middle (action) |
| `Then` | Assert expected outcome | Last (assertion) |
| `And` | Continue previous step type | After Given/When/Then |
| `But` | Negative continuation | After Given/When/Then |
| `*` | Wildcard (any step type) | Any position |

### Keyword Localization

Gherkin supports multiple languages:

```gherkin
# language: es
Característica: Autenticación de usuario
  Escenario: Inicio de sesión exitoso
    Dado un usuario registrado
    Cuando el usuario ingresa credenciales válidas
    Entonces el usuario accede al sistema
```

Common language codes: `en`, `es`, `fr`, `de`, `pt`, `ja`, `zh-CN`

## Step Patterns

### Simple Steps

```gherkin
Given a user exists
When the user logs in
Then the dashboard is displayed
```

### Parameterized Steps

```gherkin
Given a user with email "test@example.com"
When the user enters password "secret123"
Then the message "Welcome back!" is displayed
```

### Numeric Parameters

```gherkin
Given the cart contains 5 items
When the user removes 2 items
Then the cart contains 3 items
```

### Doc Strings (Multi-line Text)

```gherkin
Given the following JSON payload:
  """json
  {
    "name": "John Doe",
    "email": "john@example.com"
  }
  """
When the API receives the request
Then the user is created
```

Doc string delimiters: `"""` or `\`\`\``

### Data Tables

```gherkin
Given the following users exist:
  | name  | email            | role  |
  | Alice | alice@test.com   | admin |
  | Bob   | bob@test.com     | user  |
  | Carol | carol@test.com   | user  |
When I request the user list
Then I see 3 users
```

### Combining Tables and Doc Strings

```gherkin
Scenario: Create multiple users from JSON
  Given the API is available
  When I POST to "/users" with:
    """json
    [
      {"name": "Alice", "role": "admin"},
      {"name": "Bob", "role": "user"}
    ]
    """
  Then the response contains:
    | name  | role  |
    | Alice | admin |
    | Bob   | user  |
```

## Scenario Outline

### Basic Structure

```gherkin
Scenario Outline: Validate email format
  Given an email field
  When I enter "<email>"
  Then the validation result is "<result>"

  Examples:
    | email              | result  |
    | valid@example.com  | valid   |
    | invalid-email      | invalid |
    | @missing.com       | invalid |
```

### Multiple Example Sets

```gherkin
Scenario Outline: User permissions
  Given a user with role "<role>"
  When the user accesses "<resource>"
  Then access is "<access>"

  Examples: Admin Access
    | role  | resource      | access  |
    | admin | settings      | granted |
    | admin | user-list     | granted |
    | admin | audit-logs    | granted |

  Examples: User Access
    | role | resource      | access |
    | user | settings      | denied |
    | user | user-list     | denied |
    | user | own-profile   | granted |
```

### Placeholder Syntax

Placeholders use angle brackets: `<placeholder_name>`

```gherkin
Given a product with price <price>
When the discount of <discount>% is applied
Then the final price is <final_price>

Examples:
  | price | discount | final_price |
  | 100   | 10       | 90          |
  | 50    | 20       | 40          |
```

## Tags

### Tag Syntax

```gherkin
@tag-name
@tag_with_underscore
@tag123
```

### Tag Placement

```gherkin
@feature-level
Feature: Tagged Feature

  @rule-level
  Rule: Tagged Rule

    @scenario-level @multiple-tags
    Scenario: Tagged Scenario
      ...

    @outline-level
    Scenario Outline: Tagged Outline
      ...

      @examples-level
      Examples:
        ...
```

### Tag Inheritance

Tags are inherited downward:

- Feature tags → apply to all Scenarios
- Rule tags → apply to all Scenarios in Rule
- Scenario Outline tags → apply to all Examples

### Common Tag Patterns

```gherkin
# Priority
@critical @high @medium @low

# Test type
@smoke @regression @e2e @integration @unit

# State
@wip @pending @skip @manual

# Non-functional
@security @performance @accessibility @i18n

# Environment
@dev @staging @prod

# Sprint/Release
@sprint-42 @v2.0 @release-candidate
```

## Background

### Purpose

Shared setup for all scenarios in a Feature or Rule.

### Syntax

```gherkin
Feature: Shopping Cart

  Background:
    Given a customer is logged in
    And the store is open

  Scenario: Add item
    When the customer adds item to cart
    Then cart has 1 item

  Scenario: Empty cart
    Given the cart has items
    When the customer empties cart
    Then cart is empty
```

### Background with Rule

```gherkin
Feature: E-commerce

  Background:
    Given the store is available

  Rule: Cart Management

    Background:
      Given a customer is logged in

    Scenario: Add to cart
      ...

  Rule: Guest Checkout

    Scenario: Guest adds to cart
      Given a guest user
      ...
```

## Rule Keyword

### Purpose

Groups scenarios by business rule for better organization.

### Syntax

```gherkin
Feature: Account Management

  Rule: Password Requirements

    Scenario: Password too short
      ...

    Scenario: Password missing special character
      ...

  Rule: Account Lockout

    Background:
      Given a user with valid credentials

    Scenario: Lock after 3 failed attempts
      ...

    Scenario: Unlock after 30 minutes
      ...
```

## Comments

```gherkin
# This is a comment
Feature: Commented Feature
  # Comments can appear anywhere

  Scenario: Example
    # Before steps
    Given something
    # Between steps
    When action
    Then result
```

## Escape Characters

### In Strings

```gherkin
When I enter "He said \"Hello\""
Then the message contains "Line 1\nLine 2"
```

### In Data Tables

```gherkin
Given the following data:
  | escaped_pipe | value   |
  | a \| b       | correct |
  | c \| d       | correct |
```

## Language Declaration

### At File Level

```gherkin
# language: de
Funktionalität: Benutzeranmeldung
  Szenario: Erfolgreiche Anmeldung
    Angenommen ein registrierter Benutzer existiert
    Wenn der Benutzer gültige Anmeldedaten eingibt
    Dann ist der Benutzer angemeldet
```

## Complete Example

```gherkin
# language: en
@e-commerce @checkout
Feature: Shopping Cart Checkout
  As a customer
  I want to checkout my shopping cart
  So that I can purchase products

  Background:
    Given the store is online
    And the payment gateway is available

  Rule: Cart Validation

    @happy-path
    Scenario: Checkout with valid cart
      Given a customer with items in cart
      When the customer proceeds to checkout
      Then the order summary is displayed

    @negative
    Scenario: Cannot checkout empty cart
      Given a customer with empty cart
      When the customer tries to checkout
      Then an error message "Cart is empty" is shown

  Rule: Payment Processing

    @payment @critical
    Scenario Outline: Process payment
      Given a customer ready to pay
      And the order total is <amount>
      When the customer pays with <method>
      Then the payment status is "<status>"

      Examples: Successful Payments
        | amount | method      | status    |
        | 100.00 | credit_card | completed |
        | 50.00  | paypal      | completed |

      Examples: Failed Payments
        | amount   | method      | status  |
        | 10000.00 | credit_card | declined |
```
