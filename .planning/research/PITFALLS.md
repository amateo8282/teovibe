# Pitfalls Research

**Domain:** Rails 8.1 monolith — v1.1 Admin 고도화 (Dynamic categories, AI draft, Scheduled publishing)
**Researched:** 2026-02-28
**Confidence:** HIGH (codebase-verified + WebSearch verified against official sources and GitHub issues)

> Note: This file replaces the v1.0 pitfalls (react-rails, rhino-editor, payment infrastructure). Those issues
> are resolved in the existing codebase. This research focuses exclusively on pitfalls for v1.1 features.

---

## Critical Pitfalls

### Pitfall 1: enum integer → Category FK Migration Corrupts Existing Posts

**What goes wrong:**
The `posts` table currently stores `category` as an integer enum (blog=0, tutorial=1, free_board=2, qna=3, portfolio=4, notice=5). When migrating to a dynamic `Category` model with a foreign key `category_id`, the migration must translate old integer values to new Category record IDs. If the migration assumes ID auto-increment starts at 1 and matches the enum integers, it will silently map data wrong: blog=0 would need to match category_id=1 (first inserted Category), but if seed order differs even slightly, all posts land in the wrong category — and there is no error, just wrong data.

Additionally, if any code still references `Post.blog` (the enum scope), it raises `NoMethodError` after the enum declaration is removed, breaking every board page simultaneously.

**Why it happens:**
Developers assume "I'll insert Category seeds in the same order as the enum values, so IDs will align." But SQLite auto-increment IDs are not guaranteed to match enum integers. On a fresh `db:schema:load`, IDs start at 1, not 0. Post enum value 0 (blog) would map to nothing if the first Category gets id=1.

The current codebase has hardcoded category usage in six places that all break at once:
- `Post::CATEGORY` enum declaration
- `PostsBaseController#category` method (per-controller subclass)
- `Post#route_key` (case/when on category string)
- `Post#category_name` (hash lookup)
- `Post.where(category: :notice)` scopes throughout
- `destroy` redirect using `cat.pluralize + "_path"` in PostsBaseController

**How to avoid:**
1. Run both old enum and new FK simultaneously during transition (dual-write period).
2. In the migration, use explicit SQL mapping: `UPDATE posts SET category_id = (SELECT id FROM categories WHERE slug = old_category_name)`, never rely on auto-increment alignment.
3. Add the new `category_id` column as nullable first. Backfill. Then add NOT NULL constraint in a separate migration.
4. Redefine the model inside the migration to locally avoid the live app's enum declaration:
   ```ruby
   class Post < ApplicationRecord; end  # strips the enum declaration
   ```
5. Keep the old integer `category` column until all category-dependent code is migrated. Drop it only in the final cleanup migration.

**Warning signs:**
- Any migration that does `add_column :posts, :category_id, :integer, null: false` in a single step (should be two steps: add nullable, backfill, add constraint)
- Seeds file that inserts Categories and assumes integer positions match enum values
- Migration that runs `Post.update_all("category_id = category + 1")` (off-by-one error in the presence of 0-indexed enums vs 1-indexed IDs)

**Phase to address:**
Phase 1 (Category model): Write and test the migration data mapping script in isolation before any controller refactor. Test on a copy of production data.

---

### Pitfall 2: Hardcoded Category Routes Break Entirely After Enum Removal

**What goes wrong:**
The routing architecture uses one controller per category (BlogsController, TutorialsController, etc.), each subclassing PostsBaseController. These routes are hardcoded in `config/routes.rb`. Removing the `Post` enum without simultaneously updating routes, controllers, and all link helpers causes every board page to 404 or raise `ActionController::RoutingError`.

The `route_key` method in `Post` and the `cat.pluralize + "_path"` redirect in PostsBaseController both depend on the category being a known string matching a route name. A dynamic Category model with a slug like "vibe-coding" has no corresponding named route helper, so `polymorphic_path(@post.route_key)` raises `NoMethodError: undefined method 'vibe_coding_path'`.

**Why it happens:**
The current design treats category as a routing concern, not just a data concern. Each category has its own route prefix, controller, and URL namespace. This is excellent for the static 6-category setup but becomes a maintenance nightmare once categories become dynamic. There is a fundamental mismatch between "dynamic data" and "hardcoded routes."

**How to avoid:**
Two valid approaches — choose one before starting migration:

Option A (Minimal change): Keep the 6 existing hardcoded routes. Add a new "dynamic" route for admin-created categories. Posts in hardcoded categories use existing URLs; posts in new dynamic categories use a generic `/posts/:category_slug/:id` route. No URL breakage for existing content.

Option B (Full migration): Replace all per-category routes with a single parametric route: `resources :posts, path: "/:category_slug"`. Update all link helpers to use this new pattern. This is a breaking URL change — all existing post URLs change, SEO impact, existing links break.

For a platform that is starting external promotion (per PROJECT.md), Option A is the right choice. Preserve existing URLs at all costs.

**Warning signs:**
- Any plan that says "refactor all board routes to a single resource" without accounting for SEO and existing URL preservation
- PostsBaseController subclasses (BlogsController etc.) deleted before a redirect from old URLs is in place
- `polymorphic_path` calls not audited for new dynamic category slugs

**Phase to address:**
Phase 1 (Category model) — routing strategy must be decided before writing a single line of migration code.

---

### Pitfall 3: Admin-Only Write Toggle Applied Too Broadly, Locking Out Users

**What goes wrong:**
The "관리자 전용 작성 토글" (admin-only write toggle) feature is intended to let admins designate certain categories as admin-write-only (like "notice"). If this toggle is stored on the Category model and the authorization check is added carelessly to `PostsBaseController`, it could block non-admin users from writing in categories that should remain open. A regression where the default for new Category records is `admin_only: true` (instead of false) would silently lock every category until an admin manually toggles each one.

**Why it happens:**
Authorization checks that look at `category.admin_only?` are easy to implement at the controller layer but the default value matters enormously. New categories created by admin forget to set the toggle. Or, the default is set to `true` "for safety" without considering that ALL existing board categories would need explicit `false` setting.

**How to avoid:**
- Column default MUST be `false` (`admin_only: false, null: false, default: false`).
- Backfill: only `notice` category should be seeded as `admin_only: true`.
- Authorization check: `authorize_post!` in `PostsBaseController` should check the category's `admin_only?` flag before checking user role — and log the reason for denial.
- Test path: as a regular member, attempt to create a post in blog, tutorial, and free_board after the toggle feature ships. Verify all succeed.

**Warning signs:**
- Category seeds file does not explicitly set `admin_only: false` for non-notice categories
- `Admin::CategoriesController` create action does not set default for `admin_only`
- No integration test covering "member can create post in non-admin-only category"

**Phase to address:**
Phase 1 (Category model) — the toggle default and authorization logic must be verified in the same PR that introduces the Category model.

---

### Pitfall 4: Anthropic API Blocking the Puma Thread — No Response Streaming

**What goes wrong:**
Integrating the Anthropic Ruby SDK in a standard Rails controller action without streaming will block the Puma thread for the entire duration of the API call. Claude generation for a full blog post draft (2,000+ tokens) can take 15-60 seconds. With the default Puma thread count of 5, a single admin triggering two concurrent AI drafts starves the entire server of available threads — all other requests queue behind it.

In the specific case of this project (Rails 8.1, 1인 운영, Kamal Docker deployment), the default Puma config has 3-5 threads. One long AI request = 20-33% of capacity consumed for up to 60 seconds.

**Why it happens:**
Developers call `client.messages.create(...)` (blocking) inside a controller action, treating it like a fast API call. The Anthropic SDK defaults to a 600-second timeout with no streaming. The response does not arrive until generation completes. No threading or async mechanism is added because "it works in development" (where you are the only user).

**How to avoid:**
Use streaming with Server-Sent Events (SSE) via `ActionController::Live`:
```ruby
include ActionController::Live

def generate_draft
  response.headers["Content-Type"] = "text/event-stream"
  response.headers["Cache-Control"] = "no-cache"

  client = Anthropic::Client.new(api_key: ENV["ANTHROPIC_API_KEY"])
  client.messages.stream(model: "claude-3-5-sonnet-20241022", ...) do |event|
    response.stream.write("data: #{event.delta.text.to_json}\n\n")
  end
ensure
  response.stream.close
end
```

This approach releases the thread between chunks. Turbo Streams or a JS EventSource on the frontend consumes the stream progressively. The admin sees text appear in real time rather than waiting for a complete response.

If SSE adds complexity, the alternative is to enqueue a background job (`GenerateDraftJob`) and use Turbo Streams to broadcast the result when the job completes. The job approach has higher latency to first token but simpler frontend.

**Warning signs:**
- `Anthropic::Client.new.messages.create(...)` called directly inside a controller action without `ActionController::Live`
- No timeout configuration on the Anthropic client instance
- Puma thread count not increased before AI feature ships
- No Rack::Timeout or request timeout configured

**Phase to address:**
Phase 2 (AI Draft) — streaming architecture decision must be made before any AI integration code is written. Retrofitting streaming after a blocking implementation is a full controller rewrite.

---

### Pitfall 5: Anthropic API Key Leaking to Logs or Error Reports

**What goes wrong:**
If `ANTHROPIC_API_KEY` is interpolated into log messages, error payloads, or request parameters (even via Rails parameter logging), it can appear in plaintext in log files accessible via `tail -f log/production.log` or exception tracking tools. Given the existing Kamal deployment pattern where `.env` vars are injected at container startup, the key is always present in the process environment — but if it leaks into logs, it's one SSH session away from compromise.

**Why it happens:**
Developers debugging AI integration add temporary `Rails.logger.debug` statements. Or an exception propagates with the full HTTP request context including the Authorization header. Rails' `filter_parameters` config does not automatically filter custom HTTP headers or ENV variables.

**How to avoid:**
- Add `ANTHROPIC_API_KEY` to `config/initializers/filter_parameter_logging.rb`:
  ```ruby
  Rails.application.config.filter_parameters += [:anthropic_api_key, "ANTHROPIC_API_KEY"]
  ```
- Never pass the API key as a query param or request body param — always use the SDK's `api_key:` initializer argument.
- Wrap all Anthropic SDK calls in a service object (`AiDraftService`) that encapsulates the client initialization, keeping the key reference to one location.
- Add `ANTHROPIC_API_KEY` to `.gitignore` linting: verify it is in `.env` (gitignored) and `.kamal/secrets`, not hardcoded.

**Warning signs:**
- `Anthropic::Client.new(api_key: params[:api_key])` — key from request params
- `Rails.logger.info "Using key: #{ENV['ANTHROPIC_API_KEY']}"` — key in logs
- Anthropic client initialized in a controller (not a service object), making it easy to accidentally log

**Phase to address:**
Phase 2 (AI Draft) — the service object wrapper and parameter filtering must be in place before the first test against the real API.

---

### Pitfall 6: Scheduled Publishing Job Fires Twice (or Never) Due to Solid Queue Recurrence

**What goes wrong:**
Implementing scheduled publishing with Solid Queue recurring jobs has a known failure mode: if the recurring task configuration in `config/recurring.yml` is not loaded by the scheduler process, jobs are never enqueued (posts never publish). Conversely, if a job is retried after a transient failure and the post status check is not idempotent, the same post transitions to `published` twice — triggering duplicate notifications and point awards.

A specific Rails 8.1 issue (solid_queue#429): recurring jobs are sometimes not enqueued when using `Rails 8.1.0.alpha & friends`. The production queue.yml already present in this project uses `polling_interval: 1` for dispatchers but does not configure a scheduler section.

**Why it happens:**
Solid Queue requires a distinct `scheduler` process to handle recurring tasks. If the supervisor configuration in `queue.yml` only defines `dispatchers` and `workers` (as the current project's `queue.yml` does), recurring tasks from `recurring.yml` are never processed. The scheduler is a separate process type that must be explicitly started.

Additionally, using `perform_later` with a time argument schedules a job, but if the cron polling runs every minute and the scheduled time falls between polls, jobs can be delayed or skipped.

**How to avoid:**
1. Add a `scheduler` section to `config/queue.yml`:
   ```yaml
   default: &default
     dispatchers:
       - polling_interval: 1
         batch_size: 500
         recurring_tasks_manager: true  # enables recurring.yml
     workers:
       - queues: "*"
         threads: 3
   ```
   Actually, for Solid Queue, recurring tasks are managed by the dispatcher with `recurring_tasks_manager: true`, not a separate scheduler process. Verify current Solid Queue docs (v1.x changed this).

2. For scheduled publishing, prefer `set(wait_until: post.scheduled_at).perform_later` over a recurring cron that queries `Post.where(scheduled_at: ..past..)`. The `wait_until` approach is a single job enqueued at creation time — simpler, fewer moving parts.

3. Make the publish transition idempotent: `Post#publish!` must be a no-op if already published:
   ```ruby
   def publish!
     return if published?
     update!(status: :published, published_at: Time.current)
   end
   ```

4. Use `with_lock` in the publishing job to prevent race conditions on the post record:
   ```ruby
   def perform(post_id)
     Post.find(post_id).with_lock { post.publish! unless post.published? }
   end
   ```

**Warning signs:**
- `config/queue.yml` has no `recurring_tasks_manager` or scheduler configuration
- `PublishPostJob` lacks an idempotency check (`return if post.published?`)
- `Post` model has no `scheduled_at` column — publishing time stored elsewhere (e.g., only in the job's `scheduled_at` queue record)
- `solid_queue_recurring_tasks` table is empty after deploying `recurring.yml` config

**Phase to address:**
Phase 3 (Scheduled Publishing) — idempotency check and lock must be implemented before the first end-to-end test with real post data. Test both "job fires once" and "job retried after failure" paths.

---

### Pitfall 7: Scheduled Post Published_At vs Created_At Confusion in Feeds and Rankings

**What goes wrong:**
After adding scheduled publishing, a post created today with `scheduled_at = next week` has `created_at = today` but should appear as "published next week." If the feed, rankings, search index, and post ordering all use `created_at` (as the current codebase does via `order(created_at: :desc)`), a post scheduled for next week will appear in today's feed immediately after record creation — before it is published. This breaks the UX expectation that drafts/scheduled posts are invisible to users.

Additionally, `published_at` must be populated at the moment of actual publishing (either immediate or via the scheduled job). If `published_at` is not added as a separate column and code uses `created_at` as the sort key, the RSS feed and SEO sitemap emit the wrong dates.

**Why it happens:**
The current Post model has `status` (draft/published) but no `published_at` column. Developers add scheduled publishing by adding `scheduled_at` but forget to also add `published_at` and update all queries that use `created_at` to use `published_at` instead.

**How to avoid:**
- Add both `scheduled_at: datetime` and `published_at: datetime` (nullable) in the migration.
- Update all public-facing scopes: `scope :published_visible, -> { published.where("published_at <= ?", Time.current) }`
- Update `feeds_controller.rb` and `sitemap_generator` to use `published_at`.
- Update `PostsBaseController#index` to order by `published_at desc` (not `created_at`).
- Verify the `published` scope in `Post` still correctly hides scheduled-but-not-yet-published records.

**Warning signs:**
- Migration adds `scheduled_at` but not `published_at`
- `Post.published` scope uses only `where(status: :published)` without checking time
- RSS feed controller ordering by `created_at` not updated after publishing migration
- Admin dashboard "recent posts" shows scheduled posts as appearing immediately

**Phase to address:**
Phase 3 (Scheduled Publishing) — `published_at` column and scope update must be in the same migration as `scheduled_at`. The two columns are coupled; splitting them across phases will produce a window of incorrect behavior.

---

### Pitfall 8: SkillPack Category Migration Has No Downstream Impact Analysis

**What goes wrong:**
The `skill_packs` table also uses a hardcoded integer enum for `category` (template=0, component=1, guide=2, toolkit=3). Migrating SkillPack categories to a dynamic model requires the same analysis as Post categories. However, SkillPack categories have an additional dependency: the `Download` and `Order` models use `skill_pack_id` for analytics queries, and any admin "filter by category" UI will break if the category column is renamed without updating filter parameters.

Specifically, `SkillPack.by_category` scope uses `where(category: cat)` which passes the string name and relies on the enum mapping. After removing the enum, this scope silently returns nothing instead of raising an error.

**Why it happens:**
The SkillPack migration is done as an afterthought following the Post category migration, with less attention. Developers copy-paste the Post migration without verifying that SkillPack-specific scopes (`by_category`), the checkout flow, and the download analytics are updated consistently.

**How to avoid:**
- Treat SkillPack category migration as a separate, independent task from Post category migration.
- Audit every use of `skill_pack.category` in: admin/skill_packs views, `SkillPack.by_category` scope, checkout controller, order records.
- Update `by_category` scope before removing the enum: `scope :by_category, ->(cat) { joins(:category).where(categories: { slug: cat }) if cat.present? }`.
- The two Category models (PostCategory and SkillPackCategory) should be separate models if they have different admin management needs, or a polymorphic `Categorizable` approach if shared. Mixing them into one `Category` model with a `type` column risks confusion.

**Warning signs:**
- Single `categories` table serving both Post and SkillPack categories without a `resource_type` discriminator
- `SkillPack.by_category("template")` returning empty after migration (silent failure)
- Checkout flow not updated — `skill_pack.category_name` raises `NoMethodError` after enum removal

**Phase to address:**
Phase 1 (Category model) — the decision of shared vs. separate Category models must be made upfront, as it affects the migration strategy for both Post and SkillPack.

---

## Technical Debt Patterns

| Shortcut | Immediate Benefit | Long-term Cost | When Acceptable |
|----------|-------------------|----------------|-----------------|
| Add `category_id` nullable, skip backfill, add NOT NULL later | Faster migration | Zero-downtime risk window where posts have NULL category_id | Only acceptable if the window is a single deploy with immediate follow-up migration |
| Use blocking Anthropic API call (no streaming) | Simpler controller code | Puma thread starvation in production | Only acceptable for internal admin tools with a single user, never for public-facing |
| Use recurring cron job to poll for scheduled posts | Simple scheduling logic | Over-fires on server restart, requires idempotency everywhere | Acceptable if idempotency is implemented; prefer `wait_until` jobs over polling cron |
| Share one `categories` table for Posts and SkillPacks | Less code | Mixed concerns, harder to add category-specific fields | Acceptable if no category-specific attributes are needed (just name/slug/admin_only) |
| Keep old `category` integer column during migration for backward compatibility | Zero downtime during migration | Dual-write complexity, extra column in schema | Acceptable during the transition period — must have a deadline for cleanup |

---

## Integration Gotchas

| Integration | Common Mistake | Correct Approach |
|-------------|----------------|------------------|
| Anthropic Ruby SDK | Calling `messages.create` in controller (blocking) | Use `messages.stream` with `ActionController::Live` or enqueue `GenerateDraftJob` |
| Anthropic Ruby SDK | Not setting timeout on client | `Anthropic::Client.new(timeout: 120)` to match Puma request timeout |
| Solid Queue `recurring.yml` | Defining recurring tasks without confirming scheduler process runs | Add `recurring_tasks_manager: true` to dispatcher; verify `solid_queue_recurring_tasks` table populates after deploy |
| Solid Queue scheduled jobs | `set(wait_until:).perform_later` with UTC vs app timezone | Always use `Time.current` (respects `config.time_zone`), not `Time.now` or `DateTime.now` |
| Post integer→FK migration | Running `change_column` to rename `category` to `category_id` | Add new column, backfill, add FK constraint, remove old column — four separate steps |
| Category-based routing | Calling `polymorphic_path` with dynamic category slug that has no named route | Either keep named routes per category or switch to a slug-based generic route for new categories |

---

## Performance Traps

| Trap | Symptoms | Prevention | When It Breaks |
|------|----------|------------|----------------|
| `Post.includes(:category)` missing after Category association added | N+1 on every board index page | Add `includes(:category)` to all existing `includes(:user)` calls | From first request after Category association added |
| AI draft endpoint without rate limiting | Admin triggers 10 concurrent drafts, exhausts Puma threads | Add `Rack::Attack` limit: 1 AI request per admin per 30 seconds | First time admin is bored and clicks Generate repeatedly |
| `order(created_at: :desc)` on large posts table after `published_at` added | Sort on wrong column, scheduled posts appear in wrong order | Add index on `published_at` and update all ordering queries | Any traffic after scheduled publishing ships |
| Recurring publish job polls entire posts table | Slow `WHERE status = 'draft' AND scheduled_at <= NOW()` without index | Add composite index `(status, scheduled_at)` at migration time | ~1,000+ posts with mix of scheduled/draft |
| Category position reordering uses `acts_as_list` or manual position updates without transactions | Temporary duplicate positions during reorder | Wrap reorder in transaction; use `update_all` not individual saves | Any concurrent admin session |

---

## Security Mistakes

| Mistake | Risk | Prevention |
|---------|------|------------|
| `ANTHROPIC_API_KEY` hardcoded in initializer or leaked to logs | API key compromise — attacker can generate content on your billing account | Store in ENV only; add to `filter_parameters`; wrap in `AiDraftService` |
| AI-generated content published directly without admin review | Hallucinated or harmful content appears as official post | Always save AI output as `status: :draft` — require manual admin publish action |
| Category `admin_only` default is `true` | All new categories silently locked; users cannot post | Default must be `false` at DB level; seed explicitly |
| `GenerateDraftJob` accepts `prompt` from user input without sanitization | Prompt injection — user crafts a title that makes AI generate harmful content | Validate/sanitize title and topic inputs before passing to API; use system prompt to constrain output format |
| Scheduled post time accepts past timestamps | Any admin can set `scheduled_at` to the past to immediately publish in the past (backdating) | Validate `scheduled_at > Time.current` in Post model; or accept past dates but immediately publish without `wait_until` |

---

## UX Pitfalls

| Pitfall | User Impact | Better Approach |
|---------|-------------|-----------------|
| AI draft generation with no progress indication | Admin sees blank form for 30-60 seconds, assumes it's broken, clicks Generate again | Show streaming text as it generates; or show "Generating..." spinner with estimated time |
| Scheduled post shows creation date in UI, not scheduled date | Admin confusion about when post will appear | Show `scheduled_at` prominently in admin post list; add "Scheduled" badge with datetime |
| Category reorder saves immediately on drag without confirmation | Accidental reorder applied to production instantly | Either auto-save with undo toast, or require explicit "Save order" button |
| Admin creates category then cannot find where to assign admin-only toggle | Toggle hidden in nested settings, ignored | Put `admin_only` toggle directly on the category create/edit form, not in a separate settings section |
| User tries to post in admin-only category, gets generic 403 | No explanation of why they cannot post | Show inline message: "이 게시판은 관리자만 글을 작성할 수 있습니다." |

---

## "Looks Done But Isn't" Checklist

- [ ] **Category migration:** `Post.where(category: :blog).count` before migration equals `Post.where(category_id: blog_category.id).count` after migration — verify row counts match exactly
- [ ] **Category migration:** Rolling back the migration leaves zero data loss (test `db:rollback` in staging)
- [ ] **Admin-only toggle:** Create a regular user session, attempt to post in the notice category, verify 403 with a clear message; attempt in free_board, verify 200
- [ ] **AI draft generation:** Trigger from admin, observe text streaming in real time; close browser mid-generation, verify no orphaned Puma thread stuck in Anthropic call
- [ ] **Scheduled publishing:** Create a post with `scheduled_at = 2 minutes from now`, wait 3 minutes, verify `status = published` and `published_at` is set; verify the post appears in public index
- [ ] **Scheduled publishing:** Create a post with `scheduled_at = past`, verify it publishes immediately (not stuck in pending)
- [ ] **Published_at in feed:** RSS feed shows `published_at` not `created_at` for scheduled posts
- [ ] **SkillPack categories:** Filter by category on the public skill_packs index still works after migration
- [ ] **Solid Queue scheduler:** `SolidQueue::RecurringTask.count > 0` after deploy if using recurring.yml; or `SolidQueue::ScheduledExecution.count > 0` for `wait_until` jobs

---

## Recovery Strategies

| Pitfall | Recovery Cost | Recovery Steps |
|---------|---------------|----------------|
| Category migration maps to wrong categories | HIGH | Restore DB backup; rewrite mapping SQL; re-migrate with verified mapping |
| Routes broken after enum removal | MEDIUM | Re-add removed controller subclasses temporarily; add redirects from old route patterns; restore enum in model as `_deprecated_category` |
| AI key leaked to logs | HIGH | Rotate ANTHROPIC_API_KEY immediately; audit all log files; check error reporting tool for key exposure |
| Scheduled post never published (scheduler not running) | LOW | Run `Post.where(status: :draft).where("scheduled_at <= ?", Time.current).each(&:publish!)` in Rails console; fix scheduler config; redeploy |
| Duplicate publish notifications sent | LOW | Implement `published_at` uniqueness check retroactively; identify affected posts via `Point.where(action_type: :post_created).group(:pointable_id).having("count(*) > 1")`; manually remove duplicates |
| SkillPack `by_category` returns empty | LOW | Update scope in model; no data loss; deploy fix |

---

## Pitfall-to-Phase Mapping

| Pitfall | Prevention Phase | Verification |
|---------|------------------|--------------|
| Enum → FK migration data corruption | Phase 1 (Category model) | Row count parity check before/after migration in staging |
| Hardcoded routes break on dynamic categories | Phase 1 (Category model) | All 6 existing board URLs return 200 after migration; verify in browser |
| Admin-only toggle defaults to wrong value | Phase 1 (Category model) | Integration test: member can post in free_board, cannot post in notice |
| Anthropic API blocks Puma thread | Phase 2 (AI Draft) | Load test: 3 concurrent AI requests must not degrade non-AI page response time |
| API key leaks to logs | Phase 2 (AI Draft) | `grep -i anthropic log/development.log` returns no API key strings after integration |
| Scheduled job fires twice (race condition) | Phase 3 (Scheduled Publishing) | Trigger job twice for same post; verify `published_at` set only once, single notification sent |
| `published_at` vs `created_at` ordering | Phase 3 (Scheduled Publishing) | Public index ordered by `published_at`; scheduled post invisible before publish time |
| SkillPack category migration scope breakage | Phase 1 (Category model) | `SkillPack.by_category("template").count > 0` after migration |

---

## Sources

- Codebase analysis: `teovibe/app/models/post.rb` (enum declaration, route_key method)
- Codebase analysis: `teovibe/app/controllers/posts_base_controller.rb` (category routing pattern)
- Codebase analysis: `teovibe/config/routes.rb` (6 hardcoded category routes)
- Codebase analysis: `teovibe/config/queue.yml` (no scheduler section configured)
- Codebase analysis: `teovibe/db/schema.rb` (posts.category integer, skill_packs.category integer)
- [Solid Queue GitHub: recurring jobs not enqueued in Rails 8.1 alpha (issue #429)](https://github.com/rails/solid_queue/issues/429)
- [Solid Queue GitHub: only registering Supervisor, not scheduler in Rails 8 / Solid Queue 1.2.1 (issue #651)](https://github.com/rails/solid_queue/issues/651)
- [Ten Pitfalls Using Active Job in Rails 8 with Solid Queue — Medium](https://patrickkarsh.medium.com/ten-pitfalls-when-using-active-job-in-rails-8-with-solid-queue-3b4d40c930f8)
- [Streaming LLM Responses with Rails: SSE vs. Turbo Streams — Aha! Engineering](https://www.aha.io/engineering/articles/streaming-llm-responses-rails-sse-turbo-streams)
- [Anthropic API Errors and Timeout documentation](https://docs.anthropic.com/en/api/errors)
- [Anthropic Ruby SDK — GitHub](https://github.com/anthropics/anthropic-sdk-ruby)
- [It's time to stop changing data in Active Record Migrations — hartley mcguire](https://skipkayhil.github.io/2024/01/23/its-time-to-stop.html)
- [Enum validations and database constraints in Rails 7.1 — Thoughtbot](https://thoughtbot.com/blog/enum-validations-and-database-constraints-in-rails-7-1)
- [Solid Queue: A Deep Dive — AppSignal Blog (2025)](https://blog.appsignal.com/2025/06/18/a-deep-dive-into-solid-queue-for-ruby-on-rails.html)

---
*Pitfalls research for: Rails 8.1 monolith v1.1 — dynamic categories, AI draft, scheduled publishing*
*Researched: 2026-02-28*
