# Stack Research

**Domain:** Admin rich text editor enhancement — TipTap extensions for rhino-editor 0.17.x
**Researched:** 2026-03-14
**Confidence:** HIGH

---

## Scope

This document covers only the new v1.3 features. The existing validated stack (Rails 8.1.2, Hotwire, vite_ruby, Tailwind CSS 4.4, rhino-editor 0.17.3) is not re-researched.

New features (v1.3 Admin Editor Enhancement):
- 구분선 (HorizontalRule) — already in StarterKit
- 인용구 (Blockquote) — already in StarterKit
- 소스코드 블록 with syntax highlighting
- 취소선 (Strike) — already in StarterKit
- 밑줄 (Underline) — must add
- 텍스트 정렬 (Text Align left/center/right) — must add
- 제목 레벨 드롭다운 (H1~H3) — already in StarterKit
- 글자색 (Text Color) — must add
- 배경색/하이라이트 (Highlight) — must add
- 표(Table) 삽입 및 편집 — must add
- 블록 삽입 메뉴 (toolbar buttons) — Stimulus controller pattern
- 폰트 크기 조절 (Font Size) — must add (custom extension, no v2 npm package)

---

## Resolved TipTap Version

rhino-editor 0.17.3 declares `@tiptap/core: ^2.9.1` as a dependency.
The actual resolved version in `pnpm-lock.yaml` is **`@tiptap/core@2.27.2`**.

All new extensions must pin to `^2.27.2` to match. All the required extensions have 2.27.2 on npm.

---

## What Is Already Installed (No Action Needed)

rhino-editor 0.17.3 bundles these via `@tiptap/starter-kit@2.27.2`:

| Feature | Extension | Notes |
|---------|-----------|-------|
| 구분선 (HorizontalRule) | `HorizontalRule` | Included in StarterKit |
| 인용구 (Blockquote) | `Blockquote` | Included in StarterKit |
| 소스코드 블록 (plain) | `CodeBlock` | Included in StarterKit — replace with lowlight version |
| 취소선 (Strike) | `Strike` | Included in StarterKit |
| 제목 H1~H3 | `Heading` | Included in StarterKit |
| Bold, Italic | `Bold`, `Italic` | Included in StarterKit |
| 목록 | `BulletList`, `OrderedList` | Included in StarterKit |
| History (Undo/Redo) | `History` | Included in StarterKit |
| TextStyle mark | `@tiptap/extension-text-style@2.27.2` | Transitive dep of rhino-editor; foundation for Color and custom FontSize |

---

## Recommended Stack: New Extensions to Install

### Core Extensions (npm install required)

| Technology | Version | Purpose | Why Recommended |
|------------|---------|---------|-----------------|
| `@tiptap/extension-text-align` | `^2.27.2` | Left / center / right alignment on paragraphs and headings | Official TipTap v2 extension; 2.27.2 matches existing lockfile — zero peer dep conflicts |
| `@tiptap/extension-color` | `^2.27.2` | Text foreground color via `<span style="color:...">` | Official TipTap v2; requires TextStyle mark which is already installed as transitive dep |
| `@tiptap/extension-highlight` | `^2.27.2` | Background highlight color via `<mark>` | Official TipTap v2; `multicolor: true` enables color palette |
| `@tiptap/extension-underline` | `^2.27.2` | Underline mark (`<u>`) | Not included in StarterKit; official TipTap v2 extension |
| `@tiptap/extension-table` | `^2.27.2` | Table node (insert, edit, resize) | Official TipTap v2; all four table packages must be installed together |
| `@tiptap/extension-table-row` | `^2.27.2` | Table row node | Required companion for Table |
| `@tiptap/extension-table-cell` | `^2.27.2` | Table cell `<td>` | Required companion for Table |
| `@tiptap/extension-table-header` | `^2.27.2` | Table header cell `<th>` | Required companion for Table |
| `@tiptap/extension-code-block-lowlight` | `^2.27.2` | Code block with syntax highlighting | Replaces plain CodeBlock from StarterKit; rhino-editor official docs recommend this pattern |
| `lowlight` | `^3.3.0` | Syntax highlighting engine (highlight.js ESM wrapper) | peerDep of code-block-lowlight; accepts `^2 || ^3`; use 3.x for Vite ESM compatibility |

### Supporting Libraries

| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| `lowlight/common` subset | included in `lowlight` | Common language syntax definitions (JS, Ruby, Python, etc.) | Use `createLowlight(common)` — avoids bundling all 200+ languages |
| `@tiptap/extension-font-family` | `^2.27.2` | Font family via `<span style="font-family:...">` | Only if font-family control is desired; requires TextStyle which is already installed |

### Custom Extension (Write Locally — No npm Install)

| Extension | Source | Purpose | Implementation |
|-----------|--------|---------|---------------|
| `FontSize` | `app/frontend/extensions/font-size.js` | Font size via `<span style="font-size:...">` | `@tiptap/extension-font-size` does not exist in TipTap v2 (v3+ only). Build a custom extension using `@tiptap/extension-text-style` as the foundation. Pattern: `addGlobalAttributes()` on TextStyle with `font-size` CSS property. Provides `setFontSize(value)` and `unsetFontSize()` commands. ~25 lines. |

### Stimulus Controller (No npm Install)

| Tool | Source | Purpose | Notes |
|------|--------|---------|-------|
| `rhino_editor_controller.js` | `app/frontend/controllers/` | Wire toolbar button actions to TipTap commands | Create new Stimulus controller; attach to the `<rhino-editor>` element wrapper; use `element.editor.chain().focus()...run()` pattern |

---

## Integration Pattern with rhino-editor

rhino-editor 0.17.x provides two integration hooks. **Use the `rhino-before-initialize` event for Admin-only enhancement** — simpler and does not require changing the ERB tag name.

### Pattern 1: `rhino-before-initialize` Event (Recommended)

```javascript
// app/frontend/entrypoints/rhino-extensions.js
// (imported in application.js after "rhino-editor")

import TextAlign from "@tiptap/extension-text-align"
import Color from "@tiptap/extension-color"
import TextStyle from "@tiptap/extension-text-style"
import Highlight from "@tiptap/extension-highlight"
import Underline from "@tiptap/extension-underline"
import Table from "@tiptap/extension-table"
import TableRow from "@tiptap/extension-table-row"
import TableCell from "@tiptap/extension-table-cell"
import TableHeader from "@tiptap/extension-table-header"
import CodeBlockLowlight from "@tiptap/extension-code-block-lowlight"
import { common, createLowlight } from "lowlight"
import FontSize from "../extensions/font-size.js"

const lowlight = createLowlight(common)

document.addEventListener("rhino-before-initialize", (event) => {
  const rhino = event.target

  // Disable default plain CodeBlock — replaced by lowlight version
  rhino.starterKitOptions = {
    ...rhino.starterKitOptions,
    codeBlock: false,
  }

  rhino.extensions = [
    ...rhino.extensions,
    TextStyle,                                      // foundation for Color + FontSize
    TextAlign.configure({ types: ["heading", "paragraph"] }),
    Color,
    Highlight.configure({ multicolor: true }),
    Underline,
    Table.configure({ resizable: true }),
    TableRow,
    TableCell,
    TableHeader,
    CodeBlockLowlight.configure({ lowlight }),
    FontSize,
  ]
})
```

### Pattern 2: Subclass TipTapEditor (Alternative)

```javascript
import { TipTapEditor } from "rhino-editor/exports/elements/tip-tap-editor.js"

class AdminRhinoEditor extends TipTapEditor {
  constructor() {
    super()
    this.extensions = [
      ...this.extensions,
      TextAlign.configure({ types: ["heading", "paragraph"] }),
      // ...other extensions
    ]
  }
}
AdminRhinoEditor.define("admin-rhino-editor")
// ERB: use <admin-rhino-editor> instead of <rhino-editor>
```

Use Approach 1 unless Admin needs a completely separate editor component from the public post form.

### Toolbar Button Injection (HTML Slots)

rhino-editor uses HTML slot-based toolbar customization. Insert buttons inside `<rhino-editor>`:

```erb
<rhino-editor input="..." data-controller="rhino-editor">
  <button type="button"
          slot="after-italic-button"
          class="rhino-toolbar-button"
          data-role="toolbar-item"
          tabindex="-1"
          data-action="click->rhino-editor#toggleUnderline">
    U
  </button>
</rhino-editor>
```

Available slots follow the pattern `before-{name}-button` and `after-{name}-button` for every built-in toolbar button.

---

## Installation

```bash
# New extensions for v1.3 features
pnpm add @tiptap/extension-text-align@^2.27.2
pnpm add @tiptap/extension-color@^2.27.2
pnpm add @tiptap/extension-highlight@^2.27.2
pnpm add @tiptap/extension-underline@^2.27.2
pnpm add @tiptap/extension-table@^2.27.2 \
         @tiptap/extension-table-row@^2.27.2 \
         @tiptap/extension-table-cell@^2.27.2 \
         @tiptap/extension-table-header@^2.27.2
pnpm add @tiptap/extension-code-block-lowlight@^2.27.2
pnpm add lowlight@^3.3.0

# Optional: font-family support
pnpm add @tiptap/extension-font-family@^2.27.2
```

Note: `@tiptap/extension-text-style` is already a transitive dep (confirmed in pnpm-lock.yaml). Do not re-install unless `pnpm why @tiptap/extension-text-style` shows it missing.

---

## Alternatives Considered

| Recommended | Alternative | When to Use Alternative |
|-------------|-------------|-------------------------|
| `@tiptap/extension-*@^2.27.2` (all new extensions) | Upgrade to TipTap v3 | Only when rhino-editor ships a version with TipTap v3 support. Current 0.17.x is locked to v2. |
| Custom FontSize extension (local file) | `@tiptap/extension-font-size` npm package | When rhino-editor upgrades to TipTap v3 which includes the official FontSize extension. |
| `lowlight@^3.x` with `createLowlight(common)` | `highlight.js` directly | lowlight provides smaller, tree-shakeable ESM bundle; already the approach in rhino-editor's official syntax highlighting docs. |
| `rhino-before-initialize` event pattern | Subclassing `TipTapEditor` | Subclassing is better when building a completely separate editor component with different capabilities from the user-facing editor. |

---

## What NOT to Use

| Avoid | Why | Use Instead |
|-------|-----|-------------|
| `@tiptap/extension-font-size` (npm) | Does not exist in TipTap v2. No 2.x version available on npm. Installing would pull TipTap v3 packages causing version conflicts with rhino-editor's locked 2.27.2 peer deps. | Custom FontSize extension built on `@tiptap/extension-text-style` |
| Any `@tiptap/*@^3.x` package | TipTap v3 has breaking changes (renamed options, moved packages, changed marks). Mixing 2.x and 3.x TipTap packages causes silent runtime failures because ProseMirror extension registration conflicts. | Pin all new extensions to `^2.27.2` |
| Replace rhino-editor entirely | rhino-editor provides ActionText-compatible serialization, Active Storage image upload integration, and Rails Direct Upload hooks. Replacing it requires re-implementing all Rails integration layers. | Extend rhino-editor via `rhino-before-initialize` |
| `tiptap-extension-font-size` (community npm) | Unmaintained third-party package; no TypeScript types; last release 2+ years ago; unclear TipTap v2 compatibility. | Write a 25-line custom extension using the documented `addGlobalAttributes` pattern |
| Upgrade rhino-editor to 0.18.x | 0.18.x removed built-in image upload (documented in PROJECT.md Key Decisions — stay on 0.17.3). | Stay on `rhino-editor@0.17.3` |

---

## Version Compatibility

| Package | Compatible With | Notes |
|---------|-----------------|-------|
| All `@tiptap/extension-*@^2.27.2` | `@tiptap/core@2.27.2`, `@tiptap/pm@2.27.2` | Same minor version across all packages — zero peer dep conflict |
| `lowlight@^3.3.0` | `@tiptap/extension-code-block-lowlight@2.27.2` | peerDep range is `^2 || ^3`; use 3.x for Vite/ESM tree-shaking |
| `@tiptap/extension-color@2.27.2` | `@tiptap/extension-text-style@2.27.2` | Color requires TextStyle mark to be registered first; TextStyle already in lockfile as transitive dep |
| `@tiptap/extension-highlight@2.27.2` | `@tiptap/core@2.27.2` | `multicolor: true` stores color in `data-color` attribute on `<mark>` tag |
| `@tiptap/extension-table@2.27.2` | `@tiptap/extension-table-row`, `@tiptap/extension-table-cell`, `@tiptap/extension-table-header` all at `2.27.2` | All four must be installed together; Table node is non-functional without companion row/cell nodes |
| Custom `FontSize` extension | `@tiptap/extension-text-style@2.27.2` | Must register `TextStyle` before `FontSize` in the extensions array |

---

## Sources

- `teovibe/node_modules/rhino-editor/package.json` (local) — confirmed TipTap dep range `^2.9.1` (HIGH)
- `teovibe/pnpm-lock.yaml` (local) — confirmed all `@tiptap/*` resolve to `2.27.2` (HIGH)
- `npm view @tiptap/extension-{text-align,color,highlight,table,table-row,table-cell,table-header,underline,code-block-lowlight} versions` (live CLI) — confirmed 2.27.2 availability for all packages (HIGH)
- `npm view @tiptap/extension-code-block-lowlight@2.27.2 peerDependencies` — confirmed `lowlight: ^2 || ^3` (HIGH)
- `npm view @tiptap/extension-font-size versions` — confirmed no 2.x version exists (HIGH)
- rhino-editor docs `https://rhino-editor.vercel.app/tutorials/setup/` — TipTapEditor subclass pattern (HIGH)
- rhino-editor docs `https://rhino-editor.vercel.app/how-tos/syntax-highlighting` — `rhino-before-initialize` event pattern, `starterKitOptions.codeBlock: false` (HIGH)
- rhino-editor docs `https://rhino-editor.vercel.app/how-tos/customizing-the-toolbar/` — HTML slot toolbar customization (HIGH)
- TipTap docs `https://tiptap.dev/docs/editor/extensions/functionality/starterkit` — StarterKit extension list (HIGH)
- GitHub gist font-size-for-tiptap-v2 — custom FontSize via TextStyle addGlobalAttributes pattern (MEDIUM, community-verified for v2)

---

*Stack research for: TeoVibe v1.3 Admin Editor Enhancement — TipTap extensions for rhino-editor 0.17.x*
*Researched: 2026-03-14*
