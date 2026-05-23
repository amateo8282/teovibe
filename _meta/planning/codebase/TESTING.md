# Testing Patterns

**Analysis Date:** 2026-02-22

## Test Framework

**Runner:**
- Rails built-in test framework (Minitest)
- Version: Implicit in Rails 8.1.2 (uses Minitest 5.x)
- Config: `test/test_helper.rb`

**Assertion Library:**
- ActiveSupport::TestCase (built-in Rails assertions)
- Integration tests inherit from ActionDispatch::IntegrationTest

**Run Commands:**
```bash
rails test                    # Run all tests
rails test test/models        # Run model tests only
rails test test/controllers   # Run controller tests only
rails test test/integration   # Run integration tests only
rails test --verbose          # Verbose output
```

## Test File Organization

**Location:**
- Tests are co-located with production code but in separate `test/` directory
- Structure mirrors `app/` directory

**Naming:**
- Model tests: `test/models/{model_name}_test.rb`
- Controller tests: `test/controllers/{controller_name}_test.rb`
- Integration tests: `test/integration/{feature_name}_test.rb`
- Mailer tests: `test/mailers/` with previews in `test/mailers/previews/`
- Test helpers: `test/test_helpers/{helper_name}_test_helper.rb`

**Structure:**
```
test/
├── controllers/
│   ├── sessions_controller_test.rb
│   └── passwords_controller_test.rb
├── fixtures/
│   ├── users.yml
│   └── [other fixtures]
├── helpers/
├── integration/
├── mailers/
│   └── previews/
│       └── passwords_mailer_preview.rb
├── models/
│   └── user_test.rb
├── test_helpers/
│   └── session_test_helper.rb
└── test_helper.rb
```

## Test Structure

**Suite Organization:**
```ruby
require "test_helper"

class UserTest < ActiveSupport::TestCase
  test "downcases and strips email_address" do
    user = User.new(email_address: " DOWNCASED@EXAMPLE.COM ")
    assert_equal("downcased@example.com", user.email_address)
  end
end
```

**Integration Test Organization:**
```ruby
require "test_helper"

class SessionsControllerTest < ActionDispatch::IntegrationTest
  setup { @user = User.take }

  test "new" do
    get new_session_path
    assert_response :success
  end

  test "create with valid credentials" do
    post session_path, params: { email_address: @user.email_address, password: "password" }
    assert_redirected_to root_path
    assert cookies[:session_id]
  end

  test "destroy" do
    sign_in_as(User.take)
    delete session_path
    assert_redirected_to root_path
    assert_empty cookies[:session_id]
  end
end
```

**Patterns:**
- Setup phase: `setup { ... }` block executed before each test
- Test naming: `test "human readable name"` for readability
- Assertions: Use Rails conventions like `assert_response`, `assert_redirected_to`, `assert_enqueued_email_with`
- Redirect testing: `follow_redirect!` to chain assertions on next page

## Mocking

**Framework:**
- Rails ActionMailer queuing and assertions: `assert_enqueued_email_with`
- Fixtures for database objects (auto-loaded from `test/fixtures/*.yml`)

**Patterns:**
From `test/controllers/passwords_controller_test.rb`:
```ruby
test "create" do
  post passwords_path, params: { email_address: @user.email_address }
  assert_enqueued_email_with PasswordsMailer, :reset, args: [ @user ]
  assert_redirected_to new_session_path
end
```

From `test/mailers/previews/passwords_mailer_preview.rb`:
```ruby
class PasswordsMailerPreview < ActionMailer::Preview
  def reset
    PasswordsMailer.reset(User.take)
  end
end
```

**What to Mock:**
- Email delivery: Use `assert_enqueued_email_with` for ActionMailer assertions
- Time-based changes: `assert_changes` for state transitions

**What NOT to Mock:**
- Database operations: Use fixtures and real queries
- Model associations: Test through actual relationship queries
- Controller responses: Test with real HTTP verbs and redirects

## Fixtures and Factories

**Test Data:**
Fixtures stored in `test/fixtures/` as YAML files. Example:
```yaml
# test/fixtures/users.yml
john:
  email_address: john@example.com
  nickname: john_user
  role: member

admin_user:
  email_address: admin@example.com
  nickname: admin
  role: admin
```

**Access in Tests:**
```ruby
setup { @user = User.take }  # Get first fixture
```

Or via fixture name:
```ruby
@user = users(:john)
```

**Location:**
- `test/fixtures/` - YAML files auto-loaded for all tests
- Naming: Plural of model name (e.g., `users.yml`, `posts.yml`)

**Strategy:**
- Rails auto-loads all fixtures matching model names
- Fixtures are transaction-wrapped; changes don't persist between tests
- Referenced via test class: `ActionDispatch::TestCase` loads fixtures automatically

## Coverage

**Requirements:**
- No explicit coverage thresholds enforced in config
- Tests focus on critical paths and model validations

**View Coverage:**
Most tests are integration (HTTP) tests for controllers:
```ruby
test "create with invalid credentials" do
  post session_path, params: { email_address: @user.email_address, password: "wrong" }
  assert_redirected_to new_session_path
  assert_nil cookies[:session_id]
end
```

**Helper Assertions:**
Custom test helpers in `test/test_helpers/session_test_helper.rb`:
```ruby
module SessionTestHelper
  def sign_in_as(user)
    Current.session = user.sessions.create!
    ActionDispatch::TestRequest.create.cookie_jar.tap do |cookie_jar|
      cookie_jar.signed[:session_id] = Current.session.id
      cookies["session_id"] = cookie_jar[:session_id]
    end
  end

  def sign_out
    Current.session&.destroy!
    cookies.delete("session_id")
  end
end
```

Applied in tests:
```ruby
test "destroy" do
  sign_in_as(User.take)
  delete session_path
  assert_redirected_to root_path
end
```

## Test Types

**Unit Tests (Model Tests):**
- Location: `test/models/`
- Scope: Test model validations, associations, scopes
- Example from `test/models/user_test.rb`:
  ```ruby
  test "downcases and strips email_address" do
    user = User.new(email_address: " DOWNCASED@EXAMPLE.COM ")
    assert_equal("downcased@example.com", user.email_address)
  end
  ```
- Approach: Fast, focused on single responsibility

**Integration Tests (Controller Tests):**
- Location: `test/controllers/`
- Scope: Test request/response cycle, redirects, authentication flows
- Example from `test/controllers/sessions_controller_test.rb`:
  ```ruby
  test "create with valid credentials" do
    post session_path, params: { email_address: @user.email_address, password: "password" }
    assert_redirected_to root_path
    assert cookies[:session_id]
  end
  ```
- Approach: Full HTTP request simulation, test view rendering implicitly

**System/E2E Tests:**
- Framework: Not currently implemented (Capybara + Selenium available in Gemfile but no tests written)
- Gem available: `capybara`, `selenium-webdriver` in `:test` group

## Common Patterns

**Async Testing:**
Email assertions for async jobs:
```ruby
test "create" do
  post passwords_path, params: { email_address: @user.email_address }
  assert_enqueued_email_with PasswordsMailer, :reset, args: [ @user ]
end
```

**State Change Assertions:**
```ruby
test "update" do
  assert_changes -> { @user.reload.password_digest } do
    put password_path(@user.password_reset_token), params: { password: "new", password_confirmation: "new" }
  end
end
```

**No-Change Assertions:**
```ruby
test "update with non matching passwords" do
  token = @user.password_reset_token
  assert_no_changes -> { @user.reload.password_digest } do
    put password_path(token), params: { password: "no", password_confirmation: "match" }
  end
end
```

**Selector-based Assertions:**
From `test/controllers/passwords_controller_test.rb`:
```ruby
def assert_notice(text)
  assert_select "div", /#{text}/
end
```

**Parallel Test Execution:**
Configured in `test/test_helper.rb`:
```ruby
module ActiveSupport
  class TestCase
    parallelize(workers: :number_of_processors)
    fixtures :all
  end
end
```

## Test Configuration

**test_helper.rb:**
- Location: `test/test_helper.rb`
- Loads Rails test environment
- Configures fixtures (auto-load all YAML files)
- Enables parallel test workers
- Includes test helpers via `require_relative "test_helpers/session_test_helper"`

**test.rb Environment:**
- Location: `config/environments/test.rb`
- Eager loading: Only if CI=present env var
- Cache store: `:null_store` (no caching in test)
- Action Mailer: `:test` delivery method (accumulates in array)
- CSRF protection: Disabled for tests
- Session cookies: Encrypted with `.signed` accessor

**Mailer Configuration:**
```ruby
config.action_mailer.delivery_method = :test
config.action_mailer.default_url_options = { host: "example.com" }
```

## Test Coverage Assessment

**Tested Areas:**
- User email normalization: `test/models/user_test.rb`
- Session authentication flow: `test/controllers/sessions_controller_test.rb`
- Password reset flow: `test/controllers/passwords_controller_test.rb`
- Email delivery: `assert_enqueued_email_with` pattern

**Gaps:**
- Model associations (Comment, Like, Post relationships) - not explicitly tested
- Service layer (PointService, NotificationService) - not explicitly tested
- Authorization logic in controllers - not comprehensively tested
- Search controller with FTS5 - not tested
- Admin controllers - not tested
- Mailer content/templates - only preview available, no content assertion

---

*Testing analysis: 2026-02-22*
