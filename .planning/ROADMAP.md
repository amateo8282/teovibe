# Roadmap: TeoVibe

## Milestones

- v1.0 MVP - Phases 1-5 (shipped 2026-02-22)
- v1.1 Admin 고도화 - Phases 6-8 (in progress)

## Phases

<details>
<summary>v1.0 MVP (Phases 1-5) - SHIPPED 2026-02-22</summary>

### Phase 1: Foundation
**Goal**: vite_ruby + SQLite Solid 인프라 전환 및 ViewComponent/React 기반 마련
**Plans**: 3 plans

Plans:
- [x] 01-01: vite_ruby 빌드 파이프라인 전환
- [x] 01-02: SQLite WAL + Solid Queue/Cache/Cable 별도 DB 분리
- [x] 01-03: ViewComponent 기반 및 React 마운트 구조

### Phase 2: Content Experience
**Goal**: rhino-editor 리치 에디터 + 작성자 프로필 강화 + Admin 차트 대시보드
**Plans**: 3 plans

Plans:
- [x] 02-01: rhino-editor 도입 및 이미지 업로드
- [x] 02-02: 작성자 프로필 (아바타/소셜링크/뱃지)
- [x] 02-03: Admin 콘텐츠 분석 대시보드 (chartkick + groupdate)

### Phase 3: Interactive Landing
**Goal**: React + motion 인터랙티브 랜딩페이지 (5개 섹션, Admin JSON API 연동)
**Plans**: 2 plans

Plans:
- [x] 03-01: React 랜딩페이지 히어로 + 섹션 구조
- [x] 03-02: Admin 랜딩섹션 JSON API + motion 애니메이션

### Phase 4: Commerce
**Goal**: 토스페이먼츠 결제 기반 구조 완성 (Order 모델, 체크아웃 UI, SDK 위젯, confirm API)
**Plans**: 3 plans

Plans:
- [x] 04-01: Order 모델 및 결제 흐름 설계
- [x] 04-02: 체크아웃 UI + 토스페이먼츠 SDK 위젯
- [x] 04-03: 서버사이드 결제 confirm API

### Phase 5: Polish
**Goal**: 모바일 반응형 보완 + 브랜드 커스텀 에러 페이지
**Plans**: 2 plans

Plans:
- [x] 05-01: Navbar/Admin off-canvas 모바일 반응형
- [x] 05-02: 커스텀 에러 페이지 (404/500/422 한글 브랜드)

</details>

### v1.1 Admin 고도화 (In Progress)

**Milestone Goal:** Admin 카테고리 동적 관리, AI 초안 작성, 예약 발행으로 운영 효율성 극대화

- [x] **Phase 6: 카테고리 동적 관리** - Category 모델 전환 + Admin CRUD/순서 변경 UI 완성 (completed 2026-02-28)
- [x] **Phase 7: 게시글 예약 발행** - 날짜/시간 지정 발행 + Solid Queue 자동 전환 (completed 2026-03-04)
- [ ] **Phase 8: AI 초안 작성** - 주제 → 개요 → 본문 2단계 생성 + rhino-editor 자동 삽입

## Phase Details

### Phase 6: 카테고리 동적 관리
**Goal**: Admin이 런타임에 게시판/스킬팩 카테고리를 생성·수정·삭제·순서 변경할 수 있으며, 일반 사용자는 관리자 전용 카테고리를 볼 수 없다
**Depends on**: Phase 5 (v1.0 complete)
**Requirements**: CATM-01, CATM-02, CATM-03, CATM-04, CATM-05, CATM-06
**Success Criteria** (what must be TRUE):
  1. Admin이 게시판 카테고리를 이름/슬러그/설명으로 생성하면 게시글 작성 폼 카테고리 목록에 즉시 나타난다
  2. Admin이 카테고리를 수정/삭제할 수 있으며, 게시글이 있는 카테고리는 삭제가 거부된다
  3. Admin이 카테고리 순서를 드래그앤드롭으로 변경하면 목록 순서가 즉시 반영된다
  4. Admin이 카테고리를 '관리자 전용'으로 설정하면 일반 사용자의 게시글 작성 폼에 해당 카테고리가 노출되지 않는다
  5. Admin이 스킬팩 카테고리를 생성/수정/삭제/순서 변경할 수 있다
**Plans**: 4 plans

Plans:
- [x] 06-01: Category 모델 + enum→FK 마이그레이션 (Wave 1)
- [ ] 06-02: Admin 카테고리 CRUD UI + Sortable.js DnD (Wave 2)
- [ ] 06-03: 컨트롤러 통합 + 라우팅 리다이렉트 + Navbar 동적화 (Wave 2)
- [ ] 06-04: 통합 테스트 + 최종 검증 (Wave 3)

### Phase 7: 게시글 예약 발행
**Goal**: Admin이 게시글에 미래 발행 날짜/시간을 지정하면 해당 시각에 자동으로 공개 전환되고, 공개 피드 정렬이 정확하게 유지된다
**Depends on**: Phase 6
**Requirements**: SCHD-01, SCHD-02, SCHD-03
**Success Criteria** (what must be TRUE):
  1. Admin이 게시글 저장 시 날짜/시간 피커로 미래 발행 시각을 지정할 수 있으며 폼에 KST 시간이 표시된다
  2. 지정된 시각에 게시글이 자동으로 published 상태로 전환되어 공개 피드에 나타난다
  3. Admin 게시글 목록에 '예약됨' 배지와 예정 시각이 표시된다
  4. Admin이 예약된 게시글의 발행 시각을 변경하거나 예약을 취소할 수 있다
**Plans**: 3 plans

Plans:
- [x] 07-01: 마이그레이션 + Post 모델 + PublishPostJob TDD (Wave 1)
- [ ] 07-02: Admin 컨트롤러 예약 로직 + 폼 UI + 목록 배지 (Wave 2)
- [ ] 07-03: 통합 테스트 + 최종 검증 (Wave 3)

### Phase 8: AI 초안 작성
**Goal**: Admin이 주제/키워드를 입력하면 AI가 개요를 생성하고, 검토 후 본문을 생성하여 rhino-editor에 자동 삽입된다
**Depends on**: Phase 6
**Requirements**: AIDR-01, AIDR-02, AIDR-03, AIDR-04
**Success Criteria** (what must be TRUE):
  1. Admin이 게시글 작성 폼에서 주제/키워드를 입력하고 요청하면 AI가 H2 섹션 목록(개요)을 생성하여 화면에 표시한다
  2. Admin이 생성된 개요를 직접 수정한 뒤 본문 생성을 요청할 수 있다
  3. 생성된 본문이 rhino-editor에 자동으로 삽입되어 즉시 편집 가능한 상태가 된다
  4. 생성된 콘텐츠는 H2/H3 구조와 FAQ 섹션을 포함한 SEO/AEO 최적화 형식을 갖춘다
**Plans**: 2 plans

Plans:
- [ ] 08-01-PLAN.md — anthropic gem + AiDraftService + AiDraftsController + 라우트 + 테스트
- [ ] 08-02-PLAN.md — Stimulus ai_draft_controller.js + Admin 폼 AI 초안 패널 UI

## Progress

**Execution Order:**
Phases execute in numeric order: 6 → 7 → 8

| Phase | Milestone | Plans Complete | Status | Completed |
|-------|-----------|----------------|--------|-----------|
| 1. Foundation | v1.0 | 3/3 | Complete | 2026-02-22 |
| 2. Content Experience | v1.0 | 3/3 | Complete | 2026-02-22 |
| 3. Interactive Landing | v1.0 | 2/2 | Complete | 2026-02-22 |
| 4. Commerce | v1.0 | 3/3 | Complete | 2026-02-22 |
| 5. Polish | v1.0 | 2/2 | Complete | 2026-02-22 |
| 6. 카테고리 동적 관리 | 4/4 | Complete   | 2026-02-28 | - |
| 7. 게시글 예약 발행 | 3/3 | Complete   | 2026-03-04 | - |
| 8. AI 초안 작성 | v1.1 | 0/2 | Not started | - |
