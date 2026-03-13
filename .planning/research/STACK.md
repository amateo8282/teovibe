# Stack Research

**Domain:** TeoVibe v1.2 — SEO 검색엔진 최적화 + Admin 에디터 UX 개선
**Researched:** 2026-03-14
**Confidence:** HIGH (existing gems verified against Gemfile.lock; patterns verified against official docs and current codebase)

---

## Scope

이 문서는 v1.2 신규 기능에만 집중한다. 기존에 검증된 스택(Rails 8.1.2, Hotwire, vite_ruby + React 18, rhino-editor, meta-tags, sitemap_generator 등)은 재조사하지 않는다.

신규 기능:
1. robots.txt — Googlebot/Yeti(네이버봇) 허용 규칙 + 환경별 동작
2. Google Search Console / 네이버 서치어드바이저 인증 메타태그
3. JSON-LD 구조화 데이터 (Article, BreadcrumbList)
4. Open Graph / Twitter Card 메타태그 보강
5. canonical URL + 불필요 페이지 noindex 처리
6. Admin 게시글 에디터 2단 레이아웃

---

## 핵심 결론: 신규 gem/패키지 추가 없음

v1.2 모든 기능은 **이미 설치된 스택**으로 구현 가능하다.

| 현황 | 버전 | v1.2에서 활용 |
|------|------|--------------|
| `meta-tags` gem | 2.22.3 (최신) | OG, Twitter Card, canonical, noindex — 아직 controller에서 호출 안 됨 |
| `sitemap_generator` | 6.3.0 | 완전히 구성됨 — robots.txt에서 참조만 추가 |
| `public/robots.txt` | 정적 파일 | 동적 Rails 컨트롤러로 교체 |
| Tailwind CSS | 4.4 | Admin 2단 레이아웃 — `grid-cols-[380px_1fr]` 패턴 |
| Stimulus | current | 레이아웃 변경에 신규 controller 불필요 |
| `content_for :head` / `yield :head` | Rails 8 표준 | JSON-LD script 태그 주입 |

---

## 기능 1: robots.txt 동적화

### 현황 분석

`public/robots.txt` 정적 파일 존재. 현재 내용:
```
User-agent: *
Allow: /
Disallow: /admin/
Disallow: /auth/
Disallow: /profile/edit

Sitemap: https://teovibe.com/sitemap.xml
```

문제: 정적 파일은 환경 구분 불가. 개발/스테이징에서도 크롤러에 노출됨.

### 추가 스택: 없음 — Rails 표준 컨트롤러 패턴

#### 구현 패턴

Rails 동적 robots.txt 컨트롤러 (커뮤니티 검증 패턴):

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
# app/views/robots/show.text.erb
<% if Rails.env.production? %>
User-agent: *
Allow: /
Disallow: /admin/
Disallow: /auth/
Disallow: /profile/edit

User-agent: Yeti
Allow: /

Sitemap: https://teovibe.com/sitemap.xml
<% else %>
User-agent: *
Disallow: /
<% end %>
```

```ruby
# config/routes.rb 추가
get "/robots.:format", to: "robots#show"
```

실행: `public/robots.txt` 삭제 필수 (정적 파일이 라우터보다 우선 처리됨).

**Yeti bot 처리 이유:** Yeti는 네이버 검색로봇 공식 User-Agent. 표준 `User-agent: *` 규칙을 따르지만, 명시적 허용 선언이 네이버 서치어드바이저 등록 시 크롤링 승인 가이드라인에 권장됨.

---

## 기능 2: 검색엔진 인증 메타태그

### 현황 분석

- Google Search Console: `<meta name="google-site-verification" content="VALUE">` HTML 메타태그 방식
- 네이버 서치어드바이저: `<meta name="naver-site-verification" content="VALUE">` HTML 메타태그 방식

두 서비스 모두 HTML 파일 업로드 또는 메타태그 삽입으로 소유권 인증. 메타태그가 더 간단하고 파일 배포 없이 처리 가능.

### 추가 스택: 없음 — Rails credentials + application layout

#### 구현 패턴

인증 값은 소스코드에 하드코딩 금지. Rails credentials에 저장:

```bash
# rails credentials:edit
seo:
  google_site_verification: "GOOGLE_VALUE_HERE"
  naver_site_verification: "NAVER_VALUE_HERE"
```

`app/views/layouts/application.html.erb`의 `<head>`에 조건부 렌더링:

```erb
<% if (value = Rails.application.credentials.dig(:seo, :google_site_verification)).present? %>
  <meta name="google-site-verification" content="<%= value %>">
<% end %>
<% if (value = Rails.application.credentials.dig(:seo, :naver_site_verification)).present? %>
  <meta name="naver-site-verification" content="<%= value %>">
<% end %>
```

---

## 기능 3: JSON-LD 구조화 데이터

### 현황 분석

현재 JSON-LD 구현 없음. `posts/show.html.erb`에 breadcrumb UI는 있으나 machine-readable 구조화 데이터 없음.

Google은 Article, BreadcrumbList schema를 리치 결과(Rich Results)에 활용. JSON-LD 방식이 Google 공식 권장.

### 추가 스택: 없음 — ERB partial + content_for 패턴

`schema_dot_org` gem 검토 결과 **사용 금지**: 1인 프로젝트에 과도한 의존성, Ruby hash + `.to_json`으로 완전히 대체 가능, 유지보수 부담만 증가.

`rails_structured_data` gem **사용 금지**: 작성자가 "work in progress"로 명시.

#### 구현 패턴

Helper 메서드로 구조화 데이터 hash 생성, `content_for :head`로 layout에 주입:

```ruby
# app/helpers/seo_helper.rb
module SeoHelper
  def article_json_ld(post)
    {
      "@context" => "https://schema.org",
      "@type" => "Article",
      "headline" => post.seo_title.presence || post.title,
      "description" => post.seo_description,
      "author" => {
        "@type" => "Person",
        "name" => post.user.nickname
      },
      "datePublished" => post.created_at.iso8601,
      "dateModified" => post.updated_at.iso8601,
      "publisher" => {
        "@type" => "Organization",
        "name" => "TeoVibe",
        "url" => "https://teovibe.com"
      }
    }.compact
  end

  def breadcrumb_json_ld(items)
    {
      "@context" => "https://schema.org",
      "@type" => "BreadcrumbList",
      "itemListElement" => items.each_with_index.map do |item, i|
        {
          "@type" => "ListItem",
          "position" => i + 1,
          "name" => item[:name],
          "item" => item[:path] ? root_url.chomp("/") + item[:path] : nil
        }.compact
      end
    }
  end
end
```

```erb
<%# app/views/posts/show.html.erb에 추가 %>
<% content_for :head do %>
  <script type="application/ld+json"><%= raw article_json_ld(@post).to_json %></script>
  <script type="application/ld+json"><%= raw breadcrumb_json_ld([
    { name: "홈", path: root_path },
    { name: @post.category_name, path: category_posts_path(category_slug: @post.category&.slug) },
    { name: @post.title }
  ]).to_json %></script>
<% end %>
```

`application.html.erb`에 이미 `<%= yield :head %>` 존재 → 제로 레이아웃 변경.

---

## 기능 4: Open Graph / Twitter Card 보강

### 현황 분석

현재 `application.html.erb`에서 `display_meta_tags site: "TeoVibe"` 호출 중 (meta-tags gem 2.22.3). 그러나 어떤 controller에서도 `set_meta_tags`를 호출하지 않아 OG/Twitter Card 태그가 실제로 생성되지 않음.

### 추가 스택: 없음 — meta-tags gem 2.22.3 기존 활용

#### 구현 패턴

`ApplicationController`에 기본 메타태그 설정:

```ruby
# app/controllers/application_controller.rb
before_action :set_default_meta_tags

private

def set_default_meta_tags
  set_meta_tags(
    site: "TeoVibe",
    title: "바이브코딩 커뮤니티",
    reverse: true,
    separator: "|",
    description: "바이브코딩, 부업 아이템 등 사업화 영역의 블로그형 커뮤니티",
    og: {
      site_name: "TeoVibe",
      type: "website",
      image: image_url("og-default.png")
    },
    twitter: {
      card: "summary_large_image",
      site: "@teovibe"
    }
  )
end
```

`PostsController#show`에서 게시글별 OG 오버라이드:

```ruby
# app/controllers/posts_controller.rb show 액션에 추가
set_meta_tags(
  title: @post.seo_title.presence || @post.title,
  description: @post.seo_description,
  canonical: request.url,
  og: {
    title: @post.seo_title.presence || @post.title,
    description: @post.seo_description,
    type: "article",
    url: request.url
  },
  twitter: {
    title: @post.seo_title.presence || @post.title,
    description: @post.seo_description
  }
)
```

`set_meta_tags`는 호출할 때마다 deep merge — 기존 기본값을 덮어쓰지 않고 오버라이드만 적용.

---

## 기능 5: canonical URL + noindex

### 현황 분석

현재 canonical / noindex 적용 없음. 아래 페이지들이 noindex 대상:
- `/admin/**` (Admin 영역 전체)
- `/auth/**` (OAuth 콜백)
- `/profile/edit` (개인 설정)
- 로그인이 필요한 모든 페이지 (나중에 확장)

### 추가 스택: 없음 — meta-tags gem 2.22.3

#### 설정 추가

```ruby
# config/initializers/meta_tags.rb 에 추가
config.skip_canonical_links_on_noindex = true  # noindex + canonical 혼용 방지
```

#### 구현 패턴

```ruby
# app/controllers/admin/base_controller.rb (또는 모든 admin controller 공통 before_action)
before_action { set_meta_tags noindex: true, follow: false }

# app/controllers/sessions_controller.rb, registrations_controller.rb 등
before_action { set_meta_tags noindex: true, follow: false }
```

`noindex: true`는 `<meta name="robots" content="noindex, follow">`를 생성. `follow: false` 추가 시 `noindex, nofollow`.

---

## 기능 6: Admin 2단 레이아웃

### 현황 분석

현재 `app/views/admin/posts/_form.html.erb`: 단일 컬럼 `space-y-4` 폼.
현재 `edit.html.erb` / `new.html.erb`: `max-w-2xl` 제한 컨테이너.

요구사항: 왼쪽 패널(메타 정보: 제목, 카테고리, 상태, 예약, 고정글, SEO) | 오른쪽 패널(AI 초안 + 본문 에디터).

### 추가 스택: 없음 — Tailwind CSS 4.4 grid

#### 구현 패턴

```erb
<%# edit.html.erb, new.html.erb — max-w-2xl → w-full (또는 max-w-7xl) %>
<div class="w-full">
  <h1 class="text-2xl font-black mb-6">게시글 수정</h1>
  <%= render "form", post: @post %>
</div>
```

```erb
<%# _form.html.erb 구조 재편 %>
<%= form_with(model: [:admin, post]) do |f| %>
  <%# 에러 표시 영역 (상단 공통) %>

  <div class="grid grid-cols-1 xl:grid-cols-[380px_1fr] gap-6 items-start">
    <%# 왼쪽: 메타 정보 패널 (sticky) %>
    <div class="xl:sticky xl:top-8 space-y-4 bg-white rounded-card shadow-sm p-6">
      <%# 제목, 카테고리, 상태, 예약 발행, 고정글, SEO 제목, SEO 설명 %>
      <%# 저장/취소 버튼 %>
    </div>

    <%# 오른쪽: 에디터 패널 %>
    <div class="space-y-4 bg-white rounded-card shadow-sm p-6">
      <%# AI 초안 작성 패널 %>
      <%# rhino-editor %>
    </div>
  </div>
<% end %>
```

**Tailwind v4 주의사항:**
- `grid-cols-[380px_1fr]` — arbitrary value 문법은 v3/v4 동일
- `xl:sticky xl:top-8` — xl 브레이크포인트(1280px+) 이상에서만 sticky 적용. 모바일에서는 자연스럽게 단일 컬럼

**rhino-editor 레이아웃 주의:** rhino-editor는 `display: block` 기반. 오른쪽 패널 내부에서 `w-full`로 자연스럽게 확장됨. 별도 스타일 조정 불필요.

---

## 최종 추가 목록

### 신규 Gem: 없음

### 신규 npm 패키지: 없음

### 코드 변경 요약

| 파일 | 변경 유형 | 내용 |
|------|----------|------|
| `public/robots.txt` | 삭제 | 동적 컨트롤러로 교체 |
| `app/controllers/robots_controller.rb` | 신규 | 동적 robots.txt 컨트롤러 |
| `app/views/robots/show.text.erb` | 신규 | 환경별 robots.txt 템플릿 |
| `config/routes.rb` | 수정 | `/robots.:format` 라우트 추가 |
| `app/views/layouts/application.html.erb` | 수정 | 인증 메타태그 추가 |
| `config/initializers/meta_tags.rb` | 수정 | `skip_canonical_links_on_noindex` 추가 |
| `app/controllers/application_controller.rb` | 수정 | 기본 메타태그 before_action 추가 |
| `app/controllers/posts_controller.rb` | 수정 | show 액션에 OG/Twitter/canonical 추가 |
| `app/controllers/admin/base_controller.rb` | 수정 | Admin noindex before_action 추가 |
| `app/helpers/seo_helper.rb` | 신규 | JSON-LD helper 메서드 |
| `app/views/posts/show.html.erb` | 수정 | JSON-LD content_for :head 추가 |
| `app/views/admin/posts/_form.html.erb` | 수정 | 2단 grid 레이아웃으로 재편 |
| `app/views/admin/posts/edit.html.erb` | 수정 | max-w-2xl → w-full |
| `app/views/admin/posts/new.html.erb` | 수정 | max-w-2xl → w-full |

### ENV / Credentials 추가

| 키 | 저장 위치 | 내용 |
|----|----------|------|
| `seo.google_site_verification` | Rails credentials | Google Search Console 인증값 |
| `seo.naver_site_verification` | Rails credentials | 네이버 서치어드바이저 인증값 |

---

## Installation

```bash
# 신규 gem/패키지 없음
# credentials 편집만 필요
bin/rails credentials:edit
```

---

## Alternatives Considered

| 추천 | 대안 | 대안 선택 시기 |
|------|------|--------------|
| 기존 `meta-tags` 2.22.3 활용 | `meta_tags-rails` gem | 별도 gem 필요 없음 — meta-tags가 이미 같은 기능 제공 |
| Plain Ruby hash + `.to_json` for JSON-LD | `schema_dot_org` gem | 여러 schema 타입을 대규모 사이트에서 type-safe하게 관리할 때 |
| Rails credentials | ENV 환경변수 | 배포 파이프라인에서 ENV 주입이 쉬운 경우 (현재는 credentials이 Kamal 배포와 더 일치) |
| Tailwind grid 2단 레이아웃 | JavaScript 리사이즈 패널 | 사용자가 패널 너비를 직접 조절해야 하는 경우 |

---

## What NOT to Add

| 피할 것 | 이유 | 대신 |
|---------|------|------|
| `schema_dot_org` gem | 단순 Article/BreadcrumbList 출력에 과도한 의존성 | Plain Ruby hash + `.to_json` |
| `rails_structured_data` gem | 작성자가 "work in progress" 명시 — 프로덕션 사용 위험 | Plain ERB partial |
| `meta_tags-rails` gem (v1.1.1) | `meta-tags` gem(기존 설치)과 다른 gem. 혼용 금지 | 기존 `meta-tags` 2.22.3 |
| `sitemap_generator` 재설정 | 이미 모든 콘텐츠 커버, 완전히 구성됨 | 기존 config 유지, rake task 실행만 확인 |

---

## Version Compatibility

| 패키지 | 호환 버전 | 노트 |
|--------|----------|------|
| `meta-tags` 2.22.3 | Rails 8.1.2, Ruby 3.3 | Rails < 6.1, Ruby < 3.0 미지원 — 현재 프로젝트 모두 충족 |
| Tailwind CSS 4.4 | `grid-cols-[arbitrary]` | v4에서 arbitrary values JIT 지원 동일, v3와 문법 동일 |
| `sitemap_generator` 6.3.0 | Rails 8.1.2 | 기존 사용 중, 변경 없음 |

---

## Sources

- [meta-tags gem GitHub (kpumuk/meta-tags)](https://github.com/kpumuk/meta-tags) — OG, Twitter Card, canonical, noindex API 확인 (HIGH, 공식 소스)
- [meta-tags 2.22.3 RubyDoc](https://rubydoc.info/gems/meta-tags) — 버전 확인 (HIGH)
- [Adding Structured Data to a Rails Application (Avo Blog)](https://avohq.io/blog/structured-data-rails) — JSON-LD partial 패턴 (MEDIUM, 커뮤니티 검증)
- [Dynamic robots.txt in Rails (GitHub Gist)](https://gist.github.com/sandheepg/0e9d855d9c37d305d3cdb775a53226e1) — 컨트롤러 기반 robots.txt (MEDIUM, 커뮤니티 패턴)
- [Naver Search Advisor full guide (Interad, 2025)](https://www.interad.com/en/insights/naver-search-advisor-a-full-guide) — Yeti bot + 메타태그 인증 (MEDIUM)
- [Google Search Console 소유권 인증](https://support.google.com/webmasters/answer/9008080) — HTML 메타태그 방식 (HIGH, 공식)
- [schema_dot_org gem GitHub](https://github.com/public-law/schema-dot-org) — 대안 검토 후 제외 근거 (MEDIUM)
- 기존 Gemfile.lock (`/teovibe/Gemfile.lock`) — meta-tags 2.22.3, sitemap_generator 6.3.0 직접 확인 (HIGH)

---

*Stack research for: TeoVibe v1.2 SEO 최적화 + Admin 에디터 UX*
*Researched: 2026-03-14*
