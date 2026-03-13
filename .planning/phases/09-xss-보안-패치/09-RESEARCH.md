# Phase 9: XSS 보안 패치 - Research

**Researched:** 2026-03-14
**Domain:** Rails Helper XSS 보안 — JSON-LD `.to_json.html_safe` 패턴 수정
**Confidence:** HIGH

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|-----------------|
| SEC-01 | seo_helper.rb JSON-LD 헬퍼의 XSS 취약점 수정 (`.to_json.html_safe` → 안전한 직렬화) | 현재 취약 패턴 7개 메서드 전체 확인됨. `safe_json_ld` private 래퍼 패턴으로 일괄 수정 가능. Brakeman 0경고 달성 경로 명확 |
</phase_requirements>

---

## Summary

`teovibe/app/helpers/seo_helper.rb`에 7개 JSON-LD 헬퍼 메서드가 모두 `.to_json.html_safe` 패턴을 사용하고 있다. 이 패턴은 Ruby의 `Hash#to_json`이 `<`, `>`, `&`, `/` 문자를 HTML-safe하게 이스케이프하지 않아 XSS 취약점이 존재한다. 게시글 제목이나 사용자 닉네임에 `</script><script>alert(1)</script>` 형식의 문자열이 포함되면, 브라우저가 JSON-LD `<script>` 블록을 조기 종료하고 악성 스크립트를 실행할 수 있다.

수정 방법은 확립된 패턴이 두 가지 있다. 첫 번째는 `private` 래퍼 메서드 `safe_json_ld(data)`를 추가해 `.gsub` 체인으로 Unicode 이스케이프를 적용하는 방법이다. 두 번째는 Rails에 내장된 `json_escape` 헬퍼(ActionView::Helpers::JavaScriptHelper)를 사용하는 방법이다. 두 방식 모두 Brakeman 경고를 해소하며, 이스케이프 후 JSON은 유효한 JSON 형식을 유지하므로 Google Rich Results 검증에도 통과한다.

Phase 9는 Phase 12(JSON-LD 구조화 데이터)의 선행 조건으로 분리된 단계다. 이 패치가 완료되어야 Phase 12에서 JSON-LD 헬퍼를 뷰에서 실제로 사용할 수 있다.

**Primary recommendation:** `safe_json_ld` private 래퍼 메서드를 `seo_helper.rb`에 추가하고, 7개 public 메서드 모두 `.to_json.html_safe`를 `safe_json_ld(...)` 호출로 교체한다.

---

## Standard Stack

### Core

| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| Rails ActionView `json_escape` | Rails 8.1.2 내장 | JSON 문자열에서 HTML 특수문자 이스케이프 | Rails 공식 내장 헬퍼, 추가 gem 불필요 |
| Brakeman | Gemfile에 포함 (`bin/brakeman` 존재) | 정적 분석으로 XSS 경고 감지 | Rails 공식 보안 스캐너 |

### Supporting

| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| Rails Minitest | Rails 8.1.2 내장 | `SeoHelperTest` 단위 테스트 | Phase 9 검증 테스트 작성 시 |

### Alternatives Considered

| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| `safe_json_ld` private 래퍼 | `json_escape` ERB 직접 사용 | ERB 직접 사용은 헬퍼 반환값 책임이 뷰로 분산됨. 헬퍼 자체가 안전한 값을 반환하는 것이 더 일관적 |
| `.gsub` Unicode 이스케이프 | `CGI.escapeHTML` | CGI.escapeHTML은 HTML attribute 이스케이프용이지 JSON-LD 스크립트 컨텍스트 전용이 아님 |

**Installation:**

```bash
# 신규 gem 설치 없음 — Rails 내장 기능만 사용
```

---

## Architecture Patterns

### Recommended Project Structure

```
teovibe/app/helpers/
└── seo_helper.rb     # 7개 public 메서드 + safe_json_ld private 메서드 추가

teovibe/test/helpers/
└── seo_helper_test.rb  # 신규 생성 (현재 비어있는 디렉토리)
```

### Pattern 1: safe_json_ld Private 래퍼

**What:** `seo_helper.rb`에 `safe_json_ld(data)` private 메서드를 추가한다. 이 메서드는 Ruby Hash를 JSON 문자열로 직렬화한 뒤 `<`, `>`, `&`, `/` 문자를 Unicode 이스케이프로 치환하고 `html_safe`를 호출한다.

**When to use:** JSON-LD `<script type="application/ld+json">` 블록에 사용자 입력 데이터(게시글 제목, 본문, 닉네임)가 포함되는 모든 경우.

**Example:**

```ruby
# seo_helper.rb에 추가할 private 메서드
def safe_json_ld(data)
  data.to_json
      .gsub('<', '\u003c')
      .gsub('>', '\u003e')
      .gsub('&', '\u0026')
      .gsub('/', '\u002f')
      .html_safe
end

# 기존 취약 패턴 → 수정 후
# 수정 전: }.to_json.html_safe
# 수정 후: safe_json_ld({ ... })
def article_json_ld(post)
  safe_json_ld({
    "@context" => "https://schema.org",
    "@type" => "Article",
    "headline" => post.title,
    # ...
  })
end
```

### Pattern 2: json_escape 내장 헬퍼 (대안)

**What:** Rails ActionView의 `json_escape`를 사용하는 방법. `CGI.escapeHTML`보다 JSON 컨텍스트에 더 정확하다.

**When to use:** ERB 뷰에서 직접 이스케이프가 필요한 경우, 또는 헬퍼 반환값이 이미 hash인 경우.

```ruby
# ERB 뷰에서 직접 사용하는 방식 (대안)
<script type="application/ld+json">
  <%= json_escape(article_json_ld(@post).to_json) %>
</script>
```

### Anti-Patterns to Avoid

- **`.to_json.html_safe` 직접 사용:** `html_safe`는 Rails의 XSS 자동 이스케이프를 비활성화한다. `to_json`은 HTML 특수문자를 이스케이프하지 않으므로, 이 조합은 스크립트 컨텍스트에서 XSS를 허용한다.
- **`h()` 또는 `ERB::Util.html_escape`로 JSON 이스케이프 시도:** `h()`는 HTML attribute 컨텍스트용이며, JSON 값 내부의 HTML 이스케이프를 수행하면 JSON 형식이 깨져 Google Rich Results 파서가 오류를 반환한다.
- **헬퍼별 개별 이스케이프 처리:** 7개 메서드마다 각각 처리하면 누락 위험이 있다. `safe_json_ld` private 래퍼로 단일 진입점을 만드는 것이 안전하다.

---

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| HTML 특수문자 이스케이프 로직 | 직접 정규식 작성 | `.gsub` 4개 호출 (검증된 패턴) 또는 `json_escape` | 직접 구현 시 `/` 이스케이프 누락, 유니코드 범위 처리 오류 등 엣지 케이스 발생 가능 |
| Brakeman 경고 억제 | `# brakeman:ignore` 주석 | 실제 취약점 수정 | 경고 억제는 취약점을 남긴 채 리포팅만 우회 — 허용 불가 |

**Key insight:** `</script>` 문자열 차단이 목표가 아니다. `<`, `>`, `&` 문자 전체를 JSON 문자열 내에서 Unicode escape로 변환해야 한다. 이스케이프된 Unicode는 JSON 파서가 원본 문자로 복원하므로 렌더링에 영향 없다.

---

## Common Pitfalls

### Pitfall 1: `/` 이스케이프 누락

**What goes wrong:** `<`, `>`, `&`만 이스케이프하고 `/`를 누락하면 `</script>` 닫힘 태그를 `<\/script>` (백슬래시 이스케이프)가 아닌 Unicode로 처리해야 하는데, `>` 이스케이프가 `</script>` 전체를 커버하므로 실질적으로는 문제없다. 그러나 `</` 패턴 자체를 완전 차단하려면 `/`도 `\u002f`로 이스케이프하는 것이 방어적으로 더 안전하다.

**Why it happens:** 이스케이프 목록에서 `/`를 빠뜨리는 경우.

**How to avoid:** 4개 문자 모두 이스케이프: `<`, `>`, `&`, `/`.

**Warning signs:** Brakeman 경고가 `<`/`>` 수정 후에도 남아있는 경우 확인.

### Pitfall 2: `safe_json_ld` 추가 후 기존 메서드 7개 중 일부 누락

**What goes wrong:** 래퍼 메서드만 추가하고 기존 public 메서드 일부를 `.to_json.html_safe`로 남기면 Brakeman 경고가 남는다.

**Why it happens:** `seo_helper.rb`에 7개 메서드가 있고, 일부는 패턴이 미묘하게 다르다 (`organization_json_ld`는 hash를 private 메서드에서 받아온 뒤 직렬화).

**How to avoid:** 수정 후 `grep -n "html_safe" seo_helper.rb`로 잔여 패턴 0건 확인.

**Warning signs:** `bin/brakeman` 실행 시 `seo_helper.rb` 관련 경고가 1건이라도 남아있는 경우.

### Pitfall 3: 이스케이프 후 JSON 유효성 깨짐

**What goes wrong:** Unicode 이스케이프(`\u003c`)는 JSON 스펙상 유효한 표현이다. 그러나 잘못된 이스케이프(예: `&amp;` 또는 `&#x3C;` HTML 엔티티 변환)를 적용하면 JSON 파서가 오류를 반환한다.

**Why it happens:** HTML 이스케이프 메서드(`CGI.escapeHTML`)를 JSON 컨텍스트에 잘못 적용하는 경우.

**How to avoid:** `.gsub` Unicode 이스케이프 또는 Rails `json_escape` 사용. HTML 엔티티 변환 메서드 사용 금지.

**Warning signs:** `JSON.parse(safe_json_ld(test_data))` 테스트에서 파싱 오류 발생.

---

## Code Examples

### 현재 취약 패턴 (seo_helper.rb 실제 코드)

```ruby
# 현재 7개 메서드 모두 이 패턴 사용 — XSS 취약
def article_json_ld(post)
  {
    "@context" => "https://schema.org",
    # ...
  }.to_json.html_safe  # 취약점
end
```

### 수정 후 패턴

```ruby
module SeoHelper
  def article_json_ld(post)
    safe_json_ld({
      "@context" => "https://schema.org",
      "@type" => "Article",
      "headline" => post.title,
      "datePublished" => post.created_at.iso8601,
      "dateModified" => post.updated_at.iso8601,
      "author" => {
        "@type" => "Person",
        "name" => post.user.nickname
      },
      "publisher" => organization_json_ld_hash
    })
  end

  # ... 나머지 public 메서드도 동일하게 safe_json_ld 적용

  private

  def safe_json_ld(data)
    data.to_json
        .gsub('<', '\u003c')
        .gsub('>', '\u003e')
        .gsub('&', '\u0026')
        .gsub('/', '\u002f')
        .html_safe
  end

  def organization_json_ld_hash
    {
      "@context" => "https://schema.org",
      "@type" => "Organization",
      "name" => "TeoVibe",
      "url" => root_url,
      "description" => "바이브코딩으로 사업을 만드는 사람들의 커뮤니티"
    }
  end
end
```

### Brakeman 실행 명령

```bash
cd /path/to/teovibe && bin/brakeman --no-pager
# 수정 후 seo_helper.rb 관련 경고 0건 확인
```

### Minitest 검증 테스트 (test/helpers/seo_helper_test.rb)

```ruby
require "test_helper"

class SeoHelperTest < ActionView::TestCase
  test "article_json_ld escapes script injection in title" do
    post = posts(:one)  # 또는 OpenStruct/mock 사용
    post.title = 'test</script><script>alert(1)</script>'

    result = article_json_ld(post)

    assert result.include?('\u003c'), "< should be escaped"
    assert result.include?('\u003e'), "> should be escaped"
    refute result.include?('</script>'), "raw </script> must not appear"
    assert JSON.parse(result).is_a?(Hash), "result must be valid JSON"
  end

  test "article_json_ld escapes ampersand in title" do
    post = posts(:one)
    post.title = 'Tom & Jerry'

    result = article_json_ld(post)

    assert result.include?('\u0026'), "& should be escaped"
    assert JSON.parse(result).is_a?(Hash), "result must be valid JSON"
  end
end
```

---

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| `.to_json.html_safe` | `safe_json_ld` 래퍼 또는 `json_escape` | Rails 보안 가이드라인 — 시점 불명확하나 오랫동안 알려진 취약점 | Brakeman이 `Cross-Site Scripting (JSON)` 경고로 탐지함 |

**Deprecated/outdated:**

- `.to_json.html_safe`: JSON-LD 스크립트 블록에서 사용 금지. `to_json`은 HTML 컨텍스트를 인식하지 못한다.

---

## Open Questions

1. **`organization_json_ld_hash`의 처리**
   - What we know: `organization_json_ld_hash`는 private hash 반환 메서드이며, `organization_json_ld`와 `article_json_ld`에서 호출됨
   - What's unclear: `organization_json_ld`에서 `organization_json_ld_hash.to_json.html_safe`를 `safe_json_ld(organization_json_ld_hash)`로 변경해야 하는지, 혹은 `organization_json_ld_hash`를 `article_json_ld` hash에 embed할 때 `safe_json_ld` 최상위 호출로 한 번에 처리되는지
   - Recommendation: `article_json_ld`의 최상위 hash에 embed된 상태로 `safe_json_ld`가 한 번 호출되면 중첩 hash 전체가 이스케이프됨. `organization_json_ld`는 독립 public 메서드이므로 `safe_json_ld(organization_json_ld_hash)` 로 변경 필요

2. **테스트 픽스처 구성**
   - What we know: `test/helpers/` 디렉토리가 존재하나 현재 파일 없음. `test/fixtures/` 아래 `posts.yml`이 있을 것으로 추정
   - What's unclear: `post.user.nickname` 접근을 위한 association fixture 구성 여부
   - Recommendation: OpenStruct mock 또는 Minitest fixture association 활용. 테스트가 DB 의존성 없이 helper 로직만 검증하도록 작성 권장

---

## Validation Architecture

### Test Framework

| Property | Value |
|----------|-------|
| Framework | Rails Minitest (Rails 8.1.2 내장) |
| Config file | `teovibe/test/test_helper.rb` |
| Quick run command | `cd teovibe && bin/rails test test/helpers/seo_helper_test.rb` |
| Full suite command | `cd teovibe && bin/rails test` |

### Phase Requirements → Test Map

| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| SEC-01 | `<script>` 태그 포함 제목이 JSON-LD에서 이스케이프되어 브라우저 미실행 | unit | `cd teovibe && bin/rails test test/helpers/seo_helper_test.rb` | Wave 0 생성 필요 |
| SEC-01 | Brakeman 정적 분석 seo_helper.rb 경고 0건 | static analysis | `cd teovibe && bin/brakeman --no-pager 2>&1 \| grep -c "seo_helper"` | bin/brakeman 존재 |
| SEC-01 | safe_json_ld 반환값이 유효한 JSON으로 파싱됨 | unit | `cd teovibe && bin/rails test test/helpers/seo_helper_test.rb` | Wave 0 생성 필요 |

### Sampling Rate

- **Per task commit:** `cd teovibe && bin/rails test test/helpers/seo_helper_test.rb`
- **Per wave merge:** `cd teovibe && bin/rails test test/helpers/seo_helper_test.rb && bin/brakeman --no-pager`
- **Phase gate:** 위 전체 통과 후 `/gsd:verify-work`

### Wave 0 Gaps

- [ ] `teovibe/test/helpers/seo_helper_test.rb` — SEC-01 unit tests (XSS 이스케이프 + JSON 유효성)

*(bin/brakeman은 이미 존재 — 추가 설치 불필요)*

---

## Sources

### Primary (HIGH confidence)

- 프로젝트 코드베이스 직접 분석: `teovibe/app/helpers/seo_helper.rb` — 7개 취약 메서드 전체 확인
- [Brakeman: Cross-Site Scripting (JSON)](https://brakemanscanner.org/docs/warning_types/cross_site_scripting_to_json/) — Rails JSON XSS 취약점 원인 및 감지 방법
- `.planning/research/PITFALLS.md` (Pitfall 1) — XSS 취약점 상세 분석 및 수정 패턴 문서화

### Secondary (MEDIUM confidence)

- Rails ActionView::Helpers::JavaScriptHelper — `json_escape` 내장 헬퍼 (Rails 소스)
- OWASP: JSON-LD 스크립트 태그 XSS 패턴 — `</script>` 주입 공격 벡터

### Tertiary (LOW confidence)

- 없음

---

## Metadata

**Confidence breakdown:**

- 취약 패턴 식별: HIGH — 코드베이스 직접 확인, 7개 메서드 모두 `.to_json.html_safe` 사용
- 수정 패턴: HIGH — Brakeman 공식 문서 + PITFALLS.md 기존 연구와 일치
- 테스트 접근: MEDIUM — `test/helpers/` 디렉토리 존재 확인, fixture association 구성은 실제 코드 확인 필요

**Research date:** 2026-03-14
**Valid until:** 2026-04-14 (안정적 도메인 — Rails XSS 패치 패턴은 변경 가능성 낮음)
