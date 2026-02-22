# TeoVibe

## What This Is

사업화 영역(바이브코딩, 부업 아이템 등)을 블로그형 커뮤니티로 운영하는 Rails 기반 플랫폼. vite_ruby + React 기반 인터랙티브 랜딩페이지, rhino-editor 리치 에디터, 토스페이먼츠 결제 기반, Admin CMS 대시보드를 갖추고 외부 홍보에 사용할 수 있는 수준의 완성도를 달성한 상태.

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

### Active

<!-- 다음 마일스톤에서 구현할 목표 -->

- [ ] 슬래시 커맨드로 블록 삽입 (코드블록, 인용, 구분선 등)
- [ ] 글 하단 관련/최신 글 추천 섹션
- [ ] 태그 기반 콘텐츠 분류 및 필터링
- [ ] 이메일 알림 발송 (댓글, 좋아요 등)
- [ ] 토스페이먼츠 웹훅 처리 (결제 완료/취소 비동기 확인)
- [ ] 스킬팩 미리보기 콘텐츠 제공
- [ ] Admin 콘텐츠 분석 고도화 (차트, 기간별 필터, 내보내기)

### Out of Scope

- 실시간 채팅/DM -- 1인 운영에 과도한 운영 부담, 기존 댓글로 충분
- 모바일 앱 -- 반응형 웹으로 대응, 비용 대비 효과 낮음
- PostgreSQL 마이그레이션 -- 현재 규모에 SQLite 충분
- 별도 SPA 분리 -- Rails 내 React로 충분, 유지보수 복잡도 증가
- AI 콘텐츠 생성 -- API 비용, 품질 관리 리스크
- 사용자 마켓플레이스 -- 정산/분쟁/세금 등 완전히 다른 제품
- 협업 편집 (Y.js) -- 1인 저자 플랫폼에 불필요한 복잡도
- 알고리즘 피드 -- 현재 트래픽에서 과도한 엔지니어링

## Context

- Ruby 3.3.10, Rails 8.1.2, SQLite, Hotwire(Turbo+Stimulus), Tailwind CSS 4.4
- vite_ruby + React 18 + motion (framer-motion 후속) + TypeScript
- rhino-editor 0.17.x (TipTap 기반, ActionText 호환)
- chartkick + groupdate (Admin 차트)
- @tosspayments/payment-widget-sdk 0.12.1 (v1 SDK)
- Kamal + Docker 배포 구성 완료
- 17,092 LOC (Ruby/ERB/JS/JSX/TS/TSX/CSS)
- 1인 운영 프로젝트, 외부 홍보를 통해 사용자 유입 목표 단계

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

---
*Last updated: 2026-02-22 after v1.0 milestone*
