# Phase 12: 구조화 데이터 - Context

**Gathered:** 2026-03-14
**Status:** Ready for planning

<domain>
## Phase Boundary

기존 seo_helper.rb의 JSON-LD 헬퍼(article_json_ld, breadcrumb_json_ld, website_json_ld, organization_json_ld)를 뷰에서 호출하여 구조화 데이터를 실제로 출력한다. 헬퍼 자체는 이미 구현 완료 — 이 Phase는 배선(wiring) 작업.

</domain>

<decisions>
## Implementation Decisions

### JSON-LD 출력 위치
- 게시글 상세: content_for :head 블록에서 article_json_ld + breadcrumb_json_ld 호출
- 홈페이지: content_for :head 블록에서 website_json_ld + organization_json_ld 호출
- script type="application/ld+json" 태그로 래핑

### BreadcrumbList 계층 구조
- 홈 > 카테고리 > 게시글 3단계
- 카테고리 URL은 category_posts_path 사용 (Phase 10에서 확립된 패턴)

### Claude's Discretion
- content_for :head vs 별도 partial 선택
- 테스트에서 JSON-LD 파싱 방식
- BreadcrumbList 항목의 정확한 name 값

</decisions>

<code_context>
## Existing Code Insights

### Reusable Assets
- `seo_helper.rb`: article_json_ld, breadcrumb_json_ld, website_json_ld, organization_json_ld 전부 구현됨
- `safe_json_ld`: XSS 이스케이프 래퍼 (Phase 9 패치 완료)
- `application.html.erb`: yield :head 블록 존재 — content_for :head로 JSON-LD 주입 가능

### Established Patterns
- Phase 11에서 set_meta_tags 컨트롤러 패턴 확립
- Phase 10에서 yield :head 이전 배치 패턴 확립

### Integration Points
- `posts/show.html.erb`: article_json_ld + breadcrumb_json_ld 호출 대상
- `pages/home.html.erb` 또는 홈 뷰: website_json_ld + organization_json_ld 호출 대상
- `application.html.erb` yield :head: JSON-LD script 태그 렌더링 지점

</code_context>

<specifics>
## Specific Ideas

No specific requirements — 기존 헬퍼를 뷰에 연결하는 단순 작업

</specifics>

<deferred>
## Deferred Ideas

None — discussion stayed within phase scope

</deferred>

---

*Phase: 12-구조화-데이터*
*Context gathered: 2026-03-14*
