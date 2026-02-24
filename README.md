# TeoVibe - 바이브코딩 브랜딩 & 커뮤니티 플랫폼

바이브코딩으로 사업을 만드는 과정을 기록하고, 같은 여정을 걷는 사람들과 함께 성장하는 커뮤니티 플랫폼입니다.

## 기술 스택

| 분류 | 기술 |
|------|------|
| 프레임워크 | Rails 8.1 + Ruby 3.3 |
| 데이터베이스 | SQLite (WAL 모드) + FTS5 전문 검색 |
| 프론트엔드 | Hotwire (Turbo + Stimulus) |
| CSS | Tailwind CSS v4 (tailwindcss-rails) |
| 에셋 | Vite (vite_rails) |
| 인증 | Rails 빌트인 인증 + OmniAuth (Google, Kakao) |
| 리치 텍스트 | ActionText |
| 파일 업로드 | Active Storage |
| 페이지네이션 | Pagy v43 |
| SEO | meta-tags gem + sitemap_generator + JSON-LD |
| 메일 | ActionMailer + Gmail SMTP |
| 배포 | Kamal 2 + Litestream (SQLite 백업) |

## 주요 기능

### Phase 1: 인증 시스템
- 이메일/비밀번호 회원가입, 로그인, 로그아웃
- 소셜 로그인 (Google, Kakao) - OmniAuth
- 프로필 조회/수정

### Phase 2: 게시판 시스템
- 6개 카테고리: 블로그, 튜토리얼, 자유게시판, Q&A, 포트폴리오, 공지사항
- ActionText 리치 텍스트 에디터
- 댓글 (대댓글 지원) + Turbo Stream 실시간
- 좋아요 (게시글/댓글)
- RSS/Atom 피드

### Phase 3: 랜딩 페이지 + 관리자
- 동적 랜딩 페이지 (DB에서 섹션 관리)
- memoir 톤앤매너 디자인 (크림 톤, 대담한 타이포, pill 버튼)
- 관리자 패널 (대시보드, 랜딩 섹션/게시글/사용자/댓글 관리)
- SEO: JSON-LD, Open Graph, sitemap.xml, robots.txt

### Phase 4: 스킬팩 (무료 다운로드)
- 스킬팩 목록/상세 (카테고리 필터: 템플릿/컴포넌트/가이드/툴킷)
- Active Storage 파일 업로드 + 토큰 다운로드 링크
- 비로그인 시 로그인 후 다운로드 리다이렉트
- Admin CRUD + 파일/썸네일 관리

### Phase 5: 컨설팅 문의 + 이메일
- 문의 폼 (이름, 이메일, 연락처, 회사, 제목, 내용)
- InquiryMailer: 접수 확인 / 관리자 알림 / 답변 발송
- Gmail SMTP (production), letter_opener (개발환경)
- Admin 문의 관리 (답변/종료)

### Phase 6: 포인트/레벨 시스템
- 활동별 포인트: 글(+10), 댓글(+3), 좋아요(+2), 다운로드(+1), 일일로그인(+1)
- 10단계 레벨 시스템 (Lv1~Lv10), 레벨업 보너스(+20)
- 랭킹 페이지 (1~3위 강조), 포인트 히스토리 + 레벨 진행률

### Phase 7: 알림 + 검색 고도화
- 알림 시스템: 댓글/대댓글/좋아요/레벨업
- 네비바 벨 아이콘 + 읽지 않은 수 배지 + 드롭다운 (Stimulus)
- SQLite FTS5 전문 검색 (제목/본문/슬러그)
- 자동완성 API + Stimulus 컨트롤러

### Phase 8: SEO + 배포 준비
- JSON-LD 확장: WebSite, SoftwareApplication, ItemList, ProfilePage
- SSL/hosts 설정, Sitemap 확장
- Kamal deploy.yml (GitHub Container Registry)
- Litestream SQLite S3 백업 설정

## 로컬 개발

```bash
# Ruby 3.3 설치 (rbenv)
rbenv install 3.3.10
rbenv local 3.3.10

# 의존성 설치
cd teovibe
bundle install

# DB 마이그레이션 + 시드
bin/rails db:migrate
bin/rails db:seed

# Tailwind CSS 빌드
bin/rails tailwindcss:build

# 서버 실행
bin/rails server
```

관리자 계정: `admin@teovibe.com` / `password123`

## 디자인 시스템

memoirapp.com의 톤앤매너를 차용하여 재구성한 디자인:

- 배경: 크림 (#F5F1EA)
- 주요 CTA: 골드 (#F4BA54)
- 포인트: 오렌지 (#E86221)
- 본문: 다크 (#1D1403)
- 폰트: Pretendard (CDN)
- 버튼: pill 형태 (rounded-full)
- 카드: rounded-3xl

## 프로젝트 구조

```
teovibe/
├── app/
│   ├── controllers/
│   │   ├── posts_base_controller.rb    # 공통 게시판 CRUD
│   │   ├── skill_packs_controller.rb   # 스킬팩 다운로드
│   │   ├── inquiries_controller.rb     # 문의 폼
│   │   ├── notifications_controller.rb # 알림
│   │   ├── rankings_controller.rb      # 랭킹
│   │   ├── search_controller.rb        # FTS5 검색 + 자동완성
│   │   └── admin/                      # 관리자 패널
│   ├── models/
│   │   ├── user.rb                     # 인증 + 역할 + 포인트/레벨
│   │   ├── post.rb                     # 게시글 (6 카테고리)
│   │   ├── skill_pack.rb              # 스킬팩 (4 카테고리)
│   │   ├── notification.rb            # 알림
│   │   ├── point_transaction.rb       # 포인트 내역
│   │   └── inquiry.rb                 # 컨설팅 문의
│   ├── services/
│   │   ├── point_service.rb           # 포인트 지급/레벨업
│   │   └── notification_service.rb    # 알림 생성
│   ├── mailers/
│   │   └── inquiry_mailer.rb          # 문의 이메일
│   └── views/
├── config/
│   ├── routes.rb
│   ├── deploy.yml                     # Kamal 배포
│   ├── litestream.yml                 # SQLite 백업
│   └── sitemap.rb
└── db/
    └── migrate/                       # 17개 마이그레이션
```
