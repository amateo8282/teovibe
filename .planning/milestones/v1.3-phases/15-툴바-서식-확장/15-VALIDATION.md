---
phase: 15
slug: 툴바-서식-확장
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-03-14
---

# Phase 15 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | Rails test + manual browser verification |
| **Config file** | none |
| **Quick run command** | `cd teovibe && bin/rails runner "puts ActionText::ContentHelper.allowed_tags.include?('u')"` |
| **Full suite command** | `cd teovibe && bin/rails test` |
| **Estimated runtime** | ~10 seconds |

---

## Sampling Rate

- **After every task commit:** Run `cd teovibe && bin/rails runner "puts ActionText::ContentHelper.allowed_tags.include?('u')"`
- **After every plan wave:** Run `cd teovibe && bin/rails test`
- **Before `/gsd:verify-work`:** Full suite must be green
- **Max feedback latency:** 10 seconds

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|-----------|-------------------|-------------|--------|
| 15-01-01 | 01 | 1 | MARK-01 | manual | Admin 폼에서 Strike 버튼 클릭 확인 | N/A | ⬜ pending |
| 15-01-02 | 01 | 1 | MARK-02 | manual | Underline 버튼 + `<u>` 렌더링 확인 | N/A | ⬜ pending |
| 15-01-03 | 01 | 1 | MARK-03 | manual | Blockquote 버튼 클릭 확인 | N/A | ⬜ pending |
| 15-01-04 | 01 | 1 | MARK-04 | manual | HorizontalRule 버튼 + `<hr>` 삽입 확인 | N/A | ⬜ pending |
| 15-01-05 | 01 | 1 | MARK-05 | manual | CodeBlock 버튼 클릭 확인 | N/A | ⬜ pending |
| 15-01-06 | 01 | 1 | MARK-06 | manual | Heading 드롭다운 H1/H2/H3 확인 | N/A | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [ ] `pnpm add @tiptap/extension-underline@^2.27.2` — MARK-02 패키지 설치
- [ ] `teovibe/config/initializers/action_text.rb` — `<u>` 태그 허용목록 추가

*Existing toolbar buttons (strike, blockquote, codeBlock) cover MARK-01/03/05.*

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Strike 버튼 동작 | MARK-01 | 브라우저 DOM 상호작용 | 텍스트 선택 → Strike 클릭 → `<del>` 확인 |
| Underline 버튼 동작 | MARK-02 | 브라우저 DOM 상호작용 | 텍스트 선택 → U 클릭 → `<u>` 확인 + 저장 후 유지 |
| Blockquote 버튼 동작 | MARK-03 | 브라우저 DOM 상호작용 | 버튼 클릭 → `<blockquote>` 확인 |
| HorizontalRule 삽입 | MARK-04 | 브라우저 DOM 상호작용 | 버튼 클릭 → `<hr>` 삽입 확인 |
| CodeBlock 버튼 동작 | MARK-05 | 브라우저 DOM 상호작용 | 버튼 클릭 → `<pre><code>` 확인 |
| Heading 드롭다운 | MARK-06 | 브라우저 DOM 상호작용 | 드롭다운 H1/H2/H3 선택 → 해당 `<hN>` 변환 확인 |

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references
- [ ] No watch-mode flags
- [ ] Feedback latency < 10s
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
