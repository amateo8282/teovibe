---
phase: 10-크롤링-기초
plan: 01
subsystem: infra
tags: [robots.txt, sitemap, seo, crawling, rails, sitemap_generator]

# Dependency graph
requires: []
provides:
  - 동적 robots.txt 컨트롤러 (Googlebot/Yeti 명시 허용, 비프로덕션 전체 Disallow)
  - sitemap.rb 동적화 (Category DB 루프, post_path 통합)
  - 정적 public/robots.txt 제거
affects:
  - 11-소셜-색인-메타태그
  - 12-구조화-데이터

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "allow_unauthenticated_access로 인증 없이 접근 가능한 공개 엔드포인트 패턴"
    - "expires_in N.hours, public: true 로 CDN 캐시 설정 패턴"
    - "Rails.env.production? 조건으로 환경별 분기하는 뷰 템플릿 패턴"
    - "sitemap.rb에서 category_posts_path(category_slug: cat.slug) 동적 루프 패턴"

key-files:
  created:
    - teovibe/app/controllers/robots_controller.rb
    - teovibe/app/views/robots/show.text.erb
    - teovibe/test/controllers/robots_controller_test.rb
    - teovibe/test/integration/sitemap_test.rb
  modified:
    - teovibe/config/routes.rb
    - teovibe/config/sitemap.rb
    - teovibe/test/fixtures/posts.yml
  deleted:
    - teovibe/public/robots.txt

key-decisions:
  - "정적 public/robots.txt 삭제 필수 — Rails는 정적 파일을 라우터보다 우선 처리하므로 컨트롤러가 무시됨"
  - "비프로덕션 환경은 전체 Disallow — 개발/스테이징 환경이 검색엔진에 인덱싱되는 것 방지"
  - "sitemap 게시글 섹션에서 카테고리 의존성 제거 — post_path(post)로 통합하여 카테고리 없는 게시글도 포함 가능"
  - "픽스처 slug를 라우트 constraint에 맞게 수정 (숫자 prefix) — test-blog-post → 1-test-blog-post"

patterns-established:
  - "TDD RED: 뷰 파일 부재 + 라우트 없음으로 실패 확인"
  - "production 분기 검증: File.read로 ERB 템플릿 내용 직접 assert (환경 stub 불필요)"
  - "sitemap 구조 검증: File.read로 sitemap.rb 내용 정적 분석 + url_helpers로 라우트 동작 확인"

requirements-completed: [CRAWL-01, CRAWL-02, CRAWL-03]

# Metrics
duration: 20min
completed: 2026-03-14
---

# Phase 10 Plan 01: 동적 robots.txt 컨트롤러 및 sitemap 동적화 Summary

**RobotsController(Googlebot/Yeti 명시 허용, 6시간 캐시), 환경별 분기 ERB 뷰, sitemap.rb 카테고리/게시글 하드코딩 제거 후 DB 동적 루프로 교체**

## Performance

- **Duration:** 20min
- **Started:** 2026-03-14
- **Completed:** 2026-03-14
- **Tasks:** 2
- **Files modified:** 7 (4 created, 3 modified/deleted)

## Accomplishments
- RobotsController 생성: allow_unauthenticated_access, 6시간 CDN 캐시, text/plain 응답
- show.text.erb 뷰: production에서 Googlebot/Yeti Allow + Disallow(/admin/, /auth/, /profile/edit) + Sitemap URL, 비프로덕션에서 전체 Disallow
- 정적 public/robots.txt 삭제 (컨트롤러 라우팅 우선 처리)
- sitemap.rb: category_posts_path 동적 루프, post_path(post) 통합 (카테고리 하드코딩 완전 제거)
- 테스트 18개 전부 통과

## Task Commits

각 태스크는 원자적으로 커밋됨:

1. **Task 1: 동적 robots.txt 컨트롤러 (TDD)** - `e80fb5e` (feat)
2. **Task 2: sitemap.rb 카테고리/게시글 동적화 (TDD)** - `699adab` (feat)

## Files Created/Modified
- `teovibe/app/controllers/robots_controller.rb` - 동적 robots.txt 컨트롤러 (allow_unauthenticated_access, expires_in)
- `teovibe/app/views/robots/show.text.erb` - 환경별 분기 robots.txt 뷰 (production/비프로덕션)
- `teovibe/config/routes.rb` - GET /robots.:format 라우트 추가
- `teovibe/config/sitemap.rb` - 카테고리/게시글 하드코딩 제거, 동적 루프로 교체
- `teovibe/test/controllers/robots_controller_test.rb` - robots.txt 컨트롤러 테스트 7개
- `teovibe/test/integration/sitemap_test.rb` - sitemap 동적화 통합 테스트 11개
- `teovibe/test/fixtures/posts.yml` - slug를 라우트 constraint에 맞게 수정
- `teovibe/public/robots.txt` - 삭제 (정적 파일 제거)

## Decisions Made
- 정적 public/robots.txt 삭제: Rails는 public/ 정적 파일을 라우터보다 먼저 서빙하므로 컨트롤러가 무시됨. 삭제 필수.
- production 분기 테스트 방식: Rails.stub env 대신 File.read로 ERB 템플릿 내용 직접 assert. 환경 stub은 Rails 8에서 복잡하므로 템플릿 정적 분석 방식 선택.
- sitemap 게시글 라우트 단일화: 카테고리별 라우트(blog_path, tutorial_path 등) 대신 post_path(post) 하나로 통합. 카테고리 없는 게시글도 sitemap에 포함 가능.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] 픽스처 slug가 라우트 constraint에 맞지 않음**
- **Found during:** Task 2 (sitemap 테스트 작성 중)
- **Issue:** 기존 fixtures/posts.yml의 slug `test-blog-post`가 routes.rb의 constraint `/(\d|post-).*/`에 매칭되지 않아 post_path(post) 테스트에서 UrlGenerationError 발생
- **Fix:** 픽스처 slug를 `1-test-blog-post`, `2-test-notice-post`로 수정 (숫자 prefix)
- **Files modified:** teovibe/test/fixtures/posts.yml
- **Verification:** 테스트 11개 전부 통과
- **Committed in:** 699adab (Task 2 커밋)

---

**Total deviations:** 1 auto-fixed (Rule 1 - Bug)
**Impact on plan:** 픽스처 수정은 기존 테스트에도 영향 없음. 라우트 constraint 규칙(CLAUDE.md에 문서화됨)을 테스트 데이터에도 일관 적용.

## Issues Encountered
- 사전 존재하던 AiDraftServiceTest 2개 실패(AI 모델 버전 ID 불일치) — 이번 플랜과 무관한 기존 문제. 범위 외로 처리.

## User Setup Required
None - 외부 서비스 설정 불필요.

## Next Phase Readiness
- robots.txt 동적 컨트롤러 완료. GET /robots.txt가 프로덕션에서 Googlebot/Yeti 명시 허용, 비프로덕션에서 전체 차단.
- sitemap.rb 동적화 완료. Admin에서 카테고리 추가 시 sitemap 재생성에 자동 반영.
- Phase 11 (소셜/색인 메타태그) 진행 가능.

## Self-Check: PASSED

모든 생성 파일 존재 확인 및 커밋 해시 확인 완료.

---
*Phase: 10-크롤링-기초*
*Completed: 2026-03-14*
