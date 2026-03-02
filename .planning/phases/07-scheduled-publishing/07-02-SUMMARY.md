---
phase: 07-scheduled-publishing
plan: "02"
subsystem: admin-ui
tags: [tdd, rails, active-job, solid-queue, admin-controller, form]
dependency_graph:
  requires:
    - phase: 07-01
      provides: "Post#scheduled?, Post.scheduled scope, PublishPostJob, scheduled_at/job_id 컬럼"
  provides:
    - Admin::PostsController#handle_scheduling (KST→UTC 변환 + 예약 처리)
    - Admin::PostsController#enqueue_publish_job (SolidQueue PublishPostJob 등록)
    - Admin::PostsController#cancel_existing_job (기존 잡 취소)
    - Admin 게시글 폼 datetime-local 예약 발행 시각 입력 필드 (KST)
    - Admin 게시글 목록 예약됨 배지 + 예정 시각 표시
  affects:
    - 07-03 (예약 발행 Scheduler/SolidQueue 연동 확인)
tech-stack:
  added: []
  patterns:
    - TDD (Red-Green-Refactor)
    - ActiveSupport::TimeZone["Seoul"].parse() - KST 파싱 패턴
    - assign_attributes + save 패턴 (update 대신 - handle_scheduling 선행 할당용)
    - SolidQueue::Job.find_by(id:)&.destroy - 잡 취소 패턴

key-files:
  created:
    - teovibe/test/controllers/admin/posts_controller_scheduling_test.rb
  modified:
    - teovibe/app/controllers/admin/posts_controller.rb
    - teovibe/app/views/admin/posts/_form.html.erb
    - teovibe/app/views/admin/posts/index.html.erb

key-decisions:
  - "set_post에서 Post.find 대신 Post.find_by!(slug:) 사용 — to_param이 slug를 반환하므로 Admin 라우트 :id가 slug 값임"
  - "update에서 @post.update(post_params) 대신 assign_attributes + save 분리 — handle_scheduling이 scheduled_at을 직접 세팅하므로"
  - "scheduled_at은 post_params에서 제외 — handle_scheduling에서 TimeZone 변환 후 직접 할당 (raw params 접근)"

requirements-completed: [SCHD-01, SCHD-03]

duration: 15min
completed: 2026-03-02
---

# Phase 07 Plan 02: Admin 예약 발행 컨트롤러 + UI Summary

**Admin::PostsController에 KST→UTC 예약 처리 메서드(handle_scheduling/enqueue_publish_job/cancel_existing_job) 추가 + 폼 datetime-local 필드 + 목록 예약됨 배지 TDD 구현**

## Performance

- **Duration:** 15 min
- **Started:** 2026-03-02T13:27:38Z
- **Completed:** 2026-03-02T13:42:00Z
- **Tasks:** 2
- **Files modified:** 4

## Accomplishments

- Admin 게시글 폼에 예약 발행 시각 (KST) datetime-local 입력 필드 추가
- 컨트롤러에서 KST→UTC 변환 처리, SolidQueue에 PublishPostJob 등록 및 취소 로직 구현
- 게시글 목록에 예약됨 배지 (노란색) + 예정 시각 표시
- 전체 테스트 62건 통과 유지

## Task Commits

각 태스크는 원자 커밋으로 처리:

1. **Task 1: Admin::PostsController 예약 발행 로직 TDD 구현** - `ae853a3` (feat)
2. **Task 2: 폼 datetime-local 필드 + 목록 예약됨 배지 추가** - `2c8652e` (feat)

## Files Created/Modified

- `teovibe/test/controllers/admin/posts_controller_scheduling_test.rb` - 예약 컨트롤러 TDD 테스트 4개 (생성/즉시발행/시각변경/예약취소)
- `teovibe/app/controllers/admin/posts_controller.rb` - handle_scheduling, enqueue_publish_job, cancel_existing_job 메서드 추가 + create/update 수정
- `teovibe/app/views/admin/posts/_form.html.erb` - datetime-local 예약 발행 시각 입력 필드 추가 (상태 select 아래)
- `teovibe/app/views/admin/posts/index.html.erb` - 상태 컬럼 3분기 (scheduled? / published? / draft) 처리

## Decisions Made

- `set_post`에서 `Post.find(params[:id])` 대신 `Post.find_by!(slug: params[:id])` 사용. Post의 `to_param`이 slug를 반환하므로 Admin 경로에서 `:id`는 실제 slug 값이 됨. 기존 동작 버그 수정 (Rule 1).
- `update` 액션에서 `@post.update(post_params)` → `assign_attributes(post_params) + handle_scheduling + save`로 변경. `handle_scheduling`이 `scheduled_at`을 직접 할당하므로 분리 필요.
- `scheduled_at`은 `post_params`에서 제외하고 `params.dig(:post, :scheduled_at)`으로 raw 접근하여 TimeZone 변환 처리.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] set_post에서 slug 기반 조회로 수정**
- **Found during:** Task 1 (컨트롤러 테스트 RED 단계)
- **Issue:** `Post#to_param`이 slug를 반환하므로 `admin_post_path(post)`가 slug URL 생성. 그러나 `set_post`는 `Post.find(params[:id])`로 PK 조회. 결과: update/destroy 요청이 404 반환
- **Fix:** `Post.find_by!(slug: params[:id])`로 변경
- **Files modified:** `teovibe/app/controllers/admin/posts_controller.rb`
- **Verification:** update/destroy 테스트 통과 확인
- **Committed in:** ae853a3 (Task 1 커밋)

---

**Total deviations:** 1 auto-fixed (Rule 1 - Bug)
**Impact on plan:** set_post 버그 수정은 기존 show/edit/destroy 액션 정상 동작에 필수. 범위 이탈 없음.

## Issues Encountered

- 초기 테스트에서 Post 생성 시 category 필수 검증 실패 — 테스트에 `category_id: @blog_category.id` 및 픽스처 `@blog_category = categories(:blog)` 추가로 해결

## User Setup Required

None - 외부 서비스 설정 불필요.

## Next Phase Readiness

- Admin UI에서 예약 발행 입력/저장/취소 완전 동작
- SolidQueue에 PublishPostJob이 예약 시각으로 등록됨
- 07-03: SolidQueue Worker 설정 및 예약 발행 end-to-end 검증 단계

---
*Phase: 07-scheduled-publishing*
*Completed: 2026-03-02*

## Self-Check: PASSED

- [x] `teovibe/test/controllers/admin/posts_controller_scheduling_test.rb` — 존재
- [x] `teovibe/app/controllers/admin/posts_controller.rb` — handle_scheduling, enqueue_publish_job, cancel_existing_job 포함
- [x] `teovibe/app/views/admin/posts/_form.html.erb` — datetime-local 포함
- [x] `teovibe/app/views/admin/posts/index.html.erb` — scheduled? 분기 포함
- [x] commit ae853a3 — 존재
- [x] commit 2c8652e — 존재
- [x] 전체 테스트 62건 통과
