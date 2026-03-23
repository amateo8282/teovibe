---
phase: 09-seo
plan: 01
subsystem: seo
tags: [seo, meta-tags, post-model, before-save, json-ld, tdd]
dependency_graph:
  requires: []
  provides: [seo-auto-generation, seo-meta-priority]
  affects: [app/models/post.rb, app/controllers/posts_controller.rb, app/helpers/seo_helper.rb]
tech_stack:
  added: []
  patterns: [before_save callback, seo_title.presence fallback]
key_files:
  created: []
  modified:
    - app/models/post.rb
    - app/controllers/posts_controller.rb
    - app/helpers/seo_helper.rb
    - test/models/post_test.rb
    - test/integration/og_meta_tags_test.rb
    - test/fixtures/posts.yml
decisions:
  - "seo_title/seo_description 자동 생성은 before_save 콜백으로 구현 (generate_slug 패턴 일관성 유지)"
  - "body.present? 조건으로 ActionText body nil 안전 처리"
metrics:
  duration: 134s
  completed_date: "2026-03-23"
  tasks: 2
  files: 6
requirements: [SEO-01, SEO-02, SEO-03, SEO-04]
---

# Phase 09 Plan 01: SEO 자동 생성 콜백 및 메타태그 우선 연동 Summary

**One-liner:** before_save 콜백으로 seo_title/seo_description 자동 생성 + PostsController/SeoHelper에서 SEO 필드 우선 사용 (fallback: title/body)

## What Was Built

DB에 존재하지만 연결되지 않은 `seo_title`/`seo_description` 컬럼을 두 방향으로 활성화:

1. **자동 생성 (Post 모델 콜백)**: 게시글 저장 시 SEO 필드가 비어있으면 자동 생성
2. **메타태그 우선 사용 (Controller/Helper)**: 프론트엔드 메타태그에서 SEO 필드를 title/body보다 우선 사용

## Task Results

### Task 1: Post 모델 SEO 자동 생성 콜백 (TDD)

**Commit:** 86a2be1

- `before_save :auto_generate_seo_fields` 콜백 추가 (`generate_slug` 아래, `title.present?` 조건)
- `seo_title` 비어있으면 `title.truncate(60)` 자동 생성
- `seo_description` 비어있으면 `body.to_plain_text.squish.truncate(155)` 자동 생성
- 기존 값 보존: `seo_title.blank?` / `seo_description.blank?` 조건으로 덮어쓰지 않음
- 단위 테스트 5개 추가 (auto_generate 동작 전체 시나리오 검증)

### Task 2: PostsController/SeoHelper 메타태그 SEO 필드 우선 연동

**Commit:** bc84773

- `PostsController#show`: `meta_title = @post.seo_title.presence || @post.title` 패턴으로 og:title/twitter:title/description 전부 교체
- `SeoHelper#article_json_ld`: `"headline" => post.seo_title.presence || post.title`
- 픽스처 `blog_post`에 `seo_title`/`seo_description` 추가
- 통합 테스트 3개 추가 (og:title, og:description, twitter:title SEO 필드 우선 검증)
- 기존 Test 1 수정 (`post.seo_title.presence || post.title` 기대값 반영)

## Decisions Made

- `before_save` 콜백 위치: 기존 `generate_slug` 바로 아래에 추가하여 콜백 패턴 일관성 유지
- `body.present?` 조건 추가: ActionText body nil 접근 시 오류 방지
- `seo_description` fallback: Controller에서는 `helpers.strip_tags(@post.body.to_s).squish.truncate(150)` 유지 (기존 동작 보존)

## Test Results

| Test File | Before | After |
|-----------|--------|-------|
| test/models/post_test.rb | 4 tests | 9 tests (5 추가) |
| test/integration/og_meta_tags_test.rb | 11 tests | 14 tests (3 추가, 1 수정) |
| 전체 스위트 | 138 runs | 141 runs |

- 새로 추가된 테스트 전부 통과 (0 failures, 0 errors)
- 전체 테스트 스위트: 141 runs, 3 pre-existing failures (범위 외)

## Deviations from Plan

None - 계획대로 정확하게 실행됨.

## Pre-existing Failures (범위 외)

전체 스위트 실행 시 3개 기존 실패 존재 (본 플랜 변경과 무관):
1. `AiDraftServiceTest`: 모델 버전 불일치 (claude-opus vs claude-haiku)
2. `RobotsControllerTest` (2개): robots.txt 뷰 렌더링 테스트 이슈

이 실패들은 Phase 9 작업 이전부터 존재했음 (git stash 후 확인).

## Known Stubs

None - 모든 SEO 필드가 실제 데이터와 연결됨.

## Self-Check: PASSED

- [x] `app/models/post.rb` 존재 및 `auto_generate_seo_fields` 메서드 확인
- [x] `app/controllers/posts_controller.rb` `seo_title.presence` 패턴 확인
- [x] `app/helpers/seo_helper.rb` `seo_title.presence || post.title` 확인
- [x] `test/models/post_test.rb` SEO 테스트 5개 확인
- [x] `test/integration/og_meta_tags_test.rb` SEO 우선 사용 테스트 3개 확인
- [x] Commits 86a2be1, bc84773 확인
