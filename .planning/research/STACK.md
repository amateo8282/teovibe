# Stack Research

**Domain:** Rails 8.1 blog community platform enhancement (rich text, React components, payment prep, UI/UX)
**Researched:** 2026-02-22
**Confidence:** MEDIUM (core choices HIGH, version specifics MEDIUM)

---

## Context: What This Research Covers

This is a **subsequent milestone** research targeting four capability additions to an existing Rails 8.1 app using:
- Ruby 3.3.10, Rails 8.1.2, SQLite, Hotwire (Turbo + Stimulus), Tailwind CSS 4.4, Propshaft, ImportMap

The existing system is NOT re-researched. Only the four new capability areas are covered here.

---

## Area 1: Rich Text Editor Upgrade

### Recommendation: Rhino Editor (rhino-editor) v0.18.x

**Rationale:** Rhino Editor is the only option that (a) keeps ActionText compatibility, (b) is drop-in replaceable with Trix in existing ERB forms, (c) works with ImportMap (no bundler required), and (d) gives full access to TipTap/ProseMirror extension ecosystem. This project already has ActionText and Active Storage configured — Rhino Editor layers on top without schema migrations.

| Technology | Version | Purpose | Why Recommended |
|------------|---------|---------|-----------------|
| rhino-editor | ~0.18.x | TipTap-based Trix replacement, ActionText-compatible | Only Rails-native TipTap integration that preserves ActionText data model. ImportMap-compatible via CDN/vendor bundle. Maintained by the Rails community (KonnorRogers). |
| @tiptap/core | 2.x (bundled in rhino-editor) | ProseMirror editor engine | Ships inside rhino-editor bundle — no separate install needed |

### Installation (ImportMap approach — matches existing Rails setup)

```bash
# Download the CSS and JS bundle to vendor directory
curl -Lo ./app/assets/stylesheets/rhino-editor.css https://unpkg.com/rhino-editor/exports/styles/trix.css
curl -Lo ./vendor/javascript/rhino-editor.js https://unpkg.com/rhino-editor/exports/bundle/index.module.js

# Remove ActionText CSS to avoid conflicts
rm ./app/assets/stylesheets/actiontext.css
```

```ruby
# config/importmap.rb — replace Trix with Rhino Editor
# pin "trix"                                          # REMOVE
# pin "@rails/actiontext", to: "actiontext.esm.js"   # REMOVE
pin "rhino-editor", to: "rhino-editor.js"
```

```javascript
// app/javascript/application.js
// import "trix"                 // REMOVE
// import "@rails/actiontext"    // REMOVE
import "rhino-editor"
```

```erb
<%# In forms — replace trix_editor_tag with: %>
<%= form.hidden_field :body, id: form.field_id(:body),
    value: form.object.body.try(:to_trix_html) || form.object.body %>
<rhino-editor
  input="<%= form.field_id(:body) %>"
  data-blob-url-template="<%= rails_service_blob_url(":signed_id", ":filename") %>"
  data-direct-upload-url="<%= rails_direct_uploads_url %>"
></rhino-editor>
```

### Tradeoffs

| Factor | Rhino Editor | Trix (current) |
|--------|-------------|----------------|
| Bundle size | ~100kb gzipped | ~40kb gzipped |
| ActionText compat | YES (drop-in) | YES (native) |
| Extension ecosystem | Full TipTap/ProseMirror | Very limited |
| ImportMap support | YES (vendor bundle) | YES (native) |
| Styling complexity | Shadow DOM (Web Components) | Standard CSS |

### What NOT to Use

| Avoid | Why | Use Instead |
|-------|-----|-------------|
| RicherText gem (afomera/richer_text) | Separate data model, NOT backwards-compatible with ActionText. Would require data migration and model changes. | Rhino Editor |
| Raw TipTap (no Rails wrapper) | Requires custom ActionText-bridge code, Active Storage integration must be hand-built. | Rhino Editor |
| Editor.js | No ActionText compatibility at all. Output format is JSON, not HTML. Requires full data layer rewrite. | Rhino Editor |
| Trix enhancement only | Trix extension API is minimal. Significant features (tables, code blocks, advanced formatting) are impossible. | Rhino Editor |

**Confidence: MEDIUM-HIGH** — Rhino Editor v0.18.1 confirmed via official site. ImportMap installation path confirmed via official docs. ActionText compatibility confirmed via Context7 docs.

---

## Area 2: React Components Within Rails

### Recommendation: vite_ruby (vite-rails) gem + React

**Rationale:** ImportMap (current setup) explicitly cannot process JSX or TypeScript. To use React, a JavaScript bundler is required. Among the options:

- **react-rails gem**: The maintainers themselves recommend migrating away from it. Less actively developed, uses UJS (non-modern), lacks TypeScript support, no React Server Components path.
- **react_on_rails (Shakapacker)**: Requires Shakapacker (Webpack-based), heavy setup, overkill for "React landing page only" scope. SSR capability is its main differentiator — not needed here.
- **Inertia.js (inertia-rails)**: Designed for full SPA-style page routing with React. Conflicts philosophically with Hotwire/Turbo already in use. Not appropriate for "React components embedded in Rails views."
- **vite_ruby**: Replaces ImportMap with Vite as the bundler. Supports JSX, TypeScript, React Fast Refresh. Works alongside Propshaft (Propshaft handles static assets, Vite handles JavaScript). Endorsed by the Rails community as the most future-proof option. Allows mixing Stimulus controllers (Hotwire) and React components in the same app.

| Technology | Version | Purpose | Why Recommended |
|------------|---------|---------|-----------------|
| vite_ruby / vite-rails gem | ~3.x (check RubyGems) | JavaScript bundler replacing ImportMap | Only option that supports JSX+TypeScript while remaining Rails-native. Propshaft-compatible. Hot reloading in dev. |
| react | 18.x | UI library | Current stable LTS version |
| react-dom | 18.x | DOM rendering | Paired with react |
| @vitejs/plugin-react | ~4.x | Vite plugin for JSX transformation and Fast Refresh | Official Vite React plugin |

### Installation

```bash
# Gemfile
gem "vite_rails"

bundle install
bundle exec vite install
```

```bash
# package.json dependencies
npm install react react-dom @vitejs/plugin-react
```

```javascript
// vite.config.ts
import { defineConfig } from 'vite'
import RubyPlugin from 'vite-plugin-ruby'
import react from '@vitejs/plugin-react'

export default defineConfig({
  plugins: [
    RubyPlugin(),
    react(),
  ],
})
```

```erb
<%# Rails layout — replace asset helpers with Vite helpers %>
<%= vite_client_tag %>
<%= vite_javascript_tag 'application' %>
```

### Embedding React in ERB Views

```erb
<%# app/views/landing/index.html.erb %>
<div id="landing-hero" data-react-component="LandingHero"
     data-props="<%= { sections: @sections }.to_json %>">
</div>
<%= vite_javascript_tag 'entrypoints/landing' %>
```

```jsx
// app/javascript/entrypoints/landing.jsx
import React from 'react'
import { createRoot } from 'react-dom/client'
import LandingHero from '../components/LandingHero'

document.addEventListener('DOMContentLoaded', () => {
  document.querySelectorAll('[data-react-component]').forEach(el => {
    const Component = { LandingHero }[el.dataset.reactComponent]
    const props = JSON.parse(el.dataset.props || '{}')
    createRoot(el).render(<Component {...props} />)
  })
})
```

### Coexistence with Hotwire/Turbo

Vite replaces ImportMap but Stimulus and Turbo can continue working. React components mount via `DOMContentLoaded` or Turbo's `turbo:load` event. Keep Hotwire for server-driven pages, use React only for the landing page and highly interactive islands.

### What NOT to Use

| Avoid | Why | Use Instead |
|-------|-----|-------------|
| react-rails gem | Maintainers recommend migrating away. UJS-based (not modern ES modules). Poor TypeScript support. | vite_ruby + React |
| react_on_rails (Shakapacker) | Webpack/Shakapacker is heavy. Designed for full SSR React apps, not partial React islands. High maintenance cost for 1-person team. | vite_ruby + React |
| Inertia.js | Designed for SPA-style routing, conflicts with Turbo's page navigation model. Forces all pages into React paradigm. | vite_ruby + React (islands) |
| ImportMap + CDN React | No JSX compilation, no bundling, poor DX, no TypeScript. Not viable for real React development. | vite_ruby + React |

**Confidence: MEDIUM** — vite_ruby with Rails 8 confirmed via community articles (Medium, raelcunha.com, 2024-2025). Propshaft compatibility confirmed via Rails community discussions. Exact gem version not pinned (check RubyGems at install time). react-rails deprecation direction confirmed via GitHub README.

---

## Area 3: Payment Infrastructure — Toss Payments

### Recommendation: Toss Payments SDK v2 (JavaScript) + custom Rails controller (no gem)

**Rationale:** There is no official Toss Payments Ruby gem. The Laravel package (getsolaris/laravel-tosspayments) confirms the pattern: third-party language wrappers exist but are unofficial. For Rails, the correct approach is:
1. Use the official `@tosspayments/tosspayments-sdk` JavaScript package for the frontend widget
2. Build a thin Rails controller that calls the Toss Payments Confirm API (REST) using Net::HTTP or Faraday (already in Gemfile)

This is a **foundation-only** task per the milestone scope — actual payment processing is deferred.

| Technology | Version | Purpose | When to Use |
|------------|---------|---------|-------------|
| @tosspayments/tosspayments-sdk | latest v2.x | Frontend payment widget rendering | On checkout page — renders payment method selector, handles authentication redirect |
| Faraday (already in Gemfile) | 2.14.1 | Backend HTTP client for Toss confirm API call | Payment confirmation after redirect — POST to `https://api.tosspayments.com/v1/payments/confirm` |

### Payment Flow (v2 SDK)

```
1. Frontend: Initialize widget with clientKey
   tossPayments(clientKey).widgets({ customerKey })

2. Frontend: Render payment UI
   widget.renderPaymentMethods('#payment-methods-widget', { value: amount })
   widget.renderAgreement('#agreement-widget')

3. Frontend: Request payment (redirects to successUrl)
   widget.requestPayment({ orderId, orderName, successUrl, failUrl })

4. Backend (successUrl handler): Confirm payment
   POST https://api.tosspayments.com/v1/payments/confirm
   Authorization: Basic base64(secretKey + ":")
   Body: { paymentKey, orderId, amount }

5. Backend: Update Order/Payment record, redirect user
```

### Foundation Structure for Rails

```ruby
# Gemfile — no new gems needed (Faraday already present)

# app/models/order.rb
class Order < ApplicationRecord
  belongs_to :user
  belongs_to :skill_pack
  enum :status, { pending: 0, paid: 1, failed: 2, refunded: 3 }
  validates :amount, numericality: { greater_than: 0 }
  validates :toss_order_id, presence: true, uniqueness: true
end

# app/controllers/payments_controller.rb
class PaymentsController < ApplicationController
  def success
    # Confirm payment with Toss API
    response = TossPaymentsService.confirm(
      payment_key: params[:paymentKey],
      order_id: params[:orderId],
      amount: params[:amount]
    )
    # Update order status, grant download access
  end
end

# app/services/toss_payments_service.rb
class TossPaymentsService
  BASE_URL = "https://api.tosspayments.com/v1"

  def self.confirm(payment_key:, order_id:, amount:)
    conn = Faraday.new(url: BASE_URL) do |f|
      f.request :json
      f.response :json
      f.adapter Faraday.default_adapter
    end
    conn.post("/payments/confirm") do |req|
      req.headers["Authorization"] = "Basic #{Base64.strict_encode64("#{secret_key}:")}"
      req.body = { paymentKey: payment_key, orderId: order_id, amount: amount.to_i }
    end
  end

  def self.secret_key
    Rails.application.credentials.toss_payments[:secret_key]
  end
end
```

### Credentials Setup

```bash
# config/credentials.yml.enc (via rails credentials:edit)
toss_payments:
  client_key: "test_ck_..."   # or live_ck_... for production
  secret_key: "test_sk_..."   # or live_sk_... for production
```

### Frontend Widget (ERB + Vite)

```erb
<%# app/views/orders/checkout.html.erb %>
<div id="payment-widget"></div>
<div id="agreement-widget"></div>
<button id="pay-button">결제하기</button>
```

```javascript
// app/javascript/entrypoints/checkout.js
import { loadTossPayments } from '@tosspayments/tosspayments-sdk'

const clientKey = document.querySelector('[data-client-key]').dataset.clientKey
const tossPayments = await loadTossPayments(clientKey)
const widgets = tossPayments.widgets({ customerKey: guestId })

await widgets.setAmount({ currency: 'KRW', value: orderAmount })
await widgets.renderPaymentMethods('#payment-widget', { variantKey: 'DEFAULT' })
await widgets.renderAgreement('#agreement-widget', { variantKey: 'AGREEMENT' })

document.getElementById('pay-button').addEventListener('click', () => {
  widgets.requestPayment({
    orderId: orderId,
    orderName: skillPackName,
    successUrl: `${window.location.origin}/payments/success`,
    failUrl: `${window.location.origin}/payments/fail`,
  })
})
```

### What NOT to Use

| Avoid | Why | Use Instead |
|-------|-----|-------------|
| Toss Payments SDK v1 | Deprecated multiple payment SDKs consolidated in v2. v2 is the current recommended version. | SDK v2 (@tosspayments/tosspayments-sdk) |
| Third-party Ruby gem wrappers | No official Rails gem exists. Community wrappers are unmaintained. | Direct Faraday HTTP calls to Toss API |
| iamport or other PG | Project explicitly targets Toss Payments as the payment gateway. | Toss Payments |

**Confidence: MEDIUM** — Toss Payments v2 SDK and payment flow confirmed via official docs (docs.tosspayments.com). No Rails gem confirmed via search (only Laravel wrapper found). Faraday usage for backend confirmation is standard REST pattern confirmed by Toss API documentation.

---

## Area 4: UI/UX Enhancement Tools

### Recommendation: ViewComponent 4.x + Flowbite (CDN) + Hotwire CSS Transitions

**Rationale:** The existing stack (Tailwind CSS 4.4 + Hotwire + Propshaft) is the right foundation. The gaps are (a) reusable component structure, (b) pre-built interactive UI patterns, and (c) loading state handling. ViewComponent solves (a), Flowbite solves (b), and Turbo's built-in features solve (c).

| Technology | Version | Purpose | When to Use |
|------------|---------|---------|-------------|
| view_component gem | 4.4.0 | Encapsulated, testable Rails view components | All new UI elements: cards, buttons, modals, nav items. Replaces duplicated ERB partials. |
| Flowbite | 3.x (CDN or npm via Vite) | Pre-built Tailwind CSS 4 component patterns | Dropdowns, modals, tabs, tooltips — interactive components with minimal JS |
| Turbo progress bar + frames | (built into Turbo Rails 2.0.23) | Loading state indication | Already available — needs configuration via CSS |
| css-bundling / Vite | (via vite_ruby if added for React) | PostCSS processing for animations | Transition/animation utilities |

### ViewComponent Installation

```ruby
# Gemfile
gem "view_component", "~> 4.4"
```

```bash
bundle install

# Generate components
bin/rails generate component Card title body:text
bin/rails generate component Button label variant
bin/rails generate component Alert message type
```

```ruby
# app/components/card_component.rb
class CardComponent < ViewComponent::Base
  def initialize(title:, body: nil, classes: "")
    @title = title
    @body = body
    @classes = classes
  end
end
```

```erb
<%# app/components/card_component.html.erb %>
<div class="bg-white rounded-lg shadow-md p-6 <%= @classes %>">
  <h3 class="text-lg font-semibold text-gray-900"><%= @title %></h3>
  <% if @body %>
    <p class="mt-2 text-gray-600"><%= @body %></p>
  <% end %>
  <%= content %>
</div>
```

### Flowbite Integration (CDN — no build step required)

```erb
<%# app/views/layouts/application.html.erb %>
<%# Add before closing </body> tag %>
<script src="https://cdn.jsdelivr.net/npm/flowbite@3.0.1/dist/flowbite.min.js"></script>
```

If vite_ruby is added for React (Area 2), install via npm instead:
```bash
npm install flowbite
```

### Turbo Loading State (already available)

```css
/* app/assets/stylesheets/application.css */
/* Turbo progress bar customization */
.turbo-progress-bar {
  height: 3px;
  background: linear-gradient(to right, #6366f1, #8b5cf6);
}
```

```erb
<%# Enable Turbo frame loading indicators %>
<turbo-frame id="content" loading="lazy">
  <%# content %>
</turbo-frame>
```

### What NOT to Use

| Avoid | Why | Use Instead |
|-------|-----|-------------|
| Phlex (as replacement for ViewComponent) | Steeper learning curve for 1-person team. ViewComponent 4.x has direct Rails 8.1 support confirmed. | ViewComponent 4.x |
| Bootstrap | Already using Tailwind CSS 4.4. Adding Bootstrap creates CSS conflicts and doubles stylesheet payload. | Flowbite (Tailwind-native) |
| StimulusReflex or CableReady | Adds WebSocket complexity beyond what the current Solid Cable setup is configured for. Overkill for loading states. | Turbo Frames + native CSS transitions |
| Alpine.js | Creates third JavaScript paradigm (Stimulus + React + Alpine). Stimulus already handles the interactive micro-behavior use cases. | Stimulus (already installed) |

**Confidence: HIGH** — ViewComponent 4.4.0 released February 13, 2026, confirmed via GitHub. Rails 8.1 support confirmed in changelog. Flowbite Tailwind CSS 4 compatibility confirmed via official docs. Turbo progress bar is built-in.

---

## Full Dependency Map

```
New additions required:

Gemfile:
  gem "vite_rails"           # Replaces ImportMap for JSX bundling
  gem "view_component", "~> 4.4"

package.json:
  react ^18.x
  react-dom ^18.x
  @vitejs/plugin-react ^4.x
  @tosspayments/tosspayments-sdk  # latest v2
  flowbite ^3.x                   # if via npm (optional, CDN also works)

vendor/javascript:
  rhino-editor.js            # downloaded via curl from unpkg

app/assets/stylesheets:
  rhino-editor.css           # downloaded via curl from unpkg
```

---

## Version Compatibility Matrix

| Package | Version | Compatible With | Notes |
|---------|---------|-----------------|-------|
| vite_ruby gem | ~3.x | Rails 8.1.2, Propshaft 1.3.1 | Propshaft handles static assets; Vite handles JS. Compatible — verified via community articles. |
| view_component | 4.4.0 | Rails >= 7.1, Ruby >= 3.2.0 | Rails 8.1 support confirmed in changelog (Feb 2026). |
| rhino-editor | 0.18.x | Rails ActionText, ImportMap | Drop-in for Trix. ImportMap-compatible via vendor bundle. |
| react | 18.x | Vite 5.x + @vitejs/plugin-react 4.x | Standard pairing |
| @tosspayments/tosspayments-sdk | v2 latest | Any modern JS environment | Frontend-only. Backend calls Toss REST API via Faraday. |
| flowbite | 3.x | Tailwind CSS 4.x | Confirmed Tailwind v4 compatibility per official docs. |

---

## Installation Sequence

Follow this order to avoid conflicts:

```
1. rhino-editor (no bundler change — vendor file approach)
   → curl download, importmap.rb update, application.js update
   → Test: existing posts still render, editor loads in forms

2. vite_ruby + React (bundler change — high impact)
   → bundle add vite_rails, bundle exec vite install
   → npm install react react-dom @vitejs/plugin-react
   → Migrate application.js imports to Vite entrypoints
   → Test: existing JS (Stimulus, Turbo) still works

3. view_component
   → bundle add view_component
   → Refactor first 2-3 partials into components
   → Test: pages render correctly

4. Toss Payments foundation
   → Add Order model, PaymentsController skeleton
   → Add Toss credentials (test keys)
   → npm install @tosspayments/tosspayments-sdk
   → Build checkout page (non-functional, UI only)
   → Test: widget renders in sandbox mode
```

**CRITICAL**: Step 2 (vite_ruby) replaces ImportMap. This is a breaking change to the JavaScript loading pipeline. All existing `pin` entries in `config/importmap.rb` must be migrated to Vite entrypoints. Test Stimulus controllers and Turbo carefully after migration.

---

## Alternatives Considered

| Category | Recommended | Alternative | Why Not |
|----------|-------------|-------------|---------|
| Rich text editor | rhino-editor | RicherText gem | Not ActionText-compatible. Requires data migration. |
| Rich text editor | rhino-editor | Raw TipTap | No Rails/ActionText integration. Must build bridge manually. |
| React integration | vite_ruby + React | react_on_rails + Shakapacker | Webpack-based. Heavy setup. SSR overkill for landing page only. |
| React integration | vite_ruby + React | react-rails gem | Maintainers recommend moving away. UJS-based, not modern. |
| React integration | vite_ruby + React | Inertia.js | SPA-style routing conflicts with Turbo. Wrong mental model. |
| Component system | ViewComponent 4.x | Phlex | Higher learning curve. Smaller ecosystem for 1-person team. |
| UI components | Flowbite | DaisyUI | DaisyUI v5 requires Tailwind v4 setup changes. Flowbite confirms v4 support. |
| Payment | Toss v2 + Faraday | Third-party Ruby gem | No maintained official Rails gem exists. |

---

## Sources

- rhino-editor official site (rhino-editor.vercel.app) — v0.18.1 version, Shadow DOM architecture, ActionText compatibility [MEDIUM confidence]
- Context7 /konnorrogers/rhino-editor — ImportMap installation steps, ERB form integration pattern [HIGH confidence]
- Context7 /ueberdosis/tiptap-docs — TipTap vanilla JS integration, CDN usage [HIGH confidence]
- Context7 /shakacode/react_on_rails — react_on_rails installation, Shakapacker requirement [HIGH confidence]
- Context7 /inertiajs/inertia-rails — Inertia Rails setup, Vite + React integration [HIGH confidence]
- GitHub reactjs/react-rails — Maintainers recommend alternatives; less active development [MEDIUM confidence]
- docs.tosspayments.com/en/overview — Payment flow stages, Korean two-track payment model [MEDIUM confidence]
- docs.tosspayments.com/sdk/v2/js — JS SDK v2 methods: setAmount, renderPaymentMethods, requestPayment [MEDIUM confidence]
- npmjs.com @tosspayments/tosspayments-sdk — SDK v2 package name confirmed [MEDIUM confidence]
- viewcomponent.org — v4.4.0 released 2026-02-13, Rails 8.1 support confirmed [HIGH confidence]
- flowbite.com/docs/getting-started/rails/ — Tailwind v4 compatibility, Rails integration guide [HIGH confidence]
- vite-ruby.netlify.app — Rails integration guide, Propshaft compatibility pattern [MEDIUM confidence]
- WebSearch: "react-rails gem 2025 Rails 8" — Confirmed multiple integration approaches, ESBuild/Vite as modern standard [LOW-MEDIUM confidence]
- WebSearch: "vite_ruby Rails 8 Propshaft 2025" — Community confirmation of compatibility [MEDIUM confidence]

---

*Stack research for: TeoVibe Rails 8.1 enhancement (rich text, React, payments, UI/UX)*
*Researched: 2026-02-22*
