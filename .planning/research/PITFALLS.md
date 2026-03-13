# Pitfalls Research

**Domain:** SEO 최적화 + Admin 2-column 에디터 레이아웃 (Rails 8 + Hotwire/Turbo 기반 블로그/커뮤니티 플랫폼)
**Researched:** 2026-03-14
**Confidence:** MEDIUM-HIGH (Naver-specific 부분은 공식 문서가 제한적이어서 MEDIUM, 나머지는 HIGH)

> Note: 이 파일은 v1.2 마일스톤 전용 연구다. v1.1 pitfalls(Category 마이그레이션, AI 초안, 예약 발행)는 이미 해결됨.
> 기존 코드베이스 확인 사항:
> - `seo_helper.rb` 이미 존재 (JSON-LD 헬퍼 6종 구현됨)
> - `robots.txt` 기본 구성 완료, Yeti 전용 블록 없음
> - `sitemap.rb` 카테고리 slug 하드코딩 방식
> - `display_meta_tags` 레이아웃 적용됨, `set_meta_tags` 뷰 호출 없음
> - `admin/posts/_form.html.erb` 단일 컬럼 레이아웃

---

## Critical Pitfalls

### Pitfall 1: JSON-LD `.to_json.html_safe`의 XSS 취약점

**What goes wrong:**
`seo_helper.rb`의 `.to_json.html_safe` 패턴이 XSS 취약점을 내포한다. `post.title`, `post.user.nickname` 등 사용자가 입력한 콘텐츠가 JSON-LD `<script>` 태그에 삽입될 때, 악성 문자열이 `</script>` 시퀀스를 포함하면 스크립트 태그를 강제 종료하고 임의 HTML을 주입할 수 있다.

예: post.title에 `바이브코딩</script><script>alert(1)//` 삽입 시 브라우저가 실행.

**Why it happens:**
Ruby의 `Hash#to_json`은 `<`, `>`, `&` 문자를 HTML-safe하게 이스케이프하지 않는다. `html_safe` 표시는 Rails의 자동 XSS 방어를 비활성화한다. `article_json_ld(post)`, `website_json_ld`, `item_list_json_ld` 등 현재 구현된 6개 헬퍼가 모두 동일한 취약 패턴을 사용한다.

**How to avoid:**
모든 JSON-LD 출력에 Unicode 이스케이프 처리를 추가한다:

```ruby
# seo_helper.rb에 private 메서드로 추가
def safe_json_ld(data)
  data.to_json
      .gsub('<', '\u003c')
      .gsub('>', '\u003e')
      .gsub('&', '\u0026')
      .html_safe
end
```

또는 Rails의 `json_escape` 헬퍼 활용 (ERB에서 직접 사용):

```erb
<script type="application/ld+json">
  <%= json_escape(article_json_ld(@post)) %>
</script>
```

seo_helper.rb의 모든 public 메서드가 `safe_json_ld` 래퍼를 통해 반환하도록 통일한다.

**Warning signs:**
- Brakeman 스캐너 실행 시 `Cross-Site Scripting (JSON)` 경고 출력
- post.title에 `<script>` 문자열 포함 시 JSON-LD 검증 도구에서 파싱 오류 발생

**Phase to address:**
Phase 1 이전 사전 패치. 새 JSON-LD 추가 전에 기존 seo_helper.rb를 반드시 먼저 수정.

---

### Pitfall 2: Naver Yeti 봇 robots.txt 명시 부재로 서치어드바이저 진단 오류

**What goes wrong:**
현재 `robots.txt`는 `User-agent: *`로 전체 허용하지만, Naver Search Advisor 등록 시 Yeti 봇 전용 블록이 없으면 서치어드바이저 내부 진단 시스템이 "허용 여부 불명확"으로 처리할 수 있다. 더 큰 문제는 Yeti 봇을 서버 방화벽/Rack::Attack에서 비정상 트래픽으로 차단하면, 서치어드바이저 대시보드에서 "수집 차단됨" 오류가 발생하고 인덱싱 진단 기능이 비활성화된다.

Yeti는 JavaScript 렌더링 능력이 Google보다 제한적이다(공식 문서에 명시 없음, MEDIUM confidence). Turbo Drive의 클라이언트 네비게이션 이후 콘텐츠가 변경되어도 Yeti는 초기 SSR HTML만 크롤링하므로, 서버 사이드 렌더링이 각 URL에서 올바른 콘텐츠를 제공하는지가 핵심이다.

**Why it happens:**
- `User-agent: *`는 Yeti를 포함하지만 Naver 공식 가이드라인은 `User-agent: Yeti` 명시적 블록을 권장한다
- Yeti IP 대역이 공식 공개되지 않아 IP 기반 차단이 불가피하게 발생하는 경우 있음
- Kamal 배포 환경에서 Docker 컨테이너 레벨의 방화벽 설정이 크롤러를 차단하는 사례 발생

**How to avoid:**
robots.txt에 Yeti 전용 블록을 명시적으로 추가한다:

```
User-agent: Yeti
Allow: /
Disallow: /admin/
Disallow: /auth/
Disallow: /profile/edit

User-agent: *
Allow: /
Disallow: /admin/
Disallow: /auth/
Disallow: /profile/edit

Sitemap: https://teovibe.com/sitemap.xml
```

Rack::Attack 설정이 있다면 크롤러 User-Agent를 명시적 safelist에 추가한다. IP 기반 Yeti 차단은 절대 금지 (IP 대역 수시 변경됨).

**Warning signs:**
- Naver Search Advisor 대시보드에서 "수집 오류" 또는 "로봇 미허용" 상태 표시
- 서버 액세스 로그에서 `Yeti/1.1` User-Agent가 403/429 응답을 받는 경우

**Phase to address:**
Phase 1 (robots.txt 구성). sitemap 경로 추가와 동시에 처리.

---

### Pitfall 3: `naver-site-verification` 메타태그가 Turbo Drive 후 소실되거나 잘못된 위치에 삽입

**What goes wrong:**
`naver-site-verification` 메타태그를 특정 뷰나 컨트롤러의 `set_meta_tags` 통해 조건부로 삽입하면 루트 URL 외의 경로에서 태그가 없어 인증이 실패한다. Naver Search Advisor는 인증을 `https://teovibe.com/`(루트)에서만 검증한다.

또한 메타태그를 `<frame>` 태그 안에 삽입하면 Naver가 인식하지 못한다(Naver 공식 명시). Rails의 `yield :head` 블록이나 Turbo Frame 내에서 인증 태그를 삽입하면 검증 실패.

**Why it happens:**
- `display_meta_tags`가 기본값을 제공하고 각 뷰가 override하는 패턴에서, 인증 태그를 실수로 특정 뷰에만 배치
- `yield :head` 안에 인증 태그를 배치하면 해당 뷰가 렌더링될 때만 `<head>`에 존재
- Google, Naver 인증 태그를 비슷한 패턴으로 처리하다가 하나는 고정, 하나는 조건부가 되는 실수

**How to avoid:**
`application.html.erb` 레이아웃에 직접 하드코딩으로 고정 삽입한다. `set_meta_tags`를 사용하지 않는다:

```erb
<%# application.html.erb의 <head> 내 고정 위치 %>
<% if ENV['NAVER_SITE_VERIFICATION'].present? %>
  <meta name="naver-site-verification" content="<%= ENV['NAVER_SITE_VERIFICATION'] %>" />
<% end %>
<% if ENV['GOOGLE_SITE_VERIFICATION'].present? %>
  <meta name="google-site-verification" content="<%= ENV['GOOGLE_SITE_VERIFICATION'] %>" />
<% end %>
```

ENV 값을 `.kamal/secrets`에 등록하고 `config/application.yml` 또는 Kamal env 블록으로 주입한다.

**Warning signs:**
- Naver Search Advisor "소유권 확인 실패" 오류 (인증 직후)
- Google Search Console "메타태그를 찾을 수 없음" 오류
- 루트 URL에서만 태그가 있고 다른 URL에서는 없는 경우 (HTML 검사로 확인)

**Phase to address:**
Phase 2 (검색엔진 인증 메타태그).

---

### Pitfall 4: `og:image` 상대 경로 사용으로 소셜 공유 미리보기 실패

**What goes wrong:**
`og:image`에 `/og-default.png` 같은 상대 경로를 사용하면 카카오톡, 네이버 블로그, 페이스북, 트위터 공유 시 이미지가 표시되지 않는다. OG 크롤러는 절대 URL을 요구한다.

Rails의 `image_path` 헬퍼는 `config.action_controller.asset_host`가 미설정이면 상대 경로를 반환한다. 개발환경에서는 로컬호스트 URL로 보여 정상처럼 보이지만, 실제 소셜 크롤러는 로컬호스트에 접근 불가.

현재 코드베이스에 `asset_host` 설정이 없음(코드베이스 확인).

**Why it happens:**
- `set_meta_tags og: { image: image_path("og-default.png") }` 패턴의 흔한 오용
- `image_path`와 `image_url`의 차이를 인지하지 못하는 경우
- `seo_helper.rb`에 이미지 URL 처리 로직이 없어, 뷰에서 직접 호출하면 상대 경로가 생성됨

**How to avoid:**
`config/environments/production.rb`에 `asset_host` 설정:

```ruby
config.asset_host = "https://teovibe.com"
```

모든 OG 이미지 참조에서 `image_path` 대신 `image_url` 사용:

```ruby
set_meta_tags og: {
  image: image_url("og-default.png"),  # 절대 URL 생성
  image_width: 1200,
  image_height: 630,
  image_type: "image/png"
}
```

게시글 대표 이미지가 없을 경우를 위한 기본 OG 이미지(`public/og-default.png`, 1200x630px)를 미리 준비한다.

**Warning signs:**
- 카카오톡/네이버 블로그에 링크 공유 시 이미지 없이 텍스트만 표시됨
- Facebook Sharing Debugger에서 "og:image could not be processed" 오류
- OG 이미지 URL이 `/og-default.png` 형식(상대 경로)으로 렌더링됨

**Phase to address:**
Phase 3 (OG/Twitter Card 메타태그 보강).

---

### Pitfall 5: `sitemap.xml`에 noindex 페이지 또는 카테고리 slug 하드코딩으로 신규 카테고리 누락

**What goes wrong:**
두 가지 독립적인 문제가 있다:

1. **noindex 페이지의 sitemap 포함**: `noindex: true` 처리된 페이지(Admin 경로, 사용자 프로필, 알림, 포인트 내역 등)가 sitemap에 포함되면 검색엔진에 혼란을 주고 크롤 버짓을 낭비한다. Google은 sitemap과 noindex의 모순을 "noindex 우선"으로 처리하지만, 경고를 발생시킨다.

2. **카테고리 slug 하드코딩 (`sitemap.rb`)**: 현재 `sitemap.rb`는 `when "blog"`, `when "tutorial"` 등 6개 슬러그를 case/when으로 하드코딩한다. v1.1에서 카테고리 CRUD가 구현되어 관리자가 새 카테고리를 추가할 수 있게 됐지만, 신규 카테고리는 sitemap에 자동으로 반영되지 않는다. 신규 카테고리 게시글이 sitemap에서 누락된 채 배포된다.

**Why it happens:**
- sitemap.rb가 v1.0 때 정적 카테고리를 가정하고 작성된 이후 v1.1 카테고리 동적화 때 업데이트되지 않음
- noindex 처리 대상 목록이 명시적으로 관리되지 않아 sitemap 제외 여부를 개별 확인해야 함

**How to avoid:**
sitemap.rb의 카테고리 루프를 동적으로 교체한다:

```ruby
# 카테고리 인덱스 (동적 처리)
Category.for_posts.ordered.each do |category|
  begin
    path = category_posts_path(category_slug: category.slug)
    add path, changefreq: "daily", priority: 0.8
  rescue ActionController::UrlGenerationError
    # 라우트 없는 카테고리 skip
  end
end

# 게시글 (동적 처리)
Post.published.includes(:category).find_each do |post|
  next unless post.category&.slug
  begin
    # route_key 메서드 활용
    url = url_for(post.route_key + [only_path: false])
    add url, lastmod: post.updated_at, changefreq: "weekly", priority: 0.8
  rescue
    next
  end
end
```

noindex 처리 예정 페이지는 sitemap에 절대 추가하지 않는다(현재 sitemap.rb 검토 기준으로 현재는 괜찮음).

**Warning signs:**
- 새 카테고리를 Admin에서 추가했지만 sitemap.xml에 누락됨
- Google Search Console에서 "사이트맵에서 제외됨 - noindex로 인해" 경고 다수 발생

**Phase to address:**
Phase 1 (robots.txt/sitemap 기초 SEO). sitemap.rb 동적화는 robots.txt 작업과 동시에 처리.

---

### Pitfall 6: `canonical`과 `noindex` 동시 적용으로 SEO 신호 충돌

**What goes wrong:**
Admin 경로, 사용자 프로필 편집, 알림 등 noindex 처리 페이지에 canonical URL이 함께 설정되면 검색엔진에 상충하는 신호를 보낸다. Google John Mueller 공식 권고: "둘 중 하나만 사용하라". noindex+canonical 동시 사용 시 canonical 대상 URL의 신뢰도가 하락할 수 있다.

현재 코드베이스에서 레이아웃 수준의 `display_meta_tags`는 전역 기본값을 렌더링하므로, canonical을 전역 설정하면 noindex 처리 페이지에도 canonical이 함께 출력된다.

**Why it happens:**
- meta-tags gem의 기본 동작: `set_meta_tags noindex: true`를 뷰에서 호출해도, 레이아웃에서 canonical을 전역으로 설정한 경우 noindex 페이지에도 canonical이 렌더링됨
- Admin 레이아웃(`admin.html.erb`)에 `noindex: true`를 전역 설정하는 것을 잊어버림

**How to avoid:**
meta-tags gem 설정으로 자동 처리:

```ruby
# config/initializers/meta_tags.rb
MetaTags.configure do |config|
  config.skip_canonical_links_on_noindex = true  # noindex 페이지의 canonical 자동 제거
end
```

Admin 레이아웃에 전역 noindex 설정:

```erb
<%# layouts/admin.html.erb의 <head> %>
<meta name="robots" content="noindex, nofollow" />
```

**Warning signs:**
- Google Search Console에서 "canonical이 noindex 페이지를 가리킴" 경고
- noindex 페이지를 HTML 검사 시 `<link rel="canonical">` 태그가 동시에 존재

**Phase to address:**
Phase 4 (canonical / noindex 처리).

---

### Pitfall 7: `request.original_url`을 canonical로 사용 시 쿼리 파라미터 포함 문제

**What goes wrong:**
canonical URL에 `request.original_url`을 사용하면 `?page=2`, `?sort=latest`, `?turbo_stream=1` 같은 쿼리 파라미터가 포함된 URL이 canonical로 설정된다. 페이지네이션 URL이 각각 다른 canonical을 가지면 크롤 버짓 낭비와 중복 콘텐츠 인식이 발생한다.

**Why it happens:**
뷰에서 `set_meta_tags canonical: request.original_url` 처럼 편의상 `request.original_url`을 사용하는 경우 흔히 발생. Turbo Streams 요청에서 URL에 내부 파라미터가 붙는 경우도 있다.

**How to avoid:**
canonical에는 반드시 쿼리 파라미터 없는 라우트 헬퍼를 사용한다:

```ruby
# 게시글 상세 페이지
set_meta_tags canonical: post_url(@post)  # request.original_url 사용 금지

# 목록 페이지 (1페이지 canonical)
set_meta_tags canonical: category_posts_url(category_slug: @category.slug)
```

**Warning signs:**
- sitemap.xml URL과 실제 페이지의 canonical URL이 다른 경우
- Google Search Console에서 "사용자가 선택한 canonical과 다름" 경고

**Phase to address:**
Phase 4 (canonical / noindex 처리). OG 태그 설정 시 동시에 검토.

---

### Pitfall 8: Admin 2-column 레이아웃에서 rhino-editor 높이와 sticky 사이드바 충돌

**What goes wrong:**
`rhino-editor` 웹 컴포넌트는 기본적으로 `display: block`으로 렌더링되며, 내부 TipTap 에디터의 높이가 콘텐츠에 따라 가변적이다. 2컬럼 CSS Grid 레이아웃에서 왼쪽(메타 정보)을 sticky 사이드바로 고정하면, 왼쪽 컬럼 높이가 오른쪽(에디터) 컬럼 높이를 따라가지 못해 sticky가 작동하지 않는 현상이 발생한다.

Tailwind CSS의 `sticky` 포지셔닝은 부모 컨테이너의 `overflow` 속성에 영향을 받는다. Grid 또는 Flex 컨테이너의 `overflow: hidden`이 설정되면 sticky가 무력화된다.

**Why it happens:**
- CSS Grid의 `align-items: stretch` 기본값으로 인해 두 컬럼이 동일 높이로 맞춰짐
- `sticky` 포지셔닝이 grid cell 내에서 작동하려면 grid cell 자체가 스크롤 컨테이너여야 함
- Tailwind `prose` 클래스가 rhino-editor 내부 콘텐츠 스타일과 충돌할 수 있음(prose는 자식 요소에 cascade)

**How to avoid:**
2컬럼 레이아웃 구조:

```html
<%# 2컬럼 그리드: 오른쪽(에디터)이 메인, 왼쪽(메타)이 sticky %>
<div class="grid grid-cols-1 lg:grid-cols-[380px_1fr] gap-6 items-start">
  <%# 왼쪽: 메타 정보 (sticky) %>
  <div class="lg:sticky lg:top-6 space-y-4">
    <%# 카테고리, 상태, SEO 필드 등 %>
  </div>

  <%# 오른쪽: 에디터 (스크롤 허용) %>
  <div class="space-y-4 min-h-[600px]">
    <%# rhino-editor %>
  </div>
</div>
```

`items-start`는 sticky가 작동하기 위해 필수 (기본 `stretch` 대신). 부모 컨테이너에 `overflow: hidden` 사용 금지.

**Warning signs:**
- 긴 글 작성 시 왼쪽 메타 패널이 화면 밖으로 스크롤되어 사라짐
- `position: sticky`가 적용됐지만 실제로 고정되지 않음 (부모 `overflow` 확인 필요)
- 모바일(375px)에서 에디터와 메타 필드가 겹치거나 레이아웃 깨짐

**Phase to address:**
Phase 5 (Admin 에디터 2-column 레이아웃 구현).

---

### Pitfall 9: seo_title/seo_description 미입력 시 OG 태그 fallback 미구현

**What goes wrong:**
게시글의 `seo_title`과 `seo_description`이 비어있을 때 OG 태그에 값이 없으면 소셜 공유 시 제목 없음 또는 사이트 기본값이 표시된다. 현재 `post_params`에 `:seo_title`, `:seo_description`이 허용되어 있지만, 뷰에서 이를 OG 태그로 연결하는 로직이 없다.

**Why it happens:**
SEO 필드를 저장하는 기능과 실제로 메타태그에 사용하는 기능이 분리되어 구현될 때 발생. 필드는 있지만 사용되지 않는 "half-implemented" 상태.

**How to avoid:**
`posts/show.html.erb`에 항상 fallback 체인을 적용:

```erb
<%
  seo_title = @post.seo_title.presence || @post.title
  seo_desc  = @post.seo_description.presence || @post.body.to_plain_text.truncate(160)
  set_meta_tags(
    title:       seo_title,
    description: seo_desc,
    canonical:   post_url(@post),
    og: {
      title:       seo_title,
      description: seo_desc,
      type:        "article",
      url:         post_url(@post),
      image:       image_url("og-default.png")
    },
    twitter: {
      card:        "summary_large_image",
      title:       seo_title,
      description: seo_desc
    }
  )
%>
```

`@post.body.to_plain_text`는 ActionText 리치 텍스트에서 HTML을 제거한 순수 텍스트를 반환한다.

**Warning signs:**
- 소셜 공유 시 제목이 "TeoVibe" 사이트 기본값으로 표시됨
- og:description이 빈 문자열로 렌더링됨

**Phase to address:**
Phase 3 (OG/Twitter Card 메타태그 보강).

---

## Technical Debt Patterns

| Shortcut | Immediate Benefit | Long-term Cost | When Acceptable |
|----------|-------------------|----------------|-----------------|
| `sitemap.rb` 카테고리 slug 하드코딩 유지 | 구현 단순, 직관적 | 신규 카테고리 추가 시 sitemap 누락 (관리자가 코드 수정 필요) | v1.2에서 동적으로 교체 권장. 유지 불가 |
| `seo_helper.rb`의 `.to_json.html_safe` 유지 | 간결한 코드 | XSS 취약점 (admin-only라도 안전 관행 필요) | 절대 허용 안 됨 |
| OG 이미지 없이 SEO 배포 | 초기 구현 빠름 | 소셜 공유 미리보기 없음, 클릭률 감소 | 최종 공개 전에는 수용 가능하나 배포 전 반드시 추가 |
| canonical을 `request.original_url`로 설정 | 편의성 | 쿼리 파라미터 포함 시 비정규 canonical | 절대 허용 안 됨 |
| Admin 레이아웃 noindex를 ERB 직접 삽입 대신 meta-tags gem으로 설정 | 일관성 | `set_meta_tags`를 admin 전용 before_action에 넣어야 함 | meta-tags gem 사용이 더 일관적이나 ERB 직접 삽입이 간단하고 신뢰성 높음 |

---

## Integration Gotchas

| Integration | Common Mistake | Correct Approach |
|-------------|----------------|------------------|
| Naver Search Advisor 인증 | HTML 파일 업로드 방식 -- Kamal 재배포 시 파일이 Docker 이미지에 포함되지 않으면 인증 실패 | 메타태그 방식 사용, `application.html.erb`에 ENV 변수로 고정 삽입 |
| Google Search Console | `google-site-verification` 태그를 특정 뷰에만 삽입 | 루트 레이아웃에 고정 삽입 (모든 경로에서 접근 가능해야 함) |
| `sitemap_generator` | `rake sitemap:refresh` 없이 배포하면 sitemap.xml이 갱신되지 않음 | Kamal deploy hook 또는 cron(Solid Queue)으로 자동화 고려 |
| meta-tags gem + Turbo Drive | `set_meta_tags`를 호출하지 않은 페이지에서 이전 페이지 title 유지 | 최소한 레이아웃에서 기본값 설정, 뷰에서 override |
| JSON-LD + ActionText body | `post.body` (ActionText::RichText)를 JSON-LD description으로 직접 사용 | `post.body.to_plain_text.truncate(160)` 으로 HTML 제거 후 사용 |
| rhino-editor + 2-column Grid | sticky 사이드바가 grid의 `align-items: stretch` 기본값으로 무력화됨 | 부모 grid에 `items-start` 반드시 추가 |
| Naver Search Advisor 소유권 인증 후 URL 관리 | 서브폴더(예: `/blog`) 단위 등록 시도 -- Naver는 서브폴더 미지원 | 도메인 또는 서브도메인 단위로만 등록 (`https://teovibe.com`) |

---

## Performance Traps

| Trap | Symptoms | Prevention | When It Breaks |
|------|----------|------------|----------------|
| sitemap 생성 시 N+1 쿼리 (`post.category` 별도 쿼리) | `rake sitemap:refresh` 속도 저하 | `Post.published.includes(:category).find_each` 사용 | 게시글 500건 이상 |
| Admin 에디터 폼마다 `Category.for_posts.ordered` 호출 | 불필요한 쿼리 반복 | 카테고리 목록을 `Rails.cache.fetch`로 캐싱 (TTL 5분) | 카테고리 수 증가 + 관리자 동시 접속 시 |
| `post.body.to_plain_text`를 OG description 생성마다 실행 | 리치 텍스트 파싱 비용이 매 요청마다 발생 | `seo_description` 컬럼이 비어있을 때만 fallback 계산, 결과를 저장 | 일 10만 PV 이상, 롱-폼 콘텐츠 비중 높을 때 |

---

## Security Mistakes

| Mistake | Risk | Prevention |
|---------|------|------------|
| `seo_helper.rb`의 `.to_json.html_safe` 유지 | 사용자 콘텐츠가 JSON-LD 스크립트 태그를 이탈하는 XSS | `json_escape` 또는 Unicode 이스케이프 래퍼 사용 |
| `seo_title`, `seo_description`을 `h()` 없이 og 태그에 삽입 | Admin이 악의적 메타 값 삽입 시 XSS 가능 | meta-tags gem은 자체 escape 처리하나, 직접 ERB 삽입 시 `<%= h(@post.seo_title) %>` 명시 |
| `ENV['NAVER_SITE_VERIFICATION']` 값을 `.env`에 커밋 | 인증 키 노출 (위험도는 낮으나 관행상 비권장) | `.env`는 gitignore 처리, Kamal secrets에 등록 |
| robots.txt에서 sitemap URL을 `http://`로 선언 | 크롤러가 http로 접근 후 https 리다이렉트 만남 (불필요한 리다이렉트 체인) | `Sitemap: https://teovibe.com/sitemap.xml` (현재 올바름, 변경 금지) |

---

## UX Pitfalls

| Pitfall | User Impact | Better Approach |
|---------|-------------|-----------------|
| Admin 2-column 레이아웃 모바일 미대응 | 모바일에서 에디터와 메타 필드가 겹치거나 너무 좁음 | `grid-cols-1 lg:grid-cols-[380px_1fr]` 반응형 분기. 모바일에서 세로 스택 |
| SEO 필드(seo_title, seo_description)에 글자수 표시 없음 | Admin이 title 60자, description 160자 권장 범위 초과 여부 모름 | Stimulus 컨트롤러로 실시간 글자수 + 권장 범위 색상 표시 (간단한 5줄 구현) |
| rhino-editor 최소 높이 미설정으로 에디터 너무 작음 | 작성 화면이 좁아 불편 | 에디터 컬럼에 `min-h-[600px]` 지정 |
| seo_title 비어있을 때 OG 태그 fallback 없음 | 소셜 공유 시 제목이 비어있거나 사이트 기본값으로 표시 | `@post.seo_title.presence \|\| @post.title` 패턴을 모든 OG 설정에 적용 |
| Admin 에디터에서 SEO 미리보기 없음 | seo_title, seo_description 입력 결과가 어떻게 보일지 모름 | 글자수 표시로 충분 (Google/Naver 미리보기 시뮬레이션은 과도한 구현) |

---

## "Looks Done But Isn't" Checklist

- [ ] **JSON-LD XSS 패치**: `seo_helper.rb`의 모든 `.to_json.html_safe` 호출이 `json_escape` 또는 Unicode 이스케이프로 보호되어 있는지 확인. Brakeman 경고 0건 확인
- [ ] **robots.txt Yeti 블록**: `User-agent: Yeti` 명시적 블록이 추가되어 있는지 확인
- [ ] **naver-site-verification 고정 삽입**: 태그가 `application.html.erb`에 직접 삽입되어 있는지, Turbo 네비게이션 후에도 `<head>` DOM에 존재하는지 브라우저 확인
- [ ] **og:image 절대 URL**: 모든 OG 이미지 URL이 `https://teovibe.com/...` 형식인지 확인. `image_path` 대신 `image_url` 사용 여부
- [ ] **canonical URL 파라미터 제거**: `canonical: request.original_url` 사용 금지. 라우트 헬퍼(`post_url(@post)`) 사용 여부
- [ ] **noindex + canonical 충돌**: `MetaTags.config.skip_canonical_links_on_noindex = true` 설정 확인. noindex 페이지 HTML에 canonical 태그가 없는지 확인
- [ ] **Admin 레이아웃 noindex**: `/admin/**` 경로의 HTML에 `<meta name="robots" content="noindex">` 존재 여부 확인
- [ ] **sitemap 동적 카테고리**: 새 카테고리를 Admin에서 추가 후 `rake sitemap:refresh` 실행 시 sitemap.xml에 포함되는지 확인
- [ ] **2-column sticky 사이드바**: 긴 글 작성 시 왼쪽 메타 패널이 뷰포트에 고정되어 스크롤 따라 이동하는지 확인
- [ ] **2-column 반응형**: `375px` 모바일 너비에서 에디터가 단일 컬럼으로 올바르게 표시되는지 확인
- [ ] **seo_title fallback**: seo_title 비어있는 게시글의 og:title이 post.title로 fallback되는지 Facebook Sharing Debugger 또는 소셜 공유로 확인

---

## Recovery Strategies

| Pitfall | Recovery Cost | Recovery Steps |
|---------|---------------|----------------|
| JSON-LD XSS 취약점 발견 (배포 후) | LOW | seo_helper.rb 전체 JSON-LD 메서드에 `json_escape` 래퍼 즉시 추가 후 재배포. 10분 내 수정 가능 |
| Naver 인증 실패 (메타태그 위치 오류) | LOW | `application.html.erb`에 메타태그 고정 삽입 후 재배포. 서치어드바이저에서 재인증 클릭 |
| og:image 상대 경로 (이미 소셜 공유됨) | MEDIUM | `asset_host` 설정 + `image_url` 교체 후 재배포. Facebook Sharing Debugger "Scrape Again"으로 캐시 갱신. 카카오톡은 캐시 갱신 불가 (기존 공유 URL은 이미지 없음 유지됨) |
| sitemap에 noindex 페이지 포함 (이미 제출됨) | MEDIUM | sitemap.rb 수정 후 `rake sitemap:refresh`. Google Search Console에서 sitemap 재제출. 잘못 인덱싱된 URL은 "URL 삭제" 도구 활용 |
| canonical + noindex 충돌 (이미 인덱싱됨) | HIGH | 올바른 정책 적용 후 재배포. Google Search Console 재크롤링 요청. 인덱스 제거는 수주 소요 가능 |
| 2-column 레이아웃 sticky 미작동 | LOW | CSS `items-start` 추가 + 부모 `overflow` 확인. 순수 CSS 수정이므로 즉시 배포 가능 |

---

## Pitfall-to-Phase Mapping

| Pitfall | Prevention Phase | Verification |
|---------|------------------|--------------|
| JSON-LD XSS (`html_safe`) | Phase 0 (사전 패치, 즉시) | Brakeman 스캔 0 경고 + 특수문자 포함 게시글 JSON-LD 렌더링 확인 |
| Yeti 봇 robots.txt 명시 부재 | Phase 1 (robots.txt 구성) | Naver Search Advisor 진단 도구 "수집 허용" 상태 확인 |
| sitemap 카테고리 하드코딩 | Phase 1 (sitemap 보완) | 신규 카테고리 추가 후 sitemap.xml 포함 여부 확인 |
| naver-site-verification 위치 오류 | Phase 2 (검색엔진 인증) | 서치어드바이저 "소유권 확인 완료" 상태 확인 |
| og:image 상대 경로 | Phase 3 (OG/Twitter Card) | Facebook Sharing Debugger에서 이미지 정상 표시 확인 |
| seo_title fallback 미구현 | Phase 3 (OG/Twitter Card) | seo_title 비어있는 게시글 소셜 공유 테스트 |
| OG 메타태그 stale (Turbo) | Phase 3 (OG/Twitter Card) | 복수 게시글 순차 방문 후 `<head>` og:title 확인 |
| canonical + noindex 충돌 | Phase 4 (canonical/noindex) | `MetaTags.config` 설정 확인 + noindex 페이지 HTML 검사 |
| `request.original_url` canonical | Phase 4 (canonical/noindex) | 페이지네이션 URL 접근 시 canonical이 파라미터 없는 기본 URL인지 확인 |
| Admin 레이아웃 noindex 누락 | Phase 4 (canonical/noindex) | `/admin/posts` HTML에 noindex 메타 존재 확인 |
| rhino-editor sticky 충돌 | Phase 5 (Admin UX) | 긴 글 작성 시 사이드바 고정 동작 확인 |
| 2-column 반응형 누락 | Phase 5 (Admin UX) | 모바일(375px)에서 단일 컬럼 전환 확인 |

---

## Sources

- [BubbleShare: Naver Technical SEO 2024 Checklist](https://bubbleshare.io/blog/how-to-do-naver-technical-seo-2024-and-checklist) — Naver Search Advisor 공식 요구사항 (MEDIUM confidence)
- [Enhancing SEO in Rails Applications with Turbo](https://reintech.io/blog/enhancing-seo-rails-applications-turbo) — Turbo SEO 이슈 및 해결 패턴 (MEDIUM confidence)
- [meta-tags gem GitHub (kpumuk)](https://github.com/kpumuk/meta-tags) — `skip_canonical_links_on_noindex` 옵션 포함 (HIGH confidence)
- [Canonical URLs in Rails applications - Avo](https://avohq.io/blog/canonical-urls-rails) — Rails canonical URL 구현 패턴 (MEDIUM confidence)
- [Google: Don't Mix Noindex & Rel=Canonical - Search Engine Journal](https://www.searchenginejournal.com/google-dont-mix-noindex-relcanonical/262607/) — noindex + canonical 충돌 공식 권고 (HIGH confidence)
- [Brakeman: Cross Site Scripting (JSON)](https://brakemanscanner.org/docs/warning_types/cross_site_scripting_to_json/) — Rails JSON XSS 취약점 (HIGH confidence)
- [Sitemap Best Practices for Rails - Avo](https://avohq.io/blog/sitemap-for-rails-applications) — noindex/비정규 URL 제외 권장 사항 (MEDIUM confidence)
- [DataDome: What is NaverBot](https://datadome.co/bots/naverbot/) — Yeti 봇 기술 특성 (MEDIUM confidence)
- [Rails SEO Guide - Avo](https://avohq.io/rails-seo) — Rails SEO 종합 가이드 (MEDIUM confidence)
- 프로젝트 코드베이스 직접 분석: `seo_helper.rb`, `sitemap.rb`, `public/robots.txt`, `admin/posts/_form.html.erb`, `layouts/application.html.erb` (HIGH confidence)

---
*Pitfalls research for: v1.2 SEO 최적화 + Admin 에디터 2-column UX (Rails 8 + Hotwire)*
*Researched: 2026-03-14*
