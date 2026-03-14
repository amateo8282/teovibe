---
phase: 17
slug: 표-삽입
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-03-14
---

# Phase 17 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | Rails test + manual browser verification |
| **Config file** | none |
| **Quick run command** | `cd teovibe && bin/vite build 2>&1 \| tail -3` |
| **Full suite command** | `cd teovibe && bin/rails test` |
| **Estimated runtime** | ~10 seconds |

---

## Sampling Rate

- **After every task commit:** `bin/vite build` 성공 + ActionText smoke test
- **After every plan wave:** Admin 폼에서 표 삽입/탭 이동/행열 추가삭제/저장 후 렌더링 수동 확인
- **Before `/gsd:verify-work`:** Full suite must be green
- **Max feedback latency:** 10 seconds

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|-----------|-------------------|-------------|--------|
| 17-01-01 | 01 | 1 | TABL-01 | automated | `bin/vite build` + `bin/rails runner "puts ActionText::ContentHelper.allowed_tags.include?('table')"` | N/A | ⬜ pending |
| 17-01-02 | 01 | 1 | TABL-02 | manual | 표 삽입 버튼 → 표 생성 → Tab 셀 이동 | N/A | ⬜ pending |
| 17-01-03 | 01 | 1 | TABL-02 | manual | 표 셀 클릭 → 컨텍스트 메뉴 → 행/열 추가/삭제 | N/A | ⬜ pending |
| 17-01-04 | 01 | 1 | TABL-02 | manual | 저장 후 상세 페이지 표 렌더링 확인 | N/A | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [ ] `pnpm add @tiptap/extension-table@^2.27.2 @tiptap/extension-table-row@^2.27.2 @tiptap/extension-table-cell@^2.27.2 @tiptap/extension-table-header@^2.27.2` (리서치 중 이미 설치됨)

*ActionText table 태그 허용은 Phase 14에서 완료.*

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| 표 삽입 + Tab 셀 이동 | TABL-01 | 브라우저 DOM 상호작용 | 툴바 버튼 → 3x3 표 삽입 → Tab으로 셀 이동 |
| 컨텍스트 메뉴 행/열 편집 | TABL-02 | 브라우저 DOM 상호작용 | 표 셀 클릭 → 메뉴 → 행/열 추가/삭제 |
| 저장 후 표 렌더링 | TABL-02 | 서버 왕복 필요 | 저장 → 상세 페이지 → table 구조 확인 |
| 버블 메뉴 충돌 없음 | TABL-02 | 상태 전환 확인 | 표 밖 텍스트 선택 vs 표 안 커서 → 적절한 메뉴만 표시 |

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references
- [ ] No watch-mode flags
- [ ] Feedback latency < 10s
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
