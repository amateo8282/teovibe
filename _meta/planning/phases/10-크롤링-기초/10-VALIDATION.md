---
phase: 10
slug: 크롤링-기초
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-03-14
---

# Phase 10 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | Rails Minitest (내장) |
| **Config file** | `test/test_helper.rb` |
| **Quick run command** | `bin/rails test test/controllers/robots_controller_test.rb test/integration/seo_tags_test.rb` |
| **Full suite command** | `bin/rails test` |
| **Estimated runtime** | ~15 seconds |

---

## Sampling Rate

- **After every task commit:** Run `bin/rails test test/controllers/robots_controller_test.rb test/integration/seo_tags_test.rb`
- **After every plan wave:** Run `bin/rails test`
- **Before `/gsd:verify-work`:** Full suite must be green
- **Max feedback latency:** 15 seconds

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|-----------|-------------------|-------------|--------|
| 10-01-01 | 01 | 0 | CRAWL-01, CRAWL-02 | integration | `bin/rails test test/controllers/robots_controller_test.rb` | Wave 0 | pending |
| 10-01-02 | 01 | 0 | CRAWL-03 | integration | `bin/rails test test/integration/sitemap_test.rb` | Wave 0 | pending |
| 10-01-03 | 01 | 0 | SRCH-01, SRCH-02 | integration | `bin/rails test test/integration/seo_tags_test.rb` | Wave 0 | pending |
| 10-01-04 | 01 | 1 | CRAWL-01, CRAWL-02 | integration | `bin/rails test test/controllers/robots_controller_test.rb` | Wave 0 | pending |
| 10-01-05 | 01 | 1 | CRAWL-03 | integration | `bin/rails test test/integration/sitemap_test.rb` | Wave 0 | pending |
| 10-01-06 | 01 | 1 | SRCH-01, SRCH-02 | integration | `bin/rails test test/integration/seo_tags_test.rb` | Wave 0 | pending |

*Status: pending / green / red / flaky*

---

## Wave 0 Requirements

- [ ] `teovibe/test/controllers/robots_controller_test.rb` — CRAWL-01, CRAWL-02 커버
- [ ] `teovibe/test/integration/sitemap_test.rb` — CRAWL-03 커버
- [ ] `teovibe/test/integration/seo_tags_test.rb` — SRCH-01, SRCH-02 커버

*Existing infrastructure covers test framework — only test files need creation.*

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Google Search Console 소유권 인증 통과 | SRCH-01 | 실제 GSC 대시보드 확인 필요 | 1. 배포 후 GSC 접속 2. 속성 추가 3. HTML 태그 방식 선택 4. 인증 확인 |
| 네이버 서치어드바이저 소유권 인증 통과 | SRCH-02 | 실제 서치어드바이저 대시보드 확인 필요 | 1. 배포 후 서치어드바이저 접속 2. 사이트 추가 3. HTML 태그 방식 선택 4. 인증 확인 |

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references
- [ ] No watch-mode flags
- [ ] Feedback latency < 15s
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
