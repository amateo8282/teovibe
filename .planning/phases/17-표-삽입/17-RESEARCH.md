# Phase 17: 표 삽입 - Research

**Researched:** 2026-03-14
**Domain:** TipTap 2.27.2 Table extensions (4개 패키지) + rhino-editor BubbleMenu 아키텍처 + AdminRhinoEditor 확장 패턴
**Confidence:** HIGH

---

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|-----------------|
| TABL-01 | Table extension 설치 (table/row/cell/header 4개 패키지) | `@tiptap/extension-table@2.27.2`, `@tiptap/extension-table-row@2.27.2`, `@tiptap/extension-table-cell@2.27.2`, `@tiptap/extension-table-header@2.27.2` — 전부 v2.27.2 존재 확인. pnpm 설치 + Vite 빌드 성공 확인. `insertTable` 커맨드 포함. `@tiptap/pm`은 기존 pnpm 스토어에 이미 있어 peerDep 충족. ActionText 허용목록은 Phase 14에서 table/tr/th/td 등 이미 허용됨 |
| TABL-02 | 표 삽입 버튼 + 행/열 추가/삭제 컨텍스트 메뉴 | 툴바 삽입 버튼: `renderToolbarEnd()` override에 추가. 컨텍스트 메뉴: rhino-editor BubbleMenuPlugin은 텍스트 선택 시에만 동작 — 표 셀 내 커서는 `empty` selection이므로 기본 shouldShow가 false 반환. 별도 DOM 요소(shadow DOM 외부 `<div>`) + `editor.on("selectionUpdate")` 리스너로 커서 위치 감지 + 표시/숨김 토글 패턴을 사용한다 |
</phase_requirements>

---

## Summary

Phase 17은 Admin 에디터에 표 삽입과 행/열 관리 기능을 추가한다. 두 가지 문제를 해결해야 한다: (1) 4개 TipTap 표 extension 등록 및 툴바 삽입 버튼, (2) 표 셀 내에서 행/열 추가·삭제할 수 있는 컨텍스트 메뉴(버블 메뉴).

가장 중요한 발견은 **rhino-editor의 기존 BubbleMenu는 텍스트 선택 시에만 표시된다**는 점이다. 표 셀 안에 커서가 있는 상태(빈 선택)는 기존 `shouldShow` 로직에서 `empty === true`로 판단하여 false를 반환한다. 따라서 표 컨텍스트 메뉴는 **별도 DOM 요소**로 구현해야 하며, `editor.on("selectionUpdate")` + `editor.isActive("table")` 감지로 표시/숨김을 제어한다. rhino-editor shadow DOM 외부에 Light DOM `<div>` 요소를 렌더링하고, `editor.view.coordsAtPos(selection.$from.pos)`로 위치를 계산해 절대 좌표로 배치하는 방식이 가장 안정적이다.

ActionText 허용목록은 Phase 14에서 이미 `table`, `thead`, `tbody`, `tfoot`, `tr`, `th`, `td`, `colgroup`, `col`, `caption` 태그와 `colspan`, `rowspan`, `scope` 속성을 허용했다. **변경 불필요**. 표 extension이 출력하는 HTML은 전부 기존 허용목록으로 커버된다.

**Primary recommendation:** 4개 패키지(`@tiptap/extension-table@^2.27.2` 외 3개) — 이미 리서치 과정에서 설치 및 Vite 빌드 성공 확인됨. `admin_rhino_editor.js`에 Table/TableRow/TableCell/TableHeader extension 등록 + `insertTable` 툴바 버튼 + Light DOM 표 컨텍스트 메뉴 구현.

---

## Standard Stack

### Core (이미 설치됨)

| 라이브러리 | 버전 | 목적 | 상태 |
|------------|------|------|------|
| `rhino-editor` | 0.17.3 | TipTapEditor 서브클래스 베이스 | 설치됨 |
| `@tiptap/core` | 2.27.2 | TipTap 코어, Extension.create | 설치됨 |
| `@tiptap/pm` | 2.27.2 | ProseMirror 코어 (table extension peerDep) | 설치됨 (pnpm 스토어) |
| `lit` | 3.3.2 | Lit html 태그 템플릿 | 설치됨 |
| `@tiptap/extension-text-style` | 2.27.2 | Phase 16에서 설치됨 | 설치됨 |

### 신규 설치 완료 (리서치 중 설치 + Vite 빌드 확인)

| 라이브러리 | 버전 | 목적 | 비고 |
|------------|------|------|------|
| `@tiptap/extension-table` | 2.27.2 | Table 노드, 19개 커맨드 (insertTable, deleteTable 등) | TABL-01 |
| `@tiptap/extension-table-row` | 2.27.2 | TableRow 노드 | TABL-01 |
| `@tiptap/extension-table-cell` | 2.27.2 | TableCell 노드 (`<td>`) | TABL-01 |
| `@tiptap/extension-table-header` | 2.27.2 | TableHeader 노드 (`<th>`) | TABL-01 |

**PeerDependency 상태:**
- `@tiptap/extension-table`은 `@tiptap/pm@^2.7.0`과 `@tiptap/core@^2.7.0`을 peerDep으로 요구
- 두 패키지 모두 pnpm 스토어에 이미 v2.27.2로 있어 추가 설치 불필요
- pnpm transitive dep 문제 없음 (table extension은 직접 의존성으로 설치됨)

### Alternatives Considered

| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| Light DOM 표 컨텍스트 메뉴 | rhino-editor 기존 BubbleMenu shouldShow override | 기존 BubbleMenu는 empty selection을 차단. `shouldShow` override 가능하나 텍스트 선택 버블 메뉴와 공유 DOM이어서 두 메뉴를 구분하기 복잡. Light DOM 별도 요소가 훨씬 단순 |
| Light DOM 위치 계산 | TipTap 공식 BubbleMenu extension | TipTap 공식 BubbleMenu는 Tippy.js에 의존 (추가 설치 필요, rhino-editor와 충돌 가능). editor.on 리스너 패턴이 의존성 없이 동작 |
| `editor.on("selectionUpdate")` | ProseMirror Plugin | editor.on이 더 단순하고 TipTapEditor API에 맞음 |

**Installation (이미 완료됨):**
```bash
cd teovibe && pnpm add @tiptap/extension-table@^2.27.2 @tiptap/extension-table-row@^2.27.2 @tiptap/extension-table-cell@^2.27.2 @tiptap/extension-table-header@^2.27.2
```

---

## Architecture Patterns

### 파일 변경 목록

```
teovibe/
├── app/frontend/editor/
│   └── admin_rhino_editor.js     # [수정] Table 4종 extension 등록 + insertTable 버튼 + 표 컨텍스트 메뉴
├── package.json                   # [수정] 4개 패키지 추가 (이미 완료)
└── pnpm-lock.yaml                 # [수정] lockfile 업데이트 (이미 완료)
```

ActionText initializer(`config/initializers/action_text.rb`)는 **변경 불필요** — Phase 14에서 이미 table 관련 태그 전부 허용됨.

### Pattern 1: Table extension 4종 등록 (TABL-01)

**What:** TipTap 표 기능은 4개 extension이 함께 등록되어야 동작한다. Table이 노드 타입을 정의하고 TableRow/TableCell/TableHeader가 각각 행/일반셀/헤더셀을 담당한다.

```javascript
// Source: https://tiptap.dev/docs/editor/extensions/nodes/table (MEDIUM)
import Table from "@tiptap/extension-table"
import TableRow from "@tiptap/extension-table-row"
import TableCell from "@tiptap/extension-table-cell"
import TableHeader from "@tiptap/extension-table-header"

// connectedCallback에서 등록 (Phase 16 extension 아래에)
this.addExtensions(
  Table.configure({ resizable: false }),
  TableRow,
  TableCell,
  TableHeader
)
```

**Table.configure() 옵션:**
- `resizable: false` — Phase 17 범위. 열 너비 조절은 복잡한 drag 로직 필요, 미지원이 안전
- `allowTableNodeSelection: false` — 기본값. 표 전체 노드 선택 비활성화 (rhino-editor와 충돌 방지)

**출력 HTML:**
```html
<table>
  <tbody>
    <tr>
      <th>헤더</th>
      <th>헤더</th>
    </tr>
    <tr>
      <td>셀</td>
      <td>셀</td>
    </tr>
  </tbody>
</table>
```

ActionText allowed_tags에 이미 `table`, `tbody`, `tr`, `th`, `td` 포함 — 변경 불필요.

**탭 키 이동:** Table extension이 기본으로 `Tab`/`Shift+Tab` 키 핸들러를 내장한다. `goToNextCell()`/`goToPreviousCell()` 커맨드가 연결됨. 마지막 셀에서 Tab 누르면 새 행 자동 추가.

### Pattern 2: 표 삽입 툴바 버튼 (TABL-02)

**What:** renderToolbarEnd()에 "표 삽입" 버튼을 추가. `insertTable` 커맨드 사용.

```javascript
// Source: TipTap Table commands (HIGH — pnpm 설치 후 직접 확인)
renderInsertTableButton() {
  const isDisabled = this.editor == null || !this.editor.can().insertTable()
  return html`
    <button
      class="toolbar__button rhino-toolbar-button"
      type="button"
      tabindex="-1"
      data-role="toolbar-item"
      aria-disabled=${isDisabled}
      aria-label="표 삽입"
      title="표 삽입"
      @click=${() => {
        if (isDisabled) return
        this.editor?.chain().focus().insertTable({ rows: 3, cols: 3, withHeaderRow: true }).run()
      }}
    >
      &#8862;
    </button>
  `
}
```

**insertTable 파라미터:**
- `rows`: 행 수 (기본 3)
- `cols`: 열 수 (기본 3)
- `withHeaderRow`: true이면 첫 행이 `<th>` (헤더 행)

**renderToolbarEnd() 업데이트:**
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
    ${this.renderInsertTableButton()}
  `
}
```

### Pattern 3: 표 컨텍스트 메뉴 — Light DOM + selectionUpdate 리스너 (TABL-02)

**핵심 제약:** rhino-editor의 기존 `rhino-bubble-menu` extension은 `shouldShow` 기본 로직에서 `empty === true`(커서만 있고 선택 없는 상태)이면 false를 반환한다. 표 셀 안에 커서가 있는 상태는 empty selection이므로 기존 버블 메뉴를 활용할 수 없다.

**해결책: Light DOM 오버레이 + selectionUpdate 리스너**

AdminRhinoEditor는 Web Component(shadow DOM). Shadow DOM 외부에 Light DOM `<div>` 요소를 추가하고, `editor.on("selectionUpdate")` + `editor.on("blur")`로 표시/숨김을 제어한다.

```javascript
// connectedCallback에서 table extension 등록 후 컨텍스트 메뉴 초기화
connectedCallback() {
  super.connectedCallback()
  // ... 기존 extension 등록 ...
  this.addExtensions(
    Table.configure({ resizable: false }),
    TableRow,
    TableCell,
    TableHeader
  )
  // startEditor 완료 후 메뉴 초기화 (editor가 생성된 이후)
  this.updateComplete.then(() => {
    this._initTableContextMenu()
  })
}

_initTableContextMenu() {
  // Light DOM에 컨텍스트 메뉴 div 추가
  this._tableMenu = document.createElement("div")
  this._tableMenu.setAttribute("part", "table-context-menu")
  this._tableMenu.style.cssText = "position:absolute;z-index:100;display:none;background:white;border:1px solid #e5e7eb;border-radius:6px;box-shadow:0 2px 8px rgba(0,0,0,0.15);padding:4px;white-space:nowrap;"

  // 버튼 렌더링 (일반 DOM, Lit html 사용 안 함)
  this._tableMenu.innerHTML = `
    <button type="button" data-action="add-row-before" style="...">위에 행 추가</button>
    <button type="button" data-action="add-row-after" style="...">아래 행 추가</button>
    <button type="button" data-action="delete-row" style="...">행 삭제</button>
    <button type="button" data-action="add-col-before" style="...">왼쪽 열 추가</button>
    <button type="button" data-action="add-col-after" style="...">오른쪽 열 추가</button>
    <button type="button" data-action="delete-col" style="...">열 삭제</button>
    <button type="button" data-action="delete-table" style="...">표 삭제</button>
  `
  this._tableMenu.addEventListener("click", (e) => this._handleTableMenuClick(e))

  // 스크롤 컨테이너 또는 body에 추가 (absolute 포지셔닝)
  this.closest("form, .prose-editor-container") || document.body).appendChild(this._tableMenu)

  // editor 이벤트 리스너
  this.editor?.on("selectionUpdate", () => this._updateTableMenu())
  this.editor?.on("blur", () => { this._tableMenu.style.display = "none" })
}
```

**표 감지 + 위치 계산:**

```javascript
_updateTableMenu() {
  if (!this.editor || !this._tableMenu) return

  const isInTable = this.editor.isActive("table")
  if (!isInTable) {
    this._tableMenu.style.display = "none"
    return
  }

  // 커서 위치를 화면 좌표로 변환
  const { from } = this.editor.state.selection
  const coords = this.editor.view.coordsAtPos(from)

  // 메뉴를 커서 위에 표시
  const menuTop = coords.top + window.scrollY - this._tableMenu.offsetHeight - 8
  const menuLeft = coords.left + window.scrollX

  this._tableMenu.style.top = `${menuTop}px`
  this._tableMenu.style.left = `${menuLeft}px`
  this._tableMenu.style.display = "block"
}

_handleTableMenuClick(e) {
  const action = e.target.closest("[data-action]")?.getAttribute("data-action")
  if (!action || !this.editor) return

  e.preventDefault()

  const commands = {
    "add-row-before":  () => this.editor.chain().focus().addRowBefore().run(),
    "add-row-after":   () => this.editor.chain().focus().addRowAfter().run(),
    "delete-row":      () => this.editor.chain().focus().deleteRow().run(),
    "add-col-before":  () => this.editor.chain().focus().addColumnBefore().run(),
    "add-col-after":   () => this.editor.chain().focus().addColumnAfter().run(),
    "delete-col":      () => this.editor.chain().focus().deleteColumn().run(),
    "delete-table":    () => this.editor.chain().focus().deleteTable().run(),
  }
  commands[action]?.()
}
```

**중요: startEditor 완료 타이밍 처리**

rhino-editor의 `startEditor()`는 async이므로 `connectedCallback()`에서 `this.editor`가 null일 수 있다. `editor.on` 리스너는 editor 생성 후에만 등록 가능하다.

```javascript
// 방법 1: startEditor override
async startEditor() {
  await super.startEditor()
  // this.editor가 생성된 후에 리스너 등록
  this.editor?.on("selectionUpdate", () => this._updateTableMenu())
  this.editor?.on("blur", () => { if (this._tableMenu) this._tableMenu.style.display = "none" })
}
```

**기존 텍스트 선택 버블 메뉴와 충돌 방지:**

기존 rhino-editor BubbleMenu는 텍스트를 선택했을 때만 표시된다. 표 컨텍스트 메뉴는 `editor.isActive("table")`로만 제어된다. 두 메뉴는 서로 독립적인 DOM 요소이므로 자연적으로 충돌 없음. 단, 표 안에서 텍스트를 선택하면 두 메뉴가 동시에 표시될 수 있다 — 이 경우 표 컨텍스트 메뉴를 숨기는 것이 바람직하다.

```javascript
// selectionUpdate에서 비어있지 않은 selection이면 표 메뉴 숨김
_updateTableMenu() {
  if (!this.editor || !this._tableMenu) return

  const { empty } = this.editor.state.selection
  const isInTable = this.editor.isActive("table")

  // 텍스트가 선택된 경우 텍스트 버블 메뉴에게 양보
  if (!isInTable || !empty) {
    this._tableMenu.style.display = "none"
    return
  }

  // 커서만 있는 상태에서 표 안에 있을 때만 표시
  // ... 위치 계산 및 표시 ...
}
```

### Pattern 4: disconnectedCallback 정리

```javascript
disconnectedCallback() {
  super.disconnectedCallback()
  this._tableMenu?.remove()
  this._tableMenu = null
}
```

### Anti-Patterns to Avoid

- **Table extension 하나만 등록:** `Table` 단독 등록 시 TableRow/TableCell/TableHeader 노드 타입이 스키마에 없어 insertTable 커맨드가 실패. 4개 전부 등록 필수.
- **기존 BubbleMenu shouldShow 패치 시도:** rhino-editor StarterKit의 `rhinoBubbleMenu` 옵션은 `starterKitOptions`로 전달되는데, AdminRhinoEditor에서 override 시 타이밍 문제 발생 가능. Light DOM 별도 메뉴 접근이 훨씬 안정적.
- **Shadow DOM 안에 table context menu 렌더:** Lit의 `html` 태그를 사용해 shadow DOM에 메뉴를 넣으면 position:absolute가 shadow DOM 경계로 제한됨. Light DOM이 필요.
- **Table.configure({ resizable: true }):** drag handle 이벤트 핸들러가 추가되어 rhino-editor 내부 포인터 이벤트와 충돌 가능. Phase 17은 false 사용.
- **`can().insertTable()`로 disabled 체크 없이 클릭:** 표 안에서 또 표를 삽입하려 하면 insertTable이 실패. `aria-disabled` 체크 패턴 사용.
- **editor.on 리스너를 connectedCallback에서 등록:** `this.editor`는 `startEditor()` 비동기 완료 이후에만 non-null. connectedCallback에서 직접 등록하면 null 참조 오류.

---

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| 표 데이터 구조 + ProseMirror 스키마 | 커스텀 table Node extension | `@tiptap/extension-table` 4종 | CellSelection, fixTables, colspan/rowspan, 탭 키 이동 등 복잡한 edge case 내장. 30+개 ProseMirror plugin |
| 행 추가/삭제 로직 | 직접 tr/td DOM 조작 | `addRowBefore/After`, `deleteRow` 커맨드 | ProseMirror transaction으로 undo/redo 지원 자동 |
| 열 추가/삭제 로직 | 직접 td/colspan 계산 | `addColumnBefore/After`, `deleteColumn` 커맨드 | colspan/rowspan 병합된 셀의 열 추가/삭제는 직접 구현 불가 수준의 복잡도 |
| 탭 키 셀 이동 | keydown 핸들러 직접 구현 | Table extension 내장 | Tab/Shift+Tab 핸들러, 마지막 셀에서 새 행 추가까지 내장 |

---

## Common Pitfalls

### Pitfall 1: editor 생성 전 editor.on 등록

**What goes wrong:** `connectedCallback()`에서 `this.editor?.on("selectionUpdate", ...)` 호출 시 editor가 null이어서 리스너가 등록되지 않음.

**Why it happens:** rhino-editor의 `startEditor()`가 async. `connectedCallback()`은 동기적으로 실행되며 editor가 아직 생성되지 않은 상태.

**How to avoid:** `startEditor()`를 override해서 `await super.startEditor()` 이후에 리스너 등록:
```javascript
async startEditor() {
  await super.startEditor()
  this.editor?.on("selectionUpdate", () => this._updateTableMenu())
  this.editor?.on("blur", () => { if (this._tableMenu) this._tableMenu.style.display = "none" })
}
```

**Warning signs:** selectionUpdate 리스너가 전혀 실행되지 않음 (콘솔에 오류 없음).

### Pitfall 2: 표 컨텍스트 메뉴와 텍스트 버블 메뉴 동시 표시

**What goes wrong:** 표 안에서 텍스트를 선택하면 두 메뉴가 동시에 화면에 겹쳐 표시됨.

**Why it happens:** 표 컨텍스트 메뉴가 `isActive("table")`만 체크하면 텍스트 선택 상태에서도 표시됨.

**How to avoid:** `_updateTableMenu`에서 `!empty` 조건 추가:
```javascript
const { empty } = this.editor.state.selection
if (!isInTable || !empty) {
  this._tableMenu.style.display = "none"
  return
}
```

**Warning signs:** 표 안 텍스트 선택 시 두 개의 팝업이 동시에 나타남.

### Pitfall 3: Table extension 4개 중 일부 누락

**What goes wrong:** `insertTable` 커맨드가 TypeError를 던지거나 표가 렌더링되지 않음.

**Why it happens:** `@tiptap/extension-table`은 TableRow/TableCell/TableHeader 노드 타입을 스키마에 등록해야 동작한다. 누락 시 스키마 검증 실패.

**How to avoid:** 4개 전부 `addExtensions()` 한 번에 등록:
```javascript
this.addExtensions(
  Table.configure({ resizable: false }),
  TableRow,
  TableCell,
  TableHeader
)
```

**Warning signs:** 브라우저 콘솔에 `Unknown node type: tableRow` 스타일 오류.

### Pitfall 4: Light DOM 메뉴의 위치 계산 오차

**What goes wrong:** 표 컨텍스트 메뉴가 스크롤 위치를 고려하지 않아 잘못된 위치에 표시됨.

**Why it happens:** `coordsAtPos()`는 뷰포트 좌표를 반환. 페이지 스크롤 시 `window.scrollY`를 더해야 document 기준 좌표가 된다.

**How to avoid:**
```javascript
const menuTop = coords.top + window.scrollY - this._tableMenu.offsetHeight - 8
const menuLeft = coords.left + window.scrollX
```

**Warning signs:** 스크롤 후 메뉴가 에디터 위치와 다른 곳에 표시됨.

### Pitfall 5: disconnectedCallback 미정리로 메모리 누수

**What goes wrong:** 컴포넌트가 DOM에서 제거된 후에도 `_tableMenu` DOM 요소가 body에 남아있고, editor 이벤트 리스너가 계속 실행됨.

**How to avoid:**
```javascript
disconnectedCallback() {
  super.disconnectedCallback()
  this._tableMenu?.remove()
  this._tableMenu = null
}
```

### Pitfall 6: Phase 14 ActionText 허용목록 재확인

**What goes wrong:** 표 저장 후 상세 페이지에서 표 태그가 사라짐.

**Why it happens:** action_text.rb 허용목록 설정 누락 또는 initializer가 로드되지 않음.

**How to avoid (확인 커맨드):**
```bash
bin/rails runner "puts ActionText::ContentHelper.allowed_tags.include?('table') && ActionText::ContentHelper.allowed_tags.include?('td') && ActionText::ContentHelper.allowed_tags.include?('th')"
```

이 커맨드가 `true`를 출력해야 함. Phase 14에서 설정됨.

---

## Code Examples

### 전체 extension 등록 (Phase 17 추가 후)

```javascript
// Source: Phase 14/15/16에서 확립된 패턴 + Phase 17 신규 추가
import { TipTapEditor } from "rhino-editor/exports/elements/tip-tap-editor.js"
import Underline from "@tiptap/extension-underline"
import TextAlign from "@tiptap/extension-text-align"
import TextStyle from "@tiptap/extension-text-style"
import Color from "@tiptap/extension-color"
import Highlight from "@tiptap/extension-highlight"
import Table from "@tiptap/extension-table"
import TableRow from "@tiptap/extension-table-row"
import TableCell from "@tiptap/extension-table-cell"
import TableHeader from "@tiptap/extension-table-header"
import { FontSize } from "../editor/font_size_extension.js"
import { html } from "lit"

export class AdminRhinoEditor extends TipTapEditor {
  connectedCallback() {
    super.connectedCallback()
    this.addExtensions(Underline)
    this.addExtensions(TextAlign.configure({ types: ["heading", "paragraph"] }))
    this.addExtensions(TextStyle, Color, FontSize)
    this.addExtensions(Highlight.configure({ multicolor: true }))
    // Phase 17: Table extension 4종
    this.addExtensions(
      Table.configure({ resizable: false }),
      TableRow,
      TableCell,
      TableHeader
    )
  }

  async startEditor() {
    await super.startEditor()
    this._initTableContextMenu()
  }
  // ...
}
```

### Table 커맨드 전체 목록 (검증됨)

```javascript
// Source: pnpm install 후 node -e로 직접 확인 (HIGH)
// insertTable, addColumnBefore, addColumnAfter, deleteColumn,
// addRowBefore, addRowAfter, deleteRow, deleteTable,
// mergeCells, splitCell, toggleHeaderColumn, toggleHeaderRow,
// toggleHeaderCell, mergeOrSplit, setCellAttribute,
// goToNextCell, goToPreviousCell, fixTables, setCellSelection

this.editor?.chain().focus().insertTable({ rows: 3, cols: 3, withHeaderRow: true }).run()
this.editor?.chain().focus().addRowBefore().run()
this.editor?.chain().focus().addRowAfter().run()
this.editor?.chain().focus().deleteRow().run()
this.editor?.chain().focus().addColumnBefore().run()
this.editor?.chain().focus().addColumnAfter().run()
this.editor?.chain().focus().deleteColumn().run()
this.editor?.chain().focus().deleteTable().run()
```

### ActionText 허용목록 확인 (변경 불필요)

```bash
# Phase 14에서 이미 추가됨 — 변경 없음을 확인
bin/rails runner "
  tags = ActionText::ContentHelper.allowed_tags
  attrs = ActionText::ContentHelper.allowed_attributes
  puts tags.include?('table')     # true
  puts tags.include?('tr')        # true
  puts tags.include?('td')        # true
  puts tags.include?('th')        # true
  puts attrs.include?('colspan')  # true
  puts attrs.include?('rowspan')  # true
"
```

---

## State of the Art

| Old Approach | Current Approach | Notes |
|--------------|------------------|-------|
| Trix (표 미지원) | `@tiptap/extension-table` 4종 | Phase 17에서 추가 |
| BubbleMenu shouldShow 공유 | Light DOM 별도 요소 + editor.on 리스너 | 표 컨텍스트 메뉴는 empty selection이므로 별도 접근 필요 |
| Table.configure({ resizable: true }) | Table.configure({ resizable: false }) | resizable은 Phase 17 범위 밖. drag handle 이벤트 충돌 방지 |

**Deprecated/outdated:**
- TipTap 공식 BubbleMenu extension (`@tiptap/extension-bubble-menu`): Tippy.js 의존성 필요. rhino-editor가 이미 자체 BubbleMenu 구현 사용 — 충돌 가능성 높음. 사용 금지.

---

## Open Questions

1. **표 컨텍스트 메뉴 트리거 방식 — 커서 자동 표시 vs 아이콘 클릭**
   - What we know: 커서가 표 안에 있을 때 자동으로 팝업 표시하는 방식이 UX가 좋으나, 화면 공간을 차지함.
   - What's unclear: 사용자 선호 UX.
   - Recommendation: `selectionUpdate` 리스너로 표 안에서 자동 표시. 표 밖 클릭 시 자동 숨김. 구현이 단순하고 네이버 블로그와 유사한 UX.

2. **표 컨텍스트 메뉴 위치 — 커서 위 vs 표 상단 고정**
   - What we know: `coordsAtPos(from)` 사용 시 커서 근처에 표시. `this.editor.view.dom.querySelector("table")?.getBoundingClientRect()`로 표 상단에 고정도 가능.
   - What's unclear: 표가 길어질 때 메뉴가 화면 위로 밀려나는지.
   - Recommendation: 커서 위치 기준 (`coordsAtPos`). 메뉴가 뷰포트 상단을 넘으면 커서 아래로 fallback 처리.

3. **표 안 텍스트에 스타일 적용 가능 여부**
   - What we know: TipTap의 TextStyle/Color/FontSize extension은 `paragraph` + `textStyle` mark 위에서 동작. 표 셀 (`<td>`, `<th>`)은 ProseMirror에서 block node이며 내부에 paragraph를 포함.
   - What's unclear: 표 셀 내 텍스트에 Phase 16에서 추가한 스타일이 그대로 동작하는지.
   - Recommendation: 구현 후 Admin 폼에서 확인 checkpoint 추가. TextAlign.configure의 `types`에 "tableCell", "tableHeader"가 필요할 수 있음.

---

## Validation Architecture

### Test Framework

| Property | Value |
|----------|-------|
| Framework | 없음 (Phase 14/15/16과 동일 — 자동화 테스트 없음) |
| Config file | none |
| Quick run command | `cd teovibe && bin/vite build 2>&1 | tail -3` |
| Full suite command | `cd teovibe && bin/rails test` |

### Phase Requirements → Test Map

| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|--------------|
| TABL-01 | 4개 table extension 등록 + Vite 빌드 성공 | automated | `cd teovibe && bin/vite build 2>&1 | tail -3` | ❌ (빌드 성공으로 대체) |
| TABL-01 | ActionText allowed_tags에 table/td/th 포함 | automated | `bin/rails runner "puts ActionText::ContentHelper.allowed_tags.include?('table')"` | ❌ Wave 0 |
| TABL-02 | 툴바 버튼 클릭으로 3x3 표 삽입, 탭 키로 셀 이동 | manual | Admin 폼 → 표 삽입 버튼 → 표 생성 확인 → Tab 키 이동 확인 | N/A (manual) |
| TABL-02 | 표 셀 클릭 후 컨텍스트 메뉴 표시 → 행/열 추가/삭제 동작 | manual | Admin 폼 → 표 셀 클릭 → 메뉴 표시 확인 → 각 버튼 동작 확인 | N/A (manual) |
| TABL-02 | 저장 후 상세 페이지에서 표 구조/내용 올바르게 렌더링 | manual | 저장 → 상세 페이지 → `<table>` DOM 구조 확인 | N/A (manual) |
| TABL-02 | 텍스트 선택 버블 메뉴와 표 컨텍스트 메뉴 충돌 없음 | manual | 표 안 텍스트 선택 → 텍스트 버블 메뉴만 표시, 표 메뉴 숨김 확인 | N/A (manual) |

ActionText smoke test:
```bash
bin/rails runner "
  puts ActionText::ContentHelper.allowed_tags.include?('table')   # true
  puts ActionText::ContentHelper.allowed_tags.include?('td')      # true
  puts ActionText::ContentHelper.allowed_tags.include?('th')      # true
  puts ActionText::ContentHelper.allowed_attributes.include?('colspan') # true
"
```

### Sampling Rate

- **Per task commit:** `cd teovibe && bin/vite build 2>&1 | tail -3` (built in X.XXs 확인) + ActionText smoke test
- **Per wave merge:** Admin 폼에서 수동 확인 — 표 삽입/탭 이동/행열 추가삭제/저장 후 렌더링
- **Phase gate:** TABL-01, TABL-02 success criteria 전부 수동 확인 후 Phase 18 진입

### Wave 0 Gaps

- [ ] 패키지 설치: `@tiptap/extension-table@^2.27.2` 외 3개 — **리서치 중 이미 설치 완료** (pnpm-lock.yaml 업데이트됨)
- [ ] `teovibe/app/frontend/editor/admin_rhino_editor.js` — Table 4종 extension 등록 + renderInsertTableButton() + _initTableContextMenu() (기존 파일 수정)

---

## Sources

### Primary (HIGH confidence)

- `pnpm add @tiptap/extension-table@^2.27.2` 외 3개 — v2.27.2 설치 성공 직접 확인
- `node -e "require('.../extension-table/dist/index.cjs')"` — 19개 커맨드 직접 확인 (`insertTable`, `addRowBefore`, `addRowAfter`, `deleteRow`, `addColumnBefore`, `addColumnAfter`, `deleteColumn`, `deleteTable` 등)
- `cd teovibe && bin/vite build` — 4개 패키지 설치 후 빌드 성공 확인 (4.95s)
- `teovibe/node_modules/rhino-editor/exports/chunks/chunk-4EN52UIW.js` — BubbleMenuView.shouldShow 기본 로직 직접 확인 (`empty === true` → false 반환)
- `teovibe/node_modules/rhino-editor/exports/chunks/chunk-7E7MURG2.js` — RhinoStarterKit에서 BubbleMenuExtension이 `rhinoBubbleMenu`로 등록됨 직접 확인
- `teovibe/node_modules/rhino-editor/exports/chunks/chunk-JV22V53Y.js:250` — `rhinoBubbleMenu.element = this.shadowRoot.querySelector("role-anchored-region")` 직접 확인
- `teovibe/node_modules/rhino-editor/exports/elements/tip-tap-editor.d.ts` — `renderBubbleMenuToolbar()`, `startEditor()` API 직접 확인
- `teovibe/config/initializers/action_text.rb` — Phase 14에서 table/tr/th/td/thead/tbody/tfoot/colgroup/col/caption + colspan/rowspan/scope 허용 확인
- `pnpm view @tiptap/extension-table@2.27.2 peerDependencies` — `@tiptap/pm@^2.7.0`, `@tiptap/core@^2.7.0` peerDep 확인 (둘 다 기존 스토어에 있음)

### Secondary (MEDIUM confidence)

- [TipTap Table Docs](https://tiptap.dev/docs/editor/extensions/nodes/table) — Table 커맨드 목록, insertTable 파라미터

### Tertiary (LOW confidence — 검증 필요)

- Light DOM + `coordsAtPos()` 위치 계산 패턴 (일반적인 TipTap 커뮤니티 패턴, 단일 소스)

---

## Metadata

**Confidence breakdown:**
- TABL-01 (table extension 4종): HIGH — v2.27.2 설치 성공, Vite 빌드 확인, 커맨드 직접 확인
- TABL-02 (툴바 버튼): HIGH — insertTable 커맨드 확인, renderToolbarEnd 패턴 Phase 15-16에서 검증됨
- TABL-02 (컨텍스트 메뉴): MEDIUM — BubbleMenu shouldShow 로직 직접 확인, Light DOM 접근법은 TipTap 커뮤니티 패턴(단일 소스), 실제 동작은 구현 후 확인 필요
- ActionText 변경 불필요: HIGH — action_text.rb 직접 확인, table 태그 전부 허용됨
- 텍스트/표 버블 메뉴 충돌 없음: MEDIUM — empty selection 로직 확인됨, 실제 동작은 구현 후 checkpoint 필요

**Research date:** 2026-03-14
**Valid until:** 2026-04-14 (rhino-editor 0.17.x + @tiptap 2.27.x 안정)
