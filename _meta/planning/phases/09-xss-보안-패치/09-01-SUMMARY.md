---
phase: 09-xss-보안-패치
plan: "01"
subsystem: security
tags: [xss, json-ld, seo_helper, security-patch, tdd]
dependency_graph:
  requires: []
  provides: [safe_json_ld, seo_helper_xss_patch]
  affects: [phase-12-json-ld]
tech_stack:
  added: []
  patterns: [safe_json_ld wrapper, unicode-escape, TDD RED-GREEN]
key_files:
  created:
    - teovibe/test/helpers/seo_helper_test.rb
  modified:
    - teovibe/app/helpers/seo_helper.rb
decisions:
  - "ActiveSupport의 to_json이 이미 <, >, &를 Unicode 이스케이프하지만 safe_json_ld 래퍼로 명시적 보안 의도를 문서화"
  - "safe_json_ld에서 / 도 \\u002f로 이스케이프하여 </script> 완전 차단"
  - "item_list_json_ld, faq_json_ld, breadcrumb_json_ld는 블록 내부 hash를 변수로 분리 후 safe_json_ld 호출"
metrics:
  duration_minutes: 3
  completed_date: "2026-03-14"
  tasks_completed: 2
  tasks_total: 2
  files_created: 1
  files_modified: 1
---

# Phase 9 Plan 01: SeoHelper XSS 보안 패치 Summary

**One-liner:** `safe_json_ld` private 래퍼를 통해 seo_helper.rb 8개 JSON-LD 메서드의 `.to_json.html_safe` XSS 취약 패턴을 제거하고 단위 테스트 8개로 검증

## What Was Built

- `teovibe/app/helpers/seo_helper.rb`: `safe_json_ld(data)` private 메서드 추가, 8개 public 메서드 패치
- `teovibe/test/helpers/seo_helper_test.rb`: ActionView::TestCase 기반 XSS 이스케이프 단위 테스트 8개

## Tasks Completed

| Task | Name | Commit | Files |
|------|------|--------|-------|
| 1 (RED) | XSS 이스케이프 테스트 작성 | f1e6939 | teovibe/test/helpers/seo_helper_test.rb |
| 1 (GREEN) | safe_json_ld 패치 구현 | 066c007 | teovibe/app/helpers/seo_helper.rb |
| 2 | Brakeman 정적 분석 0경고 확인 | (no code change) | — |

## Verification Results

### 단위 테스트 (8개 전부 PASS)

```
8 runs, 13 assertions, 0 failures, 0 errors, 0 skips
```

테스트 목록:
1. `test_article_json_ld_escapes_script_injection_in_title` - PASS
2. `test_article_json_ld_escapes_ampersand` - PASS
3. `test_article_json_ld_returns_valid_JSON` - PASS
4. `test_organization_json_ld_escapes_and_returns_valid_JSON` - PASS
5. `test_profile_page_json_ld_escapes_nickname` - PASS
6. `test_item_list_json_ld_escapes_name_parameter` - PASS
7. `test_breadcrumb_json_ld_escapes_item_names` - PASS
8. `test_no_raw_html_safe_without_safe_json_ld_in_seo_helper` - PASS

### .to_json.html_safe 패턴 검사

```
grep -c ".to_json.html_safe" teovibe/app/helpers/seo_helper.rb
0
```

### Brakeman 정적 분석

seo_helper.rb 관련 XSS 경고: **0건**

전체 경고 2건 (패치 대상 외 기존 이슈):
1. `app/views/posts/show.html.erb:10` — Unescaped model attribute (pre-existing)
2. `app/controllers/admin/users_controller.rb:31` — Mass Assignment (pre-existing)

### 전체 테스트 스위트

기존 실패 2건은 `AiDraftServiceTest` AI 모델명 불일치로 본 패치와 무관한 pre-existing 이슈.

seo_helper 관련 회귀 없음.

## Success Criteria Check

- [x] seo_helper.rb의 8개 public 메서드 모두 safe_json_ld 래퍼를 통해 JSON-LD를 반환한다
- [x] `.to_json.html_safe` 패턴이 seo_helper.rb에서 완전히 제거되었다 (0건)
- [x] XSS 페이로드(`</script>`, `<img onerror>`, `&`)가 Unicode 이스케이프로 변환된다
- [x] 이스케이프 후 JSON 출력이 JSON.parse로 유효하게 파싱된다
- [x] Brakeman seo_helper.rb 관련 경고 0건
- [x] 기존 테스트 스위트 회귀 없음

## Deviations from Plan

### Key Finding: ActiveSupport to_json 동작

**Found during:** TDD RED 단계

**Issue:** 계획에서 XSS 이스케이프 테스트가 RED가 될 것이라 예상했으나, Rails의 ActiveSupport가 `to_json`을 오버라이드하여 `<`, `>`, `&`를 이미 Unicode 이스케이프함. 따라서 XSS 동작 테스트 7개가 이미 GREEN이었고, 패턴 검사 테스트(`.to_json.html_safe` 0건)만 RED였음.

**Fix:** 계획대로 `safe_json_ld` 래퍼를 구현. 명시적 이스케이프는 중복이지만 보안 의도를 코드로 문서화하고 Brakeman이 `safe_json_ld` 내부 `.html_safe`를 경고하지 않도록 패턴을 확립하는 데 의미가 있음.

**Impact:** 없음 - 계획 목표 100% 달성.

## Self-Check: PASSED

- FOUND: teovibe/test/helpers/seo_helper_test.rb
- FOUND: teovibe/app/helpers/seo_helper.rb
- FOUND: .planning/phases/09-xss-보안-패치/09-01-SUMMARY.md
- FOUND: commit f1e6939 (TDD RED)
- FOUND: commit 066c007 (TDD GREEN)
