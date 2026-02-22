---
phase: 05-polish
plan: 02
subsystem: ui
tags: [rails, error-pages, exceptions-app, erb, tailwind]

# Dependency graph
requires:
  - phase: 01-foundation
    provides: application 레이아웃, Vite 설정, Tailwind @theme 변수 (tv-gold/burgundy/orange)
provides:
  - Rails exceptions_app 패턴으로 커스텀 에러 페이지 렌더링
  - ErrorsController (ActionController::Base 직접 상속, DB 의존 없음)
  - 404/422 에러 뷰 (application 레이아웃, navbar 포함)
  - 500 에러 뷰 (error 전용 레이아웃, navbar 없음, DB 쿼리 방지)
affects: []

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "exceptions_app = self.routes 패턴으로 Rails 라우터가 에러 처리 담당"
    - "ErrorsController < ActionController::Base (ApplicationController 우회로 DB 의존성 제거)"
    - "500은 별도 error 레이아웃으로 navbar DB 쿼리 방지"

key-files:
  created:
    - teovibe/app/controllers/errors_controller.rb
    - teovibe/app/views/layouts/error.html.erb
    - teovibe/app/views/errors/not_found.html.erb
    - teovibe/app/views/errors/internal_server_error.html.erb
    - teovibe/app/views/errors/unprocessable_entity.html.erb
  modified:
    - teovibe/config/application.rb
    - teovibe/config/routes.rb

key-decisions:
  - "ErrorsController는 ActionController::Base 직접 상속 (ApplicationController 아님) — include Authentication 등 DB 의존성 우회"
  - "500 에러는 별도 error 레이아웃 사용 — navbar 렌더링 시 Current.user 등 DB 쿼리 위험 제거"
  - "에러 뷰에서 link_to/root_path 대신 <a href='/'> 직접 사용 — ActionController::Base는 Rails URL 헬퍼 미포함"
  - "색상 체계: 404=tv-gold(경고), 500=tv-burgundy(심각), 422=tv-orange(주의)"

patterns-established:
  - "exceptions_app 패턴: config.exceptions_app = self.routes + match '/404' to errors#action"
  - "에러 전용 레이아웃 분리: DB/세션 의존 없는 최소 HTML 구조"

requirements-completed: [UIUX-02]

# Metrics
duration: 5min
completed: 2026-02-22
---

# Phase 5 Plan 02: 커스텀 에러 페이지 Summary

**Rails exceptions_app 패턴으로 404/500/422 브랜드 한글 에러 페이지 구현 — 500은 DB 의존 없는 별도 error 레이아웃으로 안전 렌더링**

## Performance

- **Duration:** 5 min
- **Started:** 2026-02-22T13:20:00Z
- **Completed:** 2026-02-22T13:25:22Z
- **Tasks:** 2
- **Files modified:** 7

## Accomplishments

- config.exceptions_app = self.routes 설정으로 Rails 라우터가 에러 페이지 처리
- ErrorsController를 ActionController::Base로 직접 상속하여 DB/인증 의존성 완전 분리
- 404(tv-gold)/500(tv-burgundy)/422(tv-orange) 브랜드 색상 한글 에러 뷰 3개 구현
- 500 전용 error 레이아웃 생성 (navbar 없음, Pretendard+Vite만 로드)

## Task Commits

Each task was committed atomically:

1. **Task 1: ErrorsController + 에러 라우트 + exceptions_app 설정** - `f4d42f5` (feat)
2. **Task 2: 커스텀 에러 뷰 3개 브랜드 스타일링** - `47ec8d2` (feat)

**Plan metadata:** (docs commit below)

## Files Created/Modified

- `teovibe/config/application.rb` - config.exceptions_app = self.routes 추가
- `teovibe/config/routes.rb` - /404, /500, /422 에러 라우트 3개 추가
- `teovibe/app/controllers/errors_controller.rb` - ActionController::Base 상속 에러 컨트롤러 (신규)
- `teovibe/app/views/layouts/error.html.erb` - 500 전용 최소 레이아웃 (신규)
- `teovibe/app/views/errors/not_found.html.erb` - 404 한글 에러 뷰 tv-gold (신규)
- `teovibe/app/views/errors/internal_server_error.html.erb` - 500 한글 에러 뷰 tv-burgundy (신규)
- `teovibe/app/views/errors/unprocessable_entity.html.erb` - 422 한글 에러 뷰 tv-orange (신규)

## Decisions Made

- ErrorsController를 ApplicationController가 아닌 ActionController::Base로 직접 상속. 이유: ApplicationController에 include Authentication이 있어 세션/DB 의존성 발생, allow_browser 등 미들웨어도 에러 페이지에서 무한루프 유발 가능
- 500 에러는 별도 error 레이아웃 사용. 이유: DB 다운 상황에서 navbar의 Current.user 조회 등 DB 쿼리 실패 위험
- 에러 뷰에서 `<a href="/">` 직접 사용. 이유: ActionController::Base는 Rails URL 헬퍼(link_to, root_path) 미포함, 에러 페이지 의존성 최소화 원칙

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered

None

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- 커스텀 에러 페이지 완성. 프로덕션 수준의 브랜드 일관성 확보
- 05-polish 완료를 위한 나머지 플랜 진행 가능

---
*Phase: 05-polish*
*Completed: 2026-02-22*
