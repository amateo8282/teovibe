---
phase: 9
slug: xss-보안-패치
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-03-14
---

# Phase 9 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | Minitest (Rails default) |
| **Config file** | `test/test_helper.rb` |
| **Quick run command** | `bin/rails test test/helpers/seo_helper_test.rb` |
| **Full suite command** | `bin/rails test` |
| **Estimated runtime** | ~15 seconds |

---

## Sampling Rate

- **After every task commit:** Run `bin/rails test test/helpers/seo_helper_test.rb`
- **After every plan wave:** Run `bin/rails test`
- **Before `/gsd:verify-work`:** Full suite must be green
- **Max feedback latency:** 15 seconds

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|-----------|-------------------|-------------|--------|
| 09-01-01 | 01 | 1 | SEC-01 | unit | `bin/rails test test/helpers/seo_helper_test.rb` | ❌ W0 | ⬜ pending |
| 09-01-02 | 01 | 1 | SEC-01 | static | `bin/brakeman -q --only CrossSiteScripting` | ✅ | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [ ] `test/helpers/seo_helper_test.rb` — XSS 이스케이프 검증 테스트 스텁 (SEC-01)

*Existing test infrastructure covers framework setup. Only helper test file needed.*

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| JSON-LD가 Google Rich Results Test에서 유효 | SEC-01 | 외부 서비스 검증 | 게시글 페이지 HTML의 JSON-LD를 Google Rich Results Test에 붙여넣기 |

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references
- [ ] No watch-mode flags
- [ ] Feedback latency < 15s
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
