---
phase: 16
slug: 텍스트-스타일링
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-03-14
---

# Phase 16 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | Rails test + manual browser verification |
| **Config file** | none |
| **Quick run command** | `cd teovibe && bin/rails runner "puts ActionText::ContentHelper.allowed_attributes.include?('style') && ActionText::ContentHelper.allowed_tags.include?('span') && ActionText::ContentHelper.allowed_tags.include?('mark')"` |
| **Full suite command** | `cd teovibe && bin/rails test` |
| **Estimated runtime** | ~10 seconds |

---

## Sampling Rate

- **After every task commit:** `bin/rails runner` smoke + `bin/vite build` 성공 확인
- **After every plan wave:** Admin 폼에서 4개 스타일 기능 수동 확인 + 저장 후 상세 페이지 렌더링 확인
- **Before `/gsd:verify-work`:** Full suite must be green
- **Max feedback latency:** 10 seconds

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|-----------|-------------------|-------------|--------|
| 16-01-01 | 01 | 1 | STYL-01 | manual | 정렬 버튼 클릭 → text-align 적용 + 저장 후 유지 | N/A | ⬜ pending |
| 16-01-02 | 01 | 1 | STYL-02 | manual | 색상 picker → color 적용 + 저장 후 유지 | N/A | ⬜ pending |
| 16-01-03 | 01 | 1 | STYL-03 | manual | 하이라이트 picker → background-color 적용 + 저장 후 유지 | N/A | ⬜ pending |
| 16-01-04 | 01 | 1 | STYL-04 | manual | 폰트 크기 드롭다운 → font-size 적용 + 저장 후 유지 | N/A | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [ ] `pnpm add @tiptap/extension-text-align@^2.27.2 @tiptap/extension-color@^2.27.2 @tiptap/extension-highlight@^2.27.2 @tiptap/extension-text-style@^2.27.2`
- [ ] `teovibe/app/frontend/editor/font_size_extension.js` — 커스텀 FontSize extension 신규 파일

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| 정렬 버튼 동작 | STYL-01 | 브라우저 DOM 상호작용 | 좌/중/우 클릭 → text-align 확인 + 저장 후 유지 |
| 글자색 변경 | STYL-02 | 브라우저 DOM 상호작용 | 텍스트 선택 → color picker → 저장 후 유지 |
| 배경 하이라이트 | STYL-03 | 브라우저 DOM 상호작용 | 텍스트 선택 → highlight picker → 저장 후 유지 |
| 폰트 크기 변경 | STYL-04 | 브라우저 DOM 상호작용 | 드롭다운 선택 → font-size 확인 + 저장 후 유지 |

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references
- [ ] No watch-mode flags
- [ ] Feedback latency < 10s
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
