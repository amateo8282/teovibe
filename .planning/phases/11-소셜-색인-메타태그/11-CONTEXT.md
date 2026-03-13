# Phase 11: 소셜/색인 메타태그 - Context

**Gathered:** 2026-03-14
**Status:** Ready for planning

<domain>
## Phase Boundary

콘텐츠가 소셜에서 올바르게 미리보기되고 검색 색인이 의도한 대로 제어된다. meta-tags gem의 set_meta_tags를 활용하여 OG/Twitter/canonical/noindex 태그를 컨트롤러에서 설정.

</domain>

<decisions>
## Implementation Decisions

### OG 메타태그
- 게시글: og:title=제목, og:description=본문 앞 150자 truncate, og:url=canonical URL
- og:image: 게시글에 이미지 없으면 사이트 기본 로고 이미지 사용 (public/icon.png 또는 별도 og-default.png)
- 홈/목록 페이지: 사이트 이름/설명/기본 이미지로 고정 OG 태그

### Twitter Card
- summary 타입 사용 (작은 썸네일) — 이미지 자동 생성 없이 단순하게
- twitter:site 계정은 없으면 생략

### canonical URL
- 게시글 상세: 쿼리 파라미터 없는 절대 URL
- set_meta_tags canonical: 으로 설정

### noindex 범위
- Admin 전체 (/admin/*): admin 레이아웃에 noindex 고정
- 로그인/회원가입 페이지: 해당 컨트롤러에서 set_meta_tags noindex: true
- 그 외 추가 noindex 불필요

### Claude's Discretion
- set_meta_tags 호출 위치 (before_action vs 각 액션)
- 기본 OG 이미지 파일명/경로
- description truncate 방식 (strip_tags + truncate)

</decisions>

<code_context>
## Existing Code Insights

### Reusable Assets
- `meta-tags` gem 2.22.3: 이미 설치, `display_meta_tags site: "TeoVibe"` application.html.erb에 적용
- `seo_helper.rb`: JSON-LD 헬퍼 존재, OG/Twitter 로직은 없음

### Established Patterns
- Phase 10에서 credentials.dig 직접 호출 + yield :head 이전 배치 패턴
- 컨트롤러에서 set_meta_tags 호출하는 패턴은 아직 없음 — 이번에 처음 도입

### Integration Points
- `app/views/layouts/application.html.erb`: display_meta_tags 이미 있음 — set_meta_tags만 컨트롤러에서 호출하면 자동 반영
- `app/views/layouts/admin.html.erb`: 별도 레이아웃 — noindex 메타태그 직접 추가
- PostsController#show: og 태그 설정 대상
- HomeController#index: 사이트 기본 OG 설정 대상

</code_context>

<specifics>
## Specific Ideas

No specific requirements — open to standard approaches

</specifics>

<deferred>
## Deferred Ideas

- og:image Active Storage 본문 이미지 자동 추출 (SEOV2-01)
- 게시글별 noindex 토글 (SEOV2-02)

</deferred>

---

*Phase: 11-소셜-색인-메타태그*
*Context gathered: 2026-03-14*
