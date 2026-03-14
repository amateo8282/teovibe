---
gsd_state_version: 1.0
milestone: v1.2
milestone_name: SEO + Admin UX
status: planning
stopped_at: "Checkpoint: Task 2 human-verify — 13-01-PLAN.md"
last_updated: "2026-03-14T05:38:50.946Z"
last_activity: 2026-03-14 — Roadmap created
progress:
  total_phases: 10
  completed_phases: 5
  total_plans: 7
  completed_plans: 7
  percent: 0
---

# Project State

## Project Reference

See: .planning/PROJECT.md (updated 2026-03-14)

**Core value:** 사용자가 재방문하고 싶은 수준의 콘텐츠 품질과 UX를 갖춘 커뮤니티 플랫폼
**Current focus:** v1.2 SEO + Admin UX

## Current Position

Phase: 9 (XSS 보안 패치) — Not started
Plan: —
Status: Roadmap defined, awaiting phase planning
Last activity: 2026-03-14 — Roadmap created

```
Progress: [                    ] 0%
Phase 9  [ ] XSS 보안 패치
Phase 10 [ ] 크롤링 기초
Phase 11 [ ] 소셜/색인 메타태그
Phase 12 [ ] 구조화 데이터
Phase 13 [ ] Admin 에디터 UX
```

## Performance Metrics

**By Milestone:**

| Milestone | Phases | Plans | Status | Shipped |
|-----------|--------|-------|--------|---------|
| v1.0 MVP | 5 | 13 | Complete | 2026-02-22 |
| v1.1 Admin 고도화 | 3 | 9 | Complete | 2026-03-06 |
| v1.2 SEO + Admin UX | 5 | TBD | Active | — |
| Phase 09-xss-보안-패치 P01 | 4 | 2 tasks | 2 files |
| Phase 10-크롤링-기초 P02 | 3 | 1 tasks | 2 files |
| Phase 10-크롤링-기초 P01 | 20 | 2 tasks | 7 files |
| Phase 11-소셜-색인-메타태그 P02 | 2 | 1 tasks | 4 files |
| Phase 11-소셜-색인-메타태그 P01 | 2 | 2 tasks | 4 files |
| Phase 12-구조화-데이터 P01 | 15 | 2 tasks | 3 files |
| Phase 13-admin-ux P01 | 8 | 1 tasks | 4 files |

## Accumulated Context

### Decisions

Full decision log in PROJECT.md Key Decisions table.

**v1.2 Key Decisions:**
- Phase 9(XSS 패치)를 Phase 12(JSON-LD)의 선행 조건으로 분리 — 취약한 헬퍼를 활성화하기 전 패치 필수
- CRAWL + SRCH를 Phase 10으로 통합 — 둘 다 config/정적 파일 수정이라 동일 커밋 단위
- SOCL + INDX를 Phase 11로 통합 — 동일한 `set_meta_tags` 인프라 사용, 뷰 작업 한 번에 처리
- Phase 13(Admin UX)을 SEO 트랙과 독립 — 모델/컨트롤러 변경 없는 순수 HTML+Tailwind 작업, 병렬 진행 가능
- 검색엔진 인증 토큰은 Rails credentials 저장 — Kamal 배포 환경에서 ENV보다 일관성 높음
- [Phase 09-xss-보안-패치]: safe_json_ld private 래퍼로 .to_json.html_safe 패턴 교체 - 명시적 보안 의도 문서화
- [Phase 09-xss-보안-패치]: ActiveSupport to_json이 이미 XSS 이스케이프하지만 safe_json_ld로 이중 보안 확보
- [Phase 10-크롤링-기초]: credentials.dig 직접 호출 방식 사용 — set_meta_tags verification: 방식 불사용 (경로 외 소실 위험)
- [Phase 10-크롤링-기초]: yield :head 이전에 인증 태그 배치 — 모든 경로에서 일관 출력 보장
- [Phase 10-크롤링-기초]: 정적 public/robots.txt 삭제 필수 — Rails 정적 파일이 라우터보다 우선하므로 컨트롤러 무시됨
- [Phase 10-크롤링-기초]: sitemap.rb 게시글 라우트 단일화 — post_path(post)로 통합하여 카테고리 의존성 제거
- [Phase 11-소셜-색인-메타태그]: Admin 레이아웃은 display_meta_tags 미사용이므로 meta 태그 직접 삽입, 컨트롤러는 before_action :set_noindex 패턴으로 특정 액션에만 noindex 적용
- [Phase 11-소셜-색인-메타태그]: request.base_url + '/icon.png' 방식으로 OG 이미지 절대 URL 생성 — helpers.asset_url 테스트 환경 불안정 방지
- [Phase 11-소셜-색인-메타태그]: ActionText 픽스처에 blog_post 본문 추가 — 빈 body로 인한 og:description 누락 방지
- [Phase 12-구조화-데이터]: content_for :head 블록 내 script 태그 배치로 레이아웃의 yield :head 위치에 JSON-LD 자동 삽입
- [Phase 12-구조화-데이터]: category_posts_url(절대 URL) 사용 — BreadcrumbList item 필드는 절대 URL 필요
- [Phase 13-admin-ux]: new/edit 래퍼 카드(bg-white rounded-card shadow-sm p-6) 제거 — 2단 레이아웃에서 메타 패널 내부에 별도 카드 적용
- [Phase 13-admin-ux]: sticky 부모(flex 컨테이너)에 overflow 속성 추가 금지 — overflow가 있으면 sticky 동작이 해당 컨테이너 범위로 제한됨

### Pending Todos

None.

### Blockers/Concerns

- Post slug constraint 불일치 (영문자 시작 slug 미매칭) — tech debt from v1.1
- ANTHROPIC_API_KEY 프로덕션 환경변수 등록 필요 — tech debt from v1.1

## Session Continuity

Last session: 2026-03-14T05:38:50.944Z
Stopped at: Checkpoint: Task 2 human-verify — 13-01-PLAN.md
Resume file: None
Next action: `/gsd:plan-phase 9`
