---
phase: 17-표-삽입
plan: 01
subsystem: ui
tags: [tiptap, table, rhino-editor, lit, admin-editor]

# Dependency graph
requires:
  - phase: 14-에디터-기반-설정
    provides: ActionText 허용목록에 table/th/td 태그 추가 완료
  - phase: 15-툴바-서식-확장
    provides: renderToolbarEnd() override 패턴 및 AdminRhinoEditor 기반 구조
  - phase: 16-텍스트-스타일링
    provides: TextStyle/Color/Highlight/FontSize extension 등록 완료 구조
provides:
  - Table/TableRow/TableCell/TableHeader 4종 TipTap extension 등록
  - 툴바 표 삽입 버튼 (3x3, 헤더 포함, 중첩 방지)
  - Light DOM 기반 컨텍스트 메뉴 (행/열 추가/삭제, 표 삭제 7가지 액션)
  - selectionUpdate 기반 메뉴 위치 계산 및 텍스트 선택 시 자동 숨김
affects: [18-블록-삽입-메뉴]

# Tech tracking
tech-stack:
  added:
    - "@tiptap/extension-table@^2.27.2 (이미 설치됨)"
    - "@tiptap/extension-table-row@^2.27.2 (이미 설치됨)"
    - "@tiptap/extension-table-cell@^2.27.2 (이미 설치됨)"
    - "@tiptap/extension-table-header@^2.27.2 (이미 설치됨)"
  patterns:
    - "startEditor() override 패턴: editor 생성 후 초기화 (connectedCallback이 아닌 startEditor)"
    - "Light DOM 컨텍스트 메뉴: shadow DOM 경계 외부에 position:absolute 메뉴 배치"
    - "selectionUpdate + isActive('table') + selection.empty 조합으로 표/텍스트 메뉴 충돌 방지"

key-files:
  created: []
  modified:
    - teovibe/app/frontend/editor/admin_rhino_editor.js

key-decisions:
  - "resizable: false 필수 — true는 drag handle 이벤트가 rhino-editor 포인터 이벤트와 충돌"
  - "startEditor() override 사용 — connectedCallback 시점에는 this.editor가 null이므로 editor 이벤트 리스너 등록 불가"
  - "Light DOM 컨텍스트 메뉴 — shadow DOM 내부에서는 position:absolute가 shadow root에 갇혀 뷰포트 기준 위치 계산 불가"
  - "텍스트 선택 시 컨텍스트 메뉴 숨김 — selection.empty=false 조건으로 기존 버블 메뉴에 양보"

patterns-established:
  - "startEditor() async override: editor 생성 후 부가 초기화 작업에 활용"
  - "Light DOM 메뉴: form 또는 document.body에 appendChild, disconnectedCallback에서 remove()"

requirements-completed: [TABL-01, TABL-02]

# Metrics
duration: 2min
completed: 2026-03-14
---

# Phase 17 Plan 01: 표 삽입 Summary

**TipTap Table 4종 extension + 툴바 삽입 버튼 + Light DOM 컨텍스트 메뉴로 Admin 에디터 표 편집 기능 완성**

## Performance

- **Duration:** 2 min
- **Started:** 2026-03-14T14:31:37Z
- **Completed:** 2026-03-14T14:33:25Z
- **Tasks:** 1/2 (Task 2는 브라우저 검증 체크포인트)
- **Files modified:** 1

## Accomplishments

- Table/TableRow/TableCell/TableHeader 4종 TipTap extension connectedCallback에 등록
- 툴바 끝에 표 삽입 버튼 추가 (3x3 헤더 포함, 표 안에서 비활성화로 중첩 방지)
- startEditor() override로 editor 생성 후 Light DOM 컨텍스트 메뉴 초기화
- selectionUpdate 리스너로 표 셀 커서 위치 시 메뉴 표시, 텍스트 선택 시 자동 숨김
- 행/열 추가/삭제 및 표 삭제 7개 액션 구현
- disconnectedCallback으로 메뉴 제거해 메모리 누수 방지
- Vite 빌드 성공, ActionText table 태그 허용 확인

## Task Commits

1. **Task 1: Table extension 4종 등록 + 툴바 삽입 버튼 + Light DOM 컨텍스트 메뉴** - `b10e4db` (feat)

## Files Created/Modified

- `teovibe/app/frontend/editor/admin_rhino_editor.js` - Table 4종 extension 등록, startEditor() override, 컨텍스트 메뉴 초기화/업데이트/클릭 처리, renderInsertTableButton(), renderToolbarEnd() 업데이트

## Decisions Made

- `resizable: false` 필수 — true는 drag handle 이벤트가 rhino-editor 포인터 이벤트와 충돌
- `startEditor()` override 사용 — connectedCallback 시점에는 this.editor가 null
- Light DOM 컨텍스트 메뉴 — shadow DOM 경계 외부에 배치해야 position:absolute가 뷰포트 기준으로 동작
- `selection.empty` 체크로 텍스트 선택 시 표 메뉴 숨김, 기존 버블 메뉴에 양보

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered

None.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- Task 2 브라우저 검증 완료 후 Phase 18 블록 삽입 메뉴 진행 가능
- ActionText 허용목록 table 태그 확인 완료 (Phase 14 설정 그대로 유효)

---
*Phase: 17-표-삽입*
*Completed: 2026-03-14*
