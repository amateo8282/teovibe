---
phase: 07-scheduled-publishing
plan: "01"
subsystem: backend-jobs
tags: [tdd, migration, active-job, scheduling]
dependency_graph:
  requires: []
  provides:
    - Post#scheduled? 헬퍼
    - Post.scheduled scope
    - PublishPostJob (예약 발행 잡)
    - scheduled_at/job_id 컬럼
  affects:
    - teovibe/app/models/post.rb
    - teovibe/app/jobs/publish_post_job.rb
tech_stack:
  added: []
  patterns:
    - TDD (Red-Green-Refactor)
    - ActiveJob with guard pattern
    - ActiveRecord scope + helper method
key_files:
  created:
    - teovibe/db/migrate/20260302132108_add_scheduling_to_posts.rb
    - teovibe/app/jobs/publish_post_job.rb
    - teovibe/test/models/post_test.rb
    - teovibe/test/jobs/publish_post_job_test.rb
  modified:
    - teovibe/app/models/post.rb
decisions:
  - "Post 상태는 draft/published 2개 유지 — scheduled는 별도 컬럼(scheduled_at)으로 표현 (Research 안티패턴 회피)"
  - "PublishPostJob guard: post&.scheduled? 로 nil 체크 + 예약 상태 이중 확인"
  - "discard_on DeserializationError 포함 — 예약 발행은 1회성으로 재시도 불필요"
  - "scheduled_at 컬럼에 인덱스 추가 — 예약 게시글 조회 성능"
metrics:
  duration: "10 minutes"
  completed: "2026-03-02"
  tasks_completed: 2
  tasks_total: 2
  files_created: 4
  files_modified: 1
---

# Phase 07 Plan 01: 예약 발행 인프라 (마이그레이션 + PublishPostJob) Summary

**One-liner:** scheduled_at/job_id 컬럼 마이그레이션 + Post#scheduled? 헬퍼 + PublishPostJob guard 패턴으로 TDD 구현

## Tasks Completed

| Task | Name | Commit | Files |
|------|------|--------|-------|
| 1 | 마이그레이션 + Post 모델 scheduled? 헬퍼 추가 | f54e7e5 | migration, post.rb, post_test.rb |
| 2 | PublishPostJob TDD 구현 | da7c290 | publish_post_job.rb, publish_post_job_test.rb |

## What Was Built

### Task 1: 마이그레이션 + Post 모델

**마이그레이션 (`20260302132108_add_scheduling_to_posts.rb`):**
- `scheduled_at` datetime 컬럼 추가 (예약 발행 시각)
- `job_id` string 컬럼 추가 (ActiveJob provider_job_id 저장용)
- `scheduled_at` 인덱스 추가 (예약 게시글 조회 성능)

**Post 모델 (`app/models/post.rb`):**
```ruby
scope :scheduled, -> { where(status: :draft).where.not(scheduled_at: nil) }

def scheduled?
  draft? && scheduled_at.present?
end
```

**테스트 (`test/models/post_test.rb`):**
- draft + scheduled_at 있음 → scheduled? = true
- draft + scheduled_at nil → scheduled? = false
- published + scheduled_at 있음 → scheduled? = false
- Post.scheduled scope 정확도 검증

### Task 2: PublishPostJob

**잡 구현 (`app/jobs/publish_post_job.rb`):**
```ruby
class PublishPostJob < ApplicationJob
  queue_as :default
  discard_on ActiveJob::DeserializationError

  def perform(post_id)
    post = Post.find_by(id: post_id)
    return unless post&.scheduled?
    post.update!(status: :published, scheduled_at: nil, job_id: nil)
  end
end
```

**테스트 (`test/jobs/publish_post_job_test.rb`):**
- 정상 예약 발행: published로 전환 + scheduled_at/job_id nil 초기화
- published 게시글 guard: 아무 변경 없음
- scheduled_at nil draft 게시글 guard: 아무 변경 없음
- 존재하지 않는 post_id guard: 에러 없이 무시

## Verification

```
bin/rails db:migrate:status | grep "add_scheduling_to_posts"
  up     20260302132108  Add scheduling to posts

bin/rails test test/models/post_test.rb test/jobs/publish_post_job_test.rb -v
  8 runs, 17 assertions, 0 failures, 0 errors, 0 skips

bin/rails test
  58 runs, 185 assertions, 0 failures, 0 errors, 0 skips
```

## Deviations from Plan

### Auto-fixed Issues

None - plan executed exactly as written.

**참고:** 스키마 인터페이스 문서에 `category` integer 컬럼으로 표시되어 있었으나 실제 DB는 이미 Phase 6에서 `category_id` FK로 마이그레이션 완료된 상태였음. 코드 동작에는 영향 없음 (Post 픽스처가 category 레이블로 정확히 참조).

## Self-Check: PASSED

- [x] `teovibe/db/migrate/20260302132108_add_scheduling_to_posts.rb` — 존재
- [x] `teovibe/app/models/post.rb` — scheduled? 헬퍼 + scheduled scope 포함
- [x] `teovibe/app/jobs/publish_post_job.rb` — 존재
- [x] `teovibe/test/models/post_test.rb` — 존재
- [x] `teovibe/test/jobs/publish_post_job_test.rb` — 존재
- [x] commit f54e7e5 — 존재
- [x] commit da7c290 — 존재
- [x] 전체 테스트 58건 통과
