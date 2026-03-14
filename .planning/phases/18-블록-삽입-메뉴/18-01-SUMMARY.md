---
phase: 18-블록-삽입-메뉴
plan: 01
subsystem: ui
tags: [tiptap, floating-menu, light-dom, rhino-editor, block-insert]

# Dependency graph
requires:
  - phase: 17-표-삽입
    provides: Light DOM 컨텍스트 메뉴 패턴, startEditor() override, _initTableContextMenu 구조
provides:
  - 빈 단락 플로팅 메뉴 (+버튼): _isEmptyParagraph, _initFloatingMenu, _updateFloatingMenu, _handleFloatingMenuClick
  - 구분선/인용구/코드블록/표 빠른 삽입 UX (Notion 스타일)
affects: []

# Tech tracking
tech-stack:
  added: []
  patterns:
    - Light DOM 플로팅 메뉴 패턴 (Phase 17 _initTableContextMenu와 동일 구조)
    - TipTap FloatingMenu shouldShow 알고리즘 네이티브 구현 (외부 패키지 없이)

key-files:
  created: []
  modified:
    - teovibe/app/frontend/editor/admin_rhino_editor.js

key-decisions:
  - "@tiptap/extension-floating-menu 설치 금지 — tippy.js 의존성 + Shadow DOM 충돌. 네이티브 JS로 직접 구현"
  - "depth===1 조건으로 표 셀 내부(depth>1) 플로팅 메뉴 미표시 보장"
  - "selectionUpdate + update 두 이벤트 모두 구독 — 텍스트 입력 시 즉시 감지"

patterns-established:
  - "빈 단락 감지: view.hasFocus() + isEditable + selection.empty + depth===1 + isTextblock + !code + childCount===0 + !textContent (8개 AND)"
  - "Light DOM 플로팅 UI: closest(form)||document.body에 append, position:absolute 좌표 = editorRect.left - 24 - 8"

requirements-completed:
  - BLCK-01

# Metrics
duration: 10min
completed: 2026-03-15
---

# Phase 18 Plan 01: 블록 삽입 메뉴 Summary

**빈 단락에 커서 진입 시 + 버튼이 나타나 구분선/인용구/코드블록/표를 즉시 삽입하는 Notion 스타일 플로팅 메뉴 — TipTap FloatingMenu 패키지 없이 Light DOM으로 직접 구현**

## Performance

- **Duration:** 10 min
- **Started:** 2026-03-15T00:10:00Z
- **Completed:** 2026-03-15T00:20:00Z
- **Tasks:** 1/2 (Task 2는 브라우저 검증 체크포인트)
- **Files modified:** 1

## Accomplishments

- _isEmptyParagraph(): TipTap FloatingMenu shouldShow 알고리즘 기반 8개 조건 AND 빈 단락 감지 (표 셀 내부 자동 제외)
- _initFloatingMenu(): Light DOM + 버튼(24x24 원형) + 서브 패널(구분선/인용구/코드블록/표 4항목)
- _updateFloatingMenu(): coordsAtPos + editorRect 기반 에디터 왼쪽 여백에 정확한 위치 계산
- _handleFloatingMenuClick(): data-action 기반 TipTap chain 커맨드 실행
- startEditor()/disconnectedCallback() 업데이트로 생명주기 통합

## Task Commits

1. **Task 1: 플로팅 메뉴 4개 메서드 구현 + startEditor/disconnectedCallback 통합** - `656ee5c` (feat)

## Files Created/Modified

- `teovibe/app/frontend/editor/admin_rhino_editor.js` - _isEmptyParagraph, _initFloatingMenu, _updateFloatingMenu, _handleFloatingMenuClick 4개 메서드 추가 + startEditor/disconnectedCallback 업데이트 + Phase 18 주석

## Decisions Made

- @tiptap/extension-floating-menu 설치하지 않음: tippy.js 의존성이 Shadow DOM 환경에서 충돌 발생. Phase 17 Light DOM 패턴 그대로 재사용하여 네이티브 JS로 동일 기능 구현
- depth===1 조건 적용: TipTap 공식 FloatingMenu shouldShow 로직과 동일. 표 셀(depth>1), 리스트 항목(depth>1) 내부에서 + 버튼 미표시
- selectionUpdate와 update 이벤트 모두 구독: selectionUpdate만으로는 텍스트 입력 후 즉시 숨김 처리가 지연됨

## Deviations from Plan

None - 플랜에 명시된 대로 정확히 구현.

## Issues Encountered

- `bin/vite build`가 "watched files have not changed" 캐시로 스킵됨. `npx vite build`로 직접 실행하여 빌드 성공 확인 (built in 5.78s)

## User Setup Required

None - 외부 서비스 설정 불필요.

## Next Phase Readiness

- BLCK-01 구현 완료, 브라우저 검증(Task 2) 대기 중
- Vite 빌드 통과, Rails 서버 기동 후 Admin 게시글 편집 폼에서 직접 확인 필요

---
*Phase: 18-블록-삽입-메뉴*
*Completed: 2026-03-15*
