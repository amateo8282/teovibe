# Milestones

## v1.0 MVP (Shipped: 2026-02-22)

**Phases completed:** 5 phases, 13 plans, 26 feat commits
**Files modified:** 112 (10,515 insertions, 182 deletions)
**Lines of code:** 17,092 (Ruby/ERB/JS/JSX/TS/TSX/CSS)
**Timeline:** 2026-02-22 (single day)

**Key accomplishments:**
- ImportMap에서 vite_ruby로 빌드 파이프라인 전환 + SQLite Solid 인프라 분리 + ViewComponent/React 마운트 기반
- rhino-editor 도입으로 ActionText 호환 리치 에디터 완성 + 프로필 강화 (아바타/소셜/뱃지) + Admin 차트 대시보드
- React + motion 인터랙티브 랜딩페이지 (히어로 애니메이션, 5개 섹션, Admin JSON API 연동)
- 토스페이먼츠 결제 기반 구조 완성 (Order 모델 + 체크아웃 UI + SDK 위젯 + 서버사이드 confirm)
- 모바일 반응형 보완 (Navbar/Admin off-canvas) + 브랜드 커스텀 에러 페이지 (404/500/422)

**Archive:** `.planning/milestones/v1.0-ROADMAP.md`, `.planning/milestones/v1.0-REQUIREMENTS.md`

---

## v1.1 Admin 고도화 (Shipped: 2026-03-06)

**Phases completed:** 3 phases, 9 plans, 27 commits
**Lines of code:** 20,615 (Ruby/ERB/JS/JSX/TS/TSX/CSS)
**Timeline:** 7일 (2026-02-28 → 2026-03-06)

**Key accomplishments:**
- Category 모델 전환 (enum → FK) + Admin CRUD/DnD/토글 UI 완성 (CATM-01~06)
- PostsController 통합 + 301 SEO 리다이렉트 + 동적 Navbar/Footer
- 게시글 예약 발행: datetime-local KST→UTC 변환, PublishPostJob, SolidQueue 연동 (SCHD-01~03)
- AI 초안 작성: Anthropic API 기반 개요→본문 2단계 생성, rhino-editor 자동 삽입, SEO/AEO 프롬프트 (AIDR-01~04)
- 테스트 커버리지: 모델 13개 + 컨트롤러 14개 + 통합 11개 + AI 서비스/컨트롤러 7개

**Known gaps (resolved during audit):**
- sortable_controller.js 레거시 디렉토리 위치 → Vite 디렉토리로 이동 완료
- 레거시 app/javascript/ 디렉토리 삭제 (13파일)

**Tech debt carried forward:**
- Post slug constraint 불일치 (영문자 시작 slug 미매칭, category_routing_test 1개 실패)
- ANTHROPIC_API_KEY 환경변수 프로덕션 등록 필요

**Archive:** `.planning/milestones/v1.1-ROADMAP.md`, `.planning/milestones/v1.1-REQUIREMENTS.md`

---
