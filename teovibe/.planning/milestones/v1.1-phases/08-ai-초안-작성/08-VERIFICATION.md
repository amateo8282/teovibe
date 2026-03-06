---
phase: 08-ai-초안-작성
verified: 2026-03-06T00:00:00Z
status: human_needed
score: 4/4 must-haves verified
human_verification:
  - test: "Admin 게시글 작성 폼에서 AI 초안 전체 흐름 동작 확인"
    expected: "주제 입력 -> 개요 생성 -> textarea 수정 -> 본문 생성 -> rhino-editor 자동 삽입이 순서대로 동작한다"
    why_human: "실제 Anthropic API 호출, rhino-editor DOM 삽입, 로딩 스피너 표시 여부는 브라우저에서만 검증 가능하다"
  - test: "에러 발생 시 (ANTHROPIC_API_KEY 미설정 등) 화면에 에러 메시지 표시 확인"
    expected: "API 오류 시 빨간 텍스트로 에러 메시지가 표시되고, 에디터가 손상되지 않는다"
    why_human: "에러 렌더링은 DOM 상태 변화를 브라우저에서 확인해야 한다"
  - test: "API 호출 중 버튼 비활성화 확인"
    expected: "개요/본문 생성 버튼이 요청 중에 disabled 상태가 되어 중복 클릭이 불가능하다"
    why_human: "비동기 로딩 중 UI 상태 변화는 실제 브라우저 인터랙션으로만 검증 가능하다"
---

# Phase 08: AI 초안 작성 Verification Report

**Phase Goal:** Admin이 주제/키워드를 입력하면 AI가 개요를 생성하고, 검토 후 본문을 생성하여 rhino-editor에 자동 삽입된다
**Verified:** 2026-03-06T00:00:00Z
**Status:** human_needed (automated checks all passed)
**Re-verification:** No — initial verification

## Goal Achievement

### Observable Truths (from ROADMAP Success Criteria)

| # | Truth | Status | Evidence |
|---|-------|--------|----------|
| 1 | Admin이 게시글 작성 폼에서 주제/키워드를 입력하고 요청하면 AI가 H2 섹션 목록(개요)을 생성하여 화면에 표시한다 | VERIFIED | `_form.html.erb:14` data-controller="ai-draft" 패널 존재; `ai_draft_controller.js:8` generateOutline() 구현; POST /admin/ai_draft/outline 라우트 확인 |
| 2 | Admin이 생성된 개요를 직접 수정한 뒤 본문 생성을 요청할 수 있다 | VERIFIED | `_form.html.erb:43-46` editable textarea (data-ai-draft-target="outline"); `ai_draft_controller.js:47` outlineTarget.value.trim() 읽어서 POST |
| 3 | 생성된 본문이 rhino-editor에 자동으로 삽입되어 즉시 편집 가능한 상태가 된다 | VERIFIED | `ai_draft_controller.js:76-77` rhinoEditor.editor.commands.setContent(data.body_html, false) + updateInputElementValue() 호출 |
| 4 | 생성된 콘텐츠는 H2/H3 구조와 FAQ 섹션을 포함한 SEO/AEO 최적화 형식을 갖춘다 | VERIFIED | `ai_draft_service.rb:3-12` SYSTEM_PROMPT 상수에 "H2/H3", "FAQ", "SEO", "AEO" 명시적 포함; 테스트 7개 통과 확인 |

**Score:** 4/4 truths verified

### Required Artifacts

| Artifact | Expected | Status | Details |
|----------|----------|--------|---------|
| `teovibe/app/services/ai_draft_service.rb` | Anthropic API 래퍼, SEO/AEO 시스템 프롬프트, generate_outline/generate_body | VERIFIED | 51줄, SYSTEM_PROMPT 상수 + 두 메서드 모두 구현, Anthropic::Client 사용 |
| `teovibe/app/controllers/admin/ai_drafts_controller.rb` | outline/body JSON 엔드포인트 | VERIFIED | 24줄, Admin::BaseController 상속, outline/body 액션 + rescue 422 처리 |
| `teovibe/app/frontend/controllers/ai_draft_controller.js` | Stimulus Controller: 개요 생성, 본문 생성, rhino-editor 삽입, 로딩 상태 | VERIFIED | 110줄, generateOutline/generateBody/setLoading/showError/clearError 모두 구현 |
| `teovibe/app/views/admin/posts/_form.html.erb` | AI 초안 패널 UI (주제 입력, 개요 textarea, 버튼, 에러 영역) | VERIFIED | 109줄, 기존 코드 보존 + AI 초안 패널 상단 삽입 완료 |
| `teovibe/test/services/ai_draft_service_test.rb` | AIDR-04 시스템 프롬프트 포함 단위 테스트 | VERIFIED | 82줄, 3개 테스트 (SYSTEM_PROMPT 검증 + generate_outline/generate_body API 파라미터 검증) |
| `teovibe/test/controllers/admin/ai_drafts_controller_test.rb` | AIDR-01~03 컨트롤러 응답 테스트 (API stub) | VERIFIED | 80줄, 4개 테스트 (outline JSON 응답, body JSON 응답, 422 에러 핸들링, Admin 인증 체크) |

### Key Link Verification

| From | To | Via | Status | Details |
|------|----|-----|--------|---------|
| `admin/ai_drafts_controller.rb` | `ai_draft_service.rb` | AiDraftService.new.generate_outline / generate_body | WIRED | 컨트롤러 라인 8, 16에서 AiDraftService.new 직접 호출 확인 |
| `config/routes.rb` | `admin/ai_drafts_controller.rb` | resource :ai_draft collection post :outline, :body | WIRED | routes.rb 라인 114-119, `bin/rails routes | grep ai_draft` 두 경로 모두 확인 |
| `_form.html.erb` | `ai_draft_controller.js` | data-controller='ai-draft', data-action 어트리뷰트 | WIRED | _form.html.erb 라인 14, data-controller="ai-draft" + data-ai-draft-outline-url-value / data-ai-draft-body-url-value Rails 헬퍼로 URL 주입 |
| `ai_draft_controller.js` | /admin/ai_draft/outline + /admin/ai_draft/body | fetch POST with CSRF token | WIRED | 라인 19, 57에서 outlineUrlValue/bodyUrlValue로 fetch POST; X-CSRF-Token 헤더 포함 |
| `ai_draft_controller.js` | rhino-editor DOM element | rhinoEditor.editor.commands.setContent + updateInputElementValue() | WIRED | 라인 74-77, querySelector("rhino-editor") + setContent + updateInputElementValue() 구현 |

**Stimulus 자동 등록:** `index.js`가 `import.meta.glob("./**/*_controller.js")` 방식 사용 — ai_draft_controller.js 파일명 패턴 일치로 자동 등록됨.

### Requirements Coverage

| Requirement | Source Plan | Description | Status | Evidence |
|-------------|-------------|-------------|--------|----------|
| AIDR-01 | 08-01-PLAN.md, 08-02-PLAN.md | Admin이 주제/키워드를 입력하면 AI가 개요(H2 섹션 목록)를 생성한다 | SATISFIED | POST /admin/ai_draft/outline 엔드포인트 + Stimulus generateOutline() + _form.html.erb 패널 UI |
| AIDR-02 | 08-01-PLAN.md, 08-02-PLAN.md | Admin이 생성된 개요를 검토/수정한 후 본문 생성을 요청할 수 있다 | SATISFIED | outlinePanel textarea (editable) + generateBody() 메서드로 수정된 개요 POST |
| AIDR-03 | 08-01-PLAN.md, 08-02-PLAN.md | 생성된 본문이 rhino-editor에 자동 삽입된다 | SATISFIED | rhinoEditor.editor.commands.setContent(data.body_html) + updateInputElementValue() |
| AIDR-04 | 08-01-PLAN.md | AI 생성 시 SEO/AEO 최적화 시스템 프롬프트가 적용된다 | SATISFIED | AiDraftService::SYSTEM_PROMPT 상수에 H2/H3/FAQ/SEO/AEO 포함; system: SYSTEM_PROMPT 파라미터로 전달 |

**REQUIREMENTS.md 추적:** 4개 요구사항 모두 Phase 8 Complete로 표시. 고아 요구사항 없음.

### Anti-Patterns Found

| File | Line | Pattern | Severity | Impact |
|------|------|---------|----------|--------|
| `_form.html.erb` | 22, 46 | "placeholder" 문자열 | Info | HTML input placeholder 속성 — 구현 스텁 아님, 정상 UI 패턴 |

스텁, TODO, FIXME, 빈 구현체 없음.

### Human Verification Required

#### 1. AI 초안 전체 흐름 E2E 동작

**Test:** 개발 서버 실행 후 http://localhost:3000/admin/posts/new 접속 (Admin 계정), 주제 입력란에 "Rails 성능 최적화 팁" 입력 후 "개요 생성" 버튼 클릭
**Expected:** "생성 중..." 로딩 텍스트 표시 후 개요 textarea에 H2 섹션 목록 생성, 이후 "본문 생성 후 에디터에 삽입" 클릭 시 rhino-editor에 본문 삽입
**Why human:** 실제 Anthropic API 응답, DOM 상태 변화(hidden 클래스 토글), rhino-editor 내용 삽입 여부는 브라우저에서만 확인 가능하다

#### 2. 에러 처리 화면 표시

**Test:** ANTHROPIC_API_KEY 미설정 상태에서 개요 생성 시도, 또는 잘못된 키로 시도
**Expected:** 화면 상단 에러 영역(data-ai-draft-target="error")에 빨간 텍스트 에러 메시지 표시, 에디터 손상 없음
**Why human:** 에러 메시지 DOM 렌더링 및 가시성은 브라우저 확인 필요

#### 3. 버튼 비활성화 (중복 요청 방지)

**Test:** 개요/본문 생성 버튼 클릭 후 응답 오기 전 버튼 상태 확인
**Expected:** 요청 중 disabled 속성 적용으로 추가 클릭 불가, 응답 후 재활성화
**Why human:** 비동기 로딩 중 UI 상태 변화 타이밍은 실제 브라우저 인터랙션으로 검증 필요

## Test Results

```
7 runs, 27 assertions, 0 failures, 0 errors, 0 skips
```

- `test/services/ai_draft_service_test.rb`: 3 tests passed (SYSTEM_PROMPT 검증, generate_outline 파라미터, generate_body HTML 프롬프트)
- `test/controllers/admin/ai_drafts_controller_test.rb`: 4 tests passed (outline JSON 응답, body JSON 응답, 422 에러 핸들링, Admin 인증 리다이렉트)

## Verified Commits

| Commit | Task | Description |
|--------|------|-------------|
| 1319893 | 08-01 Task 1 | feat(08-01): anthropic gem 설치 + AiDraftService 구현 (TDD) |
| 5db9732 | 08-01 Task 2 | feat(08-01): Admin::AiDraftsController + 라우트 + 컨트롤러 테스트 (TDD) |
| 4bfb4f6 | 08-02 Task 1 | feat(08-02): Stimulus ai_draft_controller.js 구현 |
| 84292a7 | 08-02 Task 2 | feat(08-02): Admin 게시글 폼에 AI 초안 패널 UI 추가 |

## Summary

Phase 08 목표인 "Admin이 주제/키워드를 입력하면 AI가 개요를 생성하고, 검토 후 본문을 생성하여 rhino-editor에 자동 삽입된다"의 모든 자동화 검증 항목이 통과되었다.

- anthropic gem v1.23.0 설치 완료
- AiDraftService (SEO/AEO SYSTEM_PROMPT + generate_outline + generate_body) 구현
- Admin::AiDraftsController (outline/body JSON API, 에러 422 처리, Admin 인증 상속)
- 라우트 2개 (outline_admin_ai_draft_path, body_admin_ai_draft_path) 등록
- Stimulus ai_draft_controller.js (개요/본문 생성, rhino-editor 삽입, 로딩/에러 상태)
- Admin 게시글 작성/수정 폼 상단 AI 초안 패널 UI 삽입
- 7개 Minitest 테스트 통과

실제 Anthropic API 호출과 브라우저 인터랙션 (로딩 스피너, rhino-editor 삽입 확인, 버튼 비활성화)은 사람이 직접 검증해야 한다.

---

_Verified: 2026-03-06T00:00:00Z_
_Verifier: Claude (gsd-verifier)_
