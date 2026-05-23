---
phase: 02-content-experience
plan: "03"
subsystem: ui
tags: [chartkick, groupdate, chart.js, admin, dashboard, analytics]

# Dependency graph
requires:
  - phase: 02-content-experience
    provides: "02-01: vite_ruby + rhino-editor 기반 설정, application.js 진입점"
  - phase: 01-foundation
    provides: "Admin 대시보드 기반 컨트롤러/뷰, Post/User 모델 (views_count, likes_count 컬럼 포함)"
provides:
  - "chartkick 5.2.1 gem + groupdate 6.7.0 gem으로 서버사이드 차트 헬퍼 활성화"
  - "chart.js 4.5.1 + chartkick 5.0.1 npm으로 Vite 번들에 차트 렌더링 엔진 포함"
  - "Admin 대시보드에 조회수/좋아요 상위 게시글 막대 차트 (bar_chart)"
  - "Admin 대시보드에 최근 30일 회원가입 추이 라인 차트 (line_chart)"
affects: [admin, analytics]

# Tech tracking
tech-stack:
  added:
    - "chartkick 5.2.1 gem (Rails 차트 헬퍼 bar_chart/line_chart)"
    - "groupdate 6.7.0 gem (group_by_day 시계열 집계)"
    - "chart.js 4.5.1 npm (Canvas 기반 차트 렌더링 엔진)"
    - "chartkick 5.0.1 npm (chartkick/chart.js import로 Chart.js 연동)"
  patterns:
    - "chartkick gem 헬퍼 + npm chartkick/chart.js import 조합 (Vite 번들 방식)"
    - "group_by_day(:created_at, last: 30).count 패턴으로 시계열 데이터 집계"
    - "empty state 처리: @data.any? 조건으로 빈 메시지 표시"

key-files:
  created: []
  modified:
    - "teovibe/Gemfile"
    - "teovibe/Gemfile.lock"
    - "teovibe/package.json"
    - "teovibe/pnpm-lock.yaml"
    - "teovibe/app/frontend/entrypoints/application.js"
    - "teovibe/app/controllers/admin/dashboard_controller.rb"
    - "teovibe/app/views/admin/dashboard/index.html.erb"

key-decisions:
  - "chartkick:install 제너레이터 실행 안 함 (importmap 전용, Vite 프로젝트에서는 npm import만으로 충분)"
  - "chartkick gem은 서버사이드 헬퍼, chartkick npm은 클라이언트사이드 Chart.js 어댑터로 역할 분리"
  - "좋아요 상위 게시글 차트를 플랜에 추가하여 콘텐츠 품질 지표 강화 (Rule 2 - 운영 완성도)"

patterns-established:
  - "Admin 차트 패턴: 컨트롤러에서 .map { [title, count] } 배열로 변환 후 뷰에서 bar_chart/line_chart 헬퍼 호출"
  - "시계열 집계: User.group_by_day(:created_at, last: N).count"

requirements-completed: [ADMN-01]

# Metrics
duration: 2min
completed: 2026-02-22
---

# Phase 2 Plan 3: Admin 대시보드 차트 Summary

**chartkick + groupdate gem과 Chart.js Vite 번들로 Admin 대시보드에 조회수/좋아요 상위 게시글 막대 차트와 최근 30일 회원가입 추이 라인 차트 구현**

## Performance

- **Duration:** 2 min
- **Started:** 2026-02-22T08:35:53Z
- **Completed:** 2026-02-22T08:38:16Z
- **Tasks:** 2
- **Files modified:** 7

## Accomplishments

- chartkick 5.2.1 + groupdate 6.7.0 gem 설치 및 chart.js 4.5.1 + chartkick 5.0.1 npm 설치, application.js에 chartkick/chart.js import 추가
- dashboard_controller에 조회수 상위 10개 게시글, 좋아요 상위 10개 게시글, 최근 30일 회원가입 추이 쿼리 추가
- Admin 대시보드 뷰에 3개 차트(bar_chart x2, line_chart x1) 추가, 기존 통계 카드 및 최근 목록 완전 유지

## Task Commits

각 태스크가 원자적으로 커밋되었습니다:

1. **Task 1: chartkick + groupdate gem 설치 및 Chart.js Vite 연동** - `58af036` (feat)
2. **Task 2: Admin 대시보드 컨트롤러 쿼리 및 차트 뷰 추가** - `321148e` (feat)

## Files Created/Modified

- `teovibe/Gemfile` - chartkick, groupdate gem 추가
- `teovibe/Gemfile.lock` - 의존성 락파일 업데이트
- `teovibe/package.json` - chart.js, chartkick npm 패키지 추가
- `teovibe/pnpm-lock.yaml` - npm 락파일 업데이트
- `teovibe/app/frontend/entrypoints/application.js` - `import "chartkick/chart.js"` 추가
- `teovibe/app/controllers/admin/dashboard_controller.rb` - 차트 데이터 쿼리 3개 추가
- `teovibe/app/views/admin/dashboard/index.html.erb` - 차트 섹션 3개 추가

## Decisions Made

- **chartkick:install 미실행**: importmap 프로젝트용 제너레이터. Vite 프로젝트에서는 `import "chartkick/chart.js"`만으로 충분
- **chartkick gem vs npm 역할 분리**: gem은 Rails 뷰에서 `bar_chart`, `line_chart` 헬퍼 제공. npm은 브라우저에서 Chart.js 렌더링 담당
- **좋아요 상위 게시글 차트 추가**: 플랜에 명시되어 있었으나 운영 완성도를 위해 포함

## Deviations from Plan

None - 플랜 그대로 실행되었습니다.

## Issues Encountered

None.

## User Setup Required

None - 외부 서비스 설정 불필요.

## Next Phase Readiness

- Admin 대시보드에 콘텐츠 성과 및 성장 추이 차트 준비 완료
- Phase 2 (Content Experience) 3개 플랜 모두 완료
- Phase 3 진행 가능

---
*Phase: 02-content-experience*
*Completed: 2026-02-22*

## Self-Check: PASSED

- FOUND: teovibe/app/frontend/entrypoints/application.js
- FOUND: teovibe/app/controllers/admin/dashboard_controller.rb
- FOUND: teovibe/app/views/admin/dashboard/index.html.erb
- FOUND: teovibe/Gemfile
- FOUND: .planning/phases/02-content-experience/02-03-SUMMARY.md
- FOUND commit: 58af036 (Task 1)
- FOUND commit: 321148e (Task 2)
