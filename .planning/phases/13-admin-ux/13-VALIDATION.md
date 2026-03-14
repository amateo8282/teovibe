---
phase: 13
slug: admin-ux
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-03-14
---

# Phase 13 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | Minitest (Rails 기본) |
| **Config file** | `test/test_helper.rb` |
| **Quick run command** | `bundle exec rails test test/integration/admin_editor_layout_test.rb` |
| **Full suite command** | `bundle exec rails test` |
| **Estimated runtime** | ~30 seconds |

---

## Sampling Rate

- **After every task commit:** Run `bundle exec rails test test/integration/admin_editor_layout_test.rb`
- **After every plan wave:** Run `bundle exec rails test`
- **Before `/gsd:verify-work`:** Full suite must be green
- **Max feedback latency:** 30 seconds

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|-----------|-------------------|-------------|--------|
| 13-01-01 | 01 | 1 | ADMN-01 | integration | `bundle exec rails test test/integration/admin_editor_layout_test.rb` | Wave 0 | pending |
| 13-01-02 | 01 | 1 | ADMN-02 | integration | `bundle exec rails test test/integration/admin_editor_layout_test.rb` | Wave 0 | pending |
| 13-01-03 | 01 | 1 | ADMN-03 | integration | `bundle exec rails test test/integration/admin_editor_layout_test.rb` | Wave 0 | pending |

*Status: pending / green / red / flaky*

---

## Wave 0 Requirements

- [ ] `test/integration/admin_editor_layout_test.rb` — ADMN-01, ADMN-02, ADMN-03 커버 (HTML 응답에서 CSS 클래스 존재 여부 검증)

*Existing infrastructure covers test framework setup.*

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| sticky 메타 패널이 스크롤 시 뷰포트 상단에 고정 | ADMN-02 | CSS sticky 동작은 렌더링 엔진 필요 | 브라우저에서 긴 본문 스크롤 시 메타 패널 고정 확인 |
| 모바일 1단 레이아웃 전환 | ADMN-03 | 반응형 브레이크포인트는 브라우저 뷰포트 필요 | 768px 이하로 리사이즈 후 1단 레이아웃 확인 |

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references
- [ ] No watch-mode flags
- [ ] Feedback latency < 30s
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
