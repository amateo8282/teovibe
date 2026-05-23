# Phase 9: SEO 자동 생성 - Research

**Researched:** 2026-03-23
**Domain:** Rails SEO meta tag generation, ActionText body parsing, model callbacks
**Confidence:** HIGH

## Summary

Phase 9는 신규 마이그레이션 없이 순수 Ruby/Rails 레이어 작업이다. `seo_title`, `seo_description` 컬럼이 이미 DB에 존재하고 Admin 폼에서도 수동 입력이 가능한 상태지만, 두 가지가 연결되지 않은 고아(orphaned) 상태다. (1) 저장 시 자동 생성 로직이 없고, (2) `PostsController#show`에서 이 필드를 무시하고 항상 본문 truncate로 메타태그를 생성한다.

수정 범위는 세 지점이다: `Post` 모델에 `before_save` 콜백으로 자동 생성 로직 추가, `PostsController#show`에서 seo 필드 우선 사용, `SeoHelper#article_json_ld`에서도 seo_title 반영. 기존 Anthropic API(Phase 8에서 도입된 `anthropic` gem v1.23.0)를 재사용하는 방안과, API 없이 순수 Ruby로 본문 텍스트를 추출하는 방안 두 가지가 있다. 메타태그 길이 최적화(title 60자, description 155자)는 Google 권장사항이므로 자동 생성 시 반드시 준수해야 한다.

**Primary recommendation:** `Post` 모델에 `before_save` 콜백 + 순수 Ruby 텍스트 추출로 동기 처리. API 호출은 불필요하다. ActionText 본문에서 `strip_tags` + `squish` + `truncate`면 충분히 SEO-friendly한 description을 만들 수 있고, 제목은 60자 내 truncate면 된다.

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| SEO-01 | 게시글 작성 시 seo_title/seo_description이 비어있으면 본문 분석 후 자동 생성 | Post before_save 콜백 + strip_tags 추출 |
| SEO-02 | 게시글 수정 시 seo_title/seo_description이 이미 있으면 재생성하지 않음 | 콜백 조건 `if: -> { seo_title.blank? }` |
| SEO-03 | 프론트엔드 메타태그(og:title, og:description, twitter, canonical)에서 seo_title/seo_description 우선 사용 | PostsController#show 수정 |
| SEO-04 | Admin이 수동으로 SEO 필드를 입력하면 자동 생성보다 우선 적용 | 콜백 조건으로 자연 보장 |
</phase_requirements>

## Standard Stack

### Core
| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| meta-tags | 2.22.3 (설치됨) | Rails 메타태그 헬퍼 (`set_meta_tags`, `display_meta_tags`) | 이미 사용 중 — 교체 불필요 |
| ActionText (Rails 내장) | Rails 8.1 | 본문 rich text 관리, `to_plain_text` 메서드 제공 | `@post.body.to_plain_text`로 HTML 제거 텍스트 추출 |
| ActionView::Helpers::SanitizeHelper | Rails 내장 | `strip_tags` — HTML 태그 제거 | helpers.strip_tags 패턴이 이미 PostsController에서 사용됨 |

### Supporting
| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| anthropic gem | 1.23.0 (설치됨) | Anthropic API 클라이언트 | 자동 생성에 AI를 쓰는 방향 선택 시 (권장하지 않음 — 아래 참조) |

### Alternatives Considered
| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| 순수 Ruby truncate | Anthropic API(비동기 Job) | API는 네트워크 의존, 저장 지연, 비용 발생. title/description 생성은 단순 truncate로 충분하며 AI 품질 향상 폭이 미미함 |
| before_save 콜백 | Service Object (SeoAutoGenerateService) | 로직이 단순(10줄 이내)하면 콜백이 적절. 복잡해지면 Service 분리 고려 |

**설치:** 추가 gem 설치 불필요.

## Architecture Patterns

### Recommended Project Structure

변경 파일:
```
app/
├── models/post.rb                         # before_save 콜백 추가
├── controllers/posts_controller.rb        # show 액션 메타태그 수정
└── helpers/seo_helper.rb                  # article_json_ld에서 seo_title 반영 (선택)
test/
├── models/post_test.rb                    # 자동 생성 단위 테스트
└── integration/og_meta_tags_test.rb       # seo_title/seo_description 우선 사용 통합 테스트
```

### Pattern 1: Post 모델 before_save 콜백

**What:** `seo_title`/`seo_description`이 비어있을 때만 실행되는 `before_save` 콜백
**When to use:** 저장 시점 동기 처리, 단순 변환 로직, API 호출 없음

```ruby
# app/models/post.rb
before_save :auto_generate_seo_fields, if: -> { body.present? }

private

def auto_generate_seo_fields
  self.seo_title = title.truncate(60) if seo_title.blank?
  if seo_description.blank?
    plain_text = ActionController::Base.helpers.strip_tags(body.to_s).squish
    self.seo_description = plain_text.truncate(155)
  end
end
```

**중요:** `body`는 ActionText `has_rich_text :body`이므로 `body.to_s`는 HTML 문자열, `body.to_plain_text`는 순수 텍스트를 반환한다. 모델 내부에서는 `ActionController::Base.helpers.strip_tags`를 사용하거나 `body.to_plain_text`를 직접 쓰는 것이 더 깔끔하다.

**ActionText `to_plain_text` 권장 패턴:**
```ruby
def auto_generate_seo_fields
  self.seo_title = title.truncate(60) if seo_title.blank?
  if seo_description.blank?
    plain = body.to_plain_text.squish
    self.seo_description = plain.truncate(155)
  end
end
```

### Pattern 2: PostsController#show 메타태그 수정

**What:** seo_title/seo_description 존재 시 우선 사용, 없으면 기존 fallback 유지
**When to use:** 언제나 — SEO-03 요구사항의 핵심

```ruby
# app/controllers/posts_controller.rb — show 액션
def show
  @post.increment!(:views_count) unless Current.user == @post.user
  @comments = @post.comments.includes(:user).where(parent_id: nil).order(created_at: :asc)

  # seo_title/seo_description 우선, 없으면 기존 방식 fallback
  meta_title = @post.seo_title.presence || @post.title
  meta_description = @post.seo_description.presence ||
                     helpers.strip_tags(@post.body.to_s).squish.truncate(150)

  set_meta_tags(
    title: meta_title,
    description: meta_description,
    og: {
      title: meta_title,
      description: meta_description,
      url: post_url(@post),
      image: "#{request.base_url}/icon.png",
      type: "article"
    },
    twitter: {
      card: "summary",
      title: meta_title,
      description: meta_description
    },
    canonical: post_url(@post)
  )
end
```

### Pattern 3: SeoHelper article_json_ld 개선 (선택)

현재 `article_json_ld`는 `headline`에 `post.title`을 그대로 사용한다. `seo_title`이 있으면 headline에도 반영하면 Schema.org JSON-LD와 메타태그가 일관성을 가진다.

```ruby
# app/helpers/seo_helper.rb
def article_json_ld(post)
  safe_json_ld({
    "@context" => "https://schema.org",
    "@type" => "Article",
    "headline" => post.seo_title.presence || post.title,
    # ... 나머지 동일
  })
end
```

### Anti-Patterns to Avoid

- **before_save에서 API 호출:** 저장이 API 응답 대기로 블로킹됨. Phase 8 패턴(비동기 Job) 필요. 단순 자동 생성에 API 불필요.
- **after_save 콜백에서 update_columns:** N+1 저장 루프 위험. `before_save`에서 직접 attribute 세팅이 올바름.
- **모델에서 `helpers.strip_tags` 호출:** 뷰 헬퍼를 모델에서 직접 호출하면 테스트 어려움. `body.to_plain_text`(ActionText 내장) 사용.
- **seo_title이 있어도 덮어씀:** 조건을 `if seo_title.blank?`로 명확히 — 수정 시 기존 값 보존.

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| HTML에서 순수 텍스트 추출 | 정규식 기반 HTML 파서 | `ActionText::RichText#to_plain_text` | ActionText가 Trix/Prosemirror 구조를 정확히 파싱, 엣지케이스 처리 내장 |
| 메타태그 렌더링 | 직접 `<meta>` 태그 작성 | `meta-tags` gem (`set_meta_tags`) | 이미 설치됨. OG/Twitter/canonical 모두 처리, XSS 안전 |
| SEO title 길이 최적화 | 복잡한 키워드 분석 | `String#truncate(60)` | Google 권장 60자 내 truncate로 충분 |

**Key insight:** 이 Phase는 새 인프라가 필요하지 않다. 기존 컬럼, 기존 gem, 기존 콜백 패턴을 연결하는 것이 전부다.

## Common Pitfalls

### Pitfall 1: ActionText body가 nil인 상태에서 to_plain_text 호출

**What goes wrong:** 새 게시글 create 시 body가 아직 DB에 저장되지 않은 상태에서 `before_save`가 실행되면, `body.to_plain_text`가 빈 문자열 또는 nil을 반환할 수 있음
**Why it happens:** ActionText는 별도 테이블(`action_text_rich_texts`)에 저장되어 Post save 이후 처리됨. `before_save`에서 body가 in-memory 상태일 수 있음
**How to avoid:** 조건에 `body.present?`를 체크하거나, 콜백 조건을 `if: -> { body.present? && (seo_title.blank? || seo_description.blank?) }`로 설정
**Warning signs:** 테스트에서 seo_description이 항상 빈 문자열로 생성되는 경우

**실제 동작 확인:** `has_rich_text :body`로 선언된 경우, `body`는 unsaved record에서도 접근 가능한 `ActionText::RichText` 객체이다. `body.to_plain_text`는 `nil`을 반환하지 않고 빈 문자열 `""`를 반환한다. `body.present?`로 안전하게 체크 가능.

### Pitfall 2: seo_description이 자동 생성 후 갱신 조건 혼동

**What goes wrong:** 한 필드만 비어있고 다른 필드는 채워진 경우 처리 미흡
**Why it happens:** seo_title과 seo_description을 묶어서 처리하면 하나만 비어있을 때 재생성 여부가 불명확
**How to avoid:** 각 필드를 독립적으로 체크: `if seo_title.blank?` / `if seo_description.blank?`를 별도 조건으로 처리

### Pitfall 3: meta-tags gem의 `title` vs `og:title` 분리

**What goes wrong:** `set_meta_tags(title: meta_title)`이 `<title>` 태그에는 "meta_title | TeoVibe" 형태로 나오는데, og:title은 별도로 지정 안 하면 site name이 붙지 않은 원본 값
**Why it happens:** meta-tags gem의 `title`과 `og: { title: }` 키가 독립적으로 동작
**How to avoid:** `og:`, `twitter:` 키에도 명시적으로 `meta_title` 지정 (이미 현재 코드 패턴이 이를 따름 — 수정 시 유지)

### Pitfall 4: OgMetaTagsTest 기존 테스트 깨짐

**What goes wrong:** `og_meta_tags_test.rb`의 Test 1이 `og:title`을 `post.title`로 검증하고 있음. seo_title 도입 후 이 값이 달라질 수 있음
**Why it happens:** 테스트 픽스처 `posts.yml`에 `seo_title`이 없으면 자동 생성된 seo_title이 title truncate 결과로 설정됨. 60자 이내 제목은 동일한 값이 됨
**How to avoid:** 픽스처에 seo_title을 명시하거나, 테스트를 `post.seo_title.presence || post.title`로 기대값 계산 로직과 일치시킴

## Code Examples

### ActionText to_plain_text 사용 패턴

```ruby
# Source: Rails ActionText 내장 메서드
# Post 모델 내부
def auto_generate_seo_fields
  self.seo_title = title.truncate(60) if seo_title.blank?
  if seo_description.blank? && body.present?
    self.seo_description = body.to_plain_text.squish.truncate(155)
  end
end
```

### 기존 테스트 패턴 (Admin::PostsControllerTest에서 확인된 패턴)

```ruby
# test/models/post_test.rb 추가 패턴
test "seo_title이 비어있으면 자동 생성된다" do
  post = Post.create!(
    title: "테스트 게시글 제목",
    body: "본문 내용입니다.",
    category: categories(:blog),
    user: users(:one),
    status: :published
  )
  assert_not_blank post.seo_title
  assert post.seo_title.length <= 60
end

test "seo_title이 이미 있으면 자동 생성하지 않는다" do
  post = Post.create!(
    title: "제목",
    body: "본문",
    seo_title: "수동 SEO 제목",
    category: categories(:blog),
    user: users(:one),
    status: :published
  )
  assert_equal "수동 SEO 제목", post.seo_title
end
```

### meta-tags 우선순위 패턴

```ruby
# Source: meta-tags gem 2.22.3 사용 패턴 (현재 코드에서 확인)
# presence 메서드로 nil/blank 모두 처리
meta_title = @post.seo_title.presence || @post.title
meta_description = @post.seo_description.presence ||
                   helpers.strip_tags(@post.body.to_s).squish.truncate(150)
```

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| 본문 직접 truncate로 meta description 생성 | seo_description 컬럼 우선 사용 | Phase 9 | 구글 Search Console에서 게시글별 커스텀 description 반영 가능 |
| seo_title/seo_description 수동 입력만 | 자동 생성 후 수동 오버라이드 가능 | Phase 9 | 새 게시글에 즉시 SEO 최적화 적용 |

**현재 상태 (Phase 9 전):**
- `seo_title`, `seo_description` 컬럼: DB에 존재하지만 자동 생성 로직 없음
- Admin 폼: 수동 입력 가능 (124-135행)
- `PostsController#show`: 항상 `post.title` + 본문 truncate 사용 (seo_title/seo_description 무시)
- `SeoHelper#article_json_ld`: `post.title` 고정 사용

## Open Questions

1. **`before_save` vs `after_save`+`update_columns`**
   - What we know: ActionText body는 별도 테이블에 저장되므로 `before_save` 시점에 body가 이미 in-memory 객체로 존재함
   - What's unclear: create 시점에 body ActionText 객체가 `to_plain_text`를 정상 반환하는지 실제 동작 확인 필요
   - Recommendation: 구현 후 `rails test test/models/post_test.rb`로 즉시 검증

2. **기존 게시글(seo_title/seo_description 비어있는 기존 레코드) 처리**
   - What we know: Phase 9 성공 기준은 "작성/수정 시" 자동 생성 — 소급 적용은 요구사항에 없음
   - What's unclear: 배포 후 기존 게시글의 메타태그가 여전히 본문 truncate로 생성될 것
   - Recommendation: `PostsController#show` 수정이 fallback 포함하므로 기존 게시글도 일관 처리됨 (seo_description 없으면 fallback). 소급 적용은 rake task로 별도 처리 가능하나 필수 아님

3. **seo_title 자동 생성 품질: 단순 title truncate로 충분한가?**
   - What we know: Google SEO best practice는 고유하고 설명적인 title. 게시글 제목이 이미 60자 이내면 truncate와 동일
   - What's unclear: 한글 특성상 60자가 너무 길 수 있음 (한글은 영어보다 픽셀 너비 큼). 실제 SERP에서는 약 30자 내외에서 truncate됨
   - Recommendation: `truncate(60)`로 시작하되, 필요시 추후 조정. Google은 캐릭터가 아닌 픽셀(600px) 기준이지만 60자가 업계 통용 근사치

## Validation Architecture

### Test Framework
| Property | Value |
|----------|-------|
| Framework | Minitest (Rails 기본) |
| Config file | test/test_helper.rb |
| Quick run command | `bundle exec rails test test/models/post_test.rb` |
| Full suite command | `bundle exec rails test` |

### Phase Requirements → Test Map

| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| SEO-01 | seo_title/seo_description 비어있으면 자동 생성 | unit | `bundle exec rails test test/models/post_test.rb -n /auto_generate/` | ❌ Wave 0 |
| SEO-02 | seo_title/seo_description 있으면 재생성 안 함 | unit | `bundle exec rails test test/models/post_test.rb -n /이미 있으면/` | ❌ Wave 0 |
| SEO-03 | 메타태그에서 seo_title/seo_description 우선 사용 | integration | `bundle exec rails test test/integration/og_meta_tags_test.rb` | ✅ (수정 필요) |
| SEO-04 | 수동 입력 SEO 필드 우선 적용 | unit | `bundle exec rails test test/models/post_test.rb -n /수동/` | ❌ Wave 0 |

### Sampling Rate
- **Per task commit:** `bundle exec rails test test/models/post_test.rb`
- **Per wave merge:** `bundle exec rails test`
- **Phase gate:** Full suite green before `/gsd:verify-work`

### Wave 0 Gaps
- [ ] `test/models/post_test.rb` — SEO-01, SEO-02, SEO-04 단위 테스트 추가 (파일은 존재하나 SEO 관련 테스트 없음)
- [ ] `test/integration/og_meta_tags_test.rb` — SEO-03: seo_title 있는 게시글 메타태그 우선 사용 테스트 추가

## Sources

### Primary (HIGH confidence)
- 프로젝트 소스 직접 분석 — `app/models/post.rb`, `app/controllers/posts_controller.rb`, `app/helpers/seo_helper.rb`, `app/controllers/admin/posts_controller.rb`
- `db/schema.rb` + `bundle exec rails runner "puts Post.column_names"` — 실제 컬럼 구조 확인
- `test/integration/og_meta_tags_test.rb` — 기존 메타태그 테스트 패턴 확인
- Rails ActionText 공식 문서 패턴 (`has_rich_text`, `to_plain_text`)

### Secondary (MEDIUM confidence)
- meta-tags gem 2.22.3 Gemfile.lock 확인 — 설치 버전 검증
- 기존 코드의 `helpers.strip_tags(@post.body.to_s).squish.truncate(150)` 패턴 — 이미 프로젝트에서 검증된 방식

### Tertiary (LOW confidence)
- Google SEO title 60자 권장 — 업계 통용 수치, 픽셀 기반 정확한 한글 기준은 별도 검증 필요

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH — 기존 설치 gem, 기존 Rails 내장 기능만 사용
- Architecture: HIGH — 기존 콜백 패턴(`before_save :generate_slug` 이미 존재), 기존 `set_meta_tags` 패턴 동일하게 적용
- Pitfalls: HIGH — 소스 분석으로 직접 확인한 orphaned 상태와 기존 테스트 충돌 지점

**Research date:** 2026-03-23
**Valid until:** 2026-04-23 (Rails/meta-tags 안정 버전, 변경 가능성 낮음)
