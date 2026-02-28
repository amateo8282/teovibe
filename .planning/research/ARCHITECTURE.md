# Architecture Research

**Domain:** Rails 모놀리스 Admin 고도화 (동적 카테고리, AI 초안, 예약 발행)
**Researched:** 2026-02-28
**Confidence:** HIGH — 기존 코드베이스 직접 분석 + Rails 공식 패턴 기반

---

## Standard Architecture

### System Overview

```
┌─────────────────────────────────────────────────────────────┐
│                     Admin Namespace                          │
├─────────────────────────────────────────────────────────────┤
│  ┌───────────────┐  ┌───────────────┐  ┌───────────────┐    │
│  │ Categories    │  │ Posts (수정)  │  │ SkillPacks    │    │
│  │ Controller    │  │ Controller    │  │ (수정)        │    │
│  │ (NEW)         │  │ +category_id  │  │ Controller    │    │
│  │ CRUD+reorder  │  │ +publish_at   │  │ +category_id  │    │
│  └──────┬────────┘  └──────┬────────┘  └──────┬────────┘    │
│         │                 │                   │              │
│  ┌──────┴─────────────────┴───────────────────┴────────┐     │
│  │           Admin::AiDraftsController (NEW)            │     │
│  │           Turbo Stream 응답 전용                     │     │
│  └────────────────────────┬─────────────────────────────┘    │
└───────────────────────────┼──────────────────────────────────┘
                            │
┌───────────────────────────┼──────────────────────────────────┐
│                 Service Layer                                 │
├───────────────────────────┼──────────────────────────────────┤
│  ┌────────────────┐        │  ┌───────────────────────┐       │
│  │ AiDraftService │        │  │ (기존)                │       │
│  │ (NEW)          │        │  │ NotificationService   │       │
│  │ Anthropic API  │        │  │ PointService          │       │
│  │ Faraday 호출   │        │  │ PaymentService        │       │
│  └───────┬────────┘        │  └───────────────────────┘       │
└──────────┼─────────────────┼────────────────────────────────┘
           │                 │
┌──────────┼─────────────────┼────────────────────────────────┐
│                 Job Layer (Solid Queue)                       │
├──────────┼─────────────────┼────────────────────────────────┤
│  ┌───────┴────────┐        │  ┌───────────────────────┐       │
│  │ PublishPostJob │        │  │ (기존)                │       │
│  │ (NEW)          │        │  │ ClearFinishedJobs     │       │
│  │ scheduled exec │        │  │ (recurring.yml)       │       │
│  └────────────────┘        │  └───────────────────────┘       │
└────────────────────────────┼────────────────────────────────┘
                             │
┌────────────────────────────┼────────────────────────────────┐
│                 Model Layer                                   │
├────────────────────────────┼────────────────────────────────┤
│  ┌──────────────┐  ┌───────┴───────┐  ┌────────────────┐    │
│  │ Category     │  │ Post (수정)   │  │ SkillPack      │    │
│  │ (NEW)        │  │ -enum:category│  │ (수정)         │    │
│  │ record_type  │  │ +category_id  │  │ -enum:category │    │
│  │ slug         │  │ +publish_at   │  │ +category_id   │    │
│  │ position     │  │               │  │                │    │
│  │ admin_only   │  │               │  │                │    │
│  └──────────────┘  └───────────────┘  └────────────────┘    │
└─────────────────────────────────────────────────────────────┘
```

### Component Responsibilities

| Component | Responsibility | 기존 vs 신규 |
|-----------|----------------|-------------|
| `Category` 모델 | 게시판/스킬팩 카테고리 정의. `record_type` enum으로 Post/SkillPack 구분. `slug`, `position`, `admin_only` 컬럼 보유 | 신규 |
| `Admin::CategoriesController` | Category CRUD + move_up/move_down (LandingSection 패턴 재사용) | 신규 |
| `AiDraftService` | Anthropic Messages API Faraday 호출. 2단계(개요/본문) 프롬프트 관리 | 신규 |
| `Admin::AiDraftsController` | AI 초안 요청 처리. Turbo Stream으로 폼 필드 업데이트 | 신규 |
| `PublishPostJob` | Solid Queue 예약 실행. `post.update!(status: :published)` | 신규 |
| `Post` 모델 | `enum :category` 제거, `belongs_to :category`, `publish_at` 컬럼 + `after_save` 예약 콜백 추가 | 수정 |
| `SkillPack` 모델 | `enum :category` 제거, `belongs_to :category` 추가 | 수정 |
| `PostsBaseController` | `where(category:)` enum 스코프 → `joins(:category).where(categories:{slug:})` 조인 쿼리로 교체 | 수정 |
| `Admin::PostsController` | `post_params`에 `category_id`, `publish_at` 추가 | 수정 |
| `Admin::SkillPacksController` | `skill_pack_params`에 `category_id` 추가 | 수정 |

---

## Recommended Project Structure

```
teovibe/
├── app/
│   ├── models/
│   │   ├── category.rb                   # 신규: 통합 카테고리 모델
│   │   ├── post.rb                        # 수정: enum 제거, belongs_to, publish_at 콜백
│   │   └── skill_pack.rb                  # 수정: enum 제거, belongs_to
│   ├── controllers/
│   │   └── admin/
│   │       ├── categories_controller.rb   # 신규: CRUD + move_up/move_down
│   │       ├── ai_drafts_controller.rb    # 신규: Turbo Stream 응답
│   │       ├── posts_controller.rb         # 수정: category_id, publish_at 파라미터
│   │       └── skill_packs_controller.rb   # 수정: category_id 파라미터
│   ├── services/
│   │   └── ai_draft_service.rb            # 신규: Anthropic API 래퍼
│   ├── jobs/
│   │   └── publish_post_job.rb            # 신규: 예약 발행 Job
│   ├── javascript/
│   │   └── controllers/
│   │       └── ai_draft_controller.js     # 신규: Stimulus AI 초안 Fetch 처리
│   └── views/
│       └── admin/
│           ├── categories/                # 신규: index/new/edit/_form.html.erb
│           ├── ai_drafts/
│           │   └── create.turbo_stream.erb # 신규: Turbo Stream 응답 뷰
│           └── posts/
│               └── _form.html.erb          # 수정: 동적 카테고리, AI 초안 UI, publish_at 필드
├── config/
│   └── routes.rb                           # 수정: admin/categories, admin/ai_drafts 추가
└── db/
    ├── migrate/
    │   ├── YYYYMMDD_create_categories.rb
    │   ├── YYYYMMDD_add_category_id_to_posts.rb      # 기존 enum 데이터 이관 포함
    │   ├── YYYYMMDD_add_category_id_to_skill_packs.rb
    │   └── YYYYMMDD_add_publish_at_to_posts.rb
    └── seeds/
        └── categories.rb                             # 신규: 기존 6개 Post + 4개 SkillPack 카테고리
```

### Structure Rationale

- **`category.rb` 단일 모델:** `PostCategory`와 `SkillPackCategory`를 분리하는 대신 `record_type` enum으로 단일 테이블 관리. LandingSection/SectionCard 관계 패턴과 일관성 유지.
- **`ai_drafts_controller.rb` 분리:** PostsController에 AI 로직을 섞지 않음. 단일 책임 원칙. 향후 AI 기능 확장 시 이 컨트롤러만 수정.
- **`ai_draft_controller.js`:** 기존 Stimulus 패턴 유지. React 없이 Fetch + Turbo Stream만 사용.
- **마이그레이션에 데이터 이관 포함:** 마이그레이션 파일이 기존 integer enum 값을 category_id로 변환. 별도 rake task 불필요.

---

## Architectural Patterns

### Pattern 1: Category 모델 — enum 대체 전략

**What:** `posts.category` integer enum을 `categories` 테이블 FK로 교체. `record_type` 컬럼으로 Post용/SkillPack용 카테고리를 단일 테이블에서 구분.

**When to use:** 런타임에 카테고리 추가/수정/삭제/순서변경이 필요할 때. 현재 코드베이스에서 6개 Post 카테고리, 4개 SkillPack 카테고리가 하드코딩됨.

**Trade-offs:** 마이그레이션 시 기존 enum 정수값 → Category 레코드 이관 필요. `Post.where(category: :blog)` 같은 enum 스코프가 사라지고 조인 쿼리로 바뀜 (성능 영향 미미, 인덱스 있음).

**Example:**
```ruby
# app/models/category.rb
class Category < ApplicationRecord
  enum :record_type, { post: 0, skill_pack: 1 }

  validates :name, presence: true
  validates :slug, presence: true, uniqueness: { scope: :record_type }
  validates :position, numericality: { greater_than_or_equal_to: 0 }

  scope :for_posts, -> { where(record_type: :post).order(:position) }
  scope :for_skill_packs, -> { where(record_type: :skill_pack).order(:position) }

  # LandingSection의 move_up/move_down 패턴 직접 재사용
  def move_up
    above = Category.where(record_type: record_type)
                    .where("position < ?", position)
                    .order(position: :desc).first
    return unless above
    above.position, self.position = self.position, above.position
    Category.transaction { above.save!; save! }
  end

  def move_down
    below = Category.where(record_type: record_type)
                    .where("position > ?", position)
                    .order(position: :asc).first
    return unless below
    below.position, self.position = self.position, below.position
    Category.transaction { below.save!; save! }
  end
end

# app/models/post.rb (수정)
class Post < ApplicationRecord
  belongs_to :user, counter_cache: true
  belongs_to :category   # enum :category 대체
  has_many :comments, dependent: :destroy
  has_many :likes, as: :likeable, dependent: :destroy
  has_rich_text :body

  enum :status, { draft: 0, published: 1 }

  delegate :name, to: :category, prefix: true, allow_nil: true

  scope :published, -> { where(status: :published) }
  scope :pinned_first, -> { order(pinned: :desc, created_at: :desc) }

  # route_key: category.slug 기반으로 동작 (기존 string category와 동일 인터페이스)
  def route_key
    case category&.slug
    when "blog"       then [:blog, self]
    when "tutorial"   then [:tutorial, self]
    when "free_board" then [:free_board, self]
    when "qna"        then [:qna, self]
    when "portfolio"  then [:portfolio, self]
    when "notice"     then [:notice, self]
    else [:post, self]
    end
  end

  def category_name
    category&.name
  end
end
```

**마이그레이션 전략 — 기존 enum 데이터 보존:**
```ruby
# db/migrate/YYYYMMDD_add_category_id_to_posts.rb
class AddCategoryIdToPosts < ActiveRecord::Migration[8.1]
  # 기존 enum 정수 → slug 매핑
  SLUG_MAP = {
    0 => "blog", 1 => "tutorial", 2 => "free_board",
    3 => "qna",  4 => "portfolio", 5 => "notice"
  }.freeze

  def up
    add_column :posts, :category_id, :integer
    add_index :posts, :category_id

    # 시드로 Category 레코드가 생성된 후 실행
    # (마이그레이션과 시드를 함께 실행하려면 Category.reset_column_information 필요)
    SLUG_MAP.each do |old_int, slug|
      cat = Category.find_by!(slug: slug, record_type: 0) # 0 = post
      execute("UPDATE posts SET category_id = #{cat.id} WHERE category = #{old_int}")
    end

    change_column_null :posts, :category_id, false
    remove_column :posts, :category
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
```

**PostsBaseController 수정:**
```ruby
# app/controllers/posts_base_controller.rb
def index
  @category_record = Category.find_by!(slug: category_slug, record_type: :post)
  @posts = Post.joins(:category)
               .where(categories: { slug: category_slug })
               .published.pinned_first.includes(:user)
  @pagy, @posts = pagy(:offset, @posts, limit: 12)
  render "posts/index"
end

private

def category_slug
  raise NotImplementedError
end
```

```ruby
# app/controllers/blogs_controller.rb
class BlogsController < PostsBaseController
  private
  def category_slug = "blog"
end
```

### Pattern 2: AI 초안 — Turbo Stream 2단계 응답

**What:** Admin 게시글 폼에서 "AI 초안 생성" 버튼 클릭 → Stimulus Controller가 Fetch로 `POST /admin/ai_drafts` → `AiDraftService`가 Anthropic API 호출 → Turbo Stream으로 폼 특정 영역만 업데이트. 2단계 UX: 개요 확인 후 본문 생성.

**When to use:** Anthropic API 응답 시간(3-8초)으로 전체 페이지 submit 재렌더링이 UX상 부적절할 때. 입력한 제목/SEO 필드를 날리지 않으면서 AI 결과만 삽입.

**Trade-offs:** Stimulus Fetch + Turbo Stream 조합이 일반 form submit보다 복잡. 그러나 Action Cable WebSocket 방식보다 훨씬 단순. Streaming 응답(SSE)은 구현 복잡도 높으므로 단계형 UX로 대체.

**Example:**
```ruby
# app/controllers/admin/ai_drafts_controller.rb
module Admin
  class AiDraftsController < BaseController
    def create
      @result = AiDraftService.new(
        topic: params[:topic],
        stage: params[:stage]   # "outline" | "body"
      ).call

      respond_to do |format|
        format.turbo_stream
      end
    rescue AiDraftService::ApiError => e
      render turbo_stream: turbo_stream.update("ai-result-area",
        partial: "admin/ai_drafts/error", locals: { message: e.message })
    end
  end
end
```

```ruby
# app/services/ai_draft_service.rb
class AiDraftService
  ApiError = Class.new(StandardError)

  API_URL = "https://api.anthropic.com/v1/messages"
  MODEL   = "claude-opus-4-6"
  MAX_TOKENS = 4096

  SYSTEM_PROMPT = <<~PROMPT.freeze
    당신은 SEO/AEO 최적화 전문 한국어 콘텐츠 작성자입니다.
    바이브코딩, 부업, 사업화 도메인의 실용적인 글을 작성합니다.
    독자는 한국 성인 직장인/프리랜서입니다.
    - 제목: 검색 의도를 반영한 명확한 한국어
    - 본문: H2/H3 구조, 구체적 예시, 행동 가이드
    - SEO: 핵심 키워드 자연스럽게 배치
  PROMPT

  def initialize(topic:, stage:)
    @topic = topic
    @stage = stage  # "outline" | "body"
  end

  def call
    response = Faraday.post(API_URL,
      {
        model:      MODEL,
        max_tokens: MAX_TOKENS,
        system:     SYSTEM_PROMPT,
        messages:   [{ role: "user", content: prompt_for_stage }]
      }.to_json,
      {
        "anthropic-api-key"    => ENV.fetch("ANTHROPIC_API_KEY"),
        "anthropic-version"    => "2023-06-01",
        "Content-Type"         => "application/json"
      }
    )

    raise ApiError, "Anthropic API 오류: #{response.status}" unless response.success?
    JSON.parse(response.body).dig("content", 0, "text")
  rescue Faraday::Error => e
    raise ApiError, "네트워크 오류: #{e.message}"
  end

  private

  def prompt_for_stage
    case @stage
    when "outline"
      "다음 주제로 블로그 글 개요(H2 섹션 5-7개)를 작성해주세요: #{@topic}"
    when "body"
      "다음 개요를 바탕으로 완성된 본문을 작성해주세요 (마크다운 형식):\n\n#{@topic}"
    end
  end
end
```

```erb
<%# app/views/admin/ai_drafts/create.turbo_stream.erb %>
<%= turbo_stream.update "ai-result-area" do %>
  <div class="bg-tv-cream rounded-card p-4 mt-4">
    <p class="text-sm font-bold mb-2">AI 초안 결과</p>
    <pre class="whitespace-pre-wrap text-sm"><%= @result %></pre>
    <button type="button"
            class="mt-3 text-sm bg-tv-gold text-tv-black rounded-pill px-4 py-2 font-bold"
            data-action="click->ai-draft#applyToEditor">
      에디터에 적용
    </button>
  </div>
<% end %>
```

```javascript
// app/javascript/controllers/ai_draft_controller.js
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["topicInput", "stageInput", "generateBtn"]
  static values  = { editorInputId: String }

  async generate(event) {
    event.preventDefault()
    this.generateBtnTarget.disabled = true
    this.generateBtnTarget.textContent = "생성 중..."

    const response = await fetch("/admin/ai_drafts", {
      method: "POST",
      headers: {
        "Content-Type":  "application/json",
        "X-CSRF-Token":  document.querySelector('[name="csrf-token"]').content,
        "Accept":        "text/vnd.turbo-stream.html"
      },
      body: JSON.stringify({
        topic: this.topicInputTarget.value,
        stage: this.stageInputTarget.value
      })
    })

    const html = await response.text()
    Turbo.renderStreamMessage(html)

    this.generateBtnTarget.disabled = false
    this.generateBtnTarget.textContent = "AI 초안 생성"
  }

  applyToEditor(event) {
    const resultText = event.target.closest("[data-ai-result]")?.dataset.aiResult
                    || document.querySelector("#ai-result-area pre")?.textContent
    if (!resultText || !this.editorInputIdValue) return

    const input = document.getElementById(this.editorInputIdValue)
    if (input) {
      input.value = resultText
      input.dispatchEvent(new Event("change", { bubbles: true }))
    }
  }
}
```

### Pattern 3: 예약 발행 — Solid Queue 지연 Job

**What:** `posts.publish_at` datetime 컬럼 추가. `after_save` 콜백이 `draft? && publish_at.present?` 조건을 감지해 `PublishPostJob.set(wait_until: publish_at).perform_later(id)` 등록. Solid Queue가 정확한 시각에 Job 실행.

**When to use:** 미래 특정 시각 자동 발행. Solid Queue가 이미 별도 DB로 구성되어 있어 추가 인프라 불필요.

**Trade-offs:** `publish_at` 변경 시 기존 Job을 취소하는 공식 API가 없음. 멱등성으로 처리: Job 실행 시 `draft?` 여부 재확인. 중복 Job은 최대 1개만 추가 실행되고 noop으로 종료.

**Example:**
```ruby
# app/models/post.rb 에 추가
after_save :schedule_publish, if: :should_schedule_publish?

private

def should_schedule_publish?
  draft? && publish_at.present? &&
    (saved_change_to_publish_at? || saved_change_to_status?)
end

def schedule_publish
  PublishPostJob.set(wait_until: publish_at).perform_later(id)
end
```

```ruby
# app/jobs/publish_post_job.rb
class PublishPostJob < ApplicationJob
  queue_as :default

  def perform(post_id)
    post = Post.find_by(id: post_id)
    return unless post
    return if post.published?  # 수동 발행이나 중복 Job 처리 — noop

    post.update!(status: :published)
    Rails.logger.info("예약 발행 완료: Post##{post_id}")
  end
end
```

```ruby
# app/controllers/admin/posts_controller.rb 수정
def post_params
  params.require(:post).permit(
    :title, :body, :category_id, :status, :pinned,
    :seo_title, :seo_description,
    :publish_at   # 신규 추가
  )
end
```

```erb
<%# app/views/admin/posts/_form.html.erb 에 추가 %>
<div>
  <label class="block text-sm font-bold mb-1">예약 발행 시각</label>
  <%= f.datetime_local_field :publish_at,
        class: "w-full px-4 py-3 rounded-2xl border border-gray-300 focus:outline-none",
        min: Time.current.strftime("%Y-%m-%dT%H:%M") %>
  <p class="text-xs text-gray-500 mt-1">비워두면 즉시 발행 (상태가 published일 때)</p>
</div>
```

---

## Data Flow

### 동적 카테고리 흐름

```
Admin: POST /admin/categories
    ↓
Admin::CategoriesController#create
    ↓
Category.create!(record_type: :post, name: "신규게시판", slug: "new-board", position: N)
    ↓ (즉시 반영)
Admin 게시글 작성 폼
    ↓ Category.for_posts → <select> 옵션 동적 렌더링
Post.create!(category_id: selected_category_id, ...)
    ↓
BlogsController#index (기존 라우팅 유지)
    ↓ Post.joins(:category).where(categories: {slug: "blog"}).published
게시판 목록 페이지
```

### AI 초안 흐름

```
Admin 게시글 폼 (주제 텍스트 입력)
    ↓ "AI 초안 생성" 버튼 클릭
Stimulus ai_draft_controller#generate
    ↓ Fetch POST /admin/ai_drafts { topic:, stage: "outline" }
Admin::AiDraftsController#create
    ↓
AiDraftService.new(topic:, stage: "outline").call
    ↓ Faraday POST → Anthropic Messages API
    ↓ (3-8초 대기)
응답 텍스트 @result 저장
    ↓ Turbo Stream: #ai-result-area 업데이트
관리자: 개요 확인/복사
    ↓ "본문 생성" 버튼 (stage: "body", topic: 개요 텍스트)
AiDraftService (2회차)
    ↓ Turbo Stream: #ai-result-area 업데이트
"에디터에 적용" 버튼
    ↓ ai_draft_controller#applyToEditor
rhino-editor hidden input 값 업데이트 → 게시글 저장
```

### 예약 발행 흐름

```
Admin 게시글 폼 (publish_at 입력, status: draft)
    ↓ PATCH /admin/posts/:id
Admin::PostsController#update → post.update!(post_params)
    ↓
Post after_save :schedule_publish 실행
    ↓
PublishPostJob.set(wait_until: publish_at).perform_later(post.id)
    ↓ Solid Queue DB에 scheduled_executions 레코드 생성
    ↓ [publish_at 시각까지 대기]
Solid Queue worker: PublishPostJob#perform(post_id)
    ↓ post.draft? 확인 → post.update!(status: :published)
게시글 공개 완료
```

---

## Integration Points

### 기존 아키텍처와 통합 지점

| 통합 지점 | 변경 방식 | 주의사항 |
|-----------|-----------|----------|
| `Post.enum :category` 제거 | DB 마이그레이션 + 시드 데이터 선행 필요. 마이그레이션에서 기존 integer 값 → category_id 이관 | 마이그레이션 실행 전 `db/seeds/categories.rb` 를 먼저 실행해야 함 |
| `PostsBaseController#index` | `Post.where(category:)` enum 스코프 → `joins(:category).where(categories:{slug:})` | 6개 서브컨트롤러(BlogsController 등)에서 `category` 메서드 → `category_slug` 메서드로 리네임 |
| Admin 폼 카테고리 select | `Post.categories.keys` → `Category.for_posts` | `_form.html.erb` 두 곳(posts, skill_packs) 수정 |
| Solid Queue | `PublishPostJob.set(wait_until:).perform_later` | `config/queue.yml` workers 이미 `"*"` 큐 처리 중. 추가 설정 불필요 |
| Faraday HTTP 클라이언트 | `AiDraftService` 신규 사용 | Gemfile에 `gem "faraday"` 추가 필요. `PaymentService`가 이미 Faraday 사용하는지 확인 후 버전 통일 |
| rhino-editor | AI 생성 텍스트를 hidden input에 삽입 | `input.dispatchEvent(new Event("change"))` 후 rhino-editor가 내용 반영하는지 검증 필요 |
| `routes.rb` | `admin/categories` (CRUD + move_up/move_down), `admin/ai_drafts` (create only) 추가 | LandingSection 라우팅 패턴 참조 |

### 외부 서비스

| 서비스 | 연동 패턴 | 비고 |
|--------|-----------|------|
| Anthropic API | `AiDraftService` — Faraday 직접 호출 | 공식 Ruby SDK 미존재. `PaymentService` Faraday 패턴과 동일 구조. API 키는 `ENV["ANTHROPIC_API_KEY"]`로 관리 |
| Solid Queue | `PublishPostJob.set(wait_until:).perform_later` | 이미 구성됨 (`config/queue.yml`, 별도 DB) |

### 내부 경계

| 경계 | 통신 방식 | 비고 |
|------|-----------|------|
| `Admin::AiDraftsController` ↔ `AiDraftService` | 직접 메서드 호출 | Service가 `AiDraftService::ApiError`를 raise, Controller에서 rescue → Turbo Stream 에러 메시지 |
| `Post` 모델 ↔ `PublishPostJob` | ActiveJob enqueue (after_save) | `saved_change_to_publish_at?`로 불필요한 중복 enqueue 방지 |
| `Admin::CategoriesController` ↔ `PostsBaseController` | `categories` DB 테이블 공유 | 카테고리 삭제 시 FK constraint 위반 방지: 해당 카테고리 게시글이 있으면 삭제 거부 또는 reassign |
| Stimulus `ai_draft_controller` ↔ Turbo | `Turbo.renderStreamMessage(html)` | Turbo가 전역 객체로 노출되어 있어 import 불필요 |

---

## New vs Modified Components

### 신규 생성 (New)

| 파일 | 유형 | 설명 |
|------|------|------|
| `app/models/category.rb` | Model | post/skill_pack 통합 카테고리. `record_type`, `name`, `slug`, `position`, `admin_only` |
| `app/controllers/admin/categories_controller.rb` | Controller | CRUD + `move_up` / `move_down` (LandingSection 패턴 재사용) |
| `app/controllers/admin/ai_drafts_controller.rb` | Controller | `create` 단일 액션. Turbo Stream 응답 전용 |
| `app/services/ai_draft_service.rb` | Service | Anthropic Messages API 호출, 2단계 프롬프트, `ApiError` 커스텀 예외 |
| `app/jobs/publish_post_job.rb` | Job | 멱등성 보장 예약 발행. `draft?` 재확인 후 `status: :published` 업데이트 |
| `app/javascript/controllers/ai_draft_controller.js` | Stimulus | AI 초안 Fetch + `Turbo.renderStreamMessage` + 에디터 적용 |
| `app/views/admin/categories/` | Views | `index`, `new`, `edit`, `_form` (LandingSection 뷰 구조 참조) |
| `app/views/admin/ai_drafts/create.turbo_stream.erb` | View | Turbo Stream 응답. `#ai-result-area` DOM 업데이트 |
| `db/migrate/*_create_categories.rb` | Migration | `categories` 테이블. `record_type`, `name`, `slug`, `position`, `admin_only`, `color` |
| `db/migrate/*_add_category_id_to_posts.rb` | Migration | 데이터 이관 포함. 실행 전 Category 시드 필요 |
| `db/migrate/*_add_category_id_to_skill_packs.rb` | Migration | 데이터 이관 포함 |
| `db/migrate/*_add_publish_at_to_posts.rb` | Migration | `publish_at datetime` nullable 컬럼 |
| `db/seeds/categories.rb` | Seed | Post 6개 + SkillPack 4개 카테고리 초기 데이터 |

### 수정 (Modified)

| 파일 | 변경 내용 |
|------|-----------|
| `app/models/post.rb` | `enum :category` 제거 → `belongs_to :category`. `publish_at` after_save 콜백 추가. `route_key`, `category_name` → slug/delegate 방식으로 교체 |
| `app/models/skill_pack.rb` | `enum :category` 제거 → `belongs_to :category`. `category_name` → delegate |
| `app/controllers/posts_base_controller.rb` | `category` 메서드 → `category_slug` 리네임. `Post.where(category:)` → `joins(:category).where(categories:{slug:})` |
| `app/controllers/blogs_controller.rb` 외 5개 | `category` → `category_slug` 메서드명 변경 |
| `app/controllers/admin/posts_controller.rb` | `post_params`에 `category_id`, `publish_at` 추가 |
| `app/controllers/admin/skill_packs_controller.rb` | `skill_pack_params`에 `category_id` 추가 |
| `app/views/admin/posts/_form.html.erb` | 카테고리 select 소스 `Category.for_posts`로 변경. AI 초안 UI 영역 추가. `publish_at` datetime_local_field 추가 |
| `app/views/admin/skill_packs/_form.html.erb` | 카테고리 select 소스 `Category.for_skill_packs`로 변경 |
| `config/routes.rb` | `admin/categories` (CRUD + member move_up/move_down), `admin/ai_drafts` (collection create) 추가 |
| `Gemfile` | `gem "faraday"` 추가 (기존 미포함 시) |

---

## Suggested Build Order

의존성을 고려한 권장 순서. 각 단계는 독립 완료 후 테스트 가능.

```
1단계: Category 모델 + 마이그레이션 (필수 선행)
    ↓ Post/SkillPack enum 제거, belongs_to 추가
    ↓ 시드 데이터 이관 검증
    ↓ PostsBaseController 쿼리 교체

2단계: Admin 카테고리 동적 관리     3단계: 예약 발행
(1단계 완료 후 병렬 가능)           (1단계 완료 후 병렬 가능)
    ↓                                    ↓
Admin 카테고리 CRUD UI               PublishPostJob + publish_at 필드
순서 변경 (move_up/move_down)        Admin 폼 datetime_local_field

4단계: AI 초안 작성
(2, 3단계와 독립. 1단계 후 시작 가능)
    ↓
AiDraftService + AiDraftsController
Stimulus ai_draft_controller.js
Admin 폼 UI 통합
```

**1단계가 유일한 blocking 의존성.** Post/SkillPack 모델 변경이 모든 하위 작업의 전제 조건.

**2단계와 3단계는 병렬 가능.** 서로 의존성 없음.

**4단계는 Anthropic API 키 환경변수 설정 필요.** 개발 시작 전 `.env`에 `ANTHROPIC_API_KEY` 추가.

---

## Anti-Patterns

### Anti-Pattern 1: enum 유지하면서 Category 모델 병행 운영

**What people do:** `Post.category` integer enum을 유지하면서 Category 모델도 추가하고, 두 값을 동기화하는 before_save 콜백 작성.

**Why it's wrong:** 두 소스가 언제든 불일치할 수 있음. `category_name`, `route_key`, 각종 scope를 두 곳에서 관리해야 해서 복잡도 2배. enum은 런타임에 추가 불가라는 근본 문제가 그대로 남음.

**Do this instead:** 단일 마이그레이션으로 enum 컬럼 완전 제거. Category 레코드 시드로 기존 카테고리 초기화. 단일 진실의 원천 유지.

### Anti-Pattern 2: AI 초안 요청을 전체 페이지 form submit으로 처리

**What people do:** AI 초안 버튼을 hidden input으로 구현해 전체 폼을 서버에 제출하고 전체 페이지를 재렌더링.

**Why it's wrong:** 입력 중인 제목, SEO 필드, 기존 본문 내용이 모두 초기화됨. API 응답 대기(3-8초) 중 Puma 스레드 1개를 점유.

**Do this instead:** Stimulus Fetch + Turbo Stream 패턴. 폼 데이터를 보존하면서 결과 영역만 업데이트.

### Anti-Pattern 3: 예약 발행을 recurring.yml 크론잡으로 구현

**What people do:** `config/recurring.yml`에 1분마다 실행되는 크론잡 추가. `Post.where("publish_at <= ? AND status = 0", Time.current).find_each { |p| p.update!(status: :published) }`.

**Why it's wrong:** 1분마다 전체 미발행 게시글 스캔. 크론 간격으로 정확한 예약 시각 보장 안 됨(최대 1분 지연). Solid Queue의 `set(wait_until:)` 기능이 이 문제를 정확히 해결함.

**Do this instead:** `PublishPostJob.set(wait_until: publish_at).perform_later(id)`. Solid Queue가 개별 레코드를 정확한 시각에 실행.

### Anti-Pattern 4: AI 초안에 Action Cable 사용

**What people do:** 실시간 스트리밍 응답을 위해 Action Cable 채널 추가. `ActionCable.server.broadcast` 로 타이핑 효과 구현.

**Why it's wrong:** Solid Cable이 이미 설정되어 있지만, 1인 운영 플랫폼에서 AI 스트리밍 채널 구현은 복잡도 대비 UX 향상 미미. 2단계(개요 확인 후 본문) UX가 스트리밍 없이도 충분한 체감 품질 제공.

**Do this instead:** 단계형 Turbo Stream 응답. 1회차에 개요, 2회차에 본문. 각 요청이 3-8초로 총 대기가 길지만 단계 확인으로 사용자 참여 유지.

### Anti-Pattern 5: 카테고리 삭제 시 게시글 처리 미고려

**What people do:** Category에 `dependent: :destroy` 또는 `dependent: :nullify` 없이 삭제 라우트만 구현.

**Why it's wrong:** `dependent: :destroy` — 카테고리 삭제 시 게시글 전체 삭제 (데이터 손실). `dependent: :nullify` — FK NOT NULL constraint 위반 에러.

**Do this instead:** 삭제 전 `posts.count` 확인. 게시글이 있으면 삭제 거부 + 에러 메시지. 또는 대체 카테고리 선택 UI 제공.

---

## Scaling Considerations

| Scale | Architecture Adjustments |
|-------|--------------------------|
| 현재 (1인 운영, 소규모) | 현재 구조로 충분. Solid Queue 1 worker, SQLite WAL |
| AI 기능 사용 빈도 증가 시 | `AiDraftService` 동기 호출이 Puma 스레드 점유. 사용 빈도가 높아지면 Job으로 비동기화 고려 |
| 카테고리 수 증가 시 | `Category.for_posts` 결과를 `Rails.cache.fetch("categories/posts", expires_in: 1.hour)` 캐싱. Solid Cache 이미 구성됨 |
| 예약 발행 건수 증가 시 | Solid Queue `scheduled_executions` 테이블 증가 → 기존 `clear_solid_queue_finished_jobs` 크론잡이 자동 정리 |

---

## Sources

- 기존 코드베이스 직접 분석: `teovibe/app/models/`, `teovibe/app/controllers/admin/`, `teovibe/db/schema.rb` (HIGH confidence)
- `LandingSection#move_up/move_down` 패턴 — 동일 코드베이스 직접 재사용 (HIGH confidence)
- Solid Queue `set(wait_until:).perform_later` — Rails 8.1 기본 내장 ActiveJob 기능 (HIGH confidence)
- Turbo Stream `respond_to format.turbo_stream` + `.turbo_stream.erb` 뷰 패턴 (HIGH confidence)
- Anthropic Messages API REST 엔드포인트 (`POST /v1/messages`) — 공식 문서 기반. Ruby 공식 SDK 미존재, Faraday 직접 호출이 표준 접근 (MEDIUM confidence — Faraday gem Gemfile 포함 여부 실행 전 확인 필요)
- `Turbo.renderStreamMessage(html)` — Turbo JS 공식 API (HIGH confidence)

---

*Architecture research for: TeoVibe v1.1 Admin 고도화 — 동적 카테고리, AI 초안, 예약 발행*
*Researched: 2026-02-28*
