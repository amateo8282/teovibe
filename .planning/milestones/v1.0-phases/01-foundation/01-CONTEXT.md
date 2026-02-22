# Phase 1: Foundation - Context

**Gathered:** 2026-02-22
**Status:** Ready for planning

<domain>
## Phase Boundary

vite_ruby로 JS 빌드 파이프라인을 전환하고, SQLite WAL 모드 + Solid 인프라 별도 DB를 구성하며, ViewComponent를 도입하여 이후 모든 Phase의 기반을 마련한다. React 마운트가 동작함을 확인하는 것까지 포함.

</domain>

<decisions>
## Implementation Decisions

### React 마운트 패턴
- 전용 페이지 마운트 방식 채택 — 특정 페이지 전체를 React가 담당하는 구조
- ERB 안에 부분 삽입(Island) 방식은 사용하지 않음
- 데이터 전달은 JSON API 호출 방식 — React가 마운트 후 fetch로 Rails API를 호출하여 데이터를 가져옴
- ERB에서 data-* 속성으로 props를 전달하는 방식은 사용하지 않음

### Turbo와의 공존
- React 전용 페이지도 Turbo Drive 네비게이션을 유지함
- React 컴포넌트의 마운트/언마운트 라이프사이클을 Turbo 이벤트에 맞춰 처리해야 함
- data-turbo=false로 빠지지 않고, Turbo 흐름 안에서 React를 동작시킴

### Claude's Discretion
- Phase 1에서의 React 확인용 데모 컴포넌트 형태 (마운트 동작 확인이 목적)
- ViewComponent 첫 추출 대상 선정
- ImportMap에서 vite_ruby로의 마이그레이션 세부 전략
- Propshaft과 vite_ruby 공존 방식
- SQLite WAL 모드 및 Solid 인프라 구성 세부사항
- 개발 환경 HMR/빌드 설정

</decisions>

<specifics>
## Specific Ideas

- React 전용 페이지가 JSON API로 데이터를 받는 구조이므로, Phase 3 랜딩페이지에서도 동일한 패턴을 사용하게 됨
- Turbo 네비게이션 유지가 전제이므로 turbo:before-render / turbo:load 이벤트 기반 마운트/언마운트 처리가 필요

</specifics>

<deferred>
## Deferred Ideas

None — discussion stayed within phase scope

</deferred>

---

*Phase: 01-foundation*
*Context gathered: 2026-02-22*
