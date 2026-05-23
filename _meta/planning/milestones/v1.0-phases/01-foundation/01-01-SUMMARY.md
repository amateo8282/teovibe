---
phase: 01-foundation
plan: 01
subsystem: infra
tags: [vite_ruby, vite, react, tailwindcss, stimulus, turbo, importmap-migration, pnpm]

# Dependency graph
requires: []
provides:
  - "vite_rails gem 기반 JavaScript 빌드 파이프라인"
  - "app/frontend/entrypoints/application.js (Turbo, Stimulus, Trix/ActionText)"
  - "app/frontend/entrypoints/application.css (Tailwind CSS v4 @theme 블록)"
  - "app/frontend/controllers/ (Stimulus 컨트롤러 glob 등록)"
  - "vite.config.ts (React, Tailwind v4, Rails 플러그인)"
  - "config/vite.json (dev port 3036, autoBuild)"
  - "HMR 지원 개발 환경"
affects: [02-editor, 03-payments, 04-community, 05-polish, all-frontend-phases]

# Tech tracking
tech-stack:
  added:
    - "vite_rails 3.0.20 (vite_ruby 3.9.2)"
    - "vite 5.4.21"
    - "@vitejs/plugin-react 5.1.4"
    - "@tailwindcss/vite 4.2.0"
    - "tailwindcss 4.2.0"
    - "stimulus-vite-helpers 3.1.0"
    - "react 19.2.4"
    - "react-dom 19.2.4"
    - "@hotwired/turbo-rails 8.0.23"
    - "@hotwired/stimulus 3.2.2"
    - "trix 2.1.16"
    - "@rails/actiontext 8.1.200"
    - "vite-plugin-rails 0.5.0"
  patterns:
    - "app/frontend/entrypoints/ 디렉토리에 Vite 진입점 파일 배치"
    - "import.meta.glob으로 Stimulus 컨트롤러 자동 등록 (stimulus-vite-helpers)"
    - "vite_client_tag + vite_react_refresh_tag + vite_javascript_tag 레이아웃 패턴"
    - "CSS를 JS 진입점에서 import하는 Vite 패턴"

key-files:
  created:
    - "teovibe/vite.config.ts"
    - "teovibe/config/vite.json"
    - "teovibe/package.json"
    - "teovibe/pnpm-lock.yaml"
    - "teovibe/bin/vite"
    - "teovibe/app/frontend/entrypoints/application.js"
    - "teovibe/app/frontend/entrypoints/application.css"
    - "teovibe/app/frontend/controllers/index.js"
    - "teovibe/app/frontend/controllers/*_controller.js (9개)"
  modified:
    - "teovibe/Gemfile (importmap-rails, tailwindcss-rails, propshaft 제거, vite_rails 추가)"
    - "teovibe/Procfile.dev (tailwindcss:watch 제거, vite dev 추가)"
    - "teovibe/app/views/layouts/application.html.erb (vite 태그로 교체)"
    - "teovibe/app/views/layouts/admin.html.erb (vite 태그로 교체)"
  deleted:
    - "teovibe/config/importmap.rb"
    - "teovibe/config/initializers/assets.rb"

key-decisions:
  - "tailwindcss-rails gem 제거 + @tailwindcss/vite npm 패키지로 일원화 (별도 watch 프로세스 제거, Vite HMR 통합)"
  - "propshaft gem 제거 (tailwindcss-rails 의존성 없어지면서 불필요)"
  - "importmap-rails gem 제거 + config/importmap.rb 삭제 (vite_ruby로 완전 대체)"
  - "pnpm을 npm 패키지 매니저로 사용 (CLAUDE.md 프로젝트 규칙)"
  - "trix + @rails/actiontext npm 패키지 추가 (기존 Post.has_rich_text :body ActionText 사용 중)"
  - "tailwindcss npm 패키지 별도 설치 필요 (@tailwindcss/vite가 peer dependency로 요구)"
  - "app/javascript/controllers/ 기존 디렉토리 보존 (안전을 위해, 마이그레이션 후 삭제 가능)"

patterns-established:
  - "Pattern: Vite 진입점 파일은 app/frontend/entrypoints/에 배치"
  - "Pattern: Stimulus 컨트롤러는 app/frontend/controllers/에 배치, import.meta.glob으로 자동 등록"
  - "Pattern: CSS는 JS 진입점(application.js)에서 import './application.css'로 로드"
  - "Pattern: 레이아웃에서 vite_client_tag + vite_react_refresh_tag + vite_javascript_tag 순서"
  - "Pattern: React 전용 페이지는 별도 entrypoint (app/frontend/entrypoints/[page].jsx) + turbo:load 마운트"

requirements-completed: [INFRA-01]

# Metrics
duration: 5min
completed: 2026-02-22
---

# Phase 1 Plan 01: vite_ruby 빌드 파이프라인 전환 Summary

**importmap-rails/tailwindcss-rails/propshaft 스택을 vite_rails 3.0.20으로 완전 교체하여 React/JSX/npm 패키지 사용 가능한 HMR 지원 빌드 파이프라인 구축 완료**

## Performance

- **Duration:** 약 5분
- **Started:** 2026-02-22T07:53:38Z
- **Completed:** 2026-02-22T08:03:00Z
- **Tasks:** 2
- **Files modified:** 14개 (수정 10, 생성 12, 삭제 2)

## Accomplishments
- importmap-rails, tailwindcss-rails, propshaft gem을 제거하고 vite_rails gem으로 완전 대체
- app/frontend/entrypoints/ 구조로 JS/CSS 진입점 생성 (Turbo, Stimulus, Trix/ActionText, Tailwind v4)
- 9개 Stimulus 컨트롤러를 app/frontend/controllers/로 이전하고 import.meta.glob 기반 자동 등록
- application.html.erb + admin.html.erb 레이아웃을 vite 태그 헬퍼로 교체
- RAILS_ENV=production bundle exec rails assets:precompile 성공 확인

## Task Commits

각 태스크가 원자적으로 커밋됨:

1. **Task 1: Gem/npm 의존성 교체 및 Vite 설정 파일 생성** - `afdc9ce` (feat)
2. **Task 2: 코드 마이그레이션 및 기존 기능 검증** - `4bb6aab` (feat)

## Files Created/Modified

- `teovibe/vite.config.ts` - Vite 빌드 설정 (React, Tailwind v4, Rails 플러그인, fullReload 설정)
- `teovibe/config/vite.json` - vite_ruby 환경별 설정 (dev port 3036, autoBuild)
- `teovibe/package.json` - npm 의존성 목록 (pnpm 사용)
- `teovibe/pnpm-lock.yaml` - pnpm lockfile
- `teovibe/bin/vite` - Vite binstub
- `teovibe/app/frontend/entrypoints/application.js` - Turbo/Stimulus/Trix/ActionText 통합 진입점
- `teovibe/app/frontend/entrypoints/application.css` - Tailwind CSS v4 (@theme 블록 포함)
- `teovibe/app/frontend/controllers/index.js` - stimulus-vite-helpers 기반 컨트롤러 등록
- `teovibe/app/frontend/controllers/*_controller.js` - 9개 컨트롤러 이전
- `teovibe/Gemfile` - vite_rails 추가, importmap/tailwindcss/propshaft 제거
- `teovibe/Procfile.dev` - tailwindcss:watch 제거, vite dev 추가
- `teovibe/app/views/layouts/application.html.erb` - vite 태그 교체
- `teovibe/app/views/layouts/admin.html.erb` - vite 태그 교체

## Decisions Made
- tailwindcss-rails gem 제거, @tailwindcss/vite npm 패키지로 일원화: 별도 watch 프로세스 불필요, Vite HMR에 통합됨
- propshaft gem 제거: tailwindcss-rails 의존성이 없어지면서 불필요해짐
- trix + @rails/actiontext npm 패키지 추가: 기존 Post 모델에서 has_rich_text :body 사용 중이므로 필수
- tailwindcss npm 패키지 별도 설치: @tailwindcss/vite가 peer dependency로 요구함

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 2 - Missing Critical] trix + @rails/actiontext npm 패키지 추가**
- **Found during:** Task 2 (JS 진입점 생성)
- **Issue:** 기존 app/javascript/application.js에 trix + @rails/actiontext import가 있었고, Post 모델이 has_rich_text :body를 사용 중. 이 import 없이는 ActionText 기능이 동작하지 않음
- **Fix:** pnpm add trix @rails/actiontext 실행, app/frontend/entrypoints/application.js에 import 추가
- **Files modified:** package.json, pnpm-lock.yaml, app/frontend/entrypoints/application.js
- **Verification:** bundle exec rails runner 성공, assets:precompile 성공
- **Committed in:** 4bb6aab (Task 2 commit)

**2. [Rule 3 - Blocking] tailwindcss npm 패키지 추가**
- **Found during:** Task 2 (assets:precompile 검증)
- **Issue:** @tailwindcss/vite 플러그인이 tailwindcss 패키지를 peer dependency로 요구하는데, @tailwindcss/vite 설치만으로는 자동으로 설치되지 않아 Can't resolve 'tailwindcss' 에러 발생
- **Fix:** pnpm add -D tailwindcss 실행
- **Files modified:** package.json, pnpm-lock.yaml
- **Verification:** RAILS_ENV=production bundle exec rails assets:precompile 성공 (6.00 kB CSS 출력)
- **Committed in:** 4bb6aab (Task 2 commit)

---

**Total deviations:** 2 auto-fixed (1 missing critical, 1 blocking)
**Impact on plan:** 두 수정 모두 빌드 완성에 필수적. 범위 초과 없음.

## Issues Encountered
- pnpm이 시스템에 설치되어 있지 않아 공식 install.sh 스크립트로 설치 후 진행
- bundle exec vite install이 npm으로 node_modules를 설치하여, 이후 node_modules/package-lock.json 제거 후 pnpm으로 재설치

## User Setup Required
None - no external service configuration required.

## Next Phase Readiness
- vite_ruby 빌드 파이프라인 완성, Phase 2-5의 모든 프론트엔드 작업 기반 확보
- React 19 + @vitejs/plugin-react 준비 완료, JSX 컴포넌트 작성 가능
- @tailwindcss/vite 준비 완료, Tailwind v4 @theme 디자인 토큰 유지됨
- app/javascript/controllers/ 기존 디렉토리 보존됨 (app/frontend/controllers/로 이전 완료 후 삭제 가능)
- 잠재적 관심사: bin/dev 실행 후 브라우저에서 HMR 동작 여부는 개발 환경 기동 시 확인 필요

---
*Phase: 01-foundation*
*Completed: 2026-02-22*

## Self-Check: PASSED

All files exist:
- FOUND: teovibe/vite.config.ts
- FOUND: teovibe/config/vite.json
- FOUND: teovibe/app/frontend/entrypoints/application.js
- FOUND: teovibe/app/frontend/entrypoints/application.css
- FOUND: teovibe/app/frontend/controllers/index.js
- DELETED: teovibe/config/importmap.rb (correct)

All commits verified:
- FOUND: afdc9ce (Task 1: Gem/npm 의존성 교체 및 Vite 설정 파일 생성)
- FOUND: 4bb6aab (Task 2: 코드 마이그레이션 및 Vite 빌드 검증 완료)
