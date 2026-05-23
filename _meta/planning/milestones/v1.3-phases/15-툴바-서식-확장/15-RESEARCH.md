# Phase 15: 툴바 서식 확장 - Research

**Researched:** 2026-03-14
**Domain:** rhino-editor 0.17.3 toolbar 확장 (TipTap 2.27.2 기반) — 취소선/밑줄/인용구/구분선/코드블록/제목 드롭다운
**Confidence:** HIGH

---

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|-----------------|
| MARK-01 | 취소선(Strike) 툴바 버튼 추가 (이미 등록된 extension 활용) | `rhinoStrike`(CustomStrike) 는 RhinoStarterKit 기본값으로 이미 등록됨. `renderStrikeButton()` 도 TipTapEditor 에 구현되어 있음. 툴바에 이미 렌더링 중 — 버튼이 보이지 않는다면 starterKitOptions 재확인만 필요 |
| MARK-02 | 밑줄(Underline) extension 설치 + 툴바 버튼 | `@tiptap/extension-underline` 이 pnpm 스토어에 없음 — `pnpm add @tiptap/extension-underline` 필요. AdminRhinoEditor.extensions 에 추가 + renderToolbar() 오버라이드로 custom 버튼 추가 |
| MARK-03 | 인용구(Blockquote) 툴바 버튼 추가 | `blockquote` 는 StarterKit 에 포함, `renderBlockquoteButton()` 이 TipTapEditor 에 구현됨. 툴바에 이미 렌더링 중 — 추가 작업 불필요 |
| MARK-04 | 구분선(Horizontal Rule) 툴바 버튼 추가 | `horizontalRule` 은 StarterKit 에 포함(`setHorizontalRule` 커맨드 존재), 그러나 rhino-editor 에 `renderHorizontalRuleButton()` 이 없음 — renderToolbar() 오버라이드 + custom 버튼 필요 |
| MARK-05 | 소스코드 블록(Code Block) 툴바 버튼 추가 | `codeBlock` 은 StarterKit 에 포함, `renderCodeBlockButton()` 이 TipTapEditor 에 구현됨. 툴바에 이미 렌더링 중 — 추가 작업 불필요 |
| MARK-06 | 제목 레벨 드롭다운 (H1~H3 선택) | `renderHeadingButton()` 은 단일 레벨 토글 버튼만 구현 — H1/H2/H3 드롭다운은 renderToolbar() 오버라이드 필요. HTML `<select>` 또는 custom dropdown 으로 구현 |
</phase_requirements>

---

## Summary

Phase 15 의 핵심 발견은 **기존 rhino-editor 0.17.3 이 이미 Strike/Blockquote/CodeBlock 툴바 버튼을 렌더링하고 있다**는 점이다. MARK-01, MARK-03, MARK-05 는 새 코드를 거의 쓰지 않아도 된다. 문제가 보인다면 `starterKitOptions` 재확인이 전부다.

실질적인 구현 작업은 세 가지다: (1) `@tiptap/extension-underline` 설치 + custom 버튼(MARK-02), (2) HorizontalRule custom 버튼(MARK-04 — extension 은 이미 있지만 rhino-editor 에 render 메서드 없음), (3) Heading 드롭다운 — `renderHeadingButton()` 은 단일 레벨 토글 전용이므로 H1/H2/H3 `<select>` 드롭다운을 `renderToolbar()` 오버라이드로 구현.

AdminRhinoEditor 에서 `renderToolbar()` 를 override 하는 방식이 **모든 custom 버튼의 공통 패턴**이다. `toolbar-end` slot 에 Light DOM 엘리먼트를 주입하는 방식도 가능하지만, `renderToolbar()` 오버라이드가 타입 안전성과 Lit 렌더링 사이클 통합면에서 더 안정적이다.

**Primary recommendation:** AdminRhinoEditor 에 `renderToolbar()` 를 override 하여 기존 버튼들을 super 로 포함하고, Underline/HorizontalRule/Heading 드롭다운 버튼을 추가한다. `@tiptap/extension-underline` 만 신규 설치한다.

---

## Standard Stack

### Core (Phase 14에서 이미 사용)

| 라이브러리 | 버전 | 목적 | 상태 |
|------------|------|------|------|
| `rhino-editor` | 0.17.3 | TipTapEditor 서브클래스 베이스 | 설치됨 |
| `@tiptap/core` | 2.27.2 | TipTap 에디터 코어 | rhino-editor 의존성으로 설치됨 |
| `@tiptap/starter-kit` | 2.27.2 | Blockquote, CodeBlock, HorizontalRule, Heading, Strike 포함 | 설치됨 |
| `@tiptap/extension-strike` | 2.27.2 | CustomStrike(`<del>`) 베이스 | 설치됨 |
| `@tiptap/extension-horizontal-rule` | 2.27.2 | `setHorizontalRule` 커맨드 | 설치됨 |
| `@tiptap/extension-heading` | 2.27.2 | `toggleHeading({ level })` 커맨드 | 설치됨 |
| `@tiptap/extension-blockquote` | 2.27.2 | `toggleBlockquote` 커맨드 | 설치됨 |
| `@tiptap/extension-code-block` | 2.27.2 | `toggleCodeBlock` 커맨드 | 설치됨 |

### 신규 설치 필요 (Phase 15)

| 라이브러리 | 버전 | 목적 | 이유 |
|------------|------|------|------|
| `@tiptap/extension-underline` | ^2.27.2 | `toggleUnderline` 커맨드 + `<u>` 태그 렌더링 | rhino-editor 의존성에 없음, pnpm 스토어 미존재 확인 |

**Installation:**
```bash
cd teovibe && pnpm add @tiptap/extension-underline
```

### 이미 있어서 설치 불필요

- Blockquote, CodeBlock, HorizontalRule, Heading, Strike — 전부 `@tiptap/starter-kit` 에 포함, 이미 설치됨
- `@tiptap/extension-underline` 외 신규 패키지 없음

---

## Architecture Patterns

### 파일 변경 목록

```
teovibe/
├── app/frontend/editor/
│   └── admin_rhino_editor.js   # [수정] renderToolbar() 오버라이드 + Underline extension 추가
├── app/frontend/editor/
│   └── admin_rhino_editor.css  # [신규, 선택] 드롭다운 스타일 (필요 시)
└── package.json / pnpm-lock.yaml  # [수정] @tiptap/extension-underline 추가
```

### Pattern 1: AdminRhinoEditor 에서 extension 추가

**What:** 생성자 또는 `connectedCallback` 에서 `this.addExtensions()` 호출로 새 extension 을 등록한다.

**API 확인 (HIGH):** `tip-tap-editor-base.d.ts` 에 `addExtensions(...extensions)` 메서드 존재 확인. 구현: 기존 extension 이름과 중복되지 않는 것만 필터링 후 `this.extensions` 에 concat.

```javascript
// app/frontend/editor/admin_rhino_editor.js
// Source: teovibe/node_modules/rhino-editor/exports/chunks/chunk-2NB236ZC.js L484
import { TipTapEditor } from "rhino-editor/exports/elements/tip-tap-editor.js"
import Underline from "@tiptap/extension-underline"
import { html } from "lit"

export class AdminRhinoEditor extends TipTapEditor {
  connectedCallback() {
    super.connectedCallback()
    // Underline extension 추가 — StarterKit/RhinoStarterKit 에 없는 extension 만 가능
    this.addExtensions(Underline)
  }
}

AdminRhinoEditor.define("admin-rhino-editor")
```

### Pattern 2: renderToolbar() override — custom 버튼 추가

**What:** `TipTapEditor` 의 `renderToolbar()` 를 서브클래스에서 override 하여 새 버튼을 추가한다.

**When to use:** rhino-editor 에 render 메서드가 없는 버튼(HorizontalRule, Underline, 제목 드롭다운)을 추가할 때.

**전략 A — toolbar-end 슬롯 활용 (Light DOM injection):**
Admin 폼 ERB 에서 `<admin-rhino-editor>` 안에 `slot="toolbar-end"` 를 가진 엘리먼트를 추가한다.

```erb
<%# app/views/admin/posts/_form.html.erb %>
<admin-rhino-editor
  input="<%= f.field_id(:body) %>"
  data-blob-url-template="<%= rails_service_blob_url(":signed_id", ":filename") %>"
  data-direct-upload-url="<%= rails_direct_uploads_url %>"
  class="w-full min-h-[400px] rounded-2xl border border-gray-300"
>
  <%# toolbar-end 슬롯: rhino-editor 가 Shadow DOM 에서 이 콘텐츠를 toolbar 끝에 주입 %>
  <div slot="toolbar-end">
    <button type="button" id="underline-btn">U</button>
    <button type="button" id="hr-btn">HR</button>
    <select id="heading-select">
      <option value="0">단락</option>
      <option value="1">H1</option>
      <option value="2">H2</option>
      <option value="3">H3</option>
    </select>
  </div>
</admin-rhino-editor>
```

**전략 B — renderToolbar() override (권장):**
AdminRhinoEditor 클래스에서 `renderToolbar()` 를 override 하여 Lit TemplateResult 로 커스텀 버튼을 포함한다.

```javascript
// Source: tip-tap-editor.d.ts - renderToolbar(): TemplateResult<1>
// Source: tip-tap-editor-base.d.ts - renderToolbar(): TemplateResult<1>
import { TipTapEditor } from "rhino-editor/exports/elements/tip-tap-editor.js"
import Underline from "@tiptap/extension-underline"
import { html } from "lit"

export class AdminRhinoEditor extends TipTapEditor {
  connectedCallback() {
    super.connectedCallback()
    this.addExtensions(Underline)
  }

  // 제목 드롭다운 렌더링 (H1/H2/H3)
  renderHeadingDropdown() {
    const isH1 = Boolean(this.editor?.isActive("heading", { level: 1 }))
    const isH2 = Boolean(this.editor?.isActive("heading", { level: 2 }))
    const isH3 = Boolean(this.editor?.isActive("heading", { level: 3 }))

    let currentValue = "0"
    if (isH1) currentValue = "1"
    else if (isH2) currentValue = "2"
    else if (isH3) currentValue = "3"

    return html`
      <select
        class="toolbar__button rhino-toolbar-button"
        aria-label="제목 레벨"
        data-role="toolbar-item"
        .value=${currentValue}
        @change=${(e) => {
          const level = parseInt(e.target.value)
          if (level === 0) {
            this.editor?.chain().focus().setParagraph().run()
          } else {
            this.editor?.chain().focus().toggleHeading({ level }).run()
          }
        }}
      >
        <option value="0">단락</option>
        <option value="1">H1</option>
        <option value="2">H2</option>
        <option value="3">H3</option>
      </select>
    `
  }

  // 구분선 버튼 렌더링
  renderHorizontalRuleButton() {
    const isDisabled = this.editor == null || !this.editor.can().setHorizontalRule()
    return html`
      <button
        class="toolbar__button rhino-toolbar-button"
        type="button"
        tabindex="-1"
        part="toolbar__button toolbar__button--horizontal-rule"
        aria-disabled=${isDisabled}
        aria-label="구분선"
        data-role="toolbar-item"
        title="구분선"
        @click=${(e) => {
          if (isDisabled) return
          this.editor?.chain().focus().setHorizontalRule().run()
        }}
      >
        —
      </button>
    `
  }

  // 밑줄 버튼 렌더링
  renderUnderlineButton() {
    const isActive = Boolean(this.editor?.isActive("underline"))
    const isDisabled = this.editor == null || !this.editor.can().toggleUnderline()
    return html`
      <button
        class="toolbar__button rhino-toolbar-button"
        type="button"
        tabindex="-1"
        part="toolbar__button toolbar__button--underline ${isActive ? 'toolbar__button--active' : ''}"
        aria-disabled=${isDisabled}
        aria-pressed=${isActive}
        aria-label="밑줄"
        data-role="toolbar-item"
        title="밑줄"
        @click=${(e) => {
          if (isDisabled) return
          this.editor?.chain().focus().toggleUnderline().run()
        }}
      >
        <u>U</u>
      </button>
    `
  }

  // 전체 toolbar override — 기존 버튼 유지 + 새 버튼 추가
  renderToolbar() {
    // super.renderToolbar() 를 직접 활용하면 Shadow DOM 구조 재사용 가능
    // 단, Lit 의 TemplateResult 는 합성이 어려우므로 toolbar-end slot 이 더 간단할 수 있음
    // 권장: super.renderToolbar() 결과를 그대로 사용하고 slot 주입으로 추가 버튼 배치
    return html`
      ${super.renderToolbar()}
    `
    // toolbar-end 슬롯이 shadow DOM 내에서 렌더링되므로
    // 추가 버튼은 renderToolbarEnd() 오버라이드로 삽입
  }

  renderToolbarEnd() {
    return html`
      ${this.renderHeadingDropdown()}
      ${this.renderHorizontalRuleButton()}
      ${this.renderUnderlineButton()}
    `
  }
}

AdminRhinoEditor.define("admin-rhino-editor")
```

**권장 최종 패턴: `renderToolbarEnd()` override**

`renderToolbar()` 전체를 override 하는 대신 `renderToolbarEnd()` 를 override 하면 기존 toolbar 구조를 건드리지 않고 새 버튼을 `toolbar-end` slot 앞에 삽입할 수 있다.

- `renderToolbarEnd()` 는 `TipTapEditor` 에 정의됨 (d.ts 에서 확인): 기본값 빈 TemplateResult
- `renderStrikeButton()`, `renderBlockquoteButton()`, `renderCodeBlockButton()`, `renderHeadingButton()` 은 기존 toolbar 에 이미 포함 — **override 불필요**
- 추가가 필요한 것만: Underline, HorizontalRule, Heading 드롭다운

### Pattern 3: Heading 드롭다운 — reactive 상태 관리

**문제:** Lit 기반 Web Component 에서 editor selection 이 바뀔 때 드롭다운 값이 자동 업데이트되어야 한다.

**해결:** rhino-editor 는 TipTap 의 `onSelectionUpdate` / `onTransaction` 이벤트 시 `requestUpdate()` 를 호출한다. AdminRhinoEditor 가 `TipTapEditor` 를 상속하므로 이 메커니즘이 자동 적용된다. `this.editor?.isActive()` 는 매 render cycle 에 재평가된다.

**검증:** `this.editor?.isActive("heading", { level: 1 })` 는 TipTap Editor instance 의 메서드이며, `@tiptap/core` 타입에서 확인됨.

### Anti-Patterns to Avoid

- **`renderToolbar()` 전체 재작성:** 기존 Bold/Italic/Strike/Link 등 모든 버튼 코드를 복사해야 함. 관리 비용 폭발. `renderToolbarEnd()` override 만으로 충분.
- **`this.extensions.push()` 직접 수정:** `addExtensions()` 메서드를 통해 중복 필터링이 자동 처리됨. 직접 push 시 중복 등록 오류 발생.
- **`@tiptap/extension-strike` 직접 등록:** rhino-editor 가 `strike: false` (StarterKit 기본 Strike 비활성화) + `rhinoStrike` (CustomStrike, `<del>` 태그) 패턴을 사용. `@tiptap/extension-strike` 를 직접 추가하면 두 Strike 가 충돌.

---

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Strike 기능 | Custom strike mark | `rhinoStrike` (이미 등록됨) | RhinoStarterKit 기본값, `<del>` 태그로 ActionText 호환 |
| Blockquote 기능 | Custom blockquote mark | StarterKit `blockquote` (이미 등록됨) | StarterKit 기본 포함 |
| CodeBlock 기능 | Custom code block node | StarterKit `codeBlock` (이미 등록됨) | StarterKit 기본 포함 |
| Underline HTML 파싱/렌더링 | `Mark.create({ name: 'underline' })` 직접 구현 | `@tiptap/extension-underline` | 키보드 단축키, HTML 파싱, 렌더링 모두 처리됨 |
| HorizontalRule 삽입 로직 | ProseMirror transaction 직접 구현 | StarterKit `setHorizontalRule()` (이미 등록됨) | 단락 분할 처리까지 내장 |
| Heading 상태 추적 | 직접 ProseMirror selection 검사 | `this.editor.isActive("heading", { level: N })` | TipTap Editor API |

---

## Common Pitfalls

### Pitfall 1: Strike 버튼이 비활성화되어 보이는 경우

**What goes wrong:** 툴바에 Strike 버튼이 렌더링되지만 클릭해도 동작 안 함.

**Why it happens:** `rhinoStrike !== false` 조건은 통과하지만, `this.editor?.can().toggleStrike()` 가 false 를 반환. `rhinoStrike` 의 extension 이름이 `"rhino-strike"` 이므로 `editor.isActive("rhino-strike")` 로 확인.

**How to avoid:** 브라우저 콘솔에서 `document.querySelector("admin-rhino-editor").editor.commands.toggleStrike()` 실행 시 true 반환 확인.

**Warning signs:** 버튼이 `aria-disabled="true"` 상태.

### Pitfall 2: Underline 이 ActionText 렌더링 시 제거됨

**What goes wrong:** 에디터에서 밑줄이 보이지만 저장 후 상세 페이지에서 `<u>` 태그가 사라짐.

**Why it happens:** ActionText sanitizer 가 `<u>` 태그를 기본 허용목록에서 제외한다.

**How to avoid:** Phase 14 에서 구축한 `config/initializers/action_text.rb` 에 `"u"` 태그를 추가해야 한다.

**필수 추가:**
```ruby
# config/initializers/action_text.rb 에 추가
ActionText::ContentHelper.allowed_tags += %w[u]
```

**Warning signs:** 에디터에서는 밑줄 보임 — 저장 후 상세 페이지에서 사라짐.

### Pitfall 3: Heading 드롭다운 reactive 업데이트 미동작

**What goes wrong:** 에디터에서 커서를 H2 블록으로 이동해도 드롭다운이 "단락" 상태 유지.

**Why it happens:** Lit 의 property change detection 이 `this.editor` object reference 변경을 감지하지 못함. `onSelectionUpdate` 이벤트 핸들러가 `requestUpdate()` 를 호출해야 함.

**How to avoid:** rhino-editor 가 이미 `onSelectionUpdate`, `onTransaction` 에서 `requestUpdate()` 를 호출하므로, `renderToolbarEnd()` 안의 `this.editor?.isActive()` 가 자동으로 최신 상태를 반영한다. 별도 이벤트 핸들러 불필요.

**Warning signs:** 드롭다운 선택값이 커서 이동 후에도 이전 값 표시.

### Pitfall 4: `pnpm add @tiptap/extension-underline` 버전 미일치

**What goes wrong:** `@tiptap/extension-underline` 설치 시 최신 버전(v3.x)이 설치되어 rhino-editor 의 TipTap v2 환경과 충돌.

**Why it happens:** pnpm 이 최신 semver 를 설치하는데, `@tiptap/extension-underline` v3 는 TipTap v3 기반.

**How to avoid:** 버전 핀: `pnpm add @tiptap/extension-underline@^2.27.2`. 기존 `@tiptap/core@2.27.2` 와 동일 버전 범위로 맞춤.

**Warning signs:** `pnpm install` 후 `node_modules/.pnpm` 에 `@tiptap+extension-underline@3.x.x` 가 설치됨.

### Pitfall 5: HorizontalRule 삽입 후 커서 위치 문제

**What goes wrong:** `setHorizontalRule()` 실행 후 커서가 HR 위로 올라가거나 에디터 포커스를 잃음.

**Why it happens:** `chain().focus().setHorizontalRule().run()` 에서 `.focus()` 를 생략하면 포커스 이동 안 됨.

**How to avoid:** 항상 `.chain().focus().setHorizontalRule().run()` 패턴 사용.

---

## Code Examples

### MARK-01: Strike 버튼 동작 확인 (신규 코드 없음)

```javascript
// 브라우저 콘솔에서 확인
const el = document.querySelector("admin-rhino-editor")
// rhinoStrike 는 기본 등록 — 커맨드 존재 확인
el.editor.commands.toggleStrike  // function 이어야 함
el.editor.can().toggleStrike()   // true 이어야 함
el.starterKitOptions.rhinoStrike // undefined (false 가 아님 = 활성화됨)
```

### MARK-02: Underline extension 등록

```javascript
// Source: @tiptap/extension-underline 패키지 공식 API (HIGH — TipTap 2.x docs)
import { TipTapEditor } from "rhino-editor/exports/elements/tip-tap-editor.js"
import Underline from "@tiptap/extension-underline"
import { html } from "lit"

export class AdminRhinoEditor extends TipTapEditor {
  connectedCallback() {
    super.connectedCallback()
    this.addExtensions(Underline)
  }
}
```

### MARK-04: HorizontalRule 커맨드 (이미 등록됨)

```javascript
// @tiptap/extension-horizontal-rule 의 setHorizontalRule 커맨드
// Source: teovibe/node_modules/.pnpm/@tiptap+extension-horizontal-rule@2.27.2 직접 확인 (HIGH)
this.editor?.chain().focus().setHorizontalRule().run()
```

### MARK-06: Heading 드롭다운 상태 읽기

```javascript
// Source: @tiptap/core - Editor.isActive() API (HIGH)
this.editor?.isActive("heading", { level: 1 })  // H1 활성화 여부
this.editor?.isActive("heading", { level: 2 })  // H2 활성화 여부
this.editor?.isActive("heading", { level: 3 })  // H3 활성화 여부

// H1 토글
this.editor?.chain().focus().toggleHeading({ level: 1 }).run()
// 단락으로 변환
this.editor?.chain().focus().setParagraph().run()
```

### ActionText 허용목록 — Underline `<u>` 태그 추가

```ruby
# config/initializers/action_text.rb 에 기존 코드에 추가
# Phase 14 에서 생성된 파일에 <u> 태그 추가
ActionText::ContentHelper.allowed_tags += %w[u]
```

### renderToolbarEnd() override — 전체 구현

```javascript
// Source: TipTapEditor.renderToolbarEnd() 빈 기본값 확인 (d.ts 직접 확인, HIGH)
// 이 메서드만 override 하면 기존 toolbar 구조를 그대로 유지
renderToolbarEnd() {
  return html`
    ${this.renderHeadingDropdown()}
    ${this.renderHorizontalRuleButton()}
    ${this.renderUnderlineButton()}
  `
}
```

---

## 현재 Toolbar 기본 렌더링 상태 분석

rhino-editor 0.17.3 기본 툴바에 **이미 포함된 버튼**:

| 버튼 | 렌더 메서드 | Extension | 기본 표시 여부 |
|------|------------|-----------|--------------|
| Bold | `renderBoldButton()` | StarterKit.bold | O (기본) |
| Italic | `renderItalicButton()` | StarterKit.italic | O (기본) |
| **Strike** | `renderStrikeButton()` | RhinoStarterKit.rhinoStrike | **O (기본)** |
| Link | `renderLinkButton()` | RhinoStarterKit.rhinoLink | O (기본) |
| **Heading (단일)** | `renderHeadingButton()` | StarterKit.heading | **O — 단일 레벨 토글** |
| **Blockquote** | `renderBlockquoteButton()` | StarterKit.blockquote | **O (기본)** |
| **CodeBlock** | `renderCodeBlockButton()` | StarterKit.codeBlock | **O (기본)** |
| BulletList | `renderBulletListButton()` | StarterKit.bulletList | O (기본) |
| OrderedList | `renderOrderedListButton()` | StarterKit.orderedList | O (기본) |
| Attachment | `renderAttachmentButton()` | RhinoStarterKit.rhinoAttachment | O (기본) |
| Undo/Redo | `renderUndoButton()` / `renderRedoButton()` | StarterKit.history | O (기본) |

**기본 toolbar 에 없는 버튼 (신규 구현 필요):**

| 버튼 | Requirement | Extension | 필요 작업 |
|------|------------|-----------|---------|
| Underline | MARK-02 | `@tiptap/extension-underline` (미설치) | 패키지 설치 + renderUnderlineButton() + actionText 허용목록 |
| HorizontalRule | MARK-04 | StarterKit.horizontalRule (설치됨) | renderHorizontalRuleButton() 만 필요 |
| Heading 드롭다운 | MARK-06 | StarterKit.heading (설치됨) | 기존 단일 토글 버튼 대체 or 드롭다운 추가 |

**이미 동작 중이어서 코드 추가 없는 버튼:**

| Requirement | 상태 |
|-------------|------|
| MARK-01 (Strike) | 이미 toolbar 에 렌더링 중 |
| MARK-03 (Blockquote) | 이미 toolbar 에 렌더링 중 |
| MARK-05 (CodeBlock) | 이미 toolbar 에 렌더링 중 |

---

## State of the Art

| Old Approach | Current Approach | Notes |
|--------------|------------------|-------|
| `customElements.define()` 직접 호출 | `AdminRhinoEditor.define("admin-rhino-editor")` | Phase 14에서 확립된 패턴 |
| `renderToolbar()` 전체 재작성 | `renderToolbarEnd()` override | 관리 코드 최소화 |
| 별도 toolbar HTML | rhino-editor 내장 toolbar 재사용 | 일관성, 유지보수성 |
| Light DOM slot injection | `renderToolbarEnd()` Lit override | 타입 안전성, Lit lifecycle 통합 |

**Deprecated/outdated:**
- `@tiptap/extension-font-size` npm 패키지: v2에 존재하지 않음 (STATE.md 결정사항) — Phase 15 범위 외

---

## Open Questions

1. **Heading 드롭다운 vs 기존 Heading 단일 버튼 공존 여부**
   - What we know: `renderHeadingButton()` 은 `defaultHeadingLevel` 속성으로 하나의 레벨만 토글. 기본값 H1.
   - What's unclear: 기존 단일 버튼을 유지하면서 드롭다운도 추가할지, 드롭다운으로 완전 교체할지
   - Recommendation: `renderToolbarEnd()` 에 드롭다운만 추가하고 기존 버튼은 유지. MARK-06 요구사항 "H1/H2/H3 선택"을 충족하면서 기존 단일 버튼도 H1 빠른 접근으로 활용.

2. **`renderToolbarEnd()` 위치 — Underline/HorizontalRule 순서**
   - What we know: `toolbar-end` 슬롯 앞 버튼 순서는 전통적으로 중요도 순
   - Recommendation: 제목 드롭다운 → 구분선 → 밑줄 순서 (의미 유사 그룹핑)

---

## Validation Architecture

### Test Framework

| Property | Value |
|----------|-------|
| Framework | 없음 (테스트 인프라 미구축, Phase 14와 동일) |
| Config file | none |
| Quick run command | `cd teovibe && bin/rails runner "puts ActionText::ContentHelper.allowed_tags.include?('u')"` |
| Full suite command | `bin/rails test` (기본 Rails 테스트) |

### Phase Requirements → Test Map

| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|--------------|
| MARK-01 | Strike 버튼 클릭 시 선택 텍스트에 `<del>` 태그 적용됨 | manual | Admin 폼 페이지에서 텍스트 선택 → Strike 버튼 클릭 → `<del>` 렌더링 확인 | N/A (manual) |
| MARK-02 | Underline 버튼 클릭 시 선택 텍스트에 `<u>` 태그 적용, 저장 후 상세 페이지에서 유지 | manual | 위와 동일 + 저장 후 상세 페이지 확인 | N/A (manual) |
| MARK-03 | Blockquote 버튼 클릭 시 블록이 `<blockquote>` 로 변환됨 | manual | 버튼 클릭 + HTML 소스 확인 | N/A (manual) |
| MARK-04 | HorizontalRule 버튼 클릭 시 `<hr>` 태그 삽입됨 | manual | 버튼 클릭 + 에디터 HTML 확인 | N/A (manual) |
| MARK-05 | CodeBlock 버튼 클릭 시 블록이 `<pre><code>` 로 변환됨 | manual | 버튼 클릭 + HTML 소스 확인 | N/A (manual) |
| MARK-06 | 제목 드롭다운에서 H2 선택 시 커서 블록이 `<h2>` 로 변환됨 | manual | 드롭다운 선택 + HTML 소스 확인 | N/A (manual) |

### Sampling Rate

- **Per task commit:** `cd teovibe && bin/rails runner "puts ActionText::ContentHelper.allowed_tags.include?('u')"` (true 확인)
- **Per wave merge:** Admin 폼에서 각 버튼 동작 수동 확인 + 저장 후 상세 페이지 렌더링 확인
- **Phase gate:** 모든 success criteria 수동 확인 후 Phase 16 진입

### Wave 0 Gaps

- [ ] `teovibe/app/frontend/editor/admin_rhino_editor.js` — MARK-02 Underline extension + MARK-04/06 custom 버튼 구현 (기존 파일 수정)
- [ ] `teovibe/config/initializers/action_text.rb` — `<u>` 태그 허용목록 추가 (MARK-02)
- [ ] `pnpm add @tiptap/extension-underline@^2.27.2` — MARK-02 패키지 설치

---

## Sources

### Primary (HIGH confidence)

- `teovibe/node_modules/rhino-editor/exports/elements/tip-tap-editor.d.ts` — 툴바 render 메서드 전체 목록 (`renderStrikeButton`, `renderBlockquoteButton`, `renderCodeBlockButton`, `renderHeadingButton`, `renderToolbarEnd` 등) 직접 확인
- `teovibe/node_modules/rhino-editor/exports/elements/tip-tap-editor-base.d.ts` — `addExtensions()`, `extensions`, `starterKitOptions` API 직접 확인
- `teovibe/node_modules/rhino-editor/exports/chunks/chunk-JV22V53Y.js` — 전체 toolbar 렌더링 HTML + 각 버튼 enable 조건 소스 직접 확인
- `teovibe/node_modules/rhino-editor/exports/chunks/chunk-2NB236ZC.js` — `addExtensions()` 구현, 기본 `starterKitOptions = { strike: false }` 확인
- `teovibe/node_modules/rhino-editor/exports/chunks/chunk-7E7MURG2.js` — RhinoStarterKit `addExtensions()` — `rhinoStrike: CustomStrike` 기본 등록 확인
- `teovibe/node_modules/rhino-editor/exports/chunks/chunk-M36FQDQD.js` — CustomStrike(`rhino-strike`, `<del>` 태그) 구현 확인
- `teovibe/node_modules/.pnpm/@tiptap+starter-kit@2.27.2/node_modules/@tiptap/starter-kit/dist/starter-kit.d.ts` — StarterKit 포함 extension 목록 (blockquote, codeBlock, horizontalRule, heading, strike 등) 직접 확인
- `teovibe/node_modules/.pnpm/@tiptap+extension-horizontal-rule@2.27.2_.../dist/horizontal-rule.d.ts` — `setHorizontalRule()` 커맨드 존재 직접 확인
- `teovibe/node_modules/.pnpm/@tiptap+starter-kit@2.27.2` 디렉토리 존재 확인 — `@tiptap/extension-underline` 미존재 확인 (pnpm store 검색)
- `teovibe/app/frontend/editor/admin_rhino_editor.js` — Phase 14 스캐폴드 현재 상태 확인

### Secondary (MEDIUM confidence)

- Phase 14 Research (`14-RESEARCH.md`) — `rhinoStrike` 커맨드명 블로커 언급 (STATE.md 교차 확인)
- Phase 14 Summary (`14-01-SUMMARY.md`) — `AdminRhinoEditor.define()` 패턴, `editorOptions()` 오버라이드 포인트 확인

---

## Metadata

**Confidence breakdown:**
- MARK-01 (Strike 이미 동작): HIGH — 소스 직접 확인
- MARK-02 (Underline 패키지 설치): HIGH — pnpm store 미존재 확인, @tiptap/extension-underline API 공식
- MARK-03 (Blockquote 이미 동작): HIGH — renderBlockquoteButton() 소스 확인
- MARK-04 (HorizontalRule 커스텀 버튼): HIGH — setHorizontalRule() API 확인, render 메서드 없음 확인
- MARK-05 (CodeBlock 이미 동작): HIGH — renderCodeBlockButton() 소스 확인
- MARK-06 (Heading 드롭다운): HIGH — renderHeadingButton() 단일 레벨 한계 확인, isActive() API 확인

**Research date:** 2026-03-14
**Valid until:** 2026-04-14 (rhino-editor 0.17.x 안정 — 빠른 변화 없음)
