---
phase: 14
slug: 에디터-기반-설정
status: draft
nyquist_compliant: true
wave_0_complete: false
created: 2026-03-14
---

# Phase 14 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | Rails test (minitest) + rails runner smoke |
| **Config file** | none |
| **Quick run command** | `bin/rails runner "puts ActionText::ContentHelper.allowed_attributes.include?('style') && ActionText::ContentHelper.allowed_tags.include?('table')"` |
| **Full suite command** | `bin/rails test` |
| **Estimated runtime** | ~5 seconds |

---

## Sampling Rate

- **After every task commit:** Run quick run command (true 출력 확인)
- **After every plan wave:** Admin 폼 페이지 수동 확인 — `<admin-rhino-editor>` 렌더링, AI 초안 삽입
- **Before `/gsd:verify-work`:** Full suite must be green
- **Max feedback latency:** 5 seconds

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|-----------|-------------------|-------------|--------|
| 14-01-01 | 01 | 1 | INFRA-01, INFRA-02, INFRA-03 | smoke + manual | `bin/rails runner "puts ActionText::ContentHelper.allowed_attributes.include?('style')"` | ❌ W0 | ⬜ pending |
| 14-01-02 | 01 | 1 | INFRA-02, INFRA-03 | manual | Admin 폼 + AI 초안 확인 | N/A | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [ ] `config/initializers/action_text.rb` — INFRA-01 구현 대상 (test이자 artifact)
- [ ] `app/frontend/editor/admin_rhino_editor.js` — INFRA-02 구현 대상

*Existing infrastructure covers basic Rails test framework.*

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| `<admin-rhino-editor>` 렌더링 | INFRA-02 | Web Component 렌더링은 브라우저 필요 | Admin 글쓰기 페이지 방문, 에디터 정상 표시 확인 |
| AI 초안 삽입 동작 | INFRA-03 | Anthropic API 호출 + 에디터 DOM 조작 | AI 초안 버튼 클릭 → 에디터에 콘텐츠 삽입 확인 |
| style 속성 저장 후 보존 | INFRA-01 | HTML sanitization은 렌더링 시점 동작 | style 포함 콘텐츠 저장 → 상세 페이지에서 스타일 유지 확인 |
| table 태그 저장 후 보존 | INFRA-01 | HTML sanitization은 렌더링 시점 동작 | table 포함 콘텐츠 저장 → 상세 페이지에서 표 구조 유지 확인 |

---

## Validation Sign-Off

- [x] All tasks have `<automated>` verify or Wave 0 dependencies
- [x] Sampling continuity: no 3 consecutive tasks without automated verify
- [x] Wave 0 covers all MISSING references
- [x] No watch-mode flags
- [x] Feedback latency < 5s
- [x] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
