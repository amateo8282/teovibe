# Project Research Summary

**Project:** TeoVibe v1.1 Admin 고도화
**Domain:** Rails 모놀리스 CMS — 동적 카테고리, AI 초안 작성, 예약 발행
**Researched:** 2026-02-28
**Confidence:** HIGH

## Executive Summary

TeoVibe v1.1은 기존에 검증된 Rails 8.1 + Hotwire + Solid Queue 스택 위에 세 가지 운영 효율화 기능을 추가하는 밀스톤이다. 핵심 도전은 기술적 난이도보다 안전한 데이터 이관에 있다. 현재 `posts.category`와 `skill_packs.category`가 정수형 enum으로 하드코딩되어 있으며, 이를 동적 `Category` DB 모델로 전환하는 것이 모든 v1.1 기능의 선행 조건이자 최대 위험 지점이다. 이 마이그레이션을 잘못 처리하면 모든 게시판 라우팅과 기존 게시글 카테고리 분류가 동시에 파괴된다.

AI 초안 기능은 Anthropic 공식 Ruby SDK(`anthropic` gem v1.23.0)를 사용하여 2단계 생성(개요 → 본문) 패턴으로 구현한다. Puma 스레드 점유 문제를 피하기 위해 `AiDraftJob`(ActiveJob) + `Turbo::StreamsChannel.broadcast_append_to` 방식의 비동기 스트리밍을 채택한다. 예약 발행은 이미 설치된 Solid Queue의 `set(wait_until:).perform_later` 패턴으로 처리하며 신규 인프라가 전혀 필요 없다. 두 기능 모두 Category 모델 전환 완료 후 독립적으로 병렬 구현 가능하다.

주요 위험은 세 가지다. (1) enum → FK 마이그레이션의 데이터 매핑 오류로 기존 게시글 카테고리 전체 손상, (2) Anthropic API의 동기 호출이 Puma 스레드를 15-60초 블로킹, (3) 예약 발행 잡의 멱등성 미확보로 중복 발행 또는 영구 미발행. 각 위험은 명확한 예방 패턴이 연구 과정에서 확인되었으며, Phase 1에서 마이그레이션 전략을 충분히 검증하는 것이 v1.1 전체 성공의 관건이다.

---

## Key Findings

### Recommended Stack

기존 스택(Rails 8.1.2, Hotwire, Solid Queue 1.3.1, vite_ruby + React 19)은 변경 없이 유지한다. v1.1에서 추가되는 의존성은 최소화되어 있으며 모두 기존 스택과 호환이 확인된 패키지다.

**신규 Gem:**
- `anthropic ~> 1.23` — Anthropic Claude API 공식 Ruby 클라이언트. Ruby 3.2+ 요구(프로젝트 3.3.10 충족), SSE 스트리밍/재시도/타임아웃 내장, 2026-02-19 릴리즈
- `acts_as_list ~> 1.2` — Category 모델 position 기반 순서 관리. Rails 8.1.2 호환(activerecord >= 6.1), v1.2.6(2025-10-21 릴리즈)

**신규 npm 패키지:**
- `sortablejs ^1.15` — 카테고리 드래그앤드롭 UI. Stimulus Controller와 연동, jQuery 불필요, ESM import 지원
- `@types/sortablejs ^1.15` — vite_ruby TypeScript 환경 타입 정의

**신규 DB 마이그레이션:**
- `create_categories` — 통합 카테고리 모델(`record_type` enum으로 post/skillpack 구분)
- `add_category_id_to_posts` — 기존 enum 정수값 → Category FK 이관 포함
- `add_category_id_to_skill_packs` — 기존 enum 정수값 → Category FK 이관 포함
- `add_publish_at_to_posts` + `add_published_at_to_posts` — 예약 발행 datetime (두 컬럼 동시 추가)

**AI 모델 선택:** `claude-haiku-4-5-20251001` 기본값. `ENV["ANTHROPIC_MODEL"]`로 분리하여 운영 중 `claude-sonnet-4-6`로 교체 가능.

**추가하지 않을 것:**
- `sidekiq` + Redis — Solid Queue로 완전히 대체 가능, SQLite 스택과 불일치
- `whenever` gem — 개별 post 예약에 부적합한 cron 패턴
- `ruby_llm` gem — 다중 LLM 추상화 불필요, Anthropic 단독 사용
- ActionController::Live SSE (스트리밍) — Puma 스레드 점유. Action Cable 방식이 더 Rails 관용적

### Expected Features

**Must Have (Table Stakes) — v1.1 이번 밀스톤 P1:**
- 카테고리 CRUD (생성/수정/삭제/순서) — 모든 CMS 기본. 하드코딩 enum은 배포 없이 변경 불가
- 카테고리별 관리자 전용 작성 토글 (`admin_only` boolean) — "공지" 등 보호 카테고리 지원
- 스킬팩 카테고리 동적 관리 — 게시판과 동일 패턴, 독립 구현
- 게시글 예약 발행 (날짜/시간 지정) — Ghost, WordPress 등 모든 블로그 플랫폼이 지원하는 표 스테이크
- AI 초안 2단계 생성 (주제 → 개요 → 본문) — 1인 운영자 콘텐츠 생산 효율화, 경쟁 차별점

**Should Have (Competitive) — v1.1 여유 시 추가 또는 v1.x:**
- 카테고리 드래그앤드롭 순서 변경 — UX 품질 차별화 (버튼 방식으로 먼저 출시 가능)
- AI 스트리밍 응답 (실시간 타이핑 효과) — UX 개선. 기능 자체는 비스트리밍으로도 동작

**Defer (v2+):**
- 태그 기반 콘텐츠 분류 — 카테고리 안정화 후
- AI 초안 스타일/톤 선택 — 기본 동작 후 확장
- 게시글 예약 달력 뷰 — 규모 성장 후
- 카테고리 계층 구조 — 현재 요구사항 대비 과도한 복잡도 (Ancestry gem 필요)
- 사용자별 카테고리 구독/필터링 — 별도 마일스톤 수준 작업

**Anti-Features (구현 금지):**
- 반복 발행 스케줄 (cron 패턴) — 단건 예약으로 충분
- AI 자동 발행 (관리자 검토 없음) — 브랜드 리스크, 1인 운영 철학에 어긋남
- Google Indexing API 자동 제출 — 스팸 정책 위반 가능성

### Architecture Approach

단일 `Category` 모델(`record_type` enum으로 post/skillpack 구분)을 중심으로 기존 Rails 모놀리스 아키텍처를 확장한다. AI 초안 로직은 `AiDraftService` 서비스 객체로 분리하고 `Admin::AiDraftsController`가 Turbo Stream 응답을 담당한다. 예약 발행은 `Post#after_save` 콜백 → `PublishPostJob` 패턴으로 처리한다.

**주요 컴포넌트:**
1. `Category` 모델 — `record_type`, `name`, `slug`, `position`, `admin_only` 컬럼. 기존 `LandingSection#move_up/move_down` 패턴 직접 재사용
2. `Admin::CategoriesController` — CRUD + 순서 변경. Admin 네임스페이스 내 표준 패턴
3. `AiDraftService` — Anthropic SDK 래퍼. 2단계 프롬프트 관리, `ApiError` 커스텀 예외. 서비스 객체로 분리하여 API 키를 단일 위치에서 관리
4. `Admin::AiDraftsController` — Turbo Stream 응답 전용 단일 액션 컨트롤러 (PostsController와 AI 로직 분리)
5. `PublishPostJob` — 멱등성 보장 예약 발행 Job. `draft?` 재확인 + `with_lock` + `return if published?`
6. `ai_draft_controller.js` (Stimulus) — Fetch + `Turbo.renderStreamMessage` + rhino-editor 삽입

**핵심 아키텍처 결정:**
- **Category 단일 모델** (`record_type` 구분): PostCategory + SkillPackCategory 분리보다 LandingSection 패턴과 일관성 유지
- **AI 초안: Turbo Stream 비동기** (Stimulus Fetch → AiDraftJob → `broadcast_append_to`): 전체 페이지 재렌더링 없이 결과 영역만 업데이트. Action Cable 방식으로 스트리밍 구현
- **예약 발행: `wait_until` 개별 잡** (recurring cron 폴링 대신): 정확한 시각 실행, Solid Queue Dispatcher가 처리

**데이터 이관 전략 (가장 중요):**
- 마이그레이션 4단계: nullable FK 추가 → 명시적 SQL 백필 (`UPDATE posts SET category_id = (SELECT id FROM categories WHERE slug = old_slug_name)`) → NOT NULL 제약 → 구 컬럼 삭제
- 기존 6개 게시판 라우팅 유지 (BlogsController 등). SEO URL 파괴 금지. 신규 동적 카테고리는 제네릭 `/:category_slug` 라우트 추가

**빌드 순서 (아키텍처 의존성):**
```
Phase 1: Category 모델 + 마이그레이션 (필수 선행)
    ↓
Phase 2: Admin 카테고리 UI   Phase 3: 예약 발행   Phase 4: AI 초안
     (Phase 1 완료 후 독립적 병렬 가능)
```

### Critical Pitfalls

1. **enum integer → Category FK 마이그레이션 데이터 손상** — auto-increment ID가 enum 정수와 일치한다는 가정 절대 금지. `blog=0`이 `category_id=1`에 매핑되리라는 보장 없음. 명시적 slug 기반 SQL 매핑 사용. 마이그레이션 전 스테이징 DB 복사본에서 행 수 일치 검증 필수.

2. **하드코딩 카테고리 라우팅 파괴** — 현재 6개 서브컨트롤러(BlogsController 등)와 named route가 enum에 의존. 동적 slug가 `polymorphic_path`에서 `NoMethodError: undefined method 'vibe_coding_path'` 발생. Option A 채택: 기존 6개 라우트 유지 + 신규 동적 카테고리는 제네릭 라우트.

3. **Anthropic API Puma 스레드 블로킹** — 컨트롤러에서 `messages.create`(blocking) 직접 호출 시 15-60초 스레드 점유. Puma 5 스레드 환경에서 동시 AI 요청 2개면 서버 전체 응답 저하. 반드시 `AiDraftJob` 비동기 처리.

4. **예약 발행 잡 중복 실행** — `after_save` 콜백이 `publish_at` 변경마다 새 잡 등록. Solid Queue 잡 취소 공식 API 없음. 멱등성 확보 (`return if post.published?`), `with_lock`, `saved_change_to_publish_at?` 조건으로 방지.

5. **Anthropic API 키 로그 유출** — `filter_parameters`에 추가 필수. `AiDraftService` 서비스 객체로 키 참조 단일 위치 격리. 컨트롤러에서 직접 `Anthropic::Client.new` 호출 금지.

6. **`published_at` 누락으로 공개 피드 정렬 오류** — 예약 발행 후 `created_at` 기준 정렬이면 발행 전 게시글이 공개 피드에 노출. `publish_at` 컬럼과 함께 `published_at` 컬럼 반드시 동시 추가. 공개 스코프에 `where("published_at <= ?", Time.current)` 조건 포함.

---

## Implications for Roadmap

### Phase 1: Category 모델 기반 구축

**Rationale:** 모든 v1.1 기능의 선행 조건이자 가장 위험한 단계. Category 모델 없이는 Admin 카테고리 UI, Post 작성 폼, 공개 게시판 라우팅 수정이 모두 불가. 데이터 마이그레이션이 여기에 집중되므로 완전히 독립 검증 후 다음 단계로 진행해야 한다. 스테이징에서 마이그레이션 SQL 검증이 필수.

**Delivers:**
- `categories` 테이블 + `Category` 모델 (`record_type`, `name`, `slug`, `position`, `admin_only`)
- Post enum 제거 + `belongs_to :category` 전환 (기존 6개 카테고리 데이터 행 수 보존 검증)
- SkillPack enum 제거 + `belongs_to :category` 전환 (`by_category` scope 업데이트)
- `PostsBaseController` 쿼리 교체 (`joins(:category).where(categories:{slug:})`)
- 기존 6개 게시판 라우팅 유지 확인 (BlogsController 등 6개 서브컨트롤러 200 응답)
- Category 시드 데이터 (Post 6개 + SkillPack 4개, `admin_only` 기본값 `false`)

**Features Addressed:** 카테고리 CRUD 기반, 관리자 전용 토글 기반, 스킬팩 카테고리 기반
**Pitfalls to Avoid:** Pitfall 1(enum → FK 데이터 손상), Pitfall 2(라우팅 파괴), admin_only 기본값 false 강제, SkillPack `by_category` scope 파괴

---

### Phase 2: Admin 카테고리 동적 관리 UI

**Rationale:** Phase 1 완료 후 즉시 시작 가능. Phase 3, 4와 독립적 — 병렬 진행 가능. 관리자가 카테고리를 런타임에 생성/수정/삭제/순서변경할 수 있는 UI를 제공해야 "동적 카테고리" 기능이 완성된다. LandingSection 패턴을 그대로 재사용하므로 구현 위험이 낮다.

**Delivers:**
- `Admin::CategoriesController` CRUD (index/new/create/edit/update/destroy)
- `move_up` / `move_down` 순서 변경 액션 (LandingSection 패턴 재사용)
- Admin 카테고리 목록/폼 뷰 (LandingSection 뷰 구조 참조)
- 관리자 전용 작성 토글 UI (inline Turbo Stream 업데이트)
- 카테고리 삭제 시 게시글 보호 로직 (게시글 있으면 삭제 거부)
- Admin 게시글/스킬팩 폼의 카테고리 select 소스 교체 (`Category.for_posts` / `Category.for_skill_packs`)
- (P2) 드래그앤드롭 순서 변경: `sortablejs` + Stimulus Controller

**Uses:** `acts_as_list ~> 1.2`, `sortablejs ^1.15` (P2)
**Architecture Component:** `Admin::CategoriesController`, `Category#move_up/move_down`

---

### Phase 3: 게시글 예약 발행

**Rationale:** Phase 1 완료 후 즉시 시작 가능 (Phase 2와 병렬). Post 모델에 `publish_at`, `published_at` 컬럼을 추가하고 Solid Queue 잡을 연결하는 독립 기능. 이미 설치된 Solid Queue와 `config/queue.yml`을 그대로 활용하므로 추가 인프라가 없다. `published_at`과 `publish_at`은 반드시 같은 마이그레이션에서 동시에 추가해야 한다.

**Delivers:**
- `publish_at: datetime` + `published_at: datetime` 컬럼 추가 (동일 마이그레이션)
- `Post.status` `:scheduled` 추가 (`draft → scheduled → published` 상태 흐름)
- `PublishPostJob` (멱등성 보장: `return if published?`, `with_lock`)
- `Post#after_save :schedule_publish` 콜백 (`saved_change_to_publish_at?` 조건)
- Admin 폼 `datetime_local_field` + flatpickr Stimulus 컨트롤러 (KST 표시, UTC 저장)
- 공개 스코프 `where("published_at <= ?", Time.current)` 업데이트
- RSS 피드 / 사이트맵 `published_at` 기준 정렬 업데이트
- Admin 게시글 목록 "예약됨" 배지 + 예정 시각 표시

**Uses:** Solid Queue `set(wait_until:).perform_later` (기존 설치), flatpickr (npm, 별도 설치)
**Pitfalls to Avoid:** 잡 중복 실행(with_lock + 멱등성), `published_at` vs `created_at` 정렬 혼선

---

### Phase 4: AI 초안 작성 (2단계 생성)

**Rationale:** Phase 1 완료 후 시작 가능. Phase 2, 3과 독립적이나 개발 집중도를 위해 Phase 2, 3 완료 후 진행 권장. Anthropic API 키 환경변수 설정이 선행 필요. STACK.md의 `anthropic` gem 방식과 ARCHITECTURE.md의 Faraday 직접 호출 방식 중 `anthropic` gem 방식으로 통일.

**Delivers:**
- `AiDraftService` — `anthropic` gem 래퍼, 2단계 프롬프트(개요/본문), `ApiError` 커스텀 예외
- `AiDraftJob` — 비동기 스트리밍 (`Turbo::StreamsChannel.broadcast_append_to`, `broadcast_append_to "ai_draft_#{draft_id}"`)
- `Admin::AiDraftsController` — Turbo Stream 응답 전용 (`create` 액션)
- `ai_draft_controller.js` (Stimulus) — Fetch + `Turbo.renderStreamMessage` + rhino-editor 삽입
- Admin 게시글 폼 AI 초안 UI (주제 입력 → 개요 표시 → 본문 생성 → 에디터 적용)
- SEO/AEO 시스템 프롬프트 (H2/H3 구조, FAQ 섹션, 40-60자 직접 답변, 한국어 특화)
- `filter_parameters`에 `ANTHROPIC_API_KEY` 추가
- `ENV["ANTHROPIC_MODEL"]`로 모델 교체 가능 구조

**Uses:** `anthropic ~> 1.23` (Gem), `claude-haiku-4-5-20251001` (기본)
**Pitfalls to Avoid:** Puma 스레드 블로킹 (반드시 Job 비동기), API 키 유출 (서비스 객체 격리 + filter_parameters)

---

### Phase Ordering Rationale

- **Phase 1이 유일한 blocking 의존성:** Post/SkillPack 모델 변경이 모든 하위 작업의 전제 조건. 가장 위험하므로 스테이징 검증 후 프로덕션 적용.
- **Phase 2, 3, 4는 상호 독립:** 모두 Phase 1 완료 후 병렬 시작 가능. 1인 개발 제약상 Phase 2 → Phase 3 → Phase 4 순차 진행이 현실적.
- **Phase 3의 `published_at`은 독자 가시성에 직접 영향:** 카테고리 UI가 내부 Admin 기능인 반면 예약 발행은 독자에게 즉각 영향. 두 기능 중 어느 것을 먼저 해도 무방.
- **Phase 4는 외부 API 의존성:** Anthropic API 키 발급/검증 시간이 필요. 먼저 `.env`에 키 설정 후 진행.

---

### Research Flags

**Phase 1에서 깊은 검증 필요 (가장 중요):**
- enum → FK 마이그레이션 SQL 매핑 스크립트를 스테이징 DB 복사본에서 먼저 검증 (행 수 일치 확인)
- `PostsBaseController` 6개 서브컨트롤러 라우팅 변경 후 전체 게시판 URL 200 응답 확인
- SkillPack `by_category` scope 수정 후 `SkillPack.by_category("template").count > 0` 검증

**Phase 4에서 사전 확인 필요:**
- `ANTHROPIC_API_KEY` `.env` 및 `.kamal/secrets` 등록 후 시작
- Action Cable 청크 순서 보장: 개발 환경에서 스트리밍 청크가 올바른 순서로 append되는지 초기 검증
- `anthropic` gem vs ARCHITECTURE.md Faraday 방식 불일치: `anthropic` gem 방식으로 통일 결정 필요

**표준 패턴으로 추가 리서치 불필요:**
- Phase 2: LandingSection 패턴 직접 재사용 (기존 코드베이스 내 검증된 패턴)
- Phase 3: Solid Queue `set(wait_until:)` — Rails 8.1 기본 내장 ActiveJob 기능, 추가 설정 불필요

---

## Confidence Assessment

| Area | Confidence | Notes |
|------|------------|-------|
| Stack | HIGH | 공식 GitHub 릴리즈 + RubyGems 버전 직접 확인. `anthropic` gem 1.23.0(2026-02-19), `acts_as_list` 1.2.6(2025-10-21). Rails 8.1.2/Ruby 3.3.10 호환 확인. Solid Queue 1.3.1 이미 프로젝트에 설치 확인 |
| Features | MEDIUM-HIGH | 기존 코드베이스 분석 + Ghost/WordPress 기능 비교 기반. SEO/AEO 효과는 운영 후 실측 필요. 표 스테이크 분류는 경쟁 분석으로 검증됨 |
| Architecture | HIGH | 기존 코드베이스 직접 분석(models, controllers, routes, queue.yml, schema.rb). LandingSection 패턴 재사용 확인. Solid Queue scheduled_executions 테이블 동작 원리 공식 문서로 검증 |
| Pitfalls | HIGH | 코드베이스 검증(enum 선언 위치, 라우팅 구조) + Solid Queue GitHub Issues 직접 확인(#429, #651) + 공식 Anthropic 문서 기반. 실제 코드 구조에서 파생된 위험이므로 신뢰도 높음 |

**Overall confidence:** HIGH

### Gaps to Address

- **`anthropic` gem vs Faraday 방식 불일치:** ARCHITECTURE.md는 Faraday 직접 호출 패턴으로 작성되었으나 STACK.md는 공식 `anthropic` gem 사용 권장. Phase 4 시작 전 `anthropic` gem 방식으로 통일 결정 필요. (STACK.md 기준이 최신 연구 결과)
- **Action Cable 청크 순서 보장 이슈:** STACK.md에서 "Action Cable은 스레드 풀로 인해 청크 순서 보장 없음"으로 명시됨. append 방식으로만 처리하면 실용적으로 문제없으나, Phase 4 초기 개발 환경 검증 필요.
- **rhino-editor 외부 HTML 삽입 검증:** AI 생성 Markdown을 rhino-editor hidden input에 삽입 시 `dispatchEvent(new Event("change"))`가 에디터 콘텐츠를 업데이트하는지 현재 설치 버전에서 확인 필요.
- **flatpickr 한국어 로케일 패키지:** `flatpickr/dist/l10n/ko.js` import 경로가 pnpm + vite_ruby 환경에서 동작하는지 확인 필요.

---

## Sources

### Primary (HIGH confidence)
- [anthropics/anthropic-sdk-ruby GitHub](https://github.com/anthropics/anthropic-sdk-ruby) — SDK 버전, 스트리밍 패턴, Ruby 3.2+ 요구사항
- [rubygems.org/gems/anthropic](https://rubygems.org/gems/anthropic) — v1.23.0 릴리즈 날짜(2026-02-19) 확인
- [Anthropic Models Overview](https://platform.claude.com/docs/en/about-claude/models/overview) — 모델 ID 및 가격표
- [rubygems.org/gems/acts_as_list](https://rubygems.org/gems/acts_as_list) — v1.2.6(2025-10-21), activerecord >= 6.1 의존 확인
- [rails/solid_queue GitHub](https://github.com/rails/solid_queue) — `scheduled_executions` 테이블, `perform_at` 패턴, Dispatcher 설정
- 기존 코드베이스 직접 분석 — `app/models/post.rb`, `app/controllers/posts_base_controller.rb`, `config/routes.rb`, `config/queue.yml`, `db/schema.rb`

### Secondary (MEDIUM confidence)
- [AppSignal: Deep Dive into Solid Queue (2025)](https://blog.appsignal.com/2025/06/18/a-deep-dive-into-solid-queue-for-ruby-on-rails.html) — Dispatcher polling 동작 원리 확인
- [npmjs.com/package/sortablejs](https://www.npmjs.com/package/sortablejs) — v1.15.x ESM 지원 확인
- [Aha! Engineering: Streaming LLM Responses with Rails](https://www.aha.io/engineering/articles/streaming-llm-responses-rails-sse-turbo-streams) — SSE vs Turbo Streams 비교
- [evilmartians: AnyCable and LLM streaming pitfalls](https://evilmartians.com/chronicles/anycable-rails-and-the-pitfalls-of-llm-streaming) — Action Cable 순서 보장 이슈
- [Solid Queue GitHub Issues #429, #651](https://github.com/rails/solid_queue/issues/429) — recurring tasks 미등록 이슈 확인
- [flatpickr 공식 문서](https://flatpickr.js.org/) — enableTime, altInput, locale 설정

### Tertiary (LOW confidence)
- [GoRails 예약 발행 패턴](https://gorails.com/forum/following-scheduling-post-episode-with-background-jobs) — 커뮤니티 포럼, 보조 참고만
- [FAQPage 스키마 + AI 검색 인용률](https://www.frase.io/blog/faq-schema-ai-search-geo-aeo) — 단일 출처, SEO/AEO 효과는 운영 후 실측 필요

---

*Research completed: 2026-02-28*
*Ready for roadmap: yes*
