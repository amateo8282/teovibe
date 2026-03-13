# Phase 10: 크롤링 기초 - Research

**Researched:** 2026-03-14
**Domain:** robots.txt 동적화, sitemap.xml 동적 카테고리, Google/Naver 검색엔진 소유권 인증
**Confidence:** HIGH (기존 코드베이스 직접 분석 + 프로젝트 공통 연구 문서 기반)

---

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|-----------------|
| CRAWL-01 | robots.txt에 Googlebot/Yeti(네이버) 명시적 허용 규칙 추가 | 현재 정적 파일에 `User-agent: *` 만 있음. 동적 컨트롤러로 교체해 Googlebot/Yeti 전용 블록 추가 |
| CRAWL-02 | robots.txt에 sitemap.xml 경로 명시 | 현재 파일에 이미 존재하나 동적 컨트롤러로 이전 시 유지 필요 |
| CRAWL-03 | sitemap에 동적 카테고리 URL 포함 (Admin에서 카테고리 추가 시 자동 반영) | 현재 sitemap.rb에 slug case/when 하드코딩 — 동적 루프로 교체 필요 |
| SRCH-01 | Google Search Console 소유권 인증 메타태그 삽입 | application.html.erb head에 Rails credentials 기반 조건부 출력 |
| SRCH-02 | 네이버 서치어드바이저 소유권 인증 메타태그 삽입 | application.html.erb head에 고정 삽입 필수 (Turbo 네비게이션 후 소실 방지) |
</phase_requirements>

---

## Summary

Phase 10은 신규 라이브러리 없이 기존 스택으로 처리할 수 있는 설정/구성 작업이다. 핵심은 두 가지: (1) 정적 `public/robots.txt`를 동적 Rails 컨트롤러로 교체해 환경별 크롤링 정책과 Googlebot/Yeti 명시 규칙을 적용하고, (2) `config/sitemap.rb`의 카테고리 slug 하드코딩을 `Category.for_posts` DB 루프로 교체해 Admin 카테고리 추가가 자동으로 sitemap에 반영되도록 한다.

검색엔진 소유권 인증은 Rails credentials(`seo.google_site_verification`, `seo.naver_site_verification`)에 토큰을 저장하고 `application.html.erb`의 `<head>`에 직접 조건부 출력한다. `set_meta_tags verification:` 방식이 아닌 ERB 직접 삽입이 권장된다 — Naver 인증 태그가 `yield :head` 블록이나 특정 뷰에 종속되면 루트 URL 외 경로에서 태그가 소실되어 인증 실패하는 패턴이 확인됐기 때문이다.

Phase 9에서 `seo_helper.rb`의 XSS 취약점(`safe_json_ld` 래퍼)이 이미 패치됐다. Phase 10은 JSON-LD 렌더링과 무관하므로 해당 패치에 의존하지 않는다.

**Primary recommendation:** 정적 `public/robots.txt` 삭제 + `RobotsController` 신규 생성 + `sitemap.rb` 동적화 + `application.html.erb`에 인증 태그 고정 삽입 순서로 진행한다.

---

## Standard Stack

### Core

| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| `sitemap_generator` | 6.3.0 | sitemap.xml 생성 | 이미 설치됨, 완전히 구성됨 — 추가 설치 불필요 |
| `meta-tags` | 2.22.3 | 메타태그 관리 | 이미 설치됨, 레이아웃에 `display_meta_tags` 적용 중 |
| Rails credentials | Rails 8.1.2 내장 | 인증 토큰 저장 | Kamal 배포에서 ENV보다 일관성 높음 (STATE.md 결정사항) |

### 신규 gem/패키지 없음

v1.2 전체가 기존 스택으로 구현 가능하다 (STACK.md 결론). Phase 10도 동일.

### Installation

```bash
# 신규 gem/패키지 없음
# credentials 편집만 필요
bin/rails credentials:edit
```

---

## Architecture Patterns

### 패턴 1: 동적 robots.txt 컨트롤러

**What:** 정적 `public/robots.txt` 파일을 삭제하고 Rails 컨트롤러로 환경별 다른 robots.txt를 응답한다.

**When to use:** 개발/스테이징 환경에서 크롤러를 차단하고 프로덕션에서만 허용할 때.

**Why not static file:** 정적 파일은 Rails 라우터보다 먼저 처리되므로, 컨트롤러가 있어도 정적 파일이 우선 응답한다. `public/robots.txt` 반드시 삭제해야 동적 컨트롤러가 작동한다.

```ruby
# app/controllers/robots_controller.rb
class RobotsController < ApplicationController
  allow_unauthenticated_access
  def show
    expires_in 6.hours, public: true
    respond_to :text
  end
end
```

```
# config/routes.rb에 추가
get "/robots.:format", to: "robots#show"
```

```erb
<%# app/views/robots/show.text.erb %>
<% if Rails.env.production? %>
User-agent: Googlebot
Allow: /

User-agent: Yeti
Allow: /

User-agent: *
Allow: /
Disallow: /admin/
Disallow: /auth/
Disallow: /profile/edit

Sitemap: https://teovibe.com/sitemap.xml
<% else %>
User-agent: *
Disallow: /
<% end %>
```

**CRAWL-01 + CRAWL-02 달성:** Googlebot/Yeti 명시 허용 블록 + Sitemap 경로.

### 패턴 2: sitemap.rb 동적 카테고리 루프

**What:** 현재 `case slug when "blog" ...` 하드코딩을 `Category.for_posts.ordered.each` DB 루프로 교체.

**Why:** v1.1에서 카테고리 CRUD Admin UI가 구현됐으나 sitemap.rb가 업데이트되지 않아 신규 카테고리가 sitemap에서 누락된다. 라우트는 `category_posts_path(category_slug: category.slug)` 통합 패턴으로 표준화됐다.

**현재 라우트 구조 확인:** `config/routes.rb`에 `get "posts/:category_slug", to: "posts#index", as: :category_posts` 존재. 따라서 모든 카테고리를 `category_posts_path(category_slug: category.slug)`로 통일 가능.

```ruby
# config/sitemap.rb — 카테고리 부분 교체
Category.for_posts.ordered.each do |category|
  add category_posts_path(category_slug: category.slug),
      changefreq: "daily", priority: 0.8
end

# 게시글 — 카테고리별 특수 라우트 대신 통합 패턴 사용
Post.published.includes(:category).find_each do |post|
  next unless post.category&.slug
  add category_post_path(category_slug: post.category.slug, slug: post.slug),
      lastmod: post.updated_at, changefreq: "weekly", priority: 0.8
end
```

**주의:** 현재 게시글 URL 패턴은 `posts/:slug` (예: `/posts/post-8`)이며, 카테고리 경로(예: `/posts/blog/post-8`)가 아니다. sitemap에 실제 접근 가능한 URL만 포함해야 한다. 현재 `post_path(@post)` 헬퍼가 `params[:slug]`를 사용하는지 먼저 확인 필요.

**CRAWL-03 달성:** Admin 카테고리 추가 시 다음 `rake sitemap:refresh` 실행에 자동 반영.

### 패턴 3: 검색엔진 인증 메타태그 — application.html.erb 고정 삽입

**What:** Rails credentials에서 인증 토큰을 읽어 `application.html.erb` `<head>`에 조건부 출력.

**Why `set_meta_tags` 방식 사용 금지:** Naver Search Advisor는 `https://teovibe.com/` 루트에서만 소유권을 검증한다. `set_meta_tags verification:` 방식은 특정 뷰나 컨트롤러 before_action에 종속되면 루트 외 경로 방문 시 `<head>`에서 태그가 소실될 수 있다. 레이아웃 ERB 직접 삽입이 모든 경로에서 일관성을 보장한다.

**Why Rails credentials (not ENV):** STATE.md 결정사항 — "검색엔진 인증 토큰은 Rails credentials 저장 — Kamal 배포 환경에서 ENV보다 일관성 높음".

```ruby
# bin/rails credentials:edit 로 아래 키 추가
seo:
  google_site_verification: "GOOGLE_TOKEN_HERE"
  naver_site_verification: "NAVER_TOKEN_HERE"
```

```erb
<%# application.html.erb <head> 내부, <%= yield :head %> 이전에 배치 %>
<% if (token = Rails.application.credentials.dig(:seo, :google_site_verification)).present? %>
  <meta name="google-site-verification" content="<%= token %>">
<% end %>
<% if (token = Rails.application.credentials.dig(:seo, :naver_site_verification)).present? %>
  <meta name="naver-site-verification" content="<%= token %>">
<% end %>
```

**SRCH-01 + SRCH-02 달성:** 모든 경로 `<head>`에 두 인증 태그 출력.

### Anti-Patterns to Avoid

- **정적 `public/robots.txt` 유지 + 컨트롤러 동시 존재:** 정적 파일이 라우터보다 우선. 반드시 파일 삭제 후 컨트롤러 추가.
- **Naver 인증을 HTML 파일 업로드 방식으로 처리:** Kamal 재배포 시 Docker 이미지에 파일이 포함되지 않으면 인증 실패. 메타태그 방식만 사용.
- **sitemap.rb에 하드코딩 slug 추가:** 신규 카테고리마다 코드 수정이 필요한 기술 부채. DB 루프로 교체.
- **`category_posts_path` 대신 각 카테고리별 named route 사용:** v1.1에서 `blogs_path`, `tutorials_path` 등은 SEO 리다이렉트용으로만 남아있다. 실제 현재 URL은 `/posts/:category_slug` 패턴.

---

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| 검색엔진 인증 토큰 저장 | ENV 파일 + 별도 config/seo.rb initializer | Rails credentials | Kamal에서 `RAILS_MASTER_KEY` 한 개로 모든 credentials 관리, 암호화 보장 |
| sitemap 생성 | 커스텀 XML 뷰 | `sitemap_generator` gem | 이미 설치됨, ping, gzip, 다중 파일 등 엣지케이스 처리 내장 |
| robots.txt 환경 분기 | `config/environments/*.rb`에 상수 정의 | Rails 컨트롤러의 `Rails.env.production?` 조건 | 단순한 환경 분기에 과도한 설정 불필요 |

---

## Common Pitfalls

### Pitfall 1: Yeti 봇 Rack::Attack 차단

**What goes wrong:** `User-agent: *`가 Yeti를 포함하지만, Rack::Attack 설정이나 방화벽이 Yeti IP를 차단하면 서치어드바이저 대시보드에서 "수집 차단됨" 오류 발생.

**Why it happens:** Yeti IP 대역이 공식 공개되지 않아 비정상 트래픽으로 오인 가능.

**How to avoid:** robots.txt에 `User-agent: Yeti` 명시 블록 추가. IP 기반 Yeti 차단 절대 금지.

**Warning signs:** 서버 로그에서 `Yeti/1.1` User-Agent가 403/429 응답 수신.

### Pitfall 2: Naver 인증 태그 위치 오류로 소유권 인증 실패

**What goes wrong:** `naver-site-verification` 태그를 `yield :head` 블록 내부나 특정 뷰에서 삽입하면 루트 URL 외에서 태그가 없어 인증 실패.

**Why it happens:** Google/Naver 인증 패턴이 비슷해 하나를 조건부 뷰에 넣는 실수.

**How to avoid:** `application.html.erb` 레이아웃에 직접 하드코딩. `yield :head` 이전 위치에 삽입.

**Warning signs:** 서치어드바이저 "소유권 확인 실패" — 루트 URL에서만 태그 존재, 다른 경로에서는 없음.

### Pitfall 3: sitemap.rb의 카테고리 URL 패턴 불일치

**What goes wrong:** 현재 sitemap.rb는 `blogs_path`, `tutorials_path` 등 구 named routes를 사용한다. 이 routes는 v1.1에서 `/posts/:category_slug`로의 301 리다이렉트로 변경됐다. sitemap에 리다이렉트 URL이 포함되면 Google이 크롤 버짓 낭비로 인식.

**Why it happens:** sitemap.rb가 v1.0 때 작성된 이후 v1.1 라우트 통합 시 업데이트되지 않음.

**How to avoid:** `category_posts_path(category_slug: category.slug)` 통합 패턴으로 교체. 게시글 URL도 현재 라우트(`post_path`)를 확인 후 일치하게 수정.

**Warning signs:** `rake sitemap:refresh` 후 sitemap.xml에 `/blogs`, `/tutorials` 형식 URL 포함.

### Pitfall 4: `public/robots.txt` 삭제 누락

**What goes wrong:** 동적 컨트롤러를 추가해도 `public/robots.txt`가 남아있으면 정적 파일이 우선 응답. 컨트롤러 변경사항이 반영되지 않음.

**Why it happens:** 정적 파일과 라우터의 우선순위 관계를 모르는 경우.

**How to avoid:** `public/robots.txt` 반드시 삭제 후 컨트롤러 추가. 커밋 시 파일 삭제 포함 확인.

**Warning signs:** `curl https://teovibe.com/robots.txt` 응답에 Googlebot/Yeti 블록 없음 (배포 후).

---

## Code Examples

### 동적 robots.txt 컨트롤러 전체 구조

```ruby
# Source: STACK.md (프로젝트 공통 연구), Rails 커뮤니티 검증 패턴
# app/controllers/robots_controller.rb
class RobotsController < ApplicationController
  allow_unauthenticated_access
  def show
    expires_in 6.hours, public: true
    respond_to :text
  end
end
```

```
# app/views/robots/show.text.erb
<% if Rails.env.production? %>
User-agent: Googlebot
Allow: /

User-agent: Yeti
Allow: /

User-agent: *
Allow: /
Disallow: /admin/
Disallow: /auth/
Disallow: /profile/edit

Sitemap: https://teovibe.com/sitemap.xml
<% else %>
User-agent: *
Disallow: /
<% end %>
```

### sitemap.rb 카테고리 동적화

```ruby
# Source: PITFALLS.md 기반 + 현재 routes.rb 확인
# Category 루프 — case/when 하드코딩 대체
Category.for_posts.ordered.each do |category|
  add category_posts_path(category_slug: category.slug),
      changefreq: "daily", priority: 0.8
end
```

### credentials 기반 인증 태그 출력

```erb
<%# Source: STACK.md — 기능 2: 검색엔진 인증 메타태그 %>
<%# application.html.erb — <%= yield :head %> 이전 %>
<% if (token = Rails.application.credentials.dig(:seo, :google_site_verification)).present? %>
  <meta name="google-site-verification" content="<%= token %>">
<% end %>
<% if (token = Rails.application.credentials.dig(:seo, :naver_site_verification)).present? %>
  <meta name="naver-site-verification" content="<%= token %>">
<% end %>
```

### credentials 편집

```bash
# 로컬 개발환경에서 실행
bin/rails credentials:edit

# 아래 구조로 추가
# seo:
#   google_site_verification: "실제토큰값"
#   naver_site_verification: "실제토큰값"
```

---

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| 정적 `public/robots.txt` | 동적 Rails 컨트롤러 | v1.2 (이번 Phase) | 환경별 분기 가능, Googlebot/Yeti 명시 허용 |
| sitemap.rb case/when slug 하드코딩 | `Category.for_posts.ordered.each` DB 루프 | v1.2 (이번 Phase) | Admin 카테고리 추가 자동 반영 |
| 검색엔진 인증 미구현 | credentials + application.html.erb 고정 삽입 | v1.2 (이번 Phase) | GSC/서치어드바이저 소유권 인증 완료 |
| 구 named routes (`blogs_path`) | `category_posts_path` 통합 패턴 | v1.1 완료 | sitemap이 301 리다이렉트 URL 포함하는 기술 부채 제거 |

**Deprecated/outdated:**
- `public/robots.txt` 정적 파일: 컨트롤러로 대체 후 삭제.
- sitemap.rb의 `when "blog" then blogs_path` 블록: 동적 루프로 대체.

---

## Open Questions

1. **게시글 sitemap URL 패턴**
   - What we know: 현재 `config/routes.rb`에서 `resources :posts, param: :slug`로 `post_path(@post)`가 `/posts/:slug` 형식 URL 생성. 현재 sitemap.rb는 `blog_path(post)` 등 구 named route 사용.
   - What's unclear: `post_path(post)`가 현재 라우트에서 올바르게 동작하는지 로컬 확인 필요. `rake routes | grep post` 실행으로 확인.
   - Recommendation: PLAN 작업 태스크에 "게시글 URL 패턴 확인 후 sitemap.rb 업데이트" 포함.

2. **credentials vs ENV — 프로덕션 주입 방법**
   - What we know: STATE.md에 "Rails credentials 사용" 결정 있음. Kamal deploy.yml에 `RAILS_MASTER_KEY`가 secret으로 등록됨.
   - What's unclear: 현재 Kamal 환경에서 `master.key`가 실제로 Docker로 전달되는지 확인 필요. 전달된다면 credentials에 추가된 값이 프로덕션에서 자동으로 복호화됨.
   - Recommendation: PLAN에서 credentials 편집 + 로컬 테스트 단계를 명시적으로 포함.

---

## Validation Architecture

> `workflow.nyquist_validation` 키가 config.json에 없으므로 포함 (기본값 활성화).

### Test Framework

| Property | Value |
|----------|-------|
| Framework | Rails Minitest (내장) |
| Config file | `test/test_helper.rb` |
| Quick run command | `bin/rails test test/controllers/robots_controller_test.rb` |
| Full suite command | `bin/rails test` |

### Phase Requirements - Test Map

| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| CRAWL-01 | GET /robots.txt에 Googlebot/Yeti Allow 블록 포함 | integration | `bin/rails test test/controllers/robots_controller_test.rb` | Wave 0 생성 |
| CRAWL-02 | GET /robots.txt 응답에 sitemap.xml 경로 포함 | integration | `bin/rails test test/controllers/robots_controller_test.rb` | Wave 0 생성 |
| CRAWL-03 | sitemap.xml에 동적 카테고리 URL 포함 | integration | `bin/rails test test/integration/sitemap_test.rb` | Wave 0 생성 |
| SRCH-01 | 모든 페이지 head에 google-site-verification 태그 출력 | integration | `bin/rails test test/integration/seo_tags_test.rb` | Wave 0 생성 |
| SRCH-02 | 모든 페이지 head에 naver-site-verification 태그 출력 | integration | `bin/rails test test/integration/seo_tags_test.rb` | Wave 0 생성 |

### Sampling Rate

- **Per task commit:** `bin/rails test test/controllers/robots_controller_test.rb test/integration/seo_tags_test.rb`
- **Per wave merge:** `bin/rails test`
- **Phase gate:** Full suite green before `/gsd:verify-work`

### Wave 0 Gaps

- [ ] `teovibe/test/controllers/robots_controller_test.rb` — CRAWL-01, CRAWL-02 커버
- [ ] `teovibe/test/integration/sitemap_test.rb` — CRAWL-03 커버
- [ ] `teovibe/test/integration/seo_tags_test.rb` — SRCH-01, SRCH-02 커버

---

## 현재 코드베이스 상태 요약 (구현 전 기준)

| 파일 | 현재 상태 | Phase 10 필요 작업 |
|------|-----------|-------------------|
| `public/robots.txt` | User-agent: * 기본 설정, Googlebot/Yeti 블록 없음 | 삭제 (컨트롤러로 대체) |
| `config/sitemap.rb` | 카테고리 slug case/when 하드코딩 (6개) | 동적 루프로 교체 |
| `app/views/layouts/application.html.erb` | `display_meta_tags`만 있음, 인증 태그 없음 | Googlebot/Naver 인증 태그 추가 |
| `config/credentials.yml.enc` | seo 네임스페이스 없음 | `seo.google_site_verification`, `seo.naver_site_verification` 추가 |
| `config/routes.rb` | robots 라우트 없음 | `get "/robots.:format"` 추가 |
| `app/controllers/robots_controller.rb` | 없음 | 신규 생성 |
| `app/views/robots/show.text.erb` | 없음 | 신규 생성 |

---

## Sources

### Primary (HIGH confidence)

- 프로젝트 코드베이스 직접 분석: `public/robots.txt`, `config/sitemap.rb`, `config/routes.rb`, `app/views/layouts/application.html.erb`, `app/controllers/application_controller.rb` — 현재 상태 직접 확인
- `.planning/research/STACK.md` — 기능 1(robots.txt), 기능 2(인증 메타태그) 상세 패턴
- `.planning/research/PITFALLS.md` — Pitfall 2(Yeti 차단), Pitfall 3(naver 인증 위치), Pitfall 5(sitemap 하드코딩)
- `.planning/STATE.md` — "검색엔진 인증 토큰은 Rails credentials 저장" 결정
- `teovibe/config/deploy.yml` + `.kamal/secrets` — Kamal credentials 주입 패턴 확인

### Secondary (MEDIUM confidence)

- [Google Search Console 소유권 인증](https://support.google.com/webmasters/answer/9008080) — HTML 메타태그 방식 공식 확인
- [DataDome: NaverBot / Yeti](https://datadome.co/bots/naverbot/) — Yeti 기술 특성
- [Dynamic robots.txt in Rails (커뮤니티 패턴)](https://gist.github.com/sandheepg/0e9d855d9c37d305d3cdb775a53226e1) — 컨트롤러 패턴

---

## Metadata

**Confidence breakdown:**
- robots.txt 동적화: HIGH — Rails 표준 컨트롤러 패턴, 코드베이스 직접 확인
- sitemap.rb 동적화: HIGH — 현재 파일 확인, routes.rb 확인, 교체 패턴 명확
- 검색엔진 인증 메타태그: HIGH — credentials 패턴 확인, Kamal secrets 구조 확인, 인증 위치 pitfall 문서화
- Naver 서치어드바이저 특이사항: MEDIUM — 공식 문서 제한적, 커뮤니티 검증 패턴

**Research date:** 2026-03-14
**Valid until:** 2026-04-14 (안정적 스택, 30일 유효)
