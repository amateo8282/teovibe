# Requirements: TeoVibe

**Defined:** 2026-02-22
**Core Value:** 사용자가 재방문하고 싶은 수준의 콘텐츠 품질과 UX를 갖춘 커뮤니티 플랫폼

## v1 Requirements

Requirements for this milestone. Each maps to roadmap phases.

### Infrastructure

- [x] **INFRA-01**: ImportMap에서 vite_ruby로 JavaScript 빌드 파이프라인을 전환하여 JSX/React/npm 패키지를 사용할 수 있다
- [x] **INFRA-02**: SQLite WAL 모드를 활성화하고 Solid Queue/Cache/Cable이 별도 DB 파일을 사용하도록 구성한다
- [x] **INFRA-03**: ViewComponent gem을 도입하여 재사용 가능한 UI 컴포넌트 구조를 마련한다

### Editor

- [ ] **EDIT-01**: rhino-editor(TipTap 기반)를 도입하여 기존 ActionText/Trix를 대체하며 기존 콘텐츠와 호환을 유지한다
- [ ] **EDIT-02**: 에디터에서 이미지를 드래그&드롭으로 업로드하고 크기 조절할 수 있다
- [ ] **EDIT-03**: 에디터에 버블 메뉴(선택 텍스트 서식)와 플로팅 툴바를 제공한다

### Landing Page

- [ ] **LAND-01**: React 컴포넌트로 인터랙티브 랜딩페이지를 구현한다 (애니메이션 히어로, CTA, 소셜프루프 섹션)
- [ ] **LAND-02**: Admin에서 랜딩페이지 섹션 콘텐츠를 관리하면 React 컴포넌트에 반영된다
- [ ] **LAND-03**: 랜딩페이지가 모바일에서도 매끄럽게 동작한다 (반응형)

### Commerce

- [ ] **COMM-01**: Order 모델과 결제 상태 관리 스키마를 구축한다 (pending/paid/failed/refunded)
- [ ] **COMM-02**: 스킬팩 체크아웃 페이지 UI를 구현한다 (상품 정보, 가격, 결제 버튼)
- [ ] **COMM-03**: 토스페이먼츠 SDK 초기화와 결제 위젯 연동 기반을 마련한다
- [ ] **COMM-04**: 서버사이드 결제 확인(confirm) API 엔드포인트를 구현한다

### Profile & Content

- [ ] **PROF-01**: 작성자 프로필 페이지에 아바타, 바이오, 소셜링크, 작성 글 목록을 표시한다
- [ ] **PROF-02**: 프로필에 포인트, 레벨, 뱃지를 시각적으로 표시한다 (게이미피케이션)

### UI/UX

- [ ] **UIUX-01**: 전체 레이아웃의 모바일 반응형을 보완한다 (네비게이션, 사이드바, 카드 레이아웃)
- [ ] **UIUX-02**: 커스텀 404/500 에러 페이지를 제공한다

### Admin

- [ ] **ADMN-01**: Admin 대시보드에 기본 콘텐츠 분석을 표시한다 (조회수 상위 게시글, 좋아요 통계, 회원가입 추이)

## v2 Requirements

Deferred to future release. Tracked but not in current roadmap.

### Editor Enhancement

- **EDIT-04**: 슬래시 커맨드로 블록 삽입 (코드블록, 인용, 구분선 등)

### Content Discovery

- **DISC-01**: 글 하단에 관련/최신 글 추천 섹션
- **DISC-02**: 태그 기반 콘텐츠 분류 및 필터링

### Notifications

- **NOTF-01**: 이메일 알림 발송 (댓글, 좋아요 등)
- **NOTF-02**: 알림 이메일 수신 설정 (opt-out)

### Commerce Advanced

- **COMM-05**: 토스페이먼츠 웹훅 처리 (결제 완료/취소 비동기 확인)
- **COMM-06**: 스킬팩 미리보기 콘텐츠 제공

### Analytics

- **ADMN-02**: Admin 콘텐츠 분석 고도화 (차트, 기간별 필터, 내보내기)

## Out of Scope

| Feature | Reason |
|---------|--------|
| 실시간 채팅/DM | 1인 운영에 과도한 운영 부담, 기존 댓글로 충분 |
| 모바일 앱 | 반응형 웹으로 대응, 비용 대비 효과 낮음 |
| PostgreSQL 마이그레이션 | 현재 규모에 SQLite 충분, 리스크 대비 이점 없음 |
| 별도 SPA 분리 | Rails 내 React로 충분, 유지보수 복잡도 증가 |
| AI 콘텐츠 생성 | API 비용, 품질 관리 리스크 |
| 사용자 마켓플레이스 | 정산/분쟁/세금 등 완전히 다른 제품 |
| 협업 편집 (Y.js) | 1인 저자 플랫폼에 불필요한 복잡도 |
| 알고리즘 피드 | 현재 트래픽에서 과도한 엔지니어링 |

## Traceability

Which phases cover which requirements. Updated during roadmap creation.

| Requirement | Phase | Status |
|-------------|-------|--------|
| INFRA-01 | Phase 1 | Complete |
| INFRA-02 | Phase 1 | Complete |
| INFRA-03 | Phase 1 | Complete |
| EDIT-01 | Phase 2 | Pending |
| EDIT-02 | Phase 2 | Pending |
| EDIT-03 | Phase 2 | Pending |
| LAND-01 | Phase 3 | Pending |
| LAND-02 | Phase 3 | Pending |
| LAND-03 | Phase 3 | Pending |
| COMM-01 | Phase 4 | Pending |
| COMM-02 | Phase 4 | Pending |
| COMM-03 | Phase 4 | Pending |
| COMM-04 | Phase 4 | Pending |
| PROF-01 | Phase 2 | Pending |
| PROF-02 | Phase 2 | Pending |
| UIUX-01 | Phase 5 | Pending |
| UIUX-02 | Phase 5 | Pending |
| ADMN-01 | Phase 2 | Pending |

**Coverage:**
- v1 requirements: 18 total
- Mapped to phases: 18
- Unmapped: 0

---
*Requirements defined: 2026-02-22*
*Last updated: 2026-02-22 after roadmap creation — traceability complete*
