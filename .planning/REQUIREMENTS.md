# Requirements: TeoVibe

**Defined:** 2026-03-14
**Core Value:** 사용자가 재방문하고 싶은 수준의 콘텐츠 품질과 UX를 갖춘 커뮤니티 플랫폼

## v1.2 Requirements

Requirements for v1.2 SEO + Admin UX. Each maps to roadmap phases.

### 보안 패치

- [ ] **SEC-01**: seo_helper.rb JSON-LD 헬퍼의 XSS 취약점 수정 (`.to_json.html_safe` → 안전한 직렬화)

### SEO 크롤링

- [ ] **CRAWL-01**: robots.txt에 Googlebot/Yeti(네이버) 명시적 허용 규칙 추가
- [ ] **CRAWL-02**: robots.txt에 sitemap.xml 경로 명시
- [ ] **CRAWL-03**: sitemap에 동적 카테고리 URL 포함

### 검색엔진 인증

- [ ] **SRCH-01**: Google Search Console 소유권 인증 메타태그 삽입
- [ ] **SRCH-02**: 네이버 서치어드바이저 소유권 인증 메타태그 삽입

### 소셜 공유 메타태그

- [ ] **SOCL-01**: 게시글 상세 페이지에 Open Graph 메타태그 출력 (og:title/description/url/image)
- [ ] **SOCL-02**: 게시글 상세 페이지에 Twitter Card 메타태그 출력
- [ ] **SOCL-03**: 기본 페이지(홈/목록)에 사이트 기본 OG 메타태그 출력

### 중복/색인 관리

- [ ] **INDX-01**: 게시글 상세 페이지에 canonical URL 설정
- [ ] **INDX-02**: Admin 페이지 전역 noindex 처리
- [ ] **INDX-03**: 인증 관련 페이지(로그인/회원가입) noindex 처리

### 구조화 데이터

- [ ] **STRD-01**: 게시글 상세 페이지에 Article JSON-LD 출력
- [ ] **STRD-02**: 게시글 상세 페이지에 BreadcrumbList JSON-LD 출력
- [ ] **STRD-03**: 홈페이지에 WebSite + Organization JSON-LD 출력

### Admin 에디터 UX

- [ ] **ADMN-01**: Admin 게시글 작성/수정 폼 2단 레이아웃 (메타 패널 | 본문 에디터)
- [ ] **ADMN-02**: 메타 패널 sticky 고정 (스크롤 시 따라오기)
- [ ] **ADMN-03**: 모바일에서 1단 fallback 레이아웃

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
| SEC-01 | — | Pending |
| CRAWL-01 | — | Pending |
| CRAWL-02 | — | Pending |
| CRAWL-03 | — | Pending |
| SRCH-01 | — | Pending |
| SRCH-02 | — | Pending |
| SOCL-01 | — | Pending |
| SOCL-02 | — | Pending |
| SOCL-03 | — | Pending |
| INDX-01 | — | Pending |
| INDX-02 | — | Pending |
| INDX-03 | — | Pending |
| STRD-01 | — | Pending |
| STRD-02 | — | Pending |
| STRD-03 | — | Pending |
| ADMN-01 | — | Pending |
| ADMN-02 | — | Pending |
| ADMN-03 | — | Pending |

**Coverage:**
- v1.2 requirements: 18 total
- Mapped to phases: 0
- Unmapped: 18

---
*Requirements defined: 2026-03-14*
*Last updated: 2026-03-14 after initial definition*
