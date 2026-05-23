# Phase 14: 에디터 기반 설정 - Research

**Researched:** 2026-03-14
**Domain:** ActionText HTML 허용목록 + AdminRhinoEditor 서브클래스 스캐폴드 (Rails 8 + rhino-editor 0.17.3)
**Confidence:** HIGH

---

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|-----------------|
| INFRA-01 | ActionText initializer에 style 속성 + table 태그 허용 설정 | ActionText sanitizer 소스 직접 확인 완료. DEFAULT_ALLOWED_TAGS, DEFAULT_ALLOWED_ATTRIBUTES 목록 파악. 설정 패턴 검증됨 |
| INFRA-02 | AdminRhinoEditor 서브클래스 스캐폴드 (커스텀 엘리먼트 등록, Admin 폼 적용) | rhino-editor TipTapEditor 서브클래스 API 확인. 현재 admin _form.html.erb에서 `<rhino-editor>` 사용 중 — 태그명 교체 필요 |
| INFRA-03 | ai_draft_controller.js의 editor selector를 AdminRhinoEditor로 변경 | ai_draft_controller.js L74에 `document.querySelector("rhino-editor")` 하드코딩 확인. 단순 문자열 교체로 해결 |
</phase_requirements>

---

## Summary

Phase 14는 v1.3 Admin 에디터 고도화의 **선행 조건 전용 단계**다. 기능 추가 없이 세 가지 인프라 기반을 구축한다: (1) ActionText HTML 새니타이저 허용목록 확장, (2) AdminRhinoEditor 커스텀 엘리먼트 등록 및 Admin 폼 적용, (3) AI 초안 컨트롤러의 selector 업데이트.

ActionText의 새니타이저는 저장 시가 아닌 **렌더링 시**에 비허가 태그를 제거한다. 즉, `style` 속성이나 `table` 태그가 DB에는 정상 저장되지만 게시글 상세 페이지에서 보면 소리 없이 사라진다. Phase 15 이후 작업에서 이 현상을 만나면 디버깅이 매우 어렵기 때문에 Phase 14에서 반드시 선행 처리해야 한다. `config/initializers/action_text.rb`에 두 줄(style 속성, table 태그 묶음)을 추가하는 것이 전부다.

AdminRhinoEditor는 `TipTapEditor`를 상속하는 Web Component 서브클래스다. 이 단계에서는 extension 추가 없이 순수 스캐폴드만 구성한다 — 커스텀 엘리먼트 등록 + Admin 폼 태그명 교체 + AI 컨트롤러 selector 수정. 세 가지 모두 기존 rhino-editor 기능을 그대로 유지하면서 후속 Phase에서 안전하게 확장할 수 있는 토대를 만든다.

**Primary recommendation:** `config/initializers/action_text.rb` 파일 생성(INFRA-01)을 가장 먼저 구현하고, AdminRhinoEditor 스캐폴드(INFRA-02), AI selector 수정(INFRA-03) 순으로 진행한다.

---

## Standard Stack

### Core (Phase 14에서 사용)

| 라이브러리 / API | 버전 | 목적 | 근거 |
|-----------------|------|------|------|
| `rails-html-sanitizer` | 1.6.2 (현재 설치됨) | ActionText 렌더링 시 HTML 새니타이저 | rails 8.1.2 번들 — 별도 설치 불필요 |
| `rhino-editor` | 0.17.3 (현재 설치됨) | `TipTapEditor` 서브클래스 베이스 | 0.18.x 업그레이드 금지 (이미지 업로드 제거됨) |
| `@tiptap/core` | 2.27.2 (pnpm-lock.yaml 확인됨) | AdminRhinoEditor 타입 베이스 | lockfile에서 확인 — 신규 설치 없음 |

### 신규 설치 없음

Phase 14는 npm 패키지를 추가하지 않는다. 모든 작업은 기존 의존성 위에서 설정 파일과 JS 파일 생성/수정으로만 이루어진다.

---

## Architecture Patterns

### 파일 변경 목록

```
config/
└── initializers/
    └── action_text.rb          # [신규] INFRA-01 — style + table 태그 허용목록

app/frontend/
└── editor/
    └── admin_rhino_editor.js   # [신규] INFRA-02 — TipTapEditor 서브클래스

app/frontend/entrypoints/
└── application.js              # [수정] INFRA-02 — AdminRhinoEditor import 추가

app/views/admin/posts/
└── _form.html.erb              # [수정] INFRA-02 — <rhino-editor> → <admin-rhino-editor>

app/frontend/controllers/
└── ai_draft_controller.js      # [수정] INFRA-03 — querySelector 문자열 교체
```

### Pattern 1: ActionText Sanitizer 허용목록 확장 (INFRA-01)

**What:** `ActionText::ContentHelper` 모듈이 사용하는 허용 태그/속성 목록에 추가 항목을 append한다.

**When to use:** ActionText rich text field가 있고 기본 허용목록에 없는 HTML을 보존해야 할 때.

**구현 패턴:**
```ruby
# config/initializers/action_text.rb
# ActionText 렌더링 시 style 속성과 table 관련 태그를 보존하도록 허용목록 확장
# 기본값: DEFAULT_ALLOWED_ATTRIBUTES에 "style" 없음, DEFAULT_ALLOWED_TAGS에 table 계열 없음

Rails.application.config.after_initialize do
  # style 속성 허용 — TextAlign, Color, Highlight, FontSize 등 인라인 스타일 보존
  ActionText::ContentHelper.allowed_attributes += ["style"]

  # table 태그 계열 허용 — Table extension 저장 데이터 보존
  ActionText::ContentHelper.allowed_tags += %w[table thead tbody tfoot tr th td colgroup col caption]

  # table 관련 속성 허용 — colspan, rowspan, scope
  ActionText::ContentHelper.allowed_attributes += ["colspan", "rowspan", "scope"]
end
```

**Source:** `~/.rbenv/versions/3.3.10/gems/actiontext-8.1.2/app/helpers/action_text/content_helper.rb` 직접 확인 (HIGH)

**보안 주의사항:**
- `style` 허용은 CSS injection 위험을 수반한다. Admin 전용 에디터이므로 신뢰된 사용자만 입력 — 현재는 수용 가능한 트레이드오프
- `rails-html-sanitizer@1.6.2` (CVE-2024-53986): `style` + `math` 태그 조합 시 XSS 가능. `math` 태그는 허용목록에 추가하지 말 것
- 향후 일반 사용자 에디터에 적용 시 이 initializer를 Admin 전용으로 스코핑해야 함

### Pattern 2: TipTapEditor 서브클래스 (INFRA-02)

**What:** `TipTapEditor`를 상속하는 새 Web Component를 작성하고 `<admin-rhino-editor>` 태그로 등록한다.

**When to use:** Admin 전용으로 다른 기능을 추가해야 하고 일반 사용자 에디터(`<rhino-editor>`)와 분리해야 할 때.

**구현 패턴:**
```javascript
// app/frontend/editor/admin_rhino_editor.js
// Phase 14: 순수 스캐폴드 — extension 추가 없이 태그만 등록
// Phase 15 이후: this.extensions 또는 editorOptions() 오버라이드로 확장

import { TipTapEditor } from "rhino-editor/exports/elements/tip-tap-editor.js"

export class AdminRhinoEditor extends TipTapEditor {
  // Phase 14: 스캐폴드 단계 — 기존 rhino-editor와 동일하게 동작
  // 추가 확장은 Phase 15부터 이 클래스에 구현
}

AdminRhinoEditor.define("admin-rhino-editor")
```

**Source:** `teovibe/node_modules/rhino-editor/exports/elements/tip-tap-editor.d.ts` 직접 확인 — `define(tagName)` static method 존재 (HIGH)

**application.js에 import 추가:**
```javascript
// app/frontend/entrypoints/application.js
// 기존 rhino-editor import 아래에 추가
import "../editor/admin_rhino_editor.js"
```

**Admin 폼 태그 교체 (_form.html.erb):**
```erb
<%# 기존: <rhino-editor ...> %>
<admin-rhino-editor
  input="<%= f.field_id(:body) %>"
  data-blob-url-template="<%= rails_service_blob_url(":signed_id", ":filename") %>"
  data-direct-upload-url="<%= rails_direct_uploads_url %>"
  class="w-full min-h-[400px] rounded-2xl border border-gray-300"
></admin-rhino-editor>
```

### Pattern 3: AI Draft Controller Selector 업데이트 (INFRA-03)

**What:** `ai_draft_controller.js` L74의 `querySelector("rhino-editor")`를 `querySelector("admin-rhino-editor")`로 교체한다.

**현재 코드 (L74):**
```javascript
const rhinoEditor = document.querySelector("rhino-editor")
```

**변경 후:**
```javascript
const rhinoEditor = document.querySelector("admin-rhino-editor")
```

**Why:** `<rhino-editor>` 태그가 `<admin-rhino-editor>`로 교체되면 기존 selector가 `null`을 반환하여 AI 초안 삽입 기능이 무음 실패한다. `admin-rhino-editor` 인스턴스는 `TipTapEditor`를 상속하므로 `.editor`, `.updateInputElementValue()` 등 동일한 API를 그대로 사용할 수 있다.

---

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| ActionText 새니타이저 커스터마이징 | 직접 Loofah 설정 | `ActionText::ContentHelper.allowed_*` append | ActionText가 공식 제공하는 확장 포인트 |
| Web Component 정의 | 직접 `customElements.define()` | `AdminRhinoEditor.define("admin-rhino-editor")` | TipTapEditor base class의 static method가 lifecycle + naming을 처리 |
| 에디터 서브클래스 | 처음부터 TipTap 직접 구성 | `TipTapEditor` 상속 | ActionText 직렬화, Active Storage 업로드 훅, 모든 rhino-editor 기능 상속 |

---

## Common Pitfalls

### Pitfall 1: ActionText가 style/table을 렌더링 시 제거 (가장 중요)

**What goes wrong:** `style` 속성과 table 태그가 DB에 저장은 되지만 게시글 상세 페이지에서 보면 사라진다. 에디터에서는 정상 보임 — 저장 성공 메시지도 표시됨 — 그러나 상세 페이지에서만 누락.

**Why it happens:** ActionText는 `ActionText::Content#to_s` 호출(렌더 시)에 Loofah 새니타이저를 적용한다. 저장 시에는 raw HTML을 그대로 보존한다. `DEFAULT_ALLOWED_TAGS`에 table 계열이 없고, `DEFAULT_ALLOWED_ATTRIBUTES`에 `style`이 없다.

**How to avoid:** `config/initializers/action_text.rb`를 가장 먼저 생성(INFRA-01이 첫 번째 plan task). Phase 15 이후 기능 구현 전에 반드시 이 파일이 존재해야 한다.

**Warning signs:** 게시글 저장 후 에디터에서는 보이는데 상세 페이지에서 스타일/표 구조가 없어짐.

### Pitfall 2: Turbo Drive로 Admin 페이지 재방문 시 에디터 초기화

**What goes wrong:** 브라우저 뒤로가기 후 Admin 폼으로 돌아오면 에디터 내용이 비워지거나 두 번 초기화된다.

**Why it happens:** Turbo가 이전 페이지를 캐시에서 복원할 때 Web Component의 `connectedCallback`이 다시 실행되어 에디터를 재초기화한다.

**How to avoid:** Admin 레이아웃에 `<meta name="turbo-cache-control" content="no-cache">` 추가.

**Warning signs:** 뒤로가기 시 에디터 내용 손실 또는 콘솔에 TipTap 재초기화 경고.

### Pitfall 3: `<admin-rhino-editor>` 등록 전 ERB가 렌더되는 경우

**What goes wrong:** `<admin-rhino-editor>` 커스텀 엘리먼트가 `customElements.define`으로 등록되기 전에 브라우저가 HTML을 파싱하면 일반 HTMLElement로 업그레이드되지 않는다.

**Why it happens:** Vite 빌드에서 `admin_rhino_editor.js` import가 누락되거나 순서가 잘못된 경우.

**How to avoid:** `application.js`에서 `"rhino-editor"` import 바로 아래에 `admin_rhino_editor.js` import 배치. 브라우저는 `<script type="module">`로 로딩된 JS가 완료된 후 DOM을 업그레이드한다.

### Pitfall 4: ai_draft_controller.js selector 미변경

**What goes wrong:** `<rhino-editor>` 태그를 `<admin-rhino-editor>`로 교체했는데 `ai_draft_controller.js`의 selector를 안 바꾸면 `document.querySelector("rhino-editor")`가 `null`을 반환하고, `"에디터를 찾을 수 없습니다"` 오류가 발생한다.

**How to avoid:** INFRA-02와 INFRA-03을 같은 PR에서 처리 — 태그 교체와 selector 교체를 원자적으로 수행.

---

## Code Examples

### ActionText 허용목록 확인 (현재 상태)

```ruby
# DEFAULT_ALLOWED_TAGS (rails-html-sanitizer 1.6.2) 에 table 계열 없음 확인됨
# DEFAULT_ALLOWED_ATTRIBUTES에 "style" 없음 확인됨
# Source: ~/.rbenv/versions/3.3.10/gems/actiontext-8.1.2/app/helpers/action_text/content_helper.rb
ActionText::ContentHelper::ALLOWED_TAGS    # => Array (table 계열 없음)
ActionText::ContentHelper::ALLOWED_ATTRIBUTES # => Array ("style" 없음)
```

### 동작 확인 — Rails 콘솔에서 검증

```ruby
# config/initializers/action_text.rb 적용 후 콘솔에서 확인
ActionText::ContentHelper.allowed_attributes.include?("style")       # => true
ActionText::ContentHelper.allowed_tags.include?("table")              # => true
ActionText::ContentHelper.allowed_tags.include?("td")                 # => true
```

### AdminRhinoEditor 동작 확인 — 브라우저 콘솔

```javascript
// Admin 게시글 폼 페이지에서 실행
const el = document.querySelector("admin-rhino-editor")
el.constructor.name           // => "AdminRhinoEditor"
el instanceof TipTapEditor    // => true (상속 관계 확인)
typeof el.editor              // => "object" (TipTap Editor 인스턴스)
typeof el.updateInputElementValue  // => "function"
```

---

## State of the Art

| Old Approach | Current Approach | Notes |
|--------------|------------------|-------|
| Trix 에디터 (ActionText 기본) | rhino-editor 0.17.3 (TipTap 2.27.2 기반) | 이미 적용됨 — Phase 14는 이 위에서 확장 |
| 단일 `<rhino-editor>` 태그 | `<admin-rhino-editor>` (서브클래스) + `<rhino-editor>` (일반 폼) | Admin/일반 사용자 에디터 분리 |
| ActionText 기본 새니타이저 | 허용목록 확장 initializer | style + table 보존 |

---

## Open Questions

1. **Admin 레이아웃 파일 경로**
   - What we know: `<meta name="turbo-cache-control" content="no-cache">`를 Admin 레이아웃에 추가해야 함
   - What's unclear: Admin 전용 레이아웃 파일 이름 (`admin.html.erb` 또는 `application.html.erb`)
   - Recommendation: 플래닝 시 `app/views/layouts/` 아래 Admin 전용 레이아웃 파일 확인 후 task에 반영

2. **`application.js` 현재 import 구조**
   - What we know: `admin_rhino_editor.js`를 rhino-editor import 아래에 추가해야 함
   - What's unclear: 현재 `application.js`의 import 순서 (rhino-editor import 위치)
   - Recommendation: 플래닝 시 `app/frontend/entrypoints/application.js` 확인 후 정확한 삽입 위치 지정

---

## Validation Architecture

### Test Framework

| Property | Value |
|----------|-------|
| Framework | 없음 (테스트 인프라 미구축) |
| Config file | none |
| Quick run command | `bin/rails runner "puts ActionText::ContentHelper.allowed_tags.include?('table')"` |
| Full suite command | `bin/rails test` (기본 Rails 테스트) |

### Phase Requirements → Test Map

| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|--------------|
| INFRA-01 | `style` 속성 + table 태그가 ActionText 렌더링 후 보존됨 | smoke | `bin/rails runner "puts ActionText::ContentHelper.allowed_attributes.include?('style')"` | ❌ Wave 0 |
| INFRA-02 | `<admin-rhino-editor>` 커스텀 엘리먼트가 Admin 폼에 렌더링됨 | manual | Admin 폼 페이지 직접 확인 | N/A (manual) |
| INFRA-03 | AI 초안 삽입이 `admin-rhino-editor`를 통해 정상 동작 | manual | AI 초안 생성 → 삽입 버튼 클릭 확인 | N/A (manual) |

### Sampling Rate

- **Per task commit:** `bin/rails runner "puts ActionText::ContentHelper.allowed_attributes.include?('style') && ActionText::ContentHelper.allowed_tags.include?('table')"` (true 출력 확인)
- **Per wave merge:** Admin 폼 페이지 수동 확인 — `<admin-rhino-editor>` 렌더링, AI 초안 삽입 동작
- **Phase gate:** 세 success criteria 모두 수동 확인 완료 후 Phase 15 진입

### Wave 0 Gaps

- [ ] `config/initializers/action_text.rb` — INFRA-01 구현 대상 (test이자 artifact)
- [ ] `app/frontend/editor/admin_rhino_editor.js` — INFRA-02 구현 대상

---

## Sources

### Primary (HIGH confidence)

- `~/.rbenv/versions/3.3.10/gems/actiontext-8.1.2/app/helpers/action_text/content_helper.rb` — sanitize 로직, allowed_tags/attributes API
- `~/.rbenv/versions/3.3.10/gems/rails-html-sanitizer-1.6.2` — DEFAULT_ALLOWED_TAGS, DEFAULT_ALLOWED_ATTRIBUTES 직접 확인
- `teovibe/node_modules/rhino-editor/exports/elements/tip-tap-editor.d.ts` — `define()` static method, `extensions` getter, `editorOptions()` override
- `teovibe/app/frontend/controllers/ai_draft_controller.js` (L74) — `querySelector("rhino-editor")` 하드코딩 확인
- `teovibe/app/views/admin/posts/_form.html.erb` (L69) — 현재 `<rhino-editor>` 태그 사용 확인
- `.planning/research/SUMMARY.md` — 프로젝트 레벨 연구, 아키텍처 결정

### Secondary (MEDIUM confidence)

- [KonnorRogers: ActionText safe listing](https://dev.to/konnorrogers/actiontext-safe-listing-attributes-and-tags-1a4j) — `allowed_tags` 확장 패턴 (rhino-editor 작성자 게시글)
- [CVE-2024-53986](https://github.com/advisories/GHSA-638j-pmjw-jq48) — rails-html-sanitizer XSS: style + math 태그 조합 주의

---

## Metadata

**Confidence breakdown:**
- INFRA-01 (ActionText initializer): HIGH — 소스 직접 확인, 공식 API 사용
- INFRA-02 (AdminRhinoEditor scaffold): HIGH — TipTapEditor `.define()` API 직접 확인
- INFRA-03 (ai_draft selector): HIGH — 소스 코드 직접 확인, 단순 문자열 교체

**Research date:** 2026-03-14
**Valid until:** 2026-04-14 (rhino-editor 0.17.x가 안정적 — 빠른 변화 없음)
