# Roadmap: TeoVibe

## Milestones

- v1.0 MVP - Phases 1-5 (shipped 2026-02-22)
- v1.1 Admin 고도화 - Phases 6-8 (shipped 2026-03-06)
- v1.2 SEO + Admin UX - Phases 9-13 (active)

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

## v1.2 SEO + Admin UX

- [x] **Phase 9: XSS 보안 패치** — JSON-LD 헬퍼 안전한 직렬화로 교체 (completed 2026-03-13)
- [x] **Phase 10: 크롤링 기초** — robots.txt 보강 + sitemap 동적화 + 검색엔진 인증 메타태그 (completed 2026-03-13)
- [x] **Phase 11: 소셜/색인 메타태그** — Open Graph, Twitter Card, canonical URL, noindex 처리 (completed 2026-03-13)
- [ ] **Phase 12: 구조화 데이터** — Article/BreadcrumbList/WebSite/Organization JSON-LD 렌더링
- [ ] **Phase 13: Admin 에디터 UX** — 게시글 에디터 2단 레이아웃

## Phase Details

### Phase 9: XSS 보안 패치
**Goal**: JSON-LD를 안전하게 출력할 수 있는 기반 확보
**Depends on**: Nothing (prerequisite for Phase 12)
**Requirements**: SEC-01
**Success Criteria** (what must be TRUE):
  1. 게시글 제목/본문에 `<script>` 태그를 포함해도 JSON-LD 출력에서 이스케이프 처리되어 브라우저가 실행하지 않는다
  2. Brakeman 정적 분석에서 `seo_helper.rb` 관련 경고가 0건이다
  3. JSON-LD 메타태그가 유효한 JSON으로 파싱된다 (Google Rich Results 테스트 통과 가능 형태)
**Plans**: 1 plan

Plans:
- [x] 09-01-PLAN.md — safe_json_ld XSS 패치 + 테스트

### Phase 10: 크롤링 기초
**Goal**: Googlebot과 Yeti(네이버봇)이 사이트를 올바르게 수집하고, 양대 검색엔진에서 소유권이 인증된 상태
**Depends on**: Phase 9
**Requirements**: CRAWL-01, CRAWL-02, CRAWL-03, SRCH-01, SRCH-02
**Success Criteria** (what must be TRUE):
  1. `GET /robots.txt` 응답에 Googlebot과 Yeti 명시 허용 규칙 및 sitemap.xml 경로가 포함된다
  2. `GET /sitemap.xml` 응답에 동적으로 생성된 카테고리 URL이 포함된다 (Admin에서 카테고리를 추가해도 자동 반영)
  3. 모든 페이지 `<head>`에 Google Search Console 소유권 인증 메타태그가 출력된다
  4. 모든 페이지 `<head>`에 네이버 서치어드바이저 소유권 인증 메타태그가 출력된다
**Plans**: 2 plans

Plans:
- [x] 10-01-PLAN.md — 동적 robots.txt 컨트롤러 + sitemap 카테고리 동적화
- [x] 10-02-PLAN.md — Google/Naver 검색엔진 인증 메타태그

### Phase 11: 소셜/색인 메타태그
**Goal**: 콘텐츠가 소셜에서 올바르게 미리보기되고 검색 색인이 의도한 대로 제어된다
**Depends on**: Phase 10
**Requirements**: SOCL-01, SOCL-02, SOCL-03, INDX-01, INDX-02, INDX-03
**Success Criteria** (what must be TRUE):
  1. 게시글 URL을 카카오톡/Discord에 공유하면 og:title, og:description, og:image가 포함된 미리보기 카드가 표시된다
  2. 게시글 상세 페이지 `<head>`에 Twitter Card 메타태그 (`twitter:card`, `twitter:title`, `twitter:description`)가 출력된다
  3. 홈페이지 및 목록 페이지 `<head>`에 사이트 기본 OG 메타태그가 출력된다
  4. 게시글 상세 페이지 `<head>`에 `<link rel="canonical">` 태그가 쿼리 파라미터 없이 출력된다
  5. `/admin/` 하위 모든 페이지와 로그인/회원가입 페이지 `<head>`에 `<meta name="robots" content="noindex">` 태그가 출력된다
**Plans**: 2 plans

Plans:
- [ ] 11-01-PLAN.md — OG/Twitter Card/canonical 메타태그 (게시글 + 홈 + 목록)
- [ ] 11-02-PLAN.md — Admin/인증 페이지 noindex 처리

### Phase 12: 구조화 데이터
**Goal**: 게시글이 Google Rich Results 자격을 갖추고 홈페이지가 사이트 신뢰도 구조화 데이터를 제공한다
**Depends on**: Phase 9
**Requirements**: STRD-01, STRD-02, STRD-03
**Success Criteria** (what must be TRUE):
  1. 게시글 상세 페이지 `<head>`에 Article JSON-LD가 출력되며 Google Rich Results 테스트에서 유효하다 (author, datePublished, headline 포함)
  2. 게시글 상세 페이지 `<head>`에 BreadcrumbList JSON-LD가 출력되며 카테고리 계층 구조를 반영한다
  3. 홈페이지 `<head>`에 WebSite와 Organization JSON-LD가 출력된다
  4. JSON-LD 출력이 특수문자(`<`, `>`, `&`)를 올바르게 이스케이프하여 HTML 파서가 오작동하지 않는다
**Plans**: [To be planned]

### Phase 13: Admin 에디터 UX
**Goal**: Admin 게시글 에디터가 메타 정보와 본문을 분리된 2단 레이아웃으로 제공한다
**Depends on**: Nothing (independent of SEO track)
**Requirements**: ADMN-01, ADMN-02, ADMN-03
**Success Criteria** (what must be TRUE):
  1. Admin 게시글 작성/수정 페이지에서 좌측에 메타 패널(제목, 카테고리, SEO 필드 등), 우측에 본문 에디터가 나란히 표시된다
  2. 본문 에디터를 스크롤해도 메타 패널이 뷰포트 상단에 고정되어 따라온다 (sticky)
  3. 모바일 화면에서 2단 레이아웃이 1단으로 자동 전환되어 메타 패널이 에디터 위에 쌓인다
**Plans**: [To be planned]

## Progress

**Execution Order:**
Phases execute in numeric order: 9 → 10 → 11 → 12 (depends on 9) → 13 (independent, can run parallel)

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
| 11. 소셜/색인 메타태그 | 2/2 | Complete   | 2026-03-13 | — |
| 12. 구조화 데이터 | v1.2 | 0/? | Not started | — |
| 13. Admin 에디터 UX | v1.2 | 0/? | Not started | — |
