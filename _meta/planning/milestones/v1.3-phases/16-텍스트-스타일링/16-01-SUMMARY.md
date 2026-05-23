---
phase: 16-텍스트-스타일링
plan: 01
subsystem: ui
tags: [tiptap, rhino-editor, lit, text-align, color, highlight, font-size]

# Dependency graph
requires:
  - phase: 14-에디터-기반-설정
    provides: ActionText 허용목록(style/span/mark), AdminRhinoEditor 서브클래스 패턴
  - phase: 15-툴바-서식-확장
    provides: renderToolbarEnd() override 패턴, lit 직접 설치 패턴

provides:
  - TextAlign extension (좌/중/우 정렬, setTextAlign 커맨드)
  - Color extension + TextStyle (setColor/unsetColor, span style="color:")
  - Highlight extension multicolor (setHighlight/unsetHighlight, mark style="background-color:")
  - FontSize 커스텀 extension (setFontSize/unsetFontSize, span style="font-size:")
  - Admin 에디터 툴바: 정렬 3버튼 + 색상 picker + 하이라이트 picker + 폰트크기 드롭다운

affects: [17-표-삽입, 18-블록-삽입-메뉴]

# Tech tracking
tech-stack:
  added:
    - "@tiptap/extension-text-align@2.27.2"
    - "@tiptap/extension-color@2.27.2"
    - "@tiptap/extension-highlight@2.27.2"
    - "@tiptap/extension-text-style@2.27.2"
    - "@tiptap/core@2.27.2 (직접 설치 — Vite transitive dep 해석 오류 방지)"
  patterns:
    - "커스텀 Extension.create() 패턴: @tiptap/extension-font-size v2 미존재 시 로컬 구현"
    - "숨겨진 input type=color + label 패턴: 툴바에 native color picker 통합"
    - "pnpm transitive dep 직접 설치 패턴: Vite가 resolve 못하는 dep은 pnpm add로 직접 추가"

key-files:
  created:
    - "teovibe/app/frontend/editor/font_size_extension.js"
  modified:
    - "teovibe/app/frontend/editor/admin_rhino_editor.js"
    - "teovibe/package.json"
    - "teovibe/pnpm-lock.yaml"

key-decisions:
  - "@tiptap/core 직접 설치 필요 — font_size_extension.js가 import { Extension } from @tiptap/core 하는데 Vite가 transitive dep을 resolve하지 못함 (Phase 15 lit 동일 패턴)"
  - "커스텀 FontSize extension: @tiptap/extension-font-size v3.x 전용 확인, Extension.create() 30줄로 동일 기능 구현"

patterns-established:
  - "Pattern 1: pnpm transitive dep 직접 설치 — Vite 빌드 실패 시 직접 의존성 추가"
  - "Pattern 2: 로컬 커스텀 extension — npm 패키지 버전 미존재 시 Extension.create() 직접 구현"

requirements-completed: [STYL-01, STYL-02, STYL-03, STYL-04]

# Metrics
duration: 12min
completed: 2026-03-14
---

# Phase 16 Plan 01: 텍스트 스타일링 Summary

**TipTap TextAlign/Color/Highlight + 커스텀 FontSize extension 4종 + 툴바 UI(정렬 3버튼/색상 picker/하이라이트 picker/폰트크기 드롭다운) Admin 에디터에 추가**

## Performance

- **Duration:** 12 min
- **Started:** 2026-03-14T12:44:07Z
- **Completed:** 2026-03-14T12:56:00Z
- **Tasks:** 3/3 (Task 3: 브라우저 수동 검증 — checkpoint 승인 완료)
- **Files modified:** 4

## Accomplishments

- @tiptap/extension-text-align, color, highlight, text-style, core 5개 패키지 설치
- font_size_extension.js 신규 생성 — Extension.create() 기반 커스텀 FontSize (setFontSize/unsetFontSize 커맨드)
- admin_rhino_editor.js에 5개 extension 등록 + renderToolbarEnd() 확장 (총 7개 툴바 아이템)
- ActionText 허용목록 smoke test 통과 (style/span/mark 모두 true)

## Task Commits

각 태스크별 원자적 커밋:

1. **Task 1: 패키지 설치 + FontSize extension 생성 + extension 등록** - `c43d4cf` (feat)
2. **Task 2: 정렬/색상/하이라이트/폰트크기 툴바 UI 구현** - `eb3ee77` (feat)

## Files Created/Modified

- `teovibe/app/frontend/editor/font_size_extension.js` - STYL-04 커스텀 FontSize Extension.create() (setFontSize/unsetFontSize)
- `teovibe/app/frontend/editor/admin_rhino_editor.js` - TextAlign/TextStyle/Color/FontSize/Highlight 등록 + renderAlignButtons/renderColorPicker/renderHighlightPicker/renderFontSizeDropdown + renderToolbarEnd() 확장
- `teovibe/package.json` - 5개 패키지 추가 (@tiptap/extension-text-align, color, highlight, text-style, core)
- `teovibe/pnpm-lock.yaml` - lockfile 업데이트

## Decisions Made

- @tiptap/core 직접 설치 추가: font_size_extension.js에서 `import { Extension } from "@tiptap/core"` 시 Vite가 transitive dep을 resolve 못함 — Phase 15의 lit 직접 설치와 동일한 패턴으로 해결
- 커스텀 FontSize extension: @tiptap/extension-font-size가 v3.x 전용임을 확인, 30줄 Extension.create()로 동일 기능 구현

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] @tiptap/core 직접 설치**

- **Found during:** Task 1 (패키지 설치 + extension 등록) 검증
- **Issue:** `bin/vite build` 실패 — "Rollup failed to resolve import @tiptap/core from font_size_extension.js". @tiptap/core가 rhino-editor의 transitive dep으로만 있어 Vite가 직접 import를 resolve하지 못함
- **Fix:** `pnpm add @tiptap/core@^2.27.2` 직접 설치
- **Files modified:** teovibe/package.json, teovibe/pnpm-lock.yaml
- **Verification:** bin/vite build 성공
- **Committed in:** c43d4cf (Task 1 커밋에 포함)

---

**Total deviations:** 1 auto-fixed (Rule 3 Blocking)
**Impact on plan:** 필수 수정. 빌드 차단 문제. Phase 15 lit 패턴과 동일한 pnpm transitive dep 이슈.

## Issues Encountered

- @tiptap/core transitive dep Vite 해석 오류 — 위 Deviation 항목으로 해결

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- STYL-01~04 전체 완료 — 사용자 브라우저 검증 승인 완료
- Phase 17 표 삽입 진행 가능 — ActionText allowed_tags에 table/tr/td/th 이미 허용됨 (Phase 14)
- Phase 17 주의: 표 버블 메뉴가 기존 텍스트 선택 버블 메뉴와 충돌 가능 (shouldShow 가드 필수)

---
*Phase: 16-텍스트-스타일링*
*Completed: 2026-03-14*

## Self-Check: PASSED

- `teovibe/app/frontend/editor/font_size_extension.js`: FOUND
- `teovibe/app/frontend/editor/admin_rhino_editor.js`: FOUND (modified)
- Commit c43d4cf: FOUND
- Commit eb3ee77: FOUND
