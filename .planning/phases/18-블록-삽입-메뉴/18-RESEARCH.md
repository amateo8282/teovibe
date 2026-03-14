# Phase 18: 블록 삽입 메뉴 - Research

**Researched:** 2026-03-14
**Domain:** TipTap 2.27.2 FloatingMenu 패턴 + AdminRhinoEditor Light DOM 오버레이 확장
**Confidence:** HIGH

---

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|-----------------|
| BLCK-01 | FloatingMenu 기반 + 블록 삽입 버튼 (구분선/인용구/코드블록/표 빠른 삽입) | TipTap 공식 `@tiptap/extension-floating-menu`는 tippy.js 하드 의존성으로 사용 불가. 동일 빈 단락 감지 알고리즘을 `editor.on("selectionUpdate")` + Light DOM 오버레이 패턴으로 직접 구현. 삽입 커맨드(`setHorizontalRule`, `toggleBlockquote`, `toggleCodeBlock`, `insertTable`)는 Phase 15/17에서 이미 검증됨. 신규 패키지 설치 불필요. |
</phase_requirements>

---

## Summary

Phase 18은 Admin 에디터에 "빈 단락에서 + 버튼이 나타나 블록을 빠르게 삽입" 기능을 추가한다. 이 기능은 Notion/네이버 블로그 스타일의 FloatingMenu(인라인 블록 삽입 메뉴)와 동일한 UX다.

**가장 중요한 발견:** TipTap 공식 `@tiptap/extension-floating-menu@2.27.2`는 **tippy.js에 하드 의존성**이 있어 사용할 수 없다. rhino-editor는 이미 자체 BubbleMenu 구현에서 tippy를 배제했고, Web Component Shadow DOM 환경에서 tippy의 포지셔닝이 신뢰할 수 없다. Phase 17의 표 컨텍스트 메뉴 패턴(Light DOM `<div>` + `editor.on("selectionUpdate")`)을 그대로 재사용한다.

**빈 단락 감지 알고리즘**은 TipTap FloatingMenu 소스에서 직접 확인했다. `$anchor.depth === 1` + `selection.empty` + `$anchor.parent.isTextblock` + `!$anchor.parent.type.spec.code` + `$anchor.parent.childCount === 0` + `!$anchor.parent.textContent` 조건을 모두 만족할 때만 표시한다. 이 알고리즘을 `_updateFloatingMenu()` 헬퍼 메서드로 구현한다.

삽입 커맨드(`setHorizontalRule`, `toggleBlockquote`, `toggleCodeBlock`, `insertTable`)는 Phase 15/17에서 이미 검증되었고, 이미 등록된 extension에 포함되어 있다. **신규 패키지 설치 불필요.**

**Primary recommendation:** `admin_rhino_editor.js`에 Light DOM `<div>` 플로팅 버튼(`+`) + 서브 메뉴 패널 구현. `startEditor()` override에서 `editor.on("selectionUpdate")` + `editor.on("blur")`로 표시/숨김 제어. 위치는 `editor.view.coordsAtPos(from)`으로 커서 좌측에 배치.

---

## Standard Stack

### Core (전부 이미 설치됨 — 신규 설치 없음)

| 라이브러리 | 버전 | 목적 | 상태 |
|------------|------|------|------|
| `rhino-editor` | 0.17.3 | TipTapEditor 서브클래스 베이스 | 설치됨 |
| `@tiptap/core` | 2.27.2 | TipTap 코어 + `posToDOMRect` 유틸 | 설치됨 |
| `@tiptap/pm` | 2.27.2 | ProseMirror state (selection 타입) | 설치됨 |
| `lit` | 3.3.2 | Lit html 태그 (기존 renderToolbarEnd 패턴) | 설치됨 |
| `@tiptap/extension-table` | 2.27.2 | `insertTable` 커맨드 (Phase 17) | 설치됨 |

### 사용 불가 / 사용 안 함

| 패키지 | 이유 |
|--------|------|
| `@tiptap/extension-floating-menu@2.27.2` | tippy.js 하드 의존성. rhino-editor Shadow DOM과 충돌 가능. `tippy.js@^6.3.7` 추가 설치 필요. 사용 금지. |
| `tippy.js` | 직접 설치도 금지. Shadow DOM 환경에서 포지셔닝 신뢰 불가. |

**Installation:** 없음 — 신규 패키지 불필요.

---

## Architecture Patterns

### 파일 변경 목록

```
teovibe/
├── app/frontend/editor/
│   └── admin_rhino_editor.js     # [수정 전용] 플로팅 메뉴 초기화/위치/표시 로직 추가
└── package.json / pnpm-lock.yaml # [변경 없음] 신규 패키지 없음
```

### Pattern 1: 빈 단락 감지 알고리즘

**What:** TipTap FloatingMenu 소스(`@tiptap/extension-floating-menu@2.27.2/dist/index.cjs`)에서 직접 확인한 `shouldShow` 로직.

**조건 (AND):**
1. `view.hasFocus()` — 에디터가 포커스된 상태
2. `this.editor.isEditable` — 편집 가능 상태
3. `selection.empty` — 텍스트 선택 없음 (커서만)
4. `$anchor.depth === 1` — 최상위 블록 레벨 (표 셀 내부, 리스트 아이템 내부 제외)
5. `$anchor.parent.isTextblock` — 부모 노드가 텍스트 블록 (paragraph, heading 등)
6. `!$anchor.parent.type.spec.code` — 코드 블록이 아님
7. `$anchor.parent.childCount === 0` — 자식 노드 없음
8. `!$anchor.parent.textContent` — 텍스트 내용 없음

조건 8이 조건 7의 보완 역할을 한다 (softbreak 같은 non-text 자식에 대응).

**예제 구현:**

```javascript
// Source: @tiptap/extension-floating-menu@2.27.2 shouldShow 로직 (직접 확인)
_isEmptyParagraph() {
  if (!this.editor) return false
  const { state, view } = this.editor
  const { selection } = state
  const { $anchor, empty } = selection

  if (!view.hasFocus()) return false
  if (!this.editor.isEditable) return false
  if (!empty) return false
  if ($anchor.depth !== 1) return false
  if (!$anchor.parent.isTextblock) return false
  if ($anchor.parent.type.spec.code) return false
  if ($anchor.parent.childCount !== 0) return false
  if ($anchor.parent.textContent) return false

  return true
}
```

**When to use:** `editor.on("selectionUpdate")` 콜백 내부에서 호출. 결과에 따라 `_floatingMenu`를 표시/숨김.

### Pattern 2: Light DOM 플로팅 메뉴 구조 (Phase 17 패턴 재사용)

**What:** Shadow DOM 외부 Light DOM `<div>`로 플로팅 메뉴 오버레이 구현. Phase 17의 `_initTableContextMenu()` 패턴과 동일.

**두 단계 UI:**
1. `+` 버튼 (항상 보이는 단일 버튼) — 클릭 시 서브 메뉴 패널 토글
2. 서브 메뉴 패널 — 구분선/인용구/코드블록/표 4개 버튼

**메뉴 표시 조건 정리:**
- 빈 단락에 커서 → `+` 버튼 표시 (서브 메뉴는 닫힌 상태)
- `+` 버튼 클릭 → 서브 메뉴 패널 열기
- 서브 메뉴에서 항목 선택 → 삽입 후 메뉴 닫기
- 텍스트 입력 시작 → 빈 단락 조건 실패 → `+` 버튼 숨김
- 에디터 블러 → `+` 버튼 숨김

```javascript
_initFloatingMenu() {
  // 플로팅 버튼 wrapper
  const menu = document.createElement("div")
  menu.style.cssText = [
    "position:absolute",
    "z-index:50",
    "display:none",
  ].join(";")

  // + 버튼
  const toggleBtn = document.createElement("button")
  toggleBtn.type = "button"
  toggleBtn.textContent = "+"
  toggleBtn.style.cssText = [
    "width:24px",
    "height:24px",
    "border-radius:50%",
    "border:1px solid #d1d5db",
    "background:white",
    "cursor:pointer",
    "font-size:16px",
    "line-height:1",
    "color:#6b7280",
    "display:flex",
    "align-items:center",
    "justify-content:center",
    "padding:0",
  ].join(";")

  // 서브 메뉴 패널 (기본 숨김)
  const panel = document.createElement("div")
  panel.style.cssText = [
    "display:none",
    "position:absolute",
    "left:30px",
    "top:0",
    "background:white",
    "border:1px solid #e5e7eb",
    "border-radius:6px",
    "box-shadow:0 2px 8px rgba(0,0,0,0.15)",
    "padding:4px",
    "min-width:120px",
    "white-space:nowrap",
  ].join(";")

  const items = [
    { action: "horizontal-rule", label: "구분선" },
    { action: "blockquote",      label: "인용구" },
    { action: "code-block",      label: "코드블록" },
    { action: "table",           label: "표" },
  ]

  const btnStyle = [
    "display:block",
    "width:100%",
    "text-align:left",
    "padding:4px 12px",
    "border:none",
    "background:none",
    "cursor:pointer",
    "font-size:13px",
    "border-radius:4px",
  ].join(";")

  items.forEach(({ action, label }) => {
    const btn = document.createElement("button")
    btn.type = "button"
    btn.setAttribute("data-action", action)
    btn.style.cssText = btnStyle
    btn.textContent = label
    btn.onmouseenter = () => { btn.style.background = "#f3f4f6" }
    btn.onmouseleave = () => { btn.style.background = "none" }
    panel.appendChild(btn)
  })

  toggleBtn.addEventListener("click", (e) => {
    e.preventDefault()
    e.stopPropagation()
    panel.style.display = panel.style.display === "none" ? "block" : "none"
  })

  panel.addEventListener("click", (e) => this._handleFloatingMenuClick(e))

  menu.appendChild(toggleBtn)
  menu.appendChild(panel)

  const container = this.closest("form") || document.body
  container.appendChild(menu)
  this._floatingMenu = menu
  this._floatingPanel = panel
}
```

### Pattern 3: 위치 계산 — 커서 좌측에 배치

**What:** `editor.view.coordsAtPos(from)`로 뷰포트 좌표를 얻어 커서 행 높이에 맞춰 왼쪽 여백에 배치.

```javascript
_updateFloatingMenu() {
  if (!this._floatingMenu) return

  if (!this._isEmptyParagraph()) {
    this._floatingMenu.style.display = "none"
    this._floatingPanel.style.display = "none"
    return
  }

  const { from } = this.editor.state.selection
  const coords = this.editor.view.coordsAtPos(from)

  // 커서 행 수직 중앙, 에디터 왼쪽 여백에 배치
  const buttonSize = 24
  const top = coords.top + window.scrollY - (buttonSize / 2) + ((coords.bottom - coords.top) / 2)

  // 에디터 컨테이너 왼쪽 기준으로 배치
  const editorRect = this.editor.view.dom.getBoundingClientRect()
  const left = editorRect.left + window.scrollX - buttonSize - 8

  this._floatingMenu.style.top = `${top}px`
  this._floatingMenu.style.left = `${Math.max(0, left)}px`
  this._floatingMenu.style.display = "block"
}
```

**위치 fallback:** 에디터가 뷰포트 왼쪽 가장자리에 붙어있어 `left`가 음수가 될 수 있다. `Math.max(0, left)`로 0 이하 방지.

### Pattern 4: 삽입 커맨드 (이미 검증됨)

```javascript
_handleFloatingMenuClick(e) {
  const action = e.target.closest("[data-action]")?.getAttribute("data-action")
  if (!action || !this.editor) return
  e.preventDefault()

  this._floatingMenu.style.display = "none"
  this._floatingPanel.style.display = "none"

  const chain = this.editor.chain().focus()
  switch (action) {
    case "horizontal-rule":
      chain.setHorizontalRule().run()
      break
    case "blockquote":
      chain.toggleBlockquote().run()
      break
    case "code-block":
      chain.toggleCodeBlock().run()
      break
    case "table":
      chain.insertTable({ rows: 3, cols: 3, withHeaderRow: true }).run()
      break
  }
}
```

**커맨드 출처:**
- `setHorizontalRule` — Phase 15에서 검증, StarterKit 포함
- `toggleBlockquote` — rhino-editor 기본 제공, `chunk-JV22V53Y.js:643` 직접 확인
- `toggleCodeBlock` — rhino-editor 기본 제공, `chunk-JV22V53Y.js:741` 직접 확인
- `insertTable` — Phase 17에서 검증, `@tiptap/extension-table` 포함

### Pattern 5: startEditor() 통합 (Phase 17 패턴 동일)

```javascript
async startEditor() {
  await super.startEditor()
  this._initTableContextMenu()  // Phase 17 (기존)
  this._initFloatingMenu()       // Phase 18 (신규)

  // Phase 17 기존 리스너
  this.editor?.on("selectionUpdate", () => this._updateTableMenu())
  this.editor?.on("blur", () => {
    if (this._tableMenu) this._tableMenu.style.display = "none"
  })

  // Phase 18 신규 리스너
  this.editor?.on("selectionUpdate", () => this._updateFloatingMenu())
  this.editor?.on("update", () => this._updateFloatingMenu())
  this.editor?.on("blur", () => {
    if (this._floatingMenu) {
      this._floatingMenu.style.display = "none"
      this._floatingPanel.style.display = "none"
    }
  })
}
```

`editor.on("update")`도 등록하는 이유: 텍스트 입력 시 `selectionUpdate`만으로는 빈 단락이 채워지는 시점을 즉시 감지 못할 수 있음. `update` 이벤트는 doc 변경 시 항상 발생.

### Pattern 6: disconnectedCallback 정리

```javascript
disconnectedCallback() {
  super.disconnectedCallback()
  this._tableMenu?.remove()
  this._tableMenu = null
  this._floatingMenu?.remove()    // Phase 18 추가
  this._floatingMenu = null
  this._floatingPanel = null
}
```

### Anti-Patterns to Avoid

- **`@tiptap/extension-floating-menu` 설치 시도:** tippy.js 의존성으로 rhino-editor와 충돌. 절대 사용 금지.
- **Shadow DOM 내부에 플로팅 메뉴 렌더링:** Lit `html` 태그로 shadow DOM에 넣으면 `position:absolute`가 shadow DOM 범위로 제한됨. Light DOM 필수.
- **`$anchor.depth !== 1` 조건 누락:** 표 셀 내부나 리스트 아이템 안에서도 빈 텍스트 블록이 존재함. depth === 1이 아니면 최상위 단락이 아님 — 메뉴가 중첩 구조 안에서 나타나는 버그 발생.
- **`editor.on("update")`만 등록:** 커서 이동(텍스트 선택)에는 update가 발생하지 않으므로 `selectionUpdate`도 함께 등록 필요.
- **Panel을 숨기지 않고 버튼만 숨김:** 서브 메뉴 패널이 열린 채로 `+` 버튼만 숨기면 panel이 화면에 남음. 항상 `_floatingMenu`와 `_floatingPanel` 둘 다 숨김 처리.
- **표 안에서 플로팅 메뉴 표시:** `$anchor.depth === 1` 조건이 이를 자동 차단함 (표 셀 내부는 depth > 1). 하지만 명시적으로 `this.editor.isActive("table")`로 추가 가드 가능.

---

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| 빈 단락 감지 알고리즘 | 자체 regex/length 체크 | TipTap FloatingMenu 소스의 검증된 알고리즘 (`$anchor.depth`, `isTextblock`, `childCount`, `textContent`) | ProseMirror 문서 모델에서 "빈"의 정의는 단순 텍스트 길이가 아님. 소프트 줄바꿈, 마크, 중첩 노드 등 edge case 존재 |
| 삽입 커맨드 | DOM 직접 조작 | TipTap chain commands | Undo/redo 자동 지원, ProseMirror 트랜잭션 기반 |
| Tippy.js 기반 FloatingMenu | 커스텀 tippy 래퍼 | Light DOM + `editor.on("selectionUpdate")` | Shadow DOM 환경에서 tippy 포지셔닝 불안정. 의존성 추가 불필요 |

---

## Common Pitfalls

### Pitfall 1: `$anchor.depth !== 1` 조건 미적용으로 표 셀 내 메뉴 표시

**What goes wrong:** 표 안의 빈 셀에 커서를 놓으면 `+` 버튼이 나타남.

**Why it happens:** 표 셀 내 단락도 `isTextblock`, `childCount === 0`, `textContent === ""` 조건을 모두 만족하지만, depth는 4 이상(table > tableRow > tableCell > paragraph).

**How to avoid:** `$anchor.depth === 1` 조건 필수.

**Warning signs:** 표 셀 클릭 시 표 컨텍스트 메뉴와 `+` 버튼이 동시에 나타남.

### Pitfall 2: selectionUpdate만 등록 (update 미등록)

**What goes wrong:** 텍스트를 입력하면 `+` 버튼이 즉시 사라지지 않고 다음 커서 이동 시에야 사라짐.

**Why it happens:** 문자 입력 시 `update` 이벤트만 발생하고 `selectionUpdate`는 발생하지 않을 수 있음.

**How to avoid:** `editor.on("update")` + `editor.on("selectionUpdate")` 둘 다 등록.

**Warning signs:** 첫 글자를 입력해도 `+` 버튼이 잠시 남아있음.

### Pitfall 3: Light DOM 메뉴 컨테이너를 body에 붙이면 form submit 시 포함

**What goes wrong:** `+` 메뉴가 form의 외부 body에 있어도 서브 메뉴 버튼이 form submit을 트리거할 수 있음.

**Why it happens:** 버튼 `type` 속성이 기본값 `"submit"`이면 가장 가까운 form에 submit 이벤트 발생.

**How to avoid:** 모든 버튼에 `type="button"` 명시. `_initFloatingMenu()`의 모든 버튼에 이미 적용.

**Warning signs:** `+` 메뉴 항목 클릭 시 페이지가 submit/reload됨.

### Pitfall 4: disconnectedCallback에서 _floatingPanel 미정리

**What goes wrong:** 에디터 컴포넌트가 DOM에서 제거된 후에도 `+` 버튼과 서브 메뉴 패널이 화면에 남아있음.

**How to avoid:** `disconnectedCallback()`에서 `this._floatingMenu?.remove()` + `null` 할당.

### Pitfall 5: _floatingMenu가 null인 상태에서 _updateFloatingMenu 호출

**What goes wrong:** `startEditor()` 완료 전에 `selectionUpdate`가 발생하면 `_floatingMenu`가 null이어서 TypeError.

**How to avoid:** `_updateFloatingMenu()`의 첫 줄에 `if (!this._floatingMenu) return` 가드.

**Warning signs:** 브라우저 콘솔에 `Cannot set properties of null` TypeError.

---

## Code Examples

### 빈 단락 감지 (검증된 알고리즘)

```javascript
// Source: @tiptap/extension-floating-menu@2.27.2 shouldShow 로직 (직접 확인)
_isEmptyParagraph() {
  if (!this.editor) return false
  const { state, view } = this.editor
  const { selection } = state
  const { $anchor, empty } = selection

  if (!view.hasFocus()) return false
  if (!this.editor.isEditable) return false
  if (!empty) return false
  if ($anchor.depth !== 1) return false
  if (!$anchor.parent.isTextblock) return false
  if ($anchor.parent.type.spec.code) return false
  if ($anchor.parent.childCount !== 0) return false
  if ($anchor.parent.textContent) return false

  return true
}
```

### 플로팅 메뉴 표시/위치 업데이트

```javascript
// Source: Phase 17 _updateTableMenu 패턴 + posToDOMRect 커서 위치 계산
_updateFloatingMenu() {
  if (!this._floatingMenu) return

  if (!this._isEmptyParagraph()) {
    this._floatingMenu.style.display = "none"
    this._floatingPanel.style.display = "none"
    return
  }

  const { from } = this.editor.state.selection
  const coords = this.editor.view.coordsAtPos(from)

  const buttonSize = 24
  const lineHeight = coords.bottom - coords.top
  const top = coords.top + window.scrollY + (lineHeight / 2) - (buttonSize / 2)

  const editorRect = this.editor.view.dom.getBoundingClientRect()
  const left = editorRect.left + window.scrollX - buttonSize - 8

  this._floatingMenu.style.top = `${top}px`
  this._floatingMenu.style.left = `${Math.max(0, left)}px`
  this._floatingMenu.style.display = "block"
}
```

### startEditor() 통합 전체 패턴

```javascript
// admin_rhino_editor.js — Phase 17 기존 코드에 Phase 18 추가
async startEditor() {
  await super.startEditor()

  // Phase 17
  this._initTableContextMenu()
  this.editor?.on("selectionUpdate", () => this._updateTableMenu())
  this.editor?.on("blur", () => {
    if (this._tableMenu) this._tableMenu.style.display = "none"
  })

  // Phase 18
  this._initFloatingMenu()
  this.editor?.on("selectionUpdate", () => this._updateFloatingMenu())
  this.editor?.on("update", () => this._updateFloatingMenu())
  this.editor?.on("blur", () => {
    if (this._floatingMenu) {
      this._floatingMenu.style.display = "none"
      if (this._floatingPanel) this._floatingPanel.style.display = "none"
    }
  })
}
```

---

## State of the Art

| Old Approach | Current Approach | Notes |
|--------------|------------------|-------|
| `@tiptap/extension-floating-menu` + tippy.js | Light DOM 오버레이 + `editor.on("selectionUpdate")` | Shadow DOM 환경에서는 tippy 불필요. Phase 17 패턴 재사용 |
| 슬래시 커맨드 (`/` 입력) | FloatingMenu 기반 `+` 버튼 | STATE.md 결정: 슬래시 커맨드는 TipTap experimental, BLCK-01에서 FloatingMenu로 대체 |
| BubbleMenu로 표 컨텍스트 메뉴 | Light DOM 별도 요소 | Phase 17에서 확립된 패턴 |

**Deprecated/outdated:**
- `@tiptap/extension-floating-menu` 직접 사용: tippy.js 의존 + Shadow DOM 충돌 위험. 이 프로젝트에서 사용 금지.

---

## Open Questions

1. **`+` 버튼 위치 — 에디터 왼쪽 여백 vs 커서 인라인**
   - What we know: 에디터 좌측 여백에 배치하는 방식이 Notion 스타일. 에디터 DOM의 `getBoundingClientRect().left`로 계산 가능.
   - What's unclear: Admin 에디터의 실제 좌측 여백 크기. 패딩/마진에 따라 버튼이 에디터 텍스트 영역과 겹칠 수 있음.
   - Recommendation: 구현 후 Admin 폼에서 시각 확인. 버튼이 텍스트와 겹치면 `left` 값을 음수로 더 이동하거나, 에디터 컨테이너에 `padding-left`를 추가.

2. **서브 메뉴 패널 닫기 — 외부 클릭 처리**
   - What we know: 서브 메뉴 패널이 열린 상태에서 에디터 다른 부분을 클릭하면 `selectionUpdate`가 발생하고 `_isEmptyParagraph()`가 false를 반환하거나 `blur`가 발생하여 패널이 닫힘.
   - What's unclear: 서브 메뉴 열린 채로 에디터 외부를 클릭할 때의 동작.
   - Recommendation: `document.addEventListener("click")` 외부 클릭 감지를 추가하거나, `blur` 이벤트만으로도 충분할 수 있음. 구현 후 확인.

---

## Validation Architecture

### Test Framework

| Property | Value |
|----------|-------|
| Framework | 없음 (Phase 14-17과 동일 — 자동화 테스트 없음) |
| Config file | none |
| Quick run command | `cd teovibe && bin/vite build 2>&1 \| tail -3` |
| Full suite command | `cd teovibe && bin/rails test` |

### Phase Requirements → Test Map

| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|--------------|
| BLCK-01 | 빈 단락에 커서 → `+` 버튼 표시 | manual | Admin 폼 → 빈 줄 클릭 → `+` 버튼 확인 | N/A |
| BLCK-01 | 텍스트가 있는 줄 → `+` 버튼 없음 | manual | Admin 폼 → 텍스트 있는 줄 클릭 → 버튼 없음 확인 | N/A |
| BLCK-01 | `+` 클릭 → 4개 옵션 표시 (구분선/인용구/코드블록/표) | manual | `+` 클릭 → 서브 메뉴 패널 나타남 확인 | N/A |
| BLCK-01 | 각 옵션 선택 → 해당 블록 즉시 삽입 | manual | 각 항목 클릭 → 블록 삽입 확인 | N/A |
| BLCK-01 | 표 셀 내 빈 단락 → `+` 버튼 나타나지 않음 | manual | 표 안 빈 셀 클릭 → 버튼 없음 확인 | N/A |
| BLCK-01 | 삽입 후 저장 → 상세 페이지에서 올바르게 렌더링 | manual | 저장 → 상세 페이지 → 각 블록 타입 확인 | N/A |
| BLCK-01 | Vite 빌드 성공 | automated | `cd teovibe && bin/vite build 2>&1 \| tail -3` | ❌ Wave 0 |

### Sampling Rate

- **Per task commit:** `cd teovibe && bin/vite build 2>&1 | tail -3` (built in X.XXs 확인)
- **Per wave merge:** Admin 폼에서 수동 확인 — 빈 단락 `+` 버튼 + 4개 삽입 동작
- **Phase gate:** BLCK-01 success criteria 전부 수동 확인 후 Phase 완료 선언

### Wave 0 Gaps

- [ ] `teovibe/app/frontend/editor/admin_rhino_editor.js` — `_initFloatingMenu()`, `_updateFloatingMenu()`, `_isEmptyParagraph()`, `_handleFloatingMenuClick()` 메서드 추가 + `startEditor()` 업데이트 + `disconnectedCallback()` 정리 추가
- 패키지 설치 불필요 (신규 패키지 없음)

---

## Sources

### Primary (HIGH confidence)

- `@tiptap/extension-floating-menu@2.27.2/dist/index.cjs` (WebFetch로 직접 확인) — FloatingMenuView shouldShow 알고리즘 (`$anchor.depth === 1`, `isTextblock`, `childCount === 0`, `textContent === ""`)
- `teovibe/node_modules/rhino-editor/exports/chunks/chunk-4EN52UIW.js` — BubbleMenuView.shouldShow 로직 직접 확인 (`empty === true` → false 반환)
- `teovibe/node_modules/rhino-editor/exports/elements/tip-tap-editor.d.ts` — TipTapEditor API (`startEditor()`, `renderToolbarEnd()`) 직접 확인
- `teovibe/app/frontend/editor/admin_rhino_editor.js` — Phase 17 구현 완료 코드 직접 확인 (Light DOM 패턴, `coordsAtPos` 위치 계산)
- `pnpm info @tiptap/extension-floating-menu@2.27.2` — tippy.js `^6.3.7` 의존성 직접 확인
- `teovibe/node_modules/rhino-editor/exports/chunks/chunk-JV22V53Y.js:643,741` — `toggleBlockquote`, `toggleCodeBlock` 커맨드 직접 확인

### Secondary (MEDIUM confidence)

- `@tiptap/extension-floating-menu@2.27.2` peerDependencies — `@tiptap/pm@^2.7.0`, `@tiptap/core@^2.7.0` 만 요구 (tippy는 deps에 있음)

### Tertiary (LOW confidence — 검증 필요)

- `+` 버튼 위치 계산 (`editorRect.left - buttonSize - 8`) — 실제 Admin 에디터 여백에 따라 조정 필요. 구현 후 시각 확인.

---

## Metadata

**Confidence breakdown:**
- 빈 단락 감지 알고리즘: HIGH — TipTap 공식 FloatingMenu 소스에서 직접 확인
- Light DOM 오버레이 패턴: HIGH — Phase 17에서 동일 패턴 구현 완료, 사용자 브라우저 검증 완료
- 삽입 커맨드 (`setHorizontalRule`, `toggleBlockquote`, `toggleCodeBlock`, `insertTable`): HIGH — Phase 15/17에서 각각 검증됨
- `+` 버튼 좌측 배치 위치 계산: MEDIUM — `coordsAtPos` + `getBoundingClientRect` 패턴은 Phase 17에서 검증됨, 에디터 여백 값은 구현 후 확인 필요
- 신규 패키지 불필요: HIGH — tippy.js 의존성 있는 공식 extension 불가, 기존 커맨드로 충분함 확인

**Research date:** 2026-03-14
**Valid until:** 2026-04-14 (rhino-editor 0.17.x + @tiptap 2.27.x 안정)
