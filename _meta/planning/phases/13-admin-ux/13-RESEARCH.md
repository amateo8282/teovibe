# Phase 13: Admin 에디터 UX - Research

**Researched:** 2026-03-14
**Domain:** Tailwind CSS v4 레이아웃 (flex/grid, sticky positioning, 반응형)
**Confidence:** HIGH

---

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions
- 왼쪽: 본문 에디터 (넓은 영역, flex-grow)
- 오른쪽: 메타 패널 (카테고리, 상태, 예약 발행 등 — 고정 너비 ~320px)
- Tailwind flex/grid로 구현, 별도 JS 불필요
- sticky top으로 스크롤 시 메타 패널이 뷰포트에 고정
- 본문이 길어져도 메타 패널은 항상 보임
- md 브레이크포인트(768px) 이하에서 1단 레이아웃으로 전환
- 모바일에서 메타 패널이 본문 아래로 이동

### Claude's Discretion
- 정확한 Tailwind 클래스 조합
- 메타 패널 내부 필드 순서/그룹핑
- sticky의 top offset 값
- 기존 폼 필드 재배치 방식

### Deferred Ideas (OUT OF SCOPE)
- 없음
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|-----------------|
| ADMN-01 | Admin 게시글 작성/수정 폼 2단 레이아웃 (메타 패널 + 본문 에디터) | flex 컨테이너 패턴으로 구현, `_form.html.erb` 단일 파일 수정 |
| ADMN-02 | 메타 패널 sticky 고정 (스크롤 시 따라오기) | CSS sticky positioning — Tailwind `sticky top-{n}` 유틸리티, 부모 높이 조건 확인 필요 |
| ADMN-03 | 모바일에서 1단 fallback 레이아웃 | Tailwind `flex-col md:flex-row` 반응형 패턴 |
</phase_requirements>

---

## Summary

이 페이즈는 순수 HTML+Tailwind 레이아웃 작업이다. `app/views/admin/posts/_form.html.erb` 단일 파일을 재구성하여 2단 레이아웃을 구현한다. 백엔드(모델/컨트롤러) 변경은 없다.

현재 폼은 `space-y-4` 단일 컬럼 레이아웃이다. 이것을 flex 컨테이너로 감싸고, 에디터 영역(`flex-1`)과 메타 패널(`w-80` 고정)로 분리한다. 메타 패널에 `sticky top-{n}`을 적용하면 ADMN-02를 달성한다. `flex-col md:flex-row`로 모바일 fallback을 처리하면 ADMN-03이 완성된다.

Tailwind CSS v4가 사용 중이므로 `@theme` 블록 방식으로 커스텀 값을 정의하고 있다. 기존 `rounded-card`, `text-tv-black` 등 커스텀 토큰을 그대로 활용한다. 새 라이브러리 설치나 Stimulus 컨트롤러 추가는 불필요하다.

**Primary recommendation:** `_form.html.erb`를 `flex-col md:flex-row gap-6` 컨테이너로 감싸고, 에디터 영역은 `flex-1 min-w-0`, 메타 패널은 `md:w-80 md:sticky md:top-8 md:self-start`로 구성한다.

---

## Standard Stack

### Core
| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| Tailwind CSS | v4.2.0 (프로젝트 기설치) | 2단 레이아웃, sticky, 반응형 | 프로젝트 표준, 추가 설치 불필요 |

### Supporting
없음 — 기존 스택만으로 충분

### Alternatives Considered
| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| Tailwind flex | CSS Grid | Grid도 가능하나, 고정 우측 패널 + 유동 좌측 조합은 flex가 더 직관적 |
| CSS sticky | Stimulus scroll 이벤트 | Stimulus는 JS 오버헤드. 락된 결정에서 JS 불필요로 명시됨 |

**Installation:**
```bash
# 추가 설치 불필요
```

---

## Architecture Patterns

### 변경 파일 목록
```
app/views/admin/posts/
├── _form.html.erb       # 레이아웃 재구성 (주요 변경 대상)
├── new.html.erb         # max-w-2xl → max-w-full 또는 max-w-screen-xl로 확장
└── edit.html.erb        # 동일 — max-w-2xl 컨테이너 너비 조정
```

### 현재 상태 분석

**new.html.erb / edit.html.erb:**
```erb
<div class="max-w-2xl">  <%# 이 너비 제한이 2단 레이아웃을 막는다 — 수정 필요 %>
  <h1 class="text-2xl font-black mb-8">...</h1>
  <div class="bg-white rounded-card shadow-sm p-6">
    <%= render "form", post: @post %>
  </div>
</div>
```
현재 `max-w-2xl`(672px)이 2단 레이아웃을 충분히 수용하지 못한다. `max-w-5xl` 또는 `max-w-full`로 확장해야 한다.

### Pattern 1: Flex 2단 레이아웃 (ADMN-01)

**What:** form_with 내부를 flex 컨테이너로 감싸고, 두 개의 영역으로 분리
**When to use:** 2단 레이아웃 전반

```erb
<%# _form.html.erb 최상위 구조 %>
<%= form_with(model: [:admin, post]) do |f| %>
  <%# 에러 메시지 — 전체 너비 유지 %>
  <% if post.errors.any? %>
    <div class="mb-6 bg-red-50 border border-red-200 rounded-card p-4">
      ...
    </div>
  <% end %>

  <%# 2단 레이아웃 컨테이너 %>
  <div class="flex flex-col md:flex-row gap-6 items-start">

    <%# 좌측: 에디터 영역 (flex-grow) %>
    <div class="flex-1 min-w-0 space-y-4">
      <%# AI 초안 패널 + 본문 에디터 %>
    </div>

    <%# 우측: 메타 패널 (고정 너비, sticky) %>
    <div class="w-full md:w-80 md:sticky md:top-8 md:self-start space-y-4">
      <%# 제목, 카테고리, 상태, 예약발행, 고정글, SEO 필드, 버튼 %>
    </div>

  </div>
<% end %>
```

### Pattern 2: Sticky 메타 패널 (ADMN-02)

**What:** CSS `position: sticky`를 Tailwind 유틸리티로 적용
**Critical constraint:** sticky는 부모가 `overflow: hidden/auto/scroll`이면 동작하지 않는다. 또한 sticky 요소의 부모가 flex 컨테이너일 때 `self-start`가 필수다 — 부모의 `align-items: stretch` 기본값이 자식을 늘려 sticky 효과를 무력화한다.

```erb
<%# sticky 적용 시 필수 조합 %>
<div class="w-full md:w-80 md:sticky md:top-8 md:self-start">
  ...
</div>
```

**top offset 계산:**
- Admin 레이아웃 `<main>`에 `p-4 md:p-8` 적용 중
- 상단 고정 내비게이션 없음 (Admin 사이드바는 left-fixed)
- 따라서 `top-8` (32px) 정도로 충분

### Pattern 3: 모바일 1단 Fallback (ADMN-03)

**What:** `flex-col`이 모바일 기본, `md:flex-row`로 데스크탑 2단 전환
**Field order on mobile:** 모바일에서 컬럼 순서는 HTML 소스 순서를 따른다. 사용자 결정에 따라 메타 패널을 본문 아래에 배치하므로, HTML에서 에디터 div가 먼저, 메타 패널 div가 나중에 온다.

### Pattern 4: 메타 패널 내부 필드 그룹핑 (Claude's Discretion)

권장 순서:
1. 제목 (사용 빈도 높음)
2. 카테고리
3. 상태 (draft/published)
4. 예약 발행 시각
5. 고정글 체크박스
6. SEO 제목
7. SEO 설명
8. 액션 버튼 (취소/저장) — 패널 하단 고정

```erb
<div class="w-full md:w-80 md:sticky md:top-8 md:self-start">
  <div class="bg-white rounded-card shadow-sm p-5 space-y-4">
    <h2 class="text-sm font-black text-tv-gray uppercase tracking-wide">메타 정보</h2>
    <%# 제목 %>
    <%# 카테고리 %>
    <%# 상태 %>
    <%# 예약 발행 %>
    <%# 고정글 %>
    <hr class="border-gray-100">
    <h3 class="text-xs font-bold text-tv-gray">SEO</h3>
    <%# SEO 제목 %>
    <%# SEO 설명 %>
    <div class="flex gap-3 pt-2">
      <%# 취소 + 저장 버튼 %>
    </div>
  </div>
</div>
```

### Anti-Patterns to Avoid

- **`max-w-2xl` 유지:** new/edit wrapper의 `max-w-2xl`을 그대로 두면 2단 레이아웃이 좁게 렌더링됨. 반드시 `max-w-5xl` 이상으로 확장
- **sticky 부모에 overflow 속성 추가:** 부모에 `overflow-auto`가 있으면 sticky가 동작하지 않음
- **`self-start` 누락:** flex 컨테이너에서 sticky를 쓸 때 `self-start` 없으면 패널이 컨테이너 전체 높이로 늘어나 sticky가 무력화됨
- **모바일에서 `md:sticky`를 `sticky`로 쓰기:** 모바일에서는 sticky 불필요 — 오히려 스크롤 방해. `md:sticky`로 데스크탑만 적용

---

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Sticky 패널 | Stimulus scroll 이벤트로 fixed 계산 | CSS `sticky` + Tailwind | 브라우저 내장 기능, JS 오버헤드 없음 |
| 반응형 2단 | JS breakpoint detection | Tailwind `md:` prefix | 미디어쿼리 자동 처리 |
| 컬럼 너비 고정 | 인라인 style="width:320px" | `md:w-80` Tailwind 유틸리티 | 디자인 시스템 일관성 |

---

## Common Pitfalls

### Pitfall 1: sticky가 동작하지 않는 경우
**What goes wrong:** `sticky top-8 self-start`를 추가해도 패널이 스크롤과 함께 사라짐
**Why it happens:** flex 부모에 `items-stretch`(기본값)가 적용되어 자식이 전체 높이로 늘어나므로 sticky 스크롤 범위가 소진됨. 또는 부모/조상에 `overflow: hidden`
**How to avoid:** sticky 요소에 반드시 `self-start` 추가. `items-start`를 flex 컨테이너에 추가하거나 개별 요소에 `self-start`를 사용
**Warning signs:** 패널이 컬럼 전체 높이와 같아 보임

### Pitfall 2: new/edit 래퍼 너비 제한
**What goes wrong:** `_form.html.erb`는 2단으로 바뀌었는데, 실제 화면에서 좁게 렌더링됨
**Why it happens:** `new.html.erb`와 `edit.html.erb`의 `max-w-2xl` div가 폼 전체를 672px로 제한
**How to avoid:** new/edit.html.erb의 래퍼를 `max-w-5xl` 또는 `max-w-full`로 변경
**Warning signs:** 2단이 생기긴 하나 에디터 너비가 매우 좁음

### Pitfall 3: rhino-editor 너비 처리
**What goes wrong:** `rhino-editor`가 `min-w-0` 없이 flex 자식으로 들어가면 컨텐츠 오버플로우 발생
**Why it happens:** flex 아이템의 기본 `min-width: auto`가 텍스트/에디터 콘텐츠 최소 너비를 보장하려 해서 레이아웃을 밀어냄
**How to avoid:** 에디터 컬럼 wrapper에 `min-w-0` 클래스 추가
**Warning signs:** 에디터가 메타 패널을 화면 밖으로 밀어냄

### Pitfall 4: AI 초안 패널 위치
**What goes wrong:** AI 초안 패널을 에디터 위에 두면 모바일에서 매우 긴 스크롤 발생
**Why it happens:** 현재 AI 초안 패널이 폼 최상단에 위치 — 에디터 영역에 포함되므로 유지하되, 에디터 컬럼 내 최상단에 배치하면 자연스러움
**How to avoid:** AI 초안 패널은 에디터 컬럼(좌측) 안에 포함 — 현재 위치 유지

---

## Code Examples

### 완성 구조 스케치

```erb
<%# _form.html.erb — 최종 구조 %>
<%= form_with(model: [:admin, post]) do |f| %>

  <%# 에러 블록 — 전체 너비 %>
  <% if post.errors.any? %>
    <div class="mb-4 ...">...</div>
  <% end %>

  <%# 2단 컨테이너: 모바일=세로, 데스크탑=가로 %>
  <div class="flex flex-col md:flex-row gap-6 items-start">

    <%# 좌측: AI 초안 + 본문 에디터 %>
    <div class="flex-1 min-w-0 space-y-4">
      <%# AI 초안 패널 (기존 그대로) %>
      <div class="bg-gray-50 rounded-2xl border border-gray-200 p-5"
           data-controller="ai-draft" ...>
        ...
      </div>

      <%# 본문 에디터 %>
      <div>
        <label class="block text-sm font-bold mb-1">본문</label>
        <%= f.hidden_field :body, ... %>
        <rhino-editor ... class="w-full min-h-[400px] rounded-2xl border border-gray-300"></rhino-editor>
      </div>
    </div>

    <%# 우측: 메타 패널 — sticky %>
    <div class="w-full md:w-80 md:sticky md:top-8 md:self-start">
      <div class="bg-white rounded-card border border-gray-200 p-5 space-y-4">
        <%# 제목 %>
        <div>
          <label class="block text-sm font-bold mb-1">제목</label>
          <%= f.text_field :title, class: "w-full px-4 py-3 rounded-2xl border border-gray-300 focus:outline-none" %>
        </div>
        <%# 카테고리, 상태, 예약발행, 고정글, SEO 필드 ... %>
        <%# 액션 버튼 %>
        <div class="flex gap-3 pt-2">
          <%= link_to "취소", admin_posts_path, class: "border border-gray-300 rounded-pill px-6 py-3 text-sm font-bold" %>
          <%= f.submit post.persisted? ? "수정" : "작성", class: "bg-tv-gold text-tv-black rounded-pill px-6 py-3 text-sm font-bold cursor-pointer" %>
        </div>
      </div>
    </div>

  </div>
<% end %>
```

### new.html.erb / edit.html.erb 너비 수정

```erb
<%# 기존 %>
<div class="max-w-2xl">

<%# 변경 %>
<div class="max-w-5xl">
```

---

## State of the Art

| Old Approach | Current Approach | Impact |
|--------------|------------------|--------|
| 단일 컬럼 `space-y-4` | 2단 flex 레이아웃 | 에디터/메타 분리로 집중도 향상 |
| 메타 필드가 본문 아래에 위치 | 메타 패널 sticky 우측 | 긴 글 작성 시 카테고리 변경 위해 스크롤 불필요 |

---

## Open Questions

1. **rhino-editor min-height 조정**
   - What we know: 현재 `min-h-[200px]`로 설정됨
   - What's unclear: 2단 레이아웃에서 에디터가 넓어지면 높이를 더 크게 잡는 게 적절한지
   - Recommendation: `min-h-[400px]` 또는 `min-h-[60vh]`로 확장 고려 (Claude's Discretion)

2. **메타 패널 max-height 처리**
   - What we know: sticky 패널이 뷰포트보다 길어질 경우 잘릴 수 있음
   - What's unclear: SEO 필드까지 포함하면 패널이 뷰포트 높이를 초과할 가능성
   - Recommendation: `max-h-screen overflow-y-auto`를 메타 패널 내부 div에 추가하는 방어 처리 고려

---

## Validation Architecture

### Test Framework
| Property | Value |
|----------|-------|
| Framework | Minitest (Rails 기본) |
| Config file | `test/test_helper.rb` |
| Quick run command | `bundle exec rails test test/controllers/admin/posts_controller_test.rb` |
| Full suite command | `bundle exec rails test` |

### Phase Requirements → Test Map
| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| ADMN-01 | new/edit 페이지에서 flex 2단 레이아웃 HTML 구조 확인 | integration | `bundle exec rails test test/integration/admin_editor_layout_test.rb` | Wave 0 생성 |
| ADMN-02 | 메타 패널에 sticky 클래스 존재 여부 확인 | integration | (동일 파일 내 포함) | Wave 0 생성 |
| ADMN-03 | 모바일 반응형 클래스 (flex-col md:flex-row) 존재 여부 확인 | integration | (동일 파일 내 포함) | Wave 0 생성 |

**Note:** 레이아웃/CSS 클래스 변경은 시각적 렌더링 결과이므로 Minitest 통합 테스트에서 HTML 응답에 특정 CSS 클래스 문자열이 포함되었는지 `assert_select` 또는 `assert_match`로 검증한다. E2E 시각 테스트(Capybara/Playwright)는 현재 프로젝트에 설정 없으므로 사용하지 않는다.

### Sampling Rate
- **Per task commit:** `bundle exec rails test test/controllers/admin/posts_controller_test.rb`
- **Per wave merge:** `bundle exec rails test`
- **Phase gate:** Full suite green before `/gsd:verify-work`

### Wave 0 Gaps
- [ ] `test/integration/admin_editor_layout_test.rb` — ADMN-01, ADMN-02, ADMN-03 커버

---

## Sources

### Primary (HIGH confidence)
- 프로젝트 코드 직접 분석 — `app/views/admin/posts/_form.html.erb`, `new.html.erb`, `edit.html.erb`, `app/assets/tailwind/application.css`
- Tailwind CSS v4 공식 문서 (sticky, flex, responsive 유틸리티) — 버전 4.2.0 확인

### Secondary (MEDIUM confidence)
- CSS sticky + flex `self-start` 패턴 — MDN Web Docs 및 Tailwind 커뮤니티 검증된 패턴

### Tertiary (LOW confidence)
- 없음

---

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH - 기존 Tailwind v4 스택 확인됨, 추가 라이브러리 불필요
- Architecture: HIGH - 변경 대상 파일 직접 분석, Tailwind 유틸리티 명확
- Pitfalls: HIGH - CSS sticky + flex 조합의 알려진 동작 방식, 기존 코드 구조 확인

**Research date:** 2026-03-14
**Valid until:** 2026-04-14 (Tailwind v4 안정 버전, 빠른 변경 없음)
