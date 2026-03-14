# Requirements: TeoVibe v1.3

**Defined:** 2026-03-14
**Core Value:** 사용자가 재방문하고 싶은 수준의 콘텐츠 품질과 UX를 갖춘 커뮤니티 플랫폼

## v1.3 Requirements

Admin 에디터를 네이버 블로그 수준으로 고도화. rhino-editor(TipTap 2.27.2) 기반 extension 확장.

### 기반 설정

- [x] **INFRA-01**: ActionText initializer에 style 속성 + table 태그 허용 설정
- [x] **INFRA-02**: AdminRhinoEditor 서브클래스 스캐폴드 (커스텀 엘리먼트 등록, Admin 폼 적용)
- [x] **INFRA-03**: ai_draft_controller.js의 editor selector를 AdminRhinoEditor로 변경

### 서식 확장

- [x] **MARK-01**: 취소선(Strike) 툴바 버튼 추가 (이미 등록된 extension 활용)
- [x] **MARK-02**: 밑줄(Underline) extension 설치 + 툴바 버튼
- [x] **MARK-03**: 인용구(Blockquote) 툴바 버튼 추가
- [x] **MARK-04**: 구분선(Horizontal Rule) 툴바 버튼 추가
- [x] **MARK-05**: 소스코드 블록(Code Block) 툴바 버튼 추가
- [x] **MARK-06**: 제목 레벨 드롭다운 (H1~H3 선택)

### 텍스트 스타일

- [x] **STYL-01**: 텍스트 정렬 (좌/중/우) extension + 툴바 버튼
- [x] **STYL-02**: 글자색(Color) extension + 색상 선택 UI
- [x] **STYL-03**: 배경색(Highlight) extension + 색상 선택 UI
- [x] **STYL-04**: 폰트 크기 조절 커스텀 extension + 드롭다운 UI

### 표

- [x] **TABL-01**: Table extension 설치 (table/row/cell/header 4개 패키지)
- [x] **TABL-02**: 표 삽입 버튼 + 행/열 추가/삭제 컨텍스트 메뉴

### 블록 삽입

- [ ] **BLCK-01**: FloatingMenu 기반 + 블록 삽입 버튼 (구분선/인용구/코드블록/표 빠른 삽입)

## Future Requirements

- 동영상 임베드 (YouTube URL 붙여넣기)
- 파일 첨부 (Active Storage 확장)
- 슬래시 커맨드 (/ 입력으로 블록 삽입)
- 일반 사용자 에디터 확대 적용

## Out of Scope

| Feature | Reason |
|---------|--------|
| 동영상 임베드 | Active Storage 인프라 확장 필요, 현재 마일스톤 범위 초과 |
| 파일 첨부 | 별도 인프라 필요 |
| TipTap v3 업그레이드 | rhino-editor 0.17.x가 v2 기반, 호환성 깨짐 |
| 일반 사용자 에디터 적용 | Admin 전용 우선, 추후 확대 |
| 슬래시 커맨드 | TipTap 공식 미지원(experimental), FloatingMenu로 대체 |

## Traceability

| Requirement | Phase | Status |
|-------------|-------|--------|
| INFRA-01 | Phase 14 | Complete |
| INFRA-02 | Phase 14 | Complete |
| INFRA-03 | Phase 14 | Complete |
| MARK-01 | Phase 15 | Complete |
| MARK-02 | Phase 15 | Complete |
| MARK-03 | Phase 15 | Complete |
| MARK-04 | Phase 15 | Complete |
| MARK-05 | Phase 15 | Complete |
| MARK-06 | Phase 15 | Complete |
| STYL-01 | Phase 16 | Complete |
| STYL-02 | Phase 16 | Complete |
| STYL-03 | Phase 16 | Complete |
| STYL-04 | Phase 16 | Complete |
| TABL-01 | Phase 17 | Complete |
| TABL-02 | Phase 17 | Complete |
| BLCK-01 | Phase 18 | Pending |

**Coverage:**
- v1.3 requirements: 16 total
- Mapped to phases: 16
- Unmapped: 0

---
*Requirements defined: 2026-03-14*
*Last updated: 2026-03-14 after roadmap creation (all 16 requirements mapped)*
