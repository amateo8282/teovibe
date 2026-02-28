---
phase: 06-category-management
plan: 02
subsystem: ui
tags: [rails, admin, turbo-stream, stimulus, sortablejs, drag-and-drop, turbo-frame]

requires:
  - phase: 06-01
    provides: "Category 모델 (record_type enum, scopes, 삭제 보호, move_up/move_down)"

provides:
  - Admin::CategoriesController (CRUD + reorder + toggle 액션 11개)
  - admin/categories 뷰 템플릿 (index, new, edit, _form, _category_row, 2x turbo_stream)
  - sortable_controller.js Stimulus 컨트롤러 (Sortable.js 기반 DnD)
  - Admin 사이드바 카테고리 관리 링크

affects:
  - 06-03 (PostsController 통합 및 라우팅 — 카테고리 Admin UI 완성됨)
  - 06-04 (Navbar 동적 카테고리 — visible_in_nav 토글 준비됨)

tech-stack:
  added:
    - sortablejs@1.15.7
  patterns:
    - "Turbo Frame + Turbo Stream 조합으로 인라인 토글 업데이트 (turbo_frame_tag + turbo_stream.replace)"
    - "Sortable.js Stimulus 컨트롤러: onEnd 콜백으로 positions[] PATCH 전송"
    - "Admin 카테고리 CRUD: LandingSectionsController 패턴 확장 (reorder + toggle 추가)"

key-files:
  created:
    - teovibe/app/controllers/admin/categories_controller.rb
    - teovibe/app/views/admin/categories/index.html.erb
    - teovibe/app/views/admin/categories/_category_row.html.erb
    - teovibe/app/views/admin/categories/_form.html.erb
    - teovibe/app/views/admin/categories/new.html.erb
    - teovibe/app/views/admin/categories/edit.html.erb
    - teovibe/app/views/admin/categories/toggle_admin_only.turbo_stream.erb
    - teovibe/app/views/admin/categories/toggle_visible_in_nav.turbo_stream.erb
    - teovibe/app/javascript/controllers/sortable_controller.js
  modified:
    - teovibe/config/routes.rb
    - teovibe/app/views/layouts/admin.html.erb

key-decisions:
  - "turbo_frame_tag 내부에 toggle button_to 배치 — turbo_stream.replace로 프레임 단위 교체 (전체 행 리렌더 없음)"
  - "Sortable.js handle 방식 채택 (data-sortable-handle 아이콘) — 행 전체 드래그 방지"
  - "두 섹션(게시판/스킬팩) 각각 별도 tbody에 sortable 컨트롤러 연결 — 타입 간 순서 혼합 방지"

patterns-established:
  - "sortable_controller.js: eagerLoadControllersFrom으로 자동 등록 (index.js 수정 불필요)"
  - "Admin toggle 패턴: PATCH → turbo_stream.replace → turbo_frame 내 버튼 교체"
  - "관리자 사이드바 active 상태: request.path.start_with?('/admin/categories') 패턴"

requirements-completed: [CATM-01, CATM-02, CATM-03, CATM-04, CATM-06]

duration: 3min
completed: 2026-02-28
---

# Phase 6 Plan 2: Admin 카테고리 CRUD UI Summary

**Admin::CategoriesController + Sortable.js DnD + Turbo Stream 인라인 토글로 런타임 카테고리 완전 관리 UI 구현**

## Performance

- **Duration:** 3 min
- **Started:** 2026-02-28T14:11:59Z
- **Completed:** 2026-02-28T14:14:53Z
- **Tasks:** 2
- **Files modified:** 11

## Accomplishments

- Admin::CategoriesController 생성 (index, new, create, edit, update, destroy, reorder, move_up, move_down, toggle_admin_only, toggle_visible_in_nav 11개 액션)
- 게시판/스킬팩 카테고리 분리 테이블 뷰 (index.html.erb) + 개별 행 Turbo Frame (_category_row.html.erb)
- sortablejs@1.15.7 설치 + sortable_controller.js Stimulus 컨트롤러 (DnD → PATCH /admin/categories/reorder)
- admin_only / visible_in_nav 인라인 토글 (Turbo Stream으로 버튼 단위 교체)
- Admin 사이드바에 카테고리 관리 링크 추가

## Task Commits

1. **Task 1: Admin 카테고리 컨트롤러 + 라우트 + CRUD 뷰 생성** - `39c75d8` (feat)
2. **Task 2: Sortable.js 설치 + sortable_controller.js 구현** - `ca02866` (feat)

## Files Created/Modified

- `teovibe/app/controllers/admin/categories_controller.rb` - Admin 카테고리 CRUD + reorder + toggle 11개 액션
- `teovibe/config/routes.rb` - admin/categories 라우트 (member/collection 포함)
- `teovibe/app/views/admin/categories/index.html.erb` - 게시판/스킬팩 분리 테이블, Sortable 연결
- `teovibe/app/views/admin/categories/_category_row.html.erb` - Turbo Frame 행, 드래그 핸들, 인라인 토글
- `teovibe/app/views/admin/categories/_form.html.erb` - 이름/슬러그/설명/체크박스 폼
- `teovibe/app/views/admin/categories/new.html.erb` - 새 카테고리 폼
- `teovibe/app/views/admin/categories/edit.html.erb` - 카테고리 편집 폼
- `teovibe/app/views/admin/categories/toggle_admin_only.turbo_stream.erb` - 관리자전용 토글 스트림
- `teovibe/app/views/admin/categories/toggle_visible_in_nav.turbo_stream.erb` - Navbar노출 토글 스트림
- `teovibe/app/javascript/controllers/sortable_controller.js` - Sortable.js Stimulus 컨트롤러
- `teovibe/app/views/layouts/admin.html.erb` - 사이드바 카테고리 링크 추가

## Decisions Made

- turbo_frame_tag 내부에 toggle button_to 배치하고 turbo_stream.replace로 프레임 단위 교체 — 전체 행 리렌더 없이 버튼만 교체
- Sortable.js handle 방식 (data-sortable-handle 아이콘) 채택 — 행 전체 드래그 방지, 명시적 핸들 UX
- 게시판/스킬팩 두 섹션 각각 별도 tbody에 sortable 컨트롤러 연결 — 타입 간 순서 혼합 방지

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered

None.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- Admin 카테고리 CRUD UI 완성. 런타임에 카테고리 생성/수정/삭제/순서변경/토글 모두 가능
- 06-03 (PostsController 통합 및 라우팅) 즉시 시작 가능
- 06-04 (Navbar 동적 카테고리) — visible_in_nav 필드 토글 준비됨

---
*Phase: 06-category-management*
*Completed: 2026-02-28*
