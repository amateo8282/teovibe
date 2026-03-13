# Project Research Summary

**Project:** TeoVibe v1.2 — SEO 최적화 + Admin 에디터 UX 개선
**Domain:** Rails 8 monolith 기반 블로그/커뮤니티 플랫폼 SEO 고도화
**Researched:** 2026-03-14
**Confidence:** HIGH

## Executive Summary

TeoVibe v1.2 마일스톤은 신규 gem이나 npm 패키지 추가 없이 기존 스택만으로 완전히 구현 가능한 SEO 최적화 작업이다. 핵심 인프라(meta-tags gem 2.22.3, sitemap_generator 6.3.0, SeoHelper 전체 JSON-LD 헬퍼 6종)는 이미 코드베이스에 존재하지만 실제로 뷰에 연결되어 있지 않은 "절반만 구현된" 상태다. 즉, 이번 마일스톤 대부분의 작업은 새 코드 작성이 아니라 기존 컴포넌트를 올바르게 연결하는 배선(wiring) 작업이다.

구현 접근법은 두 트랙으로 분리된다. SEO 트랙은 레이아웃과 뷰에 `set_meta_tags` 호출 및 `content_for :head` JSON-LD 블록을 추가하는 작업으로, 아키텍처 변경 없이 진행된다. Admin UX 트랙은 `admin/posts/_form.html.erb`의 1컬럼 레이아웃을 CSS Grid 2컬럼으로 교체하는 작업으로, 모델/컨트롤러 변경 없이 순수 HTML + Tailwind 작업으로 처리된다. 두 트랙은 서로 독립적이라 병렬 개발이 가능하다.

가장 큰 위험 요소는 기존 `seo_helper.rb`의 XSS 보안 취약점이다. `.to_json.html_safe` 패턴이 사용자 입력이 포함된 JSON-LD에서 스크립트 인젝션을 허용한다. 이 패치는 새 JSON-LD를 뷰에 연결하기 전에 반드시 선행되어야 한다. 그 외 pitfall들(og:image 절대 URL 강제, canonical 쿼리 파라미터 제거, noindex+canonical 충돌, naver-site-verification 고정 삽입)은 모두 단일 설정 또는 한두 줄 수정으로 예방 가능하다.

## Key Findings

### Recommended Stack

v1.2의 모든 기능은 신규 gem/npm 패키지 추가 없이 구현 가능하다. 이미 설치된 `meta-tags` gem(2.22.3)이 OG, Twitter Card, canonical, noindex를 모두 처리하며, `sitemap_generator`(6.3.0)는 완전히 구성된 상태다. Admin 레이아웃은 Tailwind CSS v4.4의 `grid-cols-[380px_1fr]` arbitrary value 문법으로 2컬럼을 구현한다. 검색엔진 인증 토큰은 Rails credentials에 저장하는 것이 권장된다(Kamal 배포 환경에서 ENV 주입보다 일관성 높음).

**Core technologies:**
- `meta-tags` gem 2.22.3: OG, Twitter Card, canonical, noindex 메타태그 — 이미 레이아웃에 배선됨, 각 뷰에서 `set_meta_tags` 호출만 추가 필요
- `sitemap_generator` 6.3.0: sitemap.xml 생성 — 완전히 구성됨, 카테고리 동적화 수정만 필요
- Tailwind CSS 4.4 CSS Grid: Admin 2컬럼 레이아웃 — `grid-cols-[380px_1fr]` + `items-start` 패턴
- `SeoHelper` (기존): JSON-LD Article, BreadcrumbList, WebSite, Organization 등 6종 — 정의됨, 뷰 연결만 필요
- Rails credentials: 검색엔진 인증 토큰 저장 (`seo.google_site_verification`, `seo.naver_site_verification`)

### Expected Features

**Must have (table stakes) — v1.2 이번 마일스톤:**
- Open Graph 메타태그 (og:title, og:description, og:image, og:type) — 소셜 공유 미리보기
- Twitter Card `summary_large_image` 전역 설정 — Discord/X 공유 품질
- canonical URL 자기 참조 — 중복 콘텐츠 방지
- Admin/인증 페이지 noindex 전역 처리 — 관리자 경로 색인 차단
- JSON-LD Article + BreadcrumbList 렌더링 (게시글 상세) — Google Rich Results 자격
- JSON-LD WebSite + Organization 렌더링 (홈) — 사이트 신뢰도
- Google Search Console 인증 메타태그 — GSC 기능 활성화
- 네이버 서치어드바이저 인증 메타태그 — 네이버 검색 등록
- robots.txt Yeti(네이버봇) 명시 블록 + Googlebot 명시 블록 추가
- Admin 게시글 에디터 2컬럼 레이아웃 (Ghost/WordPress Admin 표준 패턴)
- 기본 OGP 이미지 에셋 (`public/og-default.png`, 1200x630px)

**Should have (competitive) — v1.x 이후:**
- og:image 본문 첫 번째 이미지 자동 추출 (ActionText 첨부 이미지 URL 접근 방식 추가 조사 필요)
- noindex 토글 — 게시글별 Admin 설정 (Post 모델 boolean 컬럼 추가 필요)
- sitemap ping 후처리 (게시글 발행 after_commit 콜백)
- SEO 필드 글자수 카운터 Stimulus 컨트롤러 (seo_title 60자, seo_description 160자 권장)
- JSON-LD 카테고리 목록 ItemList + 스킬팩 SoftwareApplication

**Defer (v2+):**
- Core Web Vitals 최적화 (LCP preload, CLS 방지)
- AMP 구현 — Google이 2023년 순위 요소에서 제외, 유지보수 비용만 높음
- 자동 meta description AI 생성 — Google이 50%+ 무시하는 추세, AI 초안 기능과 중복
- 다국어 hreflang — 한국어 전용 서비스, 불필요한 복잡도
- 구조화 데이터 CI 자동 검증 — 1인 운영에 오버엔지니어링

### Architecture Approach

변경 범위는 최소화된다. 새 디렉토리, 모델, 마이그레이션, 컨트롤러가 필요 없다. 모든 변경은 기존 컴포넌트에 대한 가산적(additive) 수정이다. SEO 메타태그 흐름은 `뷰 content_for :head → set_meta_tags → 레이아웃 display_meta_tags → HTML head` 단방향 파이프라인이며, 레이아웃에는 이미 `display_meta_tags`와 `yield :head`가 배선되어 있어 뷰에서 `set_meta_tags` 호출만 추가하면 된다. Admin 2컬럼은 `_form.html.erb` 외부 wrapper의 클래스 교체만으로 처리된다.

**Major components:**
1. `layouts/application.html.erb` — 검색엔진 인증 메타태그 고정 삽입 + robots yield 슬롯 추가 (수정)
2. `app/helpers/seo_helper.rb` — XSS 패치 (json_escape 적용) + og_image_url_for 헬퍼 추가 (수정)
3. `app/views/posts/show.html.erb` — set_meta_tags + Article/BreadcrumbList JSON-LD content_for 추가 (수정)
4. `app/views/pages/home.html.erb` — WebSite/Organization JSON-LD content_for 추가 (수정)
5. `app/views/admin/posts/_form.html.erb` — CSS Grid 2컬럼 레이아웃으로 교체 (수정)
6. `public/robots.txt` — Googlebot/Yeti 명시 블록 추가 (수정)
7. `config/sitemap.rb` — 카테고리 하드코딩 → 동적 루프 교체 (수정)

### Critical Pitfalls

1. **JSON-LD XSS 취약점 (`seo_helper.rb`)** — 기존 `.to_json.html_safe` 패턴에서 `<`, `>`, `&` 문자가 이스케이프되지 않아 스크립트 태그 이탈 가능. 모든 JSON-LD 메서드에 `json_escape` 또는 Unicode 이스케이프 래퍼 적용. 새 JSON-LD 연결 전 사전 패치 필수.

2. **og:image 상대 경로 사용** — `image_path` 대신 `image_url` 사용, `config/environments/production.rb`에 `config.asset_host = "https://teovibe.com"` 설정 필수. 소셜 크롤러(카카오톡, Facebook, Discord)는 절대 URL만 인식하며, 배포 후 수정 시 카카오톡은 기존 공유 URL 캐시를 갱신할 수 없음.

3. **canonical + noindex 동시 적용 충돌** — `MetaTags.configure { |c| c.skip_canonical_links_on_noindex = true }` 설정으로 자동 처리. canonical을 `request.original_url`로 설정하면 `?page=2` 등 쿼리 파라미터가 포함됨 — 라우트 헬퍼(`post_url(@post)`) 사용 필수.

4. **naver-site-verification 태그 위치 오류** — `set_meta_tags`를 통한 조건부 삽입 금지. `application.html.erb`에 ENV 조건으로 직접 고정 삽입해야 Naver Search Advisor가 루트 URL에서 항상 인식 가능. Turbo Frame 내 삽입 시 Naver가 인식 불가.

5. **rhino-editor sticky 사이드바 무력화** — Admin 2컬럼 grid에 `items-start` 필수. CSS Grid 기본값(`align-items: stretch`)에서는 sticky가 작동 안 함. 부모 컨테이너에 `overflow: hidden` 금지.

## Implications for Roadmap

Based on research, suggested phase structure:

### Phase 0: 사전 보안 패치 (XSS 수정)
**Rationale:** `seo_helper.rb`의 `.to_json.html_safe` XSS 취약점은 JSON-LD를 뷰에 연결하기 전에 반드시 패치해야 한다. 패치 없이 JSON-LD를 활성화하면 취약한 상태로 배포된다. 단독 커밋, 10분 내 수정 가능.
**Delivers:** Brakeman 경고 0건, 안전한 JSON-LD 출력 기반 확보
**Addresses:** PITFALLS.md Pitfall 1 (Critical)
**Avoids:** 배포 후 긴급 패치 시나리오

### Phase 1: 크롤링 기초 — robots.txt + sitemap 보완
**Rationale:** 다른 SEO 기능보다 선행되어야 한다. robots.txt는 크롤러가 사이트를 이해하는 첫 번째 접점이고, sitemap 카테고리 하드코딩은 v1.1 카테고리 동적화 이후 남은 기술 부채로 신규 카테고리 색인 누락을 유발한다.
**Delivers:** Yeti/Googlebot 명시 허용, 환경별 크롤링 제어 기반, 동적 카테고리 sitemap 커버리지
**Addresses:** FEATURES.md robots.txt 보강, sitemap 동적 카테고리
**Avoids:** Naver Search Advisor "수집 오류", 신규 카테고리 색인 누락

### Phase 2: 검색엔진 인증 메타태그
**Rationale:** robots.txt Yeti 허용(Phase 1) 완료 후 Naver Search Advisor 등록을 진행한다. 인증이 완료되어야 이후 SEO 변경사항의 효과를 Search Console에서 추적할 수 있다. 인증 토큰은 `application.html.erb`에 고정 삽입 필수.
**Delivers:** Google Search Console 소유권 확인, 네이버 서치어드바이저 등록 가능 상태
**Addresses:** FEATURES.md Google/Naver 인증 메타태그 (table stakes)
**Avoids:** PITFALLS.md Pitfall 3 — `application.html.erb` 고정 삽입 패턴으로 태그 위치 오류 방지

### Phase 3: OG/Twitter Card 메타태그 보강
**Rationale:** 검색엔진 인증(Phase 2) 후 실제 콘텐츠 메타데이터를 작업한다. ApplicationController 기본값 설정 후 게시글 상세에서 오버라이드하는 단방향 패턴. og:image 절대 URL과 seo_title fallback은 이 단계에서 반드시 처리해야 소셜 공유가 정상 동작한다.
**Delivers:** 소셜 공유 미리보기(카카오톡/Discord/X), 게시글별 OG 타이틀/설명/이미지, 기본 OGP 이미지 에셋
**Addresses:** FEATURES.md OG/Twitter Card (table stakes)
**Avoids:** PITFALLS.md Pitfall 4 (og:image 상대 경로), Pitfall 9 (seo_title fallback 미구현)

### Phase 4: canonical URL + noindex 처리
**Rationale:** OG 메타태그(Phase 3)와 동일한 `set_meta_tags` 인프라를 사용. canonical 쿼리 파라미터 문제와 noindex+canonical 충돌은 이 단계에서 `MetaTags.configure` 설정으로 일괄 처리.
**Delivers:** 중복 콘텐츠 방지, Admin/인증 페이지 비색인 처리, 크롤 버짓 최적화
**Addresses:** FEATURES.md canonical URL, noindex 처리 (table stakes)
**Avoids:** PITFALLS.md Pitfall 6 (canonical+noindex 충돌), Pitfall 7 (request.original_url canonical)

### Phase 5: JSON-LD 구조화 데이터 렌더링
**Rationale:** Phase 0에서 XSS 패치가 완료된 SeoHelper를 비로소 뷰에 연결한다. 헬퍼는 이미 정의되어 있으므로 `content_for :head` 블록 추가만으로 완료. Phase 3-4와 독립적으로 병렬 처리 가능하나 Phase 0 선행 필수.
**Delivers:** Google Rich Results 자격(Article + BreadcrumbList), 홈 사이트 신뢰도(WebSite + Organization)
**Addresses:** FEATURES.md JSON-LD 구조화 데이터 렌더링 (differentiator)
**Avoids:** XSS는 Phase 0에서 선제 해결됨

### Phase 6: Admin 게시글 에디터 2컬럼 레이아웃
**Rationale:** SEO 기능과 완전히 독립적. `_form.html.erb` 리팩터링만으로 처리되며 모델/컨트롤러 변경 없음. Phase 1-5 진행 중 병렬 개발 가능. Ghost/WordPress Admin 표준 패턴이므로 사전 연구가 필요 없다.
**Delivers:** 메타 정보 + 본문 에디터 2컬럼 분리, sticky 우측 설정 패널, SEO 필드 가시성 향상
**Addresses:** FEATURES.md Admin 에디터 2컬럼 레이아웃 (differentiator)
**Avoids:** PITFALLS.md Pitfall 8 (rhino-editor sticky 충돌) — `items-start` 필수 적용

### Phase Ordering Rationale

- Phase 0이 Phase 5보다 먼저인 이유: XSS 취약 헬퍼를 활성화하기 전에 반드시 패치해야 함
- Phase 1(robots.txt)이 Phase 2(인증)보다 먼저인 이유: Naver Search Advisor는 Yeti 허용이 확인된 사이트에 대해 크롤링 진단이 정확함
- Phase 3-4-5는 논리적 순서가 있지만 실제로는 독립적으로 병렬 처리 가능
- Phase 6은 SEO 트랙 전체와 독립적 — 언제든 병렬로 진행 가능

### Research Flags

Phases with standard patterns (skip research-phase):
- **Phase 0:** `json_escape` 헬퍼 적용 — Rails 내장 기능, 단순 래퍼 추가
- **Phase 1:** robots.txt 정적 파일 수정 + sitemap.rb 동적화 — 확립된 Rails 패턴, 코드 예제 연구에서 완전히 검증됨
- **Phase 2:** 인증 메타태그 — 공식 Google/Naver 문서 기반, 구현 패턴 단순
- **Phase 3:** meta-tags gem API — 공식 gem README 기반, 코드 예제 연구에서 완전히 검증됨
- **Phase 4:** canonical/noindex — meta-tags gem 설정 한 줄 (`skip_canonical_links_on_noindex = true`), 확립된 패턴
- **Phase 5:** JSON-LD SeoHelper 연결 — 헬퍼 이미 정의됨, `content_for :head` 추가만
- **Phase 6:** CSS Grid 2컬럼 — Tailwind arbitrary values 확인됨, Ghost/WordPress 표준 패턴

Phases likely needing deeper research during planning:
- **og:image 자동 추출 (v1.x 이후):** ActionText 첨부 이미지 URL 접근 방식이 Rails 버전별로 다르며 공식 문서가 충분하지 않음. 별도 연구 권장.
- **sitemap ping 자동화 (v1.x 이후):** Solid Queue + after_commit 콜백 패턴 및 Kamal deploy hook 방식 검증 필요.

## Confidence Assessment

| Area | Confidence | Notes |
|------|------------|-------|
| Stack | HIGH | 기존 Gemfile.lock 직접 확인 + 공식 gem 문서. 신규 의존성 없음 — 검증 위험 없음 |
| Features | HIGH | 공식 OGP/Schema.org/Google 문서 + meta-tags gem README 기반. 경쟁 분석(Ghost/WordPress) 포함 |
| Architecture | HIGH | 코드베이스 직접 분석(seo_helper.rb, sitemap.rb, _form.html.erb, layouts 등) — 가장 신뢰도 높음 |
| Pitfalls | MEDIUM-HIGH | Naver Search Advisor 공식 문서가 제한적(MEDIUM), 나머지 XSS/canonical/OG pitfall은 공식 소스 기반(HIGH) |

**Overall confidence:** HIGH

### Gaps to Address

- **Naver Search Advisor 크롤링 동작:** Yeti의 JavaScript 렌더링 능력이 공식 문서에 명시되지 않음. Turbo Drive가 SSR에 영향을 주지 않으므로 현재 구조는 안전하나, 등록 후 Search Advisor 진단 도구로 실제 크롤링 결과 모니터링 권장.
- **og:image Active Storage 첨부 이미지 URL 추출:** ActionText 본문에서 첫 번째 이미지 URL을 추출하는 Rails 표준 방법이 버전별로 다름. v1.x 구현 시 별도 조사 필요. 현재는 기본 OGP 이미지 폴백으로 처리.
- **sitemap_generator 자동 실행 주기:** 현재 수동 `rake sitemap:refresh` 실행. Solid Queue cron 또는 Kamal deploy hook으로 자동화 방식은 v1.x에서 결정.

## Sources

### Primary (HIGH confidence)
- 코드베이스 직접 분석: `app/helpers/seo_helper.rb`, `config/sitemap.rb`, `public/robots.txt`, `app/views/admin/posts/_form.html.erb`, `config/initializers/meta_tags.rb`, `db/schema.rb`
- [meta-tags gem GitHub (kpumuk/meta-tags)](https://github.com/kpumuk/meta-tags) — OG, canonical, noindex API, `skip_canonical_links_on_noindex` 설정
- [Open Graph protocol 공식 (ogp.me)](https://ogp.me/) — OG 스펙
- [Schema.org BreadcrumbList](https://schema.org/BreadcrumbList) — JSON-LD 스펙
- [Google Search Console 소유권 확인](https://support.google.com/webmasters/answer/9008080) — 인증 메타태그 방식
- [Google 특수 메타태그 문서](https://developers.google.com/search/docs/crawling-indexing/special-tags) — noindex, canonical 공식
- [Brakeman: Cross Site Scripting (JSON)](https://brakemanscanner.org/docs/warning_types/cross_site_scripting_to_json/) — JSON-LD XSS 취약점 근거
- [Google: noindex + canonical 혼용 금지](https://www.searchenginejournal.com/google-dont-mix-noindex-relcanonical/262607/) — John Mueller 공식 권고
- Tailwind CSS v4 공식 문서 — arbitrary value grid 문법, `items-start` sticky 동작

### Secondary (MEDIUM confidence)
- [DataDome: What is NaverBot](https://datadome.co/bots/naverbot/) — Yeti 봇 기술 특성
- [Interad: Naver Search Advisor guide (2025)](https://www.interad.com/en/insights/naver-search-advisor-a-full-guide) — Yeti robots.txt 명시 권고
- [Avo Blog: Structured Data in Rails](https://avohq.io/blog/structured-data-rails) — JSON-LD partial 패턴
- [Avo Blog: Canonical URLs in Rails](https://avohq.io/blog/canonical-urls-rails) — canonical 구현 패턴
- [Avo Blog: Sitemap Best Practices](https://avohq.io/blog/sitemap-for-rails-applications) — noindex 페이지 sitemap 제외 권장
- [PayloadCMS: 2-column editor layout discussion](https://github.com/payloadcms/payload/discussions/5181) — Admin 2컬럼 패턴 업계 표준 검증

---
*Research completed: 2026-03-14*
*Ready for roadmap: yes*
