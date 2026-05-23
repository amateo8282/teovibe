---
phase: 12-구조화-데이터
plan: "01"
subsystem: seo
tags: [json-ld, structured-data, schema.org, rails, erb]

# Dependency graph
requires:
  - phase: 09-xss-보안-패치
    provides: safe_json_ld XSS 이스케이프 래퍼가 구현된 seo_helper.rb

provides:
  - 게시글 상세 페이지 Article JSON-LD (script[type=application/ld+json])
  - 게시글 상세 페이지 BreadcrumbList JSON-LD 홈 > 카테고리 > 게시글 3단계
  - 홈페이지 WebSite JSON-LD
  - 홈페이지 Organization JSON-LD
  - JSON-LD 통합 테스트 6개 (json_ld_test.rb)

affects: [Phase 13, google-rich-results, structured-data-validation]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - content_for :head 블록에 script[type=application/ld+json] 배선 패턴
    - TDD RED-GREEN 사이클로 뷰 구조화 데이터 구현

key-files:
  created:
    - teovibe/test/integration/json_ld_test.rb
  modified:
    - teovibe/app/views/posts/show.html.erb
    - teovibe/app/views/pages/home.html.erb

key-decisions:
  - "content_for :head 블록 내 script 태그 배치 — 레이아웃의 yield :head 위치에 자동 삽입"
  - "category_posts_url(절대 URL) 사용 — BreadcrumbList item 필드는 절대 URL 필요"
  - "홈페이지는 기존 vite_javascript_tag 유지하면서 JSON-LD만 추가 — 기존 코드 보존 원칙"

patterns-established:
  - "JSON-LD 배선 패턴: content_for :head do ... script type=application/ld+json ... end"
  - "BreadcrumbList 3단계: { name: 홈, url: root_url }, { name: 카테고리명, url: category_posts_url }, { name: 게시글제목 }"

requirements-completed: [STRD-01, STRD-02, STRD-03]

# Metrics
duration: 15min
completed: 2026-03-14
---

# Phase 12 Plan 01: 구조화 데이터 JSON-LD 배선 Summary

**게시글 상세(Article + BreadcrumbList)와 홈페이지(WebSite + Organization) JSON-LD를 schema.org 표준으로 배선하여 Google Rich Results 자격 조건 충족**

## Performance

- **Duration:** 15 min
- **Started:** 2026-03-14T17:40:00Z
- **Completed:** 2026-03-14T17:55:00Z
- **Tasks:** 2
- **Files modified:** 3

## Accomplishments

- 게시글 상세 페이지에 Article JSON-LD (headline, datePublished, author.name, publisher) 출력
- 게시글 상세 페이지에 BreadcrumbList JSON-LD 홈 > 카테고리 > 게시글 3단계 구조 출력
- 홈페이지에 WebSite + Organization JSON-LD 출력 (기존 vite_javascript_tag 유지)
- JSON-LD 통합 테스트 6개 신규 작성 및 전부 PASS

## Task Commits

각 태스크는 원자적으로 커밋됨:

1. **TDD RED: JSON-LD 통합 테스트 작성** - `4b2c983` (test)
2. **Task 1: 게시글 상세 Article + BreadcrumbList JSON-LD 배선** - `54dc0d2` (feat)
3. **Task 2: 홈페이지 WebSite + Organization JSON-LD 배선** - `0ebdb23` (feat)

_TDD 사이클: RED(테스트) -> GREEN(구현), 두 태스크 모두 TDD 적용_

## Files Created/Modified

- `teovibe/test/integration/json_ld_test.rb` — JSON-LD 통합 테스트 6개 (112라인)
- `teovibe/app/views/posts/show.html.erb` — content_for :head 블록 추가 (Article + BreadcrumbList)
- `teovibe/app/views/pages/home.html.erb` — 기존 content_for :head 블록에 WebSite + Organization 추가

## Decisions Made

- `category_posts_url` (절대 URL) 사용: BreadcrumbList의 `item` 필드는 schema.org 표준상 절대 URL이어야 함
- 홈페이지 content_for :head 블록에 JSON-LD 추가 시 기존 `vite_javascript_tag` 라인 유지 — CLAUDE.md "기존 코드 보존" 원칙 준수
- ActionText rich_texts 픽스처는 별도 선언 불필요 — posts 픽스처 로드 시 자동 포함됨

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered

- `fixtures :action_text_rich_texts` 선언 시 "No fixture files found" 오류 발생 — ActionText 픽스처는 `action_text/rich_texts` 서브디렉토리에 위치하므로 단순 `posts` 픽스처로 충분함. 즉시 수정하여 RED 단계 테스트 실행 성공.

## User Setup Required

None - 뷰 레벨 변경만 포함, 외부 서비스 설정 불필요.

## Next Phase Readiness

- 게시글 상세 및 홈페이지 구조화 데이터 완비 — Google Search Console에서 Rich Results 테스트 가능
- Phase 13 (Admin 에디터 UX): 모델/컨트롤러 변경 없는 순수 HTML+Tailwind 작업, 독립 진행 가능

---
*Phase: 12-구조화-데이터*
*Completed: 2026-03-14*
