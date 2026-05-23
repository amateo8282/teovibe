---
phase: 18
slug: 블록-삽입-메뉴
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-03-14
---

# Phase 18 — Validation Strategy

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

- **After every task commit:** `bin/vite build` 성공 확인
- **After every plan wave:** Admin 폼에서 빈 단락 + 버튼 + 4개 삽입 동작 수동 확인
- **Before `/gsd:verify-work`:** Full suite must be green
- **Max feedback latency:** 10 seconds

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|-----------|-------------------|-------------|--------|
| 18-01-01 | 01 | 1 | BLCK-01 | automated | `bin/vite build` | N/A | ⬜ pending |
| 18-01-02 | 01 | 1 | BLCK-01 | manual | 빈 단락 + 버튼 표시 확인 | N/A | ⬜ pending |
| 18-01-03 | 01 | 1 | BLCK-01 | manual | 4개 옵션 삽입 동작 확인 | N/A | ⬜ pending |
| 18-01-04 | 01 | 1 | BLCK-01 | manual | 텍스트 있는 줄에서 버튼 미표시 확인 | N/A | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- 신규 패키지 설치 불필요
- `admin_rhino_editor.js`에 floating menu 메서드 추가만 필요

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| 빈 단락 + 버튼 표시 | BLCK-01 | 브라우저 DOM 상호작용 | 빈 줄 클릭 → + 버튼 나타남 |
| 4개 옵션 삽입 | BLCK-01 | 브라우저 DOM 상호작용 | + 클릭 → 구분선/인용구/코드블록/표 선택 |
| 텍스트 줄 미표시 | BLCK-01 | 브라우저 DOM 상호작용 | 텍스트 있는 줄 → 버튼 없음 |
| 표 셀 내 미표시 | BLCK-01 | 브라우저 DOM 상호작용 | 표 안 빈 셀 → 버튼 없음 (depth > 1) |

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references
- [ ] No watch-mode flags
- [ ] Feedback latency < 10s
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
