# Project Retrospective

*A living document updated after each milestone. Lessons feed forward into future planning.*

## Milestone: v1.1 — Admin 고도화

**Shipped:** 2026-03-06
**Phases:** 3 | **Plans:** 9

### What Was Built
- 게시판/스킬팩 카테고리 동적 CRUD + DnD 순서 변경 + admin_only/visible_in_nav 토글
- PostsController 통합 (6개 컨트롤러 삭제) + 301 SEO 리다이렉트 + 동적 Navbar/Footer
- 게시글 예약 발행 (KST datetime-local → UTC 변환, PublishPostJob + SolidQueue)
- AI 초안 작성 (Anthropic API 기반 개요→본문 2단계, rhino-editor 자동 삽입, SEO/AEO 시스템 프롬프트)

### What Worked
- TDD 사이클이 Phase 7-8에서 특히 효과적 — PublishPostJob과 AiDraftService의 edge case를 사전에 잡음
- Phase별 VERIFICATION.md가 마일스톤 감사(audit) 시 즉시 활용 가능
- enum → FK 마이그레이션에서 slug 기반 SQL 매핑이 auto-increment ID 의존 없이 안전하게 동작

### What Was Inefficient
- sortable_controller.js가 레거시 디렉토리(app/javascript/)에 배치되어 마일스톤 감사에서 발견 — Phase 6 실행 시 Vite 구조를 더 꼼꼼히 확인했어야 함
- 레거시 app/javascript/ 디렉토리가 v1.0 이후 정리되지 않고 남아있었음 — 마이그레이션 완료 후 즉시 정리 필요
- Phase 6 VERIFICATION이 human_needed 상태였으나 DnD가 실제로는 미동작 — 브라우저 검증 누락

### Patterns Established
- Stimulus 컨트롤러는 반드시 app/frontend/controllers/에 배치 (Vite glob 자동 등록)
- Post 상태 확장 시 enum 추가 대신 별도 컬럼 사용 (scheduled_at 패턴)
- minitest에서 외부 API 스텁: define_singleton_method 패턴
- Admin 폼에 인터랙티브 패널 추가 시: Stimulus controller + data-*-url-value Rails helper 조합

### Key Lessons
1. Vite 전환 후 레거시 디렉토리는 즉시 삭제해야 한다 — 남겨두면 새 파일이 잘못된 위치에 추가됨
2. DnD/Turbo Stream 등 브라우저 인터랙션은 자동 테스트만으로 불충분 — human verification이 실제로 수행되었는지 확인 필요
3. 마일스톤 완료 전 audit-milestone 실행이 cross-phase 통합 문제를 발견하는 데 효과적

---

## Milestone: v1.3 — Admin 에디터 고도화

**Shipped:** 2026-03-15
**Phases:** 5 | **Plans:** 5

### What Was Built
- ActionText 허용목록 + AdminRhinoEditor 서브클래스 (TipTapEditor 상속, 커스텀 엘리먼트 등록)
- 취소선/밑줄/인용구/구분선/코드블록/제목 드롭다운 툴바 확장
- 텍스트 정렬(좌/중/우)/글자색/배경색/폰트 크기 스타일링 UI
- Table extension 4종 + Light DOM 컨텍스트 메뉴 (행/열 추가/삭제)
- 빈 단락 플로팅 메뉴 (+버튼) — 구분선/인용구/코드블록/표 빠른 삽입

### What Worked
- AdminRhinoEditor 서브클래스 패턴이 모든 후속 phase의 확장 포인트로 효과적 — 1개 파일에 누적 구현
- renderToolbarEnd() override 패턴이 기존 rhino-editor 기본 버튼(Strike/Blockquote/CodeBlock)을 자연스럽게 보존
- Phase 14에서 ActionText 허용목록을 선행 설정해 Phase 15-18에서 저장/렌더링 이슈 없음
- Light DOM 메뉴 패턴(Phase 17)이 Phase 18 플로팅 메뉴에 그대로 재활용됨

### What Was Inefficient
- 전체 5개 phase를 하루 만에 실행 — VERIFICATION.md가 모두 human_needed 상태로 브라우저 검증 일괄 보류
- SUMMARY.md frontmatter에 one_liner 필드가 누락되어 자동 추출 실패 — 수동으로 accomplishments 작성 필요
- Nyquist VALIDATION.md가 Phase 14만 compliant, 나머지 4개 phase는 draft — 빠른 실행에 검증 전략이 뒤처짐

### Patterns Established
- Light DOM 메뉴 패턴: Shadow DOM 경계 밖에 position:absolute 요소 배치 — rhino-editor 에디터 확장 시 표준 패턴
- startEditor() override 패턴: connectedCallback 시점에는 this.editor가 null이므로 editor 이벤트 리스너는 startEditor()에서 등록
- pnpm transitive dep 직접 설치: lit, @tiptap/core 등 Vite 빌드 시 transitive dep 해석 오류 방지를 위해 직접 추가
- Extension.create()로 커스텀 extension 로컬 구현: v3 전용 패키지 대신 30줄로 동일 기능

### Key Lessons
1. ActionText 허용목록은 에디터 확장의 최우선 선행 작업 — 미설정 시 style/table 태그가 무음 삭제됨
2. rhino-editor의 Shadow DOM 경계가 TipTap 공식 플러그인(@tiptap/extension-floating-menu 등)과 충돌 — 네이티브 JS 직접 구현이 더 안정적
3. Table resizable:true는 rhino-editor 포인터 이벤트와 충돌 — resizable:false 필수
4. TipTap v2/v3 패키지 혼용 금지 — @tiptap/extension-font-size 등 v3 전용 패키지 주의

### Cost Observations
- 5 phases를 단일 세션에서 실행 — 고속 출시에 적합하나 검증 부채 누적
- 코드 레벨 검증은 모두 통과, 브라우저 검증은 사용자가 일괄 승인

---

## Cross-Milestone Trends

### Process Evolution

| Milestone | Phases | Plans | Key Change |
|-----------|--------|-------|------------|
| v1.0 | 5 | 13 | 초기 구축, ImportMap→Vite 전환 |
| v1.1 | 3 | 9 | GSD 워크플로우 도입, audit-milestone로 통합 검증 |
| v1.2 | 5 | 7 | SEO 최적화, JSON-LD/메타태그/크롤링 기반 |
| v1.3 | 5 | 5 | Admin 에디터 고도화, TipTap extension 확장 |

### Cumulative Quality

| Milestone | Tests Added | Key Coverage |
|-----------|------------|--------------|
| v1.0 | 기존 테스트 | 기본 CRUD |
| v1.1 | 45+ | 모델 13 + 컨트롤러 14 + 통합 11 + AI 7 |
| v1.2 | 보안/SEO | XSS 패치, 메타태그 검증 |
| v1.3 | 코드 검증 | TipTap extension 정적 분석, 브라우저 검증 일괄 |

### Top Lessons (Verified Across Milestones)

1. 빌드 시스템 전환 시 레거시 파일 즉시 정리 (v1.0 ImportMap→Vite, v1.1 sortable 사건)
2. 1인 운영이라도 자동 테스트 커버리지가 리팩토링 안전망 역할 (PostsController 6→1 통합)
3. 에디터 확장 시 허용목록(sanitizer)을 최우선 선행 작업으로 처리 (v1.3 Phase 14 패턴)
4. Shadow DOM 경계가 있는 Web Component에서는 공식 플러그인보다 네이티브 JS가 안정적 (v1.3 Light DOM 메뉴 패턴)
