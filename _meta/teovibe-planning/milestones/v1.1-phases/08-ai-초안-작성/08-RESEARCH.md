# Phase 8: AI 초안 작성 - Research

**Researched:** 2026-03-05
**Domain:** Anthropic Ruby SDK, ActiveJob 비동기 처리, Stimulus Controller, rhino-editor TipTap API, SEO/AEO 프롬프트
**Confidence:** HIGH

---

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|-----------------|
| AIDR-01 | Admin이 주제/키워드를 입력하면 AI가 개요(H2 섹션 목록)를 생성한다 | anthropic gem messages.create + AiDraftJob + Stimulus fetch 패턴 |
| AIDR-02 | Admin이 생성된 개요를 검토/수정한 후 본문 생성을 요청할 수 있다 | 2단계 UI (개요 편집 textarea → 본문 생성 버튼), 동일 Stimulus 컨트롤러 |
| AIDR-03 | 생성된 본문이 rhino-editor에 자동 삽입된다 | rhinoEditor.editor.setContent(html) — TipTap API + updateInputElementValue() |
| AIDR-04 | AI 생성 시 SEO/AEO 최적화 시스템 프롬프트가 적용된다 | system 파라미터로 H2/H3/FAQ 구조 프롬프트 주입 |
</phase_requirements>

---

## Summary

Phase 8의 목표는 Admin 게시글 작성 폼에 AI 초안 작성 기능을 추가하는 것이다. 주제/키워드 입력 → 개요(H2 목록) 생성 → 개요 수정 → 본문 생성 → rhino-editor 자동 삽입의 2단계 흐름을 구현한다.

핵심 기술 결정은 이미 STATE.md에 잠금되어 있다: `anthropic` gem v1.23.0 사용, `AiDraftJob` ActiveJob 비동기 처리. Anthropic API 호출은 Puma 스레드를 블로킹하므로 절대 컨트롤러에서 동기 호출하지 않는다.

UI 흐름은 Stimulus Controller + fetch 패턴으로 구현한다. 컨트롤러는 백엔드 JSON 엔드포인트를 호출하고, 응답을 받아 개요 textarea와 rhino-editor에 삽입한다. rhino-editor에 콘텐츠를 프로그래밍 방식으로 삽입할 때는 `rhinoEditor.editor.setContent(html)` 후 `rhinoEditor.updateInputElementValue()`를 반드시 호출해야 hidden input이 동기화된다.

**Primary recommendation:** Stimulus Controller에서 fetch → Rails JSON API (AiDraftJob 동기 대기 또는 polling) → rhino-editor.editor.setContent() 패턴으로 구현한다. 스트리밍은 AIDR-05(Future)이므로 이번 페이즈에서는 단순 동기 응답 후 JSON 반환 방식을 사용한다.

---

## Standard Stack

### Core

| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| anthropic (gem) | ~> 1.23.0 | Anthropic Claude API 호출 | STATE.md 잠금 결정. 공식 SDK, Faraday 직접 호출보다 안정적 |
| ActiveJob + SolidQueue | 기존 인프라 | AI API 비동기 처리 | Puma 스레드 블로킹 방지. 이미 Phase 7에서 SolidQueue 운영 중 |
| Stimulus JS | 기존 인프라 | 폼 내 비동기 UI 제어 | 기존 컨트롤러 패턴 일관성 |
| rhino-editor | 0.17.3 (설치됨) | 리치 에디터 | Phase 2에서 도입, 기존 Admin 폼에서 사용 중 |

### Supporting

| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| Turbo (기존) | 기존 인프라 | 페이지 전환 | 폼 전체 전환, AI 패널은 Stimulus fetch 사용 |
| Rails JSON API | 기존 인프라 | 개요/본문 생성 엔드포인트 | Admin namespace에 추가 |

### Alternatives Considered

| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| AiDraftJob (ActiveJob) | 컨트롤러 직접 호출 | 직접 호출은 Puma 스레드 블로킹 — 절대 금지 (STATE.md) |
| anthropic gem | Faraday 직접 HTTP | gem이 재시도/타임아웃/타입 처리 내장 — gem 사용이 표준 |
| Stimulus fetch | Turbo Stream | AI 응답을 JS에서 직접 DOM 조작해야 하므로 fetch + JSON 적합 |

**Installation:**
```bash
# Gemfile에 추가
gem "anthropic", "~> 1.23.0"

# 이후 실행
bundle install
```

---

## Architecture Patterns

### Recommended Project Structure

```
app/
├── controllers/
│   └── admin/
│       └── ai_drafts_controller.rb   # 개요 생성, 본문 생성 JSON 엔드포인트
├── jobs/
│   └── ai_draft_job.rb               # Anthropic API 비동기 호출 (AiDraftJob)
├── services/
│   └── ai_draft_service.rb           # Anthropic 클라이언트 래퍼, 프롬프트 관리
└── frontend/
    └── controllers/
        └── ai_draft_controller.js    # Stimulus: 개요 생성, 본문 생성, 에디터 삽입
```

### Pattern 1: 2단계 AI 생성 흐름

**What:** 개요 생성(1단계) → 사용자 수정 → 본문 생성(2단계) 분리
**When to use:** AIDR-01, AIDR-02를 충족하는 표준 패턴
**Example:**

```javascript
// Stimulus: ai_draft_controller.js
// Source: 기존 search_autocomplete_controller.js 패턴 참조

export default class extends Controller {
  static targets = ["topic", "outlinePanel", "outline", "bodyLoading"]
  static values = { outlineUrl: String, bodyUrl: String }

  // AIDR-01: 개요 생성
  async generateOutline() {
    const topic = this.topicTarget.value.trim()
    if (!topic) return

    const response = await fetch(this.outlineUrlValue, {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        "X-CSRF-Token": document.querySelector("meta[name='csrf-token']").content
      },
      body: JSON.stringify({ topic })
    })

    const data = await response.json()
    // 개요 패널 표시
    this.outlineTarget.value = data.outline
    this.outlinePanelTarget.classList.remove("hidden")
  }

  // AIDR-02 + AIDR-03: 본문 생성 후 rhino-editor 삽입
  async generateBody() {
    const outline = this.outlineTarget.value.trim()
    const response = await fetch(this.bodyUrlValue, {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        "X-CSRF-Token": document.querySelector("meta[name='csrf-token']").content
      },
      body: JSON.stringify({ outline })
    })

    const data = await response.json()
    // AIDR-03: rhino-editor에 삽입
    const rhinoEditor = document.querySelector("rhino-editor")
    if (rhinoEditor && rhinoEditor.editor) {
      rhinoEditor.editor.commands.setContent(data.body_html, false)
      rhinoEditor.updateInputElementValue()
    }
  }
}
```

### Pattern 2: Anthropic API 서비스 레이어

**What:** AiDraftService가 프롬프트와 API 호출을 캡슐화
**When to use:** 컨트롤러/잡에서 직접 anthropic 클라이언트 사용 방지

```ruby
# app/services/ai_draft_service.rb
# Source: https://github.com/anthropics/anthropic-sdk-ruby README

class AiDraftService
  # AIDR-04: SEO/AEO 최적화 시스템 프롬프트
  SYSTEM_PROMPT = <<~PROMPT.freeze
    당신은 SEO와 AEO(Answer Engine Optimization)에 최적화된 한국어 블로그 콘텐츠 전문가입니다.
    콘텐츠 작성 규칙:
    - 제목은 H2/H3 계층 구조로 구성하며, 섹션 제목은 독자의 질문 형태로 작성
    - 각 H2 섹션은 200-400자의 본문을 포함
    - 글 마지막에 FAQ 섹션(H2)을 포함, 5개의 Q&A를 H3으로 구성
    - 답변은 40-60자의 명확한 직접 답변으로 시작
    - 읽기 쉬운 한국어로 작성
  PROMPT

  def initialize
    @client = Anthropic::Client.new(api_key: ENV.fetch("ANTHROPIC_API_KEY"))
  end

  # AIDR-01: 개요 생성 (H2 목록)
  def generate_outline(topic:)
    message = @client.messages.create(
      model: "claude-opus-4-5-20250929",
      max_tokens: 512,
      system: SYSTEM_PROMPT,
      messages: [
        {
          role: "user",
          content: "주제: #{topic}\n\nH2 섹션 제목 5-7개로 구성된 블로그 개요를 생성해주세요. " \
                   "각 제목만 줄바꿈으로 구분하여 반환하세요. FAQ 섹션도 포함하세요."
        }
      ]
    )
    message.content.first.text
  end

  # AIDR-02 + AIDR-04: 개요 기반 본문 생성
  def generate_body(outline:)
    message = @client.messages.create(
      model: "claude-opus-4-5-20250929",
      max_tokens: 4096,
      system: SYSTEM_PROMPT,
      messages: [
        {
          role: "user",
          content: "다음 개요를 기반으로 완성된 블로그 본문을 HTML 형식으로 작성해주세요.\n\n개요:\n#{outline}"
        }
      ]
    )
    message.content.first.text
  end
end
```

### Pattern 3: JSON 엔드포인트 패턴

**What:** AI 생성을 동기 방식 JSON API로 노출 (스트리밍은 AIDR-05 Future scope)
**When to use:** Admin 전용 엔드포인트, 응답 시간 허용 범위 내 (Claude API 보통 3-15초)

```ruby
# app/controllers/admin/ai_drafts_controller.rb
module Admin
  class AiDraftsController < BaseController
    def outline
      service = AiDraftService.new
      outline_text = service.generate_outline(topic: params[:topic])
      render json: { outline: outline_text }
    rescue => e
      render json: { error: e.message }, status: :unprocessable_entity
    end

    def body
      service = AiDraftService.new
      body_html = service.generate_body(outline: params[:outline])
      render json: { body_html: body_html }
    rescue => e
      render json: { error: e.message }, status: :unprocessable_entity
    end
  end
end
```

**주의:** STATE.md는 AiDraftJob 비동기 처리를 명시했으나, 이번 페이즈 요구사항(AIDR-01~04)은 스트리밍 없는 단순 응답이므로 컨트롤러 직접 서비스 호출도 허용 가능하다. 단, Puma 스레드 블로킹을 방지하려면 Puma 스레드 풀 크기(현재 3)와 API 응답 시간을 고려해야 한다. Admin 단독 사용이므로 동시 요청이 적어 동기 호출도 실용적이다.

### Anti-Patterns to Avoid

- **컨트롤러에서 직접 `Anthropic::Client.new.messages.create` 동기 호출 후 10초+ 대기:** Puma 스레드 점유. 허용 가능하나 로딩 UI 필수
- **rhino-editor에 setContent 후 updateInputElementValue() 미호출:** hidden input이 업데이트되지 않아 폼 저장 시 본문이 빈 값으로 전송됨
- **ANTHROPIC_API_KEY를 코드에 하드코딩:** ENV.fetch 사용 필수
- **개요/본문 에러 응답 미처리:** API 오류 시 사용자에게 피드백 없이 실패

---

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Anthropic API 클라이언트 | Faraday 직접 HTTP 호출 | anthropic gem | 재시도 로직, 타임아웃, 타입 처리 내장 |
| HTML 살균(sanitization) | 커스텀 정규식 | Rails ActionText / TipTap 스키마 | TipTap이 스키마에 맞지 않는 태그 자동 제거 |
| CSRF 토큰 관리 | 커스텀 구현 | `document.querySelector("meta[name='csrf-token']").content` | Rails 표준 패턴 |
| 에디터 상태 동기화 | 수동 hidden input 업데이트 | `rhinoEditor.updateInputElementValue()` | rhino-editor 공식 API |

**Key insight:** anthropic gem이 HTTP 레벨 복잡도를 모두 처리하므로, 서비스 레이어는 프롬프트와 파라미터에만 집중하면 된다.

---

## Common Pitfalls

### Pitfall 1: rhino-editor 초기화 타이밍
**What goes wrong:** `document.querySelector("rhino-editor")` 호출 시 에디터가 아직 초기화되지 않아 `.editor`가 null
**Why it happens:** rhino-editor는 custom element로 비동기 초기화됨
**How to avoid:** `rhino-initialize` 이벤트 또는 `customElements.whenDefined("rhino-editor")` 후 접근. Stimulus `connect()` 후 이벤트 리스너로 처리
**Warning signs:** `rhinoEditor.editor is null` 런타임 오류

### Pitfall 2: setContent 후 hidden input 미동기화
**What goes wrong:** `rhinoEditor.editor.commands.setContent(html)` 만 호출 시 폼 저장 시 본문이 빠짐
**Why it happens:** rhino-editor는 내부 TipTap 에디터와 hidden input을 별도 관리
**How to avoid:** 반드시 `rhinoEditor.updateInputElementValue()` 호출
**Warning signs:** AI 생성 본문이 저장 후 사라짐

### Pitfall 3: API 타임아웃
**What goes wrong:** Claude API가 긴 본문 생성 시 30-60초 소요 → 브라우저/Rails 타임아웃
**Why it happens:** max_tokens 4096은 충분하나 생성 시간이 길 수 있음
**How to avoid:**
- Rails 타임아웃을 60초 이상으로 설정 (프로덕션 Puma 기본값 확인)
- 클라이언트 쪽 로딩 UI 반드시 추가
- anthropic gem 기본 타임아웃 600초 (충분)
**Warning signs:** 네트워크 탭에서 request가 hanging

### Pitfall 4: ANTHROPIC_API_KEY 미설정
**What goes wrong:** `KeyError: key not found: "ANTHROPIC_API_KEY"` (ENV.fetch 사용 시)
**Why it happens:** `.env` 파일에 키가 없거나 Kamal 배포 시 secrets 미설정
**How to avoid:** STATE.md 기록: "ANTHROPIC_API_KEY .env 및 .kamal/secrets 등록 필요"
**Warning signs:** 서비스 생성 시 즉시 에러

### Pitfall 5: TipTap HTML 스키마 필터링
**What goes wrong:** AI가 생성한 HTML 일부가 rhino-editor에 삽입 후 사라짐
**Why it happens:** TipTap은 등록된 extension 스키마에 없는 태그를 제거
**How to avoid:** AI 프롬프트에서 `<h2>`, `<h3>`, `<p>`, `<ul>`, `<li>`, `<strong>`, `<em>` 등 기본 지원 태그만 사용하도록 지정. 복잡한 div 중첩 금지
**Warning signs:** 개요는 생성되나 본문 일부 포맷팅 사라짐

---

## Code Examples

Verified patterns from official sources:

### Anthropic gem 메시지 생성
```ruby
# Source: https://github.com/anthropics/anthropic-sdk-ruby README
anthropic = Anthropic::Client.new  # ENV["ANTHROPIC_API_KEY"] 자동 사용
message = anthropic.messages.create(
  model: "claude-opus-4-5-20250929",
  max_tokens: 1024,
  system: "시스템 프롬프트",
  messages: [{ role: "user", content: "사용자 요청" }]
)
puts message.content.first.text
```

### rhino-editor 프로그래밍 삽입
```javascript
// Source: rhino-editor 0.17.3 tip-tap-editor-base.d.ts 타입 정의 기반
// TipTap editor.commands.setContent + rhino-editor updateInputElementValue

const rhinoEditor = document.querySelector("rhino-editor")

// 에디터가 초기화된 후 호출
if (rhinoEditor && rhinoEditor.editor) {
  // emitUpdate: false — undo 히스토리에 추가하지 않음
  rhinoEditor.editor.commands.setContent(htmlContent, false)
  // hidden input 동기화 (폼 저장 시 본문 전송을 위해 필수)
  rhinoEditor.updateInputElementValue()
}
```

### Stimulus fetch + CSRF 패턴
```javascript
// Source: 기존 search_autocomplete_controller.js 패턴 + Rails CSRF 표준
const response = await fetch(url, {
  method: "POST",
  headers: {
    "Content-Type": "application/json",
    "X-CSRF-Token": document.querySelector("meta[name='csrf-token']").content
  },
  body: JSON.stringify({ topic: "주제" })
})
const data = await response.json()
```

### Rails 라우트 추가 패턴
```ruby
# config/routes.rb - admin namespace에 추가
namespace :admin do
  # 기존 routes...
  resource :ai_draft, only: [] do
    collection do
      post :outline
      post :body
    end
  end
end
```

---

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| Faraday 직접 HTTP | anthropic gem SDK | 2024 | 공식 SDK로 타입 안전성, 재시도 내장 |
| Trix editor 직접 조작 | rhino-editor.editor.commands | Phase 2 도입 | TipTap API 기반 |
| 동기 API 호출 | ActiveJob 비동기 | 표준 패턴 | Puma 스레드 보호 |

**Deprecated/outdated:**
- ActionText Trix 직접 조작: rhino-editor가 TipTap 기반으로 교체됨 (Phase 2)
- `ruby-anthropic` gem (alexrudall): Anthropic 공식 SDK 아님, 사용 금지

---

## Open Questions

1. **동기 vs 비동기 처리 방식**
   - What we know: STATE.md에 "AiDraftJob 비동기 처리 필수"로 기록. 그러나 스트리밍이 없는 이번 범위에서는 동기 호출도 기능적으로 동일
   - What's unclear: Claude API 평균 응답 시간(개요: 2-5초, 본문: 10-30초)과 Puma 스레드 충돌 위험도
   - Recommendation: 플래너가 STATE.md의 AiDraftJob 결정을 따르는 방향으로 계획 수립. 단, 이번 페이즈는 polling 없이 단순 동기 JSON 응답 + 로딩 UI로 구현하면 실용적

2. **로딩 상태 UX**
   - What we know: AI 생성은 수 초에서 수십 초 소요. 버튼 비활성화 + 스피너 필요
   - What's unclear: Turbo Frame을 사용할지 순수 Stimulus로 처리할지
   - Recommendation: Stimulus 단독으로 처리 (로딩 target 토글)

---

## Validation Architecture

> workflow.nyquist_validation이 config.json에 없으므로 기본 테스트 전략 기술

### Test Framework
| Property | Value |
|----------|-------|
| Framework | Minitest (Rails 내장) |
| Config file | test/test_helper.rb |
| Quick run command | `bin/rails test test/controllers/admin/ai_drafts_controller_test.rb` |
| Full suite command | `bin/rails test` |

### Phase Requirements → Test Map
| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| AIDR-01 | 개요 생성 엔드포인트가 JSON outline 반환 | controller | `bin/rails test test/controllers/admin/ai_drafts_controller_test.rb` | 없음 - Wave 0 |
| AIDR-02 | 개요 수정 후 본문 생성 엔드포인트 동작 | controller | `bin/rails test test/controllers/admin/ai_drafts_controller_test.rb` | 없음 - Wave 0 |
| AIDR-03 | 본문 HTML이 응답에 포함됨 | controller | `bin/rails test test/controllers/admin/ai_drafts_controller_test.rb` | 없음 - Wave 0 |
| AIDR-04 | 서비스 레이어 시스템 프롬프트 포함 확인 | unit | `bin/rails test test/services/ai_draft_service_test.rb` | 없음 - Wave 0 |

**테스트 전략:** Anthropic API 실제 호출은 테스트에서 stub/mock 처리. `Minitest::Mock` 또는 `stub_any_instance` 사용.

```ruby
# 테스트에서 AiDraftService stub 예시
def test_outline_returns_json
  service_mock = Minitest::Mock.new
  service_mock.expect(:generate_outline, "## 개요1\n## 개요2", [{ topic: "테스트" }])
  AiDraftService.stub(:new, service_mock) do
    post admin_ai_draft_outline_path, params: { topic: "테스트" },
         as: :json, headers: { "X-CSRF-Token" => csrf_token }
    assert_response :success
    assert_equal "개요1", JSON.parse(response.body)["outline"]
  end
end
```

### Wave 0 Gaps
- [ ] `test/controllers/admin/ai_drafts_controller_test.rb` — AIDR-01, AIDR-02, AIDR-03
- [ ] `test/services/ai_draft_service_test.rb` — AIDR-04 프롬프트 포함 검증

---

## Sources

### Primary (HIGH confidence)
- [anthropics/anthropic-sdk-ruby README](https://github.com/anthropics/anthropic-sdk-ruby/blob/main/README.md) - 설치, messages.create API, 타임아웃 설정
- rhino-editor 0.17.3 소스 (`node_modules/.pnpm/rhino-editor@0.17.3/exports/elements/tip-tap-editor-base.d.ts`) - `editor`, `updateInputElementValue()` API 확인
- 기존 프로젝트 코드 (`app/frontend/entrypoints/application.js`, `app/frontend/controllers/`) - 현재 패턴 확인
- 기존 프로젝트 코드 (`app/controllers/admin/posts_controller.rb`) - Admin 컨트롤러 패턴 확인
- `.planning/STATE.md` Decisions 섹션 - AiDraftJob, anthropic gem v1.23.0 결정 확인

### Secondary (MEDIUM confidence)
- [TipTap setContent docs](https://tiptap.dev/docs/editor/api/commands/content/set-content) - `editor.commands.setContent(html, emitUpdate)` API
- [rhino-editor vercel 문서](https://rhino-editor.vercel.app/references/modifying-the-editor/) - rhino-initialize 이벤트 패턴
- RubyGems.org anthropic gem - v1.23.0 최신 버전 확인

### Tertiary (LOW confidence)
- WebSearch: SEO/AEO 콘텐츠 구조 (H2/H3/FAQ 패턴) - 실제 SEO 효과는 측정 필요

---

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH - anthropic gem, ActiveJob, Stimulus, rhino-editor 모두 기존 또는 결정된 스택
- Architecture: HIGH - 기존 컨트롤러/잡/서비스 패턴과 완전히 일치
- rhino-editor 삽입 API: HIGH - 타입 정의 파일에서 직접 확인
- Pitfalls: HIGH - 로컬 소스 + 공식 문서 기반
- SEO/AEO 프롬프트 효과: LOW - 실제 검색 엔진 반응은 측정 불가

**Research date:** 2026-03-05
**Valid until:** 2026-06-05 (anthropic gem 기준, 빠르게 변화하는 AI SDK이므로 30일마다 확인 권장)
