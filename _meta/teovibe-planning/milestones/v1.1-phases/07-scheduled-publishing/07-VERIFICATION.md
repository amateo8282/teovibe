---
phase: 07-scheduled-publishing
verified: 2026-03-05T00:00:00Z
status: passed
score: 12/12 must-haves verified
re_verification: false
human_verification:
  - test: "Admin 폼에서 예약 시각 입력 후 저장 시 UI 동작 확인"
    expected: "datetime-local 필드에 KST 시각이 표시되고, 저장 후 목록에서 노란색 '예약됨' 배지와 예정 시각이 보인다"
    why_human: "UI 렌더링 및 폼 입력 흐름은 자동화 테스트로 커버되지 않음 (브라우저 시각 확인 필요)"
  - test: "SolidQueue Worker가 프로덕션에서 예약 시각에 실제 발행하는지 확인"
    expected: "예약된 시각이 되면 게시글이 자동으로 published 상태로 전환되어 공개 피드에 노출된다"
    why_human: "테스트 환경에서는 :test 큐 어댑터 사용 — SolidQueue Worker 실제 동작은 프로덕션에서만 확인 가능"
---

# Phase 7: Admin 게시글 예약 발행 Verification Report

**Phase Goal:** Admin 게시글 예약 발행 기능 완성 - 관리자가 게시글 발행 시각을 예약하고 자동 발행되는 시스템 구현
**Verified:** 2026-03-05
**Status:** PASSED (human verification items noted)
**Re-verification:** No — initial verification

## Goal Achievement

### Observable Truths

| #  | Truth | Status | Evidence |
|----|-------|--------|----------|
| 1  | Post 모델에 scheduled_at(datetime)과 job_id(string) 컬럼이 존재한다 | VERIFIED | `db/structure.sql` 라인 109에 `scheduled_at datetime(6)`, `job_id varchar` 컬럼 확인. 마이그레이션 `20260302132108_add_scheduling_to_posts.rb` 존재, `db:migrate:status` 결과 `up` 확인 |
| 2  | post.scheduled?는 draft 상태이면서 scheduled_at이 있을 때 true를 반환한다 | VERIFIED | `post.rb` 라인 23-25에 `def scheduled?; draft? && scheduled_at.present?; end` 구현. `post_test.rb`에서 3가지 조합 테스트 8개 중 4개가 이 동작을 검증하며 전체 통과 |
| 3  | PublishPostJob이 실행되면 draft+scheduled 게시글이 published로 전환된다 | VERIFIED | `publish_post_job.rb`에 guard 패턴 구현. `publish_post_job_test.rb` 4개 테스트 모두 통과 (`8 runs, 17 assertions, 0 failures`) |
| 4  | PublishPostJob은 이미 published되었거나 예약 취소된 게시글을 건드리지 않는다 | VERIFIED | `return unless post&.scheduled?` guard 확인. 테스트 Test 2(published guard), Test 3(nil scheduled_at guard), Test 4(존재하지 않는 ID guard) 모두 통과 |
| 5  | Admin 게시글 폼에 datetime-local 필드로 예약 발행 시각(KST)을 입력할 수 있다 | VERIFIED | `_form.html.erb` 라인 29-33에 `type: "datetime-local"` 필드 존재. KST 표시를 위해 `in_time_zone("Seoul").strftime("%Y-%m-%dT%H:%M")` 사용 |
| 6  | 폼에서 입력한 KST 시각이 UTC로 변환되어 scheduled_at에 저장된다 | VERIFIED | `handle_scheduling` 메서드에서 `ActiveSupport::TimeZone["Seoul"].parse(raw).utc` 변환. 통합 테스트에서 KST 14:00 → UTC 05:00, KST 09:00 → UTC 00:00 검증 |
| 7  | 예약 시각 지정 시 SolidQueue에 PublishPostJob이 등록되고 job_id가 Post에 저장된다 | VERIFIED (부분) | `enqueue_publish_job`에서 `PublishPostJob.set(wait_until:).perform_later` 호출 후 `update_column(:job_id, job.provider_job_id)` 저장 구현 확인. 단, 테스트 환경에서 `:test` 어댑터는 `provider_job_id` nil 반환 — 프로덕션(SolidQueue)에서만 완전 검증 가능 |
| 8  | Admin이 예약 시각을 변경하면 기존 잡이 취소되고 새 잡이 등록된다 | VERIFIED | `update` 액션에서 `cancel_existing_job` → `handle_scheduling` → `enqueue_publish_job` 순서 구현. 컨트롤러 테스트 Test 4(시각 변경)와 통합 테스트 Test 4 통과 |
| 9  | Admin이 예약을 취소(scheduled_at 비우기)하면 기존 잡이 삭제된다 | VERIFIED | `handle_scheduling`에서 `raw.blank?`이면 `post.scheduled_at = nil` 처리. `cancel_existing_job`에서 `SolidQueue::Job.find_by(id: post.job_id)&.destroy` 구현. 컨트롤러 테스트 Test 4(예약 취소)와 통합 테스트 Test 5 통과 |
| 10 | Admin 게시글 목록에 예약된 게시글은 '예약됨' 배지와 예정 시각이 표시된다 | VERIFIED | `index.html.erb` 라인 25-34에 `post.scheduled?` 분기로 노란색 텍스트 '예약됨' 배지 + KST 변환 예정 시각 표시 구현 |
| 11 | scheduled 게시글은 Post.published scope에 포함되지 않는다 (공개 피드 미노출) | VERIFIED | `Post.published`는 `where(status: :published)`만 조회. scheduled 게시글은 `status: :draft`이므로 자동 제외. 통합 테스트 Test 7에서 `assert_not_includes Post.published, scheduled_post` 검증 통과 |
| 12 | 기존 게시글 CRUD 동작이 영향받지 않는다 | VERIFIED | 전체 테스트 스위트 `69 runs, 246 assertions, 0 failures, 1 errors`에서 1 errors는 Phase 7 이전부터 존재하는 pre-existing bug(`category_routing_test.rb`의 `url_for_post` 헬퍼 버그, SUMMARY에 명시) |

**Score:** 12/12 truths verified

### Required Artifacts

| Artifact | Expected | Status | Details |
|----------|----------|--------|---------|
| `teovibe/db/migrate/20260302132108_add_scheduling_to_posts.rb` | scheduled_at, job_id 컬럼 추가 마이그레이션 | VERIFIED | `add_column :posts, :scheduled_at` + `add_column :posts, :job_id` + 인덱스 포함, `db:migrate:status` 결과 `up` |
| `teovibe/app/models/post.rb` | scheduled? 헬퍼 및 scheduled scope | VERIFIED | 라인 18에 `scope :scheduled` + 라인 23-25에 `def scheduled?` 구현 |
| `teovibe/app/jobs/publish_post_job.rb` | 예약 발행 잡 | VERIFIED | `class PublishPostJob` with guard, `discard_on`, `post.update!` 구현 |
| `teovibe/test/jobs/publish_post_job_test.rb` | 잡 단위 테스트 | VERIFIED | 4개 테스트 케이스 모두 통과 |
| `teovibe/test/controllers/admin/posts_controller_scheduling_test.rb` | 예약 컨트롤러 TDD 테스트 | VERIFIED | 4개 테스트 케이스 (`11 runs` 중 4개 포함) 모두 통과 |
| `teovibe/app/controllers/admin/posts_controller.rb` | 예약 처리 로직 | VERIFIED | `handle_scheduling`, `enqueue_publish_job`, `cancel_existing_job` 3개 메서드 모두 구현 |
| `teovibe/app/views/admin/posts/_form.html.erb` | datetime-local 입력 필드 | VERIFIED | 라인 29-33에 `type: "datetime-local"` 필드, KST 값 변환, min 속성, 힌트 텍스트 포함 |
| `teovibe/app/views/admin/posts/index.html.erb` | 예약됨 배지 및 예정 시각 표시 | VERIFIED | 라인 25-34에 `post.scheduled?` 분기, 노란색 배지, KST 시각 표시 |
| `teovibe/test/controllers/admin/posts_controller_test.rb` | 예약 생성/수정/취소 통합 테스트 | VERIFIED | 7개 통합 테스트 모두 통과 (SCHD-01~03 + 공개 피드 scope) |

### Key Link Verification

| From | To | Via | Status | Details |
|------|----|-----|--------|---------|
| `publish_post_job.rb` | `post.rb` | `post&.scheduled?` guard + `post.update!` | VERIFIED | 라인 9: `return unless post&.scheduled?`, 라인 11: `post.update!(status: :published, scheduled_at: nil, job_id: nil)` |
| `admin/posts_controller.rb` | `publish_post_job.rb` | `PublishPostJob.set(wait_until:).perform_later` | VERIFIED | 라인 82: `PublishPostJob.set(wait_until: post.scheduled_at).perform_later(post.id)` |
| `admin/posts_controller.rb` | `SolidQueue::Job` | `SolidQueue::Job.find_by(id:).destroy` | VERIFIED | 라인 90: `SolidQueue::Job.find_by(id: post.job_id)&.destroy` |
| `_form.html.erb` | `admin/posts_controller.rb` | `scheduled_at` 파라미터 → `handle_scheduling` KST→UTC | VERIFIED | 폼 라인 29: `f.text_field :scheduled_at`로 제출, 컨트롤러 라인 65: `params.dig(:post, :scheduled_at)`으로 수신 후 변환 |
| `posts_controller_test.rb` | `admin/posts_controller.rb` | `post admin_posts_path` | VERIFIED | 7개 통합 테스트에서 `post admin_posts_path`, `patch admin_post_path` 호출 |

### Requirements Coverage

| Requirement | Source Plan | Description | Status | Evidence |
|-------------|-------------|-------------|--------|----------|
| SCHD-01 | 07-01, 07-02, 07-03 | Admin이 게시글 저장 시 발행 날짜/시간을 지정할 수 있다 | SATISFIED | datetime-local 폼 필드 존재, KST→UTC 변환 로직 구현, 컨트롤러 테스트 + 통합 테스트 Test 1, 6 통과 |
| SCHD-02 | 07-01, 07-03 | 지정된 시간에 게시글이 자동으로 published 상태로 전환된다 | SATISFIED | `PublishPostJob` 구현 + `SolidQueue`에 `wait_until`로 등록, 단위 테스트 4개 + 통합 테스트 Test 3 통과 |
| SCHD-03 | 07-02, 07-03 | Admin이 예약된 게시글의 예약을 취소하거나 시간을 변경할 수 있다 | SATISFIED | `cancel_existing_job` + `handle_scheduling` 구현, 컨트롤러 테스트 + 통합 테스트 Test 4, 5 통과 |

모든 3개 요구사항(SCHD-01, SCHD-02, SCHD-03)이 REQUIREMENTS.md에서 `[x]` 완료 표시되어 있으며 자동 테스트로 검증됨.

### Anti-Patterns Found

| File | Line | Pattern | Severity | Impact |
|------|------|---------|----------|--------|
| `db/schema.rb` | - | `scheduled_at`, `job_id` 컬럼 미포함 | Info | 이 프로젝트는 `config.active_record.schema_format = :sql` 설정으로 `structure.sql`을 primary schema로 사용. `schema.rb`는 보조 파일로 최신화되지 않음. `structure.sql`에 컬럼이 정상 존재하며 실제 DB에 마이그레이션 적용 완료 |
| `test/integration/category_routing_test.rb` | 53 | 기존 pre-existing 1 error | Info | Phase 7 이전부터 존재하는 `url_for_post` 헬퍼 버그. Phase 7 코드와 무관 (07-03 SUMMARY에 명시적으로 기록됨) |

### Human Verification Required

#### 1. Admin 폼 UI 동작 확인

**Test:** Admin 계정으로 로그인 후 새 게시글 작성 페이지(`/admin/posts/new`)에서 "예약 발행 시각 (KST)" datetime-local 필드에 미래 시각을 입력 후 저장
**Expected:** 폼이 정상 제출되고, 게시글 목록에서 노란색 "예약됨" 배지와 KST 예정 시각이 표시됨
**Why human:** UI 렌더링 및 폼 입력 플로우는 자동화 테스트로 커버되지 않음 (브라우저 시각적 확인 필요)

#### 2. SolidQueue Worker 프로덕션 실제 동작 확인

**Test:** 프로덕션 환경에서 미래 시각으로 게시글을 예약하고, 해당 시각이 지난 후 게시글 상태 확인
**Expected:** 예약 시각이 되면 게시글이 자동으로 `published` 상태로 전환되어 공개 피드에 노출됨
**Why human:** 테스트 환경은 `:test` 큐 어댑터를 사용하여 비동기 잡이 실제로 큐에 등록되지 않음. `provider_job_id`도 nil 반환. SolidQueue Worker의 실제 스케줄링 동작은 프로덕션에서만 확인 가능

### Gaps Summary

자동화 검증에서 갭 없음. 12개 must-have truth 모두 VERIFIED.

주목할 사항:
- `schema.rb`가 업데이트되지 않았으나 이는 이 프로젝트가 `structure.sql`을 primary schema로 사용하기 때문임. 실제 DB에 컬럼이 존재하고 마이그레이션이 적용된 상태.
- SolidQueue `job_id` 저장 로직은 프로덕션에서만 완전 검증 가능 (테스트 환경의 `:test` 큐 어댑터 한계). 코드 구현은 정확하며 07-03 SUMMARY에 이 결정이 명시됨.
- `category_routing_test.rb`의 pre-existing 1 error는 Phase 7 범위 외 버그로 Phase 7에 의해 도입된 것이 아님.

---

_Verified: 2026-03-05_
_Verifier: Claude (gsd-verifier)_
