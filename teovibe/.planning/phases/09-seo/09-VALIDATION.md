---
phase: 9
slug: seo
status: draft
nyquist_compliant: true
wave_0_complete: false
created: 2026-03-23
---

# Phase 9 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | Minitest (Rails 기본) |
| **Config file** | test/test_helper.rb |
| **Quick run command** | `bundle exec rails test test/models/post_test.rb` |
| **Full suite command** | `bundle exec rails test` |
| **Estimated runtime** | ~15 seconds |

---

## Sampling Rate

- **After every task commit:** Run `bundle exec rails test test/models/post_test.rb`
- **After every plan wave:** Run `bundle exec rails test`
- **Before `/gsd:verify-work`:** Full suite must be green
- **Max feedback latency:** 15 seconds

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|-----------|-------------------|-------------|--------|
| 09-01-01 | 01 | 1 | SEO-01 | unit | `bundle exec rails test test/models/post_test.rb -n /auto_generate/` | ❌ W0 | ⬜ pending |
| 09-01-01 | 01 | 1 | SEO-02 | unit | `bundle exec rails test test/models/post_test.rb -n /이미 있으면/` | ❌ W0 | ⬜ pending |
| 09-01-01 | 01 | 1 | SEO-04 | unit | `bundle exec rails test test/models/post_test.rb -n /수동/` | ❌ W0 | ⬜ pending |
| 09-01-02 | 01 | 1 | SEO-03 | integration | `bundle exec rails test test/integration/og_meta_tags_test.rb` | ✅ (수정 필요) | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [ ] `test/models/post_test.rb` — SEO-01, SEO-02, SEO-04 단위 테스트 추가 (파일은 존재하나 SEO 관련 테스트 없음)
- [ ] `test/integration/og_meta_tags_test.rb` — SEO-03: seo_title 있는 게시글 메타태그 우선 사용 테스트 추가

*Existing infrastructure covers framework setup — no new dependencies needed.*

---

## Manual-Only Verifications

*All phase behaviors have automated verification.*

---

## Validation Sign-Off

- [x] All tasks have `<automated>` verify or Wave 0 dependencies
- [x] Sampling continuity: no 3 consecutive tasks without automated verify
- [x] Wave 0 covers all MISSING references
- [x] No watch-mode flags
- [x] Feedback latency < 15s
- [x] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
