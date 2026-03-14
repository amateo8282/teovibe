---
phase: 15-툴바-서식-확장
verified: 2026-03-14T22:00:00Z
status: human_needed
score: 6/6 must-haves verified
human_verification:
  - test: "MARK-01 취소선(Strike) 버튼 동작 확인"
    expected: "텍스트 선택 후 Strike 버튼 클릭 시 취소선(<del>/<s>) 태그 적용"
    why_human: "rhino-editor 기본 renderStrikeButton()이 렌더링하는지 실제 브라우저에서만 확인 가능. Strike는 AdminRhinoEditor에 별도 코드 없이 기본 툴바에 포함됨."
  - test: "MARK-02 밑줄(Underline) 버튼 동작 및 저장 후 유지 확인"
    expected: "텍스트 선택 후 밑줄(U) 버튼 클릭 시 <u> 태그 적용, 게시글 저장 후 상세 페이지에서 밑줄 렌더링 유지"
    why_human: "ActionText 허용목록 추가와 extension 등록은 코드로 확인됐지만 실제 저장/렌더링 라운드트립은 브라우저 + 서버 실행 필요"
  - test: "MARK-03 인용구(Blockquote) 버튼 동작 확인"
    expected: "커서 위치에서 Blockquote 버튼 클릭 시 <blockquote> 블록으로 변환"
    why_human: "rhino-editor 기본 renderBlockquoteButton() 동작을 브라우저에서 확인 필요"
  - test: "MARK-04 구분선(HorizontalRule) 버튼 동작 확인"
    expected: "구분선(—) 버튼 클릭 시 <hr> 태그 삽입"
    why_human: "renderHorizontalRuleButton()의 setHorizontalRule() 명령 실행이 브라우저에서만 확인 가능"
  - test: "MARK-05 코드블록(CodeBlock) 버튼 동작 확인"
    expected: "CodeBlock 버튼 클릭 시 <pre><code> 블록으로 변환"
    why_human: "rhino-editor 기본 renderCodeBlockButton() 동작을 브라우저에서 확인 필요"
  - test: "MARK-06 제목 드롭다운(H1/H2/H3) 동작 확인"
    expected: "드롭다운에서 H1/H2/H3 선택 시 커서 블록이 해당 제목 레벨로 변환, 단락 선택 시 원래대로 복귀"
    why_human: "renderHeadingDropdown()의 toggleHeading()/setParagraph() 명령과 .value 바인딩이 브라우저에서만 검증 가능"
---

# Phase 15: 툴바 서식 확장 Verification Report

**Phase Goal:** 취소선, 밑줄, 인용구, 구분선, 코드블록, 제목 드롭다운이 Admin 에디터 툴바에 추가되어 작성자가 풍부한 서식을 적용할 수 있다
**Verified:** 2026-03-14T22:00:00Z
**Status:** human_needed
**Re-verification:** No — initial verification

## Goal Achievement

### Observable Truths

| # | Truth | Status | Evidence |
|---|-------|--------|---------|
| 1 | 툴바에서 취소선 버튼을 클릭하면 선택 텍스트에 del 태그가 적용된다 | ? UNCERTAIN | rhino-editor 기본 renderStrikeButton()이 chunk-JV22V53Y.js:450에 존재하고 renderToolbar() 안 line 1121에 slot으로 렌더링됨. 실제 동작은 human verification 필요 |
| 2 | 툴바에서 밑줄 버튼을 클릭하면 선택 텍스트에 u 태그가 적용되고 저장 후에도 유지된다 | ? UNCERTAIN | renderUnderlineButton()이 admin_rhino_editor.js:71에 구현됨. Underline extension이 connectedCallback에서 addExtensions(Underline)으로 등록됨. ActionText allowed_tags에 u 포함 확인(action_text.rb:12). 저장/렌더링 라운드트립은 human verification 필요 |
| 3 | 툴바에서 인용구 버튼을 클릭하면 블록이 blockquote로 변환된다 | ? UNCERTAIN | rhino-editor 기본 renderBlockquoteButton()이 chunk-JV22V53Y.js:601에 존재하고 renderToolbar() 안에 포함됨. 실제 동작은 human verification 필요 |
| 4 | 툴바에서 구분선 버튼을 클릭하면 hr 태그가 삽입된다 | ? UNCERTAIN | renderHorizontalRuleButton()이 admin_rhino_editor.js:47에 구현됨. setHorizontalRule() 호출 코드 확인됨. 실제 동작은 human verification 필요 |
| 5 | 툴바에서 코드블록 버튼을 클릭하면 블록이 pre>code로 변환된다 | ? UNCERTAIN | rhino-editor 기본 renderCodeBlockButton()이 chunk-JV22V53Y.js:699에 존재하고 renderToolbar() 안에 포함됨. 실제 동작은 human verification 필요 |
| 6 | 제목 드롭다운에서 H1/H2/H3을 선택하면 커서 블록이 해당 제목 레벨로 변환된다 | ? UNCERTAIN | renderHeadingDropdown()이 admin_rhino_editor.js:14에 구현됨. toggleHeading({level})/setParagraph() 호출 코드 확인됨. 실제 동작은 human verification 필요 |

**Score:** 6/6 must-haves — 코드 증거 전부 확인됨. 브라우저 동작 검증 대기.

### Required Artifacts

| Artifact | Expected | Status | Details |
|----------|----------|--------|---------|
| `teovibe/app/frontend/editor/admin_rhino_editor.js` | AdminRhinoEditor with Underline extension + renderToolbarEnd override | VERIFIED | 106줄. import Underline from "@tiptap/extension-underline" (line 4), import { html } from "lit" (line 5), connectedCallback에서 addExtensions(Underline) (line 10), renderToolbarEnd() (line 96), renderHeadingDropdown() (line 14), renderHorizontalRuleButton() (line 48), renderUnderlineButton() (line 71) 모두 존재 |
| `teovibe/config/initializers/action_text.rb` | ActionText u 태그 허용목록 | VERIFIED | line 12: allowed_tags += %w[table thead tbody tfoot tr th td colgroup col caption u] — u 태그 포함 확인 |
| `teovibe/package.json` | @tiptap/extension-underline 의존성 | VERIFIED | "@tiptap/extension-underline": "^2.27.2" 확인 |
| `teovibe/package.json` | lit 직접 의존성 (Vite 빌드 픽스) | VERIFIED | "lit": "^3.3.2" 확인 |

### Key Link Verification

| From | To | Via | Status | Details |
|------|----|-----|--------|---------|
| admin_rhino_editor.js | @tiptap/extension-underline | import Underline from "@tiptap/extension-underline" | WIRED | line 4에서 import, line 10에서 addExtensions(Underline) 호출로 등록 완료 |
| admin_rhino_editor.js | TipTap Editor commands | this.editor?.chain().focus() | WIRED | renderUnderlineButton에서 toggleUnderline() (line 87), renderHorizontalRuleButton에서 setHorizontalRule() (line 62), renderHeadingDropdown에서 toggleHeading()/setParagraph() (line 33-36) |
| config/initializers/action_text.rb | ActionText sanitizer | allowed_tags += %w[... u] | WIRED | line 12에서 기존 table 태그 라인에 u 통합하여 추가 확인 |
| admin_rhino_editor.js | rhino-editor renderToolbarEnd slot | renderToolbarEnd() override | WIRED | rhino-editor base class chunk-JV22V53Y.js:1193에서 slot name="toolbar-end"가 renderToolbarEnd() 호출. AdminRhinoEditor가 override하여 H1/H2/H3 드롭다운, 구분선, 밑줄 버튼 삽입 |

### Requirements Coverage

| Requirement | Source Plan | Description | Status | Evidence |
|-------------|------------|-------------|--------|---------|
| MARK-01 | 15-01-PLAN.md | 취소선(Strike) 툴바 버튼 추가 (이미 등록된 extension 활용) | SATISFIED | rhino-editor 기본 renderStrikeButton()이 chunk-JV22V53Y.js:450에 구현되어 있고 renderToolbar()의 slot:strike-button (line 1121)에 포함됨. AdminRhinoEditor는 renderToolbar()를 override하지 않으므로 기본 Strike 버튼이 보존됨. |
| MARK-02 | 15-01-PLAN.md | 밑줄(Underline) extension 설치 + 툴바 버튼 | SATISFIED | @tiptap/extension-underline@2.27.2 설치됨. connectedCallback에서 addExtensions(Underline) 등록. renderUnderlineButton()으로 버튼 렌더링. ActionText allowed_tags에 u 추가. |
| MARK-03 | 15-01-PLAN.md | 인용구(Blockquote) 툴바 버튼 추가 | SATISFIED | rhino-editor 기본 renderBlockquoteButton()이 chunk-JV22V53Y.js:601에 구현되어 있고 renderToolbar()의 slot:blockquote-button (line 1141)에 포함됨. |
| MARK-04 | 15-01-PLAN.md | 구분선(Horizontal Rule) 툴바 버튼 추가 | SATISFIED | renderHorizontalRuleButton()이 admin_rhino_editor.js:48에 구현됨. setHorizontalRule() 커맨드 호출 포함. renderToolbarEnd()에서 렌더링됨. |
| MARK-05 | 15-01-PLAN.md | 소스코드 블록(Code Block) 툴바 버튼 추가 | SATISFIED | rhino-editor 기본 renderCodeBlockButton()이 chunk-JV22V53Y.js:699에 구현되어 있고 renderToolbar() slot:code-block-button (line 1146)에 포함됨. |
| MARK-06 | 15-01-PLAN.md | 제목 레벨 드롭다운 (H1~H3 선택) | SATISFIED | renderHeadingDropdown()이 admin_rhino_editor.js:14에 구현됨. isActive() 상태 반영, toggleHeading({level})/setParagraph() 커맨드 연결. renderToolbarEnd()에서 최초 렌더링됨. |

### Anti-Patterns Found

| File | Line | Pattern | Severity | Impact |
|------|------|---------|----------|--------|
| (없음) | - | - | - | - |

안티패턴 없음. 구현 코드에 TODO/FIXME, 빈 핸들러, placeholder 없음.

### Human Verification Required

#### 1. Strike 버튼 동작 (MARK-01)

**Test:** Admin 에디터에서 텍스트 입력 후 선택 — Strike 버튼 클릭
**Expected:** 선택 텍스트에 취소선 적용, 버튼 active 상태 변경
**Why human:** Strike는 AdminRhinoEditor에 별도 코드 없이 rhino-editor 기본 toolbar에 포함됨. DOM 렌더링은 브라우저에서만 확인 가능.

#### 2. Underline 버튼 동작 + 저장 후 유지 (MARK-02)

**Test:** 텍스트 선택 후 밑줄(U) 버튼 클릭 — 저장 — 상세 페이지 조회
**Expected:** 밑줄 적용 확인, 저장 후 상세 페이지에서 `<u>` 태그 렌더링 유지
**Why human:** ActionText 허용목록 코드는 검증됐지만 실제 Rails 서버 + ActionText 렌더링 파이프라인의 라운드트립은 브라우저 + 서버 실행 필요.

#### 3. Blockquote 버튼 동작 (MARK-03)

**Test:** 텍스트 블록에서 Blockquote 버튼 클릭
**Expected:** `<blockquote>` 블록으로 변환
**Why human:** rhino-editor 기본 버튼 동작, 브라우저에서 확인 필요.

#### 4. HorizontalRule 버튼 동작 (MARK-04)

**Test:** 구분선(—) 버튼 클릭
**Expected:** 편집기에 `<hr>` 구분선 삽입
**Why human:** setHorizontalRule() 커맨드 실행 결과는 브라우저에서만 확인 가능.

#### 5. CodeBlock 버튼 동작 (MARK-05)

**Test:** CodeBlock 버튼 클릭
**Expected:** `<pre><code>` 블록으로 변환
**Why human:** rhino-editor 기본 버튼 동작, 브라우저에서 확인 필요.

#### 6. 제목 드롭다운 동작 (MARK-06)

**Test:** 드롭다운에서 H2 선택 — H2로 변환 확인 — 단락 선택 — 복귀 확인
**Expected:** 커서 블록이 선택한 제목 레벨로 변환, 단락 선택 시 원래대로 복귀
**Why human:** Lit `.value` 바인딩과 @change 이벤트 핸들러의 TipTap 커맨드 실행은 브라우저에서만 검증 가능.

**검증 방법:**
```
cd teovibe && bin/rails server
http://localhost:3000/admin/posts/new
```

### Summary

모든 6개 must-have의 코드 구현이 확인됐다. 자동화 검증 결과:

- **admin_rhino_editor.js**: 106줄의 실질적 구현. Underline extension import + addExtensions(), renderToolbarEnd() override, renderHeadingDropdown() / renderHorizontalRuleButton() / renderUnderlineButton() 3개 메서드 구현. 스텁 없음.
- **action_text.rb**: allowed_tags에 u 태그가 table 태그 라인(line 12)에 통합되어 추가됨.
- **package.json**: @tiptap/extension-underline@^2.27.2, lit@^3.3.2 두 패키지 직접 의존성으로 등록됨.
- **커밋 afcc76e**: 4개 파일 변경 (117줄 추가, 4줄 삭제) 실제 존재 확인됨.
- **rhino-editor 기본 toolbar**: Strike(MARK-01), Blockquote(MARK-03), CodeBlock(MARK-05)은 기본 renderToolbar()에 포함되어 AdminRhinoEditor가 renderToolbarEnd()만 override함으로써 자동 보존됨.

MARK-01, MARK-03, MARK-05 (rhino-editor 기본 버튼)와 MARK-02, MARK-04, MARK-06 (새로 구현한 버튼) 모두 코드 레벨에서 SATISFIED 상태이며, 실제 브라우저 동작 검증만 남아있다.

---

_Verified: 2026-03-14T22:00:00Z_
_Verifier: Claude (gsd-verifier)_
