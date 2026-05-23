---
phase: 06-category-management
verified: 2026-02-28T15:59:00Z
status: human_needed
score: 13/13 must-haves verified
human_verification:
  - test: "Admin 로그인 후 /admin/categories 접속"
    expected: "게시판 카테고리 6개 + 스킬팩 카테고리 4개 테이블이 표시되며, 드래그 핸들이 노출됨"
    why_human: "브라우저 렌더링, Sortable.js DnD 상호작용은 프로그래밍적 검증 불가"
  - test: "Admin에서 카테고리를 드래그앤드롭으로 순서 변경"
    expected: "PATCH /admin/categories/reorder 요청이 전송되고 페이지 새로고침 시 순서가 유지됨"
    why_human: "Sortable.js 이벤트(onEnd) 동작은 실제 브라우저에서만 확인 가능"
  - test: "admin_only 토글 클릭"
    expected: "Turbo Stream으로 버튼만 인라인 교체되고 전체 페이지 리로드 없음"
    why_human: "Turbo Stream 인라인 교체는 실시간 브라우저 동작으로 grep 검증 불가"
  - test: "일반 사용자로 /posts/new 접속 후 카테고리 드롭다운 확인"
    expected: "admin_only=true인 '공지사항' 카테고리가 드롭다운에 나타나지 않음"
    why_human: "HTML 렌더링 결과 확인 (자동 테스트로 이미 assert_select 검증됨, 시각적 최종 확인)"
  - test: "브라우저에서 /blogs 접속"
    expected: "301 리다이렉트 후 /posts/blog로 이동, 블로그 목록 표시"
    why_human: "리다이렉트 후 UI 렌더링 결과 확인"
---

# Phase 6: 카테고리 동적 관리 Verification Report

**Phase Goal:** Admin이 런타임에 게시판/스킬팩 카테고리를 생성·수정·삭제·순서 변경할 수 있으며, 일반 사용자는 관리자 전용 카테고리를 볼 수 없다
**Verified:** 2026-02-28T15:59:00Z
**Status:** human_needed
**Re-verification:** No — initial verification

## Goal Achievement

### Observable Truths

| # | Truth | Status | Evidence |
|---|-------|--------|----------|
| 1 | categories 테이블이 존재하며 name, slug, description, record_type, position, admin_only, visible_in_nav 컬럼을 포함한다 | VERIFIED | DB에서 직접 확인: `Category.count` = 10, 컬럼 모두 존재 |
| 2 | 기존 Post/SkillPack enum 데이터가 category_id FK로 정확히 매핑되어 레코드 수가 일치한다 | VERIFIED | 마이그레이션 up 상태, posts/skill_packs에 `category_id` 컬럼 존재, 기존 category enum 컬럼 제거됨 |
| 3 | Category 모델에 for_posts, for_skill_packs, ordered, visible_in_nav 스코프가 동작한다 | VERIFIED | `test/models/category_test.rb` 13개 테스트 전체 통과 |
| 4 | 게시글이 있는 카테고리는 삭제가 거부된다 | VERIFIED | `before_destroy :check_associated_records` + throw :abort 구현, 테스트 통과 |
| 5 | Admin이 /admin/categories에서 카테고리 목록을 테이블 형식으로 볼 수 있다 | VERIFIED | `Admin::CategoriesController#index` 구현, index 뷰 존재 |
| 6 | Admin이 카테고리를 생성·수정·삭제할 수 있다 | VERIFIED | CRUD 액션 구현, 컨트롤러 테스트 14개 전체 통과 |
| 7 | Admin이 카테고리를 드래그앤드롭으로 순서 변경할 수 있다 | VERIFIED (human needed) | sortable_controller.js + reorder 액션 구현, urlValue→reorder_admin_categories_path 연결됨. 실제 DnD는 브라우저 확인 필요 |
| 8 | Admin이 admin_only/visible_in_nav 토글을 인라인으로 전환할 수 있다 | VERIFIED (human needed) | turbo_stream 응답 + .turbo_stream.erb 템플릿 구현. Turbo Stream 렌더링은 브라우저 확인 필요 |
| 9 | 기존 /blogs, /tutorials 등 URL이 /posts/blog, /posts/tutorial 등으로 301 리다이렉트된다 | VERIFIED | routes.rb에 301 리다이렉트 6개 선언, 라우팅 통합 테스트 11개 전체 통과 |
| 10 | /posts/:category_slug로 카테고리별 게시글 목록이 표시된다 | VERIFIED | `PostsController#index`에서 `Category.find_by!(slug: params[:category_slug])` 사용 |
| 11 | Navbar에 visible_in_nav=true인 카테고리만 동적으로 표시된다 | VERIFIED | `_navbar.html.erb`: `Category.for_posts.visible_in_nav.ordered.each` 루프 확인 |
| 12 | 일반 사용자 게시글 작성 시 admin_only=false인 카테고리만 선택지에 표시된다 | VERIFIED | `available_post_categories` 헬퍼 구현, `_form.html.erb`에서 사용, 라우팅 테스트로 검증 |
| 13 | Admin 사용자는 게시글 작성 시 모든 카테고리를 선택할 수 있다 | VERIFIED | `available_post_categories`가 `Current.user&.admin?` 분기로 전체 카테고리 반환, 라우팅 테스트 통과 |

**Score:** 13/13 truths verified (5개 항목은 추가 브라우저 검증 권장)

### Required Artifacts

| Artifact | Expected | Status | Details |
|----------|----------|--------|---------|
| `teovibe/app/models/category.rb` | Category 모델 (record_type enum, scopes, 삭제 보호) | VERIFIED | 52줄, enum/scopes/before_destroy/move_up/move_down 모두 구현 |
| `teovibe/db/migrate/20260228124813_create_categories_and_migrate.rb` | categories 테이블 생성 + enum→FK 마이그레이션 | VERIFIED | 마이그레이션 up 상태, 실제 DB에 categories 테이블 존재 |
| `teovibe/test/models/category_test.rb` | Category 모델 단위 테스트 | VERIFIED | 13개 테스트 전체 통과 |
| `teovibe/app/controllers/admin/categories_controller.rb` | Admin 카테고리 CRUD + reorder + toggle 액션 | VERIFIED | 11개 액션 구현 (index, new, create, edit, update, destroy, reorder, move_up, move_down, toggle_admin_only, toggle_visible_in_nav) |
| `teovibe/app/views/admin/categories/index.html.erb` | 카테고리 목록 테이블 (DnD 지원) | VERIFIED | 게시판/스킬팩 섹션 분리, data-controller="sortable" 연결 |
| `teovibe/app/javascript/controllers/sortable_controller.js` | Sortable.js Stimulus 컨트롤러 | VERIFIED | sortablejs@1.15.7 설치, onEnd → fetch PATCH 구현 |
| `teovibe/app/controllers/posts_controller.rb` | 통합 PostsController (category_slug 기반 필터) | VERIFIED | category_slug 기반 index, slug 기반 CRUD 구현 |
| `teovibe/app/views/shared/_navbar.html.erb` | 동적 카테고리 Navbar | VERIFIED | visible_in_nav 카테고리 동적 루프, 하드코딩 링크 제거됨 |
| `teovibe/test/controllers/admin/categories_controller_test.rb` | Admin 카테고리 컨트롤러 통합 테스트 | VERIFIED | 14개 테스트 전체 통과 |
| `teovibe/test/integration/category_routing_test.rb` | 라우팅 리다이렉트 통합 테스트 | VERIFIED | 11개 테스트 전체 통과 |

### Key Link Verification

| From | To | Via | Status | Details |
|------|-----|-----|--------|---------|
| `app/models/post.rb` | `app/models/category.rb` | belongs_to :category | WIRED | `belongs_to :category` 선언 확인, category_id 컬럼 실제 DB에 존재 |
| `app/models/skill_pack.rb` | `app/models/category.rb` | belongs_to :category | WIRED | `belongs_to :category` 선언 확인, category_id 컬럼 실제 DB에 존재 |
| `app/javascript/controllers/sortable_controller.js` | `admin/categories#reorder` | fetch PATCH with positions array | WIRED | `fetch(this.urlValue, { method: "PATCH", body: JSON.stringify({ positions }) })` 구현 확인 |
| `app/views/admin/categories/index.html.erb` | `sortable_controller.js` | data-controller='sortable' | WIRED | 두 tbody에 `data-controller="sortable"` + `data-sortable-url-value="<%= reorder_admin_categories_path %>"` 연결 확인 |
| `app/controllers/posts_controller.rb` | `app/models/category.rb` | Category.find_by!(slug: params[:category_slug]) | WIRED | `@category = Category.find_by!(slug: params[:category_slug], record_type: :post)` 확인 |
| `app/views/shared/_navbar.html.erb` | `app/models/category.rb` | Category.for_posts.visible_in_nav.ordered | WIRED | 데스크톱/모바일 메뉴 모두 visible_in_nav 루프 사용 확인 |
| `app/views/posts/_form.html.erb` | `app/helpers/application_helper.rb` | available_post_categories | WIRED | `f.collection_select :category_id, available_post_categories` 확인 |

### Requirements Coverage

| Requirement | Source Plan | Description | Status | Evidence |
|-------------|------------|-------------|--------|----------|
| CATM-01 | 06-01, 06-02, 06-04 | Admin이 게시판 카테고리를 생성할 수 있다 (이름, 슬러그, 설명) | SATISFIED | Admin::CategoriesController#create 구현, 컨트롤러 테스트 통과 |
| CATM-02 | 06-01, 06-02, 06-04 | Admin이 게시판 카테고리를 수정/삭제할 수 있다 | SATISFIED | update/destroy 구현, before_destroy 삭제 보호, 테스트 통과 |
| CATM-03 | 06-02, 06-04 | Admin이 게시판 카테고리 순서를 드래그앤드롭으로 변경할 수 있다 | SATISFIED | sortable_controller.js + reorder 액션, 컨트롤러 테스트로 position 업데이트 확인 |
| CATM-04 | 06-02, 06-04 | Admin이 카테고리별 '관리자 전용 작성' 토글을 설정할 수 있다 | SATISFIED | toggle_admin_only 액션 + turbo_stream 응답, 테스트 통과 |
| CATM-05 | 06-03, 06-04 | 관리자 전용 카테고리는 일반 사용자 게시글 작성 시 선택지에서 숨겨진다 | SATISFIED | available_post_categories 헬퍼 (admin_only 필터), 라우팅 테스트로 assert_select 검증 |
| CATM-06 | 06-01, 06-02, 06-04 | Admin이 스킬팩 카테고리를 CRUD + 순서 변경할 수 있다 | SATISFIED | Category record_type=skill_pack 동일 컨트롤러로 처리, 스킬팩 카테고리 테스트 통과 |

### Anti-Patterns Found

| File | Pattern | Severity | Impact |
|------|---------|----------|--------|
| `teovibe/db/schema.rb` | schema.rb가 마이그레이션 실행 이전 버전(2026_02_18_063734)으로 stale 상태 | Warning | schema.rb 읽는 사람은 categories 테이블이 없고 enum 컬럼이 살아있다고 오해할 수 있음. `bin/rails db:schema:dump` 실행 필요 |

Anti-pattern 없음 (코드 품질 측면):
- TODO/FIXME/placeholder 코멘트 없음
- 빈 구현(empty handler) 없음
- 기존 6개 개별 컨트롤러(blogs, tutorials, free_boards, qnas, portfolios, notices) 모두 삭제됨 확인

### Human Verification Required

#### 1. Admin 카테고리 관리 UI 렌더링 확인

**Test:** Admin 계정으로 로그인 후 `/admin/categories` 접속
**Expected:** 게시판 카테고리 6개 + 스킬팩 카테고리 4개가 각각 테이블에 표시되고, 각 행에 드래그 핸들(≡ 아이콘), 관리자전용/Navbar노출 토글 버튼, 편집/삭제 버튼이 표시됨
**Why human:** 브라우저 렌더링 결과는 grep으로 검증 불가

#### 2. Sortable.js 드래그앤드롭 동작 확인

**Test:** Admin 카테고리 목록에서 드래그 핸들을 잡고 카테고리를 위/아래로 드래그
**Expected:** 드래그 완료(onEnd) 시 `PATCH /admin/categories/reorder` 요청이 전송되고, 페이지 새로고침 시 새 순서가 유지됨
**Why human:** Sortable.js의 DOM 이벤트 처리 및 fetch 호출은 실제 브라우저에서만 확인 가능

#### 3. Turbo Stream 인라인 토글 확인

**Test:** Admin 카테고리 관리 페이지에서 '관리자 전용' 토글 버튼 클릭
**Expected:** 페이지 전체 리로드 없이 버튼 텍스트(ON/OFF)와 스타일만 인라인으로 교체됨
**Why human:** Turbo Stream 렌더링 동작은 실시간 브라우저 동작

#### 4. admin_only 카테고리 필터 시각 확인

**Test:** 일반 사용자로 로그인 후 `/posts/new` 접속하여 카테고리 드롭다운 확인
**Expected:** '공지사항(notice)' 카테고리가 드롭다운 옵션에 표시되지 않고, '블로그', '튜토리얼' 등 일반 카테고리만 표시됨
**Why human:** 자동 테스트(assert_select)로 이미 검증됨. 시각적 최종 확인 권장

#### 5. SEO 리다이렉트 최종 확인

**Test:** 브라우저에서 `/blogs` 접속
**Expected:** `/posts/blog`로 리다이렉트되어 블로그 카테고리 게시글 목록 페이지가 표시됨
**Why human:** 라우팅 테스트로 이미 301 검증됨. 브라우저 주소창 변경 및 UI 렌더링 최종 확인 권장

### Schema.rb 주의사항

`teovibe/db/schema.rb`가 마지막 마이그레이션(20260228124813) 이후 재생성되지 않아 실제 DB 상태와 불일치합니다.

- schema.rb 버전: `2026_02_18_063734` (실제: 20260228124813 까지 up)
- schema.rb 상태: `categories` 테이블 없음, `posts.category` enum 컬럼 존재, `skill_packs.category` enum 컬럼 존재
- 실제 DB 상태: `categories` 테이블 존재 (10개 레코드), `posts.category_id` FK 컬럼 존재, `skill_packs.category_id` FK 컬럼 존재

`bin/rails db:schema:dump`를 실행하여 schema.rb를 최신 상태로 갱신하는 것을 권장합니다.

---

## Summary

Phase 6 카테고리 동적 관리의 모든 요구사항(CATM-01~06)이 구현되었으며 자동 테스트(총 38개 테스트)가 전체 통과합니다.

- Category 모델: scopes, 삭제 보호, move_up/move_down 완전 구현
- Admin CRUD UI: 11개 액션, Turbo Frame/Stream 인라인 토글, routes 완전 등록
- Sortable.js DnD: sortable_controller.js + reorder 엔드포인트 연결
- PostsController 통합: 6개 컨트롤러 삭제, 301 리다이렉트, category_slug 기반 라우팅
- 동적 Navbar/Footer: visible_in_nav 카테고리 루프
- admin_only 필터: available_post_categories 헬퍼로 분기 처리

코드 구현 품질은 높으며, 남은 항목은 브라우저 상호작용(DnD, Turbo Stream) 시각 확인뿐입니다.

---

_Verified: 2026-02-28T15:59:00Z_
_Verifier: Claude (gsd-verifier)_
