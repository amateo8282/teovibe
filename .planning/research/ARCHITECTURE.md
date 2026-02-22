# Architecture Research

**Domain:** Rails 8.1 blog-community platform — React component integration, rich text editor enhancement, payment infrastructure
**Researched:** 2026-02-22
**Confidence:** HIGH (React/Rails integration patterns), MEDIUM (editor integration), MEDIUM (Toss Payments server flow)

---

## Standard Architecture

### System Overview

The existing monolith adds three new subsystems in this milestone. Each subsystem integrates differently with the Rails core:

```
┌───────────────────────────────────────────────────────────────────────────┐
│                          Browser / Client                                  │
│  ┌──────────────────┐  ┌──────────────────┐  ┌──────────────────────────┐ │
│  │  Turbo/Stimulus  │  │  React Components │  │  Toss Payments Widget    │ │
│  │  (existing UX)   │  │  (landing page,  │  │  (client-side JS only)   │ │
│  │                  │  │   interactive UI) │  │                          │ │
│  └────────┬─────────┘  └────────┬──────────┘  └────────────┬─────────────┘│
└───────────┼────────────────────┼─────────────────────────┼──────────────┘
            │ Turbo Frames/Streams│ react_component() helper │ redirect + paymentKey
            ▼                    ▼                           ▼
┌───────────────────────────────────────────────────────────────────────────┐
│                          Rails 8.1 Monolith                                │
│                                                                            │
│  ┌─────────────────────────────────────────────────────────────────────┐  │
│  │                     Controller Layer                                 │  │
│  │  PagesController  PostsBaseController  PaymentsController           │  │
│  │  (renders React   (renders ERB with   (confirms with Toss API)     │  │
│  │   props to ERB)    Trix/Tiptap)                                     │  │
│  └──────────────────────────┬──────────────────────────────────────────┘  │
│                             │                                              │
│  ┌──────────────────────────▼──────────────────────────────────────────┐  │
│  │                      Service Layer                                   │  │
│  │  PointService  NotificationService  PaymentService (NEW)            │  │
│  └──────────────────────────┬──────────────────────────────────────────┘  │
│                             │                                              │
│  ┌──────────────────────────▼──────────────────────────────────────────┐  │
│  │                       Model Layer                                    │  │
│  │  User  Post  SkillPack  Order (NEW)  Payment (NEW)                  │  │
│  └──────────────────────────┬──────────────────────────────────────────┘  │
│                             │                                              │
│                             ▼                                              │
│                   SQLite + Active Storage                                  │
└───────────────────────────────────────────────────────────────────────────┘
            │                    │                           │
            ▼                    ▼                           ▼
     Turbo Stream           ESBuild           Toss Payments API (external)
     responses           (React bundles)
```

### Component Responsibilities

| Component | Responsibility | Communicates With |
|-----------|----------------|-------------------|
| Turbo/Stimulus (existing) | Form submissions, inline interactions, real-time partial updates | Rails controllers via Turbo Frames/Streams |
| React Components (new) | Landing page hero, interactive carousels, animated sections | Rails via `react_component()` ERB helper; receives props from controller |
| Tiptap Editor (new) | Rich text editing; replaces or enhances Trix in post form | Rails via hidden `<input>` synced on form submit; ActionText body field |
| Toss Payments Widget (new) | Client-side payment UI, payment method selection | Browser-to-Toss API directly; redirects back to Rails on completion |
| PagesController | Serves landing page, passes LandingSection data as props to React | React component props, ERB layout |
| PaymentsController (new) | Handles Toss callback redirect, calls PaymentService to confirm | PaymentService, Order model |
| PaymentService (new) | HTTP call to Toss Payments API to authorize payment, updates Order status | Toss Payments REST API (external), Order/Payment models |
| Order model (new) | Represents a purchase intent: user, sku, amount, status | SkillPack, User, Payment |
| Payment model (new) | Immutable record of Toss payment result | Order (belongs_to) |

---

## Build Order

Build dependencies between subsystems determine phase sequencing:

```
Phase A: React + JSBundling setup
    ↓  (build infrastructure ready)
Phase B: React landing page components
    ↓  (React proven working in monolith)
Phase C: Tiptap editor integration (Stimulus controller)
    ↑  (independent of Phase B, can parallel if needed)
Phase D: Order + Payment models + PaymentsController scaffold
    ↓  (models exist)
Phase E: Toss Payments Widget + client flow + PaymentService confirm
    ↓  (full server + client integration)
Phase F: UI/UX polish, profile improvements, content recommendations
```

**Phase A must come first.** React components and Tiptap both require the JSBundling+ESBuild pipeline. The existing Rails 8.1 app uses Importmap by default; Importmap cannot transpile JSX. Switching to `jsbundling-rails` with ESBuild is a prerequisite for both React and modern Tiptap usage.

**Phase D (payment models) has no React dependency** and can be scaffolded in parallel with Phase B/C, but Phase E (actual payment flow) requires both the models and the frontend widget.

---

## Recommended Project Structure

New additions to the existing `app/` tree:

```
app/
├── javascript/
│   ├── application.js              # existing Stimulus entry
│   ├── components/                 # NEW: React components (JSX)
│   │   ├── landing/
│   │   │   ├── LandingPage.jsx     # top-level landing page shell
│   │   │   ├── HeroSection.jsx     # animated hero
│   │   │   ├── FeaturesSection.jsx # feature grid
│   │   │   └── CtaSection.jsx      # call-to-action
│   │   └── index.js                # ReactOnRails/react-rails registration
│   └── controllers/
│       ├── tiptap_controller.js    # NEW: Stimulus controller wrapping Tiptap
│       └── payment_controller.js   # NEW: Stimulus controller for Toss widget
├── controllers/
│   └── payments_controller.rb      # NEW: handles Toss callback + confirmation
├── models/
│   ├── order.rb                    # NEW: purchase intent
│   └── payment.rb                  # NEW: immutable Toss result record
├── services/
│   └── payment_service.rb          # NEW: HTTP confirm call to Toss API
└── views/
    ├── pages/
    │   └── home.html.erb           # MODIFIED: uses react_component() helper
    └── payments/
        ├── new.html.erb            # checkout page (Toss widget mount point)
        └── success.html.erb        # post-payment confirmation
```

### Structure Rationale

- **app/javascript/components/**: Separates React components from Stimulus controllers. All JSX lives here and is registered for Rails view embedding.
- **app/javascript/controllers/tiptap_controller.js**: Tiptap is initialized as a Stimulus controller, not a React component. This avoids mixing React into the post editor form, where Turbo handles submission. The Stimulus controller syncs editor HTML into the existing ActionText hidden input before submit.
- **app/models/order.rb + payment.rb**: Two separate models because Order is mutable (status changes: pending → paid → fulfilled) while Payment is an immutable append-only record of what Toss returned.
- **app/services/payment_service.rb**: Follows existing service layer pattern (PointService, NotificationService). The HTTP call to Toss API belongs here, not in the controller.

---

## Architectural Patterns

### Pattern 1: React Islands in ERB (react_component helper)

**What:** Render isolated React components within existing ERB templates. Rails controller collects data, passes as JSON props via `react_component()` helper. React mounts client-side into the div rendered by the helper.

**When to use:** Landing page sections that require animation, interactivity, or complex state not worth implementing in Stimulus. Do NOT use for server-rendered content that must be SEO-crawlable without SSR (prerender: false is default for react-rails without Node SSR setup).

**Trade-offs:** Simple to adopt (no SPA infrastructure), mounts after Rails page load (slight TTFI delay), no TypeScript required but supported. Each React island is isolated — islands do not share React state by default.

**Build requirement:** jsbundling-rails + ESBuild replaces Importmap for JSX transpilation. Importmap cannot handle JSX; this is a hard constraint confirmed by official Rails importmap documentation.

**Example:**
```ruby
# app/controllers/pages_controller.rb
def home
  @landing_sections = LandingSection.ordered.as_json(include: :section_cards)
  @props = { sections: @landing_sections, hero_title: "TeoVibe" }
end
```
```erb
<!-- app/views/pages/home.html.erb -->
<%= react_component("LandingPage", props: @props) %>
```
```javascript
// app/javascript/components/index.js
import ReactOnRails from 'react-on-rails'; // or react-rails equivalent
import LandingPage from './landing/LandingPage';
ReactOnRails.register({ LandingPage });
```

### Pattern 2: Tiptap as Stimulus Controller (Editor-to-Hidden-Input sync)

**What:** Mount Tiptap on a `div[contenteditable]` via a Stimulus controller. On form submit, read `editor.getHTML()` and write into the ActionText hidden input that Rails already processes. No React involved.

**When to use:** Post creation/editing forms. Keeps the editor within the existing Turbo form submission flow. ActionText body is already stored as HTML; Tiptap outputs standard HTML — they are compatible.

**Trade-offs:** Tiptap's HTML output dialect may differ subtly from Trix/ActionText HTML. Images attached via ActionText's blob system require custom Tiptap extension to call Active Storage upload endpoint. The Stimulus approach avoids React complexity in a form context.

**Example:**
```javascript
// app/javascript/controllers/tiptap_controller.js
import { Controller } from "@hotwired/stimulus"
import { Editor } from '@tiptap/core'
import StarterKit from '@tiptap/starter-kit'

export default class extends Controller {
  static targets = ["editor", "input"]

  connect() {
    this.editor = new Editor({
      element: this.editorTarget,
      extensions: [StarterKit],
      content: this.inputTarget.value || '',
      onUpdate: ({ editor }) => {
        this.inputTarget.value = editor.getHTML()
      }
    })
  }

  disconnect() {
    this.editor.destroy()
  }
}
```
```erb
<!-- app/views/posts/new.html.erb -->
<div data-controller="tiptap">
  <div data-tiptap-target="editor"></div>
  <%= f.hidden_field :body, data: { tiptap_target: "input" } %>
</div>
```

### Pattern 3: Payment Two-Phase Commit (Client Widget + Server Confirm)

**What:** Toss Payments uses a two-phase flow. Phase 1 (client): render Toss Widget, user completes payment, Toss redirects to your `successUrl` with `paymentKey`, `orderId`, `amount`. Phase 2 (server): Rails `PaymentsController#success` calls `PaymentService.confirm(payment_key:, order_id:, amount:)` which makes a POST to Toss API. Only after server confirmation is Order status updated to `paid`.

**When to use:** All skill pack purchases. The client-side redirect alone is NOT sufficient to mark an order paid — server-side confirmation is mandatory to prevent fraud.

**Trade-offs:** Requires keeping Order in `pending` state until server confirms. If user closes browser before Rails confirms, Order stays `pending` and requires reconciliation or webhook handling. Toss provides webhooks to handle this edge case (out of scope for this milestone).

**Example:**
```ruby
# app/services/payment_service.rb
class PaymentService
  TOSS_CONFIRM_URL = "https://api.tosspayments.com/v1/payments/confirm"

  def self.confirm(payment_key:, order_id:, amount:)
    order = Order.find_by!(toss_order_id: order_id)
    raise "Amount mismatch" unless order.amount == amount.to_i

    response = HTTP.basic_auth(user: ENV["TOSS_SECRET_KEY"], pass: "")
                   .post(TOSS_CONFIRM_URL, json: {
                     paymentKey: payment_key,
                     orderId: order_id,
                     amount: amount
                   })

    if response.status.success?
      payment_data = response.parse
      order.transaction do
        order.update!(status: :paid)
        Payment.create!(
          order: order,
          toss_payment_key: payment_key,
          method: payment_data["method"],
          raw_response: payment_data.to_json
        )
      end
      order
    else
      raise PaymentConfirmationError, response.body.to_s
    end
  end
end
```

---

## Data Flow

### React Landing Page Flow

```
Admin saves LandingSection records (existing CMS)
    ↓
GET / → PagesController#home
    ↓
LandingSection.ordered.as_json → @props hash
    ↓
ERB: react_component("LandingPage", props: @props)
    ↓ (client-side mount)
React renders animated sections from props data
    ↓ (no server round-trip for section display)
User clicks CTA → standard Rails link / Turbo navigation
```

### Rich Text Editor (Tiptap) Flow

```
User navigates to /blogs/new
    ↓
Stimulus: tiptap_controller#connect fires
    ↓
Tiptap Editor mounts on <div data-tiptap-target="editor">
    ↓ (user types/formats)
editor.onUpdate → writes HTML to hidden input (real-time sync)
    ↓ (user submits form)
Turbo submits form: hidden input value = editor.getHTML()
    ↓
PostsBaseController#create: post.body = params[:post][:body]
    ↓
ActionText stores body HTML in action_text_rich_texts table
    ↓
Post show page: renders ActionText body HTML
```

### Payment Flow

```
User clicks "구매하기" on SkillPack show page
    ↓
PaymentsController#new: creates Order(status: :pending, toss_order_id: uuid)
    ↓
View: renders Toss Widget JavaScript with orderId, amount, widgetClientKey
    ↓ (client-side: Toss Widget handles payment UI)
User selects payment method, Toss processes payment
    ↓
Toss redirects to PaymentsController#success?paymentKey=X&orderId=Y&amount=Z
    ↓
PaymentService.confirm(payment_key:, order_id:, amount:)
    ↓ (HTTP POST to Toss API with secret key auth)
Toss API returns 200 with Payment object
    ↓
Order.update!(status: :paid), Payment.create!(raw_response: ...)
    ↓
Redirect to success page: show download link for SkillPack
```

### State Management

- **React component state**: Local React state within each island component. No Redux or external state store. Props from Rails are read-only; user interactions that need to persist call standard Rails Turbo form submissions.
- **Editor state**: Tiptap Editor instance held in Stimulus controller instance variable. Destroyed on controller `disconnect()` to prevent memory leaks.
- **Payment state**: Order model field `status` enum (pending/paid/failed/refunded). Single source of truth. Payment model stores raw Toss response for audit trail.

---

## Integration Points

### External Services

| Service | Integration Pattern | Auth | Notes |
|---------|---------------------|------|-------|
| Toss Payments API | Server-side HTTP POST (PaymentService) | Basic Auth (secret key base64) | SECRET_KEY in ENV only, never in client code |
| Toss Payments Widget | Client-side JS SDK embed | Widget Client Key (public, safe to expose) | Initialize in Stimulus payment_controller.js |
| Active Storage (existing) | Tiptap image upload via custom extension POSTs to Rails blob endpoint | Rails session | Requires tiptap-extension-image configured with upload callback |

### Internal Boundaries

| Boundary | Communication | Notes |
|----------|---------------|-------|
| ERB views ↔ React components | `react_component()` helper passes serialized props as JSON | Props are one-way: Rails → React. React cannot call Rails methods directly. |
| Tiptap controller ↔ ActionText | Hidden `<input>` field value | Tiptap writes HTML; ActionText reads it on POST. Compatible because ActionText body column accepts HTML. |
| PaymentsController ↔ PaymentService | Ruby method call | Controller validates params, delegates business logic to service |
| PaymentService ↔ Toss API | HTTP (net/http or faraday/httpparty) | Synchronous call in request/response cycle; add timeout handling |
| Turbo ↔ React islands | They coexist on same page; Turbo Drive navigations unmount React components | react-rails handles remounting via Turbo events; verify with `data-turbo-permanent` if needed |

---

## Scaling Considerations

| Scale | Architecture Adjustments |
|-------|--------------------------|
| 0-1k users | Current monolith is correct. React islands add no server overhead. Tiptap runs client-side. |
| 1k-10k users | Payment confirmation calls are synchronous; at high checkout volume, move PaymentService.confirm to a background job (solid_queue already configured). |
| 10k+ users | React SSR (prerender: true via react_on_rails Node SSR) for landing page if SEO/TTFB becomes a concern. Currently not needed. |

### Scaling Priorities

1. **First bottleneck:** Payment confirmation blocking request threads. Move to solid_queue background job with webhook callback from Toss to complete Order status update.
2. **Second bottleneck:** Landing page React bundle size. Use dynamic imports / code splitting if bundle grows beyond ~200KB.

---

## Anti-Patterns

### Anti-Pattern 1: Using Importmap for React/JSX

**What people do:** Try to pin React packages via `bin/importmap pin react` and write JSX inline.
**Why it's wrong:** Importmap does not transpile. JSX is not valid JavaScript. `require.context()` used by react-rails glob registration is webpack-specific and does not work with importmap or ESBuild without a plugin.
**Do this instead:** Switch to `jsbundling-rails` with ESBuild as the bundler. ESBuild natively handles JSX transpilation and is faster than Webpack.

### Anti-Pattern 2: Putting React State Inside Turbo-Driven Navigation

**What people do:** Store application state (e.g., user preferences, cart) in React component state, then navigate with Turbo Drive.
**Why it's wrong:** Turbo Drive replaces `<body>` on navigation, which unmounts React components and destroys their state. There is no persistent React tree across Turbo navigations.
**Do this instead:** Keep transient UI state (animations, hover states) in React. Keep persistent application state in Rails models / cookies / localStorage. For the landing page, this is a non-issue since it's a single-page view.

### Anti-Pattern 3: Marking Order as Paid from Client Redirect Alone

**What people do:** Trust the `?paymentKey=...&amount=...` query string from Toss redirect and immediately update Order to paid.
**Why it's wrong:** Client-side redirect parameters can be tampered with. An attacker could send any paymentKey or amount value.
**Do this instead:** Always call `PaymentService.confirm()` which makes a server-side POST to Toss API. Only update Order status after Toss returns 200.

### Anti-Pattern 4: Mixing React and Tiptap in the Same Form

**What people do:** Build the Tiptap editor as a React component, embed it via `react_component()` in the post form.
**Why it's wrong:** React-managed inputs do not participate naturally in Turbo form submissions. You need extra coordination between React state and form submit. The Stimulus controller pattern keeps the editor within the existing Turbo form submission flow without complication.
**Do this instead:** Use a Stimulus controller for Tiptap. Reserve React for components that do not need to submit data via Rails forms.

### Anti-Pattern 5: Storing Toss Secret Key in JavaScript

**What people do:** Accidentally expose the Toss secret key in JSX/JavaScript files to authenticate Toss API calls client-side.
**Why it's wrong:** Secret key gives full access to refunds, cancellations. Exposed in browser = compromised.
**Do this instead:** Secret key is used ONLY in `PaymentService` (server-side). The Widget Client Key (public) is the only Toss key that goes to JavaScript.

---

## Sources

- react-rails / react_on_rails comparison: [ShakaCode Forum](https://forum.shakacode.com/t/react-rails-vs-react-on-rails-gem/461), [Bill Harding Blog (2020)](https://bill.harding.blog/2020/11/28/rails-react-gem-options-comparison-react-rails-vs-react-on-rails-vs-webpacker-react/)
- React + Rails 8 + ESBuild guide: [RailsDrop (2025)](https://railsdrop.com/2025/07/05/guide-integrating-react-js-into-a-rails-8-application-part-2/), [RailsDrop Part 1 (2025)](https://railsdrop.com/2025/05/09/integrating-react-js-to-rails-8-application-esbuild-virtual-dom-part-1/)
- Importmap JSX limitation: [rails/importmap-rails README](https://github.com/rails/importmap-rails/blob/main/README.md), [Importmap issue thread](https://github.com/rails/rails/issues/54831)
- react_on_rails view helpers: Context7 `/shakacode/react_on_rails` — HIGH confidence
- Tiptap vanilla JS initialization: Context7 `/ueberdosis/tiptap-docs` — HIGH confidence
- Tiptap Rails + Stimulus migration: [maxencemalbois Medium](https://maxencemalbois.medium.com/migrating-from-trix-to-tiptap-in-a-rails-7-app-with-turbo-and-stimulus-js-97f253d13d0), [Good Enough blog (2025)](https://goodenough.us/blog/2025-01-16-til-tiptap-excerpt-extension-with-rails/)
- Rhino Editor (ActionText-compatible Tiptap): [GitHub KonnorRogers/rhino-editor](https://github.com/KonnorRogers/rhino-editor)
- Toss Payments widget flow: [Toss official docs](https://docs.tosspayments.com/en/integration-widget), [Toss API guide](https://docs.tosspayments.com/en/api-guide)
- toss_payments Ruby gem: [RubyGems.org v0.6.5](https://rubygems.org/gems/toss_payments/versions/0.6.5) — last released May 2023, LOW confidence for current Rails 8 compatibility; recommend direct HTTP approach
- ViewComponent + React component boundary guidance: [AHA Engineering article](https://www.aha.io/engineering/articles/rails-views-web-components-react), [Evil Martians ViewComponent guide](https://evilmartians.com/chronicles/viewcomponent-in-the-wild-building-modern-rails-frontends)
- Payment service layer patterns: [themomentum.ai Rails payment best practices](https://www.themomentum.ai/blog/best-practices-for-payment-system-in-ruby-on-rails-application)

---

*Architecture research for: TeoVibe Rails 8.1 monolith — React + Tiptap + Toss Payments enhancement milestone*
*Researched: 2026-02-22*
