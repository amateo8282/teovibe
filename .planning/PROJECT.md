# TeoVibe

## What This Is

사업화 영역(바이브코딩, 부업 아이템 등)을 블로그형 커뮤니티로 운영하는 Rails 기반 플랫폼. vite_ruby + React 기반 인터랙티브 랜딩페이지, rhino-editor 리치 에디터(TipTap 기반 서식/표/블록 삽입 확장 완료), 토스페이먼츠 결제 기반, Admin CMS 대시보드를 갖추고 SEO 최적화와 네이버 블로그 수준의 Admin 에디터까지 완성한 상태.

## Core Value

사용자가 재방문하고 싶은 수준의 콘텐츠 품질과 UX를 갖춘 커뮤니티 플랫폼 -- 외부에 보여줘도 부끄럽지 않은 완성도.

## Requirements

### Validated

- ✓ 이메일/비밀번호 회원가입 및 로그인 -- existing
- ✓ Google/Kakao OAuth 소셜 로그인 -- existing
- ✓ 세션 기반 인증 및 권한 관리 (admin/member) -- existing
- ✓ 다중 카테고리 게시판 (blog, tutorial, free_board, qna, portfolio, notice) -- existing
- ✓ 댓글 및 대댓글 기능 -- existing
- ✓ 좋아요 (게시글/댓글 폴리모픽) -- existing
- ✓ 포인트 시스템 및 레벨 -- existing
- ✓ 알림 시스템 (댓글, 좋아요, 팔로우 등) -- existing
- ✓ 스킬팩 관리 및 다운로드 (Active Storage) -- existing
- ✓ 검색 (SQLite FTS5 + fallback LIKE) -- existing
- ✓ SEO 메타태그 및 사이트맵 -- existing
- ✓ Admin CMS (게시글, 사용자, 스킬팩, 문의, 랜딩섹션 CRUD) -- existing
- ✓ Turbo Streams 실시간 UI 업데이트 -- existing
- ✓ Kamal + Docker 배포 구성 -- existing
- ✓ vite_ruby 빌드 파이프라인 (ImportMap 대체) -- v1.0
- ✓ SQLite WAL 모드 + Solid Queue/Cache/Cable 별도 DB -- v1.0
- ✓ ViewComponent 재사용 가능한 UI 컴포넌트 -- v1.0
- ✓ rhino-editor 리치 에디터 (이미지 업로드, 버블 메뉴) -- v1.0
- ✓ 작성자 프로필 (아바타, 소셜링크, 포인트/레벨/뱃지) -- v1.0
- ✓ Admin 콘텐츠 분석 대시보드 (chartkick + groupdate) -- v1.0
- ✓ React 인터랙티브 랜딩페이지 (motion 애니메이션, Admin JSON API) -- v1.0
- ✓ 토스페이먼츠 결제 기반 (Order 모델, 체크아웃 UI, SDK 위젯, confirm API) -- v1.0
- ✓ 모바일 반응형 보완 (Navbar/Admin off-canvas 사이드바) -- v1.0
- ✓ 커스텀 에러 페이지 (404/500/422 브랜드 한글) -- v1.0
- ✓ 게시판/스킬팩 카테고리 동적 CRUD + DnD 순서 변경 + 관리자 전용 토글 -- v1.1
- ✓ 게시글 예약 발행 (KST 날짜/시간 지정, SolidQueue 자동 전환) -- v1.1
- ✓ AI 초안 작성 (Anthropic API, 개요→본문 2단계, rhino-editor 삽입, SEO/AEO) -- v1.1
- ✓ JSON-LD XSS 보안 패치 (safe_json_ld 래퍼) -- v1.2
- ✓ 동적 robots.txt + sitemap 카테고리 동적화 (Googlebot/Yeti 크롤링 기반) -- v1.2
- ✓ Google/Naver 검색엔진 소유권 인증 메타태그 -- v1.2
- ✓ OG/Twitter Card/canonical 메타태그 + Admin/인증 noindex -- v1.2
- ✓ Article/BreadcrumbList/WebSite/Organization JSON-LD 구조화 데이터 -- v1.2
- ✓ Admin 게시글 에디터 2단 레이아웃 (sticky 메타 패널 + 모바일 fallback) -- v1.2
- ✓ ActionText 허용목록 + AdminRhinoEditor 서브클래스 스캐폴드 -- v1.3
- ✓ TipTap 서식 확장 (취소선/밑줄/인용구/구분선/코드블록/제목 드롭다운) -- v1.3
- ✓ 텍스트 스타일링 (정렬/글자색/배경색/폰트 크기) -- v1.3
- ✓ 표(Table) 삽입 및 행/열 편집 -- v1.3
- ✓ 블록 삽입 메뉴 (+ 버튼으로 빠른 삽입) -- v1.3

### Active

(다음 마일스톤에서 정의)

### Out of Scope

- 실시간 채팅/DM -- 1인 운영에 과도한 운영 부담, 기존 댓글로 충분
- 모바일 앱 -- 반응형 웹으로 대응, 비용 대비 효과 낮음
- PostgreSQL 마이그레이션 -- 현재 규모에 SQLite 충분
- 별도 SPA 분리 -- Rails 내 React로 충분, 유지보수 복잡도 증가
- AI 콘텐츠 생성 -- API 비용, 품질 관리 리스크
- 사용자 마켓플레이스 -- 정산/분쟁/세금 등 완전히 다른 제품
- 협업 편집 (Y.js) -- 1인 저자 플랫폼에 불필요한 복잡도
- 알고리즘 피드 -- 현재 트래픽에서 과도한 엔지니어링
- AMP 페이지 -- Google AMP 우대 종료, 유지보수 비용 대비 효과 없음
- Schema.org FAQ/HowTo -- 현재 콘텐츠 유형과 불일치

## Context

- Ruby 3.3.10, Rails 8.1.2, SQLite, Hotwire(Turbo+Stimulus), Tailwind CSS 4.4
- vite_ruby + React 18 + motion (framer-motion 후속) + TypeScript
- rhino-editor 0.17.x (TipTap 기반, ActionText 호환)
- chartkick + groupdate (Admin 차트)
- @tosspayments/payment-widget-sdk 0.12.1 (v1 SDK)
- anthropic gem v1.23.0 (AI 초안 작성)
- meta-tags gem (OG/Twitter/canonical/noindex)
- sitemap_generator gem (동적 sitemap)
- Sortable.js 1.15.7 (카테고리 DnD)
- Kamal + Docker 배포 구성 완료
- TipTap extension 10+ 등록 (Underline, TextAlign, Color, TextStyle, Highlight, FontSize, Table 4종)
- 1인 운영 프로젝트, SEO 최적화 완료 상태
- v1.0~v1.3 총 4개 마일스톤 출시 (18 phases, 34 plans)

## Constraints

- **Tech stack**: Rails 모놀리스 유지 -- 검증된 구조를 깨지 않음
- **Frontend**: vite_ruby + React로 Rails 내 부분 적용 -- 별도 SPA 아님
- **Database**: SQLite 유지 -- 현재 규모에 적합
- **1인 운영**: 유지보수 복잡도를 최소화하는 방향으로 설계
- **결제**: 토스페이먼츠 v1 SDK 기반 구축 완료 -- v2 마이그레이션은 별도 마일스톤

## Key Decisions

| Decision | Rationale | Outcome |
|----------|-----------|---------|
| vite_ruby + React (react-rails 대신) | react-rails gem은 유지보수 중단 권고, ImportMap은 JSX 미지원 | ✓ Good |
| rhino-editor 0.17.x (TipTap 기반) | ActionText 호환 유지하며 에디터 UX 개선. 0.18.x는 이미지 업로드 제거됨 | ✓ Good |
| 토스페이먼츠 Faraday 직접 호출 | 공식 Ruby gem 없음. v1 SDK로 기반 구조 선구축 | ✓ Good |
| ImportMap → vite_ruby 전환 | JSX/TypeScript/React 사용의 필수 선행 작업 | ✓ Good |
| Solid Queue/Cache/Cable 별도 DB | 개발/프로덕션 환경 일관성 확보 | ✓ Good |
| motion 패키지 (구 framer-motion) | React 애니메이션 라이브러리 최신 리브랜딩 버전 사용 | ✓ Good |
| ErrorsController < ActionController::Base | ApplicationController의 DB 의존성 우회, 500 에러 안전 렌더링 | ✓ Good |
| Tailwind v4 @source 디렉티브 | @tailwindcss/vite가 .erb 파일 자동 스캔 안 함, 명시적 추가 필요 | ✓ Good |
| Category 단일 모델 (record_type enum) | post/skillpack 구분을 단일 테이블로, LandingSection 패턴 일관성 | ✓ Good |
| Post 예약: scheduled_at 컬럼 (enum 대신) | status enum에 scheduled 추가는 안티패턴, 별도 컬럼이 유연 | ✓ Good |
| Anthropic API 동기 JSON 방식 | 스트리밍은 Future scope, 동기 방식이 구현 단순 | ✓ Good |
| Stimulus Vite glob 자동 등록 | stimulus-vite-helpers의 import.meta.glob으로 수동 등록 불필요 | ✓ Good |
| safe_json_ld 래퍼로 XSS 패치 | .to_json.html_safe 직접 사용 제거, Unicode 이스케이프 후 html_safe | ✓ Good |
| 동적 robots.txt 컨트롤러 (정적 파일 대체) | 환경별 분기(프로덕션/비프로덕션) 필요, 정적 파일은 라우터 우선하여 컨트롤러 무시 | ✓ Good |
| credentials.dig 방식 인증 메타태그 | set_meta_tags 대신 직접 출력 — yield :head 이전 배치로 모든 경로 일관 출력 | ✓ Good |
| Admin 레이아웃 noindex 하드코딩 | display_meta_tags 미사용 레이아웃이므로 직접 meta 태그 삽입이 안전 | ✓ Good |
| content_for :head로 JSON-LD 배치 | 레이아웃의 yield :head 위치에 자동 삽입, 뷰 독립적 | ✓ Good |
| Admin 에디터 2단 flex 레이아웃 (sticky) | JS 없이 Tailwind만으로 구현, sticky 부모에 overflow 금지 주의 | ✓ Good |
| AdminRhinoEditor 서브클래스 패턴 | TipTapEditor 상속 + addExtensions() + renderToolbarEnd() override — 기존 toolbar 보존하며 확장 | ✓ Good |
| renderToolbarEnd() override (renderToolbar 전체 재작성 대신) | 기존 Strike/Blockquote/CodeBlock 기본 버튼 자동 보존 | ✓ Good |
| 커스텀 FontSize extension (로컬 구현) | @tiptap/extension-font-size는 v3 전용, Extension.create() 30줄로 동일 기능 | ✓ Good |
| Light DOM 컨텍스트/플로팅 메뉴 | Shadow DOM 경계 외부 배치로 position:absolute 뷰포트 기준 동작 보장 | ✓ Good |
| @tiptap/extension-floating-menu 미사용 | tippy.js 의존성 + Shadow DOM 충돌, 네이티브 JS로 직접 구현 | ✓ Good |
| Table resizable: false | drag handle이 rhino-editor 포인터 이벤트와 충돌 | ✓ Good |

### Future (deferred from v1.1)

- 슬래시 커맨드로 블록 삽입 (코드블록, 인용, 구분선 등)
- 글 하단 관련/최신 글 추천 섹션
- 태그 기반 콘텐츠 분류 및 필터링
- 이메일 알림 발송 (댓글, 좋아요 등)
- 토스페이먼츠 웹훅 처리 (결제 완료/취소 비동기 확인)
- 스킬팩 미리보기 콘텐츠 제공
- Admin 콘텐츠 분석 고도화 (차트, 기간별 필터, 내보내기)

### Future (deferred from v1.2)

- og:image Active Storage 본문 이미지 자동 추출
- 게시글별 noindex 토글 (Post 모델 컬럼)
- sitemap ping 자동화 (Google/Naver 제출)
- SEO 제목/설명 글자수 카운터 Stimulus 컨트롤러

### Future (deferred from v1.3)

- 동영상 임베드 (YouTube URL 붙여넣기)
- 파일 첨부 (Active Storage 확장)
- 슬래시 커맨드 (/ 입력으로 블록 삽입)
- 일반 사용자 에디터 확대 적용
- actiontext.css table CSS 스타일 추가 (표 보더/패딩)

---
*Last updated: 2026-03-15 after v1.3 milestone*
