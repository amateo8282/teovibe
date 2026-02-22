---
phase: 01-foundation
plan: 02
subsystem: infra
tags: [sqlite, solid-queue, wal, rails, database]

# Dependency graph
requires:
  - phase: 01-foundation/01-01
    provides: Rails 앱 초기 설정 및 Solid Queue/Cache/Cable gem 설치
provides:
  - 개발 환경 Solid Queue/Cache/Cable 별도 SQLite DB 구성
  - 모든 개발 DB WAL 모드 활성화
  - Solid Queue를 개발 환경 active_job 어댑터로 설정
affects: [02-authentication, 03-core-features]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "개발/프로덕션 환경 모두 Solid Queue/Cache/Cable 별도 DB 사용 (storage/{env}_{type}.sqlite3)"
    - "모든 SQLite DB에 WAL 모드 자동 적용 (sqlite3 gem 2.9.0+)"

key-files:
  created: []
  modified:
    - teovibe/config/database.yml
    - teovibe/config/environments/development.rb
    - teovibe/config/initializers/assets.rb.disabled

key-decisions:
  - "개발 환경에도 프로덕션과 동일한 Solid 인프라 DB 구조 적용 (primary/cache/queue/cable 분리)"
  - "Solid Cache/Cable 개발 환경 활성화는 선택적 -- Phase 1에서는 주석으로 준비만"
  - "vite_rails 환경과 충돌하는 Sprockets 잔재(assets.rb initializer, config.assets.quiet) 제거"

patterns-established:
  - "storage/{env}_{type}.sqlite3 명명 규칙: development_queue.sqlite3, development_cache.sqlite3 등"

requirements-completed: [INFRA-02]

# Metrics
duration: 7min
completed: 2026-02-22
---

# Phase 1 Plan 02: 개발 환경 Solid 인프라 DB 구성 Summary

**개발 환경에서 Solid Queue/Cache/Cable이 별도 SQLite 파일(WAL 모드)을 사용하도록 database.yml을 구성하고, Solid Queue를 active_job 어댑터로 활성화**

## Performance

- **Duration:** 7 min
- **Started:** 2026-02-22T07:53:08Z
- **Completed:** 2026-02-22T07:54:53Z
- **Tasks:** 2
- **Files modified:** 3

## Accomplishments
- development 섹션에 primary/cache/queue/cable 4개 별도 SQLite DB 설정 추가
- 모든 개발 DB 파일 생성 후 WAL 모드(journal_mode=wal) 확인 완료
- Solid Queue가 개발 환경 active_job 어댑터(SolidQueueAdapter)로 동작

## Task Commits

각 태스크는 원자적으로 커밋됨:

1. **Task 1: database.yml 개발 환경 Solid DB 추가** - `6e10fe8` (feat)
2. **Task 2: Solid Queue 활성화 및 WAL 모드 검증** - `5ca8166` (feat)

**Plan metadata:** (다음 커밋에서 생성)

## Files Created/Modified
- `teovibe/config/database.yml` - development 섹션에 cache/queue/cable 별도 DB 경로 추가
- `teovibe/config/environments/development.rb` - Solid Queue adapter 설정, Sprockets 잔재 제거
- `teovibe/config/initializers/assets.rb.disabled` - vite_rails 환경에서 불필요한 Sprockets 이니셜라이저 비활성화

## Decisions Made
- 개발 환경도 프로덕션과 동일하게 Solid 인프라를 분리된 DB로 운영하여 배포 시 차이 최소화
- Solid Cache/Cable은 개발에서 주석 처리로 준비만 -- memory_store/async로도 충분하기 때문
- Sprockets 잔재를 제거하여 vite_rails 환경에서의 오류 근본 해결

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] bundle install 실행 (vite_rails gem 미설치)**
- **Found during:** Task 2 (Solid Queue 활성화)
- **Issue:** `vite_rails` gem이 로컬에 설치되지 않아 bin/rails db:migrate 실패
- **Fix:** `bundle install` 실행하여 Gemfile.lock의 모든 gem 설치
- **Files modified:** 없음 (gem 설치만)
- **Verification:** bundle install 완료 후 migration 정상 실행
- **Committed in:** `5ca8166` (Task 2 커밋에 포함)

**2. [Rule 1 - Bug] Sprockets 잔재 제거 (vite_rails와 충돌)**
- **Found during:** Task 2 (bin/rails db:migrate 실행 중)
- **Issue:** `config/environments/development.rb`의 `config.assets.quiet`와 `config/initializers/assets.rb`의 `config.assets.version`이 Sprockets 전용 설정으로 vite_rails 환경에서 `NoMethodError` 발생
- **Fix:** development.rb에서 `config.assets.quiet` 줄 제거, assets.rb를 assets.rb.disabled로 이름 변경
- **Files modified:** teovibe/config/environments/development.rb, teovibe/config/initializers/assets.rb.disabled
- **Verification:** bin/rails db:migrate 정상 완료, bin/rails runner 정상 동작
- **Committed in:** `5ca8166` (Task 2 커밋에 포함)

---

**Total deviations:** 2 auto-fixed (1 blocking, 1 bug)
**Impact on plan:** 두 수정 모두 Rails 앱 정상 동작에 필수적. 범위 초과 없음.

## Issues Encountered
- Psych 5.x에서 YAML aliases 파싱 시 `aliases: true` 옵션 필요 -- 검증 명령어를 `YAML.load_file(path, aliases: true)` 방식으로 조정. Rails 내부에서는 정상 파싱됨.

## User Setup Required
없음 -- 외부 서비스 구성 불필요.

## Next Phase Readiness
- 개발 환경 인프라 DB 구성 완료로 Phase 1 Plan 03(vite_ruby 설정) 진행 가능
- storage/ 디렉토리에 development_queue.sqlite3, development_cache.sqlite3, development_cable.sqlite3 파일 생성됨
- Solid Queue가 정상 동작하는 상태 -- 백그라운드 작업 기반 기능(이메일, 알림 등) 구현 가능

---
*Phase: 01-foundation*
*Completed: 2026-02-22*
