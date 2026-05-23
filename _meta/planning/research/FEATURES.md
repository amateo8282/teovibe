# Feature Research

**Domain:** Rich text editor enhancement — TipTap/rhino-editor Admin editor (v1.3 Milestone)
**Researched:** 2026-03-14
**Confidence:** HIGH (TipTap official docs verified, rhino-editor 0.17.3 source inspected)

---

## Context: What Already Exists

rhino-editor 0.17.3 is locked (0.18.x removes image upload — must not upgrade). It wraps TipTap via `RhinoStarterKit`. Source-inspected `rhino-starter-kit.d.ts` confirms these are **already registered**:

- Marks: Bold, Italic, rhinoStrike (renders `<del>`, not TipTap default `<s>`), Underline, rhinoLink
- Nodes: Heading, Blockquote, CodeBlock, HorizontalRule, BulletList, OrderedList
- Functionality: BubbleMenu, Placeholder, rhinoFocus, rhinoGallery, rhinoAttachment, rhinoImage, rhinoFigcaption, rhinoPasteEvent, rhinoCodemarkPlugin, rhinoSelection

**Critical finding for v1.3:** Strike, Underline, Blockquote, HorizontalRule, and CodeBlock are already **registered** in the editor schema. The work to expose them is **toolbar UI only** — zero new extensions needed for those five.

**Not in RhinoStarterKit** (require new extension installs): TextAlign, Table family (4 packages), Color, Highlight, FontSize.

**Extension injection API:** extend `TipTapEditor` class and push to `this.extensions = [...this.extensions, newExtension]`, or use the `rhino-before-initialize` event hook for non-class approaches.

---

## Feature Landscape

### Table Stakes (Users Expect These for a "Real" Blog Editor)

Features an admin-level blog editor must have. Without these, writing structured content feels limited compared to Naver Blog or Notion. An admin who writes daily content will notice every missing item.

| Feature | Why Expected | Complexity | Notes |
|---------|--------------|------------|-------|
| Strikethrough toolbar button | Every blog editor has it. RhinoStarterKit has rhinoStrike | LOW | Toolbar button only. `editor.chain().focus().toggleStrike().run()`. No new package. |
| Underline toolbar button | Standard formatting since every word processor | LOW | Toolbar button only. `editor.chain().focus().toggleUnderline().run()`. No new package. |
| Blockquote toolbar button | Quote formatting is standard for editorial content | LOW | Toolbar button only. `editor.chain().focus().toggleBlockquote().run()`. No new package. |
| Horizontal rule insertion | Section dividers are universal in blog content | LOW | Toolbar button only. `editor.chain().focus().setHorizontalRule().run()`. No new package. |
| Code block toolbar button | Technical content is core to TeoVibe (바이브코딩 community) | LOW | Toolbar button only. `editor.chain().focus().toggleCodeBlock().run()`. No new package. |
| Heading level selector (H1~H3) | Every blog editor exposes heading hierarchy | LOW | Heading extension already registered. Custom `<select>` UI checking `editor.isActive("heading", {level: N})`. Keyboard shortcuts: Cmd+Alt+1/2/3 already work. |
| Text alignment (left / center / right) | Standard since Word/HWP; Naver Blog has it | MEDIUM | Requires `@tiptap/extension-text-align`. Not in StarterKit. Must add via `this.extensions`. Applies via `text-align` CSS style attribute on block nodes. Configure `types: ["heading", "paragraph"]`. |
| Table insertion and editing | Naver Blog standard; any content with data needs tables | HIGH | Requires `@tiptap/extension-table` + `@tiptap/extension-table-row` + `@tiptap/extension-table-cell` + `@tiptap/extension-table-header`. All 4 must be registered. Commands: insertTable, addRowAfter, addColumnAfter, deleteRow, deleteColumn, mergeCells, deleteTable. Needs a separate table bubble menu (shouldShow: isInTable callback). |

### Differentiators (Competitive Advantage for an Admin Tool)

Features that elevate the editor above basic toolbar parity. Meaningful for a 1인 운영 admin who writes frequently.

| Feature | Value Proposition | Complexity | Notes |
|---------|-------------------|------------|-------|
| Text color picker | Inline emphasis, highlight key terms without full formatting | MEDIUM | Requires `@tiptap/extension-text-style` (shared dep) + `@tiptap/extension-color`. Renders `<span style="color: #hex">`. Must build custom color swatch UI — no official free picker. Recommend 12-color preset palette for admin tool. |
| Background highlight color | Marker-pen effect; call-out emphasis common in Naver Blog | MEDIUM | Requires `@tiptap/extension-highlight` with `multicolor: true`. Shares TextStyle dep. Renders `<mark style="background-color: #hex">`. Separate command from Color extension. |
| Font size control | Visual hierarchy beyond headings; body text size variation | MEDIUM | Requires `@tiptap/extension-font-size` (official, free). Depends on TextStyle (same dep as Color). Commands: `setFontSize('16px')`, `unsetFontSize()`. Need dropdown input UI with preset sizes (12/14/16/18/20/24px). |
| Block insertion menu (+ button) | Reduces feature discoverability problem; guided block creation | HIGH | Two approaches: (1) Floating `+` button on empty lines using TipTap `FloatingMenu` extension — free, straightforward, built-in. (2) Slash commands (`/`) using `@tiptap/suggestion` — officially experimental, no published package, must copy source or use community lib (`@harshtalks/slash-tiptap`). Slash commands were deferred from v1.1 per PROJECT.md. |

### Anti-Features (Commonly Requested, Often Problematic)

| Feature | Why Requested | Why Problematic | Alternative |
|---------|---------------|-----------------|-------------|
| TipTap Pro UI Components (SlashDropdownMenu, HeadingDropdownMenu) | Polished out-of-box UI, zero build effort | Paid subscription (Start plan). Overkill for 1인 Admin. Adds vendor lock-in and recurring cost. | Custom toolbar dropdown: 20 lines of HTML + Stimulus checking `editor.isActive` |
| rhino-editor 0.18.x upgrade | Latest version, new features | 0.18.x removes image upload. Image upload is core to current Admin workflow. PROJECT.md decision: stay on 0.17.3. | Stay on 0.17.3. Add extensions without upgrading. |
| Resizable table columns | Professional/polished look | Known TipTap bug (issue #2041): column widths are lost when editor switches to non-editable mode. ActionText serialization may also strip inline width styles. | Non-resizable tables with `table-fixed` CSS. Provide add/remove row/column via bubble menu instead. |
| Syntax highlighting in code blocks | Developer-friendly, expected in technical blogs | Adds `lowlight` + language grammar bundles (significant bundle weight). Not needed for admin-only tool. | Plain code block for v1.3. Add lowlight as v1.4 if content is primarily technical code. |
| Full font family selection | MS Word / Google Docs parity | Renders inconsistently across devices. ActionText HTML serialization may strip font-family. Hard to enforce brand consistency in frontend rendering. | Font size only for hierarchy control. System font stack enforced in CSS. |
| Collaborative editing | Nice for teams | PROJECT.md explicitly Out of Scope. 1인 운영, adds WebSocket infra and Y.js complexity. | Single-author model. Not needed. |

---

## Feature Dependencies

```
[Text Color]
    └──requires──> [TextStyle extension (@tiptap/extension-text-style)]
                       └──also required by──> [Font Size]
                                              [Font Family (if ever added)]

[Background Highlight]
    └──requires──> [Highlight extension (@tiptap/extension-highlight)]
                       └──optional: shares TextStyle (not required for Highlight itself)

[Table editing (rows/cols)]
    └──requires──> [@tiptap/extension-table]
    └──requires──> [@tiptap/extension-table-row]
    └──requires──> [@tiptap/extension-table-cell]
    └──requires──> [@tiptap/extension-table-header]
                       └──enhanced by──> [Table bubble menu (shouldShow: isInTable)]

[Block insertion floating menu]
    └──requires──> [FloatingMenu extension (already bundled in TipTap)]
                   OR
                   [@tiptap/suggestion (slash commands, experimental)]

[Heading dropdown UI]
    └──requires──> [Heading extension (already in RhinoStarterKit)]
                   └──UI only, no new package needed

[Strike / Underline / Blockquote / HorizontalRule / CodeBlock buttons]
    └──requires──> [already in RhinoStarterKit — toolbar UI only]
```

### Dependency Notes

- **TextStyle is a shared dependency:** `@tiptap/extension-text-style` must be installed once. Color, FontSize, and FontFamily all depend on it. Install it first.
- **Table requires all 4 packages:** Missing `@tiptap/extension-table-row`, `@tiptap/extension-table-cell`, or `@tiptap/extension-table-header` causes ProseMirror schema validation errors. All 4 must be added to `this.extensions`.
- **Do NOT add @tiptap/extension-strike separately:** RhinoStarterKit registers `rhinoStrike` which overrides TipTap's default Strike. Adding the standard Strike extension alongside it causes duplicate mark conflicts.
- **Slash commands conflict with FloatingMenu UX:** If both a floating `+` button and slash commands are implemented, they compete for the empty-line experience. Pick one entry point or scope slash commands strictly to the `/` character trigger only.
- **Table bubble menu needs shouldShow guard:** The existing rhino-editor bubble menu fires on text selection. A separate `BubbleMenu` component with `shouldShow: ({ editor }) => editor.isActive('table')` is needed for table operations without interfering with the existing text bubble menu.

---

## MVP Definition

This milestone (v1.3) adds to an existing editor, not a greenfield build. "MVP" is the minimum to achieve "Naver Blog-level" editing as stated in PROJECT.md.

### Launch With (v1.3 core — all P1)

- [ ] Strikethrough toolbar button — 0 packages, UI only
- [ ] Underline toolbar button — 0 packages, UI only
- [ ] Blockquote toolbar button — 0 packages, UI only
- [ ] Horizontal rule button — 0 packages, UI only
- [ ] Code block button — 0 packages, UI only
- [ ] Heading level dropdown (H1~H3) — 0 packages, custom select UI only
- [ ] Text alignment (left/center/right) — 1 new package (`@tiptap/extension-text-align`) + 3 toolbar buttons
- [ ] Table insertion + row/column add/remove + merge/split — 4 new packages + table bubble menu
- [ ] Text color (preset palette) — 2 packages (`@tiptap/extension-text-style` + `@tiptap/extension-color`) + swatch UI
- [ ] Background highlight (preset palette) — 1 package (`@tiptap/extension-highlight`) + swatch UI
- [ ] Font size control (preset sizes) — 1 package (`@tiptap/extension-font-size`, shares TextStyle) + dropdown UI

### Add After Validation (P2 — add if P1 ships with time remaining)

- [ ] Block insertion floating menu (`+` button on empty line using FloatingMenu) — validate discoverability issue first
- [ ] Slash commands (`/`) — only if `+` button proves insufficient; higher maintenance, experimental upstream

### Future Consideration (v1.4+)

- [ ] Syntax highlighting in code blocks (`@tiptap/extension-code-block-lowlight`) — bundle weight cost, only if code-heavy content dominates
- [ ] Font family selection — low value for current content type, brand consistency risk
- [ ] Table column resize — upstream bug risk with ActionText

---

## Feature Prioritization Matrix

| Feature | User Value | Implementation Cost | Priority |
|---------|------------|---------------------|----------|
| Strike/Underline/Blockquote/HR/CodeBlock buttons | HIGH (baseline completeness) | LOW (toolbar UI only, 0 packages) | P1 |
| Heading dropdown (H1~H3) | HIGH | LOW (0 packages, custom select) | P1 |
| Text alignment | HIGH | LOW-MEDIUM (1 package + 3 buttons) | P1 |
| Table (insertion + row/col ops + bubble menu) | HIGH (Naver Blog standard) | HIGH (4 packages + bubble menu) | P1 |
| Text color (preset palette) | MEDIUM | MEDIUM (2 packages + swatch UI) | P1 |
| Background highlight (preset palette) | MEDIUM | LOW-MEDIUM (1 package, shares TextStyle) | P1 |
| Font size control (preset sizes) | MEDIUM | LOW-MEDIUM (1 package, shares TextStyle) | P1 |
| Block insertion floating menu (+) | MEDIUM | MEDIUM (FloatingMenu already in TipTap) | P2 |
| Slash commands (/) | LOW-MEDIUM | HIGH (experimental, maintenance burden) | P3 |

**Priority key:**
- P1: Must ship in v1.3
- P2: Ship in v1.3 if P1 complete, else v1.4
- P3: Future milestone

---

## Competitor Feature Analysis

| Feature | Naver Blog | Notion | TeoVibe v1.2 (current) | TeoVibe v1.3 target |
|---------|------------|--------|------------------------|---------------------|
| Strikethrough | Yes, toolbar | Yes, `/` menu | Extension registered, no toolbar | Toolbar button |
| Underline | Yes, toolbar | Yes, Cmd+U | Extension registered, no toolbar | Toolbar button |
| Blockquote | Yes, toolbar | Yes, `>` trigger | Extension registered, no toolbar | Toolbar button |
| Horizontal rule | Yes, toolbar | Yes, `---` | Extension registered, no toolbar | Toolbar button |
| Code block | Yes, toolbar | Yes, triple backtick | Extension registered, no toolbar | Toolbar button |
| Heading levels | H1-H3 dropdown | H1-H3 via `/` | H1-H6 configured, no dropdown UI | H1~H3 dropdown |
| Text alignment | L/C/R/Justify | L/C/R | Not available | L/C/R (no justify) |
| Table | Insert grid, resize | Click `+` corner | Not available | Insert + bubble menu for row/col ops |
| Text color | Full color picker | Limited palette | Not available | 12-color preset palette |
| Highlight | Yes | Yes | Not available | `Highlight` multicolor, preset palette |
| Font size | Preset dropdown | Limited | Not available | Preset dropdown (12/14/16/18/20/24px) |
| Block menu | Side `+` button | `/` slash commands | Not available | FloatingMenu `+` (P2) or slash (P3) |

---

## Sources

- [TipTap Extensions Overview](https://tiptap.dev/docs/editor/extensions/overview) — extension catalog, paid vs free distinction (HIGH confidence, official docs)
- [TipTap Table Extension](https://tiptap.dev/docs/editor/extensions/nodes/table) — 4-package dependency requirement, operations list (HIGH confidence, official docs)
- [TipTap Color Extension](https://tiptap.dev/docs/editor/extensions/functionality/color) — TextStyle dependency, setColor/unsetColor API (HIGH confidence, official docs)
- [TipTap FontSize Extension](https://tiptap.dev/docs/editor/extensions/functionality/fontsize) — setFontSize/unsetFontSize API, TextStyle dependency (HIGH confidence, official docs)
- [TipTap Slash Commands (experimental)](https://tiptap.dev/docs/examples/experiments/slash-commands) — no published package, must implement from source or use community lib (HIGH confidence, official docs with explicit "experimental/unmaintained" warning)
- [TipTap Slash Dropdown Menu UI Component](https://tiptap.dev/docs/ui-components/components/slash-dropdown-menu) — paid (Start plan), not free (HIGH confidence, official pricing page)
- [TipTap Heading Dropdown Menu UI Component](https://tiptap.dev/docs/ui-components/components/heading-dropdown-menu) — paid (Start plan) (HIGH confidence, official)
- [rhino-editor GitHub](https://github.com/KonnorRogers/rhino-editor) — v0.18.2 latest, 0.17.3 in use (HIGH confidence, official repo)
- [rhino-editor Setup Docs](https://rhino-editor.vercel.app/tutorials/setup/) — extension injection API via class extension (HIGH confidence, official)
- rhino-editor 0.17.3 source `rhino-starter-kit.d.ts` (local, path: `teovibe/node_modules/.pnpm/rhino-editor@0.17.3_.../rhino-starter-kit.d.ts`) — direct source inspection of which extensions are pre-registered (HIGH confidence)
- [TipTap table resizable bug #2041](https://github.com/ueberdosis/tiptap/issues/2041) — column widths lost when editor not editable (HIGH confidence, official issue tracker)
- [TextStyleKit documentation](https://tiptap.dev/docs/editor/extensions/functionality/text-style-kit) — shared dependency pattern for Color + FontSize + FontFamily (HIGH confidence, official docs)

---
*Feature research for: TeoVibe v1.3 Admin Editor Enhancement (TipTap rich editor features)*
*Researched: 2026-03-14*
