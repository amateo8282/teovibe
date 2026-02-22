# Pitfalls Research

**Domain:** Rails 8.1 monolith enhancement — React islands, rich text editor upgrade, payment infrastructure
**Researched:** 2026-02-22
**Confidence:** MEDIUM (WebSearch verified against official sources and GitHub issues)

---

## Critical Pitfalls

### Pitfall 1: react-rails gem + Turbo Drive = Silent Component Memory Leaks

**What goes wrong:**
When users navigate between pages via Turbo Drive, React components are not properly unmounted. Each page visit stacks new component instances on top of old ones. Event listeners registered in `useEffect` accumulate. With React 18, the mismatch between `ReactDOM.unmountComponentAtNode()` (old API) and `createRoot` (new API) produces console warnings and can lead to state inconsistencies or double-renders.

**Why it happens:**
react-rails registers components using `ReactRailsUJS`, which mounts on `turbo:load` events. However, Turbo Drive replaces DOM nodes but the cleanup lifecycle (`turbolinks:before-render` → unmount) is unreliable in the react-rails gem's current implementation. A PR (#1135) removed component cleanup in favor of scroll-position restoration, breaking the lifecycle.

**How to avoid:**
- Add explicit cleanup in the Rails layout:
  ```javascript
  document.addEventListener('turbo:before-render', () => {
    ReactRailsUJS.handleUnmount()
  })
  ```
- Alternatively, mark React component containers with `data-turbo-permanent` to exempt them from Turbo Drive replacement (use sparingly — only for persistent components like nav widgets).
- React components should be scoped to routes where Turbo Drive is either disabled (`data-turbo="false"`) or where the component container persists across navigations.
- Consider using react_on_rails gem instead if SSR or more robust lifecycle management is needed.

**Warning signs:**
- Browser DevTools shows React component count growing per navigation
- `useEffect` cleanup callbacks are not firing (add console.log in cleanup to verify)
- Console warning: "You are calling ReactDOM.unmountComponentAtNode() on a container that was previously passed to ReactDOMClient.createRoot()"
- Memory usage climbs monotonically during session

**Phase to address:**
React integration phase — before any React components ship to production. Verify cleanup behavior on every page that uses React components.

---

### Pitfall 2: react-rails + importmap Cannot Compile JSX

**What goes wrong:**
Rails 8.1 uses importmap-rails by default. Importmap serves raw ES modules without transformation. JSX is not valid JavaScript and cannot be served via importmap without a build step. Attempting to use react-rails with importmap results in syntax errors in production unless JSX is pre-compiled.

**Why it happens:**
Importmap assumes browser-native ESM — no transpilation. React's `.jsx` files require Babel or esbuild transformation before the browser can parse them. The react-rails gem documentation covers both Webpacker (deprecated) and asset pipeline, but the Rails 8 importmap path requires explicit configuration that is easy to omit.

**How to avoid:**
- Add `jsbundling-rails` with esbuild as the bundler alongside react-rails:
  ```bash
  bundle add jsbundling-rails
  rails javascript:install:esbuild
  ```
- Configure `package.json` build script to output to `app/assets/builds/`:
  ```json
  "build": "esbuild app/javascript/*.* --bundle --sourcemap --outdir=app/assets/builds --loader:.jsx=jsx"
  ```
- Do NOT attempt importmap-only React integration — it cannot handle JSX in the browser.
- Verify `application.js` does not double-include React via both importmap pins and esbuild output.

**Warning signs:**
- "Unexpected token '<'" error in browser console on first React component load
- React component renders as empty `<div>` with no error (silent failure from asset pipeline misconfiguration)
- `react_component` view helper renders the wrapper div but no component

**Phase to address:**
Very first step of React integration — asset pipeline configuration must be verified before writing any component code.

---

### Pitfall 3: Rich Text Editor Replacement Breaking ActionText Data

**What goes wrong:**
Replacing Trix with a TipTap-based editor (RicherText, rhino-editor) without understanding the ActionText data format can corrupt existing post content. Trix stores content as HTML in `action_text_rich_texts.body`. A new editor that writes a different HTML structure or uses different attachment sgid formats will make existing posts render incorrectly or fail to display embedded images.

**Why it happens:**
RicherText explicitly states it is "not backwards compatible" with ActionText. TipTap uses its own JSON or HTML schema. If you install RicherText and point it at the existing ActionText column, it will read Trix-generated HTML but write TipTap-formatted HTML — creating mixed-format records that render incorrectly depending on which editor version was used.

**How to avoid:**
- Choose rhino-editor (not RicherText) if you want to keep ActionText — rhino-editor is designed as a drop-in Trix replacement that maintains ActionText's storage format.
- If you want RicherText's feature set, plan a one-time data migration: write a Rake task that reads each `action_text_rich_texts` record, parses Trix HTML, and converts to the new format before deploying the editor change.
- Never deploy a new editor before verifying 5+ existing posts render correctly with the new editor's reader.
- Take a database backup immediately before any editor migration.

**Warning signs:**
- Existing posts render raw HTML tags as visible text after switching editors
- Active Storage embedded images (sgid attachment blobs) stop displaying in existing posts
- New posts display correctly but posts older than the migration date break

**Phase to address:**
Rich text editor upgrade phase — migration script must be written and tested on a staging copy of production data before any code ships.

---

### Pitfall 4: Payment Infrastructure Without Idempotency = Double Charges

**What goes wrong:**
TossPayments (and payment gateways generally) deliver webhooks on an at-least-once guarantee. If the Rails webhook handler processes the same payment confirmation event twice, orders are fulfilled twice: the user receives the skill pack twice, point awards double, download records duplicate, and refund logic becomes unreliable.

**Why it happens:**
Network failures, provider retries, and deployment restarts all cause webhook replay. A naive Rails controller that processes the webhook payload and immediately creates an Order record has no guard against this. The problem is invisible in development (no replay) and surfaces only in production under load or after a server restart.

**How to avoid:**
- Store the payment gateway's event ID in an `idempotency_key` column on the Order or PaymentEvent model with a unique index:
  ```ruby
  add_column :orders, :payment_event_id, :string
  add_index :orders, :payment_event_id, unique: true
  ```
- In the webhook controller, check before processing:
  ```ruby
  return head :ok if Order.exists?(payment_event_id: params[:orderId])
  ```
- Process webhooks asynchronously: ACK the HTTP request immediately (return 200), enqueue a background job, and do all business logic in the job. This prevents timeouts causing the provider to retry.
- Verify webhook signatures using the provider's secret key before processing any payload.

**Warning signs:**
- `Order.where(payment_event_id: nil).count > 0` — orders without event IDs cannot be deduplicated
- No `PaymentEvent` or `WebhookLog` model exists in the schema
- Webhook controller calls `Order.create!` directly without a uniqueness check

**Phase to address:**
Payment infrastructure design phase — Order model schema must include `payment_event_id` before TossPayments integration begins. Retroactively adding idempotency to an active payment flow is high-risk.

---

### Pitfall 5: SQLite Write Lock Under Solid Queue + Web Requests

**What goes wrong:**
When Solid Queue workers and Puma web processes both write to the same SQLite database simultaneously, write transactions queue behind a single write lock. Under moderate load (sending notifications, awarding points, recording downloads simultaneously with page saves), users see `SQLite3::BusyException: database is locked` errors.

**Why it happens:**
SQLite allows unlimited concurrent readers but only one writer at a time, even in WAL mode. Rails 8's Solid Queue uses `FOR UPDATE SKIP LOCKED` to poll jobs — but SQLite does not support this clause, making job polling sequential. When notification jobs, point award jobs, and web request writes all contend on the same lock, the busy timeout is exhausted and exceptions surface.

**How to avoid:**
- Configure separate SQLite databases for each Rails 8 solid component (already supported):
  ```yaml
  # config/database.yml
  queue:
    adapter: sqlite3
    database: db/queue.sqlite3
  cache:
    adapter: sqlite3
    database: db/cache.sqlite3
  cable:
    adapter: sqlite3
    database: db/cable.sqlite3
  ```
- Enable WAL mode and set busy_timeout in `config/initializers/sqlite.rb`:
  ```ruby
  ActiveRecord::Base.connection.execute("PRAGMA journal_mode=WAL")
  ActiveRecord::Base.connection.execute("PRAGMA busy_timeout=5000")
  ```
- Keep write-heavy background jobs (notification dispatch, point calculations) minimal per request — batch rather than per-record.
- Monitor for `SQLite3::BusyException` in production logs as the primary early warning signal.

**Warning signs:**
- `SQLite3::BusyException` in production logs
- Solid Queue jobs stuck in `claimed` state that never complete
- Point awards or notifications arriving minutes late or not at all
- Admin dashboard shows inconsistent counts on rapid refresh

**Phase to address:**
Before deploying payment webhooks (which add background job volume). Database configuration should be hardened before any background-job-heavy features ship.

---

## Technical Debt Patterns

| Shortcut | Immediate Benefit | Long-term Cost | When Acceptable |
|----------|-------------------|----------------|-----------------|
| Use RicherText (not ActionText-compatible) without migration script | Faster feature richness | Existing posts render broken HTML | Never — always plan migration |
| Skip idempotency key on payment webhooks | Simpler Order model | Double fulfillment, double charges in production | Never |
| Mount React via importmap without esbuild | No build step needed | JSX fails silently in production | Never — use esbuild |
| Single SQLite DB for web + Solid Queue | Simpler config | Lock contention under moderate background load | Only acceptable in zero-background-job apps |
| Store TossPayments webhook payload without signature verification | Faster implementation | Any HTTP client can fake a successful payment | Never |

---

## Integration Gotchas

| Integration | Common Mistake | Correct Approach |
|-------------|----------------|------------------|
| react-rails + Turbo Drive | Not handling component unmount on navigation | Add `turbo:before-render` listener calling `ReactRailsUJS.handleUnmount()` |
| react-rails + esbuild | Using importmap for JSX files | Configure jsbundling-rails with esbuild, output to `app/assets/builds/` |
| rhino-editor + ActionText | Installing without verifying existing Trix HTML renders | Audit 10+ existing posts in staging; compare render output before and after |
| TossPayments webhook | Processing payload synchronously in controller | ACK immediately, enqueue `ProcessPaymentJob`, do work in job |
| Active Storage + production image URLs | Using `disk` service in production | Configure `s3` or equivalent; disk service generates localhost URLs |
| ActionText + FTS5 index | FTS5 indexed on `posts.body`, content is in `action_text_rich_texts.body` | Fix FTS trigger to join ActionText table (existing CONCERNS.md issue) |

---

## Performance Traps

| Trap | Symptoms | Prevention | When It Breaks |
|------|----------|------------|----------------|
| React component re-renders on every Turbo navigation | Growing memory, slow navigations | Scope React to isolated routes; use `data-turbo-permanent` | From first navigation in session |
| FTS5 always falls back to LIKE | Slow search on 1k+ posts | Fix FTS index to sync with ActionText body (existing debt) | ~500+ posts |
| SQLite write lock under concurrent background jobs | `BusyException`, stale job queue | Separate SQLite DBs per Solid component; WAL mode + busy timeout | ~50 concurrent users |
| N+1 on post index with user avatars | Slow board pages after adding user profile improvements | Verify `.includes(:user)` + select fields before shipping profile enhancements | Any traffic above 20 RPS |
| TipTap bundle size (rhino-editor) | Slow initial page load on landing page | Lazy-load rich editor JS — only load on edit/new routes, not on show/landing | Landing page load time > 3s on mobile |

---

## Security Mistakes

| Mistake | Risk | Prevention |
|---------|------|------------|
| Accepting TossPayments webhook without signature verification | Fraudulent "payment completed" events — skill packs delivered without payment | Implement HMAC-SHA256 signature check using TossPayments secret key before any processing |
| Storing payment event payloads without encryption | PII in payment records exposed in DB breach | Encrypt sensitive fields; store only order ID and status, not full payload |
| Serving Active Storage disk URLs in production | Files accessible via guessable localhost URLs; signed URLs expire or break after secret_key_base rotation | Use S3/object storage with signed URLs; document `secret_key_base` change impact on existing attachments |
| React component receiving Rails CSRF token via prop | Token logged in browser DevTools or JS error reporting | Use `meta[name="csrf-token"]` read in JS; do not pass as React prop through ERB |
| No rate limiting on payment initiation endpoint | Attacker initiates thousands of partial payment sessions consuming TossPayments API quota | Add Rack::Attack rule: max 10 payment initiations per user per hour |

---

## UX Pitfalls

| Pitfall | User Impact | Better Approach |
|---------|-------------|-----------------|
| Rich text editor loads on every page (not lazy-loaded) | Landing page TTI degrades; editor JS (~500KB) loads even on read-only views | Load editor only on new/edit routes; use dynamic import |
| React landing page component has no loading state | Blank flash before React hydration completes | Render skeleton HTML in ERB that matches React component structure; replace on hydration |
| Payment flow with no order status page | User pays, gets redirected, unclear if payment succeeded | Build `/orders/:id` status page before integrating payment — even with mock data |
| Notifications sent without user preference check | Users get notification spam after profile/follow improvements | Add NotificationPreference model before shipping any new notification triggers |
| Editor upgrade loses user's draft content | User loses in-progress post if new editor fails | Add localStorage draft autosave before deploying editor change |

---

## "Looks Done But Isn't" Checklist

- [ ] **React integration:** Component unmount on Turbo navigation is verified — open DevTools, navigate away and back, confirm no component count growth and no console warnings
- [ ] **Rich text editor upgrade:** 20 existing posts across all categories render correctly in staging with new editor — check embedded images, code blocks, lists
- [ ] **Payment infrastructure:** Order model has `payment_event_id` unique index; webhook handler returns 200 before processing; background job handles actual fulfillment
- [ ] **Active Storage production:** `config/storage.yml` uses S3 (not disk) for production; CORS configured on bucket; test upload and retrieve cycle end-to-end in staging
- [ ] **SQLite multi-DB:** Separate `queue.sqlite3`, `cache.sqlite3`, `cable.sqlite3` files configured in `database.yml`; WAL mode enabled; busy_timeout set
- [ ] **FTS5 index sync:** Search returns results for posts created after ActionText migration — verify by creating a test post and immediately searching for a unique word in its body

---

## Recovery Strategies

| Pitfall | Recovery Cost | Recovery Steps |
|---------|---------------|----------------|
| React memory leak in production | LOW | Deploy `turbo:before-render` unmount handler; no data loss |
| JSX importmap failure | LOW | Add jsbundling-rails + esbuild; rebuild assets; deploy |
| Rich text data corruption from wrong editor | HIGH | Restore from backup; run conversion script; re-deploy; verify all posts |
| Double charge from webhook replay | HIGH | Manual refund via TossPayments dashboard; audit all orders with duplicate event IDs; add idempotency key retroactively |
| SQLite BusyException in production | MEDIUM | Enable WAL mode + busy_timeout; separate Solid component DBs; restart Solid Queue workers |
| FTS5 index stale (search not finding new posts) | LOW | Drop and recreate FTS index with corrected ActionText join; no data loss |

---

## Pitfall-to-Phase Mapping

| Pitfall | Prevention Phase | Verification |
|---------|------------------|--------------|
| React + Turbo unmount lifecycle | React integration (first) | Navigate 10+ pages in browser, check DevTools memory, zero console warnings |
| JSX + importmap incompatibility | React integration (first task) | `rails assets:precompile` succeeds; React component renders in production build |
| Rich text editor data corruption | Editor upgrade phase (migration script first) | Run `Post.all.each { \|p\| puts p.body.to_s }` in staging — no HTML tags visible as text |
| Payment idempotency missing | Payment schema design phase | `Order.column_names.include?("payment_event_id")` and unique index exists |
| SQLite write lock under Solid Queue | Infrastructure hardening (before background-job-heavy features) | `PRAGMA journal_mode` returns `wal`; run concurrent load test with 20 simultaneous writes |
| FTS5 not synced with ActionText | Search fix phase (existing tech debt) | Create post, search for word in body, verify it appears in results |

---

## Sources

- [react-rails GitHub Issues: Components not cleaned up with turbo links navigation (#1028, #1184)](https://github.com/reactjs/react-rails/issues/1028)
- [react-rails GitHub Issues: React 18 unmountComponentAtNode warning (#884)](https://github.com/reactjs/react-rails/issues/884)
- [React components on Rails and Hotwire Turbo Streams — Mocra](https://www.mocra.com/react-components-on-rails-and-hotwire-turbo-streams/)
- [rhino-editor: Why Rhino Editor? (ActionText compatibility rationale)](https://rhino-editor.vercel.app/references/why-rhino-editor/)
- [RicherText GitHub: not backwards compatible with ActionText](https://github.com/afomera/richer_text)
- [Rails: ActionText Trix decoupled into action_text-trix gem (Sept 2025)](https://blog.saeloun.com/2025/09/12/rails-action-text-trix-gem/)
- [TipTap migration from Trix in Rails 7 — Medium](https://maxencemalbois.medium.com/migrating-from-trix-to-tiptap-in-a-rails-7-app-with-turbo-and-stimulus-js-97f253d13d0)
- [Handling Payment Webhooks Reliably — Medium](https://medium.com/@sohail_saifii/handling-payment-webhooks-reliably-idempotency-retries-validation-69b762720bf5)
- [SQLite database is locked in Rails 8 — a1w.ca](https://a1w.ca/p/2024-10-29-sqlite-database-is-locked-rails-8/)
- [SQLite on Rails: Improving concurrency — fractaledmind.com](https://fractaledmind.com/2023/12/11/sqlite-on-rails-improving-concurrency/)
- [SQLite on Rails: exciting new ways to cause outages (2025)](https://andre.arko.net/2025/09/11/rails-on-sqlite-exciting-new-ways-to-cause-outages/)
- [Solid Queue GitHub: SQLite FOR UPDATE SKIP LOCKED issue (#378)](https://github.com/rails/solid_queue/issues/378)
- [Guide: Integrating React.js into Rails 8 with ESBuild (2025)](https://railsdrop.com/2025/05/09/integrating-react-js-to-rails-8-application/)
- [Active Storage S3 expired images (Feb 2025)](https://discuss.rubyonrails.org/t/active-storage-s3-expied-images/88632)
- [Idempotency in Payment APIs — Medium (Aug 2025)](https://medium.com/@ashishgupta_34644/idempotency-in-payment-apis-ensuring-safe-retries-without-double-charges-b5a2baa5ed0b)
- Project codebase analysis: `/Users/jaehohan/Desktop/keep-going/teo-vibe/.planning/codebase/CONCERNS.md`

---
*Pitfalls research for: Rails 8.1 monolith — React, rich text editor upgrade, payment infrastructure*
*Researched: 2026-02-22*
