---
phase: 02-content-experience
plan: "01"
subsystem: ui
tags: [rhino-editor, trix, actiontext, vite, active-storage, rich-text]

# Dependency graph
requires:
  - phase: 01-foundation
    provides: "vite_ruby 설정, ActionText/Trix 포함된 Rails 앱 기반"
provides:
  - "rhino-editor 0.17.x npm 패키지 (Trix 대체 에디터)"
  - "posts/_form.html.erb에 rhino-editor 웹 컴포넌트 통합"
  - "admin/posts/_form.html.erb에 rhino-editor 웹 컴포넌트 통합"
  - "Active Storage 이미지 직접 업로드 활성화 (data-direct-upload-url)"
  - "기존 ActionText 데이터 호환성 (to_trix_html)"
affects: [02-content-experience]

# Tech tracking
tech-stack:
  added: ["rhino-editor@0.17.3 (TipTap 기반 리치 텍스트 에디터)"]
  patterns:
    - "hidden_field + rhino-editor 웹 컴포넌트 패턴으로 ActionText 폼 대체"
    - "to_trix_html 변환으로 기존 ActionText 데이터 마이그레이션 없이 호환"
    - "data-direct-upload-url 속성으로 Active Storage 직접 업로드 연결"

key-files:
  created: []
  modified:
    - "teovibe/app/frontend/entrypoints/application.js"
    - "teovibe/app/views/posts/_form.html.erb"
    - "teovibe/app/views/admin/posts/_form.html.erb"
    - "teovibe/package.json"
    - "teovibe/pnpm-lock.yaml"

key-decisions:
  - "rhino-editor 0.17.x 선택 (0.18.x는 rhinoImage/rhinoAttachment 제거로 이미지 업로드 불가)"
  - "trix + @rails/actiontext JS import 제거, rhino-editor만 import (이중 등록 방지)"
  - "trix, @rails/actiontext npm 패키지 자체는 유지 (CSS 의존성 안전하게 보존)"

patterns-established:
  - "rhino-editor 폼 패턴: f.hidden_field :body + <rhino-editor input= data-direct-upload-url= data-blob-url-template=>"
  - "기존 ActionText 콘텐츠 표시: f.object.body.try(:to_trix_html) || f.object.body"

requirements-completed: [EDIT-01, EDIT-02, EDIT-03]

# Metrics
duration: 2min
completed: 2026-02-22
---

# Phase 2 Plan 1: rhino-editor 도입 Summary

**rhino-editor 0.17.3(TipTap 기반)으로 Trix 에디터를 대체하여 이미지 드래그앤드롭 업로드 및 버블 메뉴가 내장된 리치 텍스트 편집 환경 구축**

## Performance

- **Duration:** 2 min
- **Started:** 2026-02-22T08:31:03Z
- **Completed:** 2026-02-22T08:33:21Z
- **Tasks:** 2
- **Files modified:** 5

## Accomplishments

- rhino-editor 0.17.3 npm 패키지 설치 및 application.js에서 trix import를 rhino-editor로 교체
- posts/_form.html.erb와 admin/posts/_form.html.erb에 rhino-editor 웹 컴포넌트 적용 (Trix rich_text_area 완전 대체)
- to_trix_html을 통한 기존 ActionText 콘텐츠 호환성 확보, data-direct-upload-url로 Active Storage 이미지 업로드 활성화

## Task Commits

각 태스크가 원자적으로 커밋되었습니다:

1. **Task 1: rhino-editor npm 패키지 설치 및 Vite 진입점 교체** - `038a115` (feat)
2. **Task 2: 게시글 폼에 rhino-editor 웹 컴포넌트 적용** - `0235260` (feat)

## Files Created/Modified

- `teovibe/app/frontend/entrypoints/application.js` - trix/actiontext import 제거, rhino-editor import 추가
- `teovibe/app/views/posts/_form.html.erb` - rich_text_area를 hidden field + rhino-editor 웹 컴포넌트로 교체
- `teovibe/app/views/admin/posts/_form.html.erb` - 동일하게 rhino-editor 웹 컴포넌트로 교체
- `teovibe/package.json` - rhino-editor@0.17.3 dependencies 추가
- `teovibe/pnpm-lock.yaml` - 패키지 락파일 업데이트

## Decisions Made

- **rhino-editor 0.17.x 버전 고정**: 0.18.x는 rhinoImage/rhinoAttachment 확장이 제거되어 이미지 드래그앤드롭 업로드 불가 -- 0.17.3 사용
- **trix/actiontext JS import만 제거**: npm 패키지 자체는 유지하여 CSS 의존성 안전하게 보존. trix + rhino-editor 동시 JS import는 ActionText JS 이중 등록 발생으로 금지
- **버블 메뉴/이미지 리사이즈**: rhino-editor 0.17.x에 기본 내장되어 별도 구현 불필요

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] pnpm PATH 설정 누락으로 Rails assets:precompile 실패**

- **Found during:** Task 1 (프로덕션 빌드 검증)
- **Issue:** `RAILS_ENV=production bundle exec rails assets:precompile` 실행 시 시스템 PATH에 pnpm이 없어 `No such file or directory - pnpm` 오류 발생
- **Fix:** 빌드 명령 실행 시 `export PATH="/Users/jaehohan/Library/pnpm:$PATH"` 선행하여 해결
- **Files modified:** 없음 (실행 환경 문제, 코드 변경 불필요)
- **Verification:** 프로덕션 빌드 195 modules transformed, 빌드 성공 확인
- **Committed in:** 038a115 (Task 1 커밋에 포함)

---

**Total deviations:** 1 auto-fixed (1 blocking)
**Impact on plan:** 실행 환경 PATH 설정 문제로 코드 변경 없이 해결. 플랜 범위에 영향 없음.

## Issues Encountered

- pnpm 바이너리가 시스템 PATH(/usr/local/bin 등)에 없고 `/Users/jaehohan/Library/pnpm/pnpm`에 위치 -- Rails 실행 환경에서 PATH를 명시적으로 설정해야 함

## User Setup Required

None - 외부 서비스 설정 불필요.

## Next Phase Readiness

- rhino-editor가 적용된 게시글 작성/수정 폼 준비 완료
- 이미지 드래그앤드롭 업로드 (Active Storage 직접 업로드) 활성화
- 버블 메뉴 (볼드/이탤릭/링크) 기본 내장 활성화
- 기존 Trix로 작성된 게시글 편집 시 to_trix_html로 정상 표시

---
*Phase: 02-content-experience*
*Completed: 2026-02-22*

## Self-Check: PASSED

- FOUND: teovibe/app/frontend/entrypoints/application.js
- FOUND: teovibe/app/views/posts/_form.html.erb
- FOUND: teovibe/app/views/admin/posts/_form.html.erb
- FOUND: .planning/phases/02-content-experience/02-01-SUMMARY.md
- FOUND commit: 038a115 (Task 1)
- FOUND commit: 0235260 (Task 2)
