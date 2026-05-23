# Phase 7: 게시글 예약 발행 - Research

**Researched:** 2026-03-01
**Domain:** Rails Background Jobs (SolidQueue), Datetime Form Handling, Timezone Conversion
**Confidence:** HIGH

## Summary

Phase 7는 Admin이 게시글 저장 시 미래 발행 시각을 지정하고, 해당 시각에 SolidQueue가 자동으로 `published` 상태로 전환하는 기능이다. 핵심 기술 요소는 세 가지다: (1) DB 스키마에 `scheduled_at` 컬럼 추가, (2) `PublishPostJob`을 `set(wait_until:)` 방식으로 지연 큐잉, (3) 폼에서 `datetime-local` 입력값을 KST로 해석하여 UTC로 저장하는 timezone 변환.

프로젝트는 이미 Rails 8.1 + SolidQueue + SQLite 3-DB 멀티 설정(primary/cache/queue/cable)이 완비되어 있다. Production 환경에서는 `config.active_job.queue_adapter = :solid_queue`가 이미 설정되어 있으며, `config/queue.yml`에 dispatcher와 worker가 정의되어 있다. 개발 환경에서도 SolidQueue의 queue DB(`storage/development_queue.sqlite3`)가 분리 설정되어 있다.

예약 취소/변경은 SolidQueue의 `provider_job_id`를 Post 레코드에 저장하고, `SolidQueue::Job.find(provider_job_id).destroy`로 기존 예약 잡을 제거한 뒤 새 잡을 큐잉하는 방식으로 구현한다. 이는 SolidQueue 공식 문서 및 커뮤니티 검증 패턴이다.

**Primary recommendation:** `PublishPostJob.set(wait_until: scheduled_at_utc).perform_later(post.id)`를 사용하고, Post 모델에 `scheduled_at` + `job_id` 컬럼을 추가하며, KST 입력을 `ActiveSupport::TimeZone["Seoul"].parse(params_value).utc`로 변환한다.

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|-----------------|
| SCHD-01 | Admin이 게시글 저장 시 발행 날짜/시간을 지정할 수 있다 | datetime-local 폼 필드 + KST→UTC 변환 패턴으로 구현 가능 |
| SCHD-02 | 지정된 시간에 게시글이 자동으로 published 상태로 전환된다 | SolidQueue `set(wait_until:).perform_later` + PublishPostJob으로 구현 가능 |
| SCHD-03 | Admin이 예약된 게시글의 예약을 취소하거나 시간을 변경할 수 있다 | `provider_job_id` 저장 후 `SolidQueue::Job.find().destroy` + 재큐잉으로 구현 가능 |
</phase_requirements>

## Standard Stack

### Core

| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| SolidQueue | 이미 설치 (Rails 8.1 기본) | 지연/예약 잡 실행 백엔드 | Rails 8 기본 포함, 이미 프로젝트 설정 완료 |
| ActiveJob | Rails 8.1 내장 | 잡 큐잉 인터페이스 | SolidQueue의 표준 인터페이스 |
| ActiveRecord | Rails 8.1 내장 | scheduled_at 컬럼 저장/조회 | 기존 Post 모델 확장 |

### Supporting

| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| ActiveSupport::TimeZone | Rails 내장 | KST↔UTC 변환 | 폼 입력값 처리 시 |

### Alternatives Considered

| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| SolidQueue | Sidekiq + Redis | 이미 SolidQueue 설치되어 있음. Redis 추가 인프라 불필요 |
| PublishPostJob 직접 등록 | recurring.yml 크론 폴링 | 잡 직접 등록이 더 정확하고 취소 가능. 크론 폴링은 1분 단위 오차 발생 |
| provider_job_id 추적 | DB 별도 schedule 테이블 | provider_job_id가 더 단순. SolidQueue Job 직접 참조 가능 |

**Installation:** 추가 설치 불필요. 이미 Gemfile에 `solid_queue`가 Rails 8.1과 함께 포함되어 있음.

## Architecture Patterns

### Recommended Project Structure

```
teovibe/
├── app/
│   ├── jobs/
│   │   └── publish_post_job.rb        # 예약 발행 잡
│   ├── models/
│   │   └── post.rb                    # scheduled_at, job_id 추가, scheduled? 메서드
│   └── controllers/admin/
│       └── posts_controller.rb        # 예약 파라미터 처리, 잡 큐잉/취소 로직
│   └── views/admin/posts/
│       └── _form.html.erb             # datetime-local 필드 추가
│       └── index.html.erb             # '예약됨' 배지 추가
├── db/
│   └── migrate/
│       └── YYYYMMDD_add_scheduling_to_posts.rb  # scheduled_at, job_id 컬럼
└── test/
    ├── jobs/
    │   └── publish_post_job_test.rb   # 잡 단위 테스트
    └── controllers/admin/
        └── posts_controller_test.rb   # SCHD-01~03 통합 테스트
```

### Pattern 1: SolidQueue 지연 잡 큐잉

**What:** `set(wait_until:)` 으로 미래 시각에 잡 등록
**When to use:** 게시글 생성/수정 시 `scheduled_at`이 현재 시각보다 미래인 경우

```ruby
# Source: https://context7.com/rails/solid_queue/llms.txt

# PublishPostJob 정의
class PublishPostJob < ApplicationJob
  queue_as :default

  def perform(post_id)
    post = Post.find_by(id: post_id)
    return unless post&.scheduled?  # 이미 취소된 경우 guard
    post.update!(status: :published, scheduled_at: nil, job_id: nil)
  end
end

# 컨트롤러에서 큐잉
scheduled_at_utc = ActiveSupport::TimeZone["Seoul"].parse(params[:scheduled_at]).utc
job = PublishPostJob.set(wait_until: scheduled_at_utc).perform_later(post.id)
post.update!(job_id: job.provider_job_id)
```

### Pattern 2: 예약 취소 및 재예약

**What:** 기존 큐에 등록된 잡을 제거하고 새 잡을 등록
**When to use:** Admin이 예약 시각을 변경하거나 예약을 취소할 때

```ruby
# Source: https://deepwiki.com/rails/solid_queue/10.2-activejob-integration

# 기존 잡 제거
if post.job_id.present?
  SolidQueue::Job.find_by(id: post.job_id)&.destroy
  post.update!(job_id: nil)
end

# 예약 취소 (즉시 발행이거나 draft 유지)
post.update!(scheduled_at: nil, job_id: nil)

# 재예약 (시각 변경)
new_job = PublishPostJob.set(wait_until: new_scheduled_at_utc).perform_later(post.id)
post.update!(scheduled_at: new_scheduled_at, job_id: new_job.provider_job_id)
```

### Pattern 3: KST 입력값 UTC 변환

**What:** `datetime-local` HTML 입력은 브라우저 로컬 시간(KST)으로 전달됨. Rails는 이를 UTC로 저장해야 함.
**When to use:** 폼에서 `scheduled_at` 파라미터 수신 시

```ruby
# Source: https://thoughtbot.com/blog/its-about-time-zones
# (config/application.rb에 time_zone 설정 후)
# config.time_zone = "Seoul"  # 추가하면 Time.zone.parse가 KST로 동작

# 컨트롤러에서 명시적 변환 (time_zone 미설정 시에도 안전)
raw = params[:post][:scheduled_at]  # "2026-04-01T14:00"
kst_time = ActiveSupport::TimeZone["Seoul"].parse(raw)
utc_time = kst_time.utc
# => 2026-04-01 05:00:00 UTC

# 뷰에서 KST로 표시
post.scheduled_at.in_time_zone("Seoul").strftime("%Y-%m-%dT%H:%M")
```

### Pattern 4: 폼 datetime-local 필드

**What:** HTML5 `datetime-local` 인풋을 Rails form helper로 렌더링
**When to use:** Admin 게시글 폼에 예약 시각 입력 UI 추가

```erb
<%# _form.html.erb에 추가 %>
<div>
  <label class="block text-sm font-bold mb-1">예약 발행 시각 (KST)</label>
  <%# value를 KST로 변환하여 표시 %>
  <% scheduled_kst = post.scheduled_at&.in_time_zone("Seoul")&.strftime("%Y-%m-%dT%H:%M") %>
  <%= f.text_field :scheduled_at,
        type: "datetime-local",
        value: scheduled_kst,
        min: Time.current.in_time_zone("Seoul").strftime("%Y-%m-%dT%H:%M"),
        class: "w-full px-4 py-3 rounded-2xl border border-gray-300 focus:outline-none" %>
</div>
```

### Pattern 5: 예약됨 상태 표시 (index 배지)

**What:** 게시글 목록에서 예약 상태와 예정 시각 표시
**When to use:** Admin 게시글 관리 목록 (index.html.erb)

```erb
<td class="px-4 py-3">
  <% if post.scheduled? %>
    <span class="text-yellow-600 font-bold">예약됨</span>
    <span class="text-xs text-tv-gray block">
      <%= post.scheduled_at.in_time_zone("Seoul").strftime("%m/%d %H:%M") %>
    </span>
  <% elsif post.published? %>
    <span class="text-green-600">published</span>
  <% else %>
    <span class="text-tv-gray">draft</span>
  <% end %>
</td>
```

### Anti-Patterns to Avoid

- **`status: :scheduled` enum 추가 금지**: 현재 Post enum은 `{draft: 0, published: 1}`. 예약은 `draft` 상태로 `scheduled_at` 유무로 구분하면 충분. 별도 enum 추가는 공개 피드 필터 로직 전체 수정 필요.
- **`Time.now` 사용 금지**: `Time.now`는 서버 OS timezone 기준. 반드시 `Time.current` 또는 `Time.zone.now` 사용.
- **`Time.parse` 사용 금지**: timezone 정보 없이 파싱하면 UTC로 처리됨. `ActiveSupport::TimeZone["Seoul"].parse` 사용.
- **잡 큐잉을 트랜잭션 밖에서 하지 말 것**: `post.save` 성공 후에 `perform_later` 호출. Rails 8.1 `enqueue_after_transaction_commit`이 `:default`이므로 트랜잭션 내 자동 지연 처리가 되지만, 명시적 순서 보장을 위해 `after_commit` 콜백보다 컨트롤러에서 직접 처리 권장.

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| 예약 실행 엔진 | cron job + polling | SolidQueue `set(wait_until:)` | SolidQueue dispatcher가 초 단위 정확도로 scheduled_executions 테이블 폴링 |
| 잡 취소 메커니즘 | scheduled_at 컬럼 폴링으로 status 체크 | `SolidQueue::Job.find(id).destroy` | DB 레코드 삭제가 가장 확실한 취소. 폴링은 race condition 발생 |
| 타임존 변환 | 수동 UTC offset 계산 | `ActiveSupport::TimeZone["Seoul"].parse` | DST 등 엣지 케이스를 ActiveSupport가 처리 |
| 배지 상태 판단 | 복잡한 status 로직 | `post.scheduled?` 헬퍼 메서드 | `scheduled_at.present? && draft?`로 단순 정의 가능 |

**Key insight:** SolidQueue는 이미 `solid_queue_scheduled_executions` 테이블에서 dispatcher가 주기적으로 due 잡을 `ready_executions`으로 이동시키는 메커니즘을 가지고 있다. 별도 스케줄러 로직을 구현할 필요 없다.

## Common Pitfalls

### Pitfall 1: `scheduled_at` 컬럼과 `status` enum 충돌

**What goes wrong:** `status: :scheduled`를 새로 추가하면 기존 `published` scope, 공개 피드 필터, 관리자 목록 상태 표시 전체 수정이 필요해짐.
**Why it happens:** 예약 상태를 별도 enum으로 분리하고 싶은 충동.
**How to avoid:** `scheduled_at.present?`로 "예약됨" 여부를 판단. status는 `draft`/`published` 두 가지만 유지. 잡이 실행되면 `status: :published`로 업데이트.
**Warning signs:** `Post.statuses`에 `scheduled` 추가 시도.

### Pitfall 2: KST 입력을 UTC로 착각

**What goes wrong:** `datetime-local` 필드에서 받은 `"2026-04-01T14:00"`을 그냥 `Time.parse`나 `DateTime.parse`로 처리하면 UTC로 해석되어 9시간 오차 발생.
**Why it happens:** HTML `datetime-local`은 timezone 정보 없이 로컬 시간만 전송.
**How to avoid:** `ActiveSupport::TimeZone["Seoul"].parse(raw_value)` 사용. config.time_zone을 "Seoul"로 설정하면 `Time.zone.parse`로도 가능하지만, 현재 프로젝트는 time_zone 미설정 상태.
**Warning signs:** DB에 저장된 `scheduled_at`이 KST 기준 14:00인데 05:00 UTC가 아닌 14:00 UTC로 저장됨.

### Pitfall 3: provider_job_id를 저장하지 않으면 취소 불가

**What goes wrong:** `PublishPostJob.set(wait_until:).perform_later(post.id)` 반환값에서 `provider_job_id`를 저장하지 않으면, 나중에 SolidQueue DB에서 해당 잡을 찾을 방법이 없음.
**Why it happens:** `perform_later`가 비동기이므로 반환값을 무시하는 경우 많음.
**How to avoid:** `job = PublishPostJob.set(...).perform_later(post.id)`로 반환값을 받고 `post.update!(job_id: job.provider_job_id)` 저장.
**Warning signs:** 예약 취소/변경 시 `post.job_id`가 nil.

### Pitfall 4: 잡 실행 시 Post가 이미 변경된 경우

**What goes wrong:** 예약 후 Admin이 게시글을 수동으로 `published`로 변경했는데, 기존 예약 잡을 취소하지 않으면 잡 실행 시 이미 published인 게시글을 다시 건드림.
**Why it happens:** 수동 발행 시 `job_id`로 기존 잡 취소를 누락.
**How to avoid:** Post 수정(update) 시 `job_id.present?`이면 항상 기존 잡 먼저 취소. `PublishPostJob#perform` 내에서도 `post.scheduled?` guard 추가.
**Warning signs:** 이미 published된 게시글의 `updated_at`이 의도치 않게 갱신됨.

### Pitfall 5: SolidQueue development 환경 미실행

**What goes wrong:** 개발 환경에서 `bin/rails server`만 실행하면 SolidQueue worker/dispatcher가 없어서 예약 잡이 실행되지 않음.
**Why it happens:** SolidQueue는 별도 프로세스가 필요.
**How to avoid:** `Procfile.dev`에 `worker: bin/jobs`가 있는지 확인 후 `bin/dev`로 실행 (Foreman/Overmind 사용). 또는 개발 시 `queue_adapter = :inline`으로 테스트.
**Warning signs:** `bin/rails server`만 실행 시 잡이 큐에는 들어가지만 실행 안 됨.

## Code Examples

### 마이그레이션: scheduled_at + job_id 추가

```ruby
# db/migrate/YYYYMMDD_add_scheduling_to_posts.rb
class AddSchedulingToPosts < ActiveRecord::Migration[8.1]
  def change
    add_column :posts, :scheduled_at, :datetime
    add_column :posts, :job_id, :integer  # SolidQueue::Job.id (bigint 가능)
    add_index :posts, :scheduled_at
  end
end
```

### Post 모델: scheduled? 헬퍼

```ruby
# app/models/post.rb 추가
scope :scheduled, -> { where(status: :draft).where.not(scheduled_at: nil) }

def scheduled?
  draft? && scheduled_at.present?
end
```

### PublishPostJob 전체 구현

```ruby
# app/jobs/publish_post_job.rb
class PublishPostJob < ApplicationJob
  queue_as :default

  # 잡 실행 실패 시 재시도하지 않음 (예약 발행은 1회성)
  discard_on ActiveJob::DeserializationError

  def perform(post_id)
    post = Post.find_by(id: post_id)

    # guard: 게시글이 삭제되었거나 이미 발행됨, 또는 예약 취소됨
    return unless post&.scheduled?

    post.update!(
      status: :published,
      scheduled_at: nil,
      job_id: nil
    )
  end
end
```

### Admin::PostsController: 예약 처리 로직

```ruby
# app/controllers/admin/posts_controller.rb

def create
  @post = Current.user.posts.build(post_params)
  handle_scheduling(@post)

  if @post.save
    enqueue_publish_job(@post) if @post.scheduled?
    redirect_to admin_posts_path, notice: "게시글이 작성되었습니다."
  else
    render :new, status: :unprocessable_entity
  end
end

def update
  cancel_existing_job(@post)  # 기존 잡 항상 취소

  if @post.update(post_params)
    handle_scheduling(@post)
    enqueue_publish_job(@post) if @post.scheduled?
    redirect_to admin_posts_path, notice: "게시글이 수정되었습니다."
  else
    render :edit, status: :unprocessable_entity
  end
end

private

def handle_scheduling(post)
  raw = params[:post][:scheduled_at]
  if raw.present?
    kst = ActiveSupport::TimeZone["Seoul"].parse(raw)
    post.scheduled_at = kst.utc
    post.status = :draft  # 예약 중이면 draft 유지
  else
    post.scheduled_at = nil
  end
end

def enqueue_publish_job(post)
  job = PublishPostJob.set(wait_until: post.scheduled_at).perform_later(post.id)
  post.update_column(:job_id, job.provider_job_id)
end

def cancel_existing_job(post)
  return unless post.job_id.present?
  SolidQueue::Job.find_by(id: post.job_id)&.destroy
  post.update_column(:job_id, nil)
end

def post_params
  params.require(:post).permit(:title, :body, :category_id, :status, :pinned,
                               :seo_title, :seo_description)
  # scheduled_at은 별도 handle_scheduling에서 처리 (timezone 변환 필요)
end
```

### 개발 환경 SolidQueue 실행 확인

```bash
# Procfile.dev 확인
cat teovibe/Procfile.dev

# 모든 프로세스 시작 (서버 + 잡 워커)
bin/dev
```

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| Sidekiq + Redis for background jobs | SolidQueue (DB-backed) | Rails 8 (2024) | Redis 인프라 불필요, SQLite 기반 |
| Delayed::Job gem | SolidQueue native | Rails 8 | 별도 gem 불필요 |
| Cron-based publishing check | `set(wait_until:).perform_later` | SolidQueue 도입 | 초 단위 정확도, 취소 가능 |

**Deprecated/outdated:**
- `delay` 메서드 (Delayed::Job 방식): SolidQueue에서는 `set(wait:)`/`set(wait_until:)` 사용
- `perform_in` (Sidekiq 스타일): ActiveJob 표준은 `set(wait:).perform_later`

## Open Questions

1. **개발 환경에서 SolidQueue worker 실행 방법**
   - What we know: `Procfile.dev`가 존재하고 `bin/dev`로 실행 가능할 것
   - What's unclear: `Procfile.dev` 내용 미확인 (worker 항목 포함 여부)
   - Recommendation: 구현 전 `cat teovibe/Procfile.dev` 확인. worker 없으면 추가 또는 테스트 환경에서 `queue_adapter = :inline` 사용

2. **`job_id` 컬럼 타입 (integer vs bigint vs string)**
   - What we know: SolidQueue::Job.id는 Rails 기본 primary key (integer). SQLite에서는 INTEGER로 자동 처리됨.
   - What's unclear: SolidQueue 내부에서 `provider_job_id`가 Integer인지 String인지
   - Recommendation: `provider_job_id`는 ActiveJob에서 `String`으로 반환될 수 있으므로 `t.string :job_id`가 더 안전

3. **`config.time_zone = "Seoul"` 전역 설정 여부**
   - What we know: 현재 `config/application.rb`에 time_zone 설정이 주석 처리되어 있음
   - What's unclear: 전역 설정 시 다른 datetime 표시에 영향이 있는지
   - Recommendation: 전역 time_zone 설정 대신 `ActiveSupport::TimeZone["Seoul"].parse()`로 명시적 변환. 폼 표시는 `.in_time_zone("Seoul")`으로 처리.

## Validation Architecture

### Test Framework

| Property | Value |
|----------|-------|
| Framework | Minitest (Rails 내장) |
| Config file | `test/test_helper.rb` |
| Quick run command | `bin/rails test test/jobs/publish_post_job_test.rb` |
| Full suite command | `bin/rails test test/` |

### Phase Requirements → Test Map

| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| SCHD-01 | Admin 폼에서 datetime-local 입력 → KST로 표시, UTC로 저장 | integration | `bin/rails test test/controllers/admin/posts_controller_test.rb` | Wave 0 생성 필요 |
| SCHD-02 | PublishPostJob 실행 → post.status = :published | unit | `bin/rails test test/jobs/publish_post_job_test.rb` | Wave 0 생성 필요 |
| SCHD-03 | 예약 취소 → SolidQueue Job 삭제, 시각 변경 → 새 Job 큐잉 | integration | `bin/rails test test/controllers/admin/posts_controller_test.rb` | Wave 0 생성 필요 |

### Sampling Rate

- **Per task commit:** `bin/rails test test/jobs/publish_post_job_test.rb test/controllers/admin/posts_controller_test.rb`
- **Per wave merge:** `bin/rails test test/`
- **Phase gate:** Full suite green before `/gsd:verify-work`

### Wave 0 Gaps

- [ ] `test/jobs/publish_post_job_test.rb` — SCHD-02: 잡 실행 시 draft → published 전환, guard 검증
- [ ] `test/controllers/admin/posts_controller_test.rb` — SCHD-01/03: 예약 생성/취소/변경 통합 테스트 (기존 파일에 추가)
- [ ] `db/migrate/YYYYMMDD_add_scheduling_to_posts.rb` — scheduled_at, job_id 컬럼 마이그레이션

*(기존 `test/controllers/admin/categories_controller_test.rb` 패턴 참고: `sign_in_as(@admin)` + `ActionDispatch::IntegrationTest`)*

## Sources

### Primary (HIGH confidence)

- `/rails/solid_queue` Context7 — `set(wait_until:).perform_later` 패턴, `provider_job_id` 동작 확인
- `/websites/guides_rubyonrails` Context7 — `wait_until`, `wait` ActiveJob API 확인
- [SolidQueue ActiveJob Integration](https://deepwiki.com/rails/solid_queue/10.2-activejob-integration) — provider_job_id, 잡 취소 패턴, 상태 머신 확인
- 프로젝트 코드 직접 검토 — `Gemfile`, `config/queue.yml`, `config/recurring.yml`, `app/models/post.rb`, `app/controllers/admin/posts_controller.rb`, `db/schema.rb`

### Secondary (MEDIUM confidence)

- [Ability to Cancel a Future Scheduled Job #395](https://github.com/rails/solid_queue/issues/395) — `SolidQueue::Job.find(id).destroy` 취소 패턴 커뮤니티 검증
- [Thoughtbot: It's About Time Zones](https://thoughtbot.com/blog/its-about-time-zones) — Rails timezone 베스트 프랙티스, `Time.current` vs `Time.now`

### Tertiary (LOW confidence)

- [Rails Discussion: datetime_field timezone](https://discuss.rubyonrails.org/t/postgresql-timezone-for-datetime-is-0000-set-by-datetime-field/84700) — `datetime-local` 필드의 timezone 미포함 문제 (SQLite 기반 프로젝트이므로 PostgreSQL 특이사항은 해당 없음)

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH — SolidQueue 이미 설치/설정 완료. ActiveJob API Context7에서 직접 확인
- Architecture: HIGH — SolidQueue provider_job_id + destroy 패턴이 공식 문서 및 커뮤니티에서 검증됨
- Pitfalls: HIGH — KST/UTC 혼용 문제, 잡 취소 누락, guard 패턴은 실제 코드 분석에서 도출됨

**Research date:** 2026-03-01
**Valid until:** 2026-04-01 (SolidQueue 안정 버전, 30일 유효)
