---
phase: 08-ai-초안-작성
plan: "01"
subsystem: api
tags: [anthropic, claude-api, rails, minitest, tdd, admin, json-api]

requires:
  - phase: 07-scheduled-publishing
    provides: Admin::BaseController 상속 패턴, admin 인증 구조

provides:
  - AiDraftService: Anthropic Claude API 래퍼 (SEO/AEO SYSTEM_PROMPT + generate_outline/generate_body)
  - POST /admin/ai_draft/outline JSON 엔드포인트
  - POST /admin/ai_draft/body JSON 엔드포인트
  - anthropic gem v1.23.0 설치

affects: [08-02-frontend, 프론트엔드 AI 초안 UI 연동]

tech-stack:
  added: [anthropic ~> 1.23.0]
  patterns: [Service object pattern (AiDraftService), Admin JSON API, minitest stub with define_singleton_method]

key-files:
  created:
    - teovibe/app/services/ai_draft_service.rb
    - teovibe/app/controllers/admin/ai_drafts_controller.rb
    - teovibe/test/services/ai_draft_service_test.rb
    - teovibe/test/controllers/admin/ai_drafts_controller_test.rb
  modified:
    - teovibe/Gemfile
    - teovibe/Gemfile.lock
    - teovibe/config/routes.rb

key-decisions:
  - "anthropic gem v1.23.0 사용 (STATE.md 기결정 사항 준수)"
  - "minitest 6.x에서는 minitest/mock이 없으므로 define_singleton_method 기반 stub 패턴 사용"
  - "AiDraftService 에러는 rescue 블록에서 422 + { error: message } JSON으로 반환"
  - "model: claude-opus-4-5-20250929 사용 (최신 claude-opus 계열)"

patterns-established:
  - "Admin JSON API: Admin::BaseController 상속으로 인증 자동 적용, render json: + rescue 패턴"
  - "minitest 6 stub: define_singleton_method(:new) { fake_obj } + ensure 블록에서 remove_method로 복원"

requirements-completed: [AIDR-01, AIDR-02, AIDR-03, AIDR-04]

duration: 5min
completed: 2026-03-05
---

# Phase 08 Plan 01: AI 초안 작성 백엔드 Summary

**anthropic gem v1.23.0 기반 AiDraftService(SEO/AEO 시스템 프롬프트 + outline/body 생성)와 Admin JSON API 엔드포인트 2개 구현 완료**

## Performance

- **Duration:** 5 min
- **Started:** 2026-03-04T16:58:36Z
- **Completed:** 2026-03-04T17:03:06Z
- **Tasks:** 2
- **Files modified:** 7

## Accomplishments

- anthropic gem v1.23.0 설치 및 AiDraftService 구현 (SEO/AEO SYSTEM_PROMPT: H2/H3/FAQ 포함)
- POST /admin/ai_draft/outline, POST /admin/ai_draft/body JSON API 엔드포인트 구현
- Admin::BaseController 상속으로 관리자 인증 자동 적용 (비인증 시 root 리다이렉트)
- Minitest 7개 테스트 통과 (서비스 3개 + 컨트롤러 4개)

## Task Commits

각 태스크가 독립적으로 커밋됨:

1. **Task 1: anthropic gem 설치 + AiDraftService 구현** - `1319893` (feat)
2. **Task 2: AiDraftsController + 라우트 + 컨트롤러 테스트** - `5db9732` (feat)

## Files Created/Modified

- `teovibe/app/services/ai_draft_service.rb` - Anthropic API 래퍼, SYSTEM_PROMPT 상수, generate_outline/generate_body
- `teovibe/app/controllers/admin/ai_drafts_controller.rb` - outline/body JSON 엔드포인트, 에러 핸들링
- `teovibe/config/routes.rb` - admin namespace에 resource :ai_draft collection 라우트 추가
- `teovibe/test/services/ai_draft_service_test.rb` - SYSTEM_PROMPT 검증, API 파라미터 검증 (3 tests)
- `teovibe/test/controllers/admin/ai_drafts_controller_test.rb` - JSON 응답, 422 에러, Admin 인증 (4 tests)
- `teovibe/Gemfile` - anthropic gem 추가
- `teovibe/Gemfile.lock` - bundle install 결과

## Decisions Made

- minitest 6.x에서 `minitest/mock`이 제거되었으므로, `define_singleton_method`를 활용한 수동 stub 패턴 사용 (ensure 블록에서 `remove_method`로 복원)
- AiDraftService 에러는 컨트롤러의 rescue 블록에서 422 + JSON으로 처리 (raise하지 않음)

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] minitest/mock 로드 실패 → define_singleton_method stub 패턴으로 대체**
- **Found during:** Task 1 (테스트 작성)
- **Issue:** 플랜에서 `Minitest::Mock`을 사용하도록 명시했으나, minitest 6.x에서는 `minitest/mock`이 존재하지 않음 (LoadError)
- **Fix:** Ruby의 `define_singleton_method` + ensure 블록으로 클래스 메서드를 임시 교체하는 방식으로 stub 구현
- **Files modified:** test/services/ai_draft_service_test.rb, test/controllers/admin/ai_drafts_controller_test.rb
- **Verification:** 7개 테스트 모두 통과
- **Committed in:** 1319893, 5db9732

---

**Total deviations:** 1 auto-fixed (1 blocking)
**Impact on plan:** minitest 6.x 호환성 문제 해결, 동등한 테스트 커버리지 달성. 기능 범위 변화 없음.

## Issues Encountered

- minitest 6.x에서 `Minitest::Mock`과 `Object#stub`이 모두 제거됨. Rails의 `Object#stub` 메서드도 minitest 5.x 전용. `define_singleton_method` 패턴으로 해결.

## User Setup Required

**ANTHROPIC_API_KEY 환경변수 설정 필요:**
- `.env` 파일에 `ANTHROPIC_API_KEY=sk-ant-...` 추가
- 프로덕션(Kamal) 배포 시 `.kamal/secrets`에 `ANTHROPIC_API_KEY=$ANTHROPIC_API_KEY` 추가
- 테스트에서는 stub으로 처리하므로 키 없이 테스트 통과 가능

## Next Phase Readiness

- Plan 02 (프론트엔드 AI 초안 UI)에서 즉시 연동 가능한 JSON API 엔드포인트 준비 완료
- outline_admin_ai_draft_path, body_admin_ai_draft_path 라우트 헬퍼 사용 가능
- ANTHROPIC_API_KEY 설정 후 실제 API 호출 가능

## Self-Check: PASSED

- teovibe/app/services/ai_draft_service.rb: FOUND
- teovibe/app/controllers/admin/ai_drafts_controller.rb: FOUND
- teovibe/test/services/ai_draft_service_test.rb: FOUND
- teovibe/test/controllers/admin/ai_drafts_controller_test.rb: FOUND
- .planning/phases/08-ai-초안-작성/08-01-SUMMARY.md: FOUND
- commit 1319893: FOUND
- commit 5db9732: FOUND

---
*Phase: 08-ai-초안-작성*
*Completed: 2026-03-05*
