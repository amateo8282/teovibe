# Roadmap: TeoVibe

## Overview

기존 Rails 8.1 모놀리스 위에 4개 역량 계층을 추가하는 고도화 마일스톤. JavaScript 파이프라인을 vite_ruby로 전환하여 React와 npm 패키지를 사용할 수 있는 기반을 먼저 마련하고, 그 위에 에디터 개선/프로필/어드민 분석(콘텐츠 경험), React 기반 인터랙티브 랜딩페이지, 토스페이먼츠 결제 기반, UI/UX 완성도 순으로 전달한다.

## Phases

**Phase Numbering:**
- Integer phases (1, 2, 3): Planned milestone work
- Decimal phases (2.1, 2.2): Urgent insertions (marked with INSERTED)

Decimal phases appear between their surrounding integers in numeric order.

- [x] **Phase 1: Foundation** - vite_ruby 파이프라인 전환 + SQLite 강화 + ViewComponent 도입으로 이후 모든 작업의 기반 마련 (completed 2026-02-22)
- [x] **Phase 2: Content Experience** - rhino-editor 도입, 작성자 프로필 강화, Admin 분석 대시보드로 콘텐츠 품질 완성 (completed 2026-02-22)
- [x] **Phase 3: Interactive Landing** - React 인터랙티브 랜딩페이지로 외부 유입 전환율 개선 (completed 2026-02-22)
- [x] **Phase 4: Commerce** - 토스페이먼츠 결제 기반 구조 구축 (Order 모델, 체크아웃 UI, SDK 연동) (completed 2026-02-22)
- [x] **Phase 5: Polish** - 전체 반응형 보완 및 에러 페이지 완성으로 프로덕션 완성도 달성 (completed 2026-02-22)

## Phase Details

### Phase 1: Foundation
**Goal**: 모든 후속 작업이 의존하는 JS 빌드 파이프라인, 데이터베이스, UI 컴포넌트 기반을 완성한다
**Depends on**: Nothing (first phase)
**Requirements**: INFRA-01, INFRA-02, INFRA-03
**Success Criteria** (what must be TRUE):
  1. `rails assets:precompile`이 성공하고 기존 Stimulus 컨트롤러와 Turbo 기능이 정상 동작한다
  2. Solid Queue/Cache/Cable이 별도 SQLite 파일을 사용하며 WAL 모드가 활성화되어 있다
  3. ViewComponent가 설치되어 첫 UI 컴포넌트(예: CardComponent)가 렌더링된다
  4. JSX 파일을 작성하고 브라우저에서 React 컴포넌트가 마운트됨을 확인할 수 있다
**Plans**: 3 plans

Plans:
- [ ] 01-01-PLAN.md -- vite_ruby 파이프라인 전환 (ImportMap 제거, Stimulus/Turbo 마이그레이션, Tailwind CSS v4 @tailwindcss/vite 전환)
- [x] 01-02-PLAN.md -- SQLite WAL 모드 확인 + 개발 환경 Solid Queue/Cache/Cable 별도 DB 구성
- [ ] 01-03-PLAN.md -- ViewComponent 4.x 설치 + React 데모 전용 페이지 마운트 (Turbo 공존 검증)

### Phase 2: Content Experience
**Goal**: 글 작성 UX를 개선하고 작성자 프로필을 완성하며 Admin에 콘텐츠 분석을 제공하여 플랫폼 콘텐츠 품질을 높인다
**Depends on**: Phase 1
**Requirements**: EDIT-01, EDIT-02, EDIT-03, PROF-01, PROF-02, ADMN-01
**Success Criteria** (what must be TRUE):
  1. 작성자가 새 글을 쓸 때 rhino-editor가 로드되고 기존 Trix 데이터가 깨지지 않고 렌더링된다
  2. 에디터에서 이미지를 드래그&드롭으로 업로드하고 크기를 조절할 수 있다
  3. 텍스트를 선택하면 버블 메뉴(볼드, 이탤릭, 링크 등)가 나타난다
  4. 작성자 프로필 페이지에 아바타, 바이오, 소셜링크, 포인트/레벨/뱃지, 작성 글 목록이 표시된다
  5. Admin 대시보드에 조회수 상위 게시글과 회원가입 추이 통계가 표시된다
**Plans**: 3 plans

Plans:
- [ ] 02-01-PLAN.md -- rhino-editor 도입 및 폼 교체 (Trix 대체, 이미지 업로드, 버블 메뉴)
- [ ] 02-02-PLAN.md -- 작성자 프로필 강화 (Active Storage 아바타, 소셜링크, 뱃지)
- [ ] 02-03-PLAN.md -- Admin 콘텐츠 분석 대시보드 (chartkick + groupdate)

### Phase 3: Interactive Landing
**Goal**: React 인터랙티브 컴포넌트로 랜딩페이지를 완성하여 외부 방문자의 전환율을 높인다
**Depends on**: Phase 1
**Requirements**: LAND-01, LAND-02, LAND-03
**Success Criteria** (what must be TRUE):
  1. 랜딩페이지 히어로 섹션에 애니메이션이 동작하고 CTA 버튼이 반응한다
  2. Admin에서 랜딩섹션 콘텐츠를 수정하면 React 컴포넌트에 반영된다
  3. 모바일(375px)에서 랜딩페이지 전체 섹션이 깨짐 없이 표시된다
  4. Turbo 네비게이션 후 React 컴포넌트가 메모리 누수 없이 언마운트된다
**Plans**: 2 plans

Plans:
- [ ] 03-01-PLAN.md -- JSON API + React 스캐폴드 + motion 히어로 섹션 (API -> fetch -> render 수직 슬라이스)
- [ ] 03-02-PLAN.md -- 나머지 섹션 컴포넌트 + 스크롤 애니메이션 + 모바일 반응형 완성

### Phase 4: Commerce
**Goal**: 토스페이먼츠 결제 기반 구조를 완성하여 다음 마일스톤에서 실결제를 바로 활성화할 수 있는 상태를 만든다
**Depends on**: Phase 1, Phase 2
**Requirements**: COMM-01, COMM-02, COMM-03, COMM-04
**Success Criteria** (what must be TRUE):
  1. Order 모델이 payment_event_id 유니크 인덱스를 포함하여 생성되고 pending/paid/failed/refunded 상태를 추적한다
  2. 스킬팩 체크아웃 페이지에서 상품 정보와 가격이 표시되고 결제 버튼이 렌더링된다
  3. 토스페이먼츠 위젯이 테스트 모드로 초기화되어 결제 UI가 표시된다
  4. 결제 완료 후 서버사이드 confirm API가 호출되고 Order 상태가 업데이트된다
**Plans**: 3 plans

Plans:
- [ ] 04-01-PLAN.md -- Order 모델 + 결제 상태 스키마 + 체크아웃 라우트/컨트롤러 스켈레톤
- [ ] 04-02-PLAN.md -- 체크아웃 페이지 UI + 토스페이먼츠 SDK 위젯 초기화
- [ ] 04-03-PLAN.md -- 서버사이드 결제 confirm API (PaymentService + CheckoutsController#success)

### Phase 5: Polish
**Goal**: 전체 모바일 반응형과 에러 페이지를 완성하여 외부에 공개해도 부끄럽지 않은 프로덕션 완성도를 달성한다
**Depends on**: Phase 2, Phase 3
**Requirements**: UIUX-01, UIUX-02
**Success Criteria** (what must be TRUE):
  1. 네비게이션, 사이드바, 게시판 카드가 모바일(375px)에서 깨짐 없이 표시된다
  2. 커스텀 404 페이지와 500 페이지가 브랜드에 맞게 렌더링된다
**Plans**: 2 plans

Plans:
- [ ] 05-01-PLAN.md -- 전체 레이아웃 모바일 반응형 보완 (Navbar 모바일 메뉴 + Admin 사이드바 off-canvas)
- [ ] 05-02-PLAN.md -- 커스텀 404/500/422 에러 페이지 (exceptions_app + ErrorsController)

## Progress

**Execution Order:**
Phases execute in numeric order: 1 → 2 → 3 → 4 → 5
Note: Phase 3 depends only on Phase 1 (can begin in parallel with Phase 2 if desired)

| Phase | Plans Complete | Status | Completed |
|-------|----------------|--------|-----------|
| 1. Foundation | 3/3 | Complete    | 2026-02-22 |
| 2. Content Experience | 0/3 | Complete    | 2026-02-22 |
| 3. Interactive Landing | 2/2 | Complete    | 2026-02-22 |
| 4. Commerce | 3/3 | Complete    | 2026-02-22 |
| 5. Polish | 2/2 | Complete   | 2026-02-22 |
