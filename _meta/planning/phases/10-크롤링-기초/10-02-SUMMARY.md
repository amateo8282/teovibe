---
phase: 10-크롤링-기초
plan: "02"
subsystem: seo
tags: [rails, credentials, meta-tags, google-search-console, naver-search-advisor, tdd]

# Dependency graph
requires:
  - phase: 10-크롤링-기초/10-01
    provides: robots.txt/sitemap.xml 크롤링 기초 인프라

provides:
  - application.html.erb head에 google-site-verification 조건부 메타태그
  - application.html.erb head에 naver-site-verification 조건부 메타태그
  - Rails credentials 기반 토큰 주입 패턴 (credentials.dig :seo)
  - seo_tags_test.rb 통합 테스트 5개

affects:
  - phase-11-소셜-색인-메타태그
  - 검색엔진 색인 관리 및 소유권 인증

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Rails credentials.dig(:seo, :key) 패턴으로 SEO 토큰 조건부 출력"
    - "define_singleton_method으로 credentials.dig 테스트 stub 구현"

key-files:
  created:
    - teovibe/test/integration/seo_tags_test.rb
  modified:
    - teovibe/app/views/layouts/application.html.erb

key-decisions:
  - "credentials.dig 직접 호출 방식 사용 — set_meta_tags verification: 방식 불사용 (특정 뷰에 종속되어 경로 외 소실 위험)"
  - "yield :head 이전에 인증 태그 배치 — 모든 경로에서 일관 출력 보장"
  - "define_singleton_method으로 credentials stub — Minitest 6.x에서 .stub 미지원 대안"

patterns-established:
  - "SEO credentials 패턴: Rails.application.credentials.dig(:seo, :key).present? 조건부 출력"
  - "통합 테스트 credentials stub: define_singleton_method + ensure 블록으로 cleanup"

requirements-completed: [SRCH-01, SRCH-02]

# Metrics
duration: 3min
completed: 2026-03-13
---

# Phase 10 Plan 02: 검색엔진 소유권 인증 메타태그 Summary

**Rails credentials 기반 Google/Naver 소유권 인증 메타태그를 application.html.erb에 조건부 삽입하여 모든 경로에서 일관 출력 보장**

## Performance

- **Duration:** 3 min
- **Started:** 2026-03-13T16:51:29Z
- **Completed:** 2026-03-13T16:54:04Z
- **Tasks:** 1 (TDD: RED + GREEN)
- **Files modified:** 2

## Accomplishments

- application.html.erb에 google-site-verification/naver-site-verification 메타태그 삽입
- credentials 없을 때 에러 없이 태그 미출력 조건부 처리
- 통합 테스트 5개 작성 및 전체 통과 (모든 경로 일관 출력 포함)

## Task Commits

TDD 사이클별 원자적 커밋:

1. **TDD RED: seo_tags_test.rb 작성** - `c576f7d` (test)
2. **TDD GREEN: application.html.erb 메타태그 삽입** - `1f196db` (feat)

## Files Created/Modified

- `teovibe/test/integration/seo_tags_test.rb` - Google/Naver 인증 메타태그 통합 테스트 5개 (credentials stub 헬퍼 포함)
- `teovibe/app/views/layouts/application.html.erb` - display_meta_tags 아래, yield :head 위에 인증 메타태그 조건부 삽입

## Decisions Made

- **set_meta_tags verification: 방식 불사용**: 해당 방식은 특정 뷰의 set_meta_tags 호출에 종속되어, 루트 이외 경로에서 태그가 소실될 수 있음. 직접 erb 삽입 방식 채택
- **define_singleton_method stub**: Minitest 6.x에서 `.stub` 메서드가 Object에 정의되지 않아 credentials 인스턴스에 직접 define_singleton_method 후 ensure 블록에서 cleanup하는 패턴 사용

## Deviations from Plan

**1. [Rule 1 - Bug] Minitest .stub 미지원으로 credentials stub 방식 변경**
- **Found during:** Task 1 (TDD RED 작성 중)
- **Issue:** 플랜에서 `Rails.application.stub(:credentials, ...)` 패턴 제안했으나 Minitest 6.x에서 Object#stub 미지원 (NoMethodError)
- **Fix:** credentials 인스턴스에 `define_singleton_method(:dig)`으로 직접 교체 + ensure로 cleanup
- **Files modified:** teovibe/test/integration/seo_tags_test.rb
- **Verification:** 테스트 5개 모두 통과
- **Committed in:** c576f7d (TDD RED)

---

**Total deviations:** 1 auto-fixed (Rule 1 - stub 방식 대체)
**Impact on plan:** 동일한 격리/복원 목적 달성. 범위 이탈 없음.

## Issues Encountered

- Minitest 6.x에서 `Object#stub`이 미포함 — `require 'minitest/mock'`도 로드 불가. define_singleton_method 방식으로 해결

## User Setup Required

**외부 서비스 수동 설정이 필요합니다.** 아래 항목을 사용자가 직접 설정해야 검색엔진 인증이 완료됩니다:

1. **Google Search Console** (https://search.google.com/search-console)
   - 사이트 속성 추가 후 HTML 태그 인증 방식 선택
   - content 값 복사 후 Rails credentials에 저장:
     ```bash
     cd teovibe && bin/rails credentials:edit
     # 아래 내용 추가:
     seo:
       google_site_verification: [복사한 content 값]
     ```

2. **네이버 서치어드바이저** (https://searchadvisor.naver.com/)
   - 사이트 등록 후 HTML 메타태그 인증 방식 선택
   - content 값 복사 후 Rails credentials에 저장:
     ```bash
     cd teovibe && bin/rails credentials:edit
     # 아래 내용 추가 (google 아래):
     seo:
       google_site_verification: [...]
       naver_site_verification: [복사한 content 값]
     ```

3. **배포 후 확인**: 각 검색엔진 대시보드에서 "인증 확인" 버튼 클릭

## Next Phase Readiness

- Phase 11 (소셜/색인 메타태그)로 진행 가능
- Google/Naver 소유권 인증 코드 완료 — 토큰 발급 후 credentials 설정만 남음
- sitemap.xml, robots.txt (Phase 10-01)와 함께 검색엔진 크롤링 기초 완성

---
*Phase: 10-크롤링-기초*
*Completed: 2026-03-13*
