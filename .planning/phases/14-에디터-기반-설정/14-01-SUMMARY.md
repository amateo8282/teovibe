---
phase: 14-에디터-기반-설정
plan: "01"
subsystem: infra
tags: [action-text, rhino-editor, tiptap, rails, stimulus]

requires: []
provides:
  - ActionText 렌더링 시 style 속성 및 table 태그 보존 허용목록 설정
  - AdminRhinoEditor 커스텀 엘리먼트 (TipTapEditor 서브클래스, Phase 15+ 확장 포인트)
  - admin-rhino-editor 태그로 Admin 게시글 폼 에디터 교체
  - AI 초안 컨트롤러가 admin-rhino-editor를 탐색하도록 수정
affects: [15-툴바-서식-확장, 16-텍스트-스타일링, 17-표-삽입, 18-블록-삽입-메뉴]

tech-stack:
  added: []
  patterns:
    - "AdminRhinoEditor extends TipTapEditor: Phase 15+ 에서 editorOptions() 오버라이드로 확장하는 패턴"
    - "ActionText 허용목록은 after_initialize 블록에서 sanitizer 기본값 초기화 후 += 방식으로 확장"

key-files:
  created:
    - teovibe/config/initializers/action_text.rb
    - teovibe/app/frontend/editor/admin_rhino_editor.js
  modified:
    - teovibe/app/frontend/entrypoints/application.js
    - teovibe/app/views/admin/posts/_form.html.erb
    - teovibe/app/frontend/controllers/ai_draft_controller.js

key-decisions:
  - "ActionText::ContentHelper.allowed_tags/allowed_attributes 는 nil 기본값이므로 += 전에 sanitizer 기본값으로 초기화 필요 (Rails 8.1 확인)"
  - "AdminRhinoEditor.define() 사용 — customElements.define() 대신 rhino-editor 내장 메서드 사용으로 에러 핸들링 위임"

patterns-established:
  - "ActionText 허용목록 확장: allowed_tags ||= (기본값 초기화) 후 += (추가) 패턴"
  - "커스텀 에디터 등록: class extends TipTapEditor + ClassName.define('tag-name') 패턴"

requirements-completed: [INFRA-01, INFRA-02, INFRA-03]

duration: 15min
completed: "2026-03-14"
---

# Phase 14 Plan 01: 에디터 기반 설정 Summary

**ActionText style/table 허용목록 확장 + AdminRhinoEditor(TipTapEditor 서브클래스) 스캐폴드로 v1.3 에디터 고도화 인프라 구축**

## Performance

- **Duration:** 15 min
- **Started:** 2026-03-14T11:49:48Z
- **Completed:** 2026-03-14T12:05:00Z
- **Tasks:** 1 (+ 1 checkpoint)
- **Files modified:** 5

## Accomplishments

- ActionText 렌더링 시 style 속성 및 table/tr/td 등 표 관련 태그가 무음 삭제되지 않도록 허용목록 확장
- TipTapEditor를 상속하는 AdminRhinoEditor 스캐폴드 생성 및 admin-rhino-editor 태그로 등록
- Admin 게시글 폼의 에디터 태그를 rhino-editor에서 admin-rhino-editor로 교체
- AI 초안 컨트롤러의 querySelector 선택자를 admin-rhino-editor로 업데이트

## Task Commits

각 태스크는 원자적으로 커밋됨:

1. **Task 1: ActionText 허용목록 확장 + AdminRhinoEditor 스캐폴드 + AI selector 수정** - `edcd224` (feat)

**Plan metadata:** (docs commit)

## Files Created/Modified

- `teovibe/config/initializers/action_text.rb` - ActionText style + table 태그 허용목록 초기화 및 확장
- `teovibe/app/frontend/editor/admin_rhino_editor.js` - TipTapEditor 서브클래스, admin-rhino-editor 태그 등록
- `teovibe/app/frontend/entrypoints/application.js` - admin_rhino_editor.js import 추가
- `teovibe/app/views/admin/posts/_form.html.erb` - rhino-editor → admin-rhino-editor 태그 교체
- `teovibe/app/frontend/controllers/ai_draft_controller.js` - querySelector 선택자 수정

## Decisions Made

- `ActionText::ContentHelper.allowed_tags`는 `mattr_accessor` 기본값이 nil이므로 `+=` 전에 sanitizer 기본값으로 `||=` 초기화 필요. 이 패턴을 initializer에 명시적으로 적용함.
- `AdminRhinoEditor.define('admin-rhino-editor')` 사용 — rhino-editor 내장 메서드로 customElements 등록 위임.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] ActionText::ContentHelper.allowed_attributes += nil 오류 수정**

- **Found during:** Task 1 (ActionText 허용목록 확장)
- **Issue:** 플랜의 initializer 코드가 `ActionText::ContentHelper.allowed_attributes += ["style"]`를 바로 호출하는데, Rails 8.1에서 `allowed_attributes`/`allowed_tags`의 `mattr_accessor` 기본값이 nil이어서 `NoMethodError: undefined method '+' for nil` 발생
- **Fix:** `allowed_tags ||= (sanitizer 기본값 초기화)` 후 `+=` 방식으로 변경하여 nil 참조 오류 해결
- **Files modified:** teovibe/config/initializers/action_text.rb
- **Verification:** `bin/rails runner "puts ActionText::ContentHelper.allowed_attributes.include?('style') && ..."` 결과 `true`
- **Committed in:** edcd224 (Task 1 커밋에 포함)

---

**Total deviations:** 1 auto-fixed (Rule 1 - Bug)
**Impact on plan:** Rails 8.1 API 실제 동작 확인 후 초기화 코드 수정. 기능 목표는 완전히 달성됨. 스코프 확장 없음.

## Issues Encountered

- Rails 8.1의 `ActionText::ContentHelper` mattr_accessor 기본값이 nil임을 런타임 확인. 플랜 코드 스니펫은 Rails 7.x 기준으로 작성되어 있었음.

## User Setup Required

없음 — 외부 서비스 설정 불필요.

## Next Phase Readiness

- Phase 15(툴바 서식 확장): AdminRhinoEditor 확장 포인트 준비 완료, editorOptions() 오버라이드로 TipTap extension 추가 가능
- Phase 16(텍스트 스타일링): style 속성 허용목록 준비 완료, 색상/정렬/폰트 크기 extension 추가 가능
- Phase 17(표 삽입): table/tr/td 허용목록 준비 완료, TipTap Table extension 추가 가능
- 주의: Phase 15 계획 시 rhinoStrike 커맨드명 확인 필요 (기존 STATE.md 블로커)

---
*Phase: 14-에디터-기반-설정*
*Completed: 2026-03-14*
