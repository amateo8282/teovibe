---
phase: 01-foundation
plan: 03
subsystem: ui
tags: [view_component, react, vite, turbo, rails]

# Dependency graph
requires:
  - phase: 01-01
    provides: vite_rails 빌드 파이프라인 (JSX/TSX 빌드, @vitejs/plugin-react)

provides:
  - ViewComponent 4.4 설치 및 ApplicationComponent 베이스 클래스
  - CardComponent (title, body) — 첫 서버사이드 재사용 컴포넌트
  - ReactDemo.tsx — React 컴포넌트 전용 페이지 마운트 패턴
  - react-demo.jsx 진입점 — turbo:load/turbo:before-cache 이벤트 기반 마운트/언마운트
  - /demo/react 페이지 — ViewComponent와 React 컴포넌트 공존 검증

affects:
  - 모든 후속 Phase (ViewComponent 패턴 사용)
  - Phase 2 (React 컴포넌트 구현 시 이 패턴 재사용)

# Tech tracking
tech-stack:
  added:
    - view_component 4.4 (Rails ViewComponent gem)
  patterns:
    - ViewComponent 베이스 클래스(ApplicationComponent) 상속 패턴
    - React 전용 페이지 마운트 패턴 (turbo:load + turbo:before-cache)
    - vite_javascript_tag + content_for :head 조합으로 페이지별 JS 로드

key-files:
  created:
    - app/components/application_component.rb
    - app/components/card_component.rb
    - app/components/card_component.html.erb
    - app/frontend/components/ReactDemo.tsx
    - app/frontend/entrypoints/react-demo.jsx
    - app/controllers/demo_controller.rb
    - app/views/demo/react.html.erb
  modified:
    - Gemfile (view_component 추가)
    - config/routes.rb (demo/react 라우트 추가)
    - app/controllers/application_controller.rb (stale_when_importmap_changes 제거)

key-decisions:
  - "React 마운트 방식: turbo:load 진입 시 마운트, turbo:before-cache 이탈 시 언마운트 (중복 마운트 방지)"
  - "root 레퍼런스를 module 스코프에 저장하여 Turbo Drive 재방문 시 createRoot 중복 경고 방지"
  - "content_for :head 블록으로 페이지별 React 진입점 로드 (전역 로드 방지)"

patterns-established:
  - "ViewComponent 패턴: ApplicationComponent 상속, ERB 템플릿 분리"
  - "React 전용 페이지 패턴: 진입점(entrypoints/) + 컴포넌트(components/) 분리, turbo 이벤트 기반 라이프사이클"
  - "페이지별 JS 로드: content_for :head + vite_javascript_tag 조합"

requirements-completed: [INFRA-03, INFRA-01]

# Metrics
duration: 7min
completed: 2026-02-22
---

# Phase 1 Plan 03: ViewComponent 및 React 전용 페이지 마운트 Summary

**ViewComponent 4.4로 CardComponent 서버사이드 컴포넌트 구축 및 turbo:load/turbo:before-cache 이벤트 기반 React 전용 페이지 마운트 패턴 검증**

## Performance

- **Duration:** 7 min
- **Started:** 2026-02-22T08:01:18Z
- **Completed:** 2026-02-22T08:04:11Z
- **Tasks:** 2
- **Files modified:** 10

## Accomplishments
- ViewComponent 4.4 설치 및 ApplicationComponent 베이스 클래스 + CardComponent 구현
- turbo:load/turbo:before-cache 이벤트 기반 React 마운트/언마운트 패턴 확립
- /demo/react 페이지에서 ViewComponent(서버사이드)와 React(클라이언트사이드) 공존 검증

## Task Commits

각 태스크는 원자적으로 커밋됨:

1. **Task 1: ViewComponent 설치 및 CardComponent 생성** - `95a2a32` (feat)
2. **Task 2: React 데모 컴포넌트 전용 페이지 마운트** - `8a1b8d8` (feat)

## Files Created/Modified
- `app/components/application_component.rb` - ViewComponent 베이스 클래스
- `app/components/card_component.rb` - 첫 ViewComponent (title, body 파라미터)
- `app/components/card_component.html.erb` - CardComponent ERB 템플릿
- `app/frontend/components/ReactDemo.tsx` - React 데모 컴포넌트 (카운터, 마운트 상태)
- `app/frontend/entrypoints/react-demo.jsx` - React 진입점 (Turbo 이벤트 기반 마운트)
- `app/controllers/demo_controller.rb` - 데모 컨트롤러 (allow_unauthenticated_access)
- `app/views/demo/react.html.erb` - ViewComponent + React 공존 페이지
- `Gemfile` - view_component 4.4 추가
- `config/routes.rb` - demo/react 라우트 추가
- `app/controllers/application_controller.rb` - importmap 잔재 제거

## Decisions Made
- turbo:before-render 대신 turbo:before-cache 사용 (RESEARCH.md 권장 — 캐시 오염 방지)
- root 레퍼런스를 module 스코프에 저장하여 Turbo Drive 재방문 시 중복 마운트 방지
- content_for :head 블록으로 페이지별 JS 엔트리포인트 로드 (전역 로드 방지)

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] importmap 잔재 stale_when_importmap_changes 제거**
- **Found during:** Task 2 (DemoController 동작 검증)
- **Issue:** ApplicationController에 `stale_when_importmap_changes` 호출이 남아 있었는데, 01-01에서 importmap을 vite_rails로 전환하면서 해당 메서드가 사라져 DemoController 로드 시 NoMethodError 발생
- **Fix:** ApplicationController에서 `stale_when_importmap_changes` 호출 한 줄 제거
- **Files modified:** `app/controllers/application_controller.rb`
- **Verification:** `bin/rails runner "puts DemoController.new.class.name"` 정상 출력 확인
- **Committed in:** `8a1b8d8` (Task 2 커밋)

---

**Total deviations:** 1 auto-fixed (Rule 1 - Bug)
**Impact on plan:** importmap 전환 시 생긴 잔재 제거. 정상 동작에 필수. 범위 초과 없음.

## Issues Encountered
None — Task 1 및 Task 2 모두 계획대로 진행됨. importmap 잔재는 Rule 1으로 즉시 수정됨.

## User Setup Required
None — 외부 서비스 설정 불필요.

## Next Phase Readiness
- ViewComponent 패턴 확립 완료 — 이후 모든 서버사이드 UI 컴포넌트는 app/components/ 에 구현
- React 전용 페이지 마운트 패턴 확립 완료 — Phase 2 이후 React 페이지 구현 시 재사용
- /demo/react 페이지에서 ViewComponent + React 공존 패턴 검증 완료
- Phase 1 Foundation 3개 플랜 모두 완료

---
*Phase: 01-foundation*
*Completed: 2026-02-22*
