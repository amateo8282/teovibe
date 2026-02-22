# Phase 2: Content Experience - Research

**Researched:** 2026-02-22
**Domain:** Rich Text Editor (rhino-editor/TipTap), Profile UX, Admin Analytics
**Confidence:** MEDIUM — rhino-editor v0.18.x broke image/attachment extensions; version strategy needs careful validation

## Summary

Phase 2 covers three distinct domains: (1) replacing Trix with rhino-editor for a richer editing experience, (2) enhancing the author profile page with avatar upload, social links, and gamification display, and (3) adding content analytics to the Admin dashboard. The codebase already has solid foundations: `Post has_rich_text :body` with ActionText, `User` model with `points`, `level`, `bio`, `avatar_url` columns, `PointService` with level thresholds, and a basic Admin dashboard.

The most critical risk is rhino-editor version selection. Version 0.18.0 upgraded TipTap from v2.7 to v3.4 and **removed** the `rhinoImage` and `rhinoAttachment` extensions — the exact features needed for EDIT-02. The safe strategy is to **pin to the last 0.17.x release** until the 0.18.x migration guides for image handling are clear. Additionally, rhino-editor uses Shadow DOM for its toolbar and link dialog, which conflicts with Tailwind CSS v4's `:root`-scoped CSS variables — a concern flagged in STATE.md that requires a targeted fix.

The profile page (PROF-01/02) is straightforward: `avatar_url` currently stores a URL string, which must be migrated to Active Storage `has_one_attached :avatar` for real file uploads. Gamification data (points, level, badges) already exists in the DB and PointService — the work is pure presentation. The Admin analytics (ADMN-01) requires adding `chartkick` + `groupdate` gems and writing two queries: top posts by `views_count` and daily/weekly user registrations.

**Primary recommendation:** Pin rhino-editor to `^0.17` (last stable before TipTap v3 breaking changes), integrate via Vite npm import (not importmap), resolve Shadow DOM / Tailwind conflict with a targeted CSS injection, migrate avatar to Active Storage, and use chartkick + groupdate for Admin charts with zero custom chart code.

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|-----------------|
| EDIT-01 | rhino-editor(TipTap 기반)를 도입하여 기존 ActionText/Trix를 대체하며 기존 콘텐츠와 호환을 유지한다 | npm install rhino-editor, replace `f.rich_text_area` with hidden field + `<rhino-editor>` web component, `to_trix_html` preserves existing ActionText data |
| EDIT-02 | 에디터에서 이미지를 드래그&드롭으로 업로드하고 크기 조절할 수 있다 | rhino-editor 0.17.x has built-in rhinoAttachment/rhinoImage; Active Storage direct uploads via `data-direct-upload-url` attribute; 0.18.x removed these — pin to 0.17.x |
| EDIT-03 | 에디터에 버블 메뉴(선택 텍스트 서식)와 플로팅 툴바를 제공한다 | rhino-editor has built-in bubble menu via `slot="bubble-menu-toolbar"` and `slot="additional-bubble-menu-toolbar"` — works out of the box |
| PROF-01 | 작성자 프로필 페이지에 아바타, 바이오, 소셜링크, 작성 글 목록을 표시한다 | `avatar_url` column exists (URL string) — migrate to Active Storage `has_one_attached :avatar`; bio column exists; social_links needs new JSON/string column; posts already queryable |
| PROF-02 | 프로필에 포인트, 레벨, 뱃지를 시각적으로 표시한다 (게이미피케이션) | points/level columns on users table; PointService has LEVEL_THRESHOLDS; badges need a definition/mapping table or simple hash-based logic |
| ADMN-01 | Admin 대시보드에 기본 콘텐츠 분석을 표시한다 (조회수 상위 게시글, 좋아요 통계, 회원가입 추이) | views_count/likes_count on posts; chartkick gem for charts; groupdate gem for time-series grouping |
</phase_requirements>

## Standard Stack

### Core

| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| rhino-editor | ^0.17.x (pin — see pitfalls) | TipTap-based WYSIWYG editor, ActionText compatible | Only editor that drops into ActionText without data migration; built-in Active Storage upload support |
| chartkick | ~> 5.0 (gem) | One-line Rails chart helpers for Admin | No custom JS required; integrates with Chart.js via Vite |
| groupdate | ~> 6.4 (gem) | Time-series grouping for registration trend queries | Chartkick's canonical companion for date-group queries |
| Active Storage | Built-in (Rails 8.1) | Avatar file uploads with variants | Already installed; image_processing gem already in Gemfile |

### Supporting

| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| chart.js | ^4.0 (npm) | Chartkick rendering backend | Must be imported in Vite bundle alongside chartkick |
| @rails/activestorage | ^8.0 (npm) | Direct upload JS client | Required by rhino-editor for blob uploads (already needed by ActionText) |
| image_processing | ~> 1.2 (gem, already present) | Avatar variant generation (resize, crop) | Active Storage `variant(:thumb)` calls |

### Alternatives Considered

| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| rhino-editor 0.17.x | rhino-editor 0.18.x | 0.18 has TipTap v3 but rhinoImage/rhinoAttachment removed — image upload requires extra work not yet documented |
| rhino-editor | richer_text gem | richer_text wraps TipTap in a gem with view helpers but less npm ecosystem access; rhino-editor is more actively maintained |
| chartkick | Custom React chart component | Chartkick requires zero client JS; React chart adds React bundle to admin pages unnecessarily |
| Active Storage avatar | Keep avatar_url string | URL string cannot generate variants, no upload UI — must migrate |

**Installation:**
```bash
# npm (in teovibe/ directory)
pnpm add rhino-editor@^0.17
pnpm add chart.js

# Gemfile additions
gem "chartkick"
gem "groupdate"

# After bundle install
bundle exec rails generate chartkick:install  # if using importmap — skip for Vite
```

## Architecture Patterns

### Recommended Project Structure

```
app/
├── frontend/
│   ├── entrypoints/
│   │   ├── application.js          # existing — add rhino-editor import here
│   │   └── application.css         # existing
│   └── components/
│       └── (no new React components needed for editor — web component)
├── views/
│   ├── posts/
│   │   └── _form.html.erb          # replace rich_text_area with rhino-editor web component
│   ├── profiles/
│   │   ├── show.html.erb           # add avatar, social links, badge display
│   │   └── edit.html.erb           # add avatar upload field, social links inputs
│   └── admin/
│       └── dashboard/
│           └── index.html.erb      # add chartkick chart sections
├── models/
│   └── user.rb                     # add has_one_attached :avatar
├── controllers/
│   ├── profiles_controller.rb      # update profile_params for avatar, social_links
│   └── admin/
│       └── dashboard_controller.rb # add top_posts, registration_trend queries
└── db/migrate/
    └── YYYYMMDDHHMMSS_add_social_links_to_users.rb
```

### Pattern 1: rhino-editor Web Component in Rails Form

**What:** Replace `f.rich_text_area` with a hidden field (stores ActionText HTML) + `<rhino-editor>` web component
**When to use:** Any Rails form that previously used `f.rich_text_area :body`
**Example:**
```erb
<%# Source: https://rhino-editor.vercel.app/tutorials/usage-with-rails/ %>
<%# BEFORE (Trix): %>
<%#= f.rich_text_area :body, class: "..." %>

<%# AFTER (rhino-editor): %>
<%= f.hidden_field :body,
      id: f.field_id(:body),
      value: f.object.body.try(:to_trix_html) || f.object.body %>
<rhino-editor
  input="<%= f.field_id(:body) %>"
  data-blob-url-template="<%= rails_service_blob_url(":signed_id", ":filename") %>"
  data-direct-upload-url="<%= rails_direct_uploads_url %>"
></rhino-editor>
```

### Pattern 2: rhino-editor Import in Vite Entry Point

**What:** Import rhino-editor in the Vite application bundle (replaces trix + @rails/actiontext imports)
**When to use:** Single import in application.js — auto-registers `<rhino-editor>` custom element globally
**Example:**
```javascript
// Source: https://github.com/konnorrogers/rhino-editor (README)
// app/frontend/entrypoints/application.js

// REMOVE these:
// import "trix"
// import "@rails/actiontext"

// ADD these:
import "rhino-editor"
import "rhino-editor/exports/styles/trix.css"
```

### Pattern 3: Bubble Menu Customization

**What:** rhino-editor has a built-in bubble menu (appears on text selection) with bold, italic, link, etc. Customize via slots.
**When to use:** EDIT-03 — this works out of the box; custom slots only needed for additional buttons
**Example:**
```html
<!-- Source: https://github.com/konnorrogers/rhino-editor docs/references/06-bubble-menu.md -->
<rhino-editor>
  <!-- Override entire bubble menu toolbar -->
  <role-toolbar slot="bubble-menu-toolbar">
    <!-- Custom buttons here -->
  </role-toolbar>

  <!-- Add additional context-specific toolbars -->
  <role-toolbar id="link-toolbar" slot="additional-bubble-menu-toolbar">
    <button data-role="toolbar-item" tabindex="-1">Add Link</button>
  </role-toolbar>
</rhino-editor>
```

### Pattern 4: Active Storage Avatar

**What:** Replace `avatar_url` string with Active Storage attachment
**When to use:** PROF-01 — enables file upload with variant generation
**Example:**
```ruby
# app/models/user.rb
class User < ApplicationRecord
  has_one_attached :avatar

  def avatar_thumbnail
    return unless avatar.attached?
    avatar.variant(resize_to_fill: [80, 80]).processed
  end
end
```

```erb
<%# Profile edit form %>
<%= f.file_field :avatar, accept: "image/*",
    class: "hidden",
    id: "avatar-upload" %>
<label for="avatar-upload">
  <% if @user.avatar.attached? %>
    <%= image_tag @user.avatar.variant(resize_to_fill: [80, 80]), class: "w-20 h-20 rounded-full object-cover" %>
  <% else %>
    <div class="w-20 h-20 rounded-full bg-tv-gold flex items-center justify-center text-3xl font-black">
      <%= @user.nickname.first.upcase %>
    </div>
  <% end %>
</label>
```

### Pattern 5: chartkick Admin Charts

**What:** Single-line Ruby helpers render Chart.js charts; data from grouped ActiveRecord queries
**When to use:** ADMN-01 — top posts by views_count (bar chart), registration trend (line chart)
**Example:**
```erb
<%# Source: https://chartkick.com / groupdate gem %>
<%# app/views/admin/dashboard/index.html.erb %>

<%# Registration trend (last 30 days) %>
<%= line_chart @registration_trend, library: { tension: 0.4 } %>

<%# Top posts by views %>
<%= bar_chart @top_posts_data %>
```

```ruby
# app/controllers/admin/dashboard_controller.rb
def index
  # ... existing queries ...

  # 최근 30일 가입 추이
  @registration_trend = User.group_by_day(:created_at, last: 30).count

  # 조회수 상위 10개 게시글
  @top_posts = Post.published.order(views_count: :desc).limit(10)
  @top_posts_data = @top_posts.map { |p| [p.title.truncate(30), p.views_count] }
end
```

### Pattern 6: Badge Definition (No Extra Gem)

**What:** Badges defined as a plain Ruby hash/class, computed from user's points/level/post_count
**When to use:** PROF-02 — avoid over-engineering with a badges gem for a simple display requirement
**Example:**
```ruby
# app/models/concerns/badgeable.rb
module Badgeable
  BADGES = [
    { id: :newcomer,   label: "뉴비",     condition: ->(u) { u.posts_count >= 1 } },
    { id: :writer,     label: "작가",     condition: ->(u) { u.posts_count >= 10 } },
    { id: :veteran,    label: "베테랑",   condition: ->(u) { u.level >= 5 } },
    { id: :popular,    label: "인기인",   condition: ->(u) { u.points >= 500 } },
  ].freeze

  def earned_badges
    BADGES.select { |badge| badge[:condition].call(self) }
  end
end
```

### Anti-Patterns to Avoid

- **Importing both trix AND rhino-editor:** Causes double registration of `<trix-editor>` and `<rhino-editor>` with conflicting ActionText JS. Remove trix + @rails/actiontext imports completely.
- **Using rhino-editor 0.18.x for image uploads without migration guide:** rhinoImage/rhinoAttachment removed; no documented replacement yet — images will not upload.
- **Applying Tailwind utility classes inside rhino-editor Shadow DOM:** Shadow DOM encapsulation prevents Tailwind's `:root`-scoped CSS variables from reaching inside. Use rhino-editor's own CSS custom properties for internal theming.
- **Keeping avatar_url as a plain string URL:** Cannot generate variants, no built-in upload UI, not compatible with Active Storage helpers.
- **Running migration without preserving existing avatar_url data:** Users with existing `avatar_url` strings will lose their avatar reference — copy URL to a separate column or handle in migration.
- **chartkick with importmap approach in a Vite project:** chartkick docs show importmap setup; for Vite, import chart.js and chartkick in the JS bundle manually.

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Rich text editor with image upload | Custom TipTap + ActiveStorage glue | rhino-editor | Handles attachments, sgid, trix-content serialization — the details are subtle |
| Time-series chart | Custom SVG or React chart | chartkick + groupdate | Zero custom JS; works with any Chart.js type; groupdate handles timezone-aware grouping |
| Image resizing/cropping | Manual ImageMagick calls | Active Storage variants + image_processing gem | Already in Gemfile; `variant(resize_to_fill: [w, h])` is one method call |
| Badge system | badges gem or complex state machine | Plain Ruby concern with computed conditions | 4 badges don't warrant a gem; computed from existing points/level/posts_count |
| Shadow DOM / Tailwind CSS variable injection | PostCSS plugin rewriting | Import rhino-editor's own trix.css + target CSS custom properties via `::part()` or `:host` selectors | Less fragile than patching Tailwind's output |

**Key insight:** rhino-editor is already doing the hardest part (ProseMirror schema, ActionText serialization, Active Storage uploads). The integration task is configuration, not construction.

## Common Pitfalls

### Pitfall 1: rhino-editor 0.18.x Image Attachment Regression

**What goes wrong:** Installing the latest rhino-editor (0.18.x) causes image drag-and-drop and file attachments to silently fail because `rhinoImage` and `rhinoAttachment` extensions were removed in the TipTap v3 upgrade.
**Why it happens:** rhino-editor 0.18.0 made a major internal upgrade (TipTap v2.7 → v3.4) and the attachment/image extensions had not been ported yet.
**How to avoid:** Pin to `rhino-editor@^0.17` explicitly in package.json. Do not use `^0.18` or `latest`.
**Warning signs:** Images dropped into editor disappear immediately; no upload progress events fire; `data-rhino-attachment` elements absent from output HTML.

### Pitfall 2: Shadow DOM and Tailwind CSS v4 Variable Conflict

**What goes wrong:** Tailwind CSS v4 generates CSS custom properties under the `:root` selector. rhino-editor renders its toolbar and link dialog inside Shadow DOM, which has an isolated CSS scope. Tailwind variables (e.g., `--spacing-*`, `--color-*`) are not inherited into Shadow DOM, causing layout/color breakage inside the editor toolbar.
**Why it happens:** CSS custom properties defined on `:root` do propagate into Shadow DOM (they inherit through the shadow boundary), BUT `@property` declarations and `@layer` rules do NOT propagate — and Tailwind v4 uses `@property` for typed variables.
**How to avoid:** Do not apply Tailwind utility classes to elements inside rhino-editor's Shadow DOM. Style the outer `<rhino-editor>` element from outside. Use rhino-editor's exposed CSS custom properties (e.g., `--rhino-toolbar-background`) for internal theming.
**Warning signs:** Editor toolbar appears unstyled or has wrong colors only when Tailwind v4 is active.

### Pitfall 3: Existing ActionText Data Not Rendering After Editor Switch

**What goes wrong:** Posts created with Trix show broken/empty content after switching to rhino-editor because the hidden field value is not populated with existing Trix HTML.
**Why it happens:** The form must explicitly pass the existing trix HTML via `value: form.object.body.try(:to_trix_html) || form.object.body` — rhino-editor reads this initial value to hydrate the editor.
**How to avoid:** Always use `to_trix_html` fallback in the hidden field value. Test by loading an existing post in edit mode before launch.
**Warning signs:** Edit page shows empty editor for posts that have existing content; new posts work fine.

### Pitfall 4: avatar_url Migration Creates Null Avatars

**What goes wrong:** After adding `has_one_attached :avatar` and removing `avatar_url` from permitted params, existing users who had a `avatar_url` string appear with a blank avatar.
**Why it happens:** Active Storage attachments are separate records; existing `avatar_url` strings are not automatically converted.
**How to avoid:** Keep the `avatar_url` column as a fallback during transition. In the view, check `avatar.attached? || avatar_url.present?` and display the string URL as fallback.
**Warning signs:** All existing user avatars blank after deploy despite working before.

### Pitfall 5: chartkick + Vite Setup Requires Manual Chart.js Import

**What goes wrong:** chartkick renders blank white boxes in production; no chart appears.
**Why it happens:** chartkick detects its rendering backend (Chart.js, Google Charts, Highcharts) at runtime. With Vite, you must explicitly import chart.js and expose it globally before chartkick loads.
**How to avoid:** In the Vite entrypoint, import chart.js before chartkick:
```javascript
// app/frontend/entrypoints/application.js
import "chartkick/chart.js"
```
Or alternatively use the chartkick gem with `<%= chartkick_charts %>` helper in layout to load via CDN.
**Warning signs:** Charts render in development (where CDN fallback may work) but fail in production.

### Pitfall 6: Profile social_links Column Missing

**What goes wrong:** PROF-01 requires social links (Twitter, GitHub, etc.) but the `users` table has no such column — only `bio` and `avatar_url`.
**Why it happens:** The schema shows `avatar_url`, `bio`, `level`, `points` — no social_links column.
**How to avoid:** Add a migration for `social_links` (stored as JSON string or individual columns). Simple approach: `t.string :github_url`, `t.string :twitter_url`, `t.string :website_url`.
**Warning signs:** Trying to save social links raises `ActiveModel::ForbiddenAttributesError` or is silently dropped.

## Code Examples

Verified patterns from official sources:

### rhino-editor Rails Form Integration

```erb
<%# Source: https://rhino-editor.vercel.app/tutorials/usage-with-rails/ %>
<%= form_with model: post, url: post.persisted? ? send("#{post.category}_path", post) : send("#{post.category.pluralize}_path"), class: "space-y-6" do |f| %>
  <div>
    <label class="block text-sm font-bold mb-1">본문</label>
    <%= f.hidden_field :body,
          id: f.field_id(:body),
          value: f.object.body.try(:to_trix_html) || f.object.body %>
    <rhino-editor
      input="<%= f.field_id(:body) %>"
      data-blob-url-template="<%= rails_service_blob_url(":signed_id", ":filename") %>"
      data-direct-upload-url="<%= rails_direct_uploads_url %>"
    ></rhino-editor>
  </div>
<% end %>
```

### rhino-editor Application Entry Point

```javascript
// Source: https://github.com/konnorrogers/rhino-editor README
// app/frontend/entrypoints/application.js

// Remove Trix imports:
// import "trix"
// import "@rails/actiontext"

// Add rhino-editor:
import "rhino-editor"
import "rhino-editor/exports/styles/trix.css"
```

### chartkick Admin Dashboard

```ruby
# Source: chartkick.com + groupdate gem docs
# app/controllers/admin/dashboard_controller.rb
def index
  @total_users = User.count
  @total_posts = Post.count
  @total_comments = Comment.count
  @recent_posts = Post.includes(:user).order(created_at: :desc).limit(5)
  @recent_users = User.order(created_at: :desc).limit(5)

  # ADMN-01: 조회수 상위 게시글
  @top_posts = Post.published.order(views_count: :desc).limit(10)
  @top_posts_data = @top_posts.map { |p| [p.title.truncate(30), p.views_count] }

  # ADMN-01: 회원가입 추이 (최근 30일)
  @registration_trend = User.group_by_day(:created_at, last: 30).count
end
```

```erb
<%# app/views/admin/dashboard/index.html.erb %>
<%# chartkick 설치 후 %>

<div class="mb-8">
  <h2 class="text-lg font-bold mb-4">조회수 상위 게시글</h2>
  <%= bar_chart @top_posts_data, height: "300px" %>
</div>

<div class="mb-8">
  <h2 class="text-lg font-bold mb-4">최근 30일 회원가입 추이</h2>
  <%= line_chart @registration_trend, height: "200px" %>
</div>
```

### Avatar with Active Storage

```ruby
# app/models/user.rb
has_one_attached :avatar

def display_avatar_url(size: 80)
  if avatar.attached?
    Rails.application.routes.url_helpers.rails_representation_url(
      avatar.variant(resize_to_fill: [size, size]),
      only_path: true
    )
  elsif avatar_url.present?
    avatar_url  # fallback for existing URL strings
  end
end
```

### Badge Display in Profile

```erb
<%# app/views/profiles/show.html.erb %>
<div class="flex flex-wrap gap-2 mt-3">
  <% @user.earned_badges.each do |badge| %>
    <span class="inline-flex items-center px-3 py-1 rounded-full text-xs font-bold bg-tv-gold/20 text-tv-black border border-tv-gold/40">
      <%= badge[:label] %>
    </span>
  <% end %>
</div>
```

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| Trix (ActionText default) | rhino-editor (TipTap-based) | Active since 2022; stable 0.17.x | Bubble menu, image resize, ProseMirror plugin ecosystem |
| rhino-editor 0.17.x | rhino-editor 0.18.x (TipTap v3) | Feb 2025 (approx) | 0.18 breaks rhinoImage/rhinoAttachment — not yet production-safe for image uploads |
| avatar_url string column | Active Storage `has_one_attached` | Rails 5.2+ standard | File upload UI, variant generation, S3-compatible storage |
| Manual SQL for admin stats | chartkick + groupdate | chartkick has been Rails standard since 2013; still maintained | Zero client JS for charts |

**Deprecated/outdated:**
- `import "trix"` / `import "@rails/actiontext"`: Must be removed when switching to rhino-editor — keeping both causes ActionText JS double-registration.
- `avatar_url` direct string storage: Functional but blocks file upload UX — migrate to Active Storage.

## Open Questions

1. **rhino-editor 0.17.x exact last patch version**
   - What we know: 0.17.x is the last pre-TipTap-v3 series; CHANGELOG confirms 0.18.0 removed rhinoImage/rhinoAttachment
   - What's unclear: The exact last 0.17.x version and whether 0.17.x has its own bugs to avoid
   - Recommendation: Check npm for `rhino-editor@latest` vs `rhino-editor@^0.17` during plan; pin to specific minor once verified

2. **chartkick + Vite exact setup**
   - What we know: chartkick gem works with Rails; docs show importmap setup; Vite requires JS import
   - What's unclear: Whether `import "chartkick/chart.js"` works with the Vite bundle in this project, or if `chartkick` gem helper needs separate CDN tag
   - Recommendation: Plan should include a test step — render one chart in dev before building the full dashboard

3. **social_links data model**
   - What we know: No social_links column exists in users table; PROF-01 requires social links display
   - What's unclear: How many social links? Fixed set (GitHub, Twitter, website) or open-ended?
   - Recommendation: Plan with 3 fixed columns (`github_url`, `twitter_url`, `website_url`) — simple migration, no JSON parsing complexity

4. **Existing avatar_url data during migration**
   - What we know: `avatar_url` column exists storing URL strings; some users may have values
   - What's unclear: Whether existing avatar_url values point to third-party URLs (Google/Kakao OAuth avatars) or internal uploads
   - Recommendation: Keep `avatar_url` column as fallback read-only field after adding Active Storage; don't drop the column until confirmed safe

## Sources

### Primary (HIGH confidence)
- `/konnorrogers/rhino-editor` (Context7) - installation, form integration, bubble menu slots, file upload events, CSS imports
- https://rhino-editor.vercel.app/tutorials/usage-with-rails/ - Rails form pattern with `to_trix_html`, hidden field approach
- https://rhino-editor.vercel.app/references/why-rhino-editor - Shadow DOM trade-offs, bundle size (~100kb gzipped)
- Project `db/schema.rb` - confirmed columns: users(points, level, bio, avatar_url), posts(views_count, likes_count)
- Project `app/services/point_service.rb` - LEVEL_THRESHOLDS, POINTS config, level-up logic

### Secondary (MEDIUM confidence)
- https://github.com/KonnorRogers/rhino-editor/blob/main/CHANGELOG.md - 0.18.0 removed rhinoImage/rhinoAttachment (confirmed via WebFetch)
- https://chartkick.com + https://github.com/ankane/chartkick - chartkick one-line helpers, Chart.js backend
- https://github.com/tailwindlabs/tailwindcss/discussions/15556 - Tailwind v4 `:root` vs Shadow DOM `:host` conflict
- https://github.com/tailwindlabs/tailwindcss/issues/15799 - `--spacing` missing in Shadow DOM with Tailwind v4

### Tertiary (LOW confidence)
- WebSearch results on chartkick + groupdate integration patterns (verified against chartkick.com docs)
- rhino-editor 0.18.x image upload alternative — no official replacement documented yet; flagged as open question

## Metadata

**Confidence breakdown:**
- Standard stack: MEDIUM — rhino-editor version strategy confirmed by CHANGELOG; chartkick pattern well-established but Vite setup needs validation
- Architecture: HIGH — form pattern confirmed by official docs; profile/admin patterns are standard Rails
- Pitfalls: HIGH — Shadow DOM/Tailwind conflict confirmed by Tailwind GitHub; 0.18.x regression confirmed by CHANGELOG; others from code inspection

**Research date:** 2026-02-22
**Valid until:** 2026-03-08 (rhino-editor moves fast; re-check 0.18.x image docs before starting 02-01)
