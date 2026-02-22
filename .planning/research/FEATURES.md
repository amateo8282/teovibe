# Feature Research

**Domain:** Creator-led blog community platform with digital content sales (Rails monolith)
**Researched:** 2026-02-22
**Confidence:** MEDIUM-HIGH

## Context: What Already Exists

The following features are already implemented in TeoVibe and are NOT in scope for this milestone:

- Email/password + Google/Kakao OAuth login
- Multi-category board (blog, tutorial, free_board, qna, portfolio, notice)
- ActionText/Trix rich text editor (functional, but UX is weak)
- Comments and nested replies
- Polymorphic likes system
- Points system with levels
- Notification system
- Skill pack download (free, no payment)
- SQLite FTS5 full-text search
- SEO meta tags and sitemap
- Admin CMS (posts, users, skill packs, inquiries, landing sections)
- Turbo Streams real-time UI
- Kamal + Docker deployment

The Active milestone focuses on: editor UX, landing page interactivity, digital sales scaffolding, UI/UX polish, and content experience improvement.

---

## Feature Landscape

### Table Stakes (Users Expect These)

Features that users assume exist on any modern creator community platform. Missing these = product feels incomplete or amateurish.

| Feature | Why Expected | Complexity | Notes |
|---------|--------------|------------|-------|
| Capable rich text editor with image upload | Every modern writing platform (Notion, Medium, Ghost) has this. Trix without enhancements feels like 2015. | MEDIUM | Trix enhancement or Rhino Editor (Tiptap-based, ActionText-compatible). rhino-editor gem is a direct Rails option. |
| Responsive mobile layout | 60%+ of content consumption is mobile. Any broken layout on mobile signals an unfinished product. | MEDIUM | Tailwind responsive classes exist but reported as incomplete in places. |
| Loading states and skeleton screens | Users expect visual feedback while waiting. Blank screens signal failures. | LOW | Turbo frames can show loading indicators natively. |
| Navigation clarity (logged-in vs guest state) | Users need to know where they are, who they are, and what they can do. Unclear nav causes bouncing. | LOW | Navigation component refactor, not new feature. |
| User profile page with authored content | Every community platform shows what a user has written/contributed. Profile-less communities feel anonymous and untrustworthy. | MEDIUM | Profile model exists (User), but profile page completeness is unknown from codebase doc. |
| Content discovery (related posts / recent posts) | Users who finish reading one post expect a "what's next." Without this, sessions end. | LOW | Sidebar or section with related/recent posts. Query is straightforward. |
| Image upload in editor body | Authors cannot publish compelling posts without inline images. Text-only posts underperform. | MEDIUM | ActionText/Active Storage handles this, but the Trix UX for image upload is poor. Enhancement is the goal. |
| Error pages (404, 500) | Missing custom error pages make the app feel unfinished and expose framework internals. | LOW | Rails error pages, custom ERB templates. |
| Email notification opt-out | Users expect to control notification email preferences. Missing this = spam complaints. | MEDIUM | Existing notification model needs email delivery layer and preference flags. |

### Differentiators (Competitive Advantage)

Features that set TeoVibe apart from a generic Rails blog scaffold. These align with the core value: "a community platform worth re-visiting with production-level polish."

| Feature | Value Proposition | Complexity | Notes |
|---------|-------------------|------------|-------|
| Interactive animated landing page (React-in-Rails) | Static ERB landing pages do not convert visitors. Ghost, Circle, and Substack all use animated hero sections with clear CTAs. An interactive landing page signals seriousness and drives signups. | HIGH | react-rails gem approach. Rails renders React components server-side for SEO, client-side for interactivity. Key sections: hero with animation, feature showcase, social proof, CTA. |
| Skill pack payment scaffolding (Toss Payments) | Competitors like Gumroad charge 10%. Creator-owned payment layer with Toss Payments is a Korea-specific advantage. Zero platform cut is a real differentiator for Korean creators. | HIGH | Model/route/UI scaffolding only for this milestone. Actual charge flow in next milestone. Scaffold: Order model, checkout page stub, Toss Payments client-side SDK init. |
| Enhanced editor with slash commands / block formatting | Notion-style block editing is now user expectation for serious writing tools. Ghost editor, TipTap's Bubble Menu, and slash commands all signal a modern platform. | HIGH | Rhino Editor (TipTap for ActionText) or direct TipTap Stimulus integration. Slash commands, bubble menu, better image drag/drop. |
| Author profile page with portfolio-style layout | Creators need a page they are proud to share publicly. A well-designed author page doubles as a marketing asset. Ghost does this well with author bios, post count, social links. | MEDIUM | Extend User profile: avatar upload, bio, social links, authored post list with stats. |
| Content recommendation / related posts algorithm | Platforms with "readers also enjoyed" sections increase session depth significantly. Ghost uses tag-based related posts. Simple tag overlap scoring is enough to start. | MEDIUM | Tag-based similarity scoring on Post. No ML needed. Sidebar widget or post-footer section. |
| Skill pack preview / sample content | Gumroad and Payhip both show previews before purchase. "Buy blind" digital products convert poorly. Preview mode increases purchase confidence. | MEDIUM | SkillPack model needs preview_content field (ActionText or structured). Display on skill pack show page. |
| Gamification display on profile (badges, level, points) | Points and levels already exist in the system. Surfacing them visually on profiles creates social proof and motivates contribution. | LOW | UI-only: render level badge and point count on profile and post author sections. |
| Admin content analytics (basic) | Creators/admins need to know which posts perform. Without analytics, content strategy is guesswork. Ghost shows views, member growth. | MEDIUM | Post view counter (already exists per download model pattern). Admin dashboard chart with Chartkick or simple ERB table of top posts by views/likes. |

### Anti-Features (Commonly Requested, Often Problematic)

Features that appear valuable but create disproportionate complexity, maintenance burden, or distract from the core value proposition of TeoVibe.

| Feature | Why Requested | Why Problematic | Alternative |
|---------|---------------|-----------------|-------------|
| Real-time chat / DMs | "Community" implies live conversation. Discord-style chat feels engaging. | Requires WebSocket infrastructure, moderation tools, message retention policy, abuse vectors. For a 1-person operated platform this is an operational trap. Already listed as Out of Scope in PROJECT.md. | Threaded comments on posts provide sufficient async conversation. Forum-style QnA board already exists. |
| Full collaborative editing (Google Docs-style) | TipTap supports Y.js collaboration. It sounds like a differentiator. | Requires persistent document server (Y.js provider), conflict resolution, presence indicators. Massive complexity for a blogging platform where authors write alone. | Single-author editor with autosave draft support. |
| Algorithmic content feed (social media style) | Users are used to feeds from Twitter/Instagram. | Ranked feeds require engagement signal collection, ranking model, A/B testing infrastructure. For current traffic levels this is over-engineering. Creates "filter bubble" problem in small communities. | Simple chronological "latest posts" list with category filters. |
| Mobile app (iOS/Android) | Creators want native app presence. | Separate codebase, app store approval cycles, push notification infrastructure. Web-first with responsive design delivers 80% of the value at 5% of the cost. Already listed as Out of Scope in PROJECT.md. | PWA-ready responsive web (meta viewport, web manifest). |
| User-generated skill packs / marketplace | Multiple creators selling on the platform seems like growth. | Requires seller onboarding, payout flows, dispute resolution, moderation, tax reporting. Completely different product from a creator-admin CMS. | Admin-controlled skill pack publishing only for this stage. |
| AI content generation built-in | "AI writing assistant" is a common feature request. | LLM API costs, prompt injection risks, content quality assurance responsibility. Adds a recurring operational cost and potential brand risk if AI generates bad content. | Focus on editor UX improvements that help human writers. |
| Comment voting / karma system | Reddit-style upvoting feels like community engagement. | Requires hiding/burying negative comments, moderation edge cases, vote manipulation prevention. Existing like system on comments is sufficient. | Keep existing comment likes. Hotness ranking for posts (likes + comments + recency). |
| PostgreSQL migration | "Production platforms use Postgres." | SQLite with proper configuration handles thousands of users. Migration requires schema audit, type changes, index review, deployment changes. Major risk for no current benefit. Already listed as Out of Scope in PROJECT.md. | SQLite with WAL mode + Litestream backup. |

---

## Feature Dependencies

```
[Skill Pack Preview Content]
    └──requires──> [SkillPack model preview_content field]

[Skill Pack Payment Scaffolding]
    └──requires──> [Order model + checkout route]
                       └──requires──> [Toss Payments SDK init]

[Interactive Landing Page (React)]
    └──requires──> [react-rails gem configured]
                       └──requires──> [Webpacker/esbuild React build pipeline]

[Enhanced Rich Text Editor]
    └──requires──> [Rhino Editor gem OR TipTap Stimulus controller]
                       └──enhances──> [ActionText integration (if Rhino)]

[Author Profile Page]
    └──requires──> [User model bio/social fields]
    └──enhances──> [Gamification Display (badges, level)]

[Content Recommendation]
    └──requires──> [Post tagging (tags exist if category-based or separate tag model)]

[Admin Content Analytics]
    └──requires──> [Post view counter (model + increment logic)]
```

### Dependency Notes

- **Skill Pack Payment Scaffolding requires Order model first:** The checkout UI cannot be built without a model to hold order state. Order model (user, skill_pack, amount, status, toss_payment_key) is the foundation.
- **Interactive Landing Page requires React build pipeline:** react-rails gem needs esbuild or Webpacker configured. This is a project-level config change, not just a component. Must be done before any React component work.
- **Enhanced Editor decision gates everything:** If Rhino Editor (rhino-editor gem) is chosen, it stays within ActionText. If bare TipTap via Stimulus is chosen, ActiveStorage attachment handling must be wired manually. Decision must be made first.
- **Author Profile depends on User model extension:** Adding avatar (Active Storage), bio (string), social_links (JSON or individual string columns) to User model requires a migration. This blocks the profile page view work.
- **Content Recommendation is low-risk dependency:** Tags exist via the category enum. Simple same-category recent posts is a zero-dependency starting point. True tag-based similarity needs a Tag model and joins.

---

## MVP Recommendation

For this milestone (enhancement of existing Rails 8.1 platform), the recommended priorities in order:

### Launch With (This Milestone)

- [ ] Responsive layout fixes — foundational; broken mobile = users leave. Zero new models.
- [ ] Navigation UX polish — logged-in/guest state clarity, mobile hamburger menu. Zero new models.
- [ ] Loading states (Turbo frame loading indicators) — Turbo native, very low effort.
- [ ] Enhanced rich text editor (Rhino Editor or TipTap) — single biggest UX gap identified. Requires editor gem decision.
- [ ] Author profile page (bio, avatar, social links, post list) — table stakes for any creator platform. Requires User model migration.
- [ ] Interactive landing page (React hero section, at minimum) — conversion-focused; admin landing sections exist but are static ERB. React component for hero + CTA.
- [ ] Skill pack payment scaffolding (Order model + checkout page stub) — enables next milestone actual payments.
- [ ] Skill pack preview content — improves conversion before payment is live.
- [ ] Related posts widget — session depth improvement, low complexity.

### Add After Validation (v1.x)

- [ ] Admin content analytics (views, likes, top posts table) — useful once traffic exists to measure.
- [ ] Email notification preferences — needed before any email delivery is added.
- [ ] Gamification display on profile (level badge, point count) — UI-only on top of existing data.

### Future Consideration (v2+)

- [ ] Actual Toss Payments charge flow — separate milestone per PROJECT.md constraints.
- [ ] AI content recommendations — only relevant at higher traffic volumes.
- [ ] PWA manifest — useful but not conversion-critical at current stage.

---

## Feature Prioritization Matrix

| Feature | User Value | Implementation Cost | Priority |
|---------|------------|---------------------|----------|
| Responsive layout fixes | HIGH | LOW | P1 |
| Navigation UX polish | HIGH | LOW | P1 |
| Loading states | MEDIUM | LOW | P1 |
| Enhanced rich text editor | HIGH | HIGH | P1 |
| Author profile page | HIGH | MEDIUM | P1 |
| Interactive landing page (React hero) | HIGH | HIGH | P1 |
| Skill pack payment scaffolding | HIGH | MEDIUM | P1 |
| Related posts widget | MEDIUM | LOW | P1 |
| Skill pack preview content | MEDIUM | MEDIUM | P2 |
| Admin content analytics | MEDIUM | MEDIUM | P2 |
| Email notification preferences | MEDIUM | MEDIUM | P2 |
| Gamification display on profile | LOW | LOW | P2 |
| Full Toss Payments charge flow | HIGH | HIGH | P3 (next milestone) |

**Priority key:**
- P1: Must have for this milestone
- P2: Should have, add when possible within milestone
- P3: Future milestone

---

## Competitor Feature Analysis

| Feature | Ghost | Substack | Circle | TeoVibe Current | TeoVibe Target |
|---------|-------|----------|--------|-----------------|----------------|
| Rich text editor | Custom (impressive) | Solid | Basic | Trix (weak UX) | TipTap/Rhino (MEDIUM) |
| Membership tiers | Yes (Stripe) | Yes (10% fee) | Yes | None | Scaffolding only |
| Landing page | Theme-based | Profile page | Spaces | Admin-managed static ERB | React interactive |
| Author profile | Yes | Yes | Yes | Minimal | Full profile page |
| Digital product sales | No (subscriptions only) | No | No | Free download only | Payment scaffolding |
| Content recommendations | Tag-based | Algorithmic | None | None | Tag/category based |
| Analytics for creator | Built-in | Basic | Basic | None | View counter + admin table |
| Mobile responsive | Yes | Yes | Yes | Partial (reported gaps) | Full responsive |
| Zero platform fee | Yes | No (10%) | No | N/A | Yes (Toss direct) |

**Key insight:** Ghost is the closest analog. It wins on editor quality, analytics, and member management. TeoVibe's differentiator is Korea-specific (Toss Payments, Kakao login) and creator-admin model (1 admin produces content, community responds). This is closer to a high-quality personal brand site with community than a marketplace.

---

## Sources

- Circle community platform comparison: [https://circle.so/blog/best-community-platforms](https://circle.so/blog/best-community-platforms) — MEDIUM confidence (WebFetch verified)
- Rich text editor framework comparison: [https://liveblocks.io/blog/which-rich-text-editor-framework-should-you-choose-in-2025](https://liveblocks.io/blog/which-rich-text-editor-framework-should-you-choose-in-2025) — MEDIUM confidence (WebFetch verified)
- Rhino Editor (TipTap for Rails/ActionText): [https://github.com/KonnorRogers/rhino-editor](https://github.com/KonnorRogers/rhino-editor) — HIGH confidence (GitHub source)
- Rails decoupling Trix from ActionText: [https://blog.saeloun.com/2025/09/12/rails-action-text-trix-gem/](https://blog.saeloun.com/2025/09/12/rails-action-text-trix-gem/) — HIGH confidence (official Rails blog coverage)
- Ghost creator platform features: [https://ghost.org/creators/](https://ghost.org/creators/) — HIGH confidence (official docs, WebFetch verified)
- Ghost vs Substack fee comparison: [https://ghost.org/vs/substack/](https://ghost.org/vs/substack/) — HIGH confidence (official)
- Landing page conversion features 2026: [https://www.saasframe.io/blog/10-saas-landing-page-trends-for-2026-with-real-examples](https://www.saasframe.io/blog/10-saas-landing-page-trends-for-2026-with-real-examples) — MEDIUM confidence (WebSearch)
- Community engagement drivers: [https://www.storyprompt.com/blog/community-platforms](https://www.storyprompt.com/blog/community-platforms) — MEDIUM confidence (WebFetch verified)
- Checkout UX best practices: [https://baymard.com/blog/current-state-of-checkout-ux](https://baymard.com/blog/current-state-of-checkout-ux) — HIGH confidence (Baymard is authoritative on checkout UX)
- Creator platform comparison (Circle, Disco, Mighty Networks): [https://circle.so/blog/best-content-creator-platforms](https://circle.so/blog/best-content-creator-platforms) — MEDIUM confidence (WebSearch, Circle is biased but thorough)

---

*Feature research for: Creator-led blog community platform with digital content sales (Rails 8.1)*
*Researched: 2026-02-22*
