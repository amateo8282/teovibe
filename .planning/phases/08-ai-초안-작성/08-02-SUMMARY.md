---
phase: 08-ai-초안-작성
plan: "02"
subsystem: ui
tags: [stimulus, javascript, rails, rhino-editor, ai, fetch, csrf]

# Dependency graph
requires:
  - phase: 08-01
    provides: Admin::AiDraftsController JSON API (outline/body 엔드포인트)
provides:
  - Stimulus ai_draft_controller.js (개요 생성, 본문 생성, rhino-editor 삽입, 로딩/에러 상태)
  - Admin 게시글 폼 AI 초안 패널 UI (주제 입력, 개요 textarea, 본문 생성 버튼)
affects: [admin-posts, frontend-controllers]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Stimulus Controller fetch 패턴: X-CSRF-Token 헤더 + response.ok 체크 + setLoading으로 중복 방지"
    - "rhino-editor 삽입: editor.commands.setContent + updateInputElementValue() 필수 호출"
    - "stimulus-vite-helpers glob 자동 등록: *_controller.js 파일명만 맞으면 index.js 수정 불필요"

key-files:
  created:
    - teovibe/app/frontend/controllers/ai_draft_controller.js
  modified:
    - teovibe/app/views/admin/posts/_form.html.erb

key-decisions:
  - "stimulus-vite-helpers의 import.meta.glob 자동 등록 방식으로 index.js 수동 수정 불필요"
  - "generateBodyBtn 타겟 제거: element.querySelectorAll('button[data-action]')로 모든 버튼 일괄 비활성화"

patterns-established:
  - "Stimulus Controller: static targets/values 선언 + hasXxxTarget 가드 패턴"
  - "Admin 폼 AI 패널: data-controller 루트 div + data-ai-draft-*-url-value Rails helper 패턴"

requirements-completed: [AIDR-01, AIDR-02, AIDR-03]

# Metrics
duration: 15min
completed: 2026-03-05
---

# Phase 8 Plan 02: AI 초안 작성 프론트엔드 Summary

**Stimulus ai_draft_controller.js로 주제 입력 → 개요 생성 → textarea 수정 → 본문 생성 → rhino-editor 삽입 전체 흐름 구현 및 Admin 게시글 폼에 AI 초안 패널 UI 추가**

## Performance

- **Duration:** 15 min
- **Started:** 2026-03-04T17:04:12Z
- **Completed:** 2026-03-04T17:11:17Z
- **Tasks:** 2 (auto) + 1 (checkpoint:human-verify - pending)
- **Files modified:** 2

## Accomplishments

- Stimulus Controller `ai_draft_controller.js` 구현: generateOutline/generateBody/setLoading/showError
- Admin 게시글 폼(`_form.html.erb`) 상단에 AI 초안 패널 UI 삽입 (기존 코드 보존)
- X-CSRF-Token 헤더 포함 fetch POST, rhino-editor에 `setContent + updateInputElementValue` 삽입
- 로딩 중 버튼 비활성화로 중복 API 요청 방지

## Task Commits

1. **Task 1: Stimulus ai_draft_controller.js 구현** - `4bfb4f6` (feat)
2. **Task 2: Admin 게시글 폼 AI 초안 패널 UI 추가** - `84292a7` (feat)

## Files Created/Modified

- `teovibe/app/frontend/controllers/ai_draft_controller.js` - Stimulus Controller: generateOutline/generateBody/setLoading/showError/clearError
- `teovibe/app/views/admin/posts/_form.html.erb` - AI 초안 패널 UI 추가 (data-controller="ai-draft", 주제 입력/개요/본문 생성 버튼)

## Decisions Made

- `stimulus-vite-helpers`의 `import.meta.glob("./**/*_controller.js")` 자동 등록 방식 확인 후 index.js 수정 불필요
- 플랜의 `generateBodyBtn` 타겟 제거: `element.querySelectorAll("button[data-action]")`으로 버튼 일괄 비활성화가 더 견고함

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] generateBodyBtn 타겟 제거**
- **Found during:** Task 1 (ai_draft_controller.js 구현)
- **Issue:** 플랜 코드에서 `static targets`에 `generateBodyBtn`이 포함되어 있었으나, outlinePanel이 hidden일 때 타겟 오류 발생 가능성
- **Fix:** `element.querySelectorAll("button[data-action]")`으로 모든 버튼을 한번에 비활성화하는 방식 채택
- **Files modified:** teovibe/app/frontend/controllers/ai_draft_controller.js
- **Verification:** 버튼 비활성화 로직 정상 동작 확인
- **Committed in:** 4bfb4f6

---

**Total deviations:** 1 auto-fixed (1 bug)
**Impact on plan:** 버튼 비활성화 로직 개선. 동작은 플랜과 동일.

## Issues Encountered

- 사전 존재 테스트 실패: `category_routing_test.rb`의 `test-blog-post` slug가 constraint `/(\d|post-).*/`에 불일치. 내 변경사항과 무관한 기존 이슈.

## User Setup Required

- `ANTHROPIC_API_KEY`가 `.env`에 설정되어 있어야 실제 AI API 호출 동작
- 미설정 시 화면에 에러 메시지 표시 (정상 동작)

## Next Phase Readiness

- AI 초안 작성 전체 기능 구현 완료 (백엔드 08-01 + 프론트엔드 08-02)
- Admin 폼에서 직접 UI 검증 필요 (checkpoint:human-verify 대기 중)
- ANTHROPIC_API_KEY 환경변수 설정 필요

---
*Phase: 08-ai-초안-작성*
*Completed: 2026-03-05*
