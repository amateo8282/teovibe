# Project Research Summary

**Project:** TeoVibe — Rails 8.1 creator-led blog community platform enhancement
**Domain:** Creator platform with digital content sales (Rails monolith, subsequent milestone)
**Researched:** 2026-02-22
**Confidence:** MEDIUM

## Executive Summary

TeoVibe is a creator-admin community platform built on Rails 8.1 — closer in concept to a high-quality personal brand site with community engagement than a multi-creator marketplace. The existing monolith already has core features (auth, multi-category board, ActionText, comments, likes, points, notifications, search, admin CMS, Kamal deployment). This milestone adds four capability layers: a richer text editing experience, React-driven interactive UI for the landing page, payment infrastructure scaffolding via Toss Payments, and UI/UX polish through ViewComponent and Flowbite. Ghost is the closest competitive analog; TeoVibe's differentiators are Korea-specific (Toss Payments direct integration, Kakao login) and a creator-admin publishing model with zero platform fee.

The recommended technical approach is to migrate the JavaScript pipeline from ImportMap to vite_ruby (Vite-based bundler) first, since this is a prerequisite for both React components and the Toss Payments SDK. On top of Vite, rhino-editor replaces Trix as the rich text editor — it is the only option that maintains ActionText compatibility without a data migration. React is embedded as islands in ERB views via vite_ruby's component helpers, reserved only for the landing page and highly interactive UI. Toss Payments v2 SDK handles the frontend payment widget client-side; a thin Rails PaymentService calls the Toss Confirm API server-side using Faraday. ViewComponent 4.x + Flowbite provide reusable, testable view components with pre-built Tailwind CSS 4 interactive patterns.

The top risks are: (1) the vite_ruby migration from ImportMap is a high-impact breaking change to the entire JS pipeline and must be verified before other work proceeds; (2) the wrong rich text editor choice can silently corrupt existing post data; (3) payment infrastructure without idempotency keys creates double-charge risk in production; (4) SQLite write lock contention under Solid Queue background jobs is a latent production hazard that worsens as background job volume grows.

## Key Findings

### Recommended Stack

The existing Rails 8.1 app with Hotwire, Tailwind CSS 4.4, Propshaft, and SQLite is a solid foundation. The milestone requires four targeted additions: vite_ruby replaces ImportMap as the JS bundler (required for JSX and TypeScript), rhino-editor replaces Trix in ActionText forms, Toss Payments v2 SDK is integrated via JavaScript entrypoint, and ViewComponent 4.4 adds a structured component layer. No new gems are needed for payments — Faraday (already in Gemfile) handles the Toss Confirm API call.

**Core technologies:**
- **vite_ruby ~3.x (gem) + @vitejs/plugin-react ~4.x**: Replaces ImportMap — the only Rails-native bundler that supports JSX+TypeScript, is Propshaft-compatible, and allows mixing Stimulus with React islands
- **rhino-editor ~0.18.x (vendor bundle via curl)**: TipTap-based Trix replacement; only option that maintains ActionText storage format without data migration. ImportMap-compatible via vendor bundle.
- **react 18.x + react-dom 18.x**: React islands for landing page — interactive animated sections, hero, CTA. React is isolated to non-form contexts only.
- **@tosspayments/tosspayments-sdk v2 (via npm/Vite)**: Official Toss Payments frontend widget. Backend confirmation uses Faraday (already present) calling Toss REST API directly — no Ruby gem needed.
- **view_component ~4.4 (gem)**: Encapsulated, testable Rails view components for all new UI elements. Rails 8.1 support confirmed in February 2026 changelog.
- **flowbite ~3.x (CDN or npm via Vite)**: Pre-built Tailwind CSS 4 interactive component patterns (dropdowns, modals, tabs). No new CSS framework required.

**Critical version requirement:** vite_ruby requires migrating away from all `config/importmap.rb` pins. All existing Stimulus controller imports must be migrated to Vite entrypoints. This is a one-time breaking change; test Stimulus and Turbo carefully afterward.

### Expected Features

The milestone targets enhancement of an already-functional platform. The gap analysis against Ghost (closest analog) shows the main deficits: weak editor UX, no interactive landing page, no payment capability, and partial mobile responsiveness.

**Must have (table stakes — P1 this milestone):**
- Enhanced rich text editor (rhino-editor) — Trix UX is visibly weaker than any modern writing platform
- Responsive mobile layout fixes — 60%+ of content consumption is mobile; broken layout signals an unfinished product
- Navigation UX polish (logged-in vs guest state clarity, mobile hamburger menu) — fundamental for any community platform
- Loading states via Turbo frame indicators — native Turbo feature; blank-screen-on-load signals failures
- Author profile page (bio, avatar, social links, post list) — table stakes for a creator platform; creators need a shareable page
- Interactive landing page (React hero + CTA sections) — static ERB landing pages do not convert; admin CMS sections exist but are static
- Skill pack payment scaffolding (Order model + checkout page stub + Toss SDK init) — required to enable next milestone actual payments
- Related posts widget — session depth improvement, zero-dependency starting point using existing categories

**Should have (competitive advantage — P2 this milestone):**
- Skill pack preview content — "buy blind" digital products convert poorly; Ghost and Gumroad both show previews
- Admin content analytics (view counter + top posts table) — creators need data to guide content strategy
- Email notification preferences — required before any new notification triggers are added
- Gamification display on profiles (level badge, point count) — UI-only on top of existing points/levels data

**Defer (v2+ or next milestone — P3):**
- Full Toss Payments charge flow — separate milestone per PROJECT.md; scaffolding only now
- AI content recommendations — only relevant at higher traffic volumes
- PWA manifest — not conversion-critical at current stage
- Real-time chat/DMs — operational trap for a 1-person platform; threaded comments are sufficient
- PostgreSQL migration — SQLite with WAL handles thousands of users; no current benefit

### Architecture Approach

The existing monolith follows a standard Rails MVC + service layer pattern (PointService, NotificationService already exist). This milestone adds three new subsystems that each integrate with Rails differently: React islands mount client-side via vite_ruby entrypoints within ERB views; Tiptap/rhino-editor syncs to ActionText hidden inputs on form submit; Toss Payments Widget runs entirely client-side and redirects to a Rails controller for server-side confirmation. The key architectural constraint is that React must NOT be mixed into Turbo form flows — the Stimulus controller pattern keeps the rich text editor within the existing form submission pipeline.

**Major components:**
1. **vite_ruby entrypoints + React components (app/javascript/components/landing/)** — landing page islands; props passed from Rails controller via ERB; React state is local and ephemeral
2. **rhino-editor (Web Component, vendor bundle)** — replaces Trix in post forms; keeps ActionText data model intact; no Stimulus controller needed
3. **PaymentsController + PaymentService + Order/Payment models** — two-phase payment commit: client widget initiates, server confirms with Toss API before marking Order paid
4. **ViewComponent 4.x (app/components/)** — reusable UI components replacing duplicated ERB partials; Card, Button, Alert, etc.
5. **Flowbite (CDN or npm)** — interactive UI patterns (dropdowns, modals, tabs) on top of existing Tailwind CSS 4

**Key architectural rule:** Toss secret key lives only in PaymentService (server-side via Rails credentials). The widget client key is the only Toss key that goes to JavaScript. Never expose the secret key in any client-facing code.

### Critical Pitfalls

1. **JSX + ImportMap incompatibility** — ImportMap cannot transpile JSX; React components fail silently or throw "Unexpected token '<'" in production. Prevention: migrate to vite_ruby as the very first task before writing any component code. Verify with `rails assets:precompile`.

2. **Rich text editor data corruption** — Installing RicherText (not rhino-editor) or raw TipTap against existing ActionText columns will produce mixed-format records that render broken HTML for existing posts. Prevention: use rhino-editor only; audit 20+ existing posts in staging before deploying; take database backup before any editor migration.

3. **React + Turbo Drive memory leaks** — Without explicit unmount handling, React component instances accumulate on each Turbo navigation. Prevention: add `turbo:before-render` listener calling unmount handler immediately after React integration; verify with DevTools memory profiling.

4. **Payment without idempotency = double charges** — Toss Payments webhooks deliver on at-least-once guarantee; a naive controller processes the same event twice. Prevention: add `payment_event_id` unique index on Order model before any payment integration begins; webhook handler returns 200 immediately and delegates to background job.

5. **SQLite write lock under Solid Queue** — Concurrent web writes and background job polling contend on the same SQLite lock. Prevention: configure separate `queue.sqlite3`, `cache.sqlite3`, `cable.sqlite3` databases in `database.yml`; enable WAL mode and `busy_timeout=5000` in an initializer.

## Implications for Roadmap

Based on dependency analysis across all research files, the following phase structure is recommended. The critical constraint is that vite_ruby migration must come first — it is a prerequisite for React, Toss Payments SDK, and Flowbite npm integration.

### Phase 1: JavaScript Pipeline Migration (vite_ruby)
**Rationale:** ImportMap cannot handle JSX or the Toss Payments SDK npm package. This is the single most blocking dependency in the entire milestone. Everything downstream (React landing, Toss widget, Flowbite npm) depends on Vite being in place. Doing this first also forces verification that existing Stimulus controllers and Turbo still work before other changes layer on top.
**Delivers:** Vite-based JS bundler replacing ImportMap; all existing Stimulus/Turbo behavior preserved; foundation for React and npm packages
**Addresses:** FEATURES.md — enables interactive landing page and payment widget
**Avoids:** PITFALLS.md Pitfall 2 (JSX + ImportMap incompatibility)
**Stack elements:** vite_ruby ~3.x gem, @vitejs/plugin-react ~4.x
**No deeper research needed** — official vite-ruby docs and Rails 8.1 community articles are thorough

### Phase 2: Infrastructure Hardening (SQLite + ViewComponent)
**Rationale:** Before adding background-job-heavy features (notifications, payment jobs), SQLite multi-DB configuration must be in place. ViewComponent installation is low-risk and unblocks UI work in subsequent phases. This phase has no dependencies on Phase 1.
**Delivers:** Separate SQLite databases for queue/cache/cable; WAL mode + busy_timeout; ViewComponent 4.x installed and first 2-3 partials extracted as components
**Addresses:** FEATURES.md — foundation for all UI/UX polish features
**Avoids:** PITFALLS.md Pitfall 5 (SQLite write lock)
**Stack elements:** view_component ~4.4 gem, SQLite config in database.yml
**No deeper research needed** — ViewComponent docs are authoritative; SQLite multi-DB is well-documented in Rails 8 guides

### Phase 3: Rich Text Editor Upgrade (rhino-editor)
**Rationale:** The editor upgrade has no dependency on Vite (rhino-editor uses vendor bundle via ImportMap or Vite; works with either). However, it is a high-risk operation (data compatibility) and should be isolated from the React work. The editor decision gates all content creation UX improvements.
**Delivers:** rhino-editor replacing Trix in all post forms; TipTap extension ecosystem available; existing ActionText data intact
**Addresses:** FEATURES.md — enhanced rich text editor (P1 table stakes); image upload UX improvement
**Avoids:** PITFALLS.md Pitfall 3 (rich text data corruption); must run staging audit of 20+ posts before deploying
**Stack elements:** rhino-editor ~0.18.x (vendor bundle via curl from unpkg)
**May need phase research** — rhino-editor is a niche gem; Shadow DOM styling in Tailwind CSS 4 context may require investigation

### Phase 4: React Landing Page (Interactive UI)
**Rationale:** Depends on Phase 1 (vite_ruby) being complete. React islands for the landing page are isolated from the editor and payment flows. This phase delivers the highest-visibility conversion improvement.
**Delivers:** Interactive animated landing page hero section; feature showcase; CTA sections; React component architecture established
**Addresses:** FEATURES.md — interactive landing page (P1 differentiator); loading states; navigation UX polish
**Avoids:** PITFALLS.md Pitfall 1 (React + Turbo memory leaks — must implement unmount handler from day one)
**Stack elements:** react 18.x, react-dom 18.x, Flowbite 3.x
**Architecture component:** React islands pattern (vite_ruby entrypoints + ERB react mount points)
**No deeper research needed** — pattern is well-documented; vite_ruby + React integration is confirmed

### Phase 5: Author Profile + Content Discovery
**Rationale:** Depends on React/Vite (Phase 4) being stable. User model migrations (bio, avatar, social links) are isolated from payment infrastructure. This phase addresses table stakes (profile page) and session-depth improvements (related posts).
**Delivers:** Full author profile page (bio, avatar, social links, authored post list, gamification display); related posts widget; error pages (404, 500)
**Addresses:** FEATURES.md — author profile page (P1), related posts widget (P1), gamification display (P2)
**Avoids:** PITFALLS.md — N+1 on post index with user avatars (add .includes(:user) before shipping)
**Stack elements:** Active Storage (existing) for avatar; ViewComponent for profile card
**No deeper research needed** — standard Rails patterns

### Phase 6: Payment Infrastructure Scaffolding (Toss Payments)
**Rationale:** Payment models (Order, Payment) have no React dependency and can be designed in parallel with Phase 4/5, but the checkout page and Toss widget require Vite (Phase 1). The idempotency key and SQLite hardening (Phase 2) must be in place before any payment code ships. Keeping this as a late phase ensures the infrastructure foundations are solid.
**Delivers:** Order model with payment_event_id unique index; Payment model (immutable audit record); PaymentsController skeleton; TossPaymentsService (Faraday confirm); checkout page with Toss v2 widget rendering in test mode; order status page
**Addresses:** FEATURES.md — skill pack payment scaffolding (P1); skill pack preview content (P2)
**Avoids:** PITFALLS.md Pitfall 4 (payment idempotency); security mistake of exposing secret key client-side; PITFALLS.md — rate limiting on payment initiation (Rack::Attack rule)
**Stack elements:** @tosspayments/tosspayments-sdk v2 (via Vite/npm); Faraday (existing gem); Rails credentials for Toss keys
**May need phase research** — Toss Payments webhook signature verification specifics; Rack::Attack config for payment endpoints

### Phase 7: UI/UX Polish + Mobile Responsive Fixes
**Rationale:** Depends on ViewComponent (Phase 2) being installed. This phase is a consolidation pass that addresses all remaining table stakes: responsive layout, loading states, navigation clarity. Best done after core features are in place so there is full context for what needs polish.
**Delivers:** Responsive mobile layout fixes across all board categories; Turbo progress bar styling; skeleton loading states; navigation UX (logged-in/guest clarity, hamburger menu); custom 404/500 error pages; Flowbite interactive patterns (dropdowns, modals, tabs)
**Addresses:** FEATURES.md — all P1 table stakes around UX completeness
**Avoids:** PITFALLS.md — rich text editor bundle lazy-loading (load rhino-editor JS only on edit/new routes)
**Stack elements:** Flowbite 3.x (CDN or npm), ViewComponent, Turbo built-in progress bar, Tailwind CSS 4 responsive classes
**No deeper research needed** — well-documented Tailwind + Hotwire patterns

### Phase Ordering Rationale

- **Phase 1 before all others** — vite_ruby migration is the single hardest dependency; resolves the ImportMap/JSX blocker before any React or npm-based work begins
- **Phase 2 in parallel with Phase 1** — SQLite/ViewComponent has zero overlap with Vite work; can run concurrently to save time
- **Phase 3 isolated** — editor upgrade is high-risk (data compatibility); isolating it prevents regression correlation confusion
- **Phase 4 after Phase 1** — React islands require Vite; this is a hard technical dependency
- **Phase 5 after Phase 4** — profile work is low-risk but benefits from the ViewComponent and React patterns being established
- **Phase 6 late but high value** — payment models can be designed early but widget integration requires Vite (Phase 1) and SQLite hardening (Phase 2) before shipping
- **Phase 7 last** — polish pass makes most sense after all features exist; avoids reworking components as features are added

### Research Flags

Phases likely needing deeper research during planning:
- **Phase 3 (rhino-editor):** Shadow DOM styling with Tailwind CSS 4; rhino-editor v0.18.x custom extension API; Active Storage direct upload integration with rhino-editor (blob URLs in the new Web Component)
- **Phase 6 (Toss Payments):** Webhook signature verification using HMAC-SHA256 with TossPayments secret key; Rack::Attack configuration for Korean payment endpoints; Solid Queue background job pattern for payment confirmation

Phases with standard patterns (skip research-phase):
- **Phase 1 (vite_ruby):** Official docs and Rails 8 community articles are comprehensive; implementation is mechanical
- **Phase 2 (infrastructure):** SQLite multi-DB is well-documented in Rails 8 official guides; ViewComponent 4.x docs are authoritative
- **Phase 4 (React landing):** vite_ruby + React pattern is well-established; no novel integration required
- **Phase 5 (profile/discovery):** Pure Rails patterns (model migration, partials, scopes)
- **Phase 7 (UI polish):** Tailwind + Hotwire responsive patterns are thoroughly documented

## Confidence Assessment

| Area | Confidence | Notes |
|------|------------|-------|
| Stack | MEDIUM | Core choices (vite_ruby, rhino-editor, ViewComponent) are HIGH; Toss Payments Ruby integration is MEDIUM (no official gem, direct HTTP pattern confirmed but not tested against Rails 8.1 specifically); vite_ruby/Propshaft exact compatibility is MEDIUM (community-confirmed, not officially documented) |
| Features | MEDIUM-HIGH | Feature list verified against Ghost/Substack/Circle; existing codebase features well-documented; competitor analysis sourced from official sites |
| Architecture | HIGH | React islands pattern, Stimulus-controller-for-Tiptap, and payment two-phase commit are all well-documented patterns with multiple confirmed Rails 8 implementations |
| Pitfalls | MEDIUM | React/Turbo lifecycle and SQLite lock issues are confirmed via GitHub issues and production incident reports; rhino-editor ActionText compatibility confirmed via official docs; payment idempotency is general best practice confirmed by multiple payment engineering sources |

**Overall confidence:** MEDIUM

### Gaps to Address

- **rhino-editor Tailwind CSS 4 Shadow DOM styling:** rhino-editor uses Shadow DOM (Web Components). Tailwind CSS 4 utility classes do not penetrate Shadow DOM boundaries. Custom CSS variables or ::part() selectors will be needed. Verify in Phase 3 planning.
- **vite_ruby exact version for Rails 8.1.2 + Propshaft 1.3.1:** Check RubyGems at install time; the ~3.x pin is community-confirmed but not officially documented by the Rails core team. Run `bundle update vite_rails` and test immediately.
- **Toss Payments webhook signature verification:** The PITFALLS file confirms this is a security requirement; the exact HMAC algorithm and header name used by Toss Payments was not retrieved. Verify against official Toss docs during Phase 6 planning.
- **FTS5 index and ActionText sync (existing tech debt):** PITFALLS.md references a CONCERNS.md note that FTS5 is indexed on `posts.body` but content lives in `action_text_rich_texts.body`. This means search does not find new posts. This must be fixed alongside the editor upgrade (Phase 3) — it is existing debt that the editor change will make more visible.
- **Active Storage production disk vs S3:** PITFALLS.md flags that `disk` service in production generates localhost URLs. If the current deployment uses `disk` service, this needs to be addressed before skill pack downloads go live. Verify `config/storage.yml` against Kamal deployment config.

## Sources

### Primary (HIGH confidence)
- viewcomponent.org — v4.4.0 released 2026-02-13, Rails 8.1 support confirmed
- Context7 /konnorrogers/rhino-editor — ImportMap installation, ERB form integration, ActionText compatibility
- Context7 /ueberdosis/tiptap-docs — TipTap core API, Stimulus controller integration
- Context7 /shakacode/react_on_rails — react_on_rails setup, Vite integration patterns
- flowbite.com/docs/getting-started/rails/ — Tailwind CSS 4 compatibility confirmed
- docs.tosspayments.com — v2 SDK widget flow, confirm API endpoint, Basic auth pattern
- rhino-editor.vercel.app — official site, version confirmation, ActionText compatibility rationale
- react-rails GitHub Issues #1028, #1184, #884 — Turbo Drive unmount lifecycle confirmed broken; workarounds documented

### Secondary (MEDIUM confidence)
- vite-ruby.netlify.app — Rails integration guide, Propshaft compatibility
- railsdrop.com (2025) — React + Rails 8 + ESBuild guide, practical integration steps
- fractaledmind.com — SQLite on Rails concurrency; WAL mode + busy_timeout configuration
- a1w.ca — SQLite database is locked in Rails 8 production confirmation
- maxencemalbois.medium.com — Trix-to-TipTap migration in Rails 7 + Stimulus
- evilmartians.com/chronicles/viewcomponent-in-the-wild — ViewComponent best practices
- circle.so/blog — Community platform comparison, feature expectations
- ghost.org — Feature comparison, creator platform patterns
- baymard.com — Checkout UX best practices

### Tertiary (LOW confidence)
- WebSearch "react-rails gem 2025 Rails 8" — General community direction; no authoritative single source
- WebSearch "vite_ruby Rails 8 Propshaft 2025" — Community articles confirming compatibility; not official docs

---
*Research completed: 2026-02-22*
*Ready for roadmap: yes*
