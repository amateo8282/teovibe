---
phase: 16-텍스트-스타일링
verified: 2026-03-14T13:10:00Z
status: human_needed
score: 5/5 must-haves verified (automated)
re_verification: false
human_verification:
  - test: "Admin 에디터에서 정렬 버튼(좌/중/우) 클릭 후 저장, 상세 페이지 확인"
    expected: "단락의 text-align이 에디터에서 즉시 변경되고 저장 후 게시글 상세 페이지에서도 유지됨"
    why_human: "브라우저 런타임에서 TipTap extension이 실제 DOM에 text-align 스타일을 적용하는지, ActionText가 저장 시 style attribute를 허용하는지 실제 렌더링으로만 확인 가능"
  - test: "Admin 에디터에서 텍스트 선택 후 글자색(A 아이콘) picker로 빨간색 적용, 저장 후 확인"
    expected: "선택 텍스트에 color 스타일이 적용되고 저장 후 상세 페이지에서도 span style='color:...' 형태로 유지됨"
    why_human: "Color extension의 setColor 커맨드가 실제 브라우저 TipTap 인스턴스에서 동작하는지 확인 필요"
  - test: "Admin 에디터에서 텍스트 선택 후 배경 하이라이트(H 아이콘) picker로 노란색 적용, 저장 후 확인"
    expected: "선택 텍스트에 background-color 스타일이 mark 태그로 적용되고 저장 후 상세 페이지에서 유지됨"
    why_human: "Highlight extension의 multicolor 모드 및 mark 태그 허용 여부를 실제 렌더링으로만 확인 가능"
  - test: "Admin 에디터에서 텍스트 선택 후 폰트 크기 드롭다운에서 32px 선택, 저장 후 확인"
    expected: "선택 텍스트 크기가 변경되고 저장 후 상세 페이지에서 span style='font-size:32px' 형태로 유지됨"
    why_human: "커스텀 FontSize extension의 setFontSize 커맨드가 실제 브라우저에서 동작하는지 확인 필요"
---

# Phase 16: 텍스트 스타일링 Verification Report

**Phase Goal:** 텍스트 정렬(좌/중/우), 글자색, 배경 하이라이트, 폰트 크기를 Admin 에디터에서 조절할 수 있다
**Verified:** 2026-03-14T13:10:00Z
**Status:** human_needed
**Re-verification:** No — initial verification

## Goal Achievement

### Observable Truths

| # | Truth | Status | Evidence |
|---|-------|--------|----------|
| 1 | 정렬 버튼(좌/중/우) 클릭 시 단락의 text-align이 에디터에서 변경되고 저장 후 상세 페이지에서도 유지된다 | ? NEEDS HUMAN | renderAlignButtons() 구현 완료, setTextAlign 커맨드 연결, TextAlign.configure({ types: ["heading", "paragraph"] }) 등록 — 실제 브라우저 동작은 human 확인 필요 |
| 2 | 색상 picker에서 색상 선택 시 선택 텍스트의 글자색이 변경되고 저장 후에도 유지된다 | ? NEEDS HUMAN | renderColorPicker() 구현 완료, setColor/unsetColor 커맨드 연결, Color + TextStyle extension 등록 — 실제 브라우저 동작은 human 확인 필요 |
| 3 | 하이라이트 picker에서 색상 선택 시 선택 텍스트의 배경색이 변경되고 저장 후에도 유지된다 | ? NEEDS HUMAN | renderHighlightPicker() 구현 완료, setHighlight({ color })/unsetHighlight 커맨드 연결, Highlight.configure({ multicolor: true }) 등록 — 실제 브라우저 동작은 human 확인 필요 |
| 4 | 폰트 크기 드롭다운에서 크기 선택 시 선택 텍스트의 크기가 변경되고 저장 후에도 유지된다 | ? NEEDS HUMAN | renderFontSizeDropdown() 구현 완료, setFontSize/unsetFontSize 커맨드 연결, FontSize extension 등록 — 실제 브라우저 동작은 human 확인 필요 |
| 5 | @tiptap/extension-font-size npm 패키지를 사용하지 않고 로컬 커스텀 extension으로 구현되어 있다 | VERIFIED | package.json에 @tiptap/extension-font-size 없음 확인; font_size_extension.js가 Extension.create()로 직접 구현 |

**Score (automated):** 5/5 truths verified at code level (4개 truth는 브라우저 human 검증 필요)

### Required Artifacts

| Artifact | Expected | Status | Details |
|----------|----------|--------|---------|
| `teovibe/app/frontend/editor/font_size_extension.js` | 커스텀 FontSize Extension.create() — setFontSize/unsetFontSize 커맨드 | VERIFIED | 파일 존재, Extension.create() 패턴, setFontSize/unsetFontSize 커맨드 구현, @tiptap/core import |
| `teovibe/app/frontend/editor/admin_rhino_editor.js` | TextAlign, Color, TextStyle, Highlight, FontSize extension 등록 + 정렬/색상/하이라이트/폰트크기 툴바 UI | VERIFIED | renderAlignButtons() 구현 완료, renderColorPicker() 구현 완료, renderHighlightPicker() 구현 완료, renderFontSizeDropdown() 구현 완료, renderToolbarEnd()에 모두 포함 |

### Key Link Verification

| From | To | Via | Status | Details |
|------|----|-----|--------|---------|
| `admin_rhino_editor.js` | `font_size_extension.js` | `import { FontSize }` | VERIFIED | 라인 10: `import { FontSize } from "../editor/font_size_extension.js"` 확인 |
| `admin_rhino_editor.js` | `@tiptap/extension-text-style` | TextStyle extension 등록 | VERIFIED | 라인 7: `import TextStyle from "@tiptap/extension-text-style"`, 라인 21: `this.addExtensions(TextStyle, Color, FontSize)` 확인 |
| `admin_rhino_editor.js` | `@tiptap/extension-text-align` | TextAlign.configure 호출 | VERIFIED | 라인 6: `import TextAlign from "@tiptap/extension-text-align"`, 라인 19: `TextAlign.configure({ types: ["heading", "paragraph"] })` 확인 |

### Requirements Coverage

| Requirement | Source Plan | Description | Status | Evidence |
|-------------|------------|-------------|--------|----------|
| STYL-01 | 16-01-PLAN.md | 텍스트 정렬 (좌/중/우) extension + 툴바 버튼 | VERIFIED (code) | renderAlignButtons(): 좌/중/우 버튼 3개, setTextAlign("left"/"center"/"right") 커맨드, isActive({ textAlign }) 활성 상태 표시, TextAlign.configure({ types: ["heading", "paragraph"] }) 등록 |
| STYL-02 | 16-01-PLAN.md | 글자색(Color) extension + 색상 선택 UI | VERIFIED (code) | renderColorPicker(): 숨겨진 input type="color" + setColor(@input), unsetColor 해제 버튼, Color + TextStyle extension 등록 |
| STYL-03 | 16-01-PLAN.md | 배경색(Highlight) extension + 색상 선택 UI | VERIFIED (code) | renderHighlightPicker(): 숨겨진 input type="color" + setHighlight({ color })(@input), unsetHighlight 해제 버튼, Highlight.configure({ multicolor: true }) 등록 |
| STYL-04 | 16-01-PLAN.md | 폰트 크기 조절 커스텀 extension + 드롭다운 UI | VERIFIED (code) | font_size_extension.js: Extension.create() 기반 커스텀 구현, renderFontSizeDropdown(): 12/14/16/18/24/32px 6단계, @tiptap/extension-font-size 미사용 확인 |

모든 4개 requirement가 PLAN frontmatter에 선언되어 있으며 REQUIREMENTS.md Traceability 표에서 Phase 16 Complete로 기록됨. Orphaned requirement 없음.

### Anti-Patterns Found

| File | Line | Pattern | Severity | Impact |
|------|------|---------|----------|--------|
| `font_size_extension.js` | 26 | `return {}` | Info | TipTap renderHTML API 명세상 fontSize 없을 때 빈 객체를 반환하는 것이 올바른 구현 — stub 아님 |

### Human Verification Required

#### 1. STYL-01 정렬 기능 브라우저 검증

**Test:** `cd teovibe && bin/dev` 실행 후 Admin 게시글 작성/수정 페이지에서 텍스트 입력, 좌/중/우 버튼 각각 클릭
**Expected:** 단락 정렬이 에디터에서 즉시 변경되고, 저장 후 게시글 상세 페이지에서도 동일 정렬이 유지됨
**Why human:** TipTap extension이 실제 브라우저 DOM에서 동작하는지, ActionText가 style attribute를 허용하는지 (ActionText 허용목록 smoke test는 통과했으나 실제 저장/렌더링 플로우 확인 필요)

#### 2. STYL-02 글자색 picker 브라우저 검증

**Test:** 텍스트 선택 후 A 아이콘(label) 클릭 — color picker에서 빨간색 선택
**Expected:** 선택 텍스트 글자색이 변경되고, 저장 후 상세 페이지에서 `span style="color:#..."`로 렌더링됨
**Why human:** Color extension의 setColor 커맨드와 TextStyle peer dependency 연동을 실제 런타임에서만 확인 가능

#### 3. STYL-03 배경 하이라이트 picker 브라우저 검증

**Test:** 텍스트 선택 후 H 아이콘(label) 클릭 — highlight picker에서 노란색 선택
**Expected:** 선택 텍스트 배경색이 변경되고, 저장 후 상세 페이지에서 `mark style="background-color:#..."`로 렌더링됨
**Why human:** Highlight multicolor 모드 및 mark 태그 허용 여부를 실제 브라우저로만 확인 가능

#### 4. STYL-04 폰트 크기 드롭다운 브라우저 검증

**Test:** 텍스트 선택 후 "크기" 드롭다운에서 32px 선택
**Expected:** 선택 텍스트 크기가 변경되고, 저장 후 상세 페이지에서 `span style="font-size:32px"`로 렌더링됨
**Why human:** 커스텀 FontSize extension의 setFontSize 커맨드가 실제 TipTap 인스턴스에서 textStyle mark와 올바르게 연동되는지 런타임 확인 필요

### Gaps Summary

자동화 검증 결과 코드 수준에서 모든 must-have artifact와 key link가 완전하게 구현되어 있음:

- `font_size_extension.js`: Extension.create() 기반 커스텀 FontSize — setFontSize/unsetFontSize 커맨드 완전 구현
- `admin_rhino_editor.js`: 5개 extension 등록(TextAlign/TextStyle/Color/FontSize/Highlight) + renderAlignButtons/renderColorPicker/renderHighlightPicker/renderFontSizeDropdown 4개 메서드 + renderToolbarEnd() 확장 완료
- npm 패키지: 5개 패키지(@tiptap/core, text-align, color, highlight, text-style) 설치 확인, @tiptap/extension-font-size 미설치 확인
- ActionText 허용목록: style attribute, span/mark 태그 모두 허용 확인 (rails runner smoke test: true)
- Vite 빌드: 캐시 기준 최신 성공 상태 확인
- 커밋: c43d4cf(Task 1), eb3ee77(Task 2) 모두 존재 확인

갭 없음. 브라우저 수동 검증(4개 항목) 후 완전히 통과 가능한 상태.

---

_Verified: 2026-03-14T13:10:00Z_
_Verifier: Claude (gsd-verifier)_
