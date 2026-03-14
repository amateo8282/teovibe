---
phase: 15-툴바-서식-확장
plan: "01"
subsystem: ui
tags: [rhino-editor, tiptap, lit, underline, toolbar, actiontext, rails]

requires:
  - phase: 14-에디터-기반-설정
    provides: AdminRhinoEditor 스캐폴드 + ActionText allowed_tags/allowed_attributes 초기화

provides:
  - AdminRhinoEditor에 Underline extension(toggleUnderline 커맨드) 등록
  - renderToolbarEnd() 오버라이드로 제목 드롭다운(H1/H2/H3), 구분선(--), 밑줄(U) 버튼 추가
  - ActionText allowed_tags에 u 태그 추가 (저장 후 렌더링 보존)

affects:
  - 16-텍스트-스타일링
  - 17-표-삽입
  - 18-블록-삽입-메뉴

tech-stack:
  added:
    - "@tiptap/extension-underline@2.27.2 (TipTap v2 호환 버전 고정)"
    - "lit@3.3.2 (Vite 빌드를 위한 직접 의존성 추가 — rhino-editor 내부 transitive dep)"
  patterns:
    - "renderToolbarEnd() override 패턴 — 기존 toolbar 구조 유지하며 새 버튼 추가"
    - "connectedCallback에서 addExtensions() 호출로 extension 등록"
    - "this.editor?.isActive() + this.editor?.chain().focus() 패턴으로 TipTap 커맨드 실행"

key-files:
  created: []
  modified:
    - "teovibe/app/frontend/editor/admin_rhino_editor.js — Underline extension + renderToolbarEnd() 구현"
    - "teovibe/config/initializers/action_text.rb — allowed_tags에 u 태그 추가"
    - "teovibe/package.json — @tiptap/extension-underline, lit 의존성 추가"
    - "teovibe/pnpm-lock.yaml — lockfile 업데이트"

key-decisions:
  - "lit을 직접 의존성으로 설치 — rhino-editor의 transitive dep이지만 Vite/Rollup이 심볼릭 링크로는 해석 불가, pnpm 직접 설치로 해결"
  - "renderToolbarEnd() override 선택 — renderToolbar() 전체 재작성 대신 끝에만 추가하여 기존 Bold/Italic/Strike/Blockquote/CodeBlock 버튼 보존"
  - "Heading 드롭다운을 renderToolbarEnd에 추가 — 기존 renderHeadingButton() 단일 토글은 그대로 유지(H1 빠른 접근), 드롭다운으로 H1/H2/H3 세분화 지원"

patterns-established:
  - "Pattern: AdminRhinoEditor에서 TipTap extension 추가 시 connectedCallback에서 this.addExtensions(Extension) 사용"
  - "Pattern: 새 toolbar 버튼은 renderToolbarEnd() override로 추가 (renderToolbar() 재작성 금지)"
  - "Pattern: Lit html 태그 템플릿 + this.editor?.chain().focus()...run() 패턴으로 TipTap 커맨드 실행"

requirements-completed: [MARK-01, MARK-02, MARK-03, MARK-04, MARK-05, MARK-06]

duration: ~10min
completed: "2026-03-14"
---

# Phase 15 Plan 01: 툴바 서식 확장 Summary

**@tiptap/extension-underline 설치 + renderToolbarEnd() 오버라이드로 밑줄/구분선/제목 드롭다운 버튼 추가, ActionText u 태그 허용**

## Performance

- **Duration:** ~10 min
- **Started:** 2026-03-14
- **Completed:** 2026-03-14
- **Tasks:** 2/2 (완료)
- **Files modified:** 4

## Accomplishments

- @tiptap/extension-underline@2.27.2 설치 (rhino-editor의 TipTap v2와 버전 정합)
- lit@3.3.2 직접 설치로 Vite 빌드 성공 (pnpm transitive dep 해석 문제 해결)
- AdminRhinoEditor에 renderToolbarEnd() 오버라이드: 제목 드롭다운(H1/H2/H3), 구분선(--), 밑줄(U) 버튼 구현
- ActionText allowed_tags에 u 태그 추가로 밑줄이 저장/렌더링 후에도 유지됨
- 기존 Bold/Italic/Strike/Blockquote/CodeBlock 등 기본 toolbar 버튼 보존

## Task Commits

1. **Task 1: Underline extension 설치 + renderToolbarEnd 오버라이드 + ActionText 허용목록** - `afcc76e` (feat)
2. **Task 2: 툴바 서식 버튼 전체 동작 확인** - checkpoint:human-verify (사용자 승인 완료)

## Files Created/Modified

- `teovibe/app/frontend/editor/admin_rhino_editor.js` — Underline extension + renderHeadingDropdown/renderHorizontalRuleButton/renderUnderlineButton/renderToolbarEnd 구현
- `teovibe/config/initializers/action_text.rb` — allowed_tags에 u 태그 추가
- `teovibe/package.json` — @tiptap/extension-underline@^2.27.2, lit@^3.3.2 의존성 추가
- `teovibe/pnpm-lock.yaml` — lockfile 업데이트

## Decisions Made

- lit을 직접 의존성으로 설치: rhino-editor가 내부적으로 lit을 사용하지만 pnpm virtual store의 transitive dep은 Vite/Rollup이 해석하지 못함. pnpm add lit으로 직접 추가하여 해결.
- renderToolbarEnd() 선택: renderToolbar() 전체를 override하면 기존 모든 버튼 코드를 복사해야 하는 유지보수 비용 발생. renderToolbarEnd()만 override하면 기존 toolbar가 그대로 유지되고 끝에 새 버튼 3개만 추가됨.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] lit 패키지 직접 설치로 Vite 빌드 오류 해결**
- **Found during:** Task 1 (Vite build 검증 단계)
- **Issue:** `import { html } from "lit"` 사용 시 Rollup이 "Failed to resolve import 'lit'" 오류. rhino-editor의 transitive dep이지만 pnpm symlink 체계상 직접 접근 불가.
- **Fix:** `pnpm add lit@^3.3.2` 실행으로 직접 의존성 추가
- **Files modified:** teovibe/package.json, teovibe/pnpm-lock.yaml
- **Verification:** bin/vite build 성공 (5.15s, 에러 없음)
- **Committed in:** afcc76e (Task 1 커밋에 포함)

---

**Total deviations:** 1 auto-fixed (1 blocking)
**Impact on plan:** lit 직접 설치는 pnpm의 strict hoisting 특성상 예상 가능한 이슈. 플랜 구현 범위에 영향 없음.

## Issues Encountered

- Vite 빌드 실패: `import { html } from "lit"` 해석 불가. pnpm의 strict 패키지 해석 정책으로 transitive dep은 직접 import 불가. lit 직접 설치로 해결.

## User Setup Required

없음 — 외부 서비스 설정 불필요.

## Next Phase Readiness

- Phase 15 완료 — 사용자 브라우저 검증 통과 (MARK-01~06 전체 동작 확인)
- Phase 16 (텍스트 스타일링 — 정렬/색상/하이라이트/폰트 크기) 진행 가능
- MARK-01(Strike), MARK-03(Blockquote), MARK-05(CodeBlock)은 rhino-editor 기본 구현이 이미 toolbar에 포함 — 별도 코드 추가 없음

## Self-Check

- [x] teovibe/app/frontend/editor/admin_rhino_editor.js 수정됨
- [x] teovibe/config/initializers/action_text.rb 수정됨
- [x] @tiptap/extension-underline@2.27.2 package.json에 추가됨
- [x] lit@3.3.2 package.json에 추가됨
- [x] ActionText allowed_tags에 'u' 포함 확인 (rails runner 확인: true)
- [x] renderToolbarEnd 메서드 존재 확인
- [x] Vite 빌드 성공 (bin/vite build)
- [x] 커밋 afcc76e 생성됨

## Self-Check: PASSED

---
*Phase: 15-툴바-서식-확장*
*Completed: 2026-03-14*
