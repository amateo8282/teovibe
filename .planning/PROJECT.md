# TeoVibe

## What This Is

사업화 영역(바이브코딩, 부업 아이템 등)을 블로그형 커뮤니티로 운영하는 Rails 기반 플랫폼. 어드민이 콘텐츠를 관리하면서 외부 홍보용으로도 노출되며, 회원가입한 사용자들이 글을 쓰고 의견을 교류하고, 디지털 콘텐츠(스킬팩)를 구매할 수 있는 구조를 목표로 한다.

## Core Value

사용자가 재방문하고 싶은 수준의 콘텐츠 품질과 UX를 갖춘 커뮤니티 플랫폼 -- 외부에 보여줘도 부끄럽지 않은 완성도.

## Requirements

### Validated

<!-- 기존 코드베이스에서 이미 구현된 기능 -->

- ✓ 이메일/비밀번호 회원가입 및 로그인 -- existing
- ✓ Google/Kakao OAuth 소셜 로그인 -- existing
- ✓ 세션 기반 인증 및 권한 관리 (admin/member) -- existing
- ✓ 다중 카테고리 게시판 (blog, tutorial, free_board, qna, portfolio, notice) -- existing
- ✓ ActionText(Trix) 기반 리치텍스트 글 작성 -- existing
- ✓ 댓글 및 대댓글 기능 -- existing
- ✓ 좋아요 (게시글/댓글 폴리모픽) -- existing
- ✓ 포인트 시스템 및 레벨 -- existing
- ✓ 알림 시스템 (댓글, 좋아요, 팔로우 등) -- existing
- ✓ 스킬팩 관리 및 다운로드 (Active Storage) -- existing
- ✓ 검색 (SQLite FTS5 + fallback LIKE) -- existing
- ✓ SEO 메타태그 및 사이트맵 -- existing
- ✓ Admin CMS (게시글, 사용자, 스킬팩, 문의, 랜딩섹션 CRUD) -- existing
- ✓ 랜딩 페이지 관리 (Admin 랜딩섹션) -- existing
- ✓ Turbo Streams 실시간 UI 업데이트 -- existing
- ✓ Kamal + Docker 배포 구성 -- existing

### Active

<!-- 이번 고도화에서 구현할 목표 -->

- [ ] Rich Text 에디터 UX 개선 (Trix 강화 또는 대체 에디터 도입, 이미지 업로드 개선, 서식 도구 확장)
- [ ] React 적용 매력적인 랜딩페이지 (react-rails gem 활용, 인터랙티브 컴포넌트, 전환 애니메이션)
- [ ] 디지털 콘텐츠 판매 기반 마련 (스킬팩 결제 구조 설계, 토스페이먼츠 연동 준비)
- [ ] 전반적 UI/UX 완성도 향상 (반응형 디자인 보완, 네비게이션 개선, 로딩 상태 처리)
- [ ] 사용자 유입을 위한 콘텐츠 경험 개선 (프로필 강화, 구독/팔로우 개선, 콘텐츠 추천)

### Out of Scope

- 실시간 채팅 -- 커뮤니티 핵심이 아님, 복잡도 높음
- 모바일 앱 -- 웹 우선, 반응형으로 대응
- 토스페이먼츠 실제 결제 구현 -- 기반 구조만 마련, 실결제는 다음 마일스톤
- PostgreSQL 마이그레이션 -- 현재 SQLite로 충분, 규모 커지면 검토
- 별도 SPA 분리 -- Rails 내 React 컴포넌트로 충분

## Context

- Ruby 3.3.10, Rails 8.1.2, SQLite, Hotwire(Turbo+Stimulus), Tailwind CSS 4.4 기반
- Kamal + Docker로 배포 구성 완료
- ActionText/Trix 에디터가 현재 글 작성에 사용 중이나 UX가 단순함
- 랜딩페이지는 Admin에서 섹션 관리 가능하나 정적 ERB 렌더링으로 매력도 부족
- 스킬팩 모델은 있으나 결제 흐름 없이 무료 다운로드만 가능
- 1인 운영 프로젝트로 어드민 본인이 주 콘텐츠 생산자
- 외부 홍보를 통해 사용자 유입을 목표로 하는 단계

## Constraints

- **Tech stack**: Rails 모놀리스 유지 -- 검증된 구조를 깨지 않음
- **Frontend**: React는 react-rails gem으로 Rails 내 부분 적용 -- 별도 SPA 아님
- **Database**: SQLite 유지 -- 현재 규모에 적합
- **1인 운영**: 유지보수 복잡도를 최소화하는 방향으로 설계
- **결제**: 토스페이먼츠 연동 기반만 구축 -- 실결제는 별도 마일스톤

## Key Decisions

| Decision | Rationale | Outcome |
|----------|-----------|---------|
| Rails 내 React (react-rails) | 별도 SPA 대비 유지보수 간편, 기존 인프라 활용 | -- Pending |
| Rich Text 에디터 개선 방향 (Trix 강화 vs TipTap 등 대체) | 글 작성 UX가 가장 부족한 영역으로 지목됨 | -- Pending |
| 토스페이먼츠 기반 구조 선설계 | 실결제 전 모델/라우팅/UI 기반을 먼저 마련 | -- Pending |

---
*Last updated: 2026-02-22 after initialization*
