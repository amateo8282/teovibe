# Requirements: TeoVibe

**Defined:** 2026-03-14
**Core Value:** 사용자가 재방문하고 싶은 수준의 콘텐츠 품질과 UX를 갖춘 커뮤니티 플랫폼

## v1.2 Requirements

Requirements for v1.2 SEO + Admin UX. Each maps to roadmap phases.

### 보안 패치

- [x] **SEC-01**: seo_helper.rb JSON-LD 헬퍼의 XSS 취약점 수정 (`.to_json.html_safe` → 안전한 직렬화)

### SEO 크롤링

- [x] **CRAWL-01**: robots.txt에 Googlebot/Yeti(네이버) 명시적 허용 규칙 추가
- [x] **CRAWL-02**: robots.txt에 sitemap.xml 경로 명시
- [x] **CRAWL-03**: sitemap에 동적 카테고리 URL 포함

### 검색엔진 인증

- [x] **SRCH-01**: Google Search Console 소유권 인증 메타태그 삽입
- [x] **SRCH-02**: 네이버 서치어드바이저 소유권 인증 메타태그 삽입

### 소셜 공유 메타태그

- [x] **SOCL-01**: 게시글 상세 페이지에 Open Graph 메타태그 출력 (og:title/description/url/image)
- [x] **SOCL-02**: 게시글 상세 페이지에 Twitter Card 메타태그 출력
- [x] **SOCL-03**: 기본 페이지(홈/목록)에 사이트 기본 OG 메타태그 출력

### 중복/색인 관리

- [x] **INDX-01**: 게시글 상세 페이지에 canonical URL 설정
- [x] **INDX-02**: Admin 페이지 전역 noindex 처리
- [x] **INDX-03**: 인증 관련 페이지(로그인/회원가입) noindex 처리

### 구조화 데이터

- [x] **STRD-01**: 게시글 상세 페이지에 Article JSON-LD 출력
- [x] **STRD-02**: 게시글 상세 페이지에 BreadcrumbList JSON-LD 출력
- [x] **STRD-03**: 홈페이지에 WebSite + Organization JSON-LD 출력

### Admin 에디터 UX

- [x] **ADMN-01**: Admin 게시글 작성/수정 폼 2단 레이아웃 (메타 패널 | 본문 에디터)
- [x] **ADMN-02**: 메타 패널 sticky 고정 (스크롤 시 따라오기)
- [x] **ADMN-03**: 모바일에서 1단 fallback 레이아웃

## Future Requirements

### SEO 고도화

- **SEOV2-01**: og:image Active Storage 본문 이미지 자동 추출
- **SEOV2-02**: 게시글별 noindex 토글 (Post 모델 컬럼)
- **SEOV2-03**: sitemap ping 자동화 (Google/Naver 제출)
- **SEOV2-04**: SEO 제목/설명 글자수 카운터 Stimulus 컨트롤러

## Out of Scope

| Feature | Reason |
|---------|--------|
| 동적 robots.txt 컨트롤러 | static 파일 직접 수정으로 충분, 환경별 분기 불필요 |
| AMP 페이지 | Google AMP 우대 종료, 유지보수 비용 대비 효과 없음 |
| Schema.org FAQ/HowTo | 현재 콘텐츠 유형과 불일치 |
| 네이버 HTML 파일 인증 | 메타태그 방식이 더 안전하고 관리 편함 |

## Traceability

| Requirement | Phase | Status |
|-------------|-------|--------|
| SEC-01 | Phase 9 | Complete |
| CRAWL-01 | Phase 10 | Complete |
| CRAWL-02 | Phase 10 | Complete |
| CRAWL-03 | Phase 10 | Complete |
| SRCH-01 | Phase 10 | Complete |
| SRCH-02 | Phase 10 | Complete |
| SOCL-01 | Phase 11 | Complete |
| SOCL-02 | Phase 11 | Complete |
| SOCL-03 | Phase 11 | Complete |
| INDX-01 | Phase 11 | Complete |
| INDX-02 | Phase 11 | Complete |
| INDX-03 | Phase 11 | Complete |
| STRD-01 | Phase 12 | Complete |
| STRD-02 | Phase 12 | Complete |
| STRD-03 | Phase 12 | Complete |
| ADMN-01 | Phase 13 | Complete |
| ADMN-02 | Phase 13 | Complete |
| ADMN-03 | Phase 13 | Complete |

**Coverage:**
- v1.2 requirements: 18 total
- Mapped to phases: 18
- Unmapped: 0

---
*Requirements defined: 2026-03-14*
*Last updated: 2026-03-14 — Traceability updated after roadmap creation*
