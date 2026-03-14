---
phase: 17-표-삽입
verified: 2026-03-14T15:00:00Z
status: human_needed
score: 4/5 must-haves verified
re_verification: false
human_verification:
  - test: "툴바 버튼 클릭으로 3x3 표 삽입 및 표 안에서 버튼 비활성화 확인"
    expected: "툴바 끝에 표 삽입 버튼(&#8862;)이 보이고, 클릭하면 헤더 1행+데이터 2행의 3열 표가 삽입된다. 표 안에 커서가 있으면 버튼이 비활성화되어 중첩 삽입이 차단된다."
    why_human: "Lit 렌더링과 tiptap insertTable 커맨드의 실제 브라우저 동작, aria-disabled 상태 시각적 확인은 코드 정적 분석으로 불가"
  - test: "Tab/Shift+Tab 셀 이동 및 마지막 셀에서 새 행 자동 추가"
    expected: "표 셀에서 Tab 키로 다음 셀 이동, Shift+Tab으로 이전 셀 이동, 마지막 셀에서 Tab 시 새 행 자동 추가"
    why_human: "키보드 이벤트 핸들링은 @tiptap/extension-table 내장 기능으로 코드에 별도 구현 없음. 실제 동작은 브라우저에서만 검증 가능"
  - test: "표 셀에 커서 위치 시 컨텍스트 메뉴 표시 및 행/열 추가/삭제 동작"
    expected: "표 셀에 커서를 두면(텍스트 미선택) 7개 버튼 컨텍스트 메뉴가 커서 근처에 나타나고, 각 버튼 클릭으로 행/열 추가/삭제 및 표 삭제가 동작한다"
    why_human: "Light DOM 메뉴의 position:absolute 위치 계산(coordsAtPos + scrollY), 메뉴 표시/숨김 토글이 실제 브라우저 레이아웃에서 올바르게 동작하는지 확인 필요"
  - test: "텍스트 선택 시 표 컨텍스트 메뉴 숨김 + 기존 버블 메뉴만 표시"
    expected: "표 안에서 텍스트를 드래그 선택하면 표 컨텍스트 메뉴가 사라지고 rhino-editor 기존 텍스트 버블 메뉴만 표시된다"
    why_human: "selection.empty 체크 로직은 코드에서 확인되었으나, 두 메뉴의 동시 표시/충돌 여부는 실제 브라우저 인터랙션에서만 확인 가능"
  - test: "저장 후 게시글 상세 페이지 표 렌더링"
    expected: "표가 포함된 게시글 저장 후 상세 페이지에서 <table>/<th>/<td> 구조와 내용이 올바르게 표시된다"
    why_human: "ActionText 허용목록은 코드에서 확인되었으나, TipTap 출력 HTML이 Rails ActionText를 통해 실제로 저장되고 렌더링되는 전체 플로우는 브라우저 E2E 확인 필요"
---

# Phase 17: 표 삽입 Verification Report

**Phase Goal:** Admin 에디터에서 표를 삽입하고 행/열을 추가 및 삭제할 수 있다
**Verified:** 2026-03-14T15:00:00Z
**Status:** human_needed
**Re-verification:** No — initial verification

## Goal Achievement

### Observable Truths

| #  | Truth                                                                    | Status      | Evidence                                                                                             |
|----|--------------------------------------------------------------------------|-------------|------------------------------------------------------------------------------------------------------|
| 1  | 툴바 버튼 클릭으로 3x3 표가 에디터에 삽입된다                           | ? UNCERTAIN | `renderInsertTableButton()` 구현됨, `insertTable({ rows: 3, cols: 3, withHeaderRow: true })` 연결됨, `renderToolbarEnd()`에 포함됨 — 실제 브라우저 동작 미확인                  |
| 2  | 표 안에서 Tab/Shift+Tab으로 셀 간 이동이 된다                            | ? UNCERTAIN | `@tiptap/extension-table`이 Tab/Shift+Tab 핸들러 내장 — 코드 구현 없어도 extension 등록 시 자동 동작하나 브라우저 확인 필요 |
| 3  | 표 셀에 커서를 두면 행/열 추가/삭제 컨텍스트 메뉴가 나타난다            | ? UNCERTAIN | `_initTableContextMenu()`, `_updateTableMenu()`, `selectionUpdate` + `isActive("table")` 로직 구현 완료 — 브라우저 위치 계산 동작 미확인 |
| 4  | 표 안에서 텍스트를 선택하면 표 컨텍스트 메뉴는 숨겨지고 버블 메뉴만 표시 | ? UNCERTAIN | `!isEmpty` 조건으로 숨김 처리 코드 확인 (`selection.empty` 체크) — 두 메뉴 동시 표시 충돌은 브라우저 확인 필요 |
| 5  | 저장 후 게시글 상세 페이지에서 표 구조와 내용이 올바르게 렌더링된다      | ? UNCERTAIN | ActionText 허용목록에 `table`, `thead`, `tbody`, `th`, `td`, `tr`, `colspan`, `rowspan` 전부 포함 확인 (`action_text.rb` L12-13) — 실제 저장/렌더링은 E2E 확인 필요 |

**Score:** 0/5 truths can be fully verified programmatically — all pass automated static checks but require browser verification

### Required Artifacts

| Artifact                                                          | Expected                                          | Status      | Details                                                                                                                                            |
|-------------------------------------------------------------------|---------------------------------------------------|-------------|----------------------------------------------------------------------------------------------------------------------------------------------------|
| `teovibe/app/frontend/editor/admin_rhino_editor.js`               | Table 4종 extension 등록 + 삽입 버튼 + 컨텍스트 메뉴 | ✓ VERIFIED  | 389줄, 실질적 구현. 4종 import (L12-15), `Table.configure({ resizable: false })` + 3종 등록 (L30-35), `renderInsertTableButton()` (L352-372), `_initTableContextMenu()` (L58-110), `_updateTableMenu()` (L113-136), `_handleTableMenuClick()` (L139-154). `renderToolbarEnd()`에 삽입 버튼 포함 (L384) |
| `teovibe/package.json` — `@tiptap/extension-table` 외 3개 패키지  | 4개 패키지 의존성 선언                            | ✓ VERIFIED  | `"@tiptap/extension-table": "^2.27.2"`, `"@tiptap/extension-table-cell": "^2.27.2"`, `"@tiptap/extension-table-header": "^2.27.2"`, `"@tiptap/extension-table-row": "^2.27.2"` 모두 선언됨 (L20-23) |
| `teovibe/node_modules/@tiptap/extension-table` 외 3개             | 실제 설치 완료                                    | ✓ VERIFIED  | node_modules에 4개 패키지 디렉토리 존재 확인                                                                                                         |
| `teovibe/config/initializers/action_text.rb`                      | table 관련 태그/속성 허용목록                     | ✓ VERIFIED  | L12: `table thead tbody tfoot tr th td colgroup col caption` 허용. L13: `colspan rowspan scope` 허용. (Phase 14 설정 — 변경 없음)                   |

### Key Link Verification

| From                               | To                                | Via                        | Status    | Details                                                                               |
|------------------------------------|-----------------------------------|----------------------------|-----------|---------------------------------------------------------------------------------------|
| `admin_rhino_editor.js`            | `@tiptap/extension-table`         | import + addExtensions     | ✓ WIRED   | L12: `import Table from "@tiptap/extension-table"` + L30: `Table.configure({ resizable: false })` addExtensions 등록 |
| `admin_rhino_editor.js` 삽입 버튼 | `editor.chain().insertTable()`    | toolbar click handler      | ✓ WIRED   | L366: `this.editor?.chain().focus().insertTable({ rows: 3, cols: 3, withHeaderRow: true }).run()` — click handler 내부에서 호출 |
| `admin_rhino_editor.js` 컨텍스트 메뉴 | `editor.on("selectionUpdate")`  | selectionUpdate + isActive | ✓ WIRED   | L43: `this.editor?.on("selectionUpdate", () => this._updateTableMenu())`. L115: `this.editor.isActive("table")` 확인 |

### Requirements Coverage

| Requirement | Source Plan | Description                                       | Status       | Evidence                                                                                        |
|-------------|-------------|---------------------------------------------------|--------------|-------------------------------------------------------------------------------------------------|
| TABL-01     | 17-01-PLAN  | Table extension 설치 (table/row/cell/header 4개 패키지) | ✓ SATISFIED | 4개 패키지 package.json 선언 + node_modules 설치 + admin_rhino_editor.js에 import + addExtensions 등록 완료. Vite 빌드 성공 (4.79s) |
| TABL-02     | 17-01-PLAN  | 표 삽입 버튼 + 행/열 추가/삭제 컨텍스트 메뉴      | ✓ SATISFIED  | `renderInsertTableButton()` + `renderToolbarEnd()` 통합. 7개 액션 컨텍스트 메뉴 (`add-row-before/after`, `delete-row`, `add-col-before/after`, `delete-col`, `delete-table`). 실제 동작은 브라우저 검증 필요 |

**REQUIREMENTS.md 트레이서빌리티 확인:** TABL-01, TABL-02 모두 Phase 17 Complete로 표시됨. 이 Phase에 할당된 추가 요구사항 없음 (BLCK-01은 Phase 18 Pending).

**Orphaned Requirements:** 없음 — REQUIREMENTS.md에서 Phase 17에 매핑된 요구사항이 PLAN에 모두 선언됨.

### Anti-Patterns Found

| File | Line | Pattern | Severity | Impact |
|------|------|---------|----------|--------|
| (없음) | — | — | — | — |

정적 분석 결과: TODO/FIXME/PLACEHOLDER 없음. 빈 구현 없음. 모든 메서드가 실질적 로직 포함.

### Human Verification Required

#### 1. 표 삽입 버튼 동작 확인

**Test:** Rails 서버 실행 후 Admin 게시글 작성/수정 폼에서 툴바 끝의 표 삽입 버튼(&#8862;) 클릭
**Expected:** 3열 3행 표(1행은 헤더 `<th>`, 2행은 데이터 `<td>`)가 에디터 안에 삽입됨. 표 안에 커서가 있으면 버튼이 비활성화됨.
**Why human:** Lit 렌더링 사이클과 tiptap insertTable 커맨드의 실제 브라우저 실행 결과는 정적 분석 불가

#### 2. Tab/Shift+Tab 셀 이동

**Test:** 표 셀 클릭 후 Tab 키 반복 입력
**Expected:** Tab으로 다음 셀 이동, Shift+Tab으로 이전 셀 이동, 마지막 셀에서 Tab으로 새 행 자동 추가
**Why human:** @tiptap/extension-table 내장 키 핸들러의 실제 동작 확인은 브라우저 필요

#### 3. 컨텍스트 메뉴 표시 및 행/열 편집

**Test:** 표 셀을 클릭하고(텍스트 미선택) 컨텍스트 메뉴 표시 확인. 각 버튼("아래 행 추가", "오른쪽 열 추가", "행 삭제", "열 삭제", "표 삭제") 클릭
**Expected:** 커서 근처에 7개 버튼 메뉴가 나타남. 각 버튼이 해당 편집 액션을 실행함.
**Why human:** Light DOM 메뉴 position:absolute 위치 계산(coordsAtPos + window.scrollY)의 실제 화면 렌더링 결과 확인 필요

#### 4. 텍스트 선택 시 메뉴 충돌 확인

**Test:** 표 셀 안에서 텍스트를 드래그 선택
**Expected:** 표 컨텍스트 메뉴가 사라지고 기존 rhino-editor 텍스트 버블 메뉴만 표시됨
**Why human:** selection.empty 체크 로직은 코드에서 확인되었으나 두 메뉴의 실제 동시 표시 여부는 브라우저 인터랙션으로만 확인 가능

#### 5. 저장 후 표 렌더링

**Test:** 표가 포함된 게시글 저장 후 상세 페이지 방문
**Expected:** 표의 행/열 구조와 입력한 내용이 상세 페이지에서 HTML `<table>` 형태로 올바르게 표시됨
**Why human:** ActionText 허용목록은 확인되었으나 TipTap 출력 HTML이 ActionText 저장/렌더링 파이프라인을 통해 올바르게 처리되는지 E2E 검증 필요

### Gaps Summary

자동화 검증 결과 코드 구현은 완전하다:

- **TABL-01:** 4개 패키지가 package.json 선언, node_modules 설치, admin_rhino_editor.js에 import + addExtensions 등록 완료
- **TABL-02:** renderInsertTableButton() 구현 + renderToolbarEnd() 통합, Light DOM 컨텍스트 메뉴 7개 액션 구현, selectionUpdate 리스너 + isActive 로직 구현 완료
- **Vite 빌드:** --force 재빌드 성공 (4.79s)
- **ActionText 허용목록:** action_text.rb에 table/th/td/tr/thead/tbody/tfoot + colspan/rowspan 전부 허용 확인
- **커밋 존재:** b10e4db 확인됨

자동화로 검증 불가한 항목은 모두 브라우저 인터랙션(표 삽입 실행, Tab 키, 컨텍스트 메뉴 위치, 메뉴 충돌, 저장 후 렌더링)이다. 구조적 결함(stub, orphaned artifact, missing wiring)은 발견되지 않았다.

---

_Verified: 2026-03-14T15:00:00Z_
_Verifier: Claude (gsd-verifier)_
