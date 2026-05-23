# Coding Conventions

**Analysis Date:** 2026-02-22

## Naming Patterns

**Files:**
- Controllers: snake_case (e.g., `posts_base_controller.rb`, `registrations_controller.rb`)
- Models: singular snake_case (e.g., `user.rb`, `post.rb`, `skill_pack.rb`)
- Services: snake_case with `_service` suffix (e.g., `point_service.rb`, `notification_service.rb`)
- Mailers: snake_case with `_mailer` suffix (e.g., `passwords_mailer.rb`, `application_mailer.rb`)
- Modules/Concerns: PascalCase when acting as modules (e.g., `Authentication`, `ApplicationHelper`)
- Test helpers: snake_case with `_test_helper` suffix (e.g., `session_test_helper.rb`)

**Functions/Methods:**
- Controllers: verb_noun in snake_case (`create`, `update`, `authorize_post!`, `set_post`)
- Private methods: underscore prefix convention not used; instead rely on `private` keyword
- Boolean methods: end with `?` (e.g., `admin?`, `liked_by?(user)`, `authenticated?`)
- Helper methods exposed to views: explicitly declared with `helper_method` in controller

**Variables:**
- Local variables: snake_case (`@user`, `@posts`, `@category`, `current_user`)
- Instance variables: `@` prefix in controllers and models (e.g., `@post`, `@pagy`)
- Constants: UPPER_SNAKE_CASE (e.g., `POINTS`, `LEVEL_THRESHOLDS`)

**Types/Models:**
- ActiveRecord models: PascalCase, singular (e.g., `User`, `Post`, `Comment`, `SkillPack`)
- Enums: lowercase symbols (e.g., `:admin`, `:member`, `:published`, `:draft`)
- Scopes: verb_noun in snake_case (e.g., `published`, `pinned_first`, `unread`, `recent`)

## Code Style

**Formatting:**
- Tool: RuboCop with `rubocop-rails-omakase` base configuration
- Config: `.rubocop.yml` at project root inherits Omakase defaults
- Line length: Not explicitly overridden; follows Omakase defaults
- Comments: Written in Korean (한글) for domain-specific logic

**Linting:**
- Tool: RuboCop via `rubocop-rails-omakase` gem
- Rules: Omakase preset enforces Rails conventions
- Enabled rules: Standard Rails naming, spacing, length checks
- Customization: Config file is minimal, relying on inherited defaults

## Import Organization

**Order:**
1. Standard library imports (none typically in Rails)
2. Gem imports (via `include`, `extend`, `has_many`, etc.)
3. Local module includes (via `include Authentication`)

**Pattern in Controllers:**
```ruby
class BlogsController < PostsBaseController
  # Inherits from parent
  private
  def category = :blog
end
```

**Pattern in Models:**
```ruby
class Post < ApplicationRecord
  has_secure_password
  has_many :comments, dependent: :destroy
  has_many :likes, as: :likeable, dependent: :destroy

  enum :category, { blog: 0, tutorial: 1, free_board: 2, qna: 3, portfolio: 4, notice: 5 }
  enum :status, { draft: 0, published: 1 }

  validates :title, presence: true, length: { maximum: 200 }

  scope :published, -> { where(status: :published) }

  before_save :generate_slug, if: -> { slug.blank? && title.present? }
end
```

**Path Aliases:**
Not explicitly used; Rails routing handles URL paths via `send()` in helpers.

## Error Handling

**Pattern - Validation:**
Models use standard ActiveRecord validation syntax:
```ruby
validates :nickname, presence: true, length: { maximum: 30 }
validates :email_address, presence: true, uniqueness: true
```

**Pattern - Authorization:**
Controllers check permissions in `before_action` callbacks:
```ruby
before_action :authorize_post!, only: %i[edit update destroy]

def authorize_post!
  unless @post.user == Current.user || Current.user&.admin?
    redirect_to root_path, alert: "권한이 없습니다."
  end
end
```

**Pattern - Authentication:**
Implemented via `Authentication` concern module in `app/controllers/concerns/authentication.rb`:
```ruby
def require_authentication
  resume_session || request_authentication
end

def request_authentication
  session[:return_to_after_authenticating] = request.url
  redirect_to new_session_path
end
```

**Pattern - Rescue/Fallback:**
Search controller demonstrates fallback logic:
- Primary: FTS5 full-text search
- Secondary: LIKE pattern matching on title/slug/body text

## Logging

**Framework:** Ruby standard `Rails.logger` (implicit)

**Patterns:**
- Explicit logging not found in core business logic
- Rails transaction logs capture all database operations
- Mailer preview available at `/rails/mailers/passwords_mailer`

## Comments

**When to Comment:**
- Complex business logic with domain rules
- Service class methods explaining point/notification logic
- Comments are written in Korean

**Example from `point_service.rb`:**
```ruby
# 활동별 포인트 설정
POINTS = {
  post_created: 10,
  comment_created: 3,
  liked_received: 2,
  download_skill_pack: 1,
  daily_login: 1,
  level_up_bonus: 20
}.freeze

# 일일 로그인 포인트 (당일 첫 로그인만)
def self.award_daily_login(user)
  return if PointTransaction.where(user: user, action_type: :daily_login)
                            .where("created_at >= ?", Time.current.beginning_of_day)
                            .exists?
end
```

**JSDoc/TSDoc:**
Not applicable in Rails Ruby codebase.

## Function Design

**Size:**
- Service class methods: Single responsibility, typically 10-20 lines
- Controller actions: 5-15 lines, delegating complex logic to services or models
- Model callbacks: Short and focused on domain operations

**Parameters:**
- Methods use keyword arguments for clarity:
  ```ruby
  def self.award(action_type, user:, pointable: nil, description: nil)
  ```
- Service methods accept named parameters to reduce coupling

**Return Values:**
- Services return created records or nil for chained operations
- Controllers redirect or render templates
- Scopes return relations for chaining

**Example - Service Pattern:**
```ruby
class PointService
  def self.award(action_type, user:, pointable: nil, description: nil)
    new.award(action_type, user: user, pointable: pointable, description: description)
  end

  def award(action_type, user:, pointable: nil, description: nil)
    amount = POINTS[action_type.to_sym]
    return unless amount

    PointTransaction.create!(
      user: user,
      amount: amount,
      action_type: action_type,
      pointable: pointable,
      description: description || default_description(action_type)
    )

    user.increment!(:points, amount)
    check_level_up(user)
  end
end
```

## Module Design

**Exports:**
- Service classes expose class methods for public API: `PointService.award(...)`
- Models expose instance methods and scopes: `Post.published`, `post.liked_by?(user)`
- Concerns are included in controllers: `include Authentication`

**Barrel Files:**
Not used; Rails autoloading handles file discovery via convention.

**Concern Pattern:**
Used for cross-cutting controller logic:
```ruby
module Authentication
  extend ActiveSupport::Concern

  included do
    before_action :restore_authentication
    before_action :require_authentication
    helper_method :authenticated?
  end

  class_methods do
    def allow_unauthenticated_access(**options)
      skip_before_action :require_authentication, **options
    end
  end

  private
    def authenticated?
      resume_session
    end
end
```

**Applied in Controllers:**
```ruby
class ApplicationController < ActionController::Base
  include Authentication
  include Pagy::Method
end

class PostsBaseController < ApplicationController
  allow_unauthenticated_access only: %i[index show]
end
```

---

*Convention analysis: 2026-02-22*
