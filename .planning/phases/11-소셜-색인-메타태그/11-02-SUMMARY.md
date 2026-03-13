---
phase: 11-소셜-색인-메타태그
plan: "02"
subsystem: seo
tags: [rails, meta-tags, noindex, robots, seo, tdd]

# Dependency graph
requires:
  - phase: 11-소셜-색인-메타태그/11-01
    provides: set_meta_tags 인프라 (meta-tags gem 설치 + application.html.erb display_meta_tags)
provides:
  - Admin 레이아웃에 noindex 메타태그 하드코딩 삽입
  - SessionsController new 액션에 set_meta_tags noindex: true
  - RegistrationsController new 액션에 set_meta_tags noindex: true
  - noindex 통합 테스트 (3개 케이스)
affects: [12-구조화-데이터]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - Admin 레이아웃은 display_meta_tags 미사용 — <meta> 태그 직접 삽입 방식
    - 컨트롤러 before_action으로 set_meta_tags noindex: true 호출 패턴

key-files:
  created:
    - teovibe/test/integration/noindex_test.rb
  modified:
    - teovibe/app/views/layouts/admin.html.erb
    - teovibe/app/controllers/sessions_controller.rb
    - teovibe/app/controllers/registrations_controller.rb

key-decisions:
  - "Admin 레이아웃은 display_meta_tags를 사용하지 않으므로 <meta name='robots' content='noindex'>를 직접 삽입"
  - "SessionsController/RegistrationsController는 before_action :set_noindex 패턴으로 noindex 설정"

patterns-established:
  - "display_meta_tags 미사용 레이아웃(admin)은 직접 meta 태그 삽입"
  - "컨트롤러에서 특정 액션에만 noindex 적용: before_action :set_noindex, only: %i[new]"

requirements-completed: [INDX-02, INDX-03]

# Metrics
duration: 2min
completed: 2026-03-13
---

# Phase 11 Plan 02: Admin/인증 페이지 noindex 메타태그 Summary

**Admin 레이아웃 직접 삽입 + before_action set_meta_tags로 로그인/회원가입 페이지 noindex 처리, 통합 테스트 3개 통과**

## Performance

- **Duration:** 2 min
- **Started:** 2026-03-13T17:21:08Z
- **Completed:** 2026-03-13T17:23:14Z
- **Tasks:** 1 (TDD: RED + GREEN 커밋 2개)
- **Files modified:** 4

## Accomplishments
- Admin 레이아웃 head에 `<meta name="robots" content="noindex">` 직접 삽입 — 모든 Admin 페이지 자동 적용
- SessionsController new 액션에 before_action :set_noindex 추가 — 로그인 페이지 noindex 출력
- RegistrationsController new 액션에 before_action :set_noindex 추가 — 회원가입 페이지 noindex 출력
- noindex 통합 테스트 3개 작성 및 통과 (Admin, 로그인, 회원가입)

## Task Commits

TDD 사이클로 커밋 2개:

1. **RED: noindex 테스트 작성** - `78ba7ad` (test)
2. **GREEN: noindex 메타태그 구현** - `a70b03d` (feat)

## Files Created/Modified
- `teovibe/test/integration/noindex_test.rb` - Admin/로그인/회원가입 페이지 noindex 메타태그 통합 테스트 (3 케이스)
- `teovibe/app/views/layouts/admin.html.erb` - head에 `<meta name="robots" content="noindex">` 직접 삽입
- `teovibe/app/controllers/sessions_controller.rb` - before_action :set_noindex, set_meta_tags noindex: true
- `teovibe/app/controllers/registrations_controller.rb` - before_action :set_noindex, set_meta_tags noindex: true

## Decisions Made
- Admin 레이아웃은 `display_meta_tags`를 사용하지 않으므로 `<meta>` 태그를 직접 head에 삽입 — 가장 확실한 방법
- 컨트롤러에서는 `before_action :set_noindex, only: %i[new]` 패턴으로 특정 액션에만 noindex 적용

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] 통합 테스트 admin 로그인 방식 수정**
- **Found during:** RED 실패 분석
- **Issue:** 계획에서는 `post session_path` + `after_authentication_url` 사용을 제안했으나, `after_authentication_url`이 integration test 컨텍스트에서 undefined
- **Fix:** 기존 `sign_in_as` 헬퍼(test/test_helpers/session_test_helper.rb)로 교체 — 다른 통합 테스트와 일관된 방식
- **Files modified:** teovibe/test/integration/noindex_test.rb
- **Verification:** 3 tests PASS
- **Committed in:** 78ba7ad (RED 커밋 내 수정)

---

**Total deviations:** 1 auto-fixed (Rule 1 - Bug)
**Impact on plan:** 테스트 헬퍼 방식 통일로 일관성 향상. 기능 범위에 영향 없음.

## Issues Encountered
- `after_authentication_url` 메서드가 integration test 컨텍스트에서 사용 불가 — 기존 `sign_in_as` 헬퍼로 해결

## User Setup Required
None - 외부 서비스 설정 불필요.

## Next Phase Readiness
- Phase 11 Plan 02 완료: Admin/인증 페이지 noindex 처리 완성
- Phase 12(구조화 데이터 JSON-LD) 진행 가능

---
## Self-Check: PASSED

- noindex_test.rb: FOUND
- admin.html.erb: FOUND
- sessions_controller.rb: FOUND
- registrations_controller.rb: FOUND
- Commit 78ba7ad (RED): FOUND
- Commit a70b03d (GREEN): FOUND

*Phase: 11-소셜-색인-메타태그*
*Completed: 2026-03-13*
