# Project State

## Project Reference

See: .planning/PROJECT.md (updated 2026-02-22)

**Core value:** 사용자가 재방문하고 싶은 수준의 콘텐츠 품질과 UX를 갖춘 커뮤니티 플랫폼
**Current focus:** Phase 2 - Content Experience

## Current Position

Phase: 2 of 5 (Content Experience)
Plan: 2 of 3 in current phase
Status: In progress
Last activity: 2026-02-22 — 02-02 완료: Active Storage 아바타, 소셜링크, Badgeable concern으로 프로필 강화

Progress: [████░░░░░░] 33%

## Performance Metrics

**Velocity:**
- Total plans completed: 5
- Average duration: 5 min
- Total execution time: 21 min

**By Phase:**

| Phase | Plans | Total | Avg/Plan |
|-------|-------|-------|----------|
| 01-foundation | 3/3 | 19 min | 6 min |
| 02-content-experience | 2/3 | 2 min | 1 min |

**Recent Trend:**
- Last 5 plans: 7 min, 5 min, 7 min, 1 min, 1 min
- Trend: -

*Updated after each plan completion*

## Accumulated Context

### Decisions

Decisions are logged in PROJECT.md Key Decisions table.
Recent decisions affecting current work:

- [Init]: vite_ruby 선택 (ImportMap 대비 JSX/TypeScript 지원 필요, React + Toss SDK 전제조건)
- [Init]: rhino-editor 선택 (ActionText 데이터 마이그레이션 없이 Trix 대체 가능한 유일한 옵션)
- [Init]: 토스페이먼츠 기반 구조만 구축 — 실결제는 다음 마일스톤
- [01-02]: 개발 환경도 프로덕션과 동일하게 Solid 인프라를 분리된 DB로 운영 (primary/cache/queue/cable)
- [01-02]: Solid Cache/Cable 개발 환경 활성화는 선택적으로 주석 처리만
- [01-02]: vite_rails 환경과 충돌하는 Sprockets 잔재(assets.rb, config.assets.quiet) 제거
- [01-01]: tailwindcss-rails gem 제거 + @tailwindcss/vite npm으로 일원화 (별도 watch 프로세스 제거, Vite HMR 통합)
- [01-01]: trix + @rails/actiontext npm 패키지 추가 (Post.has_rich_text :body ActionText 사용 중)
- [01-01]: tailwindcss npm 패키지 별도 설치 필요 (@tailwindcss/vite가 peer dependency로 요구)
- [01-03]: turbo:before-render 대신 turbo:before-cache 사용 (캐시 오염 방지, RESEARCH.md 권장)
- [01-03]: root 레퍼런스를 module 스코프에 저장하여 Turbo Drive 재방문 시 중복 마운트 방지
- [01-03]: content_for :head 블록으로 페이지별 JS 엔트리포인트 로드 (전역 로드 방지)
- [02-02]: Active Storage 아바타 추가 시 기존 avatar_url 컬럼 유지 (OAuth 아바타 폴백 보존)
- [02-02]: 소셜링크를 JSON 단일 컬럼 아닌 3개 별도 string 컬럼으로 구현 (파싱 복잡도 회피)
- [02-02]: 뱃지 로직을 별도 gem 없이 Badgeable concern으로 직접 구현 (4개 뱃지에 gem은 과도)

### Pending Todos

None yet.

### Blockers/Concerns

- [Phase 2]: rhino-editor Shadow DOM과 Tailwind CSS 4 클래스 충돌 가능성 — Phase 2 플래닝 시 조사 필요
- [Phase 4]: 토스페이먼츠 웹훅 서명 검증 HMAC 알고리즘 세부 사항 — Phase 4 플래닝 시 공식 문서 확인 필요

## Session Continuity

Last session: 2026-02-22
Stopped at: Completed 02-content-experience/02-02-PLAN.md (Active Storage 아바타, 소셜링크, Badgeable concern 프로필 강화)
Resume file: None
