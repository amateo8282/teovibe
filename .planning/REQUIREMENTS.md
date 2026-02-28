# Requirements: TeoVibe

**Defined:** 2026-02-28
**Core Value:** 사용자가 재방문하고 싶은 수준의 콘텐츠 품질과 UX를 갖춘 커뮤니티 플랫폼

## v1.1 Requirements

Requirements for v1.1 Admin 고도화. Each maps to roadmap phases.

### 카테고리 관리

- [ ] **CATM-01**: Admin이 게시판 카테고리를 생성할 수 있다 (이름, 슬러그, 설명)
- [ ] **CATM-02**: Admin이 게시판 카테고리를 수정/삭제할 수 있다
- [ ] **CATM-03**: Admin이 게시판 카테고리 순서를 드래그앤드롭으로 변경할 수 있다
- [ ] **CATM-04**: Admin이 카테고리별 '관리자 전용 작성' 토글을 설정할 수 있다
- [ ] **CATM-05**: 관리자 전용 카테고리는 일반 사용자 게시글 작성 시 선택지에서 숨겨진다
- [ ] **CATM-06**: Admin이 스킬팩 카테고리를 CRUD + 순서 변경할 수 있다

### AI 초안 작성

- [ ] **AIDR-01**: Admin이 주제/키워드를 입력하면 AI가 개요(H2 섹션 목록)를 생성한다
- [ ] **AIDR-02**: Admin이 생성된 개요를 검토/수정한 후 본문 생성을 요청할 수 있다
- [ ] **AIDR-03**: 생성된 본문이 rhino-editor에 자동 삽입된다
- [ ] **AIDR-04**: AI 생성 시 SEO/AEO 최적화 시스템 프롬프트가 적용된다

### 예약 발행

- [ ] **SCHD-01**: Admin이 게시글 저장 시 발행 날짜/시간을 지정할 수 있다
- [ ] **SCHD-02**: 지정된 시간에 게시글이 자동으로 published 상태로 전환된다
- [ ] **SCHD-03**: Admin이 예약된 게시글의 예약을 취소하거나 시간을 변경할 수 있다

## Future Requirements

Deferred to future release. Tracked but not in current roadmap.

### AI 초안 확장

- **AIDR-05**: 본문 생성 시 스트리밍으로 실시간 타이핑 효과를 보여준다
- **AIDR-06**: AI 초안 톤/스타일 선택 (전문적/친근한/SEO 집중)

### 콘텐츠 확장

- **CONT-01**: 슬래시 커맨드로 블록 삽입 (코드블록, 인용, 구분선 등)
- **CONT-02**: 글 하단 관련/최신 글 추천 섹션
- **CONT-03**: 태그 기반 콘텐츠 분류 및 필터링

### 알림/결제

- **NOTF-01**: 이메일 알림 발송 (댓글, 좋아요 등)
- **PYMT-01**: 토스페이먼츠 웹훅 처리 (결제 완료/취소 비동기 확인)
- **SKLP-01**: 스킬팩 미리보기 콘텐츠 제공

## Out of Scope

Explicitly excluded. Documented to prevent scope creep.

| Feature | Reason |
|---------|--------|
| AI 자동 발행 (사람 검토 없이) | 품질 보증 불가, 브랜드 리스크 |
| 반복 발행 스케줄 (cron 패턴) | 콘텐츠마다 내용이 달라 자동화 무의미 |
| 카테고리 계층 구조 (중첩) | 현재 평면 구조에 과도한 복잡도 |
| 사용자별 카테고리 구독/필터링 | Admin 운영 효율화에 집중, 사용자 기능은 별도 마일스톤 |
| Google Indexing API 자동 제출 | 대량 AI 콘텐츠 자동 제출은 스팸 정책 위반 가능 |

## Traceability

Which phases cover which requirements. Updated during roadmap creation.

| Requirement | Phase | Status |
|-------------|-------|--------|
| CATM-01 | Phase 6 | Pending |
| CATM-02 | Phase 6 | Pending |
| CATM-03 | Phase 6 | Pending |
| CATM-04 | Phase 6 | Pending |
| CATM-05 | Phase 6 | Pending |
| CATM-06 | Phase 6 | Pending |
| AIDR-01 | Phase 8 | Pending |
| AIDR-02 | Phase 8 | Pending |
| AIDR-03 | Phase 8 | Pending |
| AIDR-04 | Phase 8 | Pending |
| SCHD-01 | Phase 7 | Pending |
| SCHD-02 | Phase 7 | Pending |
| SCHD-03 | Phase 7 | Pending |

**Coverage:**
- v1.1 requirements: 13 total
- Mapped to phases: 13
- Unmapped: 0

---
*Requirements defined: 2026-02-28*
*Last updated: 2026-02-28 after roadmap creation — all 13 requirements mapped*
