# Stack Research

**Domain:** TeoVibe v1.1 Admin 고도화 — 동적 카테고리 관리, AI 초안 작성, 예약 발행
**Researched:** 2026-02-28
**Confidence:** HIGH

---

## Scope

이 문서는 v1.1 신규 기능에만 집중한다. 기존에 검증된 스택(Rails 8.1.2, Hotwire, Solid Queue 1.3.1, vite_ruby + React 19, rhino-editor, chartkick 등)은 재조사하지 않는다.

신규 기능:
1. 게시판/스킬팩 카테고리 동적 CRUD + 순서 변경
2. Anthropic API 기반 AI 초안 작성 (2단계 생성, SEO/AEO)
3. 게시글 예약 발행 (날짜/시간 지정, Solid Queue scheduled job)

---

## 기능 1: 동적 카테고리 CRUD

### 현황 분석

`Post#category`와 `SkillPack#category`가 현재 Rails `enum`으로 하드코딩:

```ruby
# 현재 구조 — 하드코딩 enum
enum :category, { blog: 0, tutorial: 1, free_board: 2, qna: 3, portfolio: 4, notice: 5 }
enum :category, { template: 0, component: 1, guide: 2, toolkit: 3 }
```

동적 관리를 위해 `Category` 모델로 전환 필요. 스킬팩 카테고리는 순서 변경 요구사항 있음.

### 추가 스택

#### 신규 Gem

| Technology | Version | Purpose | Why Recommended |
|------------|---------|---------|-----------------|
| `acts_as_list` | `~> 1.2` | Category 모델 position 기반 순서 관리 | 스킬팩 카테고리 순서 변경 요구사항. `insert_at`, `move_higher/lower`, `move_to_top` 메서드로 position 관리를 Rails 레벨에서 처리. v1.2.6 (2025-10-21 릴리즈), activerecord >= 6.1 의존 — Rails 8.1.2 호환 확인 |

#### 신규 npm 패키지

| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| `sortablejs` | `^1.15` | 드래그 앤 드롭 카테고리 순서 변경 UI | Admin 카테고리 순서 변경. Stimulus Controller와 연동해 drag-end 이벤트를 PATCH 요청으로 전환. jQuery 불필요, 모바일 터치 지원 |
| `@types/sortablejs` | `^1.15` | SortableJS TypeScript 타입 | vite_ruby TypeScript 환경에서 타입 안전성 확보 |

### 아키텍처 결정

- `Category` 모델: `name`, `slug`, `position`, `admin_only` (boolean), `category_type` (enum: post/skillpack)
- `Post#category` integer enum → `belongs_to :category`로 마이그레이션
- `SkillPack#category` integer enum → `belongs_to :category`로 마이그레이션
- 기존 라우팅 slug(`/blogs`, `/tutorials`)는 `Category#slug`로 대체
- `acts_as_list`의 `scope: :category_type`으로 post/skillpack 카테고리 각각 독립 순서 관리

### 구현 패턴

```ruby
# Gemfile
gem "acts_as_list", "~> 1.2"

# app/models/category.rb
class Category < ApplicationRecord
  acts_as_list scope: :category_type

  enum :category_type, { post: 0, skillpack: 1 }

  validates :name, presence: true, uniqueness: { scope: :category_type }
  before_validation :generate_slug, if: -> { slug.blank? }
end
```

```javascript
// app/javascript/controllers/sortable_controller.js
import { Controller } from "@hotwired/stimulus"
import Sortable from "sortablejs"

export default class extends Controller {
  connect() {
    this.sortable = Sortable.create(this.element, {
      animation: 150,
      onEnd: this.onEnd.bind(this)
    })
  }

  onEnd({ item, newIndex }) {
    const id = item.dataset.id
    fetch(item.dataset.url, {
      method: "PATCH",
      headers: { "Content-Type": "application/json", "X-CSRF-Token": document.querySelector('meta[name="csrf-token"]').content },
      body: JSON.stringify({ position: newIndex + 1 })
    })
  }
}
```

---

## 기능 2: Anthropic API — AI 초안 작성

### 현황 분석

- Faraday 2.14.1이 이미 Gemfile.lock에 존재 (결제 연동용)
- 직접 HTTP 호출도 가능하나, Anthropic 공식 Ruby SDK가 2025년 4월 출시됨 (v1.23.0, 2026-02-19)

### 추가 스택

#### 신규 Gem

| Technology | Version | Purpose | Why Recommended |
|------------|---------|---------|-----------------|
| `anthropic` | `~> 1.23` | Anthropic Claude API 공식 Ruby 클라이언트 | 2026-02-19 최신 릴리즈. Ruby 3.2.0+ 요구 (프로젝트 Ruby 3.3.10 — 충족). net/http 기반으로 외부 HTTP 의존성 없음. SSE 스트리밍 내장. 자동 재시도(기본 2회), 600초 타임아웃. Yard/RBS/RBI 타입 정의 포함 |

### 모델 선택: `claude-haiku-4-5-20251001`

| Model | API ID | Input | Output | Latency | 추천 이유 |
|-------|--------|-------|--------|---------|---------|
| **Claude Haiku 4.5** | `claude-haiku-4-5-20251001` | $1/MTok | $5/MTok | 가장 빠름 | **초안 생성 권장** — 빠른 응답, 1인 운영 비용 효율 |
| Claude Sonnet 4.6 | `claude-sonnet-4-6` | $3/MTok | $15/MTok | 빠름 | 고품질 필요 시 ENV로 교체 가능한 옵션 |
| Claude Opus 4.6 | `claude-opus-4-6` | $5/MTok | $25/MTok | 보통 | 초안 생성에 과도 |

모델명은 `ENV["ANTHROPIC_MODEL"]`로 분리하여 비용/품질 트레이드오프 조정 가능하게 구성.

### 2단계 생성 플로우

```
Step 1: 주제 입력 → 개요 생성 (짧은 응답, ~500 tokens, non-streaming)
Step 2: 개요 확인 → 본문 생성 (긴 응답, ~3000 tokens, Turbo Stream 스트리밍)
```

두 단계 모두 동일한 `anthropic` gem으로 처리 — 별도 라이브러리 불필요.

### 스트리밍 구현 패턴

**선택: ActiveJob + Turbo::StreamsChannel (Action Cable 방식)**

1인 운영 Admin 기능이므로 동시 접속 극히 낮음. Action Cable이 ActionController::Live(SSE)보다 구현 단순.

```ruby
# app/jobs/ai_draft_job.rb
class AiDraftJob < ApplicationJob
  queue_as :default

  SYSTEM_PROMPT = <<~PROMPT
    You are an expert Korean tech blogger specializing in SEO/AEO optimization.
    Write content that directly answers user questions (AEO) and includes
    structured headings (H2/H3) with relevant keywords (SEO).
    Output format: Markdown-compatible HTML for rhino-editor (ActionText).
  PROMPT

  def perform(draft_id, messages)
    client = Anthropic::Client.new(api_key: ENV["ANTHROPIC_API_KEY"])

    stream = client.messages.stream(
      model: ENV.fetch("ANTHROPIC_MODEL", "claude-haiku-4-5-20251001"),
      max_tokens: 4096,
      system: SYSTEM_PROMPT,
      messages: messages
    )

    stream.text.each do |chunk|
      Turbo::StreamsChannel.broadcast_append_to(
        "ai_draft_#{draft_id}",
        target: "ai-draft-output",
        partial: "admin/ai_drafts/chunk",
        locals: { text: chunk }
      )
    end

    Turbo::StreamsChannel.broadcast_replace_to(
      "ai_draft_#{draft_id}",
      target: "ai-draft-status",
      partial: "admin/ai_drafts/done"
    )
  end
end
```

**Action Cable 순서 주의:** Action Cable은 스레드 풀로 인해 청크 순서 보장 없음. 해결책: 청크를 append 방식으로만 처리(순서 의존 없음). Admin 전용 단일 사용자 환경이므로 실용적으로 문제없음.

### ENV 설정

```bash
# .env (development, .kamal/secrets for production)
ANTHROPIC_API_KEY=sk-ant-...
ANTHROPIC_MODEL=claude-haiku-4-5-20251001
```

---

## 기능 3: 예약 발행 — Solid Queue Scheduled Job

### 현황 분석

- `solid_queue` 1.3.1 이미 설치 및 설정 완료
- `config/queue.yml`: Dispatcher 프로세스 + Worker 프로세스 구성됨
- `config/recurring.yml`: 이미 매시간 finished job 정리 설정됨
- `Post#status` enum: `{ draft: 0, published: 1 }` 존재
- DB 스키마에 `publish_at` datetime 컬럼 없음 → 마이그레이션만 필요

### 추가 스택: 없음

Solid Queue의 `perform_at` (ActiveJob `wait_until`) 기능으로 완전히 처리 가능. 신규 gem 불필요.

### Solid Queue 스케줄드 잡 동작 원리

```
1. PublishPostJob.set(wait_until: post.publish_at).perform_later(post.id)
   → solid_queue_scheduled_executions 테이블에 저장

2. Dispatcher 프로세스 (polling_interval: 1초, config/queue.yml)
   → scheduled_at이 현재 시간 이전인 잡을 ready_executions로 이동

3. Worker 프로세스 (threads: 3, polling_interval: 0.1초)
   → ready_executions에서 잡 픽업 후 실행
```

### 필요 마이그레이션

```ruby
# db/migrate/YYYYMMDDHHMMSS_add_publish_at_to_posts.rb
class AddPublishAtToPosts < ActiveRecord::Migration[8.1]
  def change
    add_column :posts, :publish_at, :datetime
    add_index :posts, :publish_at
  end
end
```

### 구현 패턴

```ruby
# app/jobs/publish_post_job.rb
class PublishPostJob < ApplicationJob
  queue_as :default

  def perform(post_id)
    post = Post.find_by(id: post_id)
    return unless post
    return unless post.draft?  # 이미 발행됐거나 삭제됐으면 스킵
    return if post.publish_at.nil? || post.publish_at > Time.current  # 아직 발행 시간 아님

    post.update!(status: :published, publish_at: nil)
  end
end

# app/controllers/admin/posts_controller.rb (update 액션)
def update
  if @post.update(post_params)
    if @post.publish_at.present? && @post.publish_at.future?
      PublishPostJob.set(wait_until: @post.publish_at).perform_later(@post.id)
      redirect_to admin_posts_path, notice: "#{@post.publish_at.strftime('%Y-%m-%d %H:%M')}에 예약 발행됩니다."
    elsif post_params[:status] == "published"
      redirect_to admin_posts_path, notice: "게시글이 발행되었습니다."
    else
      redirect_to admin_posts_path, notice: "임시저장되었습니다."
    end
  end
end
```

**예약 취소:** `publish_at`을 nil로 업데이트. Solid Queue 잡은 실행 시 `publish_at`이 없으면 스킵하므로 별도 잡 취소 불필요. (멱등성 확보)

---

## 최종 추가 목록

### 신규 Gem (Gemfile)

| Gem | Version | For |
|-----|---------|-----|
| `anthropic` | `~> 1.23` | AI 초안 작성 |
| `acts_as_list` | `~> 1.2` | 카테고리 순서 관리 |

### 신규 npm 패키지

| Package | Version | For |
|---------|---------|-----|
| `sortablejs` | `^1.15` | 카테고리 드래그 앤 드롭 |
| `@types/sortablejs` | `^1.15` | TypeScript 타입 |

### 신규 DB 마이그레이션

| Migration | Purpose |
|-----------|---------|
| `create_categories` | 동적 카테고리 모델 |
| `add_category_ref_to_posts` | Post → Category 외래키 |
| `add_category_ref_to_skill_packs` | SkillPack → Category 외래키 |
| `add_publish_at_to_posts` | 예약 발행 datetime |

### ENV 추가

| Key | Description |
|-----|-------------|
| `ANTHROPIC_API_KEY` | Anthropic API 인증 키 |
| `ANTHROPIC_MODEL` | 사용 모델 (기본: `claude-haiku-4-5-20251001`) |

---

## Installation

```bash
# Gemfile에 추가
gem "anthropic", "~> 1.23"
gem "acts_as_list", "~> 1.2"

# 설치
bundle install

# npm 패키지 (pnpm 사용)
pnpm add sortablejs
pnpm add -D @types/sortablejs

# DB 마이그레이션
bin/rails db:migrate
```

---

## Alternatives Considered

| Recommended | Alternative | When to Use Alternative |
|-------------|-------------|-------------------------|
| `anthropic` gem 1.23 | Faraday 직접 HTTP 호출 | 공식 SDK 이전 상황이었다면 Faraday. 현재는 SDK가 스트리밍/재시도/타임아웃을 처리하므로 SDK 우선 |
| `anthropic` gem 1.23 | `ruby_llm` gem | 여러 LLM provider(OpenAI, Gemini 등) 동시 지원이 필요한 경우 |
| `acts_as_list` | `ranked-model` | 비순차 float 순서(0.5, 1.5 사이 삽입)가 필요할 때. 현재는 단순 정수 position으로 충분 |
| `sortablejs` (직접) | `stimulus-sortable` npm 패키지 | stimulus-sortable은 sortablejs 래퍼. 커스텀 콜백이 적을 때 더 빠른 통합 가능 |
| Solid Queue `perform_at` | `whenever` gem + cron | 매일 같은 시간에 반복 실행(cron 패턴)이 필요할 때. 개별 post 예약은 perform_at이 적합 |
| `claude-haiku-4-5` | `claude-sonnet-4-6` | 생성 품질이 더 중요하고 비용이 허용될 때 (3배 비용) |

---

## What NOT to Add

| Avoid | Why | Use Instead |
|-------|-----|-------------|
| `ruby_llm` gem | 다중 LLM 추상화. Anthropic 단독 사용에 불필요한 레이어 추가 | `anthropic` gem 직접 |
| `sidekiq` + Redis | 예약 발행에 Redis 의존성 추가. SQLite 스택과 불일치. Solid Queue로 완전히 대체 가능 | Solid Queue `perform_at` |
| `whenever` gem | cron 파일 별도 관리, 배포 복잡도 증가. 개별 post 예약에 적합하지 않은 패턴 | Solid Queue scheduled job |
| ActionController::Live SSE (스트리밍) | Puma 스레드 점유. Admin 1인 환경에서도 불필요. Action Cable 방식이 더 Rails 관용적 | Turbo::StreamsChannel + ActiveJob |
| `ranked-model` gem | 비순차 float 순서는 현재 요구사항 이상. acts_as_list가 더 단순하고 성숙함 | `acts_as_list` |

---

## Version Compatibility

| Package | Compatible With | Notes |
|---------|-----------------|-------|
| `anthropic` ~> 1.23 | Ruby >= 3.2.0 | 프로젝트 Ruby 3.3.10 — 호환 확인. net/http 기반으로 Rails 버전 의존 없음 |
| `acts_as_list` ~> 1.2 | activerecord >= 6.1 | Rails 8.1.2 포함 — 호환 확인. v1.2.6 (2025-10-21 릴리즈) |
| `sortablejs` ^1.15 | Vite 5.x / ESM | vite_ruby 번들링 환경에서 ESM import 지원. 호환 확인 |
| `claude-haiku-4-5-20251001` | `anthropic` ~> 1.23 | Anthropic 공식 현재 모델 ID (2026-02-28 기준) |
| Solid Queue 1.3.1 | `perform_at` / `set(wait_until:)` | 이미 설치된 버전. scheduled_executions 테이블로 미래 실행 지원 |

---

## Sources

- [anthropics/anthropic-sdk-ruby GitHub](https://github.com/anthropics/anthropic-sdk-ruby) — 버전, 사용법, 스트리밍 패턴 (HIGH)
- [rubygems.org/gems/anthropic](https://rubygems.org/gems/anthropic) — v1.23.0 최신 버전 (2026-02-19 릴리즈) 확인 (HIGH)
- [Anthropic Models Overview](https://platform.claude.com/docs/en/about-claude/models/overview) — claude-haiku-4-5-20251001 모델 ID 및 가격 공식 확인 (HIGH)
- [rubygems.org/gems/acts_as_list](https://rubygems.org/gems/acts_as_list) — v1.2.6 (2025-10-21), activerecord >= 6.1 의존 확인 (HIGH)
- [rails/solid_queue GitHub](https://github.com/rails/solid_queue) — scheduled_executions 테이블, Dispatcher 동작, perform_at 패턴 (HIGH)
- [AppSignal: Deep Dive into Solid Queue](https://blog.appsignal.com/2025/06/18/a-deep-dive-into-solid-queue-for-ruby-on-rails.html) — Dispatcher polling 동작 원리 확인 (MEDIUM)
- [npmjs.com/package/sortablejs](https://www.npmjs.com/package/sortablejs) — v1.15.x 확인 (MEDIUM)
- [stimulus-components/stimulus-sortable](https://github.com/stimulus-components/stimulus-sortable) — SortableJS + Stimulus 통합 패턴 참고 (MEDIUM)
- [evilmartians: AnyCable and LLM streaming pitfalls](https://evilmartians.com/chronicles/anycable-rails-and-the-pitfalls-of-llm-streaming) — Action Cable 순서 보장 이슈 확인 (MEDIUM)

---

*Stack research for: TeoVibe v1.1 Admin 고도화 (동적 카테고리, AI 초안, 예약 발행)*
*Researched: 2026-02-28*
