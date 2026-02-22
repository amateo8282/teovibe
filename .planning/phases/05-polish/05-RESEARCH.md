# Phase 5: Polish - Research

**Researched:** 2026-02-22
**Domain:** Tailwind CSS v4 반응형 보완, Rails 8 커스텀 에러 페이지
**Confidence:** HIGH (프로젝트 코드 직접 확인 + Rails 8 공식 패턴)

---

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|-----------------|
| UIUX-01 | 전체 레이아웃의 모바일 반응형을 보완한다 (네비게이션, 사이드바, 카드 레이아웃) | 기존 navbar/admin layout/posts 카드 코드 직접 확인. 모바일 메뉴는 이미 존재하나 Admin 사이드바는 모바일 미대응 상태 |
| UIUX-02 | 커스텀 404/500 에러 페이지를 제공한다 | 현재 public/404.html, public/500.html은 Rails 기본 영문 페이지. Rails `config.exceptions_app` 패턴으로 ERB 뷰 렌더링 가능 |
</phase_requirements>

---

## Summary

Phase 5는 두 가지 작업으로 구성된다. 첫째, 전체 레이아웃의 모바일 반응형 보완이다. 프로젝트는 Tailwind CSS v4 (`@tailwindcss/vite` 플러그인) + ERB 뷰 기반으로 운영된다. 기존 navbar에 모바일 햄버거 메뉴(`MobileMenuController` Stimulus)는 이미 존재하지만 알림 드롭다운과 사용자 드롭다운이 모바일에서 숨겨진 채로 남아있다. Admin 레이아웃은 `fixed` 사이드바가 모바일에서 공간을 차지하는 구조적 문제가 있다. 카드 그리드는 `grid-cols-1 md:grid-cols-2 lg:grid-cols-3`으로 이미 반응형이지만 일부 텍스트 크기와 패딩 조정이 필요하다.

둘째, 커스텀 에러 페이지 구현이다. 현재 `public/404.html`과 `public/500.html`은 Rails 기본 영문 페이지로 브랜드와 전혀 다르다. Rails 8에서 커스텀 에러 페이지를 렌더링하는 표준 방법은 `config.exceptions_app`을 라우터로 설정하고, `ErrorsController`에서 ERB 뷰를 렌더링하는 방법이다. 단, 500 에러 페이지는 DB/앱 자체가 다운된 상황을 고려해 정적 HTML(`public/500.html`)로 유지하거나 최소한의 의존성으로 구현하는 것이 안전하다.

**Primary recommendation:** 모바일 반응형은 기존 Tailwind 클래스 조정(추가 JS 없음)으로 해결하고, 에러 페이지는 `config.exceptions_app = routes` + `ErrorsController` 패턴으로 Rails 애플리케이션 레이아웃을 재사용해 브랜드 일관성을 확보하라.

---

## Project Context (현재 코드베이스 상태)

### 현재 레이아웃 구조

```
app/views/layouts/
  application.html.erb   # 공개 레이아웃: fixed navbar (86px) + main + footer
  admin.html.erb         # Admin 레이아웃: fixed 사이드바(w-60) + ml-60 메인
```

### 현재 반응형 현황 (코드 직접 확인)

| 영역 | 현황 | 문제 |
|------|------|------|
| 공개 Navbar | `hidden md:flex` 데스크톱 메뉴, `md:hidden` 햄버거 존재 | 모바일 메뉴에 알림/드롭다운 없음, 통지수 배지 없음 |
| Admin 사이드바 | `w-60 fixed` 항상 표시 | 모바일에서 전체 너비 침범, `ml-60` 메인이 좁아짐 |
| 카드 그리드 | `grid-cols-1 md:grid-cols-2 lg:grid-cols-3` | 이미 반응형 |
| 게시글 show | `max-w-[800px]` 단일 컬럼 | 이미 반응형 |
| 스킬팩 show | `max-w-[800px]` 단일 컬럼 | 이미 반응형 |
| 푸터 | `grid-cols-1 md:grid-cols-3` | 이미 반응형 |

### Tailwind CSS 버전

- **Tailwind CSS v4** (package.json: `"tailwindcss": "^4.2.0"`)
- 진입점: `app/frontend/entrypoints/application.css`
- 설정 방식: `@theme {}` 인라인 블록 (v4 방식). `tailwind.config.js` 없음
- 커스텀 컬러: `--color-tv-*` 변수로 정의됨
- 브레이크포인트: `sm:`, `md:`, `lg:`, `xl:` — v4에서도 동일

---

## Standard Stack

### Core

| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| Tailwind CSS v4 | ^4.2.0 (이미 설치) | 반응형 유틸리티 클래스 | 프로젝트 기존 CSS 인프라 |
| Stimulus.js | ^3.2.2 (이미 설치) | 모바일 메뉴/사이드바 토글 JS | 프로젝트 기존 JS 인프라 |
| Rails Router | Rails 내장 | exceptions_app 라우터 설정 | 커스텀 에러 페이지 표준 방법 |

### Supporting

| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| 없음 | - | - | 새 패키지 설치 불필요 |

**Installation:**
```bash
# 새 패키지 불필요. 기존 인프라로 모두 구현 가능.
```

---

## Architecture Patterns

### Pattern 1: 모바일 반응형 - 공개 Navbar 개선

**현황 파악:**
```html
<!-- 기존: 모바일 메뉴에 알림/드롭다운 없음 -->
<div data-mobile-menu-target="menu" class="hidden md:hidden bg-white border-t">
  <div class="px-5 py-4 space-y-3">
    <!-- 네비게이션 링크만 있음 -->
    <!-- Current.user 분기는 있으나 알림벨 없음 -->
  </div>
</div>
```

**개선 방향:** 모바일 메뉴 패널에 로그인 사용자용 알림 링크 + 프로필 링크를 명시적으로 추가. 알림 드롭다운은 모바일에서 별도 패널이나 링크로 대체.

**What:** 모바일 화면(375px)에서 navbar 드롭다운/알림이 접근 가능하도록 모바일 메뉴 섹션에 항목 추가.
**When to use:** `md:hidden` 모바일 메뉴 블록에 조건부 렌더링 추가.

```html
<!-- 개선 패턴: 모바일 메뉴에 알림 + 프로필 링크 추가 -->
<% if Current.user %>
  <%= link_to "알림", notifications_path, class: "block text-lg font-medium" %>
  <%= link_to "내 프로필", me_path, class: "block text-lg font-medium" %>
  <%= link_to "글쓰기", new_post_path, class: "block text-center bg-tv-gold ..." %>
  <% if Current.user.admin? %>
    <%= link_to "관리자", admin_root_path, class: "block text-lg font-medium" %>
  <% end %>
  <%= button_to "로그아웃", session_path, method: :delete, class: "..." %>
<% else %>
  ...
<% end %>
```

### Pattern 2: 모바일 반응형 - Admin 사이드바

**현황 파악:**
```html
<!-- 문제: 모바일에서 w-60 fixed 사이드바가 항상 렌더링됨 -->
<aside class="w-60 bg-tv-dark text-white min-h-screen fixed">
<main class="ml-60 flex-1 p-8">
```

**접근 방식 A (Off-canvas 슬라이드):** Stimulus `AdminSidebarController`로 토글 가능한 오프캔버스. 모바일에서는 숨기고 햄버거 버튼으로 열기.

**접근 방식 B (반응형 클래스만 조정):** `hidden md:block` + `md:w-60 w-0`으로 사이드바 숨기고, `ml-0 md:ml-60`으로 메인 조정. 모바일에서는 상단 바에 메뉴 버튼 추가.

**권장 방식:** B가 구현이 단순하고 Admin은 1인 운영자만 사용하므로 Over-engineering 방지. 단, 접근성을 위해 최소한의 Stimulus 토글은 필요.

```html
<!-- 개선 패턴 예시 -->
<aside class="hidden md:block w-60 bg-tv-dark text-white min-h-screen fixed"
       data-admin-sidebar-target="sidebar">
  ...
</aside>

<main class="ml-0 md:ml-60 flex-1 p-4 md:p-8">
  <!-- 모바일에서 상단에 메뉴 토글 버튼 -->
  <div class="md:hidden mb-4">
    <button data-action="click->admin-sidebar#toggle">메뉴</button>
  </div>
  ...
</main>
```

### Pattern 3: 커스텀 에러 페이지 (Rails 8)

**Rails 표준 패턴:**

Rails 8에서 커스텀 에러 페이지를 Rails 애플리케이션 레이아웃으로 렌더링하는 표준 방법:

1. `config/application.rb`에 `config.exceptions_app = self.routes` 추가
2. `config/routes.rb`에 에러 경로 추가
3. `ErrorsController` 생성
4. `app/views/errors/` 에 뷰 생성

**config/application.rb:**
```ruby
config.exceptions_app = self.routes
```

**routes.rb 추가:**
```ruby
# 에러 페이지
match "/404", to: "errors#not_found", via: :all
match "/500", to: "errors#internal_server_error", via: :all
match "/422", to: "errors#unprocessable_entity", via: :all
```

**ErrorsController:**
```ruby
# app/controllers/errors_controller.rb
class ErrorsController < ApplicationController
  # 에러 페이지는 인증 불필요
  allow_unauthenticated_access

  def not_found
    render status: :not_found
  end

  def internal_server_error
    render status: :internal_server_error
  end

  def unprocessable_entity
    render status: :unprocessable_entity
  end
end
```

**주의사항:** `ApplicationController`에 `allow_browser versions: :modern`이 있으므로 오래된 브라우저에서 500 에러 발생 시 무한 루프 가능성. `ErrorsController`는 ApplicationController 상속보다 직접 `ActionController::Base` 상속 검토 또는 `allow_browser` 예외 처리 필요.

**더 안전한 패턴:**
```ruby
class ErrorsController < ActionController::Base
  layout "application"
  include Authentication  # Current.user 사용 시 필요 (navbar 조건부 렌더링)

  def not_found
    render status: :not_found
  end

  def internal_server_error
    render status: :internal_server_error
  end
end
```

**뷰 예시:**
```erb
<%# app/views/errors/not_found.html.erb %>
<div class="max-w-[800px] mx-auto px-5 py-20 text-center">
  <div class="text-8xl font-black text-tv-gold mb-4">404</div>
  <h1 class="text-3xl font-black mb-4">페이지를 찾을 수 없습니다</h1>
  <p class="text-tv-gray mb-8">요청하신 페이지가 존재하지 않거나 이동되었습니다.</p>
  <%= link_to "홈으로 돌아가기", root_path,
    class: "inline-block bg-tv-gold text-tv-black rounded-pill px-8 py-3 font-bold hover:opacity-90" %>
</div>
```

### Pattern 4: Tailwind v4 반응형 주의사항

**v4에서 달라진 점:**
- `tailwind.config.js` 없음 → `@theme {}` 블록에서 커스텀 값 정의
- 브레이크포인트는 동일: `sm:` (640px), `md:` (768px), `lg:` (1024px), `xl:` (1280px)
- 커스텀 브레이크포인트 추가 시: `@theme { --breakpoint-xs: 375px; }`
- v4에서는 `screens` 설정 없음 — `@custom-media` 또는 `--breakpoint-*` 변수

**375px 모바일 타겟 접근 방식:**
```css
/* app/frontend/entrypoints/application.css */
@theme {
  /* 기존 @theme 블록에 추가 */
  --breakpoint-xs: 375px;
}
```

그러면 Tailwind에서 `xs:` 접두어 사용 가능. 단, 대부분의 경우 기본 `md:` 브레이크포인트(768px)를 기준으로 모바일-first 접근이 충분하다.

### Anti-Patterns to Avoid

- **에러 페이지에서 DB 쿼리:** 500 에러는 DB 자체가 문제일 수 있으므로, 500 뷰에서는 최소한의 렌더링. navbar의 알림 카운트 (`Current.user.notifications.unread.count`) 같은 쿼리가 에러 페이지 렌더링 중 또 다른 에러를 유발할 수 있음.
- **Admin 사이드바를 JavaScript에만 의존:** CSS `hidden md:block`으로 기본 숨김 처리 후 JS는 토글만 담당. JS 비활성화 시에도 기본 동작해야 함.
- **v4 설정을 v3 방식으로:** `tailwind.config.js` 만들거나 `@apply`로 커스텀 컴포넌트 클래스 추가 시 v4 방식(`@utility`, `@layer`) 사용.
- **public/404.html 유지 + exceptions_app 둘 다:** `config.exceptions_app = self.routes` 설정 후 Rails가 동적 라우터로 처리하므로 `public/404.html`은 자동으로 무시됨 (개발 환경에서는 show_exceptions이 override할 수 있음).

---

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| 모바일 메뉴 애니메이션 | CSS keyframe 직접 작성 | Tailwind `transition` + `hidden` 토글 | 기존 패턴과 일관성, 과도한 복잡도 방지 |
| 에러 페이지 미들웨어 | 커스텀 Rack 미들웨어 | `config.exceptions_app = self.routes` | Rails 8 표준 패턴, 유지보수 단순 |
| 반응형 그리드 | 직접 미디어쿼리 | Tailwind 반응형 접두어 | 프로젝트 기존 패턴과 일관성 |

**Key insight:** 이 Phase는 새 기능이 아닌 기존 코드 수정이다. 새 패키지, 새 아키텍처 도입 없이 기존 Tailwind 클래스와 Stimulus 패턴만으로 해결하는 것이 핵심이다.

---

## Common Pitfalls

### Pitfall 1: 500 에러 페이지에서 DB 쿼리 실행

**What goes wrong:** navbar partial(`_navbar.html.erb`)에 `Current.user.notifications.unread.count` 같은 DB 쿼리가 있어 500 에러 처리 중 또 다른 DB 에러 발생
**Why it happens:** `config.exceptions_app = self.routes`로 Rails 라우터가 에러 처리 → ApplicationController → 레이아웃 → navbar partial 렌더링
**How to avoid:** `ErrorsController`를 `ActionController::Base` 직접 상속하거나, `errors/internal_server_error.html.erb`에서 `layout false` 또는 별도 `error` 레이아웃 사용. 또는 navbar partial에 nil-safe 조건 추가 (`Current.user&.notifications&.unread&.count`)
**Warning signs:** 500 페이지 접근 시 또 다른 500 에러 발생 (무한 루프)

### Pitfall 2: Admin 에러 페이지 (admin 레이아웃 사용 시)

**What goes wrong:** `/admin` 경로에서 404 발생 시 admin 레이아웃(사이드바 포함)으로 에러 페이지가 렌더링됨
**Why it happens:** Rails exceptions_app은 원래 요청 URL 기반이 아니라 `ErrorsController`를 단순 호출
**How to avoid:** `ErrorsController`가 `application` 레이아웃을 명시적으로 사용 (`layout "application"`)하여 admin 레이아웃 방지
**Warning signs:** 에러 페이지에 admin 사이드바가 표시됨

### Pitfall 3: 개발 환경에서 exceptions_app 미작동

**What goes wrong:** 개발 환경에서 `config.consider_all_requests_local = true` (기본값)이므로 exceptions_app이 무시되고 Rails 기본 에러 페이지가 표시됨
**Why it happens:** 개발 환경은 상세한 에러 정보가 필요하므로 Rails가 자체 에러 페이지를 우선함
**How to avoid:** 에러 페이지 개발 시 테스트용으로 production 환경 시뮬레이션 필요. 또는 `config/environments/development.rb`에 임시로 `config.consider_all_requests_local = false` 추가하여 확인
**Warning signs:** 개발 환경에서 에러 페이지 변경이 반영되지 않음

### Pitfall 4: Tailwind v4 `@theme` 변수 충돌

**What goes wrong:** 기존 `@theme` 블록에 새 브레이크포인트 변수 추가 시 기존 변수 오버라이드
**Why it happens:** Tailwind v4는 `@theme` 블록 내 변수를 전역으로 처리
**How to avoid:** 기존 `application.css`의 `@theme {}` 블록에 **추가**만 하고, 기존 변수는 절대 삭제하거나 변경하지 말 것 (기존 코드 보존 원칙)
**Warning signs:** 기존 색상 유틸리티(`text-tv-gold` 등)가 사라짐

### Pitfall 5: Admin 사이드바 모바일 대응 - `ml-60` 잔류

**What goes wrong:** 사이드바를 `hidden md:block`으로 모바일에서 숨겼는데 `ml-60`이 main에 남아 있어 빈 공간 발생
**Why it happens:** 사이드바와 메인의 margin/padding이 짝을 이루어야 함
**How to avoid:** `<main class="ml-0 md:ml-60 ...">`으로 조정
**Warning signs:** 모바일에서 왼쪽에 빈 공백 240px이 항상 존재

---

## Code Examples

Verified patterns from project codebase:

### 현재 Admin 레이아웃 (문제 있는 부분)
```html
<!-- app/views/layouts/admin.html.erb (현재) -->
<aside class="w-60 bg-tv-dark text-white min-h-screen fixed">
  ...
</aside>
<main class="ml-60 flex-1 p-8">
  ...
</main>
```

### Admin 레이아웃 반응형 개선 패턴
```html
<!-- 개선 후: 모바일 off-canvas 패턴 -->
<div data-controller="admin-sidebar">
  <!-- 오버레이 (모바일) -->
  <div data-admin-sidebar-target="overlay"
       class="hidden fixed inset-0 bg-black/50 z-40 md:hidden"
       data-action="click->admin-sidebar#close">
  </div>

  <!-- 사이드바: 모바일은 transform으로 숨김, 데스크톱은 항상 표시 -->
  <aside data-admin-sidebar-target="sidebar"
         class="fixed inset-y-0 left-0 z-50 w-60 bg-tv-dark text-white
                -translate-x-full md:translate-x-0 transition-transform">
    ...
  </aside>

  <!-- 메인 콘텐츠 -->
  <main class="md:ml-60 flex-1 p-4 md:p-8 min-h-screen">
    <!-- 모바일 헤더 (햄버거 버튼) -->
    <div class="md:hidden flex items-center gap-4 mb-6 pb-4 border-b border-tv-cream">
      <button data-action="click->admin-sidebar#open"
              class="p-2 rounded-lg hover:bg-tv-cream">
        <svg class="w-6 h-6" ...>햄버거 아이콘</svg>
      </button>
      <span class="font-bold">TeoVibe Admin</span>
    </div>
    <%= render "shared/flash" %>
    <%= yield %>
  </main>
</div>
```

### AdminSidebarController (Stimulus)
```javascript
// app/javascript/controllers/admin_sidebar_controller.js
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["sidebar", "overlay"]

  open() {
    this.sidebarTarget.classList.remove("-translate-x-full")
    this.overlayTarget.classList.remove("hidden")
  }

  close() {
    this.sidebarTarget.classList.add("-translate-x-full")
    this.overlayTarget.classList.add("hidden")
  }
}
```

### Rails 커스텀 에러 페이지 설정
```ruby
# config/application.rb
config.exceptions_app = self.routes

# config/routes.rb
match "/404", to: "errors#not_found", via: :all
match "/500", to: "errors#internal_server_error", via: :all
match "/422", to: "errors#unprocessable_entity", via: :all

# app/controllers/errors_controller.rb
class ErrorsController < ActionController::Base
  # ActionController::Base 직접 상속 (DB 에러 시 안전)
  layout "application"

  def not_found
    render status: :not_found
  end

  def internal_server_error
    # 500은 가능한 단순하게 — DB 쿼리 없음
    render status: :internal_server_error, layout: "error"
  end

  def unprocessable_entity
    render status: :unprocessable_entity
  end
end
```

### 에러 레이아웃 (500용 - 최소 의존성)
```erb
<%# app/views/layouts/error.html.erb (500 에러 전용 심플 레이아웃) %>
<!DOCTYPE html>
<html lang="ko">
  <head>
    <title>TeoVibe</title>
    <meta name="viewport" content="width=device-width,initial-scale=1">
    <%= vite_client_tag %>
    <%= vite_javascript_tag 'application' %>
  </head>
  <body class="bg-tv-cream text-tv-black min-h-screen flex items-center justify-center">
    <%= yield %>
  </body>
</html>
```

### 404 에러 뷰
```erb
<%# app/views/errors/not_found.html.erb %>
<div class="max-w-[600px] mx-auto px-5 py-20 text-center">
  <div class="text-9xl font-black text-tv-gold mb-6">404</div>
  <h1 class="text-3xl md:text-4xl font-black mb-4">페이지를 찾을 수 없습니다</h1>
  <p class="text-tv-gray text-lg mb-10">
    요청하신 페이지가 존재하지 않거나 이동되었습니다.
  </p>
  <%= link_to "홈으로 돌아가기", root_path,
    class: "inline-block bg-tv-gold text-tv-black rounded-pill px-8 py-3 text-lg font-bold hover:opacity-90 transition-opacity" %>
</div>
```

### 500 에러 뷰
```erb
<%# app/views/errors/internal_server_error.html.erb %>
<div class="max-w-[600px] mx-auto px-5 py-20 text-center">
  <div class="text-9xl font-black text-tv-burgundy mb-6">500</div>
  <h1 class="text-3xl md:text-4xl font-black mb-4">서버 오류가 발생했습니다</h1>
  <p class="text-tv-gray text-lg mb-10">
    일시적인 문제가 발생했습니다. 잠시 후 다시 시도해주세요.
  </p>
  <%= link_to "홈으로 돌아가기", root_path,
    class: "inline-block bg-tv-gold text-tv-black rounded-pill px-8 py-3 text-lg font-bold hover:opacity-90 transition-opacity" %>
</div>
```

---

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| `public/404.html` 정적 HTML | `config.exceptions_app = self.routes` + ERB | Rails 3.2+ | 애플리케이션 레이아웃/스타일 재사용 가능 |
| `tailwind.config.js` `screens` 설정 | `@theme { --breakpoint-xs: ... }` | Tailwind v4 | 설정 파일 없이 CSS 내에서 직접 정의 |
| 별도 반응형 CSS 파일 | Tailwind 유틸리티 클래스만 | 현재 | 프로젝트 기존 패턴과 일관성 |

**Deprecated/outdated:**
- `tailwind.config.js`의 `screens` 설정: v4에서는 `@theme { --breakpoint-* }` 방식으로 대체
- `@apply` 남용: v4에서는 가능하나 공식 문서는 직접 유틸리티 클래스 권장
- `public/404.html` 직접 편집: Rails `exceptions_app` 설정 없이 수정해도 프로덕션에서만 사용됨

---

## Open Questions

1. **500 에러 페이지 레이아웃 수준**
   - What we know: 500은 DB가 다운된 상황일 수 있어 navbar의 DB 쿼리가 위험
   - What's unclear: 별도 `error` 레이아웃(navbar 없는 심플)을 만들 것인지, 500도 기존 application 레이아웃을 쓸 것인지
   - Recommendation: 500은 별도 심플 레이아웃 사용 (navbar DB 쿼리 방지). 404/422는 `application` 레이아웃 재사용

2. **Admin 사이드바 오프캔버스 복잡도**
   - What we know: Admin은 1인 운영자만 사용
   - What's unclear: Off-canvas 슬라이드 애니메이션이 필요한지, 단순히 숨기기만 해도 되는지
   - Recommendation: `translate-x` Tailwind 클래스로 슬라이드 구현 (CSS 트랜지션, 추가 라이브러리 불필요)

3. **422 (CSRF 토큰 만료) 에러 페이지 필요 여부**
   - What we know: Rails 기본 422 에러는 Turbo 사용 시 자주 발생 (새로고침 후 폼 제출)
   - What's unclear: 사용자에게 유용한 설명 제공이 필요한지
   - Recommendation: 404와 동일 패턴으로 간단히 "세션이 만료되었습니다" 페이지 제공

---

## Sources

### Primary (HIGH confidence)
- 프로젝트 코드 직접 확인 (`app/views/layouts/`, `app/views/shared/_navbar.html.erb`) - 현재 반응형 상태 파악
- 프로젝트 코드 직접 확인 (`app/frontend/entrypoints/application.css`, `package.json`) - Tailwind v4 설정 확인
- 프로젝트 코드 직접 확인 (`public/404.html`, `public/500.html`) - 현재 에러 페이지 상태 확인
- Rails 8.1 표준: `config.exceptions_app = self.routes` 패턴 (Rails 3.2부터 안정화된 표준 패턴)
- Tailwind v4 공식 패턴: `@theme {}` 인라인 블록으로 브레이크포인트 설정

### Secondary (MEDIUM confidence)
- Tailwind CSS v4 문서 패턴: `--breakpoint-*` 커스텀 브레이크포인트 정의 방식

### Tertiary (LOW confidence)
- 없음

---

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH - 프로젝트 코드 직접 확인으로 현재 상태 파악. 새 패키지 없음
- Architecture: HIGH - Rails 표준 exceptions_app 패턴, Tailwind v4 이미 사용 중
- Pitfalls: HIGH - 500 에러 시 DB 쿼리 문제는 잘 알려진 Rails 함정, 코드 직접 확인으로 navbar 쿼리 존재 확인

**Research date:** 2026-02-22
**Valid until:** 2026-04-22 (Tailwind v4, Rails 8.1 안정 버전, 빠른 변경 없음)
