---
phase: 03-interactive-landing
plan: 01
subsystem: ui
tags: [react, motion, vite, rails-api, typescript, landing-page]

# Dependency graph
requires:
  - phase: 01-foundation
    provides: "vite_ruby 설정, turbo:before-cache 기반 React 마운트 패턴 (react-demo.jsx)"
  - phase: 02-content-experience
    provides: "LandingSection 모델 + Admin CRUD (히어로 섹션 데이터)"
provides:
  - "/api/v1/landing_sections JSON 엔드포인트 (비인증 공개)"
  - "landing.jsx Turbo Drive 기반 React 진입점"
  - "LandingPage.tsx: API fetch + 섹션 컴포넌트 라우팅"
  - "HeroSection.tsx: motion stagger 애니메이션"
  - "home.html.erb React 마운트 포인트로 교체"
affects:
  - 03-interactive-landing (Plan 02 이후 섹션 추가 시 SECTION_COMPONENTS 맵 확장)

# Tech tracking
tech-stack:
  added:
    - "motion 12.34.3 (motion/react 임포트 기반 애니메이션)"
  patterns:
    - "SECTION_COMPONENTS 맵 패턴: section_type 문자열 -> React 컴포넌트 라우팅"
    - "LandingPage API fetch 패턴: useEffect + useState + loading placeholder (CLS 방지)"
    - "DefaultHero fallback: 섹션 없을 때 하드코딩 기본 히어로"

key-files:
  created:
    - teovibe/app/controllers/api/v1/landing_sections_controller.rb
    - teovibe/app/frontend/entrypoints/landing.jsx
    - teovibe/app/frontend/components/landing/LandingPage.tsx
    - teovibe/app/frontend/components/landing/HeroSection.tsx
  modified:
    - teovibe/config/routes.rb
    - teovibe/app/views/pages/home.html.erb
    - teovibe/package.json
    - teovibe/pnpm-lock.yaml

key-decisions:
  - "motion 12.34.3 설치 — import는 'motion/react' (구 'framer-motion'에서 리브랜딩된 패키지명)"
  - "LandingSection 인터페이스를 HeroSection.tsx에 export하여 LandingPage.tsx에서 re-import (순환 의존 방지)"
  - "home.html.erb의 ERB 섹션 루프를 완전히 제거하고 React 단일 마운트 포인트로 교체 (기존 ERB 파셜은 삭제하지 않음)"
  - "Api::V1::LandingSectionsController에 allow_unauthenticated_access 적용 (비로그인 랜딩페이지 접근 허용)"

patterns-established:
  - "SECTION_COMPONENTS 맵: 새 섹션 타입 추가 시 컴포넌트만 등록하면 LandingPage가 자동 렌더링"
  - "min-h-[744px] bg-tv-cream 로딩 플레이스홀더로 CLS(Cumulative Layout Shift) 방지"
  - "containerVariants + itemVariants stagger 패턴: motion 애니메이션 표준"

requirements-completed: [LAND-01, LAND-02]

# Metrics
duration: 2min
completed: 2026-02-22
---

# Phase 3 Plan 01: Interactive Landing - Foundation Summary

**motion stagger 애니메이션 히어로 섹션 + /api/v1/landing_sections JSON API + Turbo Drive 기반 React 랜딩페이지 스캐폴드 구축**

## Performance

- **Duration:** 2 min
- **Started:** 2026-02-22T09:03:41Z
- **Completed:** 2026-02-22T09:06:01Z
- **Tasks:** 2
- **Files modified:** 8

## Accomplishments

- motion 패키지 설치 + Api::V1::LandingSectionsController 생성 (allow_unauthenticated_access, JSON 반환)
- landing.jsx 진입점: turbo:load/turbo:before-cache 이벤트 기반 마운트/언마운트 (react-demo.jsx 패턴 재사용)
- LandingPage.tsx: API fetch + SECTION_COMPONENTS 맵 라우팅 + DefaultHero fallback
- HeroSection.tsx: 기존 _hero.html.erb 디자인 포팅 + motion containerVariants/itemVariants stagger 애니메이션
- home.html.erb 교체: ERB 섹션 루프 제거, React 마운트 포인트(#landing-root) + vite_javascript_tag 삽입

## Task Commits

1. **Task 1: motion 설치 + JSON API 엔드포인트 + 라우트 추가** - `d78d943` (feat)
2. **Task 2: React 진입점 + LandingPage + HeroSection + home.html.erb 교체** - `92b459a` (feat)

## Files Created/Modified

- `teovibe/app/controllers/api/v1/landing_sections_controller.rb` - 비인증 공개 랜딩 섹션 JSON API
- `teovibe/app/frontend/entrypoints/landing.jsx` - Turbo Drive 기반 React 진입점
- `teovibe/app/frontend/components/landing/LandingPage.tsx` - API fetch + 섹션 컴포넌트 라우터
- `teovibe/app/frontend/components/landing/HeroSection.tsx` - motion stagger 애니메이션 히어로 섹션
- `teovibe/config/routes.rb` - /api/v1/landing_sections GET 라우트 추가
- `teovibe/app/views/pages/home.html.erb` - React 마운트 포인트로 교체
- `teovibe/package.json` - motion 12.34.3 의존성 추가
- `teovibe/pnpm-lock.yaml` - 락파일 업데이트

## Decisions Made

- motion 패키지명 사용 (`motion/react` import) — 구 `framer-motion`에서 리브랜딩된 최신 패키지
- LandingSection 인터페이스를 HeroSection.tsx에서 export하고 LandingPage.tsx에서 re-import (순환 의존 방지)
- allow_unauthenticated_access를 Api::V1::LandingSectionsController에 적용 (비로그인 방문자 접근 허용)
- home.html.erb ERB 섹션 루프를 완전히 제거 (기존 ERB 파셜들은 참조용으로 보존)

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered

- `bin/vite build`가 pnpm PATH 문제로 실패 — corepack shim 경로를 명시(`/usr/local/lib/node_modules/corepack/shims`)하여 `pnpm exec vite build`로 우회 성공
- TypeScript 컴파일러(`tsc`)가 devDependencies에 없어 직접 타입체크 불가 — Vite 빌드 성공으로 대체 검증

## Next Phase Readiness

- SECTION_COMPONENTS 맵에 `hero` 컴포넌트 등록 완료 — Plan 02에서 features/testimonials/stats 등 추가 가능
- /api/v1/landing_sections 엔드포인트 공개 — Admin에서 섹션 수정 시 즉시 반영
- Vite 빌드 성공 확인 — 프로덕션 배포 준비됨

---
*Phase: 03-interactive-landing*
*Completed: 2026-02-22*
