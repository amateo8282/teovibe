# Codebase Concerns

**Analysis Date:** 2026-02-22

## Tech Debt

**Minimal Test Coverage:**
- Issue: Only 3 test files exist for a multi-feature Rails application
- Files: `teovibe/test/controllers/passwords_controller_test.rb` only (3 total test files)
- Impact: Critical business logic in services, models, and controllers lacks test protection. New changes risk undetected regressions, especially in point system, notifications, and user authentication flows.
- Fix approach: Establish TDD discipline. Create test suite for core domains: User authentication (OmniAuth, password reset), Point system (award, level-up logic), Notification system (triggers, deliverability), Comment/Like operations, Admin authorization. Target: 70%+ coverage for domain logic.

**FTS5 Index Not Synced with ActionText Body:**
- Issue: Search uses FTS5 triggers on raw `posts.body` column, but actual post content is stored in `action_text_rich_texts.body` table via ActionText
- Files: `teovibe/db/migrate/20260218063734_create_posts_fts5.rb`, `teovibe/app/controllers/search_controller.rb`
- Impact: FTS5 index is empty/stale for post content, search fallback to LIKE query on `action_text_rich_texts` works but FTS optimization is wasted; misleading search logic flow
- Fix approach: Update migration to join and index ActionText body content. Or store denormalized body in posts table for FTS. Consider: is FTS needed if LIKE fallback works? Profile before optimizing.

**Slug Generation Race Condition:**
- Issue: `Post#generate_slug` and `SkillPack#generate_slug` use `Post.maximum(:id).to_i + 1` outside transaction, vulnerable to ID collision under concurrent creates
- Files: `teovibe/app/models/post.rb` line 57-60, `teovibe/app/models/skill_pack.rb` line 36-38
- Impact: Two simultaneous POST requests can generate identical slugs, violating uniqueness constraint and failing creates
- Fix approach: Use SecureRandom for slug component instead of ID prediction. Example: `"#{SecureRandom.hex(4)}-#{title.parameterize}"`. Or use database-level sequence/AUTOINCREMENT guarantee.

**Missing Validation for Duplicate Downloads:**
- Issue: Download deduplication relies on `find_or_create_by(user: Current.user)` but no model-level validation
- Files: `teovibe/app/controllers/skill_packs_controller.rb` line 43-46, `teovibe/app/models/download.rb`
- Impact: If controller logic bypassed (direct API call, race condition), duplicate downloads could be recorded, inflating download counts
- Fix approach: Add `validates :user_id, uniqueness: { scope: :skill_pack_id }` to Download model (already exists in code line 14 of download.rb, but verify it's enforced).

**Counter Cache Corruption Risk:**
- Issue: Multiple `increment!` calls on User points, post views, comment likes without transaction safety
- Files: `teovibe/app/controllers/posts_base_controller.rb` line 17, `teovibe/app/services/point_service.rb` line 44, 69
- Impact: Under high concurrency, counter values can drift. Example: two users liking same post simultaneously may result in `likes_count=1` instead of `2`
- Fix approach: Wrap increment operations in database transactions. Use `User.transaction { user.increment!(:points, amount) }`. Add monitoring/audits to detect skew.

**OmniAuth Test Mode Hardcoded:**
- Issue: Development environment creates mock OAuth responses in initializer without external dependency check
- Files: `teovibe/config/initializers/omniauth.rb` line 19-42
- Impact: Test mode is always active unless real OAuth credentials present. This masks potential OAuth integration bugs until production. Mock credentials are hardcoded (obvious security smell, though not production-exposed).
- Fix approach: Separate test fixtures from config. Use environment-specific test user factory instead of inline mocks. Document OAuth credential setup requirement.

**Admin Access Control Not Enforced in BaseController:**
- Issue: `Admin::BaseController#require_admin!` uses `Current.user&.admin?` but Current.user depends on session cookie
- Files: `teovibe/app/controllers/admin/base_controller.rb` line 8-11
- Impact: If Current.user is nil (session expired/invalid), admin check fails gracefully with redirect. However, no rate limiting on failed attempts. Brute force attacks on admin URLs are not throttled.
- Fix approach: Add Rack::Attack or similar rate limiting for failed authentication attempts. Log admin access attempts.

**Point Transaction Race in Level-Up Logic:**
- Issue: `PointService#check_level_up` creates transaction record after `user.update!(level:)`, creating window where level and point_transactions are inconsistent
- Files: `teovibe/app/services/point_service.rb` line 59-71
- Impact: If level-up fails mid-execution, user level is updated but bonus transaction not created. Transaction audit trail is incomplete.
- Fix approach: Wrap entire method in `User.transaction { ... }` block. Create transaction record before updating user level.

## Known Bugs

**Notifications Sent Without Checking User Opt-Out:**
- Symptoms: All users receive notifications for all activities (comments, likes, replies) without unsubscribe option
- Files: `teovibe/app/services/notification_service.rb`, `teovibe/app/models/comment.rb` line 24-26, `teovibe/app/models/like.rb` line 20-21
- Trigger: Create comment on followed user's post
- Workaround: None. Users must tolerate all notifications.

**Comment "Accepted" Field Not Exposed in QnA Controller:**
- Symptoms: QnA posts have feature to mark answers as accepted (accept endpoint exists), but acceptance state is never displayed or used in ranking
- Files: `teovibe/app/controllers/qnas_controller.rb` (routes define accept action), but Comment model has `accepted` field (schema line 53)
- Trigger: QnA post with answers, attempt to mark best answer
- Workaround: None. Feature exists but is unused in views.

**Download Counter Not Accurate for Duplicate Downloads:**
- Symptoms: `SkillPack#downloads_count` may overcount if race condition occurs
- Files: `teovibe/app/models/skill_pack.rb` line 4 (counter_cache), `teovibe/app/controllers/skill_packs_controller.rb` line 43-46
- Trigger: Two simultaneous download requests from same user
- Workaround: Admin can manually correct counts in database.

## Security Considerations

**OmniAuth Access Token Storage Unencrypted:**
- Risk: OAuth access tokens stored in plaintext in `connected_services.access_token` column
- Files: `teovibe/app/controllers/omniauth/sessions_controller.rb` line 18, 32; `teovibe/db/migrate/20260218053909_create_connected_services.rb`
- Current mitigation: Database encryption at rest (if configured). Access tokens are read-only (not used in app yet), reducing immediate exposure.
- Recommendations: Encrypt `access_token` column using Rails `encrypt` attribute. Or remove storage if tokens are not actively used.

**Email Validation Uses Regex, Not RFC-Compliant:**
- Risk: `Inquiry` model validates email with `URI::MailTo::EMAIL_REGEXP`, which accepts some invalid formats
- Files: `teovibe/app/models/inquiry.rb` line 5
- Current mitigation: Low risk; inquiry emails are user-provided and must be responded to, so invalid format discovery is fast.
- Recommendations: Consider double opt-in (send confirmation link) before storing inquiry email. Or use gem like `email_validator`.

**Search Input Escaping Incomplete:**
- Risk: Search query sanitization removes only special characters but doesn't prevent DoS via extremely long queries
- Files: `teovibe/app/controllers/search_controller.rb` line 54-56
- Current mitigation: No query length limit enforced.
- Recommendations: Add length validation `params[:q].to_s.strip` max 500 chars before FTS query. Add timeout to FTS queries.

**Admin Dashboard Counts Unoptimized:**
- Risk: N `User.count`, `Post.count`, `Comment.count` queries on admin dashboard page load
- Files: `teovibe/app/controllers/admin/dashboard_controller.rb` line 4-6
- Current mitigation: Counts are cached by Rails default (first-pass caching). But repeated admin reloads query database.
- Recommendations: Cache counts in Redis with TTL (e.g., 5 min). Or materialized view. Monitor for dashboard abuse.

**Post View Count Incremented Without Auth Check:**
- Risk: View counter incremented unconditionally unless user is post author; no distinction between human views and bot crawlers
- Files: `teovibe/app/controllers/posts_base_controller.rb` line 17
- Current mitigation: Only incremented on HTML show page (not API), limiting bot exposure.
- Recommendations: Add User-Agent filtering to ignore crawlers. Or require JS token in view to increment (harder for bots).

## Performance Bottlenecks

**N+1 Query on Post Index (Category Board):**
- Problem: PostsBaseController index includes posts but does not preload user profile image, nickname, or post category. Each post renders author info.
- Files: `teovibe/app/controllers/posts_base_controller.rb` line 10
- Cause: `.includes(:user)` fetches user record but view likely accesses `post.user.avatar_url`, `post.user.nickname` which may trigger additional queries
- Improvement path: Verify view template. If accessing user fields, change to `.includes(:user).select("posts.*, users.id, users.nickname, users.avatar_url")` or use `.eager_load`.

**FTS Search Falls Back to LIKE on Every Miss:**
- Problem: FTS5 index is not synced with ActionText body (see Tech Debt). Every search first tries FTS, then falls back to LIKE with multi-table join.
- Files: `teovibe/app/controllers/search_controller.rb` line 8-24
- Cause: FTS index only has old post data; new posts are inserted but body is in ActionText, not posts.body
- Improvement path: Fix FTS syncing first (above). Then benchmark: does FTS provide measurable speedup? If yes, keep. If no, remove and simplify to LIKE-only.

**Dashboard Query Inefficiency:**
- Problem: Admin dashboard runs 5+ separate queries: User.count, Post.count, Comment.count, Post.includes(:user).order.limit(5), User.order.limit(5)
- Files: `teovibe/app/controllers/admin/dashboard_controller.rb`
- Cause: Each count is a full table scan. For large tables (thousands of posts), this is slow.
- Improvement path: Cache counts in Redis. Or use single aggregated query with GROUP BY if dashboard shows counts by category. Benchmark current response time first.

**Comment Threads Load All Replies Per Post:**
- Problem: PostsBaseController show action loads `@comments = @post.comments.includes(:user).where(parent_id: nil)` but does not preload replies
- Files: `teovibe/app/controllers/posts_base_controller.rb` line 18
- Cause: View likely loops through comments and renders replies, triggering N queries for N root comments
- Improvement path: Change to `.includes(:user, :replies)` to batch-load replies.

## Fragile Areas

**OmniAuth Flow with ConnectedService:**
- Files: `teovibe/app/controllers/omniauth/sessions_controller.rb`, `teovibe/app/models/connected_service.rb`, `teovibe/app/models/user.rb`
- Why fragile: Three separate object creations (User, ConnectedService, Session) in single action with no transaction. If Session.create fails after User created, orphan user exists. If ConnectedService create fails, user has no linked account.
- Safe modification: Wrap entire action in `User.transaction { ... }`. Test rollback scenarios: what if ConnectedService validation fails? Should User be deleted?
- Test coverage: Zero tests for OmniAuth flow. Tests for email signup, password reset exist, but social login untested.

**Point System Spans Multiple Models:**
- Files: `teovibe/app/services/point_service.rb`, `teovibe/app/models/post.rb`, `teovibe/app/models/comment.rb`, `teovibe/app/models/like.rb`, `teovibe/app/models/user.rb`
- Why fragile: Point award logic is scattered: `Post#award_points`, `Comment#send_notifications` (which calls PointService), `Like#award_points_to_author`. Adding new point action requires modifying multiple files and remembering to call PointService.
- Safe modification: Create `PointableListener` concern or use ActiveSupport Notifications to centralize point logic. Make PointService the single source of truth.
- Test coverage: Zero tests for point calculations. Hard to verify level thresholds are correct.

**Search Query Handling:**
- Files: `teovibe/app/controllers/search_controller.rb`
- Why fragile: Manual FTS query construction with sanitize_sql is error-prone. FTS5 syntax is picky (special chars, boolean operators). Fallback LIKE query uses COALESCE on ActionText.body which may behave unexpectedly.
- Safe modification: Use scope or helper method to encapsulate FTS logic. Document FTS query syntax assumptions.
- Test coverage: Zero tests for search. Impossible to verify search quality or regressions.

**Post/SkillPack Slug Generation:**
- Files: `teovibe/app/models/post.rb#generate_slug`, `teovibe/app/models/skill_pack.rb#generate_slug`
- Why fragile: Slug generation uses ID prediction and has fallback for non-parameterizable titles (all-Korean). If ID prediction is wrong, slug collides. No uniqueness validation before save.
- Safe modification: Use SecureRandom instead of ID prediction. Add before_validation callback that ensures uniqueness by appending suffix if needed.
- Test coverage: Zero tests for slug generation.

**Admin Authorization Pattern:**
- Files: `teovibe/app/controllers/admin/base_controller.rb`
- Why fragile: Single `require_admin!` filter for all admin routes. If accidentally removed from action, authorization disappears silently. No audit log of authorization checks.
- Safe modification: Use Pundit or similar authorization gem. Or add auth logging to require_admin!.
- Test coverage: Zero tests for admin access control.

## Scaling Limits

**SQLite Database Cannot Scale Horizontally:**
- Current capacity: File-based SQLite suitable for <50 concurrent users
- Limit: SQLite has coarse locking (entire database locked during writes). Under sustained load (100+ concurrent users), write queue grows.
- Scaling path: Migrate to PostgreSQL or MySQL. This requires schema.rb review (SQLite-specific types: `integer` instead of `bigint`, FTS5 virtual tables are SQLite-specific and must be rewritten as PostgreSQL full-text search).

**FTS5 Not Available in Production (Likely):**
- Current capacity: SQLite FTS5 works locally
- Limit: If production uses PostgreSQL, FTS5 triggers/queries must be rewritten. FTS5 is SQLite-only.
- Scaling path: Before migrating to PostgreSQL, plan FTS migration: use PostgreSQL tsvector and GIN indexes, or install PostgreSQL full-text extensions.

**Counter Cache Consistency Under High Concurrency:**
- Current capacity: Works fine for <10 writes/sec per post
- Limit: Counter cache can drift under >50 concurrent likes/comments on same post
- Scaling path: Add periodic background job to recalculate counter caches. Or use database-level triggers (PostgreSQL, MySQL) instead of Rails counter_cache.

**No Caching Layer:**
- Current capacity: Suitable for <100 concurrent users
- Limit: Every read query hits database. Admin counts query full tables.
- Scaling path: Add Redis or Memcached. Cache post listings, user profiles, dashboard counts.

## Dependencies at Risk

**Omniauth-Kakao Gem:**
- Risk: Kakao OAuth gem is community-maintained; check for security advisories
- Impact: Kakao social login breaks if gem is compromised or deprecated
- Migration plan: Maintain fallback email/password auth as primary. Kakao is optional enhancement. If gem breaks, disable in OmniAuth config and communicate to users.

**Solid Queue/Cache/Cable (Rails 8 Bundled):**
- Risk: New in Rails 8 (as of 2026), may have undiscovered bugs or scaling issues
- Impact: Job queue, caching, and WebSocket handling rely on these unproven gems
- Migration plan: Monitor GitHub issues. Have fallback plan to migrate to Sidekiq (Redis-based) if issues arise.

## Missing Critical Features

**Soft Delete Not Implemented:**
- Problem: User.destroy, Post.destroy use hard delete. Once deleted, data is lost. Comments on deleted posts are cascaded deleted (dependent: :destroy).
- Blocks: Cannot recover deleted content. Cannot maintain audit trails.
- Fix: Add `acts-as-paranoid` gem or custom `deleted_at` column. Mark soft-deleted records invisible in queries.

**Notification Unsubscribe/Preferences:**
- Problem: No way for users to opt-out of notifications or customize preferences
- Blocks: Users cannot reduce notification fatigue. Could lead to notification spam complaints.
- Fix: Add NotificationPreference model with fields: `user`, `notification_type` (enum), `enabled` (boolean). Check preference before sending.

**Audit Log for Admin Actions:**
- Problem: No record of who created/edited/deleted admin resources
- Blocks: Cannot investigate unauthorized changes. Compliance audits fail.
- Fix: Use gem like `Audited`. Or add manual `AuditLog` model with user, action, resource_type, resource_id, changes.

**Rate Limiting:**
- Problem: No rate limits on login attempts, search queries, downloads, or API endpoints
- Blocks: App is vulnerable to brute force (password guessing) and DoS (resource exhaustion).
- Fix: Add Rack::Attack or similar. Example: 5 failed logins per IP per 15 min, 100 search queries per user per hour.

**Scheduled Jobs for Maintenance:**
- Problem: No jobs for cleaning up stale sessions, recalculating counters, sending digest emails
- Blocks: Sessions table grows unbounded. Counter caches can drift. No background notifications.
- Fix: Use Solid Queue (already in Gemfile). Add jobs: `SessionCleanupJob`, `CounterRecalcJob`, `NotificationDigestJob`.

## Test Coverage Gaps

**Authentication/Authorization Flows Not Tested:**
- What's not tested: OmniAuth callback, user registration, password reset token validation, admin access checks
- Files: `teovibe/app/controllers/omniauth/sessions_controller.rb`, `teovibe/app/controllers/registrations_controller.rb`, `teovibe/app/controllers/sessions_controller.rb`, `teovibe/app/controllers/admin/base_controller.rb`
- Risk: Regressions in core auth flows can expose user accounts or grant unauthorized admin access. No test protection.
- Priority: High - auth is critical. Add integration tests for: signup via email, signup via Google/Kakao, login with wrong password, forgot password flow, admin panel access checks.

**Point System Not Tested:**
- What's not tested: Point awards (post creation, comment, like), level-up calculation, threshold correctness, transaction creation
- Files: `teovibe/app/services/point_service.rb`, all models with `after_create :award_points`
- Risk: Point calculation bugs go unnoticed. Users could be over-awarded or under-awarded points. Level thresholds could be wrong.
- Priority: High - gamification is core feature. Add unit tests for each award action. Test level-up boundary (e.g., user at 49 points creates post worth 10, should reach Lv3).

**Search Functionality Not Tested:**
- What's not tested: FTS5 search, fallback LIKE search, query escaping, empty results, pagination
- Files: `teovibe/app/controllers/search_controller.rb`
- Risk: Search regressions undetected. FTS and LIKE may return different results. No quality assurance.
- Priority: Medium - feature is public-facing but not critical. Add tests: search with special characters, search with no results, search with many results (pagination).

**Admin CRUD Operations Not Tested:**
- What's not tested: Admin post/user/skill pack/inquiry creation, editing, deletion. Admin authorization checks.
- Files: `teovibe/app/controllers/admin/*_controller.rb`
- Risk: Admin features break silently. Unauthorized users could potentially bypass checks (no tests verify checks work).
- Priority: High - admin panel is privileged. Add tests for each admin controller: verify only admins can access, verify CRUD operations succeed, verify invalid inputs rejected.

**Comment Threading (Parent/Reply) Not Tested:**
- What's not tested: Creating reply to comment (parent_id), reply notification, reply list rendering, accepted answer marking in QnA
- Files: `teovibe/app/models/comment.rb`, `teovibe/app/controllers/comments_controller.rb`, `teovibe/app/controllers/qnas_controller.rb`
- Risk: Reply logic could break. Accepted answers feature is untested (and currently unexposed in UI).
- Priority: Medium - feature is less critical but affects UX. Add tests: create comment with parent_id, verify notification sent, mark as accepted, verify accepted state displays.

**Skill Pack Download Flow Not Tested:**
- What's not tested: Download recording, token-based download, download deduplication, download count accuracy
- Files: `teovibe/app/controllers/skill_packs_controller.rb`, `teovibe/app/models/download.rb`
- Risk: Download counter could be inaccurate. Token-based download could expose unauthorized access.
- Priority: Medium - monetization feature but not critical. Add tests: download as user, verify Download record created, verify token download works, verify duplicate downloads deduplicated.

**Notification System Not Tested:**
- What's not tested: Notification creation (comment, reply, like, level up), notification display, mark as read
- Files: `teovibe/app/services/notification_service.rb`, `teovibe/app/models/notification.rb`
- Risk: Notifications may not be sent, may be sent to wrong users, mark_as_read could fail silently.
- Priority: Medium - UX feature. Add tests: create comment, verify notification sent to post author, verify notification marked as read.

---

*Concerns audit: 2026-02-22*
