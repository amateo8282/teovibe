---
phase: 02-content-experience
plan: "02"
subsystem: ui
tags: [rails, active-storage, avatar, badges, social-links, profile, gamification]

# Dependency graph
requires:
  - phase: 01-foundation
    provides: User 모델, profiles_controller, 프로필 뷰 기반 구조
provides:
  - Active Storage avatar 첨부 (has_one_attached :avatar)
  - 소셜링크 3개 컬럼 (github_url, twitter_url, website_url)
  - Badgeable concern (earned_badges 메서드, 4개 뱃지 정의)
  - display_avatar_url 헬퍼 (Active Storage 우선, avatar_url 폴백)
  - 프로필 show 페이지 아바타/뱃지/소셜링크 표시
  - 프로필 edit 폼 아바타 업로드 + 소셜링크 입력
affects: [03-engagement, 04-monetization]

# Tech tracking
tech-stack:
  added: [Active Storage (has_one_attached)]
  patterns: [Concern 모듈로 뱃지 로직 분리, display_avatar_url 폴백 패턴]

key-files:
  created:
    - teovibe/app/models/concerns/badgeable.rb
    - teovibe/db/migrate/20260222083121_add_social_links_to_users.rb
  modified:
    - teovibe/app/models/user.rb
    - teovibe/app/controllers/profiles_controller.rb
    - teovibe/app/views/profiles/show.html.erb
    - teovibe/app/views/profiles/edit.html.erb

key-decisions:
  - "Active Storage 아바타 첨부 시 기존 avatar_url 컬럼 유지 (OAuth 아바타 폴백 보존)"
  - "소셜링크를 JSON 컬럼이 아닌 3개 별도 string 컬럼으로 구현 (파싱 복잡도 회피)"
  - "뱃지 로직을 별도 gem 없이 Badgeable concern으로 직접 구현 (4개 뱃지에 gem은 과도)"

patterns-established:
  - "display_avatar_url 패턴: Active Storage 첨부 우선 확인, 기존 URL 폴백"
  - "Badgeable concern: BADGES 상수 + earned_badges 메서드로 뱃지 계산 캡슐화"

requirements-completed: [PROF-01, PROF-02]

# Metrics
duration: 2min
completed: 2026-02-22
---

# Phase 02 Plan 02: 프로필 강화 Summary

**Active Storage 아바타 업로드, github/twitter/website 소셜링크 컬럼, 4개 뱃지 Badgeable concern으로 작성자 프로필 페이지 게이미피케이션 완성**

## Performance

- **Duration:** 2 min
- **Started:** 2026-02-22T08:31:13Z
- **Completed:** 2026-02-22T08:33:01Z
- **Tasks:** 2
- **Files modified:** 6

## Accomplishments

- User 모델에 Active Storage avatar 첨부 + Badgeable concern include + display_avatar_url 폴백 헬퍼 추가
- AddSocialLinksToUsers 마이그레이션으로 github_url, twitter_url, website_url 3개 컬럼 추가
- 프로필 show 페이지에 아바타(Active Storage + URL 폴백 + 이니셜 폴백), earned_badges 뱃지 섹션, 소셜링크 표시 구현
- 프로필 edit 폼에 아바타 파일 업로드 필드 + 소셜링크 3개 입력 필드 추가
- profiles_controller profile_params에 신규 파라미터 모두 permit 처리

## Task Commits

각 태스크는 원자적으로 커밋:

1. **Task 1: User 모델 확장 (Active Storage 아바타 + 소셜링크 + Badgeable)** - `7915738` (feat)
2. **Task 2: 프로필 페이지 뷰 및 컨트롤러 업데이트** - `ffe6d1d` (feat)

## Files Created/Modified

- `teovibe/app/models/concerns/badgeable.rb` - 4개 뱃지 정의 및 earned_badges 메서드 (Badgeable concern)
- `teovibe/db/migrate/20260222083121_add_social_links_to_users.rb` - github_url, twitter_url, website_url 컬럼 마이그레이션
- `teovibe/app/models/user.rb` - has_one_attached :avatar, include Badgeable, display_avatar_url 헬퍼 추가
- `teovibe/app/controllers/profiles_controller.rb` - profile_params에 :avatar, :github_url, :twitter_url, :website_url permit 추가
- `teovibe/app/views/profiles/show.html.erb` - 아바타, 뱃지, 소셜링크 섹션 추가
- `teovibe/app/views/profiles/edit.html.erb` - 아바타 업로드 필드, 소셜링크 입력 필드 추가

## Decisions Made

- Active Storage 아바타를 추가하면서 기존 avatar_url 컬럼 유지: OAuth 로그인 시 받아오는 아바타 URL이 폴백으로 동작
- 소셜링크를 JSON 단일 컬럼이 아닌 3개 별도 string 컬럼으로 구현: 파싱/직렬화 복잡도 없이 간단한 permit/update 처리 가능
- 뱃지 로직을 별도 gem 없이 Concern으로 직접 구현: 4개 고정 뱃지에 merit/merit-badge 등 gem은 과도한 의존성

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered

None

## User Setup Required

None - no external service configuration required.

Active Storage는 Rails 기본 내장이므로 별도 설정 불필요. 프로덕션 배포 시 storage.yml에서 S3 등 외부 스토리지 설정 권장 (현재는 local disk).

## Next Phase Readiness

- 프로필 페이지 강화 완료. 소셜링크, 아바타, 뱃지 모두 표시 및 편집 가능
- Phase 02 Plan 03 (콘텐츠 경험 개선) 진행 가능

---
*Phase: 02-content-experience*
*Completed: 2026-02-22*
