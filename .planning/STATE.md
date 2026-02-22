# Project State

## Project Reference

See: .planning/PROJECT.md (updated 2026-02-22)

**Core value:** 사용자가 재방문하고 싶은 수준의 콘텐츠 품질과 UX를 갖춘 커뮤니티 플랫폼
**Current focus:** Phase 4 - Commerce

## Current Position

Phase: 4 of 5 (Commerce)
Plan: 1 of 3 in current phase (04-01 완료)
Status: In progress
Last activity: 2026-02-22 — 04-01 완료: Order 모델(enum/unique index) + SkillPack price + User payment_customer_key + CheckoutsController 스켈레톤

Progress: [██████░░░░] 60%

## Performance Metrics

**Velocity:**
- Total plans completed: 9
- Average duration: 3 min
- Total execution time: 29 min

**By Phase:**

| Phase | Plans | Total | Avg/Plan |
|-------|-------|-------|----------|
| 01-foundation | 3/3 | 19 min | 6 min |
| 02-content-experience | 3/3 | 4 min | 1 min |
| 03-interactive-landing | 2/3 | 4 min | 2 min |
| 04-commerce | 1/3 | 2 min | 2 min |

**Recent Trend:**
- Last 5 plans: 1 min, 2 min, 2 min, 2 min, 2 min
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
- [02-01]: rhino-editor 0.17.x 선택 (0.18.x는 rhinoImage/rhinoAttachment 제거로 이미지 업로드 불가)
- [02-01]: trix/actiontext JS import만 제거, npm 패키지 자체는 유지 (CSS 의존성 안전하게 보존)
- [02-01]: rhino-editor 폼 패턴 — hidden_field + <rhino-editor> 웹 컴포넌트, to_trix_html로 기존 콘텐츠 호환
- [02-02]: Active Storage 아바타 추가 시 기존 avatar_url 컬럼 유지 (OAuth 아바타 폴백 보존)
- [02-02]: 소셜링크를 JSON 단일 컬럼 아닌 3개 별도 string 컬럼으로 구현 (파싱 복잡도 회피)
- [02-02]: 뱃지 로직을 별도 gem 없이 Badgeable concern으로 직접 구현 (4개 뱃지에 gem은 과도)
- [02-03]: chartkick:install 제너레이터 미실행 (importmap 전용, Vite에서는 npm import만 사용)
- [02-03]: chartkick gem(서버사이드 헬퍼) + chartkick npm(Chart.js 클라이언트 어댑터)으로 역할 분리
- [03-01]: motion 패키지명 사용 (`motion/react` import) — 구 `framer-motion`에서 리브랜딩된 최신 패키지
- [03-01]: SECTION_COMPONENTS 맵 패턴으로 section_type 문자열 -> React 컴포넌트 라우팅 (Plan 02+ 확장 준비)
- [03-01]: allow_unauthenticated_access를 Api::V1::LandingSectionsController에 적용 (비로그인 랜딩 접근)
- [03-02]: FadeInSection을 섹션 전체와 개별 카드 양쪽에 적용 (이중 애니메이션 효과)
- [03-02]: LandingSection 타입은 HeroSection.tsx에서 re-import (Plan 01 패턴 유지, 순환 의존 방지)
- [03-02]: pricing/faq/custom 섹션 타입은 SECTION_COMPONENTS에 미등록 (null 반환으로 자동 스킵)
- [04-01]: Order status는 integer enum (pending=0/paid=1/failed=2/refunded=3) — Rails 내장 enum 활용
- [04-01]: toss_order_id unique index + payment_event_id conditional unique index (WHERE IS NOT NULL) — SQLite partial index 지원
- [04-01]: User payment_customer_key를 UUID로 자동생성하여 재사용 — 이메일/ID 예측 가능 값 금지 (토스 정책)
- [04-01]: CheckoutsController success 액션은 Plan 03에서 confirm 로직 추가 예정

### Pending Todos

None yet.

### Blockers/Concerns

- [Phase 4]: 토스페이먼츠 웹훅 서명 검증 HMAC 알고리즘 세부 사항 — Phase 4 플래닝 시 공식 문서 확인 필요

## Session Continuity

Last session: 2026-02-22
Stopped at: Completed 04-commerce/04-01-PLAN.md (Order 모델 + 결제 DB 스키마 + CheckoutsController 스켈레톤 완성)
Resume file: None
