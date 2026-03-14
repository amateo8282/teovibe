# Milestones

## v1.2 SEO + Admin UX (Shipped: 2026-03-14)

**Phases completed:** 5 phases, 7 plans, 10 tasks
**Timeline:** 2026-03-14 (single day)

**Key accomplishments:**
- JSON-LD XSS 보안 패치 — safe_json_ld 래퍼로 seo_helper.rb 전체 헬퍼 안전화 (SEC-01)
- 동적 robots.txt 컨트롤러 + sitemap 카테고리 동적화 — Googlebot/Yeti 크롤링 기반 확보 (CRAWL-01~03)
- Google Search Console / Naver 서치어드바이저 소유권 인증 메타태그 삽입 (SRCH-01~02)
- OG/Twitter Card/canonical 메타태그 + Admin/인증 페이지 noindex 처리 (SOCL-01~03, INDX-01~03)
- Article/BreadcrumbList/WebSite/Organization JSON-LD 구조화 데이터 렌더링 (STRD-01~03)
- Admin 게시글 에디터 2단 레이아웃 — sticky 메타 패널 + 모바일 1단 fallback (ADMN-01~03)

**Tech debt carried forward:**
- Post slug constraint 불일치 (영문자 시작 slug 미매칭) — tech debt from v1.1
- ANTHROPIC_API_KEY 프로덕션 환경변수 등록 필요 — tech debt from v1.1
- SRCH-01/SRCH-02: credentials에 실제 인증 토큰 설정 후 외부 서비스 대시보드 확인 필요

**Archive:** `.planning/milestones/v1.2-ROADMAP.md`, `.planning/milestones/v1.2-REQUIREMENTS.md`

---

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
