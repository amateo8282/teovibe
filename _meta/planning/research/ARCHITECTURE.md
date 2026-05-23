# Architecture Research

**Domain:** TipTap extension integration with rhino-editor (Admin CMS editor enhancement)
**Researched:** 2026-03-14
**Confidence:** HIGH — based on direct source inspection of rhino-editor 0.17.3 and existing codebase

## Standard Architecture

### System Overview

```
┌─────────────────────────────────────────────────────────────────────┐
│                    Admin Layout (admin.html.erb)                      │
│                    vite_javascript_tag 'application'                  │
├─────────────────────────────────────────────────────────────────────┤
│                 Admin Post Form (_form.html.erb)                       │
│  ┌──────────────────────────────────┐  ┌──────────────────────────┐  │
│  │       Left: Editor Column        │  │  Right: Meta Panel       │  │
│  │  ┌────────────────────────────┐  │  │  (sticky, 320px)         │  │
│  │  │   AI Draft Panel           │  │  │  - 제목, 카테고리, 상태   │  │
│  │  │   (Stimulus: ai-draft)     │  │  │  - 예약 발행, 고정글      │  │
│  │  ├────────────────────────────┤  │  │  - SEO 필드              │  │
│  │  │   <admin-rhino-editor>     │  │  └──────────────────────────┘  │
│  │  │   Custom toolbar (NEW)     │  │                                │
│  │  │   TipTap + extensions      │  │                                │
│  │  │   (AdminRhinoEditor class) │  │                                │
│  │  └────────────────────────────┘  │                                │
│  └──────────────────────────────────┘                                │
├─────────────────────────────────────────────────────────────────────┤
│                    application.js (Vite entrypoint)                   │
│  ┌──────────────────┐  ┌────────────────────┐  ┌─────────────────┐  │
│  │  import           │  │  import             │  │  import          │  │
│  │  "rhino-editor"  │  │  Stimulus           │  │  admin_rhino_   │  │
│  │  (global reg.)   │  │  controllers        │  │  editor (NEW)   │  │
│  └──────────────────┘  └────────────────────┘  └─────────────────┘  │
├─────────────────────────────────────────────────────────────────────┤
│                    TipTap Extension Layer (NEW)                        │
│  ┌──────────┐ ┌──────────┐ ┌──────────┐ ┌──────────┐ ┌──────────┐  │
│  │TextAlign │ │Underline │ │  Color   │ │Highlight │ │  Table   │  │
│  └──────────┘ └──────────┘ └──────────┘ └──────────┘ └──────────┘  │
│  ┌──────────┐ ┌──────────┐                                          │
│  │FontSize  │ │Suggestion│  (optional: slash command)               │
│  │(TextStyle│ │          │                                          │
│  └──────────┘ └──────────┘                                          │
└─────────────────────────────────────────────────────────────────────┘
```

### Component Responsibilities

| Component | Responsibility | Typical Implementation |
|-----------|----------------|------------------------|
| `<rhino-editor>` | Lit Web Component wrapping TipTap + ActionText integration | Registered globally via `import "rhino-editor"` in application.js — used on public post form, unchanged |
| `TipTapEditorBase` | Base class exposing `extensions` property, `addExtensions()`, `editorOptions()`, `updateInputElementValue()` | rhino-editor internal class — consumed via subclass |
| `TipTapEditor` | Concrete `<rhino-editor>` element with toolbar slots, bubble menu, and link dialog | Subclassable via ES6 class extension |
| `AdminRhinoEditor` (NEW) | Subclass of `TipTapEditor` with extended extensions and custom toolbar | New file: `app/frontend/editor/admin_rhino_editor.js` |
| Stimulus `ai-draft` | Bridges AI draft generation to editor `commands.setContent()` | MODIFY: update querySelector target from `"rhino-editor"` to `"admin-rhino-editor"` |

## Integration Approaches

Two patterns are valid. **Pattern A is recommended** for this milestone.

---

### Pattern A: Subclass TipTapEditor (Recommended)

**What:** Create `AdminRhinoEditor extends TipTapEditor`, override `editorOptions()` to inject new extensions, override `renderToolbar()` to add new toolbar buttons, register as a separate custom element `<admin-rhino-editor>`.

**Why recommended:**
- `editorOptions()` is the documented extension point in rhino-editor source — override merges with parent defaults cleanly
- All extension logic lives in one JS class — no DOM queries or Stimulus coordination needed
- Clean isolation: `<rhino-editor>` on the public post form stays untouched
- `renderToolbar()` returns a Lit `TemplateResult` — override gives full control without slot fighting
- Lit is already a transitive dependency of rhino-editor (zero extra bundle cost)

**Trade-offs:**
- Requires Lit `html` tagged template literals for toolbar rendering
- New custom element tag `<admin-rhino-editor>` must be used in admin ERB
- `ai_draft_controller.js` querySelector must be updated (one-line change)

**Example:**
```javascript
// app/frontend/editor/admin_rhino_editor.js
import { TipTapEditor } from "rhino-editor/exports/elements/tip-tap-editor.js"
import { html } from "lit"
import TextAlign from "@tiptap/extension-text-align"
import Underline from "@tiptap/extension-underline"
import Color from "@tiptap/extension-color"
import TextStyle from "@tiptap/extension-text-style"
import Highlight from "@tiptap/extension-highlight"
import Table from "@tiptap/extension-table"
import TableRow from "@tiptap/extension-table-row"
import TableCell from "@tiptap/extension-table-cell"
import TableHeader from "@tiptap/extension-table-header"

export class AdminRhinoEditor extends TipTapEditor {
  editorOptions(element) {
    const parentOptions = super.editorOptions(element)
    return {
      ...parentOptions,
      extensions: [
        ...(parentOptions.extensions || []),
        TextAlign.configure({ types: ["heading", "paragraph"] }),
        Underline,
        Color,
        TextStyle,
        Highlight.configure({ multicolor: true }),
        Table.configure({ resizable: true }),
        TableRow,
        TableCell,
        TableHeader,
      ]
    }
  }

  renderToolbar() {
    // Extend or replace the base toolbar using Lit html
    return html`
      ${super.renderToolbar()}
      <!-- Additional toolbar buttons rendered here -->
    `
  }
}

if (!customElements.get("admin-rhino-editor")) {
  customElements.define("admin-rhino-editor", AdminRhinoEditor)
}
```

```erb
<!-- app/views/admin/posts/_form.html.erb -->
<admin-rhino-editor
  input="<%= f.field_id(:body) %>"
  data-blob-url-template="<%= rails_service_blob_url(":signed_id", ":filename") %>"
  data-direct-upload-url="<%= rails_direct_uploads_url %>"
  class="w-full min-h-[400px] rounded-2xl border border-gray-300"
></admin-rhino-editor>
```

---

### Pattern B: Slot Injection + Stimulus Controller

**What:** Keep `<rhino-editor>` tag, inject custom toolbar buttons via named slots (`toolbar-start`, `toolbar-end`), use a Stimulus controller to call `rhinoEditor.editor.commands.*` on clicks.

**Why not recommended for v1.3:**
- Slots can add buttons but **cannot register new TipTap extensions**. TextAlign, Underline, Color, Table all require extension registration at TipTap init time.
- Stimulus controller must DOM-query `<rhino-editor>` and manage async init timing via `initializationComplete` promise.

---

### Pattern C: addExtensions() After Mount

**What:** After `<rhino-editor>` mounts, call `rhinoEditor.addExtensions(TextAlign, ...)` from a Stimulus controller.

**Why not recommended:**
- `addExtensions()` internally calls `rebuildEditor()` — destroys and recreates the TipTap instance. Content loss risk.
- Race condition on Turbo Drive navigation (custom element lifecycle vs Turbo page cache).

---

## Recommended Project Structure

```
app/frontend/
├── entrypoints/
│   └── application.js              # MODIFY: add import "../editor/admin_rhino_editor"
├── controllers/
│   └── ai_draft_controller.js      # MODIFY: querySelector "rhino-editor" -> "admin-rhino-editor"
├── editor/                         # NEW directory
│   ├── admin_rhino_editor.js       # NEW: AdminRhinoEditor class + customElements.define
│   └── admin_toolbar_helpers.js    # NEW (optional): extracted Lit template helpers if toolbar grows large
app/views/admin/posts/
└── _form.html.erb                  # MODIFY: <rhino-editor> -> <admin-rhino-editor>
app/views/posts/
└── _form.html.erb                  # UNCHANGED: public form keeps plain <rhino-editor>
```

### Structure Rationale

- **`app/frontend/editor/`:** Keeps editor extension code isolated from Stimulus controllers. Different concern (TipTap API) vs DOM event handling (Stimulus). Mirrors how `components/landing/` and `components/checkout/` isolate React components.
- **Single registration in `application.js`:** Admin layout already loads `application.js`. No separate entrypoint needed. The `<admin-rhino-editor>` custom element definition is harmless on public pages (undefined custom elements are silently ignored by browsers).
- **No Rails-side changes needed:** ActionText serialization is unchanged. New extensions (TextAlign, Underline, Color, Highlight, Table) output standard HTML that ActionText stores verbatim in the `body` rich text column. No migrations required.

## Data Flow

### Extension Registration Flow

```
application.js loads
    |
    +-- import "rhino-editor"
    |       registers <rhino-editor> globally
    +-- import "../editor/admin_rhino_editor"
            registers <admin-rhino-editor> globally
    |
Admin post form renders (<admin-rhino-editor> element)
    |
connectedCallback() fires -> startEditor() -> editorOptions()
    |
editorOptions() merges:
    parent extensions (StarterKit + RhinoStarterKit)
    + TextAlign + Underline + Color + TextStyle + Highlight + Table + ...
    |
TipTap Editor initialized with ALL extensions
    |
User edits content
    |
TipTap commands called:
    editor.commands.toggleUnderline()
    editor.commands.setColor('#ff0000')
    editor.commands.insertTable({ rows: 3, cols: 3 })
    |
TipTap transaction dispatched -> ProseMirror state update
    |
rhino-editor __handleTransaction fires -> updateInputElementValue()
    |
Hidden input (post[body]) updated with Trix-compatible HTML
    |
Form submit -> Rails ActionText stores HTML in body rich_text column
```

### ai_draft_controller.js Impact

The current controller uses:
```javascript
const rhinoEditor = document.querySelector("rhino-editor")
```

After ERB tag change to `<admin-rhino-editor>`, this becomes:
```javascript
const rhinoEditor = document.querySelector("admin-rhino-editor")
```

The `rhinoEditor.editor.commands.setContent()` and `rhinoEditor.updateInputElementValue()` calls are **identical** — `AdminRhinoEditor` inherits all methods from `TipTapEditorBase`.

### ActionText Compatibility

| Extension | HTML Output | Rails Storage | Notes |
|-----------|-------------|--------------|-------|
| TextAlign | `style="text-align: center"` on paragraph/heading node | Stored verbatim in rich_text body | Renders via browser default or public CSS |
| Underline | `<u>` tag | Stored verbatim | Standard HTML |
| Color | `<span style="color: #hex">` via TextStyle | Stored verbatim | Requires TextStyle as peer extension |
| Highlight | `<mark style="background: #hex">` | Stored verbatim | |
| Table | `<table><tr><th><td>` | Stored verbatim | Public view CSS must include table styles |
| FontSize | `<span style="font-size: Npx">` via TextStyle | Stored verbatim | Requires TextStyle |

No Rails migrations, no ActionText configuration changes, no model changes required.

## Build Order (Phase Dependencies)

```
Phase 1: Scaffold
  - Install @tiptap extension packages (pinned to 2.27.2)
  - Create app/frontend/editor/admin_rhino_editor.js
    (initially just subclass with no extra extensions to verify setup)
  - Update application.js import
  - Update _form.html.erb tag: <rhino-editor> -> <admin-rhino-editor>
  - Update ai_draft_controller.js querySelector
  - Verify: editor still works, AI draft still works

Phase 2: Basic marks (no new packages needed)
  - Configure starterKitOptions: heading levels [1,2,3]
  - Add Underline extension
  - Add toolbar buttons: H1/H2/H3 dropdown, underline button
  - Strike: already in RhinoStarterKit as <del> — may just need toolbar button

Phase 3: Text alignment
  - Add TextAlign extension (configure for heading + paragraph)
  - Add 3 toolbar buttons: align left / center / right

Phase 4: Color and Highlight
  - Add TextStyle extension (required peer for Color)
  - Add Color extension
  - Add Highlight extension (multicolor: true)
  - Add toolbar: color picker (<input type="color"> -> setColor command), highlight picker

Phase 5: Table
  - Add Table + TableRow + TableCell + TableHeader extensions
  - Add insert-table button in toolbar
  - Add table context toolbar (add/remove row/column, delete table)
  - Table CSS for public post view

Phase 6: Font size
  - TextStyle already added in Phase 4 — no new package
  - Add font size dropdown or input -> setFontSize command

Phase 7: Block insert menu (slash command) — highest complexity, last
  - Add @tiptap/suggestion
  - Implement slash command trigger and menu UI
  - Commands: insert heading, blockquote, codeblock, horizontal rule, table
```

Each phase is independently releasable. Phases 2-4 can proceed in parallel if needed.

## Architectural Patterns

### Pattern 1: Extension Configuration via starterKitOptions

**What:** Built-in extensions (Heading, Strike, Blockquote, CodeBlock) in StarterKit can be configured via `starterKitOptions` property without subclassing. Pass options to the element or set in the subclass constructor.

**When to use:** Adjusting behavior of extensions already present in rhino-editor's StarterKit — e.g., restricting heading levels to H1-H3 only.

**Trade-offs:** Cannot add new extensions (TextAlign, Table, etc.) this way — only configure existing ones.

**Example:**
```javascript
// In AdminRhinoEditor constructor
constructor() {
  super()
  this.starterKitOptions = { heading: { levels: [1, 2, 3] } }
}
```

### Pattern 2: Lit html Template for Toolbar Rendering

**What:** Override `renderToolbar()` in the subclass. Use Lit's `html` tagged template literal to compose the toolbar. Call `super.renderToolbar()` to include the base buttons, then append new buttons.

**When to use:** Required for new toolbar buttons, dropdowns, color pickers, and heading level selectors.

**Trade-offs:** Must import `html` from `lit`. The base toolbar buttons rendered by `super.renderToolbar()` use rhino-editor's internal Lit template — they render in the shadow DOM. New buttons added outside the shadow root appear in light DOM and must account for shadow DOM CSS isolation.

**Example:**
```javascript
renderToolbar() {
  return html`
    ${super.renderToolbar()}
    <button @click="${() => this.editor?.commands.toggleUnderline()}"
            class="${this.editor?.isActive('underline') ? 'active' : ''}">
      U
    </button>
  `
}
```

### Pattern 3: Toolbar Slots (Additive, No Subclass Required)

**What:** rhino-editor exposes named slots: `toolbar-start`, `toolbar-end`, `before-{button-name}-button`, `after-{button-name}-button`. Inject HTML elements into these slots to augment the default toolbar.

**When to use:** Only when adding buttons for extensions already registered — e.g., if using Pattern A (subclass) and wanting to inject one or two simple buttons without overriding the full toolbar.

**Trade-offs:** Slot elements live in light DOM and communicate with the TipTap editor via direct JS calls. Cannot replace the entire toolbar structure.

## Anti-Patterns

### Anti-Pattern 1: Modifying the Global `<rhino-editor>` Registration

**What people do:** Import `TipTapEditor` from rhino-editor and monkey-patch its prototype or call `addExtensions()` on the global element during page load.

**Why it's wrong:** Affects the public post form (`posts/_form.html.erb`) which also uses `<rhino-editor>`. Table, Color, and TextAlign extensions add unnecessary ProseMirror schema complexity to the member-facing editor. Public users do not need these extensions — adding them increases bundle weight and schema validation overhead for zero benefit.

**Do this instead:** Subclass and register a separate `<admin-rhino-editor>` custom element. The public `<rhino-editor>` is untouched.

### Anti-Pattern 2: Mismatched @tiptap Package Versions

**What people do:** Install extensions without pinning to the exact version that rhino-editor peers against (`@tiptap/core@2.27.2`).

**Why it's wrong:** TipTap extensions share a ProseMirror schema registry. Version mismatches cause duplicate node/mark registrations — resulting in schema conflicts and editor initialization crashes.

**Do this instead:** Pin all `@tiptap/*` installs to exactly `2.27.2`:
```bash
pnpm add @tiptap/extension-text-align@2.27.2 @tiptap/extension-underline@2.27.2 @tiptap/extension-color@2.27.2 @tiptap/extension-text-style@2.27.2 @tiptap/extension-highlight@2.27.2 @tiptap/extension-table@2.27.2 @tiptap/extension-table-row@2.27.2 @tiptap/extension-table-cell@2.27.2 @tiptap/extension-table-header@2.27.2
```

### Anti-Pattern 3: Calling addExtensions() After Mount

**What people do:** In a Stimulus controller `connect()`, call `document.querySelector("rhino-editor").addExtensions(TextAlign, ...)` after the editor renders.

**Why it's wrong:** `addExtensions()` internally calls `rebuildEditor()` which destroys and recreates the TipTap instance — content loss risk if called mid-edit. Also triggers a double rebuild on Turbo Drive navigation (custom element re-connects after page restore from Turbo cache).

**Do this instead:** Pass all extensions via `editorOptions()` override in the subclass. Extensions are registered at init time.

### Anti-Pattern 4: Forgetting to Update ai_draft_controller.js querySelector

**What people do:** Change the ERB tag from `<rhino-editor>` to `<admin-rhino-editor>` but leave the Stimulus controller's querySelector unchanged.

**Why it's wrong:** `document.querySelector("rhino-editor")` returns `null` on the admin form, causing the AI draft insertion to silently fail with "에디터를 찾을 수 없습니다" error message. No build-time error surfaces.

**Do this instead:** The querySelector update is step 1 of the scaffold phase, verified before any other work proceeds.

### Anti-Pattern 5: Missing TextStyle When Using Color Extension

**What people do:** Install `@tiptap/extension-color` without also installing `@tiptap/extension-text-style`.

**Why it's wrong:** The Color extension requires TextStyle as a peer — it applies color via the TextStyle mark. Without TextStyle registered, `editor.commands.setColor()` silently does nothing.

**Do this instead:** Always register TextStyle before Color and FontSize in the extensions array.

## Integration Points

### New vs Modified Components Summary

| Component | Status | Change |
|-----------|--------|--------|
| `app/frontend/editor/admin_rhino_editor.js` | NEW | AdminRhinoEditor class + `<admin-rhino-editor>` registration |
| `app/frontend/editor/admin_toolbar_helpers.js` | NEW (optional) | Extracted Lit toolbar render helpers |
| `app/frontend/entrypoints/application.js` | MODIFIED | Add `import "../editor/admin_rhino_editor"` |
| `app/views/admin/posts/_form.html.erb` | MODIFIED | `<rhino-editor>` -> `<admin-rhino-editor>` |
| `app/frontend/controllers/ai_draft_controller.js` | MODIFIED | Update querySelector target |
| `app/views/posts/_form.html.erb` | UNCHANGED | Public form keeps `<rhino-editor>` |
| Rails models / migrations | UNCHANGED | ActionText stores HTML verbatim |
| `app/views/layouts/admin.html.erb` | UNCHANGED | Already loads `application.js` |

### New npm Packages Required

All must be installed at `@2.27.2` to match the `@tiptap/core` version already installed as a rhino-editor transitive dependency.

| Package | Purpose | Status |
|---------|---------|--------|
| `@tiptap/extension-text-align` | Left/center/right alignment | NOT installed |
| `@tiptap/extension-underline` | Underline mark | NOT installed |
| `@tiptap/extension-color` | Text color | NOT installed |
| `@tiptap/extension-text-style` | Required peer for Color and FontSize | NOT installed |
| `@tiptap/extension-highlight` | Background color/highlight mark | NOT installed |
| `@tiptap/extension-table` | Table node | NOT installed |
| `@tiptap/extension-table-row` | Table row node | NOT installed |
| `@tiptap/extension-table-cell` | Table cell node | NOT installed |
| `@tiptap/extension-table-header` | Table header node | NOT installed |
| `@tiptap/suggestion` | Slash command menu trigger | NOT installed (optional, Phase 7 only) |

Already installed (transitive via rhino-editor at `2.27.2`):
- `@tiptap/extension-strike` — `rhinoStrike` variant uses `<del>` tag
- `@tiptap/extension-code-block` — in StarterKit
- `@tiptap/extension-blockquote` — in StarterKit
- `@tiptap/extension-horizontal-rule` — in StarterKit
- `@tiptap/extension-heading` — in StarterKit (configure `levels: [1,2,3]` via starterKitOptions)

## Scaling Considerations

This feature is Admin-only for a 1-person operator. No scaling concerns apply. Architecture decisions are driven by maintainability and non-interference with the public editor.

| Scale | Architecture Adjustments |
|-------|--------------------------|
| 1 admin user | Current approach is sufficient indefinitely |
| Multiple admin editors | No changes — AdminRhinoEditor is stateless per-page-load |
| Collaborative editing | Out of scope per PROJECT.md (Y.js explicitly excluded) |

## Sources

- rhino-editor 0.17.3: `exports/elements/tip-tap-editor-base.d.ts` — `extensions` property, `editorOptions()`, `addExtensions()`, `updateInputElementValue()` API confirmed (HIGH confidence)
- rhino-editor 0.17.3: `exports/elements/tip-tap-editor.d.ts` — slot names, `renderToolbar()`, `renderBoldButton()` etc. confirmed (HIGH confidence)
- rhino-editor 0.17.3: `exports/extensions/rhino-starter-kit.d.ts` — confirmed extensions already included in StarterKit (HIGH confidence)
- Installed @tiptap packages: direct inspection of `node_modules/.pnpm/` — confirmed `@tiptap/core@2.27.2` version and missing packages (HIGH confidence)
- Existing codebase: `app/frontend/controllers/ai_draft_controller.js` — confirmed `querySelector("rhino-editor")` and `commands.setContent` pattern (HIGH confidence)
- Existing codebase: `app/views/admin/posts/_form.html.erb` — confirmed current `<rhino-editor>` usage and 2-column layout (HIGH confidence)
- `@tiptap/extension-text-style` as Color peer: TipTap official docs pattern — MEDIUM confidence (verify against 2.27.2 changelog before install)

---

*Architecture research for: v1.3 Admin 에디터 고도화 — TipTap extensions with rhino-editor*
*Researched: 2026-03-14*
