# Project State

## Project Reference

See: .planning/PROJECT.md (updated 2026-02-28)

**Core value:** 사용자가 재방문하고 싶은 수준의 콘텐츠 품질과 UX를 갖춘 커뮤니티 플랫폼
**Current focus:** v1.1 Phase 6 - 카테고리 동적 관리

## Current Position

Phase: 6 of 8 (카테고리 동적 관리)
Plan: — of TBD in current phase
Status: Ready to plan
Last activity: 2026-02-28 — v1.1 로드맵 생성 완료

Progress: [░░░░░░░░░░] 0% (v1.1 기준)

## Performance Metrics

**Velocity (v1.0 reference):**
- Total plans completed: 13
- Average duration: —
- Total execution time: 1 day

**By Phase (v1.0):**

| Phase | Plans | Status |
|-------|-------|--------|
| 1-5 (v1.0) | 13/13 | Complete |
| 6 (v1.1) | 0/TBD | Not started |
| 7 (v1.1) | 0/TBD | Not started |
| 8 (v1.1) | 0/TBD | Not started |

## Accumulated Context

### Decisions

- Phase 6: Category 단일 모델 (`record_type` enum으로 post/skillpack 구분) 채택 — LandingSection 패턴 일관성
- Phase 6: enum → FK 마이그레이션 시 auto-increment ID 가정 금지, slug 기반 SQL 매핑 사용
- Phase 6: 기존 6개 게시판 라우팅(BlogsController 등) 유지 — SEO URL 파괴 금지
- Phase 8: Anthropic API는 `AiDraftJob` 비동기 처리 필수 — Puma 스레드 블로킹 방지
- Phase 8: `anthropic` gem v1.23.0 사용 (Faraday 직접 호출 방식 대신)

### Pending Todos

None.

### Blockers/Concerns

- Phase 6: enum → FK 마이그레이션이 가장 위험한 단계. 스테이징 DB에서 행 수 일치 검증 필수
- Phase 8 선행: `ANTHROPIC_API_KEY` `.env` 및 `.kamal/secrets` 등록 필요

## Session Continuity

Last session: 2026-02-28
Stopped at: v1.1 ROADMAP.md + STATE.md 생성 완료. Phase 6 플래닝 준비됨
Resume file: None
