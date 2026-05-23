# TeoVibe - 바이브코딩 브랜딩 & 커뮤니티 플랫폼

## 프로젝트 개요

바이브코딩 사업화 과정과 노하우를 담는 블로그형 커뮤니티 사이트.
강의, 컨설팅, 스킬팩 판매, 포트폴리오 전시를 하나의 플랫폼에서 운영한다.
VibeLabs.kr를 레퍼런스로 하되, 1인 브랜딩에 최적화된 구조로 만든다.

운영자는 비개발자 1인 사업자이다.
유지보수 부담을 최소화하고, 운영 자동화에 집중한다.

---

## 기술 스택 (1인 운영 최적화)

### 핵심 원칙
- 외부 gem 의존성 최소화 (업데이트/호환성 문제 예방)
- Rails 빌트인 기능 최대 활용 (공식 지원 = 장기 안정성)
- 관리 포인트가 적은 인프라 선택
- "바이브코딩으로 빌드, 바이브코딩으로 유지보수" 가능한 수준 유지

### 프레임워크 & 백엔드
- Ruby on Rails 8.1 (최신 LTS)
- Puma (Rails 기본 웹서버)
- SQLite + Litestream (프로덕션) -- PostgreSQL 대신 선택
  * 이유: 별도 DB 서버 관리 불필요, 백업은 Litestream으로 S3에 자동 스트리밍
  * Rails 8부터 SQLite 프로덕션 사용이 공식 지원됨
  * 1인 커뮤니티 트래픽에 충분한 성능
- Solid Queue (백그라운드 잡) -- Redis/Sidekiq 대신 선택
  * 이유: SQLite 기반으로 동작, 별도 Redis 서버 불필요
  * Rails 8 기본 포함
- Solid Cache (캐싱) -- Redis 대신 선택
  * 이유: 마찬가지로 DB 기반, 추가 인프라 제로
- Solid Cable (WebSocket/Action Cable) -- Redis 대신 선택

### 프론트엔드
- Hotwire (Turbo + Stimulus) -- React/Vue 없이 동적 UI
- Propshaft + Import Maps -- 번들러 제로 (webpack, esbuild 불필요)
- Tailwind CSS 4 -- 스타일링
- Remix Icon (CDN) -- 아이콘
- Pretendard (CDN) -- 한글 폰트

### 인증 (Devise 사용하지 않음)
- Rails 8 빌트인 인증 제너레이터 (`bin/rails generate authentication`)
  * 이유: Devise는 Rails 업그레이드 시 호환성 문제가 반복됨
  * 빌트인은 내 코드로 생성되어 완전한 제어 가능
  * Hotwire/Turbo와 기본 호환
- OmniAuth + omniauth-google-oauth2 + omniauth-kakao -- 소셜 로그인
- omniauth-rails_csrf_protection -- CSRF 방어
- ConnectedService 모델로 소셜 계정 연결 관리

### 리치 텍스트 에디터
- ActionText (Trix) -- Rails 기본 포함
- 추후 필요 시 Tiptap 확장 가능

### 파일 업로드
- ActiveStorage -- Rails 기본 포함
- 로컬 디스크 저장 (Docker 볼륨 마운트)
- 추후 필요 시 S3/R2 연동

### 배포 & 인프라
- Kamal 2 -- Rails 8 기본 포함 배포 도구
  * `kamal deploy` 한 줄로 배포
  * Docker 기반, 제로 다운타임
  * Heroku 같은 편의성 + 직접 서버의 비용 효율
- Hetzner CAX11 (월 ~4유로) 또는 DigitalOcean Droplet ($6/월)
  * 1인 커뮤니티에 충분한 사양
- Cloudflare -- DNS + CDN + SSL 자동 + DDoS 방어 (무료)
- Docker -- 컨테이너화 (Kamal이 자동 관리)
- Litestream -- SQLite 자동 백업 → S3/R2

### 모니터링 & 분석
- Rails Server Timing 헤더 (기본 활성화)
- Google Analytics
- Sentry 또는 Honeybadger (에러 트래킹, 무료 티어)

### 최종 인프라 구성도

```
[사용자] → [Cloudflare CDN/SSL] → [Hetzner VPS]
                                      ├── Docker (Kamal 관리)
                                      │   ├── Rails 8 + Puma
                                      │   ├── SQLite (앱 내장)
                                      │   ├── Solid Queue (잡)
                                      │   └── Solid Cache (캐시)
                                      └── Litestream → S3 (자동 백업)

관리 포인트: VPS 1대 + Cloudflare (무료) + S3 버킷 (백업)
월 비용: ~$7-10 (VPS + S3 소량)
```

---

## 응답 규칙

- 한국어로 응답. 코드 주석도 한국어
- 간결하게. 불필요한 설명 생략
- 코드 먼저, 설명은 간단히
- 이모지 사용 금지
- 불확실하면 질문
- gem 추가 시 반드시 이유를 설명하고 확인받을 것

## Git 규칙

- 커밋 메시지: 한국어, conventional commits
  - "feat: 게시판 CRUD 구현"
  - "test: 로그인 인증 테스트 추가"
  - "fix: 댓글 정렬 오류 수정"
- 커밋은 자주, 푸시는 기능 완료 또는 테스트 통과 후
- 민감 정보 절대 커밋 금지. Rails credentials 사용

## 테스트 규칙

- Minitest + Capybara (Rails 기본)
- 모델, 컨트롤러, 시스템 테스트 작성
- `bin/rails test` 통과 후 커밋

---

# Phase 1: 프로젝트 초기화 및 인증

## 1-1. Rails 8 프로젝트 생성

```bash
rails new teovibe --css tailwind --database sqlite3
cd teovibe
```

확인사항:
- Propshaft + Import Maps 기본 설정
- Kamal config (config/deploy.yml) 생성 확인
- Dockerfile 생성 확인
- Solid Queue, Solid Cache, Solid Cable 설정 확인
- 기본 health check: GET /up

## 1-2. 인증 시스템

```bash
# Rails 8 빌트인 인증 생성
bin/rails generate authentication
```

이 명령으로 생성되는 것:
- User 모델 (email_address, password_digest)
- Session 모델 (user_id, ip_address, user_agent)
- Current 모델 (CurrentAttributes)
- SessionsController (로그인/로그아웃)
- PasswordsController (비밀번호 리셋)
- Authentication concern

### User 모델 확장 (마이그레이션 추가)

```
users 테이블 추가 컬럼:
- nickname: string (not null)
- avatar_url: string
- bio: text
- role: integer (default: 0) # 0: member, 1: admin
- points: integer (default: 0)
- level: integer (default: 1)
- posts_count: integer (default: 0)
- comments_count: integer (default: 0)
```

### 소셜 로그인 (OmniAuth)

```ruby
# Gemfile
gem 'omniauth'
gem 'omniauth-google-oauth2'
gem 'omniauth-kakao'
gem 'omniauth-rails_csrf_protection'
```

ConnectedService 모델:
```
connected_services 테이블:
- user_id: references
- provider: string (not null)
- uid: string (not null)
- unique index: [provider, uid]
```

OmniAuth::SessionsController에서:
1. ConnectedService로 기존 유저 찾기
2. 없으면 email로 기존 유저 찾기
3. 없으면 새 유저 생성
4. Rails 8 빌트인 세션 시스템으로 로그인 처리

### 라우트

```ruby
# config/routes.rb

# 인증 (빌트인)
resource :session
resources :passwords, param: :token

# 소셜 로그인
post '/auth/:provider/callback', to: 'omniauth/sessions#create'
get '/auth/failure', to: 'omniauth/sessions#failure'

# 회원가입 (빌트인에 없으므로 직접 추가)
resource :registration, only: [:new, :create]

# 편의 라우트
get '/login', to: 'sessions#new'
delete '/logout', to: 'sessions#destroy'

# 프로필
get '/me', to: 'profiles#show'
get '/me/posts', to: 'profiles#posts'
get '/me/comments', to: 'profiles#comments'
get '/me/point_logs', to: 'profiles#point_logs'
get '/profile/edit', to: 'profiles#edit'
patch '/profile', to: 'profiles#update'
```

---

# Phase 2: 블로그 & 커뮤니티 게시판

## 2-1. 게시판 시스템

단일 Post 모델 + category enum으로 모든 게시판 관리:

```
posts 테이블:
- title: string (not null)
- body: text (ActionText rich text)
- category: integer (not null)
  # 0: blog (내 글/칼럼)
  # 1: tutorial (바이브코딩 튜토리얼)
  # 2: free_board (자유게시판)
  # 3: qna (Q&A)
  # 4: portfolio (포트폴리오 전시)
  # 5: notice (공지사항)
- user_id: references
- slug: string (unique)
- published: boolean (default: false)
- pinned: boolean (default: false)
- views_count: integer (default: 0)
- likes_count: integer (default: 0)
- comments_count: integer (default: 0)
- tags: string
```

### 컨트롤러 패턴

```ruby
# 공통 로직을 가진 베이스 컨트롤러
class PostsBaseController < ApplicationController
  private
  def scope
    Post.where(category: self.class::CATEGORY).published
  end
end

class BlogsController < PostsBaseController
  CATEGORY = :blog
end

class TutorialsController < PostsBaseController
  CATEGORY = :tutorial
end
# ... 나머지도 동일 패턴
```

### 라우트

```ruby
resources :blogs, only: [:index, :show]
resources :tutorials, only: [:index, :show]
resources :free_boards
resources :qnas do
  member { post :accept_answer }
end
resources :portfolios
resources :notices
```

## 2-2. 댓글

```
comments 테이블:
- body: text (not null)
- post_id: references
- user_id: references
- parent_id: references (대댓글)
- likes_count: integer (default: 0)
- accepted: boolean (default: false)
```

## 2-3. 좋아요

```
likes 테이블:
- user_id: references
- likeable_type: string
- likeable_id: integer
- unique index: [user_id, likeable_type, likeable_id]
```

polymorphic association. Turbo Stream으로 실시간 업데이트.

## 2-4. 검색

PostgreSQL이 아니므로 SQLite FTS5 또는 LIKE 검색:

```ruby
# 간단한 LIKE 검색 (1인 커뮤니티 규모에 충분)
Post.published.where("title LIKE :q OR body LIKE :q", q: "%#{params[:q]}%")
```

---

# Phase 3: 랜딩 페이지 & 관리자

## 3-1. 동적 랜딩 페이지

```
landing_sections 테이블:
- title: string
- subtitle: text
- section_type: integer
  # 0: hero, 1: features, 2: testimonials, 3: cta, 4: custom
- content: text
- position: integer
- active: boolean (default: true)
- background_style: string
```

```
section_cards 테이블:
- landing_section_id: references
- title: string
- description: text
- icon: string
- link_url: string
- position: integer
```

position 정렬은 직접 구현 (acts_as_list gem 없이):
```ruby
# LandingSection 모델
scope :ordered, -> { order(:position) }
scope :active, -> { where(active: true) }

def move_up
  above = self.class.where("position < ?", position).order(position: :desc).first
  return unless above
  self.class.transaction do
    above.update!(position: position)
    update!(position: above.position_was)
  end
end
```

## 3-2. Admin 패널

```ruby
namespace :admin do
  root 'dashboard#index'
  resources :landing_sections do
    member { patch :move_up; patch :move_down; patch :toggle_active }
    resources :section_cards
  end
  resources :posts, only: [:index, :show, :update, :destroy]
  resources :users, only: [:index, :show, :update]
  resources :comments, only: [:index, :destroy]
  resources :skill_orders
  resources :inquiries
  get 'analytics', to: 'analytics#index'
end
```

Admin 접근 제어:
```ruby
# app/controllers/admin/base_controller.rb
class Admin::BaseController < ApplicationController
  before_action :require_admin

  private
  def require_admin
    redirect_to root_path, alert: "권한이 없습니다." unless Current.user&.admin?
  end
end
```

---

# Phase 4: 스킬팩 판매

## 4-1. 스킬팩 상품

```
skill_packs 테이블:
- title: string
- description: text (ActionText)
- price: integer (원)
- slug: string
- active: boolean (default: true)
- download_count: integer (default: 0)
```

## 4-2. 주문 & 토큰 다운로드

```
skill_orders 테이블:
- user_id: references
- skill_pack_id: references
- download_token: string (unique, SecureRandom.urlsafe_base64)
- status: integer # 0: pending, 1: paid, 2: delivered
- paid_at: datetime
- delivered_at: datetime
```

파일은 ActiveStorage로 관리.
결제: 1차 수동 확인 (계좌이체) → 추후 PortOne 연동.
다운로드: 토큰 기반 URL로 접근 제어.

```ruby
get 'skills/download/:token', to: 'skill_downloads#show_by_token'
```

---

# Phase 5: 컨설팅 문의

```
inquiries 테이블:
- name: string
- email: string
- company: string
- inquiry_type: integer # 0: consulting, 1: outsourcing, 2: lecture
- budget_range: string
- message: text
- status: integer # 0: new, 1: in_progress, 2: completed
```

```ruby
get '/consulting', to: 'pages#consulting'
resources :inquiries, only: [:new, :create] do
  collection { get :success }
end
```

문의 접수 시 ActionMailer로 관리자 이메일 알림 (Solid Queue로 백그라운드 발송).

---

# Phase 6: 포인트 & 레벨

```
point_logs 테이블:
- user_id: references
- amount: integer
- reason: string
- source_type: string
- source_id: integer
```

ActiveSupport::Concern으로 포인트 로직 분리:

```ruby
module Pointable
  extend ActiveSupport::Concern
  REWARDS = {
    post_create: 10, comment_create: 3,
    post_liked: 2, daily_login: 1, accepted_answer: 15
  }
end
```

---

# Phase 7: 알림 + 검색

```
notifications 테이블:
- user_id: references
- actor_id: references
- action: string
- notifiable_type: string
- notifiable_id: integer
- read_at: datetime
```

Stimulus `notification_dropdown_controller`로 UI.
검색: `GET /search` → SQLite LIKE 쿼리.

---

# Phase 8: SEO + 배포

## 8-1. SEO
- 시맨틱 HTML
- meta 태그 (title, description, og:image)
- sitemap.xml 자동 생성
- robots.txt
- slug 기반 URL

## 8-2. Kamal 배포

```yaml
# config/deploy.yml
service: teovibe
image: your-dockerhub/teovibe

servers:
  web:
    hosts:
      - YOUR_VPS_IP

proxy:
  ssl: true
  host: teovibe.kr

registry:
  username: your-dockerhub-username
  password:
    - KAMAL_REGISTRY_PASSWORD

env:
  secret:
    - RAILS_MASTER_KEY
  clear:
    RAILS_ENV: production
    SOLID_QUEUE_IN_PUMA: true

volumes:
  - teovibe_storage:/rails/storage
```

배포 명령:
```bash
kamal deploy        # 배포
kamal app logs -f   # 로그 확인
kamal rollback      # 롤백
kamal app exec --interactive --reuse "bin/rails console"  # 콘솔
```

## 8-3. 프로덕션 보안 체크리스트

- [ ] config.force_ssl = true
- [ ] RAILS_ENV=production
- [ ] Rails credentials로 시크릿 관리
- [ ] Debug 에러 페이지 비활성화 확인
- [ ] Web Console gem은 development 그룹에만
- [ ] Cloudflare WAF 기본 규칙 활성화

---

# Stimulus 컨트롤러 목록

| 컨트롤러 | 용도 |
|----------|------|
| mobile_menu | 모바일 네비 토글 |
| dropdown | 일반 드롭다운 |
| notification_dropdown | 알림 드롭다운 |
| tabs | 게시판 카테고리 탭 |
| reveal | 토글/아코디언 |
| editor | ActionText 에디터 |
| dismissable | 플래시 메시지 닫기 |
| highlight | 코드 블록 하이라이트 |

---

# 데이터 모델 관계도

```
User (has_secure_password, Rails 8 빌트인)
 ├── has_many :sessions (Rails 8 빌트인)
 ├── has_many :connected_services (소셜 로그인)
 ├── has_many :posts
 ├── has_many :comments
 ├── has_many :likes
 ├── has_many :skill_orders
 ├── has_many :point_logs
 ├── has_many :notifications
 └── has_one_attached :avatar

Post (category enum)
 ├── belongs_to :user (counter_cache: true)
 ├── has_many :comments
 ├── has_many :likes, as: :likeable
 ├── has_rich_text :body
 └── has_many_attached :images

Comment
 ├── belongs_to :user
 ├── belongs_to :post (counter_cache: true)
 ├── belongs_to :parent, optional: true
 ├── has_many :replies
 └── has_many :likes, as: :likeable

ConnectedService
 └── belongs_to :user

LandingSection
 └── has_many :section_cards

SkillPack → has_many :skill_orders
SkillOrder → belongs_to :user, :skill_pack
Inquiry (standalone)
Notification → belongs_to :user, :actor
PointLog → belongs_to :user
```

---

# 외부 gem 목록 (최소한)

```ruby
# Gemfile - 추가 gem (Rails 기본 외)

# 인증
gem 'omniauth'
gem 'omniauth-google-oauth2'
gem 'omniauth-kakao'
gem 'omniauth-rails_csrf_protection'

# 뷰 헬퍼
gem 'pagy'  # 페이지네이션 (경량, 의존성 제로)

# 모니터링 (선택)
gem 'sentry-ruby'
gem 'sentry-rails'
```

총 gem 추가: 6개 (OmniAuth 4 + pagy 1 + sentry 1)
VibeLabs 대비 제거: Devise, Doorkeeper, Chartkick, web-console(production)

---

# 구현 순서

1. Phase 1: `rails new` + 빌트인 인증 + 소셜 로그인
2. Phase 2: 게시판 CRUD + 댓글 + 좋아요
3. Phase 3: 랜딩 페이지 + Admin 패널
4. Phase 4: 스킬팩 판매 + 토큰 다운로드
5. Phase 5: 컨설팅 문의
6. Phase 6: 포인트/레벨
7. Phase 7: 알림 + 검색
8. Phase 8: SEO + Kamal 배포

각 Phase 완료 후 `bin/rails test` 통과 확인하고 커밋/푸시.

---

# 운영 가이드 (비개발자용)

## 일상 운영
- 글 작성/관리: /admin 에서 CRUD
- 스킬팩 주문 확인: /admin/skill_orders
- 문의 확인: /admin/inquiries

## 배포 (코드 수정 후)
```bash
kamal deploy  # 이것만 실행하면 자동 빌드 → 배포 → 헬스체크
```

## 백업
- Litestream이 SQLite를 실시간으로 S3에 백업
- 수동 개입 불필요

## 장애 대응
```bash
kamal app logs -f    # 로그 확인
kamal rollback       # 이전 버전으로 복구
kamal app restart    # 재시작
```

## 비용 구조 (월간)
- VPS (Hetzner CAX11): ~5,000원
- 도메인 (.kr): ~18,000원/년
- Cloudflare: 무료
- S3 백업: ~500원
- 합계: 월 ~6,000원
