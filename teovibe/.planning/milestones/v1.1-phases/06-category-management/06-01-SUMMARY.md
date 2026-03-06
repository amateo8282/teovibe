---
phase: 06-category-management
plan: 01
subsystem: database
tags: [rails, activerecord, migration, category, enum-to-fk, sqlite]

requires: []

provides:
  - Category 모델 (record_type enum, scopes, 삭제 보호, move_up/move_down)
  - categories 테이블 (Post 6개 + SkillPack 4개 카테고리 시드)
  - Post/SkillPack 모델 belongs_to :category 연관관계
  - enum→FK 데이터 마이그레이션 완료

affects:
  - 06-02 (Admin 카테고리 CRUD UI)
  - 06-03 (PostsController 통합 및 라우팅)
  - 06-04 (Navbar 동적 카테고리)

tech-stack:
  added: []
  patterns:
    - "Category 단일 테이블 + record_type enum으로 post/skill_pack 구분 (LandingSection 패턴 확장)"
    - "enum→FK 마이그레이션: slug 기반 서브쿼리 매핑 (ID 가정 금지)"
    - "삭제 보호: before_destroy + throw :abort 패턴"
    - "move_up/move_down: record_type 스코프 내에서만 position 교환"

key-files:
  created:
    - teovibe/app/models/category.rb
    - teovibe/db/migrate/20260228124813_create_categories_and_migrate.rb
    - teovibe/test/models/category_test.rb
    - teovibe/test/fixtures/categories.yml
    - teovibe/test/fixtures/skill_packs.yml
  modified:
    - teovibe/app/models/post.rb
    - teovibe/app/models/skill_pack.rb
    - teovibe/app/controllers/posts_base_controller.rb
    - teovibe/app/controllers/blogs_controller.rb
    - teovibe/app/controllers/tutorials_controller.rb
    - teovibe/app/controllers/free_boards_controller.rb
    - teovibe/app/controllers/qnas_controller.rb
    - teovibe/app/controllers/portfolios_controller.rb
    - teovibe/app/controllers/notices_controller.rb
    - teovibe/app/controllers/admin/posts_controller.rb
    - teovibe/app/controllers/admin/skill_packs_controller.rb
    - teovibe/app/helpers/application_helper.rb
    - teovibe/config/sitemap.rb
    - teovibe/app/views/posts/index.html.erb
    - teovibe/app/views/posts/show.html.erb
    - teovibe/app/views/posts/_form.html.erb
    - teovibe/app/views/admin/posts/_form.html.erb
    - teovibe/app/views/admin/skill_packs/_form.html.erb
    - teovibe/app/views/skill_packs/index.html.erb

key-decisions:
  - "category_record 메서드 패턴: PostsBaseController 서브클래스가 Category AR 객체를 반환 (enum 심볼 반환 방식 폐기)"
  - "slug 기반 서브쿼리 매핑 사용 (ID 기반 매핑 금지 - STATE.md 결정 이행)"
  - "기존 6개 컨트롤러 유지 (라우팅 통합은 06-03에서 수행)"

patterns-established:
  - "Category.for_posts.ordered / Category.for_skill_packs.ordered 스코프 패턴"
  - "category&.slug 기반 case 분기로 라우트 결정 (enum 문자열 비교 대체)"
  - "category_name 위임: post.category&.name 반환 (enum 해시 조회 대체)"

requirements-completed: [CATM-01, CATM-02, CATM-06]

duration: 45min
completed: 2026-02-28
---

# Phase 6 Plan 1: Category 모델 + enum→FK 마이그레이션 Summary

**SQLite slug 기반 서브쿼리로 Post 6개, SkillPack 4개 enum→FK 안전 마이그레이션 + Category 모델 with scopes/삭제보호/move_up_down**

## Performance

- **Duration:** 45 min
- **Started:** 2026-02-28T12:00:00Z
- **Completed:** 2026-02-28T12:45:00Z
- **Tasks:** 2
- **Files modified:** 23

## Accomplishments

- Category 모델 생성 (record_type enum, 4개 스코프, 삭제 보호, move_up/move_down)
- categories 테이블 + Post 카테고리 6개 + SkillPack 카테고리 4개 시드 데이터 생성
- slug 기반 서브쿼리로 enum→FK 데이터 마이그레이션 (레코드 수 불일치 시 예외 발생 검증 포함)
- Post/SkillPack 모델 enum 제거, belongs_to :category 전환
- 6개 PostsBaseController 서브클래스 category_record 메서드로 수정
- 뷰/헬퍼/사이트맵 enum 참조 제거 (Category 모델 기반으로 전환)
- Category 모델 테스트 13개 전체 통과

## Task Commits

1. **Task 1: Category 모델 + 마이그레이션 + 모델/뷰/헬퍼 수정** - `3b64d62` (feat)
2. **Task 2: Category 테스트 + 픽스처 수정** - `035bcf0` (test)

## Files Created/Modified

- `teovibe/app/models/category.rb` - Category 모델 (record_type, scopes, 삭제보호, move_up/down)
- `teovibe/db/migrate/20260228124813_create_categories_and_migrate.rb` - enum→FK 마이그레이션
- `teovibe/app/models/post.rb` - enum 제거, belongs_to :category, route_key/category_name 수정
- `teovibe/app/models/skill_pack.rb` - enum 제거, belongs_to :category, by_category scope 수정
- `teovibe/app/controllers/posts_base_controller.rb` - category_record 패턴으로 리팩터링
- `teovibe/app/helpers/application_helper.rb` - url_for_post slug 기반으로 수정
- `teovibe/config/sitemap.rb` - Category 모델 동적 루프로 변경
- `teovibe/test/models/category_test.rb` - 13개 테스트 (유효성/스코프/삭제보호/이동)
- `teovibe/test/fixtures/categories.yml` - 카테고리 픽스처
- `teovibe/test/fixtures/orders.yml` - payment_event_id 중복 버그 수정

## Decisions Made

- PostsBaseController 서브클래스가 `category_record` 메서드로 Category AR 객체를 직접 반환하도록 함 (기존 enum 심볼 반환 방식 폐기)
- 뷰에서 category.slug 기반 case 분기로 라우트 결정 (6개 컨트롤러는 06-03까지 유지)
- sitemap.rb를 Category 모델 기반 동적 루프로 전환하되 기존 SEO URL 경로 유지

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] orders 픽스처 payment_event_id 중복 값 수정**
- **Found during:** Task 2 (Category 테스트 실행 중)
- **Issue:** test/fixtures/orders.yml의 two 레코드가 one과 동일한 payment_event_id: MyString 사용 → UNIQUE constraint 오류로 모든 테스트가 픽스처 로딩 단계에서 실패
- **Fix:** payment_event_id를 고유 값(payment-event-one, payment-event-two)으로 수정
- **Files modified:** teovibe/test/fixtures/orders.yml
- **Verification:** Category 모델 테스트 13개 전체 통과 확인
- **Committed in:** 035bcf0

**2. [Rule 3 - Blocking] skill_packs 픽스처 파일 생성**
- **Found during:** Task 2 (픽스처 로딩 중)
- **Issue:** orders.yml이 skill_pack: one/two 참조하지만 skill_packs.yml 파일 없어 FK 위반 오류
- **Fix:** test/fixtures/skill_packs.yml 생성 (Category 픽스처 참조 포함)
- **Files modified:** teovibe/test/fixtures/skill_packs.yml (신규)
- **Verification:** 픽스처 로딩 성공, 테스트 통과 확인
- **Committed in:** 035bcf0

---

**Total deviations:** 2 auto-fixed (1 Bug, 1 Blocking)
**Impact on plan:** 두 수정 모두 기존 버그/누락 수정. 스코프 이탈 없음.

## Issues Encountered

- SQLite 버전 3.43.2 확인 완료 (3.35+ 지원으로 DROP COLUMN 직접 사용 가능)
- enum→FK 매핑 시 slug 기반 서브쿼리 사용으로 레코드 수 불일치 방지 확인

## Next Phase Readiness

- Category 모델 및 categories 테이블 준비 완료
- 06-02 (Admin 카테고리 CRUD UI) 즉시 시작 가능
- 기존 6개 컨트롤러(BlogsController 등) 06-03에서 PostsController로 통합 예정

---
*Phase: 06-category-management*
*Completed: 2026-02-28*
