# Phase 6: 카테고리 동적 관리 - Research

**Researched:** 2026-02-28
**Domain:** Rails DB-backed dynamic categories, enum → FK migration, Sortable.js DnD, Turbo Stream
**Confidence:** HIGH

---

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions
- **데이터 이관 전략**: 통합 URL `/posts/:category_slug` 형식으로 통일. 기존 /blogs, /tutorials 등은 리다이렉트 라우트로 처리
- **통합 테이블**: `categories` 테이블 하나에 `record_type` 컬럼(post/skill_pack)으로 구분
- **컨트롤러 통합**: 기존 6개 개별 컨트롤러(BlogsController 등) 삭제, PostsController 하나로 통합. 기존 URL은 리다이렉트
- **Admin UI - 테이블 목록**: LandingSection과 같은 테이블 형식으로 이름/슬러그/게시글수/순서 표시
- **Admin UI - 드래그앤드롭**: Sortable.js로 드래그해서 순서 변경
- **Admin UI - 관리자 전용 토글**: 카테고리 목록에서 인라인 토글 스위치로 바로 전환 (Turbo Stream)
- **Navbar**: Category.ordered에서 전체 로드, `visible_in_nav` 토글로 노출 여부 설정
- **삭제 정책**: 게시글이 있는 카테고리는 삭제 불가. "게시글 N개가 있어 삭제할 수 없습니다" 메시지

### Claude's Discretion
- 마이그레이션 SQL 세부 구현 (enum → FK 매핑)
- Admin 폼 레이아웃 세부 디자인
- Sortable.js Stimulus 컨트롤러 구조
- 리다이렉트 라우트 세부 설정

### Deferred Ideas (OUT OF SCOPE)
없음 — 논의가 페이즈 범위 내에서 유지됨
</user_constraints>

---

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|-----------------|
| CATM-01 | Admin이 게시판 카테고리를 생성할 수 있다 (이름, 슬러그, 설명) | Category 모델 + Admin::CategoriesController#new/create |
| CATM-02 | Admin이 게시판 카테고리를 수정/삭제할 수 있다 | edit/update/destroy + 삭제 전 posts_count 검증 |
| CATM-03 | Admin이 게시판 카테고리 순서를 드래그앤드롭으로 변경할 수 있다 | Sortable.js + Stimulus + PATCH /reorder 엔드포인트 |
| CATM-04 | Admin이 카테고리별 '관리자 전용 작성' 토글을 설정할 수 있다 | `admin_only` boolean 컬럼 + Turbo Stream 인라인 토글 |
| CATM-05 | 관리자 전용 카테고리는 일반 사용자 게시글 작성 시 선택지에서 숨겨진다 | PostsController 폼 렌더링 시 admin_only 필터 적용 |
| CATM-06 | Admin이 스킬팩 카테고리를 CRUD + 순서 변경할 수 있다 | 동일 Category 모델 record_type=skill_pack으로 처리 |
</phase_requirements>

---

## Summary

이 페이즈의 핵심 난이도는 **데이터 마이그레이션**이다. 현재 Post와 SkillPack 모두 integer enum 컬럼으로 카테고리를 저장하고 있으며, 이를 `categories` 테이블을 참조하는 FK로 전환해야 한다. 마이그레이션 중 기존 데이터 무결성이 가장 위험한 단계다.

두 번째 핵심은 **라우팅 통합**이다. 기존 6개 개별 컨트롤러(BlogsController, TutorialsController 등)를 단일 PostsController로 통합하면서, SEO URL을 유지하기 위해 기존 경로를 리다이렉트로 처리해야 한다. STATE.md에서 "SEO URL 파괴 금지"가 명시적 제약으로 등록되어 있다.

세 번째는 **Sortable.js DnD** 구현이다. 현재 프로젝트에 Sortable.js가 미설치 상태로, pnpm으로 추가가 필요하다. Stimulus 컨트롤러와 연동하여 position 배열을 서버로 PATCH 전송하는 패턴을 사용한다.

**Primary recommendation:** Domain 레이어(Category 모델) → 마이그레이션(enum→FK) → Admin UI → 라우팅 통합 순으로 구현. 마이그레이션은 반드시 트랜잭션 내에서 slug 기반 매핑으로 수행.

---

## Standard Stack

### Core
| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| Rails ActiveRecord | 8.x (현재 프로젝트) | Category 모델, 마이그레이션, FK | 프로젝트 기반 |
| turbo-rails | 8.0.23 (현재 설치됨) | Turbo Stream 인라인 토글 | 이미 사용 중 |
| stimulus-rails | 현재 설치됨 | Sortable.js 연동 컨트롤러 | 이미 사용 중 |
| Sortable.js | 1.15.x | 드래그앤드롭 순서 변경 | 경량, Stimulus 친화적 |

### Supporting
| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| vite_rails | 현재 설치됨 | JS 번들링 | Sortable.js pnpm add 후 import |

### Alternatives Considered
| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| Sortable.js | acts_as_list gem | Sortable.js는 프론트엔드 DnD, acts_as_list는 서버사이드만. DnD 요구사항에는 Sortable.js 필요 |
| 단일 categories 테이블 | posts_categories + skill_pack_categories 분리 | record_type 방식이 LandingSection 패턴과 일관성 유지 |

**Installation:**
```bash
cd /Users/jaehohan/Desktop/keep-going/teo-vibe/teovibe
pnpm add sortablejs
```

---

## Architecture Patterns

### Category 모델 구조
```ruby
# app/models/category.rb
class Category < ApplicationRecord
  enum :record_type, { post: 0, skill_pack: 1 }

  has_many :posts, foreign_key: :category_id         # record_type = post
  has_many :skill_packs, foreign_key: :category_id   # record_type = skill_pack

  validates :name, presence: true
  validates :slug, presence: true, uniqueness: { scope: :record_type }

  scope :ordered, -> { order(position: :asc) }
  scope :for_posts, -> { where(record_type: :post) }
  scope :for_skill_packs, -> { where(record_type: :skill_pack) }
  scope :visible_in_nav, -> { where(visible_in_nav: true) }

  before_destroy :check_associated_records

  # LandingSection 패턴 그대로 재사용
  def move_up
    above = Category.where(record_type: record_type).where("position < ?", position).order(position: :desc).first
    return unless above
    above.position, self.position = self.position, above.position
    Category.transaction { above.save!; save! }
  end

  def move_down
    below = Category.where(record_type: record_type).where("position > ?", position).order(position: :asc).first
    return unless below
    below.position, self.position = self.position, below.position
    Category.transaction { below.save!; save! }
  end

  private

  def check_associated_records
    count = record_type == "post" ? posts.count : skill_packs.count
    if count > 0
      errors.add(:base, "게시글 #{count}개가 있어 삭제할 수 없습니다")
      throw :abort
    end
  end
end
```

### 마이그레이션 패턴 (enum → FK)
```ruby
# db/migrate/XXXXXX_create_categories_and_migrate_post_category.rb

class CreateCategoriesAndMigratePostCategory < ActiveRecord::Migration[8.0]
  def up
    # 1. categories 테이블 생성
    create_table :categories do |t|
      t.string :name, null: false
      t.string :slug, null: false
      t.text :description
      t.integer :record_type, null: false, default: 0
      t.integer :position, null: false, default: 0
      t.boolean :admin_only, null: false, default: false
      t.boolean :visible_in_nav, null: false, default: true
      t.timestamps
    end
    add_index :categories, [:slug, :record_type], unique: true

    # 2. 기존 Post enum → Category 레코드 시드 (slug 기반 - ID 가정 금지)
    post_categories = [
      { name: "블로그", slug: "blog", position: 0 },
      { name: "튜토리얼", slug: "tutorial", position: 1 },
      { name: "자유게시판", slug: "free-board", position: 2 },
      { name: "Q&A", slug: "qna", position: 3 },
      { name: "포트폴리오", slug: "portfolio", position: 4 },
      { name: "공지사항", slug: "notice", position: 5, admin_only: true },
    ]
    post_categories.each do |attrs|
      execute <<~SQL
        INSERT INTO categories (name, slug, record_type, position, admin_only, visible_in_nav, created_at, updated_at)
        VALUES ('#{attrs[:name]}', '#{attrs[:slug]}', 0, #{attrs[:position]}, #{attrs[:admin_only] || false}, true, datetime('now'), datetime('now'))
      SQL
    end

    # 3. posts에 category_id 컬럼 추가
    add_column :posts, :category_id, :integer

    # 4. slug 기반으로 기존 enum 값 → FK 매핑 (STATE.md 결정: slug 기반)
    enum_to_slug = { 0 => "blog", 1 => "tutorial", 2 => "free-board", 3 => "qna", 4 => "portfolio", 5 => "notice" }
    enum_to_slug.each do |enum_val, slug|
      execute <<~SQL
        UPDATE posts
        SET category_id = (SELECT id FROM categories WHERE slug = '#{slug}' AND record_type = 0)
        WHERE category = #{enum_val}
      SQL
    end

    # 5. posts.category (enum) 컬럼 제거 -- SQLite는 rename 후 재생성 필요
    # NOTE: SQLite는 DROP COLUMN을 Rails 8+에서 지원
    remove_column :posts, :category

    # 6. SkillPack 동일 처리
    skill_pack_categories = [
      { name: "템플릿", slug: "template", position: 0 },
      { name: "컴포넌트", slug: "component", position: 1 },
      { name: "가이드", slug: "guide", position: 2 },
      { name: "툴킷", slug: "toolkit", position: 3 },
    ]
    skill_pack_categories.each do |attrs|
      execute <<~SQL
        INSERT INTO categories (name, slug, record_type, position, admin_only, visible_in_nav, created_at, updated_at)
        VALUES ('#{attrs[:name]}', '#{attrs[:slug]}', 1, #{attrs[:position]}, false, true, datetime('now'), datetime('now'))
      SQL
    end

    add_column :skill_packs, :category_id, :integer
    enum_to_slug_sp = { 0 => "template", 1 => "component", 2 => "guide", 3 => "toolkit" }
    enum_to_slug_sp.each do |enum_val, slug|
      execute <<~SQL
        UPDATE skill_packs
        SET category_id = (SELECT id FROM categories WHERE slug = '#{slug}' AND record_type = 1)
        WHERE category = #{enum_val}
      SQL
    end
    remove_column :skill_packs, :category
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
```

### Admin::CategoriesController 패턴
```ruby
# app/controllers/admin/categories_controller.rb
module Admin
  class CategoriesController < BaseController
    before_action :set_category, only: %i[edit update destroy move_up move_down toggle_admin_only toggle_visible_in_nav]

    def index
      @post_categories = Category.for_posts.ordered
      @skill_pack_categories = Category.for_skill_packs.ordered
    end

    def reorder
      # Sortable.js가 보내는 positions 배열 처리
      params[:positions].each_with_index do |id, index|
        Category.where(id: id).update_all(position: index)
      end
      head :ok
    end

    def toggle_admin_only
      @category.update!(admin_only: !@category.admin_only)
      respond_to do |format|
        format.turbo_stream
        format.html { redirect_to admin_categories_path }
      end
    end

    def toggle_visible_in_nav
      @category.update!(visible_in_nav: !@category.visible_in_nav)
      respond_to do |format|
        format.turbo_stream
        format.html { redirect_to admin_categories_path }
      end
    end

    def destroy
      if @category.destroy
        redirect_to admin_categories_path, notice: "카테고리가 삭제되었습니다.", status: :see_other
      else
        redirect_to admin_categories_path, alert: @category.errors.full_messages.join(", "), status: :see_other
      end
    end

    # ... new, create, edit, update, move_up, move_down (LandingSection 패턴 동일)
  end
end
```

### Sortable.js Stimulus 컨트롤러
```javascript
// app/javascript/controllers/sortable_controller.js
import { Controller } from "@hotwired/stimulus"
import Sortable from "sortablejs"

export default class extends Controller {
  static values = { url: String }

  connect() {
    this.sortable = Sortable.create(this.element, {
      animation: 150,
      onEnd: this.onEnd.bind(this)
    })
  }

  disconnect() {
    this.sortable?.destroy()
  }

  onEnd() {
    const positions = [...this.element.querySelectorAll("[data-id]")].map(el => el.dataset.id)
    fetch(this.urlValue, {
      method: "PATCH",
      headers: {
        "Content-Type": "application/json",
        "X-CSRF-Token": document.querySelector('meta[name="csrf-token"]')?.content
      },
      body: JSON.stringify({ positions })
    })
  }
}
```

### 라우팅 패턴
```ruby
# config/routes.rb

# 통합 라우트
resources :posts, param: :slug, only: %i[index show new create edit update destroy]
# /posts/:category_slug 형식
get "posts/:category_slug", to: "posts#index", as: :category_posts

# SEO 유지를 위한 리다이렉트 (기존 URL 보존 - STATE.md 제약)
get "/blogs", to: redirect("/posts/blog"), as: :blogs
get "/blogs/:id", to: redirect { |params, req| "/posts/#{params[:id]}" }
get "/tutorials", to: redirect("/posts/tutorial"), as: :tutorials
get "/tutorials/:id", to: redirect { |params, req| "/posts/#{params[:id]}" }
get "/free-boards", to: redirect("/posts/free-board"), as: :free_boards
get "/free-boards/:id", to: redirect { |params, req| "/posts/#{params[:id]}" }
get "/qnas", to: redirect("/posts/qna"), as: :qnas
get "/qnas/:id", to: redirect { |params, req| "/posts/#{params[:id]}" }
get "/portfolios", to: redirect("/posts/portfolio"), as: :portfolios
get "/portfolios/:id", to: redirect { |params, req| "/posts/#{params[:id]}" }
get "/notices", to: redirect("/posts/notice"), as: :notices
get "/notices/:id", to: redirect { |params, req| "/posts/#{params[:id]}" }

# Admin
namespace :admin do
  resources :categories, only: %i[index new create edit update destroy] do
    member do
      patch :move_up
      patch :move_down
      patch :toggle_admin_only
      patch :toggle_visible_in_nav
    end
    collection do
      patch :reorder
    end
  end
end
```

### Recommended Project Structure
```
app/
├── models/
│   └── category.rb                           # 신규: record_type enum
├── controllers/
│   ├── posts_controller.rb                   # 통합 (category_slug 기반 필터)
│   ├── admin/
│   │   └── categories_controller.rb          # 신규
│   └── [삭제] blogs_controller.rb, tutorials_controller.rb 등 6개
├── views/
│   ├── admin/categories/
│   │   ├── index.html.erb                    # 신규
│   │   ├── _category_row.html.erb            # Turbo Frame용
│   │   ├── new.html.erb
│   │   ├── edit.html.erb
│   │   └── toggle_admin_only.turbo_stream.erb
│   └── shared/
│       └── _navbar.html.erb                  # 수정: 동적 루프
└── javascript/
    └── controllers/
        └── sortable_controller.js            # 신규

db/migrate/
└── XXXXXX_create_categories_and_migrate.rb   # 신규
```

### Anti-Patterns to Avoid
- **마이그레이션에서 ID 기반 enum 매핑**: `SET category_id = 1 WHERE category = 0` 방식은 auto-increment ID가 1부터 시작한다는 보장이 없음. 반드시 slug 기반 서브쿼리로 매핑
- **Post.category enum 삭제 전 데이터 검증 누락**: 마이그레이션 전후 레코드 수 일치 확인 필수
- **6개 컨트롤러 파일 삭제 후 routes 미정리**: 라우팅 에러 발생. routes.rb 수정 → 컨트롤러 삭제 순서 지킬 것
- **Sortable.js onEnd에서 CSRF 토큰 누락**: Turbo가 없는 fetch 요청은 수동으로 CSRF 헤더 포함 필요

---

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| DnD 순서 변경 | 커스텀 마우스이벤트 리스너 | Sortable.js | 터치 지원, 애니메이션, 브라우저 호환성 처리 |
| 인라인 토글 업데이트 | 폼 submit + 페이지 새로고침 | Turbo Stream | 이미 프로젝트에 설치됨, 깜빡임 없는 UI |
| position 재정렬 | Ruby 루프 | SQL UPDATE 배치 | N+1 방지 |

**Key insight:** LandingSection의 move_up/move_down 패턴이 이미 검증되어 있으므로, 카테고리도 동일 패턴을 재사용. Sortable.js DnD는 해당 패턴 위에 UX 개선 레이어로 추가.

---

## Common Pitfalls

### Pitfall 1: SQLite DROP COLUMN 지원
**What goes wrong:** SQLite는 오랫동안 ALTER TABLE DROP COLUMN을 지원하지 않았음
**Why it happens:** Rails 7.0 이전에는 SQLite에서 컬럼 삭제가 지원되지 않았음
**How to avoid:** Rails 8.x + SQLite 3.35+ 환경에서는 `remove_column` 직접 사용 가능. 프로덕션 DB 버전 확인 필요
**Warning signs:** `ActiveRecord::IrreversibleMigration` 또는 `NotImplementedError`

### Pitfall 2: Post.route_key 및 category_name 메서드 의존성
**What goes wrong:** 기존 `post.rb`의 `route_key`, `category_name` 메서드가 enum 문자열에 의존. enum 제거 후 이 메서드들이 nil 반환
**Why it happens:** `when "blog"` 등 enum 심볼 비교가 `post.category` 반환값에 의존
**How to avoid:** enum 제거 후 `post.category` → `post.category.slug` 등으로 변경. 마이그레이션과 동시에 모델 메서드 업데이트 필요
**Warning signs:** 뷰에서 nil 노출 또는 라우팅 에러

### Pitfall 3: helpers / sitemap의 카테고리 참조
**What goes wrong:** `application_helper.rb`, `seo_helper.rb`, `config/sitemap.rb`에 하드코딩된 카테고리 참조가 마이그레이션 후 오류 발생
**Why it happens:** 이 파일들이 Post.blog, Post.tutorial 등 enum 스코프 메서드를 직접 호출
**How to avoid:** 마이그레이션 후 이 파일들을 검색하여 Category.find_by(slug:) 방식으로 교체
**Warning signs:** `NoMethodError: undefined method 'blog' for Post:Class`

### Pitfall 4: Navbar 캐싱
**What goes wrong:** 카테고리 변경 후 Navbar가 캐시된 구버전을 계속 보여줌
**Why it happens:** fragment 캐싱이 Category 변경을 추적하지 않는 경우
**How to avoid:** Navbar partial에 `cache ["navbar", Category.maximum(:updated_at)]` 적용 또는 캐싱 없이 매 요청 쿼리
**Warning signs:** Admin에서 변경했는데 사용자 화면에 반영 안됨

### Pitfall 5: 마이그레이션 롤백 불가
**What goes wrong:** `irreversible` 마이그레이션으로 인해 롤백 불가
**Why it happens:** enum → FK 전환은 원본 데이터를 변형하므로 역방향이 불명확
**How to avoid:** 마이그레이션 전 DB 스냅샷 또는 데이터 백업. `down` 메서드에 `raise ActiveRecord::IrreversibleMigration`으로 명시

---

## Code Examples

### Turbo Stream 토글 응답
```erb
<%# app/views/admin/categories/toggle_admin_only.turbo_stream.erb %>
<%= turbo_stream.replace "category_#{@category.id}_admin_only" do %>
  <%= render "admin_only_toggle", category: @category %>
<% end %>
```

### Admin index 뷰 DnD 연결
```erb
<%# Sortable.js 연결: data-controller와 data-id 필수 %>
<tbody data-controller="sortable"
       data-sortable-url-value="<%= reorder_admin_categories_path %>">
  <% @post_categories.each do |category| %>
    <tr data-id="<%= category.id %>">
      <td><%= category.name %></td>
      <td><%= category.slug %></td>
      <td><%= category.posts.count %></td>
      <%# 토글 스위치 %>
    </tr>
  <% end %>
</tbody>
```

### PostsController 통합 패턴
```ruby
class PostsController < ApplicationController
  def index
    @category = Category.find_by!(slug: params[:category_slug], record_type: :post)
    @posts = @category.posts.published.pinned_first.page(params[:page])
  end
end
```

### 일반 사용자 카테고리 선택지 필터 (CATM-05)
```ruby
# 폼 헬퍼에서 admin_only 카테고리 제외
def available_post_categories
  if Current.user&.admin?
    Category.for_posts.ordered
  else
    Category.for_posts.where(admin_only: false).ordered
  end
end
```

---

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| Post.enum :category | Category 모델 FK | 이 페이즈에서 변경 | 런타임 카테고리 추가/수정 가능 |
| 6개 개별 컨트롤러 | PostsController 단일 통합 | 이 페이즈에서 변경 | 코드 중복 제거, 유지보수성 향상 |
| 하드코딩 Navbar 링크 | Category.ordered 동적 루프 | 이 페이즈에서 변경 | 카테고리 추가 시 자동 반영 |

---

## Open Questions

1. **SQLite 환경에서 DROP COLUMN 버전 확인**
   - What we know: Rails 8.x는 SQLite 3.35+ 필요
   - What's unclear: 프로덕션 서버의 SQLite 버전
   - Recommendation: 마이그레이션 전 `SELECT sqlite_version()` 실행 확인

2. **Post slug 기반 라우팅 충돌 가능성**
   - What we know: Post.slug는 `{id}-{title}` 형식, category_slug는 단어
   - What's unclear: `/posts/blog` 가 카테고리 라우트인지 포스트 slug 라우트인지 충돌 가능
   - Recommendation: 카테고리 라우트를 `/c/:category_slug` 또는 posts routes 앞에 배치하여 우선순위 확보

3. **기존 PostsBaseController 제거 타이밍**
   - What we know: PostsBaseController가 category별 분기 로직 포함
   - What's unclear: 6개 컨트롤러 삭제 후 상속 체인 영향
   - Recommendation: 6개 컨트롤러 먼저 삭제, PostsBaseController 마지막에 제거

---

## Sources

### Primary (HIGH confidence)
- 프로젝트 코드 직접 분석: `app/models/landing_section.rb` - move_up/move_down 패턴
- 프로젝트 코드 직접 분석: `app/controllers/admin/landing_sections_controller.rb` - Admin CRUD 패턴
- 프로젝트 코드 직접 분석: `app/models/post.rb`, `app/models/skill_pack.rb` - 현재 enum 구조
- 프로젝트 코드 직접 분석: `package.json` - Sortable.js 미설치 확인, Stimulus/Turbo 설치 확인

### Secondary (MEDIUM confidence)
- STATE.md: "slug 기반 SQL 매핑 사용" 결정 사항
- CONTEXT.md: 모든 구현 결정 사항

---

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH - 현재 프로젝트 패키지/gem 직접 확인
- Architecture: HIGH - LandingSection 기존 패턴 재사용, 변형 최소화
- Pitfalls: HIGH - 코드베이스 직접 분석으로 의존성 파악
- Migration safety: MEDIUM - SQLite 버전 의존성은 런타임 확인 필요

**Research date:** 2026-02-28
**Valid until:** 2026-03-28 (안정적 스택, 30일 유효)
