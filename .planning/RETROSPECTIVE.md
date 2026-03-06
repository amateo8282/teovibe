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

## Cross-Milestone Trends

### Process Evolution

| Milestone | Phases | Plans | Key Change |
|-----------|--------|-------|------------|
| v1.0 | 5 | 13 | 초기 구축, ImportMap→Vite 전환 |
| v1.1 | 3 | 9 | GSD 워크플로우 도입, audit-milestone로 통합 검증 |

### Cumulative Quality

| Milestone | Tests Added | Key Coverage |
|-----------|------------|--------------|
| v1.0 | 기존 테스트 | 기본 CRUD |
| v1.1 | 45+ | 모델 13 + 컨트롤러 14 + 통합 11 + AI 7 |

### Top Lessons (Verified Across Milestones)

1. 빌드 시스템 전환 시 레거시 파일 즉시 정리 (v1.0 ImportMap→Vite, v1.1 sortable 사건)
2. 1인 운영이라도 자동 테스트 커버리지가 리팩토링 안전망 역할 (PostsController 6→1 통합)
