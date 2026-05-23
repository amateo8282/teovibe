---
phase: 06-category-management
plan: 03
subsystem: routing
tags: [rails, routing, controller, navbar, category, redirect]

# Dependency graph
requires:
  - phase: 06-01
    provides: Category 모델 + slug/record_type/admin_only/visible_in_nav 컬럼

provides:
  - 통합 PostsController (category_slug 기반 index, slug 기반 CRUD)
  - 6개 URL(blogs/tutorials/free-boards/qnas/portfolios/notices) → /posts/:category_slug 301 리다이렉트
  - 동적 Navbar/Footer (visible_in_nav=true 카테고리 루프)
  - available_post_categories 헬퍼 (admin_only 필터)
  - Post#to_param → slug 기반 라우팅
  - CommentController#accept (QnA 답변 채택, qnas nested routes 제거 후 이관)

affects: [06-04, 07, 08]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "category_slug 기반 /posts/:category_slug 목록 라우팅"
    - "Post#to_param 오버라이드로 slug 기반 URL 자동 생성"
    - "resources :posts, param: :slug 단일 param 라우팅"

key-files:
  created: []
  modified:
    - teovibe/app/controllers/posts_controller.rb
    - teovibe/config/routes.rb
    - teovibe/app/helpers/application_helper.rb
    - teovibe/app/models/post.rb
    - teovibe/app/controllers/comments_controller.rb
    - teovibe/app/controllers/likes_controller.rb
    - teovibe/app/views/posts/index.html.erb
    - teovibe/app/views/posts/show.html.erb
    - teovibe/app/views/posts/_form.html.erb
    - teovibe/app/views/shared/_navbar.html.erb
    - teovibe/app/views/shared/_footer.html.erb
    - teovibe/app/views/comments/_comment.html.erb

key-decisions:
  - "QnA accept 액션을 QnasController에서 CommentsController로 이관 (nested qnas 라우트 제거)"
  - "Post#to_param → slug 반환으로 post_path(post)가 /posts/:slug 자동 생성"
  - "/posts/:category_slug를 /posts/:slug보다 먼저 선언하여 라우트 충돌 방지"
  - "LikesController: post_id → post_slug 파라미터 변경 (resources :posts, param: :slug 에 맞춤)"

patterns-established:
  - "카테고리 목록: GET /posts/:category_slug → posts#index"
  - "게시글 CRUD: slug param 기반 (post.slug = to_param 반환값)"
  - "Navbar/Footer: Category.for_posts.visible_in_nav.ordered 루프 패턴"
  - "admin 권한별 카테고리 노출: available_post_categories 헬퍼"

requirements-completed: [CATM-05]

# Metrics
duration: 30min
completed: 2026-02-28
---

# Phase 06 Plan 03: 컨트롤러 통합 + 라우팅 리다이렉트 Summary

**6개 개별 게시판 컨트롤러를 단일 PostsController로 통합하고, 기존 URL에 301 리다이렉트를 설정하며, Navbar/Footer를 visible_in_nav 카테고리 동적 루프로 전환**

## Performance

- **Duration:** 30 min
- **Started:** 2026-02-28T00:00:00Z
- **Completed:** 2026-02-28T00:30:00Z
- **Tasks:** 2
- **Files modified:** 12

## Accomplishments

- Blogs/Tutorials/FreeBoards/Qnas/Portfolios/Notices 6개 컨트롤러 및 PostsBaseController 삭제 완료
- PostsController: `category_slug` 기반 index + `slug` 기반 CRUD 단일 컨트롤러로 통합
- 6개 기존 URL → /posts/:category_slug 형식으로 301 영구 리다이렉트 설정
- Navbar/Footer: 하드코딩 링크 제거, visible_in_nav=true 카테고리 동적 렌더링
- 일반 사용자 게시글 작성 시 admin_only=false 카테고리만 노출 (CATM-05 완료)

## Task Commits

Each task was committed atomically:

1. **Task 1: PostsController 통합 + 라우팅 리다이렉트 설정** - `25a2aa2` (feat)
2. **Task 2: Navbar 동적 카테고리 + 게시글 작성 폼 admin_only 필터** - `a7af0ac` (feat)

## Files Created/Modified

- `teovibe/app/controllers/posts_controller.rb` - category_slug 기반 통합 PostsController
- `teovibe/config/routes.rb` - SEO 리다이렉트 + category_posts + resources :posts, param: :slug
- `teovibe/app/helpers/application_helper.rb` - available_post_categories 헬퍼 (admin_only 필터)
- `teovibe/app/models/post.rb` - to_param → slug 반환, qna? 메서드 추가
- `teovibe/app/controllers/comments_controller.rb` - accept 액션 이관 (QnA 답변 채택)
- `teovibe/app/controllers/likes_controller.rb` - post_slug 파라미터로 변경
- `teovibe/app/views/posts/index.html.erb` - 하드코딩 라우트 제거, new_post_path 사용
- `teovibe/app/views/posts/show.html.erb` - category_posts_path, post_path 사용
- `teovibe/app/views/posts/_form.html.erb` - 카테고리 선택 드롭다운 추가
- `teovibe/app/views/shared/_navbar.html.erb` - visible_in_nav 카테고리 동적 루프
- `teovibe/app/views/shared/_footer.html.erb` - visible_in_nav 카테고리 동적 루프
- `teovibe/app/views/comments/_comment.html.erb` - accept_comment_path로 변경

**삭제된 파일:**
- `teovibe/app/controllers/blogs_controller.rb`
- `teovibe/app/controllers/tutorials_controller.rb`
- `teovibe/app/controllers/free_boards_controller.rb`
- `teovibe/app/controllers/qnas_controller.rb`
- `teovibe/app/controllers/portfolios_controller.rb`
- `teovibe/app/controllers/notices_controller.rb`
- `teovibe/app/controllers/posts_base_controller.rb`

## Decisions Made

- **QnA accept 이관**: QnasController의 accept 액션을 CommentsController로 이관. QnA 전용 nested routes (`qnas/:qna_id/comments/:id/accept`) 제거하고 `comments/:id/accept` 단일 경로로 통합
- **Post#to_param**: `resources :posts, param: :slug` 사용 시 `post_path(post)` 헬퍼가 자동으로 slug를 사용하도록 Post#to_param 오버라이드
- **라우트 순서**: `/posts/:category_slug`를 `resources :posts, param: :slug` 앞에 선언하여 `posts/new` URL 충돌 방지 (`:category_slug` 패턴보다 named route가 먼저 매칭됨)
- **LikesController**: `param: :slug` 변경으로 인해 `params[:post_id]` → `params[:post_slug]`로 변경, `Post.find_by!(slug:)` 사용

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] QnA accept 라우트/컨트롤러 재구성**
- **Found during:** Task 1 (컨트롤러 삭제 시)
- **Issue:** QnasController의 accept 액션이 `qnas/:qna_id/comments/:id/accept` 라우트 의존. QnasController 삭제 시 accept 기능 소실
- **Fix:** accept 액션을 CommentsController로 이관, routes.rb에 `member { patch :accept }` 추가, `accept_comment_path` 사용
- **Files modified:** comments_controller.rb, config/routes.rb, comments/_comment.html.erb
- **Verification:** bin/rails routes에서 accept_comment PATCH /comments/:id/accept 확인
- **Committed in:** 25a2aa2 (Task 1)

**2. [Rule 1 - Bug] Post#to_param 추가**
- **Found during:** Task 1 (라우팅 설정 시)
- **Issue:** `resources :posts, param: :slug` 설정 후 `post_path(post)` 호출 시 기본 `to_param`이 `id`를 반환하여 URL 불일치
- **Fix:** Post 모델에 `def to_param; slug; end` 추가
- **Files modified:** app/models/post.rb
- **Verification:** bin/rails runner 'Post.first&.to_param' → slug 값 반환
- **Committed in:** 25a2aa2 (Task 1)

**3. [Rule 1 - Bug] LikesController post_slug 파라미터 수정**
- **Found during:** Task 1 (라우트 분석 시)
- **Issue:** `resources :posts, param: :slug`로 변경 시 like 라우트가 `post_slug` 파라미터를 생성하나, LikesController가 `params[:post_id]`를 사용하여 Post를 찾을 수 없음
- **Fix:** `params[:post_slug]`로 변경, `Post.find_by!(slug:)` 사용
- **Files modified:** app/controllers/likes_controller.rb
- **Committed in:** 25a2aa2 (Task 1)

**4. [Rule 1 - Bug] Post#qna? 메서드 추가**
- **Found during:** Task 2 (comments 뷰 분석 시)
- **Issue:** `comments/_comment.html.erb`에서 `comment.post.qna?` 호출하나 Post 모델에 해당 메서드 없음
- **Fix:** `def qna?; category&.slug == "qna"; end` Post 모델에 추가
- **Files modified:** app/models/post.rb
- **Committed in:** 25a2aa2 (Task 1)

**5. [Rule 1 - Bug] Footer 동적 카테고리 전환**
- **Found during:** Task 2 (Navbar 작업 시)
- **Issue:** Footer에도 하드코딩된 blogs_path, tutorials_path 등 구 라우트 참조 존재
- **Fix:** Footer도 visible_in_nav 카테고리 동적 루프로 전환
- **Files modified:** app/views/shared/_footer.html.erb
- **Committed in:** a7af0ac (Task 2)

---

**Total deviations:** 5 auto-fixed (Rule 1 - 모두 정확성 버그 수정)
**Impact on plan:** 모든 수정이 라우팅 통합으로 인한 필수 연쇄 변경. 범위 이탈 없음.

## Issues Encountered

None - 계획 외 발견 사항은 모두 자동 수정 규칙으로 처리됨.

## User Setup Required

None - 외부 서비스 설정 불필요.

## Next Phase Readiness

- 통합 PostsController 완성, 모든 게시판 CRUD 동작 준비 완료
- Navbar 동적 카테고리 기반으로 전환 완료
- 06-04 (Admin 카테고리 관리 UI) 진행 가능

---
*Phase: 06-category-management*
*Completed: 2026-02-28*
