# Feature Research

**Domain:** SEO 최적화 + Admin 에디터 UX — Rails 블로그 커뮤니티 플랫폼 (v1.2 Milestone)
**Researched:** 2026-03-14
**Confidence:** HIGH

## Context: What Already Exists (v1.1 이전 구현 완료)

이 파일은 v1.2 밀스톤의 신규 기능에만 집중한다. 중복 작업 방지를 위해 기존 구현 현황을 먼저 정리한다.

### 이미 있는 SEO 기반 인프라

- `meta-tags` gem 설치 + `display_meta_tags site: "TeoVibe"` 레이아웃에 적용
- `sitemap_generator` gem + `config/sitemap.rb` (게시글/스킬팩/카테고리 URL 포함)
- `public/robots.txt` 기본 설정 (User-agent: * / Disallow: /admin/, /auth/, /profile/edit)
- `app/helpers/seo_helper.rb` — Article, BreadcrumbList, WebSite, Organization, ItemList, ProfilePage, FAQPage, SoftwareApplication JSON-LD 헬퍼 정의 완료
- Post 모델에 `seo_title`, `seo_description` 컬럼 존재
- Admin 게시글 폼에 SEO 제목/설명 필드 존재 (1컬럼 레이아웃 하단에 위치)

### 아직 없는 것 (v1.2 대상)

- `set_meta_tags`를 각 페이지/컨트롤러에서 실제 호출하는 코드 없음
- Open Graph / Twitter Card 메타태그 실제 출력 없음
- JSON-LD 헬퍼가 정의되어 있으나 뷰에서 실제 렌더링되지 않음
- canonical URL 처리 없음
- noindex 페이지 지정 없음
- robots.txt에 Yeti(네이버봇) 전용 룰 없음
- Google/네이버 Search Console 인증 메타태그 없음
- Admin 에디터 1컬럼 레이아웃 — 메타/설정 필드와 본문 에디터가 세로로 나열됨

---

## Feature Landscape

### Table Stakes (Users Expect These)

SEO 최적화 플랫폼이라면 당연히 있어야 하는 기능들. 없으면 크롤러에게 "미완성" 시그널을 준다.

| Feature | Why Expected | Complexity | Notes |
|---------|--------------|------------|-------|
| Open Graph 메타태그 (og:title, og:description, og:image, og:type) | 카카오/페이스북/링크드인/슬랙 링크 공유 시 미리보기 생성. 없으면 제목도 없는 빈 카드 노출 | LOW | meta-tags gem이 이미 설치됨. 각 컨트롤러/뷰에서 `set_meta_tags og: {...}` 호출만 추가하면 됨. 게시글 상세 페이지에서는 `og:type = "article"` 필수 |
| Twitter Card 메타태그 (twitter:card, twitter:title, twitter:image) | X(구 트위터)/Discord 공유 시 미리보기. `summary_large_image` 타입이 클릭률 높음 | LOW | OG 태그와 거의 동일한 패턴. Twitter는 OG 태그를 fallback으로 사용하므로 핵심 twitter:card만 추가해도 동작 |
| canonical URL 자기 참조 | 페이지네이션, 쿼리스트링 등 동일 콘텐츠 중복 URL 발생 방지. Google이 공식 권장 | LOW | meta-tags gem의 `set_meta_tags canonical: request.original_url` 패턴. ApplicationController concern으로 자동화 가능 |
| noindex — Admin/인증 페이지 | 관리자 페이지, 프로필 편집 등이 검색 결과에 노출되면 안 됨. robots.txt Disallow는 크롤링 차단이지 noindex가 아님 | LOW | Admin 레이아웃에 `set_meta_tags noindex: true` 전역 설정 한 줄로 처리 가능. meta-tags gem의 `skip_canonical_links_on_noindex: true` config와 함께 사용 권장 |
| robots.txt 보강 — Yeti(네이버봇) 허용 룰 + sitemap 경로 | 네이버 검색 등록을 위해 Yeti 봇 명시적 허용 설정 필요. 현재 robots.txt는 sitemap 경로 기재되어 있으나 Yeti 전용 룰 없음 | LOW | `User-agent: Yeti` 항목 추가. 현재 `User-agent: *` 규칙이 이미 Yeti를 허용하지만 네이버 서치어드바이저는 명시적 선언을 선호함. `public/robots.txt` 정적 파일 수정 |
| Google Search Console 인증 메타태그 | 사이트 소유권 확인 없이 GSC 기능 사용 불가. `google-site-verification` 메타태그가 표준 방법 | LOW | `config/initializers/` 또는 환경변수로 토큰 저장 후 application.html.erb `yield :head`에 출력. meta-tags gem의 `set_meta_tags verification: { google: token }` 지원 |
| 네이버 서치어드바이저 인증 메타태그 | 네이버 검색 노출을 위한 소유권 확인. `naver-site-verification` 메타태그 사용 | LOW | Google과 동일 패턴. `set_meta_tags verification: { naver: token }` 방식 |

### Differentiators (Competitive Advantage)

기본 SEO를 넘어 검색 품질과 관리자 UX를 실질적으로 개선하는 기능들.

| Feature | Value Proposition | Complexity | Notes |
|---------|-------------------|------------|-------|
| JSON-LD 구조화 데이터 실제 렌더링 (Article + BreadcrumbList) | Google Rich Results에서 별점, 날짜, 작성자 표시 가능. 클릭률 향상. 헬퍼는 이미 정의됨 — 뷰에 연결만 하면 됨 | LOW-MEDIUM | 게시글 상세에 `article_json_ld(@post)` + `breadcrumb_json_ld(items)` 렌더링. 홈에 `website_json_ld` + `organization_json_ld`. `<script type="application/ld+json">` 태그로 head에 삽입 |
| og:image OGP 이미지 자동 생성/선택 | 이미지 없는 OG 카드는 공유 시 매력 없음. 게시글 본문 첫 번째 이미지 자동 추출 또는 기본 OGP 이미지 폴백 | MEDIUM | Post 모델에 `og_image_url` 메서드 추가: (1) 본문에서 첫 번째 첨부 이미지 URL 추출, (2) 없으면 사이트 기본 OGP 이미지(`/opengraph-default.png`) 폴백 |
| Admin 게시글 에디터 2컬럼 레이아웃 | 현재 1컬럼에서 AI 패널, 제목, 카테고리, 상태, 예약, 본문 에디터, SEO 필드가 세로로 나열 — 스크롤이 매우 길어짐. 2컬럼으로 분리하면 에디터에 집중하면서 메타 정보를 한눈에 볼 수 있음 | MEDIUM | **왼쪽(넓게, ~70%):** AI 패널 + 제목 + 본문 에디터 / **오른쪽(좁게, ~30%):** 카테고리, 상태, 예약 시간, 고정글, SEO 제목/설명. Tailwind CSS Grid 또는 Flex로 구현. Ghost/WordPress Admin이 동일 패턴 사용 |
| noindex 토글 — 게시글별 관리자 선택 | 시리즈 중간 페이지, 임시 공개 게시글 등 특정 글을 의도적으로 비색인 처리. 현재 모든 published 게시글이 색인됨 | MEDIUM | Post 모델에 `noindex: boolean` 컬럼 추가. Admin 에디터 우측 패널에 토글. 게시글 show 뷰에서 조건부 `set_meta_tags noindex: true` |

### Anti-Features (Commonly Requested, Often Problematic)

요청받을 수 있지만 현재 맥락에서 구현하면 안 되는 기능들.

| Feature | Why Requested | Why Problematic | Alternative |
|---------|---------------|-----------------|-------------|
| sitemap 동적 핑 자동 전송 (Google Indexing API) | 새 글 발행 즉시 구글에 색인 요청하고 싶음 | Google Indexing API는 JobPosting, BroadcastEvent 등 특정 스키마만 지원. 일반 블로그 게시글에는 Search Console ping 엔드포인트 사용이 표준. 과도한 API 호출은 스팸으로 분류될 수 있음 | `sitemap_generator`의 ping 기능(`SitemapGenerator::Sitemap.ping_search_engines`)을 배포 시 한 번 호출하거나 새 글 발행 후 after_create_commit 콜백으로 제한 |
| 자동 meta description 생성 (본문 첫 200자) | SEO 설명을 매번 입력하기 번거로움 | 자동 생성된 설명은 SEO 품질 낮음. Google이 이미 meta description을 무시하고 자체 snippets 생성하는 추세 (2025년 기준 50% 이상 무시). AI 초안이 이미 있으므로 중복 | Admin 에디터에서 AI 초안 생성 시 SEO 설명도 함께 제안하도록 AI 프롬프트에 포함. 빈 경우만 자동 생성 |
| AMP (Accelerated Mobile Pages) 별도 구현 | 모바일 검색 속도 향상을 위해 AMP 페이지 만들기 | Google이 2023년부터 AMP를 Core Web Vitals 순위 요소에서 제외. AMP는 Rails에서 별도 뷰 세트 필요로 유지보수 비용 높음. 현재 반응형 Tailwind 디자인으로 충분 | Core Web Vitals(LCP, CLS, FID) 최적화에 집중 |
| 다국어 hreflang 태그 | 한국어/영어 별도 버전 운영 시 필요 | TeoVibe는 한국어 전용 서비스. 불필요한 복잡도 추가 | `<html lang="ko">` 이미 설정됨. `og:locale = "ko_KR"` 추가로 충분 |
| 구조화 데이터 유효성 검사 자동화 CI | PR마다 JSON-LD 유효성 자동 체크 | 1인 운영에 CI 설정 오버엔지니어링. 수동으로 Google Rich Results Test 사용이 현실적 | 초기 구현 후 한 번 Google Rich Results Test(`https://search.google.com/test/rich-results`)로 수동 검증 |

---

## Feature Dependencies

```
[Open Graph 메타태그]
    └──requires──> [meta-tags gem (이미 설치됨)]
    └──requires──> [각 컨트롤러/뷰에서 set_meta_tags 호출]
    └──enhances──> [og:image] (이미지 있으면 공유 카드 품질 향상)

[JSON-LD 구조화 데이터 렌더링]
    └──requires──> [seo_helper.rb 헬퍼 (이미 정의됨)]
    └──requires──> [각 뷰에서 content_for :head 블록으로 script 태그 삽입]
    └──enhances──> [BreadcrumbList] (shared/breadcrumb 컴포넌트와 일관성 유지 필요)

[noindex 토글 (게시글별)]
    └──requires──> [Post 모델 noindex 컬럼 마이그레이션]
    └──requires──> [Admin 에디터 2컬럼 레이아웃] (우측 패널에 배치)
    └──conflicts──> [canonical URL] (Google 권장: noindex 페이지에 canonical 동시 사용 지양)
                       └──해결: MetaTags.config.skip_canonical_links_on_noindex = true

[Admin 2컬럼 레이아웃]
    └──requires──> [기존 _form.html.erb 리팩터링]
    └──enables──> [noindex 토글 UI] (우측 패널 공간 확보)
    └──enables──> [SEO 필드 가시성 향상] (현재 폼 하단에 묻혀있음)

[Google/네이버 Search Console 인증]
    └──requires──> [환경변수로 인증 토큰 관리] (.env에 GOOGLE_SITE_VERIFICATION, NAVER_SITE_VERIFICATION)
    └──requires──> [application.html.erb head 섹션에 토큰 출력]
    └──독립적──> [다른 SEO 기능과 독립적으로 구현 가능]

[robots.txt 보강]
    └──독립적──> [정적 파일 수정만으로 완료]
    └──선행 권장──> [Google/네이버 Search Console 인증보다 먼저 완료 권장]
```

### Dependency Notes

- **JSON-LD와 BreadcrumbList 일관성:** `seo_helper.rb`의 `breadcrumb_json_ld`가 생성하는 구조화 데이터는 반드시 실제 페이지에 보이는 breadcrumb UI와 일치해야 함. 불일치 시 Google이 구조화 데이터를 무시하거나 패널티 부여 가능.
- **noindex + canonical 충돌:** Google의 John Mueller 권고에 따라 noindex 페이지에는 canonical 태그를 함께 사용하지 않는 것이 권장됨. `MetaTags.config.skip_canonical_links_on_noindex = true` 설정으로 자동 처리.
- **og:image 없는 OG 태그 금지:** `og:image`가 없으면 공유 시 빈 카드 노출. 기본 OGP 이미지를 반드시 `public/` 에 준비해야 함.
- **Admin 2컬럼 레이아웃이 noindex 토글의 선행 조건:** 1컬럼에서도 noindex 토글 추가는 가능하나, 2컬럼으로 전환 시 우측 패널에 자연스럽게 배치되므로 레이아웃 작업을 먼저 하는 것이 효율적.

---

## 기능별 상세 동작 분석

### 1. Open Graph + Twitter Card 메타태그

**동작 방식:**
- 각 페이지 타입별로 `set_meta_tags` 호출 시 meta-tags gem이 `<head>`에 `<meta property="og:...">` 태그 자동 생성
- Twitter는 OG 태그를 fallback으로 사용하므로 `twitter:card` 타입만 명시하면 나머지는 OG에서 상속

**구현 패턴:**

게시글 상세 컨트롤러 (`posts_controller.rb#show`):
```ruby
set_meta_tags(
  title: @post.seo_title.presence || @post.title,
  description: @post.seo_description,
  og: {
    title: @post.seo_title.presence || @post.title,
    description: @post.seo_description,
    type: "article",
    url: request.original_url,
    image: @post.og_image_url,
    locale: "ko_KR",
    "article:published_time" => @post.created_at.iso8601,
    "article:author" => @post.user.nickname
  },
  twitter: {
    card: "summary_large_image"
  }
)
```

ApplicationController (전역 기본값):
```ruby
before_action :set_default_meta_tags

def set_default_meta_tags
  set_meta_tags(
    site: "TeoVibe",
    title: "바이브코딩 커뮤니티",
    description: "바이브코딩으로 사업을 만드는 사람들의 커뮤니티",
    og: {
      site_name: "TeoVibe",
      type: "website",
      image: "#{root_url}opengraph-default.png",
      locale: "ko_KR"
    },
    twitter: { card: "summary_large_image" }
  )
end
```

**og:image 자동 추출 (Post 모델 메서드):**
```ruby
def og_image_url
  # ActionText 본문에서 첫 번째 첨부 이미지 URL 추출
  # 없으면 사이트 기본 OGP 이미지 반환 (컨트롤러에서 처리)
  nil # 컨트롤러에서 폴백 처리
end
```

**이미지 권장 사이즈:** 1200x630px (1.91:1 비율). `public/opengraph-default.png` 필수 준비.

### 2. JSON-LD 구조화 데이터 렌더링

**동작 방식:**
- `seo_helper.rb`에 헬퍼 정의 완료됨. 뷰에서 `content_for :head` 블록으로 `<script type="application/ld+json">` 태그를 `yield :head` 위치에 삽입하면 됨

**게시글 상세 뷰 (`posts/show.html.erb`) 추가:**
```erb
<% content_for :head do %>
  <script type="application/ld+json"><%= article_json_ld(@post) %></script>
  <script type="application/ld+json"><%= breadcrumb_json_ld([
    { name: "홈", url: root_url },
    { name: @post.category_name, url: category_posts_url(category_slug: @post.category&.slug) },
    { name: @post.title }
  ]) %></script>
<% end %>
```

**중요:** BreadcrumbList의 `itemListElement`에 사용하는 URL이 실제 breadcrumb UI에 표시된 링크와 동일해야 함.

**페이지별 JSON-LD 매핑:**

| 페이지 | JSON-LD 타입 |
|--------|-------------|
| 홈 (`/`) | WebSite + Organization |
| 게시글 상세 | Article + BreadcrumbList |
| 스킬팩 상세 | SoftwareApplication |
| 카테고리 목록 | ItemList + BreadcrumbList |
| 프로필 | ProfilePage |

### 3. canonical URL + noindex 처리

**canonical URL 전략:**
- 모든 페이지: 자기 참조 canonical (`request.original_url` 기반)
- 페이지네이션(`?page=2`): 각 페이지의 `request.original_url`을 canonical로 사용 (noindex 적용 금지 — 深 페이지 콘텐츠 색인 방지)
- ApplicationController before_action으로 기본값 설정, 각 컨트롤러에서 필요 시 오버라이드

**noindex 적용 대상:**
1. Admin 레이아웃 전체 (`admin.html.erb` head에 전역 설정)
2. 인증 관련 페이지 (`/auth/`, `/sessions/`, `/registrations/`)
3. 프로필 편집 페이지 (`/profile/edit`)
4. 게시글별 noindex 토글 (Admin에서 선택 시 해당 게시글만)

**구현 방식:**
- Admin 레이아웃: `<meta name="robots" content="noindex, follow">` 직접 삽입 또는 `set_meta_tags noindex: true`
- ApplicationController: `MetaTags.config.skip_canonical_links_on_noindex = true`

### 4. robots.txt 보강

**현재 상태 (이미 있음):**
```
User-agent: *
Allow: /
Disallow: /admin/
Disallow: /auth/
Disallow: /profile/edit
Sitemap: https://teovibe.com/sitemap.xml
```

**v1.2 추가 사항:**
```
User-agent: Googlebot
Allow: /

User-agent: Yeti
Allow: /

User-agent: *
Allow: /
Disallow: /admin/
Disallow: /auth/
Disallow: /sessions/
Disallow: /profile/edit

Sitemap: https://teovibe.com/sitemap.xml
```

**참고:** Yeti는 네이버 검색 크롤러의 공식 명칭. `User-agent: *` 규칙이 이미 Yeti를 허용하지만, 네이버 서치어드바이저 등록 시 명시적 선언이 크롤링 품질에 도움.

### 5. Google / 네이버 Search Console 인증

**동작 방식:**
- Google: `<meta name="google-site-verification" content="TOKEN">` — 홈페이지 head에 삽입
- Naver: `<meta name="naver-site-verification" content="TOKEN">` — 홈페이지 head에 삽입

**구현 패턴 (환경변수 기반):**

`config/initializers/seo.rb`:
```ruby
# 환경변수에서 토큰 로드 (없으면 nil, 메타태그 미출력)
GOOGLE_SITE_VERIFICATION = ENV["GOOGLE_SITE_VERIFICATION"]
NAVER_SITE_VERIFICATION = ENV["NAVER_SITE_VERIFICATION"]
```

`app/views/layouts/application.html.erb` (yield :head 전):
```erb
<% if defined?(GOOGLE_SITE_VERIFICATION) && GOOGLE_SITE_VERIFICATION.present? %>
  <meta name="google-site-verification" content="<%= GOOGLE_SITE_VERIFICATION %>">
<% end %>
<% if defined?(NAVER_SITE_VERIFICATION) && NAVER_SITE_VERIFICATION.present? %>
  <meta name="naver-site-verification" content="<%= NAVER_SITE_VERIFICATION %>">
<% end %>
```

또는 meta-tags gem 방식:
```ruby
# ApplicationController
set_meta_tags verification: {
  google: ENV["GOOGLE_SITE_VERIFICATION"],
  "naver-site-verification" => ENV["NAVER_SITE_VERIFICATION"]
}
```

**주의:** 인증 토큰은 절대 코드에 하드코딩 금지. `.env` 파일에 저장, `.gitignore`에 `.env*` 포함 확인.

### 6. Admin 게시글 에디터 2컬럼 레이아웃

**현재 레이아웃 문제:**
- 1컬럼 세로 나열: AI 패널 → 제목 → 카테고리 → 상태 → 예약 → 고정글 → 본문 에디터 → SEO 제목 → SEO 설명
- 본문 에디터에 집중하려면 SEO/설정 필드까지 스크롤해야 함
- SEO 필드가 폼 하단에 있어 자주 빠뜨리게 됨

**2컬럼 레이아웃 설계:**

```
┌─────────────────────────────┬──────────────────────┐
│  왼쪽 (flex-1, ~70%)         │  오른쪽 (~30%)        │
│                             │                      │
│  [AI 초안 작성 패널]          │  [게시 설정]          │
│                             │  - 카테고리           │
│  [제목 입력]                  │  - 상태              │
│                             │  - 예약 발행 시각      │
│  [본문 에디터 (rhino-editor)] │  - 고정글 토글        │
│  (높이 가득 차지)              │  - noindex 토글 (신규) │
│                             │                      │
│                             │  [SEO 설정]           │
│                             │  - SEO 제목           │
│                             │  - SEO 설명           │
│                             │                      │
│                             │  [저장/취소 버튼]      │
└─────────────────────────────┴──────────────────────┘
```

**구현 패턴:**

```erb
<%# admin/posts/_form.html.erb 구조 변경 %>
<%= form_with(model: [:admin, post]) do |f| %>
  <%# AI 패널 — 풀 width %>
  <div class="mb-4">
    <%= render "admin/posts/ai_panel", f: f %>
  </div>

  <%# 2컬럼 그리드 %>
  <div class="grid grid-cols-1 lg:grid-cols-[1fr_320px] gap-6 items-start">
    <%# 왼쪽: 제목 + 에디터 %>
    <div class="space-y-4">
      <%# 제목 필드 %>
      <%# rhino-editor %>
    </div>

    <%# 오른쪽: 메타/설정 %>
    <div class="space-y-4 lg:sticky lg:top-[100px]">
      <%# 카테고리, 상태, 예약, 고정글, noindex %>
      <%# SEO 제목, SEO 설명 %>
      <%# 저장 버튼 %>
    </div>
  </div>
<% end %>
```

**sticky 우측 패널:** `lg:sticky lg:top-[100px]`로 우측 설정 패널을 뷰포트에 고정시켜 긴 본문 편집 시에도 설정값 확인 가능.

**모바일 대응:** `grid-cols-1 lg:grid-cols-[1fr_320px]` — 모바일은 1컬럼(설정이 에디터 아래), 데스크탑은 2컬럼.

**AI 패널 위치:** 2컬럼 밖 풀 width 영역에 배치. 레이아웃 변경이 AI 패널 기능에 영향 없어야 함.

---

## MVP Definition

### Launch With (v1.2 이번 밀스톤)

- [ ] robots.txt 보강 (Yeti 명시, /sessions/ 추가) — 정적 파일 수정, 5분
- [ ] ApplicationController 기본 meta 태그 전역 설정 (site, description, og 기본값) — LOW
- [ ] 게시글 상세 Open Graph 메타태그 (`set_meta_tags` 컨트롤러 호출) — LOW
- [ ] Twitter Card `summary_large_image` 타입 전역 설정 — LOW
- [ ] canonical URL 자기 참조 (ApplicationController before_action) — LOW
- [ ] Admin 레이아웃 noindex 전역 처리 — LOW (한 줄)
- [ ] 인증 관련 페이지 noindex 처리 — LOW
- [ ] JSON-LD 게시글 상세 Article + BreadcrumbList 렌더링 — LOW (헬퍼 이미 정의됨)
- [ ] JSON-LD 홈페이지 WebSite + Organization 렌더링 — LOW
- [ ] Google Search Console 인증 메타태그 (환경변수 기반) — LOW
- [ ] 네이버 서치어드바이저 인증 메타태그 (환경변수 기반) — LOW
- [ ] Admin 게시글 에디터 2컬럼 레이아웃 (_form.html.erb 리팩터링) — MEDIUM
- [ ] 기본 OGP 이미지 (`public/opengraph-default.png`, 1200x630px) — LOW (에셋 준비)

### Add After Validation (v1.x)

- [ ] og:image 본문 첫 번째 이미지 자동 추출 (Post 모델 메서드) — MEDIUM (ActionText 첨부 이미지 URL 접근 방식 조사 필요)
- [ ] noindex 토글 — 게시글별 Admin 설정 (Post 모델 컬럼 추가 필요) — MEDIUM
- [ ] JSON-LD 카테고리 목록 ItemList + BreadcrumbList — LOW (각 카테고리 컨트롤러 추가)
- [ ] JSON-LD 스킬팩 상세 SoftwareApplication — LOW
- [ ] sitemap ping 후처리 (게시글 발행 after_commit 콜백) — LOW

### Future Consideration (v2+)

- [ ] Core Web Vitals 최적화 (LCP 이미지 preload, CLS 방지) — 트래픽 증가 후 의미 있음
- [ ] 이미지 최적화 파이프라인 (WebP 변환, responsive srcset) — 별도 마일스톤
- [ ] AI 초안 생성 시 SEO 제목/설명 자동 제안 — AI 기능 고도화 마일스톤

---

## Feature Prioritization Matrix

| Feature | User Value | Implementation Cost | Priority |
|---------|------------|---------------------|----------|
| robots.txt 보강 | LOW | LOW | P1 (5분 작업) |
| 전역 기본 OG 메타태그 | HIGH | LOW | P1 |
| 게시글 상세 OG 메타태그 | HIGH | LOW | P1 |
| Twitter Card 설정 | MEDIUM | LOW | P1 |
| canonical URL 처리 | MEDIUM | LOW | P1 |
| Admin/인증 noindex | MEDIUM | LOW | P1 |
| JSON-LD Article 렌더링 | MEDIUM | LOW | P1 (헬퍼 이미 있음) |
| JSON-LD WebSite/Organization 렌더링 | LOW | LOW | P1 |
| Google/네이버 SC 인증 | HIGH | LOW | P1 |
| OGP 기본 이미지 에셋 준비 | HIGH | LOW | P1 |
| Admin 에디터 2컬럼 레이아웃 | HIGH | MEDIUM | P1 |
| og:image 자동 추출 | MEDIUM | MEDIUM | P2 |
| noindex 토글 (게시글별) | MEDIUM | MEDIUM | P2 |
| JSON-LD 목록/스킬팩 | LOW | LOW | P2 |
| sitemap ping 후처리 | LOW | LOW | P2 |

**Priority key:**
- P1: 이번 밀스톤(v1.2) 필수
- P2: 이번 밀스톤 내 여유 시 또는 바로 다음 PR
- P3: 차기 밀스톤

---

## Competitor Feature Analysis

| Feature | Ghost (블로그 플랫폼) | WordPress | TeoVibe v1.1 현황 | TeoVibe v1.2 목표 |
|---------|---------------------|-----------|-------------------|-------------------|
| Open Graph 메타태그 | 자동 생성 | Yoast SEO 플러그인 | 미구현 (gem 설치만) | 컨트롤러별 set_meta_tags |
| Twitter Card | 자동 생성 | Yoast SEO | 미구현 | summary_large_image 전역 |
| JSON-LD 구조화 데이터 | Article, BreadcrumbList 자동 | Yoast가 자동 생성 | 헬퍼 정의만, 렌더링 안 됨 | 뷰에 script 태그 삽입 |
| canonical URL | 자동 설정 | Yoast 자동 | 미구현 | before_action 전역 처리 |
| noindex 설정 | 게시글별 토글 | Yoast 게시글별 토글 | 미구현 | Admin 레이아웃 전역 + 게시글별 (P2) |
| Search Console 인증 | HTML 파일 업로드 권장 | 플러그인 | 미구현 | 메타태그 방식, 환경변수 |
| 에디터 레이아웃 | 2컬럼 (본문+사이드바) | 2컬럼 (본문+사이드바) | 1컬럼 세로 나열 | 2컬럼 (본문+설정 사이드바) |
| robots.txt 관리 | Admin UI에서 편집 | Admin UI에서 편집 | 정적 파일, 기본 설정만 | 정적 파일 수동 보강 |

**Key insight:** Ghost와 WordPress Admin 모두 에디터 2컬럼 레이아웃을 표준으로 사용한다. 우측 사이드바에 발행 설정 + SEO 설정이 배치되는 패턴이 CMS 업계 표준. OG/JSON-LD는 두 플랫폼 모두 자동 생성하는 기능 — TeoVibe에서는 수동 구현이 필요하나 Rails meta-tags gem과 기존 헬퍼 덕분에 실제 작업량은 적음.

---

## Sources

- meta-tags gem 공식 GitHub: [https://github.com/kpumuk/meta-tags](https://github.com/kpumuk/meta-tags) — HIGH confidence (공식)
- meta-tags gem 설정 체크시트: [https://devhints.io/meta-tags](https://devhints.io/meta-tags) — MEDIUM confidence (커뮤니티 레퍼런스)
- Google 공식 특수 메타태그 문서: [https://developers.google.com/search/docs/crawling-indexing/special-tags](https://developers.google.com/search/docs/crawling-indexing/special-tags) — HIGH confidence (공식)
- Google Search Console 소유권 확인: [https://support.google.com/webmasters/answer/9008080](https://support.google.com/webmasters/answer/9008080) — HIGH confidence (공식)
- 네이버 서치어드바이저 메타태그 인증: [https://seo.tbwakorea.com/blog/robots-txt-complete-guide/](https://seo.tbwakorea.com/blog/robots-txt-complete-guide/) — MEDIUM confidence (검증된 한국 SEO 에이전시)
- BreadcrumbList Schema.org: [https://schema.org/BreadcrumbList](https://schema.org/BreadcrumbList) — HIGH confidence (공식)
- Open Graph protocol 공식: [https://ogp.me/](https://ogp.me/) — HIGH confidence (공식)
- Twitter Card 메타태그 가이드 2025: [https://www.everywheremarketer.com/blog/ultimate-guide-to-social-meta-tags-open-graph-and-twitter-cards](https://www.everywheremarketer.com/blog/ultimate-guide-to-social-meta-tags-open-graph-and-twitter-cards) — MEDIUM confidence (WebSearch, 다수 출처 일치)
- Rails canonical URL 구현: [https://avohq.io/blog/canonical-urls-rails](https://avohq.io/blog/canonical-urls-rails) — MEDIUM confidence (검증된 Rails 블로그)
- canonical + noindex 혼용 가이드: [https://sitechecker.pro/site-audit-issues/canonicalized-url-noindex-nofollow/](https://sitechecker.pro/site-audit-issues/canonicalized-url-noindex-nofollow/) — MEDIUM confidence
- Yeti (NaverBot) 정보: [https://datadome.co/bots/naverbot/](https://datadome.co/bots/naverbot/) — HIGH confidence
- robots.txt SEO 가이드 2025: [https://increv.co/academy/seo/robots-txt/](https://increv.co/academy/seo/robots-txt/) — MEDIUM confidence (WebSearch)
- Admin 2컬럼 에디터 UX 패턴: [https://github.com/payloadcms/payload/discussions/5181](https://github.com/payloadcms/payload/discussions/5181) — MEDIUM confidence (PayloadCMS 공식 토론, 2컬럼 메타 사이드바 표준 언급)

---

*Feature research for: SEO 최적화 + Admin 에디터 UX (v1.2)*
*Researched: 2026-03-14*
