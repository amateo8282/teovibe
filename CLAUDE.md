# Claude Code 규칙

## 기본 원칙

- **한국어 사용**: 모든 커밋 메시지, PR, 주석, 문서는 한국어로 작성
- **이모지 사용 금지**: 코드, 커밋 메시지, 문서에서 이모지 사용 지양
- **점진적 구현**: 한 번에 많은 변경보다 작은 단위로 구현 후 테스트
- **pnpm 사용**: 패키지 관리는 npm 대신 pnpm (`pnpm install`, `pnpm add`, `pnpm run`)
- **즉시 실행**: 간단한 작업(commit, push, branch)은 긴 설명이나 확인 없이 바로 실행
- **구현 우선**: 작업 요청 시 실제 코드를 구현. "계획만" 요청하지 않는 한 계획 문서만 생성하고 멈추지 말 것
- **기존 코드 보존**: 새 기능 구현 시 기존 코드/UI를 덮어쓰지 말 것. 변경 전 파일 현재 상태를 반드시 확인
- **사용자 방향 존중**: 대안 제안이나 요청 재구성 금지. 아키텍처와 도구 선택은 사용자 지시를 따를 것
- **중단 = 방향 수정**: 사용자가 중단하면 현재 접근이 잘못된 신호로 처리

## Tech Stack

- Frontend: TypeScript, React, Vite, Tailwind CSS
- Backend: FastAPI (Python), Clean Architecture
- Tailwind 버전(v3 vs v4) 수정 전 반드시 확인 -- v4는 @theme 인라인 블록 방식이 다름
- 외부 의존성 사용 시 프로젝트 Node 버전과 호환성 확인 후 설치
- 새 라이브러리 도입 시 context7로 최신 문서 확인
- 메이저 버전 업그레이드 전 breaking changes 체크
- 공식 문서 우선, 블로그/SO는 참고만

## Git

### 커밋 규칙
- 커밋과 푸시를 요청받으면 리뷰/분류 없이 즉시 실행
- 커밋 메시지는 한글로 간결하고 구체적으로 작성
  - 좋은 예: "로그인 기능 구현", "회원가입 폼 유효성 검사 추가"
  - 나쁜 예: "수정", "업데이트", "fix"
- 하나의 커밋에는 하나의 논리적 변경만 포함
- 기능 구현 완료 또는 TDD 사이클 완료 시 커밋

### 브랜치 전략
- `main`: 프로덕션 코드
- `dev`: 개발 중인 코드
- 기능 브랜치: `feature/기능명` (예: `feature/login`)

### 푸시 규칙
- 첫 푸시 전 remote URL 확인
- 푸시 전 README.md가 현재 프로젝트 상태를 반영하는지 점검 후 업데이트

## 보안

### 절대 커밋하지 않을 파일
- `.env`, `.env.local`, `.env.production`
- API 키, 시크릿 키가 포함된 파일
- 인증 정보 (credentials.json, service-account.json 등)

### .gitignore 필수 항목
```
.env*
*.pem
*.key
credentials*.json
```

## 코드 스타일

### 명명 규칙
- 컴포넌트: PascalCase (`LoginForm.tsx`)
- 유틸리티: camelCase (`formatDate.ts`)
- 스타일: kebab-case (`login-form.css`)

### 주석
- 복잡한 로직에는 한글 주석 필수
- `// TODO: 설명` / `// FIXME: 설명`

## TDD (Test-Driven Development)

### 사이클
1. **Red**: 실패하는 테스트 작성 (도메인 -> 유스케이스 -> 프레젠테이션 순)
2. **Green**: 테스트를 통과하는 최소한의 코드 작성
3. **Refactor**: 중복 제거, 네이밍 개선, 구조 최적화 (테스트는 계속 통과해야 함)
4. 사이클 완료 시 커밋

### 테스트 규칙
- 모든 새 기능은 테스트부터 작성
- 단위 테스트: 소스 파일과 같은 디렉토리에 `*.test.ts` / `*.test.tsx`
- 통합/E2E 테스트: `__tests__/integration/`, `__tests__/e2e/`
- 각 테스트는 독립적이며 하나의 동작만 검증

### 커버리지 목표
- 핵심 비즈니스 로직: 80% 이상
- 유틸리티 함수: 100%
- UI 컴포넌트: 주요 사용자 플로우

## 클린 아키텍처

### 계층 및 의존성 규칙

```
Presentation → Application → Domain ← Infrastructure
```

| 계층 | 역할 |
|------|------|
| **Domain** | 엔티티, 값 객체, 도메인 서비스. 외부 의존성 없음 |
| **Application** | 유스케이스, 인터페이스 정의 (Repository, Service), DTO |
| **Infrastructure** | DB, API 클라이언트. Application 인터페이스 구현 |
| **Presentation** | UI 컴포넌트, 페이지, 훅, 상태 관리 |

- **절대 금지**: Domain이 외부 계층에 의존
- Repository 인터페이스는 Application 계층에 정의, Infrastructure에서 구현
- 의존성 주입(DI)으로 결합도 낮춤
- 구현 순서: Domain -> Application -> Infrastructure -> Presentation

### 프로젝트 구조

```
project/
├── src/
│   ├── domain/               # 엔티티, 값 객체, 도메인 서비스
│   ├── application/          # 유스케이스, 인터페이스, DTO
│   ├── infrastructure/       # Repository 구현, API 클라이언트, DB 설정
│   └── presentation/         # 컴포넌트, 페이지, 훅, 상태 관리, 스타일
├── public/
├── docs/plans/               # 기능 계획 문서 (Plan.md, PRD.md, TRD.md, TASK.md)
└── __tests__/                # 통합/E2E 테스트
```

- Next.js App Router 사용 시 `src/` 대신 `app/` 폴더 가능

## 병렬 서브 에이전트 활용

### 공통 규칙
- 각 에이전트는 반드시 CLAUDE.md를 읽고 프로젝트 규칙을 따를 것
- feature 브랜치에서 작업하고, 변경마다 테스트 실행
- 실패 시 최소 3가지 다른 접근을 시도한 후 블로커로 보고
- 모든 에이전트 완료 후 단일 PR 생성 (각 에이전트 작업 요약 포함)

### 패턴 1: 디자인 시스템 추출
3개 병렬 에이전트로 각 참조 사이트에서 색상 팔레트, 타이포그래피, 간격 추출:
- 각 에이전트는 `/design-systems/`에 개별 JSON 출력
- 전체 완료 후 통합 `design-tokens.json` 합성

### 패턴 2: 풀스택 기능 구현
3개 병렬 에이전트로 백엔드/프론트엔드/통합 동시 구현:
- **백엔드 에이전트**: FastAPI 엔드포인트 구현 (요청 검증, 에러 처리, pytest 테스트). 테스트 통과까지 반복
- **프론트엔드 에이전트**: React 컴포넌트 구현 (TypeScript 타입, Tailwind 스타일링, 테스트). 테스트 통과까지 반복
- **통합 에이전트**: 위 두 에이전트 완료 대기 후 통합 테스트 작성. API 호출 -> 프론트엔드 렌더링 검증

## 태스크 추적 (TaskCreate/TaskUpdate)

### 플랜 문서 작성 시 태스크 분해 규칙
- 플랜 문서(`docs/plans/TASK.md`) 작성과 동시에 **TaskCreate로 개별 태스크를 등록**할 것
- 기능을 구현 가능한 최소 단위로 분해 (1태스크 = 1커밋 수준)
- 각 태스크에는 명확한 완료 조건(acceptance criteria)을 description에 포함
- 태스크 간 의존성이 있으면 `addBlockedBy`로 순서 지정

### 태스크 상태 관리
- 구현 시작 시: `TaskUpdate`로 `in_progress` 전환
- 테스트 통과 + 커밋 완료 시: `TaskUpdate`로 `completed` 전환
- 구현 중 추가 작업 발견 시: 즉시 `TaskCreate`로 새 태스크 추가
- 블로커 발생 시: 태스크는 `in_progress` 유지, 블로커 내용을 description에 기록

### 태스크 분해 예시
```
기능: 사용자 로그인

태스크 1: User 엔티티 및 값 객체 정의 (Domain)
태스크 2: AuthRepository 인터페이스 정의 (Application)
태스크 3: LoginUseCase 구현 (Application) -- blocked by 1, 2
태스크 4: AuthRepository 구현 (Infrastructure) -- blocked by 2
태스크 5: LoginForm 컴포넌트 구현 (Presentation) -- blocked by 3, 4
태스크 6: 통합 테스트 작성 -- blocked by 5
```

### 진행 상황 확인
- 작업 시작 전 `TaskList`로 현재 진행 상황 파악
- 완료된 태스크 비율로 전체 진행도 추적
- 모든 태스크 완료 시 최종 통합 테스트 후 푸시

## OmniAuth 소셜 로그인 (트러블슈팅 기록)

### Kakao OAuth
- **omniauth-kakao gem (v0.0.1)은 사용 금지**: strategy 파일이 누락된 불완전한 gem. 개발 Mock 모드에서만 동작하고 프로덕션에서 LoadError 발생
- **omniauth-kakao-oauth2 gem도 사용 금지**: omniauth v1.x 의존성을 강제하여 omniauth-rails_csrf_protection이 0.1.2로 다운그레이드됨. 이로 인해 CSRF 토큰 검증 실패 (authenticity_error)
- **해결**: `config/omniauth_kakao_strategy.rb`에 커스텀 strategy 직접 구현
- **핵심 설정**: `auth_scheme: :request_body` 필수 (카카오 API는 client_id를 header가 아닌 body로 요구)
- **Zeitwerk 주의**: `lib/omniauth/strategies/` 경로에 두면 Zeitwerk가 `Omniauth::Strategies::Kakao`로 autoload 시도하여 NameError. `config/` 디렉토리에 배치하고 `require_relative`로 로드

### OmniAuth + Turbo 호환성
- `button_to`로 소셜 로그인 POST 시 반드시 `data: { turbo: false }` 추가
- Turbo가 OmniAuth POST를 가로채면 CSRF 토큰이 제대로 전달되지 않아 authenticity_error 발생

### Kamal 배포 시 환경변수
- `.env` 파일의 OAuth 키는 `.kamal/secrets`에서 `$ENV_VAR` 형태로 참조
- 배포 전 `export $(cat .env | grep -v '^#' | grep -v '^$' | xargs)` 실행 필요
- `dotenv-rails` gem은 development/test 그룹에만 설치 (프로덕션 Docker에서는 Kamal이 env 주입)

### 관련 파일
- `config/omniauth_kakao_strategy.rb` - Kakao OAuth2 strategy (커스텀)
- `config/initializers/omniauth.rb` - OmniAuth 미들웨어 설정
- `app/views/shared/_auth_social.html.erb` - 소셜 로그인 버튼
- `app/controllers/omniauth/sessions_controller.rb` - OAuth 콜백 처리
- `docs/OAUTH_SETUP_GUIDE.md` - OAuth 설정 매뉴얼

## 게시판 / 라우팅 트러블슈팅 기록

### Post status 기본값 문제
- **증상**: 일반 사용자가 글을 작성해도 게시판 목록에 미노출. 마이페이지에서는 보임
- **원인**: `Post` 모델 `status` enum 기본값이 `draft: 0`. `PostsController` 폼에 status 필드가 없어 모든 글이 draft로 저장됨. 게시판 목록은 `.published` scope만 조회
- **해결**: `PostsController#create`에서 `@post.status = :published` 명시적 설정
- **주의**: `Admin::PostsController`는 예약 발행 로직이 별도 존재 — 건드리지 말 것

### Rails 라우트 순서 충돌 (카테고리 목록 vs 게시글 상세)
- **증상**: 글 작성 후 `/posts/post-8` 이동 시 404 발생
- **원인**: `GET /posts/:category_slug`(index)가 `GET /posts/:slug`(show)보다 먼저 선언되어 동일 패턴 충돌. `post-8`이 카테고리 slug로 잘못 매칭
- **해결**: `resources :posts`에 slug constraint 추가 후 카테고리 라우트보다 앞에 선언
  ```ruby
  resources :posts, param: :slug, only: %i[show edit update destroy],
            constraints: { slug: /(\d|post-).*/ }
  get "posts/:category_slug", to: "posts#index", as: :category_posts
  ```
- **규칙**: post slug는 항상 숫자(`8-title`) 또는 `post-N` 형태. 카테고리 slug는 영문자로만 시작 (`blog`, `free-board` 등). 이 규칙이 깨지면 constraint도 수정 필요

### Kamal 배포 시 환경변수 로딩
- **증상**: `kamal deploy` 실행 시 `docker login` 실패 (`flag needs an argument: 'p'`)
- **원인**: 셸에 `KAMAL_REGISTRY_PASSWORD`가 설정되지 않은 상태로 실행
- **해결**: `teovibe/` 디렉토리 안에서 반드시 `.env` 로드 후 배포
  ```bash
  cd teovibe
  export $(cat .env | grep -v '^#' | grep -v '^$' | xargs) && kamal deploy
  ```
- **주의**: `teovibe/` 상위 디렉토리에서 실행 시 `.env` 경로가 달라짐

## 작업 흐름

1. 기능 요구사항 확인 및 도메인 모델 설계
2. `docs/plans/`에 계획 문서 작성 (Plan.md, PRD.md, TRD.md, TASK.md)
3. **TASK.md 기반으로 TaskCreate로 태스크 등록** (의존성 포함)
4. TDD 사이클 실행 (Red -> Green -> Refactor -> 커밋) -- 각 태스크별 상태 업데이트
5. 통합/E2E 테스트
6. 푸시 (README.md 점검 포함)
7. 문서 업데이트 (프로젝트 푸시 시 본 파일도 프로젝트 내용 반영하여 업데이트)
