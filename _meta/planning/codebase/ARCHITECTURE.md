# Architecture

**Analysis Date:** 2026-02-22

## Pattern Overview

**Overall:** Rails Monolith with Modular Controller Structure

**Key Characteristics:**
- MVC (Model-View-Controller) pattern with Rails conventions
- Resource-oriented routes with category-based controller inheritance
- Domain-specific services for complex business logic (PointService, NotificationService)
- Database-backed session management using CurrentAttributes
- Polymorphic relationships for flexible associations (Likes, Notifications, PointTransactions)
- Full-text search using SQLite FTS5 virtual tables
- Turbo Streams for real-time UI updates

## Layers

**Model Layer (Domain + Data):**
- Purpose: Data representation and validation, business logic enforcement
- Location: `app/models/`
- Contains: ActiveRecord models with validations, enums, associations, callbacks
- Depends on: Rails ActiveRecord, bcrypt (password hashing)
- Used by: Controllers, Services, other models
- Key models: User, Post, Comment, Like, SkillPack, PointTransaction, Notification

**Service Layer (Business Logic):**
- Purpose: Encapsulate complex operations not tied to a single model
- Location: `app/services/`
- Contains: PointService (point calculation, level-up logic), NotificationService (notification creation)
- Depends on: Models
- Used by: Models (via callbacks), Controllers

**Controller Layer (Request Handling):**
- Purpose: Handle HTTP requests, route to appropriate actions, render responses
- Location: `app/controllers/`
- Contains: Resource controllers for posts, comments, authentication, admin operations
- Depends on: Models, Services, Rails ActionController
- Pattern:
  - Base class with shared behavior: `ApplicationController` (authentication), `PostsBaseController` (category-specific posts)
  - Category-specific controllers inherit from `PostsBaseController`: BlogsController, TutorialsController, etc.
  - Admin controllers inherit from `Admin::BaseController` with admin authorization checks
  - Turbo Stream responses for AJAX interactions

**View Layer (Presentation):**
- Purpose: HTML rendering, form display, component partials
- Location: `app/views/`
- Technology: ERB templates, Tailwind CSS, Stimulus JS, Turbo Frames/Streams
- Organized by controller: `posts/`, `comments/`, `admin/`, etc.
- Shared partials: `shared/` for navigation, headers, footers
- Uses: Rails view helpers, custom helpers from `app/helpers/`

**Authentication Layer (Concern):**
- Purpose: Session management, user authentication, authorization
- Location: `app/controllers/concerns/authentication.rb`
- Pattern: Module included in ApplicationController
- Methods: `restore_authentication`, `require_authentication`, `resume_session`, `start_new_session_for`, `terminate_session`
- Uses: Session model, Current attributes, signed cookies

## Data Flow

**Post Creation Flow:**

1. User submits form to PostsBaseController#create
2. Controller builds post with category from current user
3. Post validates (title, body, slug)
4. Post#save triggers after_create callback: `award_points`
5. PointService.award creates PointTransaction record, increments user.points
6. PointService checks level-up threshold, updates user.level if needed
7. Controller redirects to post URL

**Notification Flow:**

1. Comment created with after_create callbacks
2. Comment#send_notifications calls NotificationService.comment_created
3. NotificationService.notify creates Notification record (skips if self)
4. NotificationService.comment_replied creates second notification if reply
5. NotificationsController#index fetches user.notifications.recent
6. View displays by notification_type (new_comment, comment_reply, post_liked, etc.)

**Like Flow:**

1. LikesController#create finds or creates Like record for likeable (Post or Comment)
2. Like#save triggers after_create callbacks
3. Like#award_points_to_author awards points to content author
4. Like#send_notification calls NotificationService.liked
5. Response renders turbo_stream replacing like button partial

**Search Flow:**

1. SearchController#index receives query parameter
2. FTS5 query: SELECT rowid FROM posts_fts WHERE posts_fts MATCH ?
3. If no FTS5 matches, fallback to LIKE search on title, slug, ActionText body
4. Results paginated with pagy gem
5. SearchController#suggestions returns JSON for autocomplete (5 results)

**Download Flow:**

1. User accesses SkillPacksController#download (requires authentication)
2. Download record created via polymorphic Download model
3. Redirect to rails_blob_path for file download (Active Storage)
4. IP address captured in Download record
5. PointTransaction created for download action

**State Management:**

- Session: User stored in Current class via ActiveSupport::CurrentAttributes
- Sessions table: Tracks user_agent, ip_address, one row per login
- Cookies: signed permanent cookie with session_id (httponly, same_site: :lax)
- Current.user: Delegated from Current.session
- Current.session: Set during restore_authentication, cleared on logout

## Key Abstractions

**Post (Multi-Category):**
- Purpose: Single model representing content across 6 categories (blog, tutorial, free_board, qna, portfolio, notice)
- Examples: `app/models/post.rb`, `app/controllers/posts_base_controller.rb`
- Pattern: Enum category field, controllers inherit from PostsBaseController and override `category` method
- Routes: `/blogs/:id`, `/tutorials/:id`, etc., all map to same Post model with different category filter

**Likeable (Polymorphic):**
- Purpose: Allow likes on multiple content types without separate join tables
- Examples: Post, Comment both have `has_many :likes, as: :likeable`
- Pattern: Like model with `belongs_to :likeable, polymorphic: true`
- Uses: `likes_count` counter cache, uniqueness constraint on (user_id, likeable_type, likeable_id)

**Notifiable (Polymorphic):**
- Purpose: Create notifications for various events without tight coupling
- Examples: Notification#notifiable can be Comment, Like, User
- Pattern: `belongs_to :notifiable, polymorphic: true, optional: true`
- Service-driven: NotificationService methods handle creation with proper actor/subject

**PointablePolymorphic):**
- Purpose: Track point awards across different actions
- Examples: PointTransaction#pointable can be Post, Comment, Like
- Pattern: `belongs_to :pointable, polymorphic: true, optional: true`
- Service-driven: PointService.award creates transaction with pointable reference

## Entry Points

**Web Route:**
- Location: `config/routes.rb`
- Root: `GET /` → PagesController#home
- Session: `GET /new_session` → SessionsController#new, `POST /session` → SessionsController#create
- Posts: `GET /blogs`, `GET /tutorials`, `GET /qnas/:id` etc.

**Admin Route:**
- Location: `config/routes.rb` namespace :admin block
- Root: `GET /admin` → Admin::DashboardController#index (requires admin role)
- Resources: posts, users, skill_packs, inquiries, landing_sections with CRUD

**OmniAuth Route:**
- Location: `GET /auth/:provider/callback` → OmniAuth::SessionsController#create
- Supports: Google OAuth2, Kakao OAuth2
- Sets up ConnectedService, creates/updates user, starts session

**Background Jobs:**
- Location: `app/jobs/` (if needed)
- Configured via solid_queue gem (database-backed)

## Error Handling

**Strategy:**
- Model validation errors bubbled to controller
- Controller rescues via render with status :unprocessable_entity
- User-friendly alerts/notices in redirects
- Authorization checks in controller before_actions

**Patterns:**

1. **Authorization:**
   ```ruby
   # app/controllers/posts_base_controller.rb
   before_action :authorize_post!, only: %i[edit update destroy]

   def authorize_post!
     unless @post.user == Current.user || Current.user&.admin?
       redirect_to root_path, alert: "권한이 없습니다."
     end
   end
   ```

2. **Admin Check:**
   ```ruby
   # app/controllers/admin/base_controller.rb
   before_action :require_admin!

   def require_admin!
     unless Current.user&.admin?
       redirect_to root_path, alert: "관리자만 접근할 수 있습니다."
     end
   end
   ```

3. **Not Found Rescue:**
   ```ruby
   # app/controllers/skill_packs_controller.rb
   @skill_pack = SkillPack.published.find_by!(download_token: params[:download_token])
   # find_by! raises ActiveRecord::RecordNotFound → 404
   ```

4. **Validation Feedback:**
   ```ruby
   # app/controllers/posts_base_controller.rb
   if @post.save
     redirect_to url_for_post(@post), notice: "글이 작성되었습니다."
   else
     render "posts/new", status: :unprocessable_entity
   end
   ```

## Cross-Cutting Concerns

**Logging:** Rails default logger (config/environments/), log file at `log/development.log`

**Validation:**
- Model-level: `validates :title, presence: true`
- Custom scopes: `scope :published, -> { where(status: :published) }`
- Counter caches: `counter_cache: true` on associations

**Authentication:**
- Concern at `app/controllers/concerns/authentication.rb`
- Before-action: `allow_unauthenticated_access only: %i[index show]`
- Require authentication by default, skip selectively

**Authorization:**
- User role enum: `enum :role, { member: 0, admin: 1 }`
- Helper: `Current.user&.admin?`
- Controller checks: `require_admin!` in Admin::BaseController

---

*Architecture analysis: 2026-02-22*
