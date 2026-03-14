# Phase 16: 텍스트 스타일링 - Research

**Researched:** 2026-03-14
**Domain:** TipTap 2.27.2 텍스트 스타일링 extensions (TextAlign, Color, Highlight, 커스텀 FontSize) — rhino-editor 0.17.3 + AdminRhinoEditor 패턴
**Confidence:** HIGH

---

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|-----------------|
| STYL-01 | 텍스트 정렬(좌/중/우) extension + 툴바 버튼 | `@tiptap/extension-text-align@2.27.2` 존재 확인. 출력 HTML `<p style="text-align: center">`. ActionText style 속성 이미 허용됨(Phase 14). renderToolbarEnd() 패턴으로 추가 |
| STYL-02 | 글자색(Color) extension + 색상 선택 UI | `@tiptap/extension-color@2.27.2` 존재 확인. `@tiptap/extension-text-style` 직접 설치 필요(pnpm virtual store에만 있음). 출력 `<span style="color: #hex">`. style + span 이미 허용됨 |
| STYL-03 | 배경색(Highlight) extension + 색상 선택 UI | `@tiptap/extension-highlight@2.27.2` 존재 확인. `multicolor: true` 옵션으로 색상 선택 가능. 출력 `<mark style="background-color: #hex">`. mark + style 이미 허용됨 |
| STYL-04 | 폰트 크기 커스텀 extension + 드롭다운 UI | `@tiptap/extension-font-size`는 v3.x 전용 — v2.27.2 없음. TextStyle 기반 로컬 커스텀 extension 필요(gregveres/64ec1d8a 패턴 검증됨). 출력 `<span style="font-size: 16px">` |
</phase_requirements>

---

## Summary

Phase 16은 Admin 에디터에 네 가지 텍스트 스타일링 기능을 추가한다: 정렬(TextAlign), 글자색(Color), 배경 하이라이트(Highlight), 폰트 크기(커스텀 FontSize). 모든 기능은 Phase 14에서 구축한 인프라(`style` 속성 허용, `AdminRhinoEditor` 서브클래스) 위에서 동작하며, Phase 15에서 확립한 `renderToolbarEnd()` override 패턴을 그대로 따른다.

핵심 발견은 **ActionText 허용목록 변경이 불필요하다**는 점이다. Phase 14에서 `style` 속성과 `span`, `mark` 태그를 이미 허용했다. 네 가지 extension이 출력하는 HTML(`<p style="text-align:…">`, `<span style="color:…">`, `<mark style="background-color:…">`, `<span style="font-size:…">`)은 전부 기존 허용목록으로 커버된다.

설치가 필요한 npm 패키지는 세 가지다: `@tiptap/extension-text-align@^2.27.2`, `@tiptap/extension-color@^2.27.2`, `@tiptap/extension-highlight@^2.27.2`. `@tiptap/extension-text-style`은 `@tiptap/extension-color`의 peer dependency이며 pnpm virtual store에만 있어 Vite가 직접 import할 수 없으므로 함께 설치해야 한다. `@tiptap/extension-font-size`는 v3.x 전용으로 v2.27.2에 존재하지 않으므로 `Extension.create()`로 로컬 파일에 직접 구현한다.

**Primary recommendation:** `pnpm add @tiptap/extension-text-align@^2.27.2 @tiptap/extension-color@^2.27.2 @tiptap/extension-highlight@^2.27.2 @tiptap/extension-text-style@^2.27.2` 후, `admin_rhino_editor.js`에 extension 등록 + renderToolbarEnd() 확장, 색상 팔레트/드롭다운 UI를 Lit html 템플릿으로 구현한다.

---

## Standard Stack

### Core (이미 설치됨)

| 라이브러리 | 버전 | 목적 | 상태 |
|------------|------|------|------|
| `rhino-editor` | 0.17.3 | TipTapEditor 서브클래스 베이스 | 설치됨 |
| `@tiptap/core` | 2.27.2 | TipTap 코어 (Extension.create 포함) | 설치됨 |
| `@tiptap/starter-kit` | 2.27.2 | 기존 extension 묶음 | 설치됨 |
| `lit` | 3.3.2 | Lit html 태그 템플릿 (Phase 15에서 직접 설치) | 설치됨 |
| `@tiptap/extension-underline` | 2.27.2 | Phase 15에서 설치됨 | 설치됨 |

### 신규 설치 필요 (Phase 16)

| 라이브러리 | 버전 | 목적 | 이유 |
|------------|------|------|------|
| `@tiptap/extension-text-align` | ^2.27.2 | setTextAlign/unsetTextAlign 커맨드, 단락/제목 정렬 | STYL-01 |
| `@tiptap/extension-color` | ^2.27.2 | setColor/unsetColor 커맨드, `<span style="color:…">` | STYL-02. peerDep: @tiptap/extension-text-style |
| `@tiptap/extension-highlight` | ^2.27.2 | setHighlight/unsetHighlight/toggleHighlight 커맨드, `<mark>` | STYL-03 |
| `@tiptap/extension-text-style` | ^2.27.2 | TextStyle Mark (span 렌더러), Color/FontSize의 토대 | STYL-02/04 peerDep. pnpm virtual store에만 있어 Vite 직접 import 불가 |

### 신규 설치 불필요 (로컬 구현)

| 기능 | 이유 | 구현 방법 |
|------|------|---------|
| FontSize extension | `@tiptap/extension-font-size`는 v3.x 전용 (v2.27.2 없음 확인됨) | `Extension.create()` 로컬 파일 (`app/frontend/editor/font_size_extension.js`) |

### Alternatives Considered

| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| 로컬 FontSize Extension | `tiptap-extension-font-size` (3rd party) | 버전 고정/보안 관리 부담. Extension.create() 30줄로 동일 기능 구현 가능 — 직접 구현이 낫다 |
| Highlight multicolor | 단일 기본 노란색 highlight | 색상 선택이 STYL-03 요구사항 — multicolor: true 필수 |

**Installation:**
```bash
cd teovibe && pnpm add @tiptap/extension-text-align@^2.27.2 @tiptap/extension-color@^2.27.2 @tiptap/extension-highlight@^2.27.2 @tiptap/extension-text-style@^2.27.2
```

---

## Architecture Patterns

### 파일 변경 목록

```
teovibe/
├── app/frontend/editor/
│   ├── admin_rhino_editor.js      # [수정] STYL-01~04 extension 등록 + renderToolbarEnd() 확장
│   └── font_size_extension.js     # [신규] STYL-04 커스텀 FontSize extension
├── package.json                   # [수정] 4개 패키지 추가
└── pnpm-lock.yaml                 # [수정] lockfile 업데이트
```

ActionText initializer(`config/initializers/action_text.rb`)는 **변경 불필요** — Phase 14에서 `style`, `span`, `mark` 모두 이미 허용됨.

### Pattern 1: TextAlign extension 등록 및 구성 (STYL-01)

**What:** `TextAlign`은 `paragraph`/`heading` 노드에 `text-align` 인라인 스타일을 적용하는 TipTap extension이다.

**핵심 구성:**
```javascript
// Source: https://tiptap.dev/docs/editor/extensions/functionality/textalign (HIGH)
// types: 정렬을 적용할 노드 타입 목록. paragraph와 heading 모두 지정해야 한다.
import TextAlign from "@tiptap/extension-text-align"

// connectedCallback에서 addExtensions로 등록
this.addExtensions(
  TextAlign.configure({ types: ["heading", "paragraph"] })
)
```

**중요:** `addExtensions()`는 extension의 `.name` 으로 중복 체크한다. TextAlign의 name은 `"textAlign"`이므로 StarterKit과 충돌 없음(StarterKit에 포함되지 않음).

**커맨드:**
```javascript
this.editor?.chain().focus().setTextAlign("center").run()    // 가운데 정렬
this.editor?.chain().focus().setTextAlign("left").run()      // 왼쪽 정렬
this.editor?.chain().focus().setTextAlign("right").run()     // 오른쪽 정렬
this.editor?.chain().focus().unsetTextAlign().run()          // 정렬 해제
```

**출력 HTML:** `<p style="text-align: center">텍스트</p>` — style 속성이 허용되어 있어 ActionText 렌더링 시 보존됨.

**상태 확인:**
```javascript
this.editor?.isActive({ textAlign: "center" })   // 가운데 정렬 활성 여부
this.editor?.isActive({ textAlign: "left" })     // 왼쪽 정렬 활성 여부
this.editor?.isActive({ textAlign: "right" })    // 오른쪽 정렬 활성 여부
```

### Pattern 2: Color + TextStyle extension 등록 (STYL-02)

**What:** `Color`는 `TextStyle` mark 위에서 동작하며 선택 텍스트에 `style="color: #hex"` 인라인 스타일을 적용한다.

**TextStyle은 peer dependency:** `@tiptap/extension-color`는 `@tiptap/extension-text-style`을 peerDependency로 가진다. TextStyle을 먼저(또는 함께) 등록해야 Color가 동작한다.

```javascript
// Source: https://tiptap.dev/docs/editor/extensions/functionality/color (HIGH)
import TextStyle from "@tiptap/extension-text-style"
import Color from "@tiptap/extension-color"

// connectedCallback에서 등록 (TextStyle 먼저)
this.addExtensions(TextStyle, Color)
```

**커맨드:**
```javascript
this.editor?.chain().focus().setColor("#FF0000").run()   // 빨간색
this.editor?.chain().focus().unsetColor().run()          // 색상 해제
```

**출력 HTML:** `<span style="color: #FF0000">텍스트</span>`

**addExtensions 중복 체크 주의:** TextStyle의 name은 `"textStyle"`, Color의 name은 `"color"`. StarterKit/RhinoStarterKit에 없으므로 중복 없음.

### Pattern 3: Highlight extension 등록 (STYL-03)

**What:** `Highlight`는 `<mark>` 태그로 배경 하이라이트를 적용한다. `multicolor: true`로 설정해야 색상 선택이 가능하다.

```javascript
// Source: https://tiptap.dev/docs/editor/extensions/marks/highlight (HIGH)
import Highlight from "@tiptap/extension-highlight"

// multicolor: true 필수 — 기본값(false)은 고정 노란색만 지원
this.addExtensions(Highlight.configure({ multicolor: true }))
```

**커맨드:**
```javascript
this.editor?.chain().focus().toggleHighlight({ color: "#FFFF00" }).run()  // 노란 하이라이트
this.editor?.chain().focus().setHighlight({ color: "#FFD700" }).run()     // 특정 색상
this.editor?.chain().focus().unsetHighlight().run()                        // 하이라이트 해제
```

**출력 HTML:** `<mark style="background-color: #FFFF00">텍스트</mark>`

ActionText allowed_tags에 이미 `mark` 포함, allowed_attributes에 이미 `style` 포함 — 변경 불필요.

### Pattern 4: 커스텀 FontSize extension (STYL-04)

**Why local:** `@tiptap/extension-font-size`는 v3.x 전용으로 v2.27.2에 존재하지 않는다 (`pnpm view @tiptap/extension-font-size@2.27.2`로 미존재 확인). 로컬 Extension.create() 패턴으로 구현한다.

**구현 파일 (`app/frontend/editor/font_size_extension.js`):**
```javascript
// Source: gregveres/64ec1d8a gist (TipTap v2 커스텀 FontSize 패턴, MEDIUM confidence)
// TextStyle.create() 위에서 동작하는 Extension (Mark가 아닌 Extension)
import { Extension } from "@tiptap/core"

export const FontSize = Extension.create({
  name: "fontSize",

  addOptions() {
    return {
      types: ["textStyle"],
    }
  },

  addGlobalAttributes() {
    return [
      {
        types: this.options.types,
        attributes: {
          fontSize: {
            default: null,
            parseHTML: (element) =>
              element.style.fontSize.replace(/['"]+/g, ""),
            renderHTML: (attributes) => {
              if (!attributes.fontSize) return {}
              return { style: `font-size: ${attributes.fontSize}` }
            },
          },
        },
      },
    ]
  },

  addCommands() {
    return {
      setFontSize:
        (fontSize) =>
        ({ chain }) =>
          chain().setMark("textStyle", { fontSize }).run(),

      unsetFontSize:
        () =>
        ({ chain }) =>
          chain()
            .setMark("textStyle", { fontSize: null })
            .removeEmptyTextStyle()
            .run(),
    }
  },
})
```

**admin_rhino_editor.js에서 import:**
```javascript
import { FontSize } from "../editor/font_size_extension.js"

// TextStyle이 등록된 후 FontSize 추가 (TextStyle → FontSize 순서 의존)
this.addExtensions(TextStyle, Color, FontSize)
```

**커맨드:**
```javascript
this.editor?.chain().focus().setFontSize("16px").run()
this.editor?.chain().focus().setFontSize("24px").run()
this.editor?.chain().focus().unsetFontSize().run()
```

**출력 HTML:** `<span style="font-size: 16px">텍스트</span>`

### Pattern 5: renderToolbarEnd() 확장 — 스타일링 UI 추가

Phase 15에서 확립한 `renderToolbarEnd()` override 패턴을 그대로 따른다. 기존 버튼(제목 드롭다운, 구분선, 밑줄)에 스타일링 버튼을 추가한다.

**정렬 버튼 그룹:**
```javascript
renderAlignButtons() {
  const isLeft = this.editor?.isActive({ textAlign: "left" })
  const isCenter = this.editor?.isActive({ textAlign: "center" })
  const isRight = this.editor?.isActive({ textAlign: "right" })

  return html`
    <button
      class="toolbar__button rhino-toolbar-button ${isLeft ? 'toolbar__button--active' : ''}"
      type="button" tabindex="-1" data-role="toolbar-item"
      aria-label="왼쪽 정렬" title="왼쪽 정렬"
      @click=${() => this.editor?.chain().focus().setTextAlign("left").run()}
    >&#8676;</button>
    <button
      class="toolbar__button rhino-toolbar-button ${isCenter ? 'toolbar__button--active' : ''}"
      type="button" tabindex="-1" data-role="toolbar-item"
      aria-label="가운데 정렬" title="가운데 정렬"
      @click=${() => this.editor?.chain().focus().setTextAlign("center").run()}
    >&#8677;</button>
    <button
      class="toolbar__button rhino-toolbar-button ${isRight ? 'toolbar__button--active' : ''}"
      type="button" tabindex="-1" data-role="toolbar-item"
      aria-label="오른쪽 정렬" title="오른쪽 정렬"
      @click=${() => this.editor?.chain().focus().setTextAlign("right").run()}
    >&#8678;</button>
  `
}
```

**색상 팔레트 (Color/Highlight):**

색상 팔레트는 `<input type="color">` 또는 미리 정의된 색상 버튼 배열로 구현할 수 있다. 가장 간단한 방식은 `<input type="color">`:

```javascript
renderColorPicker() {
  return html`
    <label class="toolbar__button rhino-toolbar-button" title="글자색" data-role="toolbar-item">
      <span style="text-decoration: underline; text-decoration-color: currentColor">A</span>
      <input
        type="color"
        style="width: 0; height: 0; opacity: 0; position: absolute;"
        @input=${(e) => this.editor?.chain().focus().setColor(e.target.value).run()}
      />
    </label>
    <button
      class="toolbar__button rhino-toolbar-button"
      type="button" tabindex="-1" data-role="toolbar-item"
      aria-label="글자색 해제" title="글자색 해제"
      @click=${() => this.editor?.chain().focus().unsetColor().run()}
    >A&#8416;</button>
  `
}

renderHighlightPicker() {
  return html`
    <label class="toolbar__button rhino-toolbar-button" title="배경 하이라이트" data-role="toolbar-item">
      <mark style="padding: 0 2px;">H</mark>
      <input
        type="color"
        style="width: 0; height: 0; opacity: 0; position: absolute;"
        @input=${(e) => this.editor?.chain().focus().setHighlight({ color: e.target.value }).run()}
      />
    </label>
    <button
      class="toolbar__button rhino-toolbar-button"
      type="button" tabindex="-1" data-role="toolbar-item"
      aria-label="하이라이트 해제" title="하이라이트 해제"
      @click=${() => this.editor?.chain().focus().unsetHighlight().run()}
    >H&#8416;</button>
  `
}
```

**폰트 크기 드롭다운:**
```javascript
renderFontSizeDropdown() {
  const sizes = ["12px", "14px", "16px", "18px", "24px", "32px"]
  return html`
    <select
      class="toolbar__button rhino-toolbar-button"
      aria-label="폰트 크기"
      data-role="toolbar-item"
      @change=${(e) => {
        if (e.target.value === "") {
          this.editor?.chain().focus().unsetFontSize().run()
        } else {
          this.editor?.chain().focus().setFontSize(e.target.value).run()
        }
      }}
    >
      <option value="">크기</option>
      ${sizes.map(size => html`<option value=${size}>${size}</option>`)}
    </select>
  `
}
```

**renderToolbarEnd() 전체:**
```javascript
renderToolbarEnd() {
  return html`
    ${this.renderHeadingDropdown()}
    ${this.renderHorizontalRuleButton()}
    ${this.renderUnderlineButton()}
    ${this.renderAlignButtons()}
    ${this.renderColorPicker()}
    ${this.renderHighlightPicker()}
    ${this.renderFontSizeDropdown()}
  `
}
```

### Anti-Patterns to Avoid

- **`@tiptap/extension-font-size` 설치 시도:** v3.x 전용. `pnpm add @tiptap/extension-font-size`는 v3.x를 설치하여 TipTap v2 환경에서 충돌. 로컬 extension 사용.
- **TextStyle 없이 Color 등록:** `this.addExtensions(Color)` 단독 등록 시 TextStyle peerDependency 미충족. `this.addExtensions(TextStyle, Color)` 순서 필수.
- **Highlight에 multicolor: false(기본값) 사용:** 색상 선택 불가. `Highlight.configure({ multicolor: true })` 필수.
- **TextAlign 등록 시 types 생략:** `TextAlign.configure()` (types 없음)는 어떤 노드에도 정렬이 적용되지 않음. `types: ["heading", "paragraph"]` 필수.
- **actiontext.rb에 불필요한 태그 추가:** `span`/`mark`/`style`은 Phase 14에서 이미 허용됨. 중복 추가하면 initializer 가독성 저하 + 잠재적 배열 중복.

---

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| 텍스트 색상 적용 | ProseMirror mark 직접 구현 | `@tiptap/extension-color` + TextStyle | HTML 파싱/렌더링, 중첩 span 처리 등 edge case 내장 |
| 배경 하이라이트 | 직접 `<mark>` mark 구현 | `@tiptap/extension-highlight` | multicolor 지원, parseHTML/renderHTML, 단축키 내장 |
| 텍스트 정렬 | 노드에 직접 textAlign attribute 추가 | `@tiptap/extension-text-align` | 모든 노드 타입에 일관된 적용, 커맨드 체인 통합 |
| FontSize (npm 패키지) | `@tiptap/extension-font-size` 설치 | 로컬 `font_size_extension.js` | v2.27.2에 해당 패키지 없음. 30줄 Extension.create()가 완전히 동일한 기능 제공 |

**Key insight:** Color/Highlight/TextAlign 모두 TipTap 공식 v2.27.2 패키지로 제공됨. FontSize만 예외적으로 커스텀 구현이 필요하며, 이는 요구사항 STYL-04에 명시된 사항.

---

## Common Pitfalls

### Pitfall 1: TextStyle peerDependency 미충족으로 Color/FontSize가 동작하지 않음

**What goes wrong:** Color extension을 등록했는데 `setColor()` 커맨드가 undefined이거나, 실행해도 텍스트에 색상이 적용되지 않음.

**Why it happens:** `@tiptap/extension-color`는 TextStyle mark를 peerDependency로 요구한다. TextStyle 없이는 Color가 span 태그를 렌더링할 수 없다.

**How to avoid:** `this.addExtensions(TextStyle, Color, FontSize)` — TextStyle을 반드시 먼저, Color와 FontSize를 뒤에 등록.

**Warning signs:** 브라우저 콘솔에서 `document.querySelector("admin-rhino-editor").editor.commands.setColor` 가 undefined.

### Pitfall 2: addExtensions의 이름 중복 필터링

**What goes wrong:** 이미 등록된 extension 이름과 동일한 이름의 extension을 추가하려 할 때 조용히 무시됨.

**Why it happens:** `addExtensions()`는 `existingExtensions.includes(ext.name)`으로 중복 체크하여 필터링한다(소스 직접 확인됨). TextStyle name은 `"textStyle"`, Color는 `"color"`, Highlight는 `"highlight"`, FontSize는 `"fontSize"`, TextAlign은 `"textAlign"` — StarterKit/RhinoStarterKit에 없으므로 충돌 없음.

**How to avoid:** 문제 없음. 단, 커스텀 FontSize extension의 `name: "fontSize"`는 유니크하게 유지할 것.

### Pitfall 3: TextAlign이 저장 후 상세 페이지에서 사라짐

**What goes wrong:** 에디터에서 텍스트를 가운데 정렬해도 저장 후 상세 페이지에서 왼쪽 정렬로 돌아옴.

**Why it happens:** Phase 14에서 `style` 속성을 ActionText 허용목록에 추가했으므로, 이 pitfall은 **발생하지 않는다**. 단, action_text.rb의 `allowed_attributes += ["style"]` 라인이 실제로 실행됐는지 확인이 필요하다.

**How to avoid:** `bin/rails runner "puts ActionText::ContentHelper.allowed_attributes.include?('style')"` 가 `true`임을 확인.

**Warning signs:** style 속성이 ActionText 허용목록에 없거나, initializer가 로드되지 않은 경우.

### Pitfall 4: `<input type="color">` UI와 Lit reactive 업데이트

**What goes wrong:** color picker에서 색상을 선택해도 에디터 텍스트에 적용되지 않거나 적용됐다가 사라짐.

**Why it happens:** `@input` 이벤트 핸들러가 Lit의 업데이트 사이클과 겹치면서 포커스가 에디터에서 빠져나갈 수 있다.

**How to avoid:** 항상 `.chain().focus().setColor(value).run()` 패턴으로 포커스를 에디터로 복귀시킨다. `@change` 대신 `@input` 이벤트를 사용하면 실시간 미리보기가 가능하다.

**Warning signs:** 색상 picker 클릭 후 에디터 선택 해제 → setColor 실행 시 선택 영역 없음 오류.

### Pitfall 5: FontSize 커스텀 extension의 parseHTML 정규식

**What goes wrong:** 저장된 글을 다시 에디터에서 열면 폰트 크기 설정이 손실됨.

**Why it happens:** 커스텀 FontSize extension의 `parseHTML`에서 `element.style.fontSize`를 올바르게 파싱하지 못함.

**How to avoid:** `parseHTML: (element) => element.style.fontSize.replace(/['"]+/g, "")` — CSS 값에서 따옴표만 제거하는 단순 정규식 사용. `element.style.fontSize`가 빈 문자열이면 `null`을 반환해야 한다.

```javascript
parseHTML: (element) => element.style.fontSize.replace(/['"]+/g, "") || null
```

**Warning signs:** 에디터에서 폰트 크기 설정 → 저장 → 재편집 시 크기 드롭다운이 "크기" (기본값)으로 돌아옴.

### Pitfall 6: Phase 15에서 알려진 패턴 — pnpm transitive dep Vite 오류

**What goes wrong:** `import TextStyle from "@tiptap/extension-text-style"` 사용 시 Vite/Rollup이 "Failed to resolve import" 오류 발생.

**Why it happens:** `@tiptap/extension-text-style`은 rhino-editor의 transitive dep으로 pnpm virtual store에만 있다. Phase 15의 `lit` 동일 문제.

**How to avoid:** `pnpm add @tiptap/extension-text-style@^2.27.2`로 직접 의존성 추가 (설치 커맨드에 포함됨).

**Warning signs:** `bin/vite build` 시 `Failed to resolve import "@tiptap/extension-text-style"` 오류.

---

## Code Examples

### 전체 admin_rhino_editor.js import 섹션 (Phase 16 이후)

```javascript
// Source: Phase 14/15에서 확립된 패턴 + Phase 16 신규 추가
import { TipTapEditor } from "rhino-editor/exports/elements/tip-tap-editor.js"
import Underline from "@tiptap/extension-underline"
import TextAlign from "@tiptap/extension-text-align"
import TextStyle from "@tiptap/extension-text-style"
import Color from "@tiptap/extension-color"
import Highlight from "@tiptap/extension-highlight"
import { FontSize } from "../editor/font_size_extension.js"
import { html } from "lit"
```

### connectedCallback extension 등록

```javascript
connectedCallback() {
  super.connectedCallback()
  // Phase 15: Underline
  this.addExtensions(Underline)
  // Phase 16: TextAlign (types 필수), TextStyle → Color → FontSize (순서 의존)
  this.addExtensions(TextAlign.configure({ types: ["heading", "paragraph"] }))
  this.addExtensions(TextStyle, Color, FontSize)
  this.addExtensions(Highlight.configure({ multicolor: true }))
}
```

### ActionText 허용목록 확인 (변경 불필요)

```bash
# Phase 14에서 이미 추가됨 — 변경 없음을 확인
bin/rails runner "
  puts ActionText::ContentHelper.allowed_attributes.include?('style')  # true
  puts ActionText::ContentHelper.allowed_tags.include?('span')         # true
  puts ActionText::ContentHelper.allowed_tags.include?('mark')         # true
"
```

---

## State of the Art

| Old Approach | Current Approach | Notes |
|--------------|------------------|-------|
| Trix 기본 에디터 (서식 없음) | rhino-editor + AdminRhinoEditor extension 시스템 | Phase 14에서 확립 |
| `@tiptap/extension-font-size` (v3 only) | 로컬 `Extension.create()` 커스텀 구현 | STYL-04 요구사항에 명시 |
| 단일 색상 하이라이트 | `Highlight.configure({ multicolor: true })` | STYL-03 — 색상 선택 필수 |
| renderToolbar() 전체 재작성 | renderToolbarEnd() override | Phase 15에서 확립된 패턴 |

**Deprecated/outdated:**
- `@tiptap/extension-font-size`: v3.x 전용. v2.27.2 환경에서 설치 불가.
- `renderToolbar()` 전체 재작성: 기존 버튼 코드 복사 필요 — renderToolbarEnd() 사용.

---

## Open Questions

1. **색상 팔레트 UI 방식 — `<input type="color">` vs 사전 정의 팔레트**
   - What we know: `<input type="color">`는 구현이 단순하나 브라우저 native color picker UI가 노출됨. 사전 정의 팔레트는 디자인 일관성은 높으나 구현 복잡도가 증가.
   - What's unclear: 플래너가 어떤 UX를 선호하는지 — 두 방법 모두 기술적으로 가능.
   - Recommendation: `<input type="color">` 방식으로 구현. 추후 팔레트 버튼으로 교체 가능한 구조로 renderColorPicker() 메서드 분리.

2. **폰트 크기 선택지 범위**
   - What we know: 요구사항은 "드롭다운"으로 크기를 선택하는 방식.
   - What's unclear: 제공할 크기 선택지 (12/14/16/18/24/32px? 또는 더 넓은 범위?)
   - Recommendation: 12px, 14px, 16px, 18px, 24px, 32px — 6단계. 네이버 블로그 수준의 표준 범위.

3. **툴바 버튼 과부하 — 현재 버튼 수 체크**
   - What we know: Phase 15 이후 이미 제목 드롭다운/구분선/밑줄이 renderToolbarEnd에 추가됨. Phase 16에서 정렬 3개 + 색상 + 하이라이트 + 폰트 크기 드롭다운이 추가됨.
   - What's unclear: 툴바가 UI 상 너무 길어지는지 — 실제 브라우저에서 확인 필요.
   - Recommendation: 구현 후 Admin 폼에서 브라우저 확인 checkpoint 추가.

---

## Validation Architecture

### Test Framework

| Property | Value |
|----------|-------|
| Framework | 없음 (Phase 14/15와 동일) |
| Config file | none |
| Quick run command | `cd teovibe && bin/rails runner "puts ActionText::ContentHelper.allowed_attributes.include?('style') && ActionText::ContentHelper.allowed_tags.include?('span') && ActionText::ContentHelper.allowed_tags.include?('mark')"` |
| Full suite command | `bin/rails test` |

### Phase Requirements → Test Map

| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|--------------|
| STYL-01 | 정렬 버튼 클릭 시 단락에 `text-align` 인라인 스타일 적용, 저장 후 유지 | manual | Admin 폼 → 정렬 버튼 클릭 → HTML 소스 확인 → 저장 → 상세 페이지 확인 | N/A (manual) |
| STYL-02 | 색상 picker에서 색상 선택 시 `<span style="color:…">` 적용, 저장 후 유지 | manual | Admin 폼 → 텍스트 선택 → 색상 picker → 저장 → 상세 페이지 확인 | N/A (manual) |
| STYL-03 | 하이라이트 picker에서 색상 선택 시 `<mark style="background-color:…">` 적용, 저장 후 유지 | manual | Admin 폼 → 텍스트 선택 → 하이라이트 picker → 저장 → 상세 페이지 확인 | N/A (manual) |
| STYL-04 | 폰트 크기 드롭다운에서 크기 선택 시 `<span style="font-size:…">` 적용, 저장 후 유지 | manual | Admin 폼 → 텍스트 선택 → 크기 드롭다운 → 저장 → 상세 페이지 확인 | N/A (manual) |

ActionText 허용목록 automated smoke:
```bash
bin/rails runner "
  s = ActionText::ContentHelper.allowed_attributes.include?('style')
  span = ActionText::ContentHelper.allowed_tags.include?('span')
  mark = ActionText::ContentHelper.allowed_tags.include?('mark')
  puts s && span && mark
"
```

### Sampling Rate

- **Per task commit:** `bin/rails runner "puts ActionText::ContentHelper.allowed_attributes.include?('style')"` (true 확인) + `bin/vite build` 성공 확인
- **Per wave merge:** Admin 폼에서 4개 스타일 기능 모두 수동 확인 + 저장 후 상세 페이지 렌더링 확인
- **Phase gate:** STYL-01~04 success criteria 모두 수동 확인 후 Phase 17 진입

### Wave 0 Gaps

- [ ] `teovibe/app/frontend/editor/font_size_extension.js` — STYL-04 커스텀 FontSize extension (신규 파일)
- [ ] 패키지 설치: `pnpm add @tiptap/extension-text-align@^2.27.2 @tiptap/extension-color@^2.27.2 @tiptap/extension-highlight@^2.27.2 @tiptap/extension-text-style@^2.27.2`

---

## Sources

### Primary (HIGH confidence)

- `teovibe/pnpm-lock.yaml` — `@tiptap/core@2.27.2`, `@tiptap/extension-text-style@2.27.2` 설치 확인, text-align/color/highlight 미설치 확인
- `teovibe/node_modules/.pnpm/@tiptap+extension-text-style@2.27.2_@tiptap+core@2.27.2_@tiptap+pm@2.27.2_/node_modules/@tiptap/extension-text-style/dist/text-style.d.ts` — TextStyle Mark API 직접 확인
- `teovibe/node_modules/rhino-editor/exports/chunks/chunk-2NB236ZC.js L484` — `addExtensions()` 구현 (이름 중복 필터링 로직) 직접 확인
- `pnpm view @tiptap/extension-color@2.27.2 peerDependencies` — `@tiptap/extension-text-style` peerDep 확인
- `pnpm view @tiptap/extension-font-size@2.27.2 version` → NOT FOUND (v3.x 전용 확인)
- `bin/rails runner` — ActionText allowed_tags: `span`, `mark` 포함 확인 / allowed_attributes: `style` 포함 확인
- `teovibe/config/initializers/action_text.rb` — 현재 허용목록 설정 직접 확인
- `teovibe/app/frontend/editor/admin_rhino_editor.js` — Phase 15 완료 상태 (renderToolbarEnd, connectedCallback 패턴) 직접 확인

### Secondary (MEDIUM confidence)

- [TipTap TextAlign Docs](https://tiptap.dev/docs/editor/extensions/functionality/textalign) — types 옵션, setTextAlign 커맨드
- [TipTap Color Docs](https://tiptap.dev/docs/editor/extensions/functionality/color) — setColor/unsetColor, TextStyle 의존성
- [TipTap Highlight Docs](https://tiptap.dev/docs/editor/extensions/marks/highlight) — multicolor 옵션, setHighlight 커맨드
- [TipTap FontSize Docs](https://tiptap.dev/docs/editor/extensions/functionality/fontsize) — @tiptap/extension-text-style 기반, setFontSize 커맨드

### Tertiary (LOW confidence — 검증 필요)

- [gregveres/64ec1d8a gist](https://gist.github.com/gregveres/64ec1d8a733feb735b7dd4c46331abae) — TipTap v2 커스텀 FontSize Extension.create() 패턴 (단일 출처, 그러나 공식 fontFamily extension과 동일한 패턴)

---

## Metadata

**Confidence breakdown:**
- STYL-01 (TextAlign): HIGH — 패키지 존재 확인, 공식 docs 확인, ActionText style 허용 확인
- STYL-02 (Color + TextStyle): HIGH — peerDep 확인, 공식 docs, pnpm view 버전 확인
- STYL-03 (Highlight): HIGH — 패키지 존재 확인, multicolor 옵션 공식 docs
- STYL-04 (FontSize 커스텀): MEDIUM — @tiptap/extension-font-size v2 미존재 HIGH, 로컬 구현 패턴은 단일 gist 소스(gregveres) + 공식 fontFamily 패턴과 동일 구조로 MEDIUM
- ActionText 변경 불필요: HIGH — 직접 Rails runner로 allowed_tags/attributes 확인
- renderToolbarEnd 패턴: HIGH — Phase 15에서 검증된 패턴

**Research date:** 2026-03-14
**Valid until:** 2026-04-14 (rhino-editor 0.17.x + @tiptap 2.27.x 안정 — 빠른 변화 없음)
