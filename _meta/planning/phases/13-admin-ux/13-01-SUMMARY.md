---
phase: 13-admin-ux
plan: 01
subsystem: ui
tags: [rails, erb, tailwind, admin, layout, sticky, responsive]

requires:
  - phase: 11-소셜-색인-메타태그
    provides: Admin 레이아웃 구조 확인 (display_meta_tags 미사용 패턴)

provides:
  - Admin 게시글 new/edit 페이지 2단 flex 레이아웃
  - sticky 메타 패널(md:sticky md:top-8)
  - 모바일 1단 fallback(flex-col → md:flex-row)
  - 통합 테스트(ADMN-01/02/03 CSS 클래스 검증)

affects: []

tech-stack:
  added: []
  patterns:
    - "Admin 에디터 폼: 좌측 에디터 컬럼(flex-1 min-w-0) + 우측 sticky 메타 패널(md:w-80)"
    - "sticky 부모 컨테이너에 overflow 속성 미적용 규칙(sticky 동작 보장)"
    - "메타 패널 max-h+overflow-y-auto로 뷰포트 넘침 방어"

key-files:
  created:
    - teovibe/test/integration/admin_editor_layout_test.rb
  modified:
    - teovibe/app/views/admin/posts/_form.html.erb
    - teovibe/app/views/admin/posts/new.html.erb
    - teovibe/app/views/admin/posts/edit.html.erb

key-decisions:
  - "new/edit 래퍼 카드(bg-white rounded-card shadow-sm p-6) 제거 — 2단 레이아웃에서 전체를 감싸는 카드는 부적절하며 메타 패널 내부에 별도 카드 적용"
  - "에디터 컬럼에 min-w-0 필수 — rhino-editor 오버플로우 방지"
  - "sticky 부모(flex 컨테이너)에 overflow 속성 추가 금지 — overflow가 있으면 sticky가 해당 컨테이너 범위로 제한됨"

patterns-established:
  - "2단 에디터 레이아웃: flex flex-col md:flex-row gap-6 items-start"
  - "에디터 컬럼: flex-1 min-w-0 space-y-4"
  - "sticky 메타 패널: w-full md:w-80 md:sticky md:top-8 md:self-start"

requirements-completed: [ADMN-01, ADMN-02, ADMN-03]

duration: ~8min
completed: 2026-03-14
---

# Phase 13 Plan 01: Admin 에디터 2단 레이아웃 Summary

**Tailwind flex 2단 레이아웃으로 Admin 게시글 에디터 재구성 — 좌측 에디터 + 우측 sticky 메타 패널, 모바일 1단 fallback**

## Performance

- **Duration:** ~8 min
- **Started:** 2026-03-14T05:29:00Z
- **Completed:** 2026-03-14T05:37:43Z
- **Tasks:** 2/2
- **Files modified:** 4

## Accomplishments

- `_form.html.erb`를 `flex flex-col md:flex-row` 2단 컨테이너로 재구성
- 좌측 에디터 컬럼(AI 초안 패널 + rhino-editor `min-h-[400px]`)과 우측 sticky 메타 패널 분리 배치
- `new.html.erb`, `edit.html.erb` 래퍼 `max-w-2xl` → `max-w-5xl` 확장 및 외부 카드 래퍼 제거
- 통합 테스트 6개 작성(ADMN-01/02/03 CSS 클래스 검증) — 전체 통과

## Task Commits

1. **Task 1: 통합 테스트 작성 + 2단 레이아웃 구현** - `c70bc70` (feat)
2. **Task 2: 시각 검증 — 2단 레이아웃 + sticky + 모바일 fallback** - 사용자 승인 (checkpoint:human-verify)

**Plan metadata:** 324d3a2 (docs(13-01): Admin 에디터 2단 레이아웃 플랜 완료)

## Files Created/Modified

- `teovibe/test/integration/admin_editor_layout_test.rb` - 레이아웃 CSS 클래스 검증 통합 테스트(6개)
- `teovibe/app/views/admin/posts/_form.html.erb` - 2단 flex 레이아웃으로 전면 재구성
- `teovibe/app/views/admin/posts/new.html.erb` - max-w-5xl 래퍼, 외부 카드 제거
- `teovibe/app/views/admin/posts/edit.html.erb` - max-w-5xl 래퍼, 외부 카드 제거

## Decisions Made

- `new/edit` 래퍼의 `bg-white rounded-card shadow-sm p-6` 카드를 제거하고 메타 패널 내부에 별도 카드를 적용했다. 2단 레이아웃에서 전체를 감싸는 카드는 시각적으로 부적절하다.
- sticky 부모 컨테이너에는 overflow 속성을 추가하지 않았다. overflow가 있으면 sticky 동작이 해당 컨테이너 범위로 제한된다.
- 에디터 컬럼에 `min-w-0`을 필수로 포함했다. rhino-editor가 flex 컨테이너에서 오버플로우하는 것을 방지한다.

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered

- `AiDraftServiceTest` 2개 테스트(`claude-opus-4-5-20250929` 모델명 불일치)가 사전 존재하는 실패였다. 해당 테스트는 본 플랜 작업 이전부터 실패 상태였으며 현재 작업과 무관하다. 로그를 `deferred-items.md`로 이관 필요.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- Admin 에디터 2단 레이아웃 완료, v1.2 SEO + Admin UX 마일스톤 Phase 13 완료
- 사용자 시각 검증(데스크탑 2단 배치, sticky 동작, 모바일 1단 전환, 폼 제출) 통과
- 기존 AiDraftServiceTest 모델명 불일치 실패는 본 플랜 이전부터 존재하는 tech debt (범위 외)

---
*Phase: 13-admin-ux*
*Completed: 2026-03-14*
