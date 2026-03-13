# Architecture Research

**Domain:** Rails 8 monolith — SEO crawling optimization + Admin 2-column post editor
**Researched:** 2026-03-14
**Confidence:** HIGH (based on direct codebase inspection)

## Current State Audit

### What Already Exists

| Component | Location | State |
|-----------|----------|-------|
| `meta-tags` gem | `Gemfile`, `config/initializers/meta_tags.rb` | Installed, configured (title_limit: 70, description_limit: 160), but `display_meta_tags` is called only in `layouts/application.html.erb` — no view calls `set_meta_tags` |
| `sitemap_generator` gem | `config/sitemap.rb` | Configured, covers posts/pages/skill_packs |
| `SeoHelper` | `app/helpers/seo_helper.rb` | All JSON-LD helpers defined (Article, BreadcrumbList, Organization, WebSite, SoftwareApplication, ItemList, ProfilePage, FAQPage) but never called in any view |
| `robots.txt` | `public/robots.txt` | Static file, allows all bots, disallows `/admin/`, `/auth/`, `/profile/edit`. No Googlebot/Yeti-specific rules. Sitemap line present |
| Post schema | `db/schema.rb` | `seo_title` (string) and `seo_description` (text) columns exist |
| Admin post form | `app/views/admin/posts/_form.html.erb` | 1-column stacked layout — AI draft panel, title, category, status, scheduled_at, pinned, rhino-editor body, seo_title, seo_description fields all stacked vertically |
| `post_params` | `admin/posts_controller.rb` | Already permits `:seo_title`, `:seo_description` |

### What Is Missing

| Feature | Gap |
|---------|-----|
| OG/Twitter meta tags | Not rendered anywhere — `set_meta_tags` is never called in any view |
| JSON-LD in `<head>` | Helpers defined in `SeoHelper` but no `content_for :head` calls exist in any view |
| Canonical URL | Not set anywhere |
| noindex | Not applied to any page |
| Googlebot / Yeti rules in robots.txt | Only generic `User-agent: *` block |
| Search Console verification meta tags | Not present in any layout |
| Admin 2-column layout | Post form is fully 1-column stacked |

---

## Standard Architecture

### System Overview

```
HTTP Request
    |
    v
Rails Router
    |
    +---------------------------+---------------------------+
    |                           |                           |
Public Controllers          Admin Controllers           Static Files
PostsController             Admin::PostsController      public/robots.txt
PagesController             (Admin::BaseController)     public/sitemap.xml
SkillPacksController             |
    |                            |
    v                            v
layouts/application.html.erb   layouts/admin.html.erb
display_meta_tags              (NO meta tag setup)
yield :head                    yield
    |
    v
Individual views
posts/show.html.erb            admin/posts/_form.html.erb
(NO set_meta_tags today)       (1-column stacked today)
(NO JSON-LD today)
    |
    v
SeoHelper (app/helpers/seo_helper.rb)
article_json_ld / website_json_ld / breadcrumb_json_ld / etc.
DEFINED but never called from any view
```

### Component Responsibilities

| Component | Responsibility | Current State |
|-----------|---------------|---------------|
| `layouts/application.html.erb` | Renders all meta tags via `display_meta_tags` and exposes `yield :head` for per-view additions | Partial — `display_meta_tags` wired but no view populates it with `set_meta_tags` |
| `SeoHelper` | Generates JSON-LD blobs as html_safe strings | Complete but unused |
| `public/robots.txt` | Static crawl rules | Needs Googlebot/Yeti sections, `/checkouts/` Disallow, verification paths |
| `admin/posts/_form.html.erb` | Admin post CRUD form | Needs 2-column layout split |
| Post model / schema | Stores `seo_title`, `seo_description` | Done — no migration needed |

---

## Recommended Project Structure

Changes for v1.2 are additive to existing structure. No new directories needed.

```
teovibe/
├── app/
│   ├── helpers/
│   │   └── seo_helper.rb                    # MODIFY: add og_image_url helper for Active Storage blob
│   ├── views/
│   │   ├── layouts/
│   │   │   └── application.html.erb         # MODIFY: add robots yield slot, Search Console meta tags
│   │   ├── posts/
│   │   │   └── show.html.erb                # MODIFY: add content_for :head (set_meta_tags + JSON-LD)
│   │   ├── pages/
│   │   │   └── home.html.erb                # MODIFY: add content_for :head (website + org JSON-LD)
│   │   ├── sessions/
│   │   │   └── new.html.erb                 # MODIFY: add content_for :robots_directive noindex
│   │   ├── checkouts/
│   │   │   └── *.html.erb                   # MODIFY: add content_for :robots_directive noindex
│   │   └── admin/
│   │       └── posts/
│   │           └── _form.html.erb           # MODIFY: 2-column CSS Grid layout
│   └── frontend/
│       └── controllers/
│           └── seo_preview_controller.js    # NEW (optional): character counter for seo fields
├── public/
│   └── robots.txt                           # MODIFY: Googlebot/Yeti blocks, checkouts Disallow
└── config/
    └── sitemap.rb                           # NO CHANGE (already correct)
```

### Structure Rationale

- No new model, migration, or controller is needed. All SEO data fields (`seo_title`, `seo_description`) already exist in the Post schema.
- `SeoHelper` already implements all needed JSON-LD generators — they only need to be called.
- The `meta-tags` gem is already wired in the layout — individual views only need `set_meta_tags` calls.
- The 2-column layout is pure CSS — no Stimulus controller required.

---

## Architectural Patterns

### Pattern 1: meta-tags gem — set_meta_tags in view via content_for

**What:** The `meta-tags` gem splits responsibilities: `set_meta_tags` populates a per-request hash, `display_meta_tags` (in the layout) renders it. Either the controller or the view can call `set_meta_tags`. For TeoVibe, the view approach is correct because `@post` is already available and meta logic belongs alongside its template.

**When to use:** Any public-facing page that should appear in search results with a specific title, description, and OG tags.

**Trade-offs:** View approach keeps meta logic co-located with the template. Controller approach centralises it but adds bloat and splits concerns. For a 1-person project the view approach is simpler to maintain.

**Example (posts/show.html.erb — add at top):**
```erb
<% content_for :head do %>
  <% set_meta_tags(
    title: @post.seo_title.presence || @post.title,
    description: @post.seo_description.presence || @post.body.to_plain_text.truncate(160),
    og: {
      title: @post.seo_title.presence || @post.title,
      description: @post.seo_description.presence || @post.body.to_plain_text.truncate(160),
      type: "article",
      url: request.original_url
    },
    twitter: { card: "summary_large_image" },
    canonical: request.original_url
  ) %>
  <script type="application/ld+json"><%= article_json_ld(@post) %></script>
  <script type="application/ld+json"><%= breadcrumb_json_ld([
    { name: "홈", url: root_url },
    { name: @post.category_name, url: category_posts_url(category_slug: @post.category&.slug) },
    { name: @post.title }
  ]) %></script>
<% end %>
```

The layout already has `display_meta_tags site: "TeoVibe"` and `yield :head` — no layout changes required for this pattern.

### Pattern 2: noindex via content_for yield slot in layout

**What:** Add a `yield :robots_directive` slot in the layout. Views for private or low-value pages emit a noindex directive into that slot. No gem needed.

**Important:** Admin pages use `layouts/admin.html.erb` which does NOT include `display_meta_tags`. Admin pages are already invisible to crawlers — the noindex pattern applies only to public-facing layout pages (login, profile edit, checkout, etc.).

**Example — layout addition (inside `<head>`):**
```erb
<meta name="robots" content="<%= yield(:robots_directive).presence || 'index, follow' %>">
```

**Example — in a view that should be noindexed:**
```erb
<% content_for :robots_directive, "noindex, nofollow" %>
```

**Pages to noindex:** `/sessions/new` (login), `/profile/edit`, `/checkouts/*` (payment flows), `/registrations/new` (signup if public).

### Pattern 3: robots.txt — per-bot directives in static file

**What:** `public/robots.txt` is served as a static file (no Rails controller needed). Add separate `User-agent` blocks for Googlebot and Yeti (Naver bot) with explicit `Allow` and `Disallow` directives.

**Why:** Googlebot and Yeti have different crawl behaviour. Explicit `User-agent: Yeti` blocks are recommended in Naver Search Advisor documentation. The generic `*` block covers all other bots.

**Example:**
```
User-agent: Googlebot
Allow: /
Disallow: /admin/
Disallow: /auth/
Disallow: /profile/edit
Disallow: /checkouts/

User-agent: Yeti
Allow: /
Disallow: /admin/
Disallow: /auth/
Disallow: /profile/edit

User-agent: *
Allow: /
Disallow: /admin/
Disallow: /auth/
Disallow: /profile/edit
Disallow: /checkouts/

Sitemap: https://teovibe.com/sitemap.xml
```

### Pattern 4: Admin 2-column layout — CSS Grid inside existing form partial

**What:** Replace the `space-y-4` single-column wrapper in `admin/posts/_form.html.erb` with a CSS Grid two-column layout. Left column (sticky): metadata fields — title, category, status, scheduled_at, pinned, SEO fields, AI draft panel, action buttons. Right column: rhino-editor body at full height.

**When to use:** The existing admin layout already uses `md:ml-60` sidebar. The content area is wide enough for two columns on desktop. Mobile collapses via `grid-cols-1 lg:grid-cols-[380px_1fr]`.

**Trade-offs:** Pure Tailwind CSS — zero JavaScript. rhino-editor is a Web Component and renders correctly in a constrained column; only needs an explicit `min-h` to show the editor chrome properly.

**Example structure:**
```erb
<%= form_with(model: [:admin, post]) do |f| %>
  <%# Error banner — full width %>

  <div class="grid grid-cols-1 lg:grid-cols-[380px_1fr] gap-6 items-start">
    <%# LEFT: metadata (sticky on scroll) %>
    <div class="space-y-4 lg:sticky lg:top-8">
      <%# AI draft panel %>
      <%# title %>
      <%# category, status, scheduled_at, pinned %>
      <%# seo_title, seo_description %>
      <%# action buttons %>
    </div>

    <%# RIGHT: body editor %>
    <div>
      <label class="block text-sm font-bold mb-1">본문</label>
      <%= f.hidden_field :body, ... %>
      <rhino-editor
        input="<%= f.field_id(:body) %>"
        ...
        class="w-full min-h-[600px] rounded-2xl border border-gray-300"
      ></rhino-editor>
    </div>
  </div>
<% end %>
```

---

## Data Flow

### SEO Meta Tag Flow (post show page)

```
GET /posts/:slug
    |
PostsController#show  (sets @post)
    |
posts/show.html.erb
    | content_for :head =>
    |   set_meta_tags(title, description, og:*, twitter:*, canonical:)
    |   <script type="application/ld+json"> article_json_ld(@post)
    |   <script type="application/ld+json"> breadcrumb_json_ld(...)
    |
layouts/application.html.erb
    | display_meta_tags(site: "TeoVibe")
    |   => <title>, <meta name="description">, <meta property="og:*">, <link rel="canonical">
    | yield :head
    |   => JSON-LD script tags
    |
HTML <head> delivered to browser / Googlebot / Yeti
```

### noindex Flow

```
GET /sessions/new  (or /profile/edit, /checkouts/*)
    |
sessions/new.html.erb
    | content_for :robots_directive, "noindex, nofollow"
    |
layouts/application.html.erb
    | <meta name="robots" content="noindex, nofollow">
    |
Crawler sees noindex, does not index the page
```

### robots.txt Flow

```
GET /robots.txt
    |
Rails static file serving (public/robots.txt)  — no controller, no DB
    |
Googlebot / Yeti reads directives
    |
Sitemap: https://teovibe.com/sitemap.xml  -> crawler fetches sitemap
    |
sitemap_generator serves sitemap.xml.gz   -> crawler discovers post URLs
```

### Admin 2-Column Form Flow

```
GET /admin/posts/:id/edit
    |
Admin::PostsController#edit  (sets @post)
    |
admin/posts/edit.html.erb renders admin/posts/_form.html.erb
    |
_form.html.erb:
    CSS Grid [380px left (sticky) | 1fr right]
    LEFT:  title, category, status, scheduled_at, pinned, seo_title, seo_description, buttons
    RIGHT: rhino-editor body (min-h-[600px])
    |
POST /admin/posts/:id
    |
post_params  (already permits :seo_title, :seo_description — NO CHANGE)
    |
redirect_to admin_posts_path
```

---

## Integration Points

### SEO Features — New vs Modified

| Component | Action | Rationale |
|-----------|--------|-----------|
| `public/robots.txt` | MODIFY | Add Googlebot/Yeti blocks; add `/checkouts/` to Disallow |
| `app/views/layouts/application.html.erb` | MODIFY | Add `<meta name="robots">` yield slot; add Search Console verification meta tags |
| `app/views/posts/show.html.erb` | MODIFY | Add `content_for :head` with `set_meta_tags` + Article + BreadcrumbList JSON-LD |
| `app/views/pages/home.html.erb` | MODIFY | Add `content_for :head` with `website_json_ld` + `organization_json_ld` |
| `app/views/sessions/new.html.erb` | MODIFY | Add `content_for :robots_directive, "noindex, nofollow"` |
| `app/views/checkouts/*.html.erb` | MODIFY | Add `content_for :robots_directive, "noindex, nofollow"` |
| `app/views/profile/edit.html.erb` | MODIFY | Add `content_for :robots_directive, "noindex"` |
| `app/helpers/seo_helper.rb` | MODIFY (minor) | Add `og_description_for(post)` and `og_image_url_for(post)` helpers to DRY repeated logic |
| `config/sitemap.rb` | NO CHANGE | Already covers published posts and correct pages |
| Post model / schema | NO CHANGE | `seo_title` and `seo_description` columns already exist |
| Admin controllers | NO CHANGE | `post_params` already permits all needed fields |

### Admin 2-Column Layout — New vs Modified

| Component | Action | Rationale |
|-----------|--------|-----------|
| `app/views/admin/posts/_form.html.erb` | MODIFY | Replace `space-y-4` wrapper div with CSS Grid `grid-cols-1 lg:grid-cols-[380px_1fr]` |
| `app/views/admin/posts/new.html.erb` | NO CHANGE | Renders `_form` partial — layout change flows through automatically |
| `app/views/admin/posts/edit.html.erb` | NO CHANGE | Same |
| `app/controllers/admin/posts_controller.rb` | NO CHANGE | `post_params` already permits all fields |
| Post model / schema | NO CHANGE | All columns already present |
| New Stimulus controller | OPTIONAL | A lightweight `seo_preview_controller.js` (character counter on seo_title / seo_description) improves UX but is not required |

### Internal Boundaries

| Boundary | Communication | Notes |
|----------|---------------|-------|
| `SeoHelper` to views | Direct ERB helper call | `SeoHelper` is `include`d via `ApplicationHelper` — no wiring change needed |
| `meta-tags` gem to layout | `set_meta_tags` (in view) + `display_meta_tags` (in layout) | Already wired in layout; only missing `set_meta_tags` calls in individual views |
| Admin layout to `meta-tags` | Admin layout does NOT call `display_meta_tags` | Correct — admin pages should not be indexed |
| `rhino-editor` to 2-column grid | Web Component in constrained column | Set `min-h-[600px]` on the editor element; no attribute changes needed |

---

## Build Order (Dependencies)

```
Step 1: robots.txt modification
    No dependencies. Static file. Fastest win. Safe to do first.

Step 2: layouts/application.html.erb — robots yield slot + Search Console meta
    Independent of data model. Enables noindex on any page.
    Must complete BEFORE Step 3.

Step 3: noindex on private/low-value pages (sessions, profile/edit, checkouts)
    Depends on: Step 2 (yield slot must exist first).
    Pages: sessions/new, checkouts/*, profile/edit.

Step 4: posts/show.html.erb — set_meta_tags + JSON-LD
    Depends on: seo_title/seo_description columns (DONE), SeoHelper (DONE),
    display_meta_tags in layout (DONE), yield :head in layout (DONE).
    Independent of Steps 2/3.

Step 5: pages/home.html.erb — website + organization JSON-LD
    Independent of all other steps.
    Uses existing SeoHelper methods.

Step 6: Admin _form.html.erb — 2-column CSS Grid layout
    Fully independent of all SEO steps.
    Can be developed in parallel with any of Steps 1-5.
    No model or controller changes required.
```

Steps 4, 5, and 6 are independent of each other and can be developed in parallel after Step 2 completes.

---

## Anti-Patterns

### Anti-Pattern 1: Calling set_meta_tags in ApplicationController before_action

**What people do:** Add `before_action :set_default_meta_tags` in `ApplicationController` that sets generic defaults, then override in individual controllers.

**Why it's wrong:** For TeoVibe, views already have direct access to `@post`. Controller-level meta forces duplication of model-fetching logic or tight coupling between controller and view concerns. `MetaTags.configure` already handles default limits.

**Do this instead:** Call `set_meta_tags` in `content_for :head` within the individual view template. Defaults are handled by `display_meta_tags site: "TeoVibe"` in the layout.

### Anti-Pattern 2: Rendering JSON-LD via a separate JSON endpoint fetched by JS

**What people do:** Create a `/posts/:slug/json-ld.json` endpoint and inject it into `<head>` using a JavaScript fetch on page load.

**Why it's wrong:** Search engine crawlers may not execute JavaScript during initial indexing. JSON-LD must be present in the initial HTML response for reliable structured data parsing. This is a Google recommendation.

**Do this instead:** Render JSON-LD as `<script type="application/ld+json">` inside `content_for :head` in the ERB view. `SeoHelper` methods already return `html_safe` JSON strings.

### Anti-Pattern 3: Extracting Admin form layout into a Stimulus controller for dynamic toggling

**What people do:** Build a Stimulus controller that dynamically toggles between 1-column and 2-column modes based on screen size or a button click.

**Why it's wrong:** Unnecessary JavaScript. The layout requirement is fixed: always 2-column on desktop, always 1-column on mobile. Tailwind responsive prefixes (`lg:grid-cols-[...]`) handle this with zero JS.

**Do this instead:** CSS Grid with `lg:` responsive prefix in Tailwind. Tailwind v4 supports arbitrary grid values (`grid-cols-[380px_1fr]`). Only the outer wrapper class in `_form.html.erb` needs to change.

### Anti-Pattern 4: Adding noindexed pages to sitemap.rb

**What people do:** Add all URLs to the sitemap "for completeness," including login, profile edit, checkout, and admin pages.

**Why it's wrong:** Having a URL in the sitemap signals "please index this" while a noindex meta tag signals "do not index this." The contradiction wastes crawl budget and Google explicitly recommends against it.

**Do this instead:** Keep `sitemap.rb` as-is. It already limits to `published` posts and specific static pages. Only add a URL to the sitemap if it also gets `index, follow` robots meta.

---

## Scaling Considerations

| Scale | Architecture Adjustments |
|-------|--------------------------|
| Launch phase (current) | Static robots.txt + view-level `set_meta_tags` is sufficient. No meta caching needed. |
| 1k-10k posts | Consider fragment caching for `@post.body.to_plain_text.truncate(160)` if the `body.to_plain_text` call shows in query profiling (ActionText rich text load). |
| Sitemap growth | `sitemap_generator` supports multiple sitemap files natively. Current `config/sitemap.rb` handles this without architecture change when post count exceeds 50k. |

---

## Sources

- Direct codebase inspection: `app/helpers/seo_helper.rb`, `app/views/layouts/application.html.erb`, `app/views/admin/posts/_form.html.erb`, `config/initializers/meta_tags.rb`, `config/sitemap.rb`, `public/robots.txt`, `db/schema.rb`, `db/migrate/20260218053910_create_posts.rb` (HIGH confidence)
- meta-tags gem: view vs controller approach documented in gem README; both patterns are supported (HIGH confidence)
- Google Search Central: JSON-LD must be present in initial HTML for reliable structured data — not dynamically injected (HIGH confidence)
- Google Search Central: URLs with noindex meta should not appear in sitemap (HIGH confidence)
- Naver Search Advisor: explicit `User-agent: Yeti` block recommended (MEDIUM confidence — official Naver documentation)
- Tailwind CSS v4: `grid-cols-[380px_1fr]` arbitrary value syntax supported (HIGH confidence)

---

*Architecture research for: TeoVibe v1.2 SEO + Admin UX*
*Researched: 2026-03-14*
