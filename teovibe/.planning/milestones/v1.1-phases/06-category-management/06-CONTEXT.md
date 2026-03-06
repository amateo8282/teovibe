# Phase 6: 카테고리 동적 관리 - Context

**Gathered:** 2026-02-28
**Status:** Ready for planning

<domain>
## Phase Boundary

Admin이 게시판/스킬팩 카테고리를 런타임에 CRUD하고, 순서 변경 + 관리자 전용 토글을 설정. 기존 하드코딩 enum을 DB 기반 Category 모델로 전환.

</domain>

<decisions>
## Implementation Decisions

### 데이터 이관 전략
- 통합 URL로 전환: 모든 카테고리를 /posts/:category_slug 형식으로 통일. 기존 /blogs, /tutorials 등은 리다이렉트 라우트로 처리
- 통합 테이블: categories 테이블 하나에 record_type 컬럼(post/skill_pack)으로 구분
- 컨트롤러 통합: 기존 6개 개별 컨트롤러(BlogsController 등) 삭제, PostsController 하나로 통합. 기존 URL은 리다이렉트

### Admin 카테고리 UI
- 테이블 목록: LandingSection과 같은 테이블 형식으로 이름/슬러그/게시글수/순서 표시
- 드래그앤드롭 순서 변경: Sortable.js로 드래그해서 순서 변경
- 관리자 전용 토글: 카테고리 목록에서 인라인 토글 스위치로 바로 전환 (Turbo Stream)

### Navbar 반영
- 전체 동적 로드: Category.ordered에서 전체 로드하여 Navbar에 표시
- visible_in_nav 토글: 카테고리별로 Navbar 노출 여부 설정 가능. 숨겨진 카테고리는 URL 직접 접근만 가능

### 카테고리 삭제 정책
- 삭제 거부: 게시글이 있는 카테고리는 삭제 불가. "게시글 N개가 있어 삭제할 수 없습니다" 메시지 표시

### Claude's Discretion
- 마이그레이션 SQL 세부 구현 (enum → FK 매핑)
- Admin 폼 레이아웃 세부 디자인
- Sortable.js Stimulus 컨트롤러 구조
- 리다이렉트 라우트 세부 설정

</decisions>

<code_context>
## Existing Code Insights

### Reusable Assets
- LandingSection: position + move_up/move_down 패턴, Admin CRUD 컨트롤러 구조 재사용 가능
- Admin::BaseController: 인증/권한 체크 기반 컨트롤러
- PostsBaseController: category별 분기 로직 (통합 시 제거 대상)

### Established Patterns
- Admin 네임스페이스: Admin::LandingSectionsController 패턴 (index, new, create, edit, update, destroy + move_up/move_down/toggle)
- enum 패턴: Post.category (integer enum), SkillPack.category (integer enum)
- Turbo Stream: 인라인 업데이트 패턴 (toggle_active 등)

### Integration Points
- Post.category enum (blog:0, tutorial:1, free_board:2, qna:3, portfolio:4, notice:5) → category_id FK로 전환
- SkillPack.category enum (template:0, component:1, guide:2, toolkit:3) → category_id FK로 전환
- config/routes.rb: 개별 resources 6개 → 통합 resources + 리다이렉트
- app/views/shared/_navbar.html.erb: 하드코딩 링크 → 동적 루프
- app/helpers/application_helper.rb, seo_helper.rb: 카테고리 참조 코드
- config/sitemap.rb: 카테고리별 URL 생성

</code_context>

<specifics>
## Specific Ideas

No specific requirements — open to standard approaches

</specifics>

<deferred>
## Deferred Ideas

None — discussion stayed within phase scope

</deferred>

---

*Phase: 06-category-management*
*Context gathered: 2026-02-28*
