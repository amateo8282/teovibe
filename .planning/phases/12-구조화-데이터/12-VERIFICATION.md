---
phase: 12-구조화-데이터
verified: 2026-03-14T18:30:00Z
status: passed
score: 4/4 must-haves verified
re_verification: false
gaps: []
---

# Phase 12: 구조화 데이터 Verification Report

**Phase Goal:** 게시글이 Google Rich Results 자격을 갖추고 홈페이지가 사이트 신뢰도 구조화 데이터를 제공한다
**Verified:** 2026-03-14T18:30:00Z
**Status:** passed
**Re-verification:** No — initial verification

## Goal Achievement

### Observable Truths

| #   | Truth                                                                                           | Status     | Evidence                                                                                        |
| --- | ----------------------------------------------------------------------------------------------- | ---------- | ----------------------------------------------------------------------------------------------- |
| 1   | 게시글 상세 페이지 HTML에 Article JSON-LD가 script[type=application/ld+json] 태그로 출력된다   | VERIFIED   | `show.html.erb` line 3: `<script type="application/ld+json"><%= article_json_ld(@post) %></script>`, 통합 테스트 Test 1 PASS |
| 2   | 게시글 상세 페이지 HTML에 BreadcrumbList JSON-LD가 홈 > 카테고리 > 게시글 3단계로 출력된다    | VERIFIED   | `show.html.erb` line 4-8: `breadcrumb_json_ld([{홈, root_url}, {카테고리명, category_posts_url}, {제목}])`, 통합 테스트 Test 3-4 PASS (itemListElement 3개, 첫 항목 "홈" 확인) |
| 3   | 홈페이지 HTML에 WebSite + Organization JSON-LD가 각각 출력된다                                 | VERIFIED   | `home.html.erb` line 6-7: `website_json_ld`, `organization_json_ld` 호출, 통합 테스트 Test 5-6 PASS |
| 4   | JSON-LD 출력에 `<script>` 등 특수문자가 Unicode 이스케이프되어 있다                             | VERIFIED   | `seo_helper.rb` `safe_json_ld` 메서드: `<`→`\u003c`, `>`→`\u003e`, `&`→`\u0026`, `/`→`\u002f` 적용. `seo_helper_test.rb` 8개 테스트 PASS (XSS 이스케이프 검증 포함) |

**Score:** 4/4 truths verified

### Required Artifacts

| Artifact                                                        | Expected                                          | Status     | Details                                                                                     |
| --------------------------------------------------------------- | ------------------------------------------------- | ---------- | ------------------------------------------------------------------------------------------- |
| `teovibe/app/views/posts/show.html.erb`                         | Article + BreadcrumbList JSON-LD content_for :head 블록 | VERIFIED   | 9라인 content_for :head 블록 존재, `article_json_ld(@post)` 및 `breadcrumb_json_ld` 호출 확인 |
| `teovibe/app/views/pages/home.html.erb`                         | WebSite + Organization JSON-LD content_for :head 블록 | VERIFIED   | 기존 `vite_javascript_tag` 유지하면서 `website_json_ld`, `organization_json_ld` 추가됨 |
| `teovibe/test/integration/json_ld_test.rb`                      | JSON-LD 출력 통합 테스트 (min 30줄)               | VERIFIED   | 112라인, 6개 테스트, 24개 assertions, 0 failures — 실제 실행으로 확인                        |

### Key Link Verification

| From                                     | To                                        | Via                                                  | Status   | Details                                                                                                     |
| ---------------------------------------- | ----------------------------------------- | ---------------------------------------------------- | -------- | ----------------------------------------------------------------------------------------------------------- |
| `teovibe/app/views/posts/show.html.erb`  | `teovibe/app/helpers/seo_helper.rb`       | `article_json_ld(@post)` + `breadcrumb_json_ld`      | WIRED    | show.html.erb line 3: `article_json_ld(@post)` 패턴 확인됨. `content_for :head` → `yield :head`(layout line 21)로 렌더링 |
| `teovibe/app/views/pages/home.html.erb`  | `teovibe/app/helpers/seo_helper.rb`       | `website_json_ld` + `organization_json_ld`           | WIRED    | home.html.erb line 6-7에 두 헬퍼 호출 확인됨. 기존 `vite_javascript_tag` 보존됨                              |

### Requirements Coverage

| Requirement | Source Plan | Description                                        | Status      | Evidence                                                                                              |
| ----------- | ----------- | -------------------------------------------------- | ----------- | ----------------------------------------------------------------------------------------------------- |
| STRD-01     | 12-01-PLAN  | 게시글 상세 페이지에 Article JSON-LD 출력           | SATISFIED   | `show.html.erb` content_for :head에 `article_json_ld(@post)` 호출. 통합 테스트 2건 PASS. REQUIREMENTS.md: `[x]` 완료 표시 |
| STRD-02     | 12-01-PLAN  | 게시글 상세 페이지에 BreadcrumbList JSON-LD 출력   | SATISFIED   | `show.html.erb` content_for :head에 `breadcrumb_json_ld(3-item array)` 호출. 통합 테스트 2건 PASS. REQUIREMENTS.md: `[x]` 완료 표시 |
| STRD-03     | 12-01-PLAN  | 홈페이지에 WebSite + Organization JSON-LD 출력     | SATISFIED   | `home.html.erb` content_for :head에 `website_json_ld`, `organization_json_ld` 호출. 통합 테스트 2건 PASS. REQUIREMENTS.md: `[x]` 완료 표시 |

**고아 요구사항(ORPHANED):** 없음. REQUIREMENTS.md의 Phase 12 매핑(STRD-01, STRD-02, STRD-03)과 PLAN frontmatter가 완전히 일치.

### Anti-Patterns Found

| File | Line | Pattern | Severity | Impact |
| ---- | ---- | ------- | -------- | ------ |

(발견 없음)

### Human Verification Required

#### 1. Google Rich Results Test

**Test:** https://search.google.com/test/rich-results 에서 게시글 상세 URL(`/posts/:slug`) 입력
**Expected:** Article 구조화 데이터가 유효하고 Rich Results 자격 있음으로 표시
**Why human:** Google의 Rich Results 서비스는 실제 네트워크 요청과 Google 크롤러 시뮬레이션이 필요하며 자동화 테스트로 검증 불가

#### 2. Schema.org Validator — BreadcrumbList URL 확인

**Test:** 실제 배포 환경에서 게시글 상세 페이지 HTML 소스 내 BreadcrumbList `item` 필드 URL이 절대 URL(`https://...`)인지 확인
**Expected:** `category_posts_url`로 생성된 절대 URL이 `item` 필드에 포함됨
**Why human:** 통합 테스트는 test 환경의 host(`www.example.com`)로 동작하므로 프로덕션 도메인 확인은 수동 필요

---

## Verification Details

### Test Suite Results

```
JsonLdTest (json_ld_test.rb):
  6 runs, 24 assertions, 0 failures, 0 errors, 0 skips
  - Test 1: Article JSON-LD script 태그 존재                    PASS (0.67s)
  - Test 2: Article headline/datePublished/author.name 필드     PASS (0.01s)
  - Test 3: BreadcrumbList itemListElement 3개                  PASS (0.01s)
  - Test 4: BreadcrumbList 홈/카테고리명 항목 확인              PASS (0.01s)
  - Test 5: WebSite name/url 필드                               PASS (0.02s)
  - Test 6: Organization name/url 필드                          PASS (0.00s)

SeoHelperTest (seo_helper_test.rb) — 회귀 없음:
  8 runs, 13 assertions, 0 failures, 0 errors, 0 skips
```

### Commits Verified

| Hash      | Message                                              | Exists |
| --------- | ---------------------------------------------------- | ------ |
| `4b2c983` | test(12-01): JSON-LD 통합 테스트 작성 (TDD RED)     | YES    |
| `54dc0d2` | feat(12-01): 게시글 상세 페이지 Article + BreadcrumbList JSON-LD 배선 | YES |
| `0ebdb23` | feat(12-01): 홈페이지 WebSite + Organization JSON-LD 배선 | YES |

### Layout Wiring

`teovibe/app/views/layouts/application.html.erb` line 21: `<%= yield :head %>` — content_for :head 블록이 이 위치에 렌더링됨. 양쪽 뷰의 content_for :head 블록이 레이아웃에 정상 주입됨.

---

_Verified: 2026-03-14T18:30:00Z_
_Verifier: Claude (gsd-verifier)_
