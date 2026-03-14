# Roadmap: TeoVibe

## Milestones

- v1.0 MVP - Phases 1-5 (shipped 2026-02-22)
- v1.1 Admin 고도화 - Phases 6-8 (shipped 2026-03-06)
- v1.2 SEO + Admin UX - Phases 9-13 (shipped 2026-03-14)
- v1.3 Admin 에디터 고도화 - Phases 14-18 (active)

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

<details>
<summary>v1.1 Admin 고도화 (Phases 6-8) - SHIPPED 2026-03-06</summary>

- [x] Phase 6: 카테고리 동적 관리 (4/4 plans) — completed 2026-02-28
- [x] Phase 7: 게시글 예약 발행 (3/3 plans) — completed 2026-03-04
- [x] Phase 8: AI 초안 작성 (2/2 plans) — completed 2026-03-06

</details>

<details>
<summary>v1.2 SEO + Admin UX (Phases 9-13) - SHIPPED 2026-03-14</summary>

- [x] Phase 9: XSS 보안 패치 (1/1 plans) — completed 2026-03-13
- [x] Phase 10: 크롤링 기초 (2/2 plans) — completed 2026-03-13
- [x] Phase 11: 소셜/색인 메타태그 (2/2 plans) — completed 2026-03-13
- [x] Phase 12: 구조화 데이터 (1/1 plans) — completed 2026-03-13
- [x] Phase 13: Admin 에디터 UX (1/1 plans) — completed 2026-03-14

</details>

### v1.3 Admin 에디터 고도화 (Phases 14-18)

- [x] **Phase 14: 에디터 기반 설정** — ActionText 허용목록 + AdminRhinoEditor 서브클래스 스캐폴드 (completed 2026-03-14)
- [x] **Phase 15: 툴바 서식 확장** — 취소선/밑줄/인용구/구분선/코드블록/제목 드롭다운 (패키지 설치 없음) (completed 2026-03-14)
- [ ] **Phase 16: 텍스트 스타일링** — 정렬/글자색/배경색/폰트 크기 통합 구현
- [ ] **Phase 17: 표 삽입** — Table extension 4개 패키지 + 행/열 편집 컨텍스트 메뉴
- [ ] **Phase 18: 블록 삽입 메뉴** — FloatingMenu 기반 + 버튼 빠른 삽입

## Phase Details

### Phase 14: 에디터 기반 설정
**Goal**: ActionText HTML 허용목록과 AdminRhinoEditor 서브클래스가 준비되어 모든 후속 에디터 작업의 토대가 갖춰진다
**Depends on**: Phase 13 (v1.2 완료)
**Requirements**: INFRA-01, INFRA-02, INFRA-03
**Success Criteria** (what must be TRUE):
  1. Admin 게시글 폼에 `<admin-rhino-editor>` 커스텀 엘리먼트가 렌더링되고 기존 rhino-editor와 동일하게 동작한다
  2. AI 초안 작성 버튼이 AdminRhinoEditor를 정상적으로 감지하고 초안을 삽입한다
  3. style 속성이 포함된 콘텐츠를 저장 후 게시글 상세 페이지에서 로드해도 style이 유지된다
  4. table/tr/td/th 태그가 포함된 콘텐츠를 저장 후 게시글 상세 페이지에서 로드해도 표 구조가 유지된다
**Plans**: 1 plan

Plans:
- [ ] 14-01-PLAN.md — ActionText 허용목록 + AdminRhinoEditor 스캐폴드 + AI selector 수정

### Phase 15: 툴바 서식 확장
**Goal**: 취소선, 밑줄, 인용구, 구분선, 코드블록, 제목 드롭다운이 Admin 에디터 툴바에 추가되어 작성자가 풍부한 서식을 적용할 수 있다
**Depends on**: Phase 14
**Requirements**: MARK-01, MARK-02, MARK-03, MARK-04, MARK-05, MARK-06
**Success Criteria** (what must be TRUE):
  1. 툴바에서 취소선/밑줄/인용구/구분선/코드블록 버튼을 클릭하면 선택 텍스트에 해당 서식이 즉시 적용된다
  2. 제목 드롭다운에서 H1/H2/H3을 선택하면 커서가 위치한 블록이 해당 제목 레벨로 변환된다
  3. 위 서식이 적용된 게시글을 저장하고 상세 페이지에서 조회하면 서식이 그대로 렌더링된다
  4. 새 npm 패키지 없이 기존 RhinoStarterKit 등록 extension만으로 모든 버튼이 동작한다
**Plans**: 1 plan

Plans:
- [ ] 15-01-PLAN.md — Underline extension + renderToolbarEnd 오버라이드 + ActionText u 태그 허용 + 서식 검증

### Phase 16: 텍스트 스타일링
**Goal**: 텍스트 정렬(좌/중/우), 글자색, 배경 하이라이트, 폰트 크기를 Admin 에디터에서 조절할 수 있다
**Depends on**: Phase 14
**Requirements**: STYL-01, STYL-02, STYL-03, STYL-04
**Success Criteria** (what must be TRUE):
  1. 정렬 버튼(좌/중/우) 클릭 시 해당 단락의 텍스트 정렬이 에디터와 저장 후 상세 페이지 모두에서 적용된다
  2. 색상 팔레트에서 색상을 선택하면 선택 텍스트의 글자색 또는 배경색이 즉시 변경되고 저장 후에도 유지된다
  3. 폰트 크기 드롭다운에서 크기를 선택하면 선택 텍스트의 크기가 변경되고 저장 후에도 유지된다
  4. @tiptap/extension-font-size npm 패키지를 사용하지 않고 로컬 커스텀 extension으로 구현된다
**Plans**: 1 plan

Plans:
- [ ] 14-01-PLAN.md — ActionText 허용목록 + AdminRhinoEditor 스캐폴드 + AI selector 수정

### Phase 17: 표 삽입
**Goal**: Admin 에디터에서 표를 삽입하고 행/열을 추가 및 삭제할 수 있다
**Depends on**: Phase 14
**Requirements**: TABL-01, TABL-02
**Success Criteria** (what must be TRUE):
  1. 툴바 버튼으로 표를 삽입할 수 있고 표 안에서 탭 키로 셀 간 이동이 된다
  2. 표 셀 내 컨텍스트 메뉴(버블 메뉴)에서 행/열 추가 및 삭제가 동작한다
  3. 저장 후 게시글 상세 페이지에서 표 구조와 내용이 올바르게 렌더링된다
  4. 기존 텍스트 선택 버블 메뉴와 표 버블 메뉴가 충돌 없이 각자 적절한 상황에서만 표시된다
**Plans**: 1 plan

Plans:
- [ ] 14-01-PLAN.md — ActionText 허용목록 + AdminRhinoEditor 스캐폴드 + AI selector 수정

### Phase 18: 블록 삽입 메뉴
**Goal**: 빈 줄에서 + 버튼이 나타나 구분선/인용구/코드블록/표를 빠르게 삽입할 수 있다
**Depends on**: Phase 15, Phase 17
**Requirements**: BLCK-01
**Success Criteria** (what must be TRUE):
  1. 빈 단락에 커서를 놓으면 + 플로팅 버튼이 나타난다
  2. + 버튼 클릭 시 구분선/인용구/코드블록/표 삽입 옵션이 표시되고 선택 시 즉시 삽입된다
  3. 텍스트가 있는 줄에서는 + 버튼이 나타나지 않는다
**Plans**: 1 plan

Plans:
- [ ] 14-01-PLAN.md — ActionText 허용목록 + AdminRhinoEditor 스캐폴드 + AI selector 수정

## Progress

| Phase | Milestone | Plans Complete | Status | Completed |
|-------|-----------|----------------|--------|-----------|
| 1. Foundation | v1.0 | 3/3 | Complete | 2026-02-22 |
| 2. Content Experience | v1.0 | 3/3 | Complete | 2026-02-22 |
| 3. Interactive Landing | v1.0 | 2/2 | Complete | 2026-02-22 |
| 4. Commerce | v1.0 | 3/3 | Complete | 2026-02-22 |
| 5. Polish | v1.0 | 2/2 | Complete | 2026-02-22 |
| 6. 카테고리 동적 관리 | v1.1 | 4/4 | Complete | 2026-02-28 |
| 7. 게시글 예약 발행 | v1.1 | 3/3 | Complete | 2026-03-04 |
| 8. AI 초안 작성 | v1.1 | 2/2 | Complete | 2026-03-06 |
| 9. XSS 보안 패치 | v1.2 | 1/1 | Complete | 2026-03-13 |
| 10. 크롤링 기초 | v1.2 | 2/2 | Complete | 2026-03-13 |
| 11. 소셜/색인 메타태그 | v1.2 | 2/2 | Complete | 2026-03-13 |
| 12. 구조화 데이터 | v1.2 | 1/1 | Complete | 2026-03-13 |
| 13. Admin 에디터 UX | v1.2 | 1/1 | Complete | 2026-03-14 |
| 14. 에디터 기반 설정 | 1/1 | Complete    | 2026-03-14 | - |
| 15. 툴바 서식 확장 | 1/1 | Complete   | 2026-03-14 | - |
| 16. 텍스트 스타일링 | v1.3 | 0/? | Not started | - |
| 17. 표 삽입 | v1.3 | 0/? | Not started | - |
| 18. 블록 삽입 메뉴 | v1.3 | 0/? | Not started | - |
