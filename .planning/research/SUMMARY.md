# Project Research Summary

**Project:** TeoVibe v1.3 Admin Editor Enhancement
**Domain:** TipTap extension integration via rhino-editor 0.17.x (Rails 8 + ActionText)
**Researched:** 2026-03-14
**Confidence:** HIGH

## Executive Summary

TeoVibe v1.3 adds "Naver Blog-level" editing capability to the Admin CMS by extending the existing rhino-editor 0.17.3 component with additional TipTap extensions. The recommended approach is to subclass `TipTapEditor` as a new custom element `<admin-rhino-editor>`, adding 9 npm packages pinned to `@tiptap/core@2.27.2` and one locally-written custom FontSize extension. This isolates Admin enhancements from the public post form, preserves ActionText/ActiveStorage integration, and requires no Rails-side migrations.

The key insight from source inspection is that five of the eleven requested features (Strike, Underline, Blockquote, HorizontalRule, CodeBlock) are already registered in `RhinoStarterKit` — they only need toolbar UI work. The six genuinely new extensions (TextAlign, Color, Highlight, Table family, FontSize) require careful version pinning to `2.27.2` and a pre-implementation `config/initializers/action_text.rb` that allowlists the `style` attribute and table-related HTML tags before any colored or table content is written to the DB.

The two highest-risk areas are ActionText HTML sanitization (which silently strips `style` attributes and table tags on render, not on save — making bugs invisible in development until the post detail page is loaded) and TipTap extension version conflicts (mixing any `@tiptap/*@3.x` package with the `2.27.2` ecosystem causes silent ProseMirror schema errors). Both risks have deterministic preventions documented in PITFALLS.md and must be addressed as Day 1 setup tasks before any feature work begins.

---

## Key Findings

### Recommended Stack

rhino-editor 0.17.3 is the locked base (0.18.x removed image upload — must not upgrade). It resolves `@tiptap/core` to exactly `2.27.2`. All new extensions must pin to this version. The `@tiptap/extension-font-size` npm package does not exist in TipTap v2 and must be implemented as a 25-line custom extension using `@tiptap/extension-text-style`'s `addGlobalAttributes` pattern.

**Core technologies to install:**
- `@tiptap/extension-text-align@2.27.2` — left/center/right alignment — only official option for v2
- `@tiptap/extension-color@2.27.2` — text foreground color — requires TextStyle peer (already transitive dep)
- `@tiptap/extension-highlight@2.27.2` — background color — `multicolor: true` for palette
- `@tiptap/extension-underline@2.27.2` — not in StarterKit despite being in RhinoStarterKit
- `@tiptap/extension-table@2.27.2` + `table-row` + `table-cell` + `table-header` — all 4 required together
- `FontSize` (local, `app/frontend/extensions/font-size.js`) — no v2 npm package exists; build on TextStyle

**What NOT to install:**
- Any `@tiptap/*@^3.x` package — causes schema conflicts with the locked 2.27.2 ecosystem
- `@tiptap/extension-font-size` (npm) — does not exist in v2; installing pulls v3 packages
- `tiptap-extension-font-size` (community, unmaintained)
- rhino-editor 0.18.x (removes image upload)

### Expected Features

Source inspection of `rhino-starter-kit.d.ts` confirmed that Strike, Underline, Blockquote, HorizontalRule, and CodeBlock are all pre-registered in RhinoStarterKit. This collapses five "extension tasks" into five "toolbar button tasks" with zero package installs.

**Must have — P1 (v1.3 core):**
- Strikethrough toolbar button — 0 packages, `rhinoStrike` already registered (renders `<del>`, not `<s>`)
- Underline toolbar button — 0 packages, already registered in RhinoStarterKit
- Blockquote toolbar button — 0 packages, already registered
- Horizontal rule button — 0 packages, already registered
- Code block button — 0 packages, already registered
- Heading H1~H3 dropdown — 0 packages, configure via `starterKitOptions.heading.levels`
- Text alignment (L/C/R) — 1 package (`@tiptap/extension-text-align`)
- Table insertion + row/col operations + bubble menu — 4 packages
- Text color preset palette (12 colors) — 2 packages (`@tiptap/extension-text-style` + `@tiptap/extension-color`)
- Background highlight preset palette — 1 package (`@tiptap/extension-highlight`)
- Font size preset dropdown — custom local extension (TextStyle shared from Color)

**Should have — P2 (add if P1 ships with time remaining):**
- Block insertion floating menu (`+` button on empty lines via TipTap `FloatingMenu`)

**Defer to v1.4+:**
- Slash commands (`/`) — experimental upstream, no official npm package, high maintenance burden
- Syntax highlighting in code blocks (`@tiptap/extension-code-block-lowlight`) — bundle weight cost
- Table column resize — upstream TipTap bug #2041 (widths lost when editor not editable)
- Font family selection — brand consistency risk, low value for current content type

### Architecture Approach

The recommended architecture creates one new JS file (`app/frontend/editor/admin_rhino_editor.js`) that subclasses `TipTapEditor`, injects extensions via `editorOptions()` override, and registers as `<admin-rhino-editor>`. Three existing files require minimal modification: `application.js` (add one import), `admin/posts/_form.html.erb` (change element tag), `ai_draft_controller.js` (update one querySelector string). The public `posts/_form.html.erb` is untouched. No Rails migrations or model changes are required — all new HTML (style attributes, table tags) is stored verbatim by ActionText and requires only the sanitizer allowlist configuration.

**Major components:**
1. `AdminRhinoEditor` class (`app/frontend/editor/admin_rhino_editor.js`) — subclass with extended extensions, custom toolbar via Lit `renderToolbar()` override
2. `config/initializers/action_text.rb` — allowlist `style` attribute + all table HTML tags; must be created before any feature work begins
3. Toolbar UI (Lit html templates inline or in `admin_toolbar_helpers.js`) — heading dropdown, color swatches, alignment buttons, table bubble menu

### Critical Pitfalls

1. **ActionText strips `style` attributes on render, not on save** — Color/Highlight/TextAlign appear to work in development (editor renders them) but are silently stripped when the post detail page loads. Fix: create `config/initializers/action_text.rb` with `ActionText::ContentHelper.allowed_attributes += ["style"]` as the very first task before writing any color/alignment feature code.

2. **ActionText strips table tags on render** — `<table>`, `<tr>`, `<th>`, `<td>`, `<thead>`, `<tbody>`, `<tfoot>` are all absent from `DEFAULT_ALLOWED_TAGS`. Entire tables disappear after save. Fix: add all table tags + `colspan`/`rowspan` attributes to the same initializer, before any table feature work begins.

3. **TipTap extension duplicate registration** — Adding an extension that already exists in StarterKit (CodeBlock, Heading, Strike) causes `[tiptap warn]: Duplicate extension names found` and silent malfunction. Heading levels must be adjusted via `starterKitOptions.heading.levels`, not by adding a second Heading extension. `rhinoStrike` uses `<del>` — do NOT add the standard Strike extension alongside it.

4. **`@tiptap/extension-font-size` does not exist in v2** — Installing it pulls TipTap v3 packages, causing peer dep conflicts with `@tiptap/core@2.27.2`. Write a 25-line custom extension using `addGlobalAttributes` on TextStyle instead.

5. **Toolbar buttons missing `type="button"` submit the form** — Any `<button>` inside `<form>` without `type` defaults to `type="submit"`. Every custom toolbar button must have `type="button"` explicitly.

6. **Turbo Drive stale editor on back navigation** — Lit Web Components re-fire `connectedCallback` on Turbo cache restore, reinitializing the editor and losing content. Fix: add `<meta name="turbo-cache-control" content="no-cache">` to the Admin layout.

---

## Implications for Roadmap

Based on research, the work decomposes naturally into a setup phase followed by feature phases ordered by complexity. Simpler toolbar-only features ship first to validate the scaffold, then progressively more complex extensions are added.

### Phase 1: Foundation Setup
**Rationale:** ActionText sanitizer configuration and the AdminRhinoEditor scaffold must exist before any feature work begins. The sanitizer pitfalls (Pitfalls 2 and 3) cause silent, hard-to-debug data loss if encountered mid-feature — addressing them upfront eliminates an entire class of bugs. The `<admin-rhino-editor>` scaffold verifies that the subclass pattern and `ai_draft_controller.js` still work before any extensions are added.
**Delivers:** `config/initializers/action_text.rb` (style + table allowlists), `AdminRhinoEditor` skeleton class, `<admin-rhino-editor>` tag in admin ERB, updated querySelector in ai_draft_controller, Turbo no-cache meta tag on admin layout.
**Avoids:** Pitfalls 2, 3, 5, 7 (ActionText stripping, addExtensions timing, stale Turbo cache)

### Phase 2: Toolbar-Only Marks (Zero New Packages)
**Rationale:** Five features already have their extensions registered — only toolbar UI is needed. This phase ships visible editor improvements with zero dependency risk and validates the Lit toolbar rendering pattern before any packages are installed.
**Delivers:** Strikethrough button, Underline button, Blockquote button, Horizontal Rule button, Code Block button, Heading H1/H2/H3 dropdown.
**Uses:** `starterKitOptions.heading.levels: [1,2,3]`, existing RhinoStarterKit extensions.
**Avoids:** Pitfall 3 (do NOT add separate Strike or Heading extensions), Pitfall 6 (rhinoStrike vs Strike tag mismatch — confirm `<del>` behavior)

### Phase 3: Text Alignment
**Rationale:** Single package with straightforward integration; validates the full extension-install-configure-toolbar cycle before tackling the more complex TextStyle-dependent features.
**Delivers:** Left/center/right alignment buttons, `@tiptap/extension-text-align` installed and registered.
**Implements:** Extension injection pattern via `editorOptions()` override.
**Avoids:** Pitfall 2 (style attribute allowlisted in Phase 1, so alignment persists after save)

### Phase 4: Color and Highlight
**Rationale:** Both features share the `@tiptap/extension-text-style` peer dependency. Installing and registering them together is more efficient than two separate phases. Requires color swatch UI (12 preset colors).
**Delivers:** Text color preset palette, background highlight preset palette, `@tiptap/extension-color` + `@tiptap/extension-highlight` installed.
**Uses:** `@tiptap/extension-text-style@2.27.2` (must be registered before Color in extensions array).
**Avoids:** Pitfall 5 (TextStyle registered before Color)

### Phase 5: Table
**Rationale:** Highest complexity among P1 features — 4 packages, table bubble menu, public view CSS, ActionText tag allowlist. Isolated to its own phase to contain risk. The ActionText table tag allowlist is already done in Phase 1, so this phase focuses entirely on editor UX.
**Delivers:** Table insertion, add/remove row/column, delete table, table bubble menu with `shouldShow: isActive('table')` guard, table CSS for public post view.
**Uses:** `@tiptap/extension-table@2.27.2`, `table-row`, `table-cell`, `table-header` (all 4 required).
**Avoids:** Pitfall 3 (table tags allowlisted upfront), Pitfall 8 (no separate Heading extension added alongside Table)

### Phase 6: Font Size
**Rationale:** TextStyle is already installed by Phase 4, so this phase only requires writing the local custom extension. Low risk, validates the custom extension authoring pattern.
**Delivers:** Font size preset dropdown (12/14/16/18/20/24px), custom `FontSize` extension at `app/frontend/extensions/font-size.js`.
**Uses:** `@tiptap/extension-text-style` (already installed in Phase 4), `addGlobalAttributes` pattern.
**Avoids:** Pitfall 4 (`@tiptap/extension-font-size` npm package does not exist in v2)

### Phase 7: Block Insertion Menu (P2, conditional)
**Rationale:** Lowest priority, highest implementation complexity. Ship only if Phases 1-6 complete and discoverability of toolbar items is identified as a real usability problem. Use TipTap's built-in `FloatingMenu` extension (already bundled) before considering experimental slash commands.
**Delivers:** `+` floating button on empty lines using `FloatingMenu`.
**Avoids:** Building slash commands (experimental, no official npm package, high maintenance burden)

### Phase Ordering Rationale

- Phase 1 must precede all others — ActionText configuration is global and its absence causes data loss that is invisible until the post detail page is viewed.
- Phase 2 ships maximum user value with zero package risk, validating the scaffold and toolbar pattern before dependencies are introduced.
- Phase 3 comes before Phase 4 because it is simpler (no shared-dep coordination) and validates the extension injection path.
- Phase 4 (Color + Highlight) is grouped because they share the TextStyle peer dependency.
- Phase 5 (Table) is isolated last among P1 features because it has the most moving parts (4 packages + bubble menu + CSS).
- Phase 6 (FontSize) comes after Phase 4 because it depends on TextStyle already being registered.
- Phase 7 is gated on P1 completion and a deliberate decision to address discoverability.

### Research Flags

Phases with standard well-documented patterns (research-phase not needed):
- **Phase 1:** Rails ActionText sanitizer configuration is a common pattern with official documentation. Subclassing `TipTapEditor` is the documented extension approach per rhino-editor official docs.
- **Phase 2:** Pure toolbar UI using known Lit template patterns. Extensions already registered.
- **Phase 3:** Single official TipTap extension, official docs confirmed.
- **Phase 4:** Official TipTap extensions, peer deps confirmed. Color swatch UI is a simple HTML pattern.
- **Phase 6:** Custom extension using documented `addGlobalAttributes` API, community-verified for v2.

Phases that may benefit from additional research during planning:
- **Phase 5 (Table):** The table bubble menu (separate from the existing rhino-editor bubble menu) needs careful `shouldShow` implementation to avoid interfering with the existing text-selection bubble menu. May need to verify correct Lit template structure for mounting a second BubbleMenu component inside the subclass.
- **Phase 7 (Block menu):** If slash commands are chosen over FloatingMenu, the `@tiptap/suggestion` integration has no published package and requires copying source or using a community library — needs research at planning time.

---

## Confidence Assessment

| Area | Confidence | Notes |
|------|------------|-------|
| Stack | HIGH | Versions verified via live `npm view` commands and direct lockfile inspection. `@tiptap/extension-font-size` absence confirmed on npm. |
| Features | HIGH | `rhino-starter-kit.d.ts` directly inspected to confirm which extensions are pre-registered. Feature list matches TipTap official docs. |
| Architecture | HIGH | rhino-editor source TypeScript declarations (`tip-tap-editor-base.d.ts`, `tip-tap-editor.d.ts`) directly inspected. `editorOptions()` override confirmed as documented extension point. |
| Pitfalls | HIGH | ActionText sanitizer source (`content_helper.rb`, `rails-html-sanitizer-1.6.2`) directly inspected. DEFAULT_ALLOWED_TAGS and DEFAULT_ALLOWED_ATTRIBUTES confirmed. |

**Overall confidence:** HIGH

### Gaps to Address

- **TextStyle peer dep verification:** `@tiptap/extension-text-style` is believed to be a transitive dep (rhino-editor depends on it). Verify with `pnpm why @tiptap/extension-text-style` before Phase 4. If missing, add explicit `@tiptap/extension-text-style@2.27.2` install to Phase 4.
- **Table bubble menu Lit integration:** The exact pattern for mounting a second `BubbleMenu` component inside the `AdminRhinoEditor` subclass alongside the existing rhino-editor bubble menu has not been prototyped. Low risk (BubbleMenu is a standard TipTap extension) but worth confirming at Phase 5 start.
- **`rhinoStrike` command name:** RhinoStarterKit uses `rhinoStrike` which renders `<del>`. The toolbar toggle command may be `toggleStrike()` or a rhino-specific variant. Confirm the exact command name against the RhinoStarterKit mark definition at Phase 2 start.
- **ActionText scrubber scope:** The global `allowed_attributes += ["style"]` initializer also applies to any future member-facing rich text inputs. This is acceptable technical debt for v1.3 (Admin only), but must be refactored before a general member editor is introduced.

---

## Sources

### Primary (HIGH confidence)
- `teovibe/node_modules/rhino-editor/exports/elements/tip-tap-editor-base.d.ts` — `extensions`, `editorOptions()`, `addExtensions()` API
- `teovibe/node_modules/rhino-editor/exports/elements/tip-tap-editor.d.ts` — slot names, `renderToolbar()`
- `teovibe/node_modules/rhino-editor/exports/extensions/rhino-starter-kit.d.ts` — confirmed pre-registered extensions including Underline
- `teovibe/pnpm-lock.yaml` — confirmed all `@tiptap/*` resolve to `2.27.2`
- `~/.rbenv/versions/3.3.10/gems/actiontext-8.1.2/app/helpers/action_text/content_helper.rb` — sanitize logic
- `~/.rbenv/versions/3.3.10/gems/rails-html-sanitizer-1.6.2` — DEFAULT_ALLOWED_TAGS and DEFAULT_ALLOWED_ATTRIBUTES
- `npm view @tiptap/extension-{text-align,color,highlight,table,...} versions` (live CLI) — version availability confirmed
- `npm view @tiptap/extension-font-size versions` — confirmed no 2.x version exists
- [rhino-editor docs: Syntax Highlighting](https://rhino-editor.vercel.app/how-tos/syntax-highlighting) — `starterKitOptions.codeBlock: false` pattern
- [rhino-editor docs: Customizing the toolbar](https://rhino-editor.vercel.app/how-tos/customizing-the-toolbar/) — slot system, required button attributes
- [TipTap Table extension](https://tiptap.dev/docs/editor/extensions/nodes/table) — 4-package requirement, operations API
- [TipTap Color extension](https://tiptap.dev/docs/editor/extensions/functionality/color) — TextStyle peer requirement
- [TipTap FontSize extension](https://tiptap.dev/docs/editor/extensions/functionality/fontsize) — setFontSize/unsetFontSize API
- [ActionText Rails issue #36725](https://github.com/rails/rails/issues/36725) — style attribute stripping behavior
- [CVE-2024-53986](https://github.com/advisories/GHSA-638j-pmjw-jq48) — rails-html-sanitizer XSS: style + math tag interaction

### Secondary (MEDIUM confidence)
- GitHub gist: font-size-for-tiptap-v2 — custom FontSize via `addGlobalAttributes` pattern (community-verified for v2)
- [KonnorRogers: ActionText safe listing](https://dev.to/konnorrogers/actiontext-safe-listing-attributes-and-tags-1a4j) — allowed_tags extension pattern (written by rhino-editor author)
- [TipTap table resizable bug #2041](https://github.com/ueberdosis/tiptap/issues/2041) — column widths lost when editor not editable
- [Maquina Components: Turbo Compatibility 2026](https://maquina.app/blog/2026/02/maquina-components-0-4-0-turbo-compatibility/) — Web Component + Turbo Drive stale issue

---
*Research completed: 2026-03-14*
*Ready for roadmap: yes*
