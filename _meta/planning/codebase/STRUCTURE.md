# Codebase Structure

**Analysis Date:** 2026-02-22

## Directory Layout

```
teovibe/
├── app/                        # Application code
│   ├── models/                 # ActiveRecord models
│   ├── controllers/            # Request handlers
│   ├── views/                  # ERB templates
│   ├── helpers/                # View helpers
│   ├── services/               # Business logic (PointService, NotificationService)
│   ├── jobs/                   # Background jobs (solid_queue)
│   ├── mailers/                # Email handlers
│   ├── channels/               # WebSocket channels (Action Cable)
│   ├── assets/                 # CSS, JS, images
│   └── javascript/             # JavaScript modules
├── config/                     # Rails configuration
│   ├── routes.rb               # URL routing
│   ├── environments/           # Environment-specific config
│   ├── initializers/           # Gem initialization
│   └── database.yml            # Database connection
├── db/                         # Database
│   ├── migrate/                # Migration files
│   ├── seeds.rb                # Seed data
│   ├── schema.rb               # Database schema
│   └── structure.sql           # SQL schema (for FTS5)
├── public/                     # Static files served by web server
├── storage/                    # Active Storage (file uploads)
├── test/                       # Tests (Minitest)
│   ├── models/                 # Model tests
│   ├── controllers/            # Controller tests
│   ├── fixtures/               # Test data
│   └── test_helpers/           # Custom test helpers
├── lib/                        # Custom utilities and concerns
├── vendor/                     # Third-party code
└── Gemfile                     # Ruby gem dependencies

```

## Directory Purposes

**app/models/:**
- Purpose: Data models with validation, associations, business logic
- Contains: 15 model files
- Key files:
  - `user.rb`: User account with role enum, sessions, posts, comments
  - `post.rb`: Content with 6 categories, rich text body, polymorphic likes
  - `comment.rb`: Nested comments (parent_id), likes, point awards
  - `like.rb`: Polymorphic, counter_cache, notifications
  - `notification.rb`: User notifications (new_comment, post_liked, level_up, etc.)
  - `point_transaction.rb`: Point history with action_type enum
  - `skill_pack.rb`: Downloadable resources (template, component, guide, toolkit)
  - `inquiry.rb`: Contact form submissions (status: pending/replied/closed)
  - `session.rb`: Session tracking (user_agent, ip_address)
  - `application_record.rb`: Base class for all models

**app/controllers/:**
- Purpose: Handle HTTP requests, business logic orchestration
- Contains: 28 controller files
- Structure:
  - `application_controller.rb`: Base with authentication concern
  - `posts_base_controller.rb`: Shared logic for all post categories
  - Category controllers (inherit PostsBase): `blogs_controller.rb`, `tutorials_controller.rb`, `qnas_controller.rb`, `portfolios_controller.rb`, `notices_controller.rb`, `free_boards_controller.rb`
  - `comments_controller.rb`: Create/destroy with Turbo Stream responses
  - `likes_controller.rb`: Polymorphic likes (posts, comments)
  - `skill_packs_controller.rb`: Browsing and download logic
  - `notifications_controller.rb`: User notification center
  - `rankings_controller.rb`: User leaderboard by points
  - `search_controller.rb`: FTS5 search + LIKE fallback
  - `profiles_controller.rb`: User profile view/edit, points history
  - `sessions_controller.rb`: Login/logout
  - `registrations_controller.rb`: Signup
  - `passwords_controller.rb`: Password reset
  - `inquiries_controller.rb`: Contact form submission
  - `pages_controller.rb`: Static pages (home, about, consulting)
  - `feeds_controller.rb`: RSS/Atom feed
  - `admin/base_controller.rb`: Admin authorization base
  - `admin/posts_controller.rb`: Admin post management
  - `admin/users_controller.rb`: Admin user management
  - `admin/skill_packs_controller.rb`: Admin skill pack management
  - `admin/inquiries_controller.rb`: Admin inquiry response
  - `admin/landing_sections_controller.rb`: Admin landing page sections
  - `admin/section_cards_controller.rb`: Admin section card management
  - `omniauth/sessions_controller.rb`: OAuth2 callback handler
- Concerns: `concerns/authentication.rb` with session management

**app/views/:**
- Purpose: HTML templates for all pages
- Contains: 26 view directories + 1 shared directory
- Structure by resource:
  - `posts/`: index, show, new, edit, _post.html.erb
  - `admin/`: dashboard, posts, users, skill_packs, inquiries, landing_sections
  - `comments/`: _comment.html.erb, _form.html.erb (Turbo streams)
  - `likes/`: _button.html.erb (Turbo stream partial)
  - `pages/`: home.html.erb, about.html.erb, consulting.html.erb
  - `layouts/`: application.html.erb, admin.html.erb, mailer.html.erb
  - `shared/`: Navigation, headers, footers shared across pages
  - `sessions/`: new.html.erb (login form)
  - `registrations/`: new.html.erb (signup form)
  - `notifications/`: index.html.erb (notification center)
  - `skill_packs/`: index.html.erb, show.html.erb
  - `search/`: index.html.erb (search results)
  - `rankings/`: index.html.erb (leaderboard)
  - Mailer templates: `passwords_mailer/`, `inquiry_mailer/`

**app/services/:**
- Purpose: Encapsulate business logic not tied to single model
- Key files:
  - `point_service.rb`: Award points, check level-up, point transactions
  - `notification_service.rb`: Create notifications for comments, likes, level-ups

**app/helpers/:**
- Purpose: View helpers for template logic
- Key files:
  - `application_helper.rb`: `url_for_post(post)` helper for polymorphic routes
  - `seo_helper.rb`: SEO meta tags

**config/routes.rb:**
- Purpose: URL routing configuration
- Structure:
  - Resource routes for posts by category: `/blogs`, `/tutorials`, `/qnas`, etc.
  - Polymorphic routes: `resources :comments, :likes` nested under posts/comments
  - Admin namespace: `/admin` with admin authorization
  - OmniAuth routes: `/auth/:provider/callback`
  - Static pages: `/about`, `/consulting`
  - Health check: `/up`
  - Root: `/` → PagesController#home

**db/migrate/:**
- Purpose: Database schema changes
- Key migrations:
  - `20260218053552_create_users.rb`: Users table with role enum
  - `20260218053558_add_fields_to_users.rb`: Add points, level, nickname columns
  - `20260218053910_create_posts.rb`: Posts with category enum, rich text
  - `20260218053911_create_comments.rb`: Comments with parent_id for nesting
  - `20260218053912_create_likes.rb`: Polymorphic likes table
  - `20260218053913_create_landing_sections.rb`: Landing page sections
  - `20260218054008_create_active_storage_tables.active_storage.rb`: File uploads
  - `20260218054009_create_action_text_tables.action_text.rb`: Rich text editor
  - `20260218062916_create_skill_packs.rb`: Downloadable resources
  - `20260218062921_create_downloads.rb`: Download tracking
  - `20260218063223_create_inquiries.rb`: Contact form submissions
  - `20260218063451_create_point_transactions.rb`: Point transaction history
  - `20260218063719_create_notifications.rb`: User notifications
  - `20260218063734_create_posts_fts5.rb`: Full-text search table

**db/schema.rb:**
- Purpose: Current database structure reference
- Format: ActiveRecord schema definition (SQL-based)
- Note: Structure uses `structure.sql` for FTS5 virtual table support

**test/:**
- Purpose: Automated testing
- Contains: Minitest (Rails default)
- Key files:
  - `test_helper.rb`: Fixture setup, parallel test workers
  - `models/user_test.rb`: User model tests (email normalization)
  - `controllers/sessions_controller_test.rb`: Session/auth tests
  - `controllers/passwords_controller_test.rb`: Password reset tests
  - `test_helpers/session_test_helper.rb`: `sign_in_as()` helper for tests
  - `fixtures/`: YAML files for model fixtures (users, posts, comments)

**config/:**
- Purpose: Application configuration
- Key files:
  - `routes.rb`: URL routing
  - `database.yml`: SQLite database path
  - `environments/development.rb`: Dev logging, asset serving
  - `environments/production.rb`: Production settings
  - `environments/test.rb`: Test database
  - `initializers/`: Gem setup (omniauth, pagy, sitemap_generator, etc.)
  - `application.rb`: Rails 8.1 load defaults, SQL schema format

**public/:**
- Purpose: Static files (images, stylesheets, JS)
- Generated: favicon, robots.txt, 404/500 error pages

## Key File Locations

**Entry Points:**
- `config/routes.rb`: All URL routes defined here
- `app/controllers/application_controller.rb`: Base controller with authentication

**Configuration:**
- `config/database.yml`: SQLite database path
- `Gemfile`: Ruby gem dependencies
- `.rubocop.yml`: Code style linting
- `config/initializers/`: Gem initialization (omniauth, pagy, etc.)

**Core Logic:**
- `app/models/post.rb`: Post creation with 6 categories
- `app/models/user.rb`: User model with role enum
- `app/services/point_service.rb`: Point calculation and level-ups
- `app/services/notification_service.rb`: Notification creation
- `app/controllers/posts_base_controller.rb`: Shared post CRUD logic

**Testing:**
- `test/test_helper.rb`: Test setup and fixtures
- `test/test_helpers/session_test_helper.rb`: Session helpers
- `test/fixtures/`: YAML data files for tests

## Naming Conventions

**Files:**
- Controllers: `snake_case_controller.rb` (e.g., `posts_base_controller.rb`, `blogs_controller.rb`)
- Models: `singular_snake_case.rb` (e.g., `user.rb`, `post.rb`)
- Services: `snake_case_service.rb` (e.g., `point_service.rb`)
- Views: `snake_case.html.erb` (e.g., `show.html.erb`, `_post.html.erb`)
- Migrations: `YYYYMMDDHHMMSS_description.rb` (timestamp-based)
- Tests: `snake_case_test.rb` (e.g., `user_test.rb`)

**Directories:**
- Controllers: Plural by resource: `controllers/blogs_controller.rb`, etc.
- Models: Singular: `models/post.rb`
- Views: Plural by controller: `views/posts/`, `views/comments/`
- Services: Plural: `services/`
- Admin namespace: `admin/` subdirectory in both controllers and views

**Classes:**
- Models: PascalCase (e.g., `User`, `Post`, `PointService`)
- Controllers: PascalCase + "Controller" (e.g., `BlogsController`)
- Nested admin: Module + PascalCase (e.g., `Admin::PostsController`)
- Concerns: PascalCase (e.g., `Authentication`)

## Where to Add New Code

**New Feature (Domain Logic):**
- Primary code: `app/models/[model].rb` - define associations, validations
- Business logic: `app/services/[feature]_service.rb` - complex operations
- Tests: `test/models/[model]_test.rb` - model unit tests
- Migrations: `db/migrate/YYYYMMDDHHMMSS_create_[table].rb`

**New Controller/Route:**
- If post category: Inherit from `PostsBaseController`, override `category` method
- If admin feature: Inherit from `Admin::BaseController` (auto admin check)
- Routes: Add to `config/routes.rb` (resources or namespace)
- Authorization: Add before_action checks in controller

**New View/Template:**
- ERB file: `app/views/[controller]/[action].html.erb`
- Shared partial: `app/views/shared/_component_name.html.erb`
- Mailer template: `app/views/[mailer_name]/[action].text.erb` + `.html.erb`
- Use: `<%= render 'shared/component', locals: { var: value } %>`

**New Model Validations:**
- Add to model: `validates :field, presence: true, length: { maximum: 200 }`
- Enum field: `enum :status, { draft: 0, published: 1 }`
- Association: `belongs_to :user`, `has_many :comments`

**New Service Method:**
- Create `app/services/[name]_service.rb`
- Class method for entry point: `self.action_name(args)`
- Call from model callback: `after_create :trigger_action`
- Example: `PointService.award(:post_created, user: user)`

**Utilities/Helpers:**
- Model helpers: Add to `app/helpers/application_helper.rb`
- Concern (shared behavior): Add to `app/controllers/concerns/[concern].rb`
- Included in controller: `include [Concern]` in ApplicationController

## Special Directories

**app/channels/:**
- Purpose: WebSocket connections (Action Cable)
- Generated: Present but not currently used
- Committed: Yes

**app/jobs/:**
- Purpose: Background jobs
- Generated: Present, empty
- Using: solid_queue gem (database-backed job queue)
- Committed: Yes

**app/assets/:**
- Purpose: Rails asset pipeline (CSS, JS, images)
- Sub-dirs: `stylesheets/`, `images/`, `javascripts/`
- Committed: Yes

**app/javascript/:**
- Purpose: ES6 modules, Stimulus controllers
- Contains: Hotwire Stimulus JS
- Committed: Yes

**storage/:**
- Purpose: Active Storage cache (file uploads)
- Generated: Yes (created at runtime)
- Committed: No (in .gitignore)

**log/:**
- Purpose: Application log files
- Files: `development.log`, `production.log`, `test.log`
- Generated: Yes (created at runtime)
- Committed: No (in .gitignore)

**tmp/:**
- Purpose: Temporary files, caches
- Generated: Yes (created at runtime)
- Committed: No (in .gitignore)

---

*Structure analysis: 2026-02-22*
