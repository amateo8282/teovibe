# Pitfalls Research

**Domain:** TipTap extension integration via rhino-editor 0.17.x (Rails 8 + ActionText + Hotwire/Turbo)
**Researched:** 2026-03-14
**Confidence:** HIGH (rhino-editor source code + ActionText source code 직접 확인, TipTap 공식 문서 확인)

> Note: 이 파일은 v1.3 마일스톤 전용 연구다. "rhino-editor에 TipTap extension을 추가할 때 흔히 발생하는 실수"에 집중한다.
> 핵심 전제: rhino-editor는 TipTap을 감싸는 Lit 기반 Web Component다.
> `TipTapEditor`를 직접 인스턴스화하지 않고 `<rhino-editor>` DOM 엘리먼트의 API를 통해 확장해야 한다.
>
> 코드베이스 확인 사항:
> - `application.js`에서 `import "rhino-editor"` — `TipTapEditor.define()` 자동 호출됨
> - rhino-editor 0.17.3이 `@tiptap/starter-kit` + `RhinoStarterKit` 두 개를 함께 사용
> - `strike: false`가 기본 starterKitOptions (rhinoStrike 대신 TipTap 기본 strike 비활성화)
> - ActionText는 rails-html-sanitizer 1.6.2 사용 — `style` 속성 기본 차단

---

## Critical Pitfalls

### Pitfall 1: TipTap StarterKit 내장 extension 중복 등록

**What goes wrong:**
`@tiptap/starter-kit`에 이미 포함된 extension을 `addExtensions()`로 추가하면 TipTap이 "Duplicate extension names found" 경고를 내보내고, 에디터가 오작동하거나 특정 extension이 완전히 비활성화된다. 예를 들어 `CodeBlockLowlight`를 추가하면서 기존 `codeBlock`을 비활성화하지 않으면 두 codeBlock extension이 공존하여 코드 블록 입력 자체가 깨진다.

rhino-editor 0.17.x의 기본 extension 구성:
- **StarterKit 포함**: blockquote, bold, bulletList, code, codeBlock, document, dropcursor, gapcursor, hardBreak, heading, history, horizontalRule, italic, listItem, orderedList, paragraph, strike, text
- **RhinoStarterKit 추가**: rhinoStrike (`<del>` 태그), rhinoGallery, rhinoAttachment, rhinoLink, rhinoCodemarkPlugin, rhinoPlaceholder, increaseIndentation, decreaseIndentation

**Why it happens:**
TipTap 공식 extension 문서를 보고 단순히 `addExtensions(CodeBlockLowlight)`를 호출하면, StarterKit의 `codeBlock`이 여전히 활성화된 상태로 두 extension이 동일한 이름 `codeBlock`을 등록하게 된다.

**How to avoid:**
extension을 추가하기 전에 반드시 기존 StarterKit 항목을 비활성화한다. rhino-editor 전용 방식은 `starterKitOptions`를 수정하는 것이다:

```javascript
// rhino-before-initialize 이벤트에서 처리
document.addEventListener("rhino-before-initialize", (event) => {
  const rhinoEditor = event.target
  // 1. StarterKit의 codeBlock 비활성화
  rhinoEditor.starterKitOptions = {
    ...rhinoEditor.starterKitOptions,
    codeBlock: false
  }
  // 2. 대체 extension 추가
  rhinoEditor.addExtensions(
    CodeBlockLowlight.configure({ lowlight })
  )
})
```

비활성화 가능한 항목: `blockquote`, `bold`, `bulletList`, `code`, `codeBlock`, `document`, `dropcursor`, `gapcursor`, `hardBreak`, `heading`, `history`, `horizontalRule`, `italic`, `listItem`, `orderedList`, `paragraph`, `strike`, `text`
RhinoStarterKit 항목 비활성화: `rhinoStrike`, `rhinoGallery`, `rhinoAttachment`, `rhinoLink`, `rhinoCodemarkPlugin`

**Warning signs:**
- 브라우저 콘솔에 `[tiptap warn]: Duplicate extension names found` 경고 출력
- 코드 블록 입력 후 두 가지 스타일이 번갈아 적용됨
- 특정 단축키가 작동하지 않거나 예상과 다른 extension을 호출함

**Phase to address:**
각 extension 추가 Phase 첫 번째 단계. CodeBlockLowlight 추가 시 Phase 최우선 처리.

---

### Pitfall 2: ActionText HTML 저장 시 style 속성 자동 삭제

**What goes wrong:**
TipTap의 Color extension, Highlight extension, TextAlign extension은 모두 인라인 `style` 속성 또는 HTML 속성을 사용한다:
- Color: `<span style="color: #FF0000">`
- Highlight: `<mark style="background-color: #FFFF00">`
- TextAlign: `<p style="text-align: center">`

ActionText가 `render_action_text_content`를 통해 저장된 HTML을 렌더링할 때, rails-html-sanitizer(1.6.2)의 기본 `DEFAULT_ALLOWED_ATTRIBUTES`에 `style`이 없으므로 모든 style 속성이 삭제된다. 에디터에서 색상/정렬을 적용해 저장해도 화면 출력 시 모두 제거된다.

실제 `DEFAULT_ALLOWED_ATTRIBUTES` (rails-html-sanitizer 1.6.2):
```
abbr, alt, cite, class, datetime, height, href, lang, name, src, title, width, xml:lang
```
`style`, `color`, `data-text-align`, `align` 모두 없음.

**Why it happens:**
ActionText는 저장 시가 아니라 렌더링 시 sanitize한다. `@post.body = "<p style='color:red'>test</p>"`는 DB에 저장되지만, `<%= @post.body %>`로 화면에 출력할 때 `<p>test</p>`가 된다. 개발 중에는 에디터에서 색이 보이지만(에디터는 sanitize 안 함), 저장 후 상세 페이지에서는 색이 사라져 버그처럼 보인다.

**How to avoid:**
`config/initializers/action_text.rb`를 생성하여 필요한 속성을 허용한다:

```ruby
# config/initializers/action_text.rb
Rails.application.config.after_initialize do
  ActionText::ContentHelper.allowed_attributes += ["style"]
  # 또는 더 안전한 방식: style 속성 범위를 좁히려면 커스텀 scrubber 작성
end
```

보안 주의: `style` 전체를 허용하면 `expression()`, `javascript:`, `-moz-binding` 등 CSS 인젝션 위험이 있다. Admin 전용 에디터이므로 신뢰된 사용자만 접근한다면 허용 가능하나, 일반 사용자 에디터(`posts/_form.html.erb`)에 동일 설정을 적용하면 XSS 위험이 증가한다. 일반 사용자 에디터와 Admin 에디터를 별도 initializer 또는 scrubber로 분리 처리하는 것이 이상적이다.

TextAlign의 경우 `style="text-align: center"` 대신 class 기반으로 구현하는 대안도 있다:
```javascript
TextAlign.configure({
  types: ['heading', 'paragraph'],
  // class 방식: style 대신 data 속성 사용
})
```
하지만 TipTap 공식 TextAlign extension은 style 방식만 지원하므로, class 방식은 custom extension이 필요하다.

**Warning signs:**
- 에디터에서 색상 적용 후 저장 → 상세 페이지에서 색상 사라짐
- 에디터와 뷰어의 렌더링 결과가 다름
- `@post.body.to_s`에 `style`이 없지만 에디터 재로드 시에는 style이 있음 (저장은 되지만 렌더링 시 제거)

**Phase to address:**
색상/배경색 Phase 시작 전. `action_text.rb` initializer 생성을 첫 번째 태스크로 처리.

---

### Pitfall 3: Table extension 사용 시 ActionText allowed_tags 미등록으로 표 삭제

**What goes wrong:**
TipTap Table extension은 `<table>`, `<thead>`, `<tbody>`, `<tfoot>`, `<tr>`, `<th>`, `<td>`, `<colgroup>`, `<col>` 태그를 사용한다. 이 태그들은 rails-html-sanitizer의 `DEFAULT_ALLOWED_TAGS`에 포함되어 있지 않아 저장된 표가 렌더링 시 완전히 삭제된다.

```
DEFAULT_ALLOWED_TAGS에 없는 Table 관련 태그:
table, thead, tbody, tfoot, tr, th, td, colgroup, col
```

추가로 TipTap Table은 `colspan`, `rowspan` 속성을 사용하는데, 이것도 `DEFAULT_ALLOWED_ATTRIBUTES`에 없다.

**Why it happens:**
Pitfall 2와 동일한 구조. 에디터에서는 보이지만 저장 후 렌더링 시 사라진다. 서버 재시작 없이 initializer를 추가해도 효과 없음 — ActionText sanitizer는 싱글톤이라 서버 시작 시 한 번만 초기화된다.

**How to avoid:**
`config/initializers/action_text.rb`에 table 태그와 속성 추가:

```ruby
Rails.application.config.after_initialize do
  # Table 태그 허용
  ActionText::ContentHelper.allowed_tags += [
    "table", "thead", "tbody", "tfoot", "tr", "th", "td", "colgroup", "col"
  ]

  # Table 속성 허용
  ActionText::ContentHelper.allowed_attributes += [
    "colspan", "rowspan", "scope", "style"
  ]
end
```

변경 후 반드시 서버 재시작 필요. Heroku/Kamal 환경에서 재배포 필요.

**Warning signs:**
- 에디터에서 표 삽입 후 저장 → 상세 페이지에서 표가 완전히 사라짐
- `@post.body.to_s`에 `<table>` 태그 없음
- 개발 서버에서 initializer 수정 후 서버 재시작 없이 테스트하면 변경 효과 없음

**Phase to address:**
Table 삽입 Phase 시작 전. `action_text.rb` initializer에 style 허용과 함께 통합 처리.

---

### Pitfall 4: addExtensions() 중복 호출로 extension 중복 등록

**What goes wrong:**
`rhino-before-initialize` 이벤트 리스너를 `document.addEventListener`로 등록할 때, Turbo Drive 페이지 이동으로 동일한 페이지를 재방문하면 이벤트 리스너가 누적되어 `addExtensions()`가 여러 번 호출된다. rhino-editor 0.17.3의 `addExtensions()` 구현은 이름 기반 중복 체크를 수행하지만, 리스너 자체가 중복으로 쌓이면 불필요한 rebuildEditor() 호출이 반복된다.

```javascript
// 코드 내부 동작 (chunk-2NB236ZC.js 584행):
addExtensions(...extensions) {
  const existingExtensions = this.extensions.map(ext => ext.name)
  ary = ary.filter(ext => !existingExtensions.includes(ext.name)) // 중복 필터 존재
  this.extensions = this.extensions.concat(ary)  // 배열 할당 → willUpdate 트리거
}
```

단순 중복 extension 추가는 내부 필터로 방지되지만, `starterKitOptions` 재할당 자체가 `rebuildEditor()`를 트리거한다.

**Why it happens:**
Turbo Drive는 페이지 이동 시 `<script>` 태그를 재실행하지 않지만, custom element의 `connectedCallback`은 매번 호출된다. `document.addEventListener`로 등록한 리스너는 페이지 이동 후에도 유지되며, 새 페이지에서 또 등록되면 동일 이벤트에 복수 리스너가 달린다.

**How to avoid:**
방법 1 — Stimulus 컨트롤러 사용 (권장):
```javascript
// app/frontend/controllers/rhino_extensions_controller.js
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  connect() {
    this.element.addEventListener("rhino-before-initialize", this.extendEditor)
  }
  disconnect() {
    this.element.removeEventListener("rhino-before-initialize", this.extendEditor)
  }
  extendEditor = (event) => {
    const rhinoEditor = event.target
    rhinoEditor.addExtensions(/* extensions */)
  }
}
```

방법 2 — `{ once: true }` 옵션 사용 (일회성이면):
```javascript
document.addEventListener("rhino-before-initialize", handler, { once: true })
```

방법 3 — TipTapEditor 서브클래스 정의 (전역 확장 시):
```javascript
import { TipTapEditor } from "rhino-editor/exports/elements/tip-tap-editor.js"
class EnhancedEditor extends TipTapEditor {
  constructor() {
    super()
    this.extensions = [...this.extensions, MyExtension]
  }
}
EnhancedEditor.define("rhino-editor")  // 기존 등록명 override
```

**Warning signs:**
- Turbo 이동 후 에디터가 여러 번 rebuild되며 콘솔에 반복 경고 출력
- 페이지를 여러 번 방문할수록 에디터 초기화 시간이 길어짐
- `document.addEventListener` 호출이 `application.js` 최상위에 위치하는 경우

**Phase to address:**
Stimulus 컨트롤러 방식을 표준 패턴으로 채택. extension 추가 Phase 초반에 아키텍처 결정.

---

### Pitfall 5: toolbar 슬롯 커스텀 버튼에서 타입 누락으로 폼 submit 트리거

**What goes wrong:**
rhino-editor의 toolbar 커스텀 버튼에 `type="button"`을 생략하면, 버튼의 기본 타입이 `submit`이 되어 클릭 시 폼이 전송된다. Admin 글쓰기 폼에서 툴바 버튼을 클릭할 때마다 글이 저장되거나 페이지가 이동한다.

**Why it happens:**
rhino-editor는 HTML 슬롯 방식으로 커스텀 버튼을 삽입한다. `<rhino-editor>` 엘리먼트가 `<form>` 내부에 있으므로, `type` 속성이 없는 버튼은 폼의 submit 버튼으로 동작한다.

공식 문서에서 요구하는 필수 속성:
- `type="button"` — 폼 submit 방지 (가장 중요)
- `slot="[위치명]"` — 슬롯 배치
- `class="rhino-toolbar-button"` — 스타일 통일
- `data-role="toolbar-item"` — 툴바 포커스 관리
- `tabindex="-1"` — 키보드 내비게이션

**How to avoid:**
```html
<rhino-editor input="post_body">
  <!-- 필수: type="button" 없으면 폼 submit됨 -->
  <button
    type="button"
    slot="before-bold-button"
    class="rhino-toolbar-button"
    data-role="toolbar-item"
    tabindex="-1"
    data-action="click->rhino-extensions#insertTable"
  >
    표 삽입
  </button>
</rhino-editor>
```

**Warning signs:**
- 툴바 버튼 클릭 시 폼이 제출되며 페이지 이동 발생
- 개발자 도구 Network 탭에서 버튼 클릭 시 POST 요청 발생
- 버튼에 `type` 속성이 없는 경우 (HTML 검사로 즉시 확인 가능)

**Phase to address:**
커스텀 툴바 버튼 추가 Phase. 첫 번째 커스텀 버튼 구현 전에 체크리스트화.

---

### Pitfall 6: rhinoStrike와 TipTap Strike 혼용으로 `<del>` / `<s>` 태그 불일치

**What goes wrong:**
rhino-editor 0.17.3은 기본적으로 `strike: false`(StarterKit의 `<s>` 기반 strike 비활성화)를 설정하고, 대신 `rhinoStrike`(`<del>` 태그 기반)를 사용한다. ActionText는 `<del>` 태그를 `DEFAULT_ALLOWED_TAGS`에 포함하고 있다. 그런데 `Underline` extension을 추가하면서 실수로 `rhinoStrike`도 비활성화하거나, 반대로 `strike: true`로 복원하면 저장된 기존 `<del>` 콘텐츠와 새 `<s>` 콘텐츠가 혼재하게 된다.

`<del>`은 기본 허용되지만 `<s>`는 `DEFAULT_ALLOWED_TAGS`에 없어 렌더링 시 삭제된다.

**Why it happens:**
`disableStarterKitOptions` 또는 `starterKitOptions` 수정 시, 이미 기본값이 `strike: false`임을 모르고 `strike: true`로 복원하는 실수.

**How to avoid:**
취소선 기능 수정 시 현재 기본값을 먼저 확인한다:
- 기본값: `strike: false`, `rhinoStrike` 활성 → `<del>` 태그 생성 → ActionText 허용
- `strike: true`로 변경 시: `<s>` 태그 생성 → ActionText 기본 차단 → 렌더링 삭제

취소선을 커스터마이즈할 때는 `rhinoStrike`를 유지하거나, `strike: true`로 변경 시 `allowed_tags += ["s"]` 추가.

**Warning signs:**
- 취소선 텍스트가 에디터에서는 보이지만 저장 후 사라짐
- HTML 검사 시 `<s>` 태그가 저장됐지만 `to_s` 출력에는 없음

**Phase to address:**
취소선/밑줄 서식 확장 Phase. 기본 동작 변경 전 확인.

---

### Pitfall 7: Turbo Drive 캐시에서 rhino-editor가 stale 상태로 복원

**What goes wrong:**
Turbo Drive는 페이지 이동 시 현재 페이지의 스냅샷을 캐시한다. 뒤로 가기로 돌아오면 캐시된 스냅샷을 먼저 보여주고, 새 요청 결과로 교체한다. rhino-editor(Lit 기반 Web Component)의 Shadow DOM 내부 상태(에디터 내용, 포커스 상태)는 캐시 스냅샷과 실제 DOM이 불일치할 수 있다.

특히 `defer-initialize` 속성이 없는 경우, 캐시에서 복원된 rhino-editor가 이미 초기화된 상태에서 `connectedCallback`을 다시 호출하여 에디터 내용이 초기화되는 현상이 발생한다.

**Why it happens:**
Lit Web Component는 `connectedCallback` / `disconnectedCallback`을 Turbo의 페이지 이동과 독립적으로 처리한다. Turbo의 `turbo:before-cache` 이벤트 시점에 에디터 상태를 저장하지 않으면, 캐시 스냅샷에는 현재 에디터 DOM이 그대로 담기지만 내부 TipTap 인스턴스는 소멸된다.

**How to avoid:**
방법 1 — 편집 페이지 캐시 비활성화:
```html
<!-- layouts/admin.html.erb 또는 편집 뷰 -->
<meta name="turbo-cache-control" content="no-cache">
```

방법 2 — `turbo:before-cache` 이벤트로 에디터 정리:
```javascript
document.addEventListener("turbo:before-cache", () => {
  document.querySelectorAll("rhino-editor").forEach(el => {
    el.editor?.destroy()
  })
})
```

방법 3 — Turbo를 에디터 폼에서만 비활성화:
```html
<form data-turbo="false">
  <!-- 에디터 폼 -->
</form>
```

**Warning signs:**
- 뒤로 가기 후 에디터 내용이 초기화되거나 비어있음
- 콘솔에 "Cannot read properties of undefined (reading 'chain')" 류의 에러 (TipTap 인스턴스 소멸 후 접근)
- 에디터가 표시되지만 타이핑이 불가능한 상태

**Phase to address:**
모든 extension 추가 Phase와 독립적으로, 에디터 페이지에 `no-cache` 메타태그를 초반에 추가.

---

### Pitfall 8: TipTap Table + Heading extension이 빈 `<p>` 태그를 생성하는 ProseMirror 스키마 충돌

**What goes wrong:**
TipTap Table extension은 `tableRow`, `tableCell`, `tableHeader`를 별도 Node로 등록하며, 이 Node들의 content schema는 `block+`(한 개 이상의 block 노드)를 요구한다. Heading extension과 함께 사용할 때, 표 안에서 제목을 입력하면 ProseMirror가 스키마 유효성을 맞추기 위해 빈 `<p>` 노드를 자동 삽입하는 경우가 있다.

더 심각한 경우: Heading extension이 `levels: [1, 2, 3]`을 기본으로 사용하는데, rhino-editor의 StarterKit도 이미 `heading`을 포함한다. Heading을 `disableStarterKitOptions("heading")`으로 비활성화하지 않고 별도 Heading extension을 추가하면 Pitfall 1의 중복 등록이 발생한다.

**Why it happens:**
TipTap 제공 Heading extension은 StarterKit에 이미 포함되어 있다. 레벨(H1~H3)만 조정하려면 별도 extension 추가가 아니라 `starterKitOptions` 설정으로 처리해야 한다.

**How to avoid:**
제목 레벨 드롭다운 구현 시:
```javascript
// 별도 Heading extension 추가가 아니라 StarterKit 옵션 설정
rhinoEditor.starterKitOptions = {
  ...rhinoEditor.starterKitOptions,
  heading: { levels: [1, 2, 3] }  // levels 제한
}
// addExtensions(Heading.configure(...))는 사용하지 않음 — 중복 등록
```

Table extension은 공식 `@tiptap/extension-table`, `@tiptap/extension-table-row`, `@tiptap/extension-table-cell`, `@tiptap/extension-table-header` 4개를 함께 설치해야 한다. 누락 시 스키마 오류 발생.

**Warning signs:**
- 표 안에 제목 입력 후 저장 → 빈 `<p>` 태그가 포함된 HTML 생성
- H1/H2 적용 시 헤딩이 중복으로 감싸지는 현상
- 표 관련 패키지 일부 누락 시 "Unknown node type" 에러

**Phase to address:**
Table 삽입 Phase. 제목 드롭다운 Phase에서 starterKitOptions heading 설정 방식 채택 강제.

---

## Technical Debt Patterns

| Shortcut | Immediate Benefit | Long-term Cost | When Acceptable |
|----------|-------------------|----------------|-----------------|
| `ActionText::ContentHelper.allowed_attributes += ["style"]` 전역 설정 | 구현 단순 | 일반 사용자 에디터에도 적용되어 CSS 인젝션 위험 | Admin 전용 에디터만 있는 동안. 일반 사용자 에디터 도입 전에 분리 처리 필요 |
| `rhino-before-initialize`를 `document.addEventListener`로 등록 | 구현 단순 | Turbo 이동으로 리스너 누적, 잠재적 메모리 누수 | 절대 권장 안 됨. Stimulus 컨트롤러 방식 사용 |
| 표 스타일을 ActionText 이후 CSS로 처리 (allowed_tags 미등록) | ActionText 변경 불필요 | 표 콘텐츠가 DB에 저장되지만 렌더링 시 삭제됨 | 절대 허용 안 됨 |
| `no-cache` 메타태그로 에디터 페이지 캐시 전체 비활성화 | 에디터 stale 문제 완전 해결 | Turbo Drive 뒤로 가기 성능 저하 | Admin 에디터 페이지는 캐시 불필요, 허용 가능 |
| Stimulus 컨트롤러 대신 인라인 `<script>` 태그로 addExtensions | 빠른 구현 | Turbo 캐시와의 충돌, 리스너 관리 어려움 | 절대 권장 안 됨 |

---

## Integration Gotchas

| Integration | Common Mistake | Correct Approach |
|-------------|----------------|------------------|
| rhino-editor + Color extension | `allowed_attributes += ["style"]` 없이 배포 | `config/initializers/action_text.rb`에 style 속성 추가, 서버 재시작 |
| rhino-editor + Table extension | table 태그만 추가하고 표 관련 패키지 4개 중 일부 누락 | `@tiptap/extension-table`, `table-row`, `table-cell`, `table-header` 모두 설치 + allowed_tags에 전체 table 관련 태그 추가 |
| rhino-editor + CodeBlockLowlight | `codeBlock: false` 설정 없이 CodeBlockLowlight 추가 | starterKitOptions에서 `codeBlock: false` 선행 설정 필수 |
| rhino-editor + Heading dropdown | Heading extension 별도 추가 | StarterKit의 heading 옵션(starterKitOptions)으로 레벨 설정 |
| toolbar 슬롯 + Stimulus action | `type="button"` 없는 버튼 | 모든 커스텀 버튼에 `type="button"` 필수 |
| rhino-editor + Turbo Drive | 에디터 페이지 뒤로 가기 시 stale 상태 | Admin 에디터 레이아웃에 `<meta name="turbo-cache-control" content="no-cache">` 추가 |
| slash command + TipTap Suggestion | tippy.js 팝업이 z-index 충돌로 sticky 사이드바 뒤에 렌더링됨 | `appendTo: () => document.body` 옵션으로 팝업을 body에 마운트 |

---

## Performance Traps

| Trap | Symptoms | Prevention | When It Breaks |
|------|----------|------------|----------------|
| Table extension의 선택 핸들러 | 표 내 클릭마다 ProseMirror transaction 발생, 대용량 표에서 렌더링 지연 | 표 크기 제한 UI 제공 (행/열 최대값 가이드) | 50행 이상 표 |
| CodeBlockLowlight + lowlight 모든 언어 import | 번들 크기 대폭 증가 | `createLowlight({ javascript, python, ... })` 방식으로 필요 언어만 등록 | 초기 페이지 로드 2MB+ 시 |
| slash command + 대규모 명령 목록 | 슬래시 입력 시마다 DOM 업데이트 비용 | 명령 목록 10-15개로 제한, fuzzy search에 디바운스 적용 | 명령 30개 이상 |

---

## Security Mistakes

| Mistake | Risk | Prevention |
|---------|------|------------|
| `ActionText::ContentHelper.allowed_tags += ["style"]` | CSS `expression()`, `-moz-binding`, `javascript:` URI 실행 가능 (XSS) | `style` 대신 허용 가능한 속성을 HTML 속성으로 처리하거나, `style` 허용 범위를 커스텀 scrubber로 whitelist CSS 속성 목록으로 제한 |
| rails-html-sanitizer 1.6.x에서 `table`과 `style` 동시 허용 | CVE-2024-53986 취약점: math + style 태그 동시 허용 시 XSS 가능 | `style` 태그(엘리먼트)가 아닌 `style` 속성만 허용. `"math"` 태그는 절대 추가하지 않음 |
| 일반 사용자 에디터에 Admin과 동일한 allowed_tags 적용 | 사용자가 `<table>` + `style` 등을 이용한 UI 조작 | Admin 에디터(신뢰된 사용자)와 일반 사용자 에디터를 분리된 scrubber로 처리 |

---

## UX Pitfalls

| Pitfall | User Impact | Better Approach |
|---------|-------------|-----------------|
| 표 삽입 후 셀 밖으로 커서 이동 불가 | 표 아래에 새 단락을 추가할 수 없어 글 작성 중단 | TipTap Table extension의 `addColumnAfter/addRowAfter` 버튼 제공 + 표 다음 빈 단락 자동 삽입 처리 |
| slash command 팝업이 에디터 하단에서 화면 밖으로 잘림 | 슬래시 명령 목록이 잘려 일부 항목 선택 불가 | tippy.js `placement: "auto"` 설정으로 자동 위치 조정 |
| 색상 선택기 UI 없이 hex 코드 직접 입력 | Admin이 색상 코드를 외워야 함 | `<input type="color">` 또는 preset 색상 버튼 제공 |
| 표 삽입 메뉴에서 행/열 수 선택 UI 없이 기본값(3x3)만 | 원하는 크기 표를 바로 삽입 불가 | 행/열 수 입력 다이얼로그 또는 그리드 선택 UI |
| CodeBlock 언어 선택 없이 plain text로만 저장 | 코드 하이라이팅 무효 | language dropdown 또는 자동 감지 표시 |

---

## "Looks Done But Isn't" Checklist

- [ ] **색상/정렬 저장**: 색상/배경색/텍스트 정렬 적용 후 저장 → 상세 페이지에서 동일하게 렌더링되는지 확인 (`action_text.rb` initializer 없으면 style 삭제됨)
- [ ] **표 저장**: 표 삽입 후 저장 → 상세 페이지에서 표가 완전히 렌더링되는지 확인 (allowed_tags 미등록 시 표 전체 삭제)
- [ ] **서버 재시작**: `config/initializers/action_text.rb` 추가 또는 수정 후 개발 서버 재시작 없이 테스트하면 변경 미적용 상태
- [ ] **취소선 태그 확인**: 취소선이 `<del>`(ActionText 허용)인지 `<s>`(허용 안 됨)인지 HTML 소스로 확인
- [ ] **폼 submit 방어**: 커스텀 툴바 버튼 클릭 시 폼 제출이 발생하지 않는지 확인 (`type="button"` 누락 여부)
- [ ] **Turbo 재방문**: Admin 편집 페이지 → 다른 페이지 → 뒤로 가기 후 에디터가 정상 작동하는지 확인
- [ ] **중복 extension**: 브라우저 콘솔에 "Duplicate extension names found" 경고가 없는지 확인
- [ ] **Table 패키지 4종**: `@tiptap/extension-table`, `table-row`, `table-cell`, `table-header` 모두 설치됐는지 `package.json` 확인
- [ ] **allowed_attributes 범위**: `style` 속성 허용 후 일반 사용자 에디터(`posts/_form.html.erb`)에도 동일하게 적용되는지 확인 (Admin 전용 의도라면 분리 처리 필요)
- [ ] **initializer 로딩 순서**: `Rails.application.config.after_initialize` 블록 사용 확인 (즉시 실행 시 ActionText 아직 초기화 안 됨)

---

## Recovery Strategies

| Pitfall | Recovery Cost | Recovery Steps |
|---------|---------------|----------------|
| Extension 중복 등록 (에디터 오작동) | LOW | `starterKitOptions`에 해당 extension `false` 추가 → 서버 재시작 없이 Vite HMR 적용 가능 |
| style 속성 저장 안 됨 (기존 콘텐츠 이미 style 없이 저장됨) | MEDIUM | `action_text.rb` initializer 추가 → 서버 재시작 → 이미 저장된 콘텐츠는 style 없음 (재편집 필요) |
| Table 태그 저장 안 됨 (기존 콘텐츠 이미 표 없이 저장됨) | HIGH | allowed_tags 추가 → 서버 재시작 → 이미 저장된 콘텐츠에서 표 삭제됨 (원본 HTML DB에 없으므로 복구 불가, 재입력 필요) |
| Turbo stale editor (에디터 응답 없음) | LOW | Admin 에디터 레이아웃에 `no-cache` 메타태그 추가, 즉시 배포 가능 |
| slash command z-index 충돌 | LOW | `appendTo` 옵션 수정, CSS z-index 조정 |
| toolbar 버튼이 폼 제출 트리거 | LOW | 버튼에 `type="button"` 추가, 즉시 수정 가능 |

---

## Pitfall-to-Phase Mapping

| Pitfall | Prevention Phase | Verification |
|---------|------------------|--------------|
| Extension 중복 등록 (codeBlock 등) | 각 extension 추가 Phase 첫 태스크 | 브라우저 콘솔 경고 0건 확인 |
| style 속성 ActionText 차단 | 색상/배경색/정렬 Phase 시작 전 (`action_text.rb` initializer) | 색상 적용 저장 후 상세 페이지 HTML에 style 존재 확인 |
| Table 태그 ActionText 차단 | Table 삽입 Phase 시작 전 (`action_text.rb` initializer) | 표 저장 후 상세 페이지에서 `<table>` 태그 존재 확인 |
| toolbar 버튼 폼 submit | 커스텀 버튼 추가 Phase 코드 리뷰 | 버튼 클릭 시 Network 탭에서 불필요한 POST 요청 없음 확인 |
| addExtensions 중복 호출 | Stimulus 컨트롤러 아키텍처 결정 Phase | Turbo 이동 후 에디터 재방문 시 콘솔 경고 없음 확인 |
| rhinoStrike vs Strike 혼용 | 취소선 서식 Phase | HTML에 `<del>` 태그 확인, `<s>` 태그 없음 확인 |
| Turbo Drive stale editor | 에디터 폼 페이지 초기 설정 Phase | 뒤로 가기 후 에디터 정상 작동 확인 |
| Table + Heading 스키마 충돌 | Table Phase에서 starterKitOptions heading 설정 확인 | 표 안에 제목 입력 후 저장된 HTML에 빈 `<p>` 없음 확인 |

---

## Sources

- 프로젝트 코드베이스 직접 분석 (HIGH confidence)
  - `teovibe/node_modules/rhino-editor/exports/chunks/chunk-2NB236ZC.js` — TipTapEditorBase 소스, addExtensions 구현 확인
  - `teovibe/node_modules/rhino-editor/exports/elements/tip-tap-editor-base.d.ts` — TypeScript 선언, starterKitOptions 확인
  - `teovibe/node_modules/rhino-editor/exports/chunks/chunk-7E7MURG2.js` — RhinoStarterKit extension 목록 확인
  - `~/.rbenv/versions/3.3.10/gems/actiontext-8.1.2/app/helpers/action_text/content_helper.rb` — sanitize 로직 확인
  - `~/.rbenv/versions/3.3.10/gems/rails-html-sanitizer-1.6.2/lib/rails/html/sanitizer.rb` — DEFAULT_ALLOWED_TAGS, DEFAULT_ALLOWED_ATTRIBUTES 전체 목록 확인
- [Rhino Editor: Customizing the toolbar](https://rhino-editor.vercel.app/how-tos/customizing-the-toolbar/) — 슬롯 방식, 필수 속성 (HIGH confidence)
- [Rhino Editor: Syntax Highlighting how-to](https://rhino-editor.vercel.app/how-tos/syntax-highlighting) — codeBlock: false 패턴 (HIGH confidence)
- [ActionText ContentHelper stripping inline style · rails/rails#36725](https://github.com/rails/rails/issues/36725) — style 속성 차단 공식 이슈 (HIGH confidence)
- [TipTap: Duplicate extension names found · Discussion #3030](https://github.com/ueberdosis/tiptap/discussions/3030) — 중복 extension 원인 및 해결 (HIGH confidence)
- [ActionText: Safe listing attributes and tags — KonnorRogers (rhino-editor 제작자)](https://dev.to/konnorrogers/actiontext-safe-listing-attributes-and-tags-1a4j) — allowed_tags 확장 패턴 (HIGH confidence)
- [GitHub: OnRailsBlog/actiontext-table](https://github.com/OnRailsBlog/actiontext-table) — Rails Table extension ActionText 통합 (MEDIUM confidence)
- [CVE-2024-53986 rails-html-sanitizer XSS advisory](https://github.com/advisories/GHSA-638j-pmjw-jq48) — style + math 태그 동시 허용 취약점 (HIGH confidence)
- [Maquina Components: Turbo Compatibility (2026)](https://maquina.app/blog/2026/02/maquina-components-0-4-0-turbo-compatibility/) — Web Component + Turbo Drive stale 문제 (MEDIUM confidence)

---
*Pitfalls research for: v1.3 TipTap extension integration via rhino-editor 0.17.x (Rails 8 + ActionText)*
*Researched: 2026-03-14*
