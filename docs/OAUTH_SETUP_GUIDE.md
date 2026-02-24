# TeoVibe OAuth 로그인 설정 매뉴얼

TeoVibe는 Google과 Kakao 소셜 로그인을 지원합니다.
환경변수만 설정하면 자동으로 활성화됩니다.

---

## 목차

1. [Google OAuth 설정](#1-google-oauth-설정)
2. [Kakao OAuth 설정](#2-kakao-oauth-설정)
3. [환경변수 적용](#3-환경변수-적용)
4. [개발 환경 테스트](#4-개발-환경-테스트)
5. [프로덕션 배포](#5-프로덕션-배포)
6. [트러블슈팅](#6-트러블슈팅)

---

## 1. Google OAuth 설정

### 1.1 Google Cloud Console 프로젝트 생성

1. [Google Cloud Console](https://console.cloud.google.com/) 접속
2. 상단의 프로젝트 선택 > **새 프로젝트** 클릭
3. 프로젝트 이름 입력 (예: `TeoVibe`) > **만들기**

### 1.2 OAuth 동의 화면 구성

1. 좌측 메뉴 > **API 및 서비스** > **OAuth 동의 화면**
2. **시작하기** 클릭
3. 앱 정보 입력:
   - **앱 이름**: TeoVibe
   - **사용자 지원 이메일**: 본인 이메일
   - **개발자 연락처 이메일**: 본인 이메일
4. **대상** 설정:
   - 테스트 중에는 **외부** 선택
   - 테스트 사용자를 추가해야 로그인 가능 (최대 100명)
5. **범위(Scope)** 추가:
   - `email` (사용자 이메일 주소)
   - `profile` (사용자 기본 프로필)
   - 위 두 항목은 민감하지 않은 범위이므로 별도 검증 불필요

### 1.3 OAuth 클라이언트 ID 생성

1. 좌측 메뉴 > **API 및 서비스** > **사용자 인증 정보**
2. **사용자 인증 정보 만들기** > **OAuth 클라이언트 ID**
3. 애플리케이션 유형: **웹 애플리케이션**
4. 이름: `TeoVibe Web`
5. **승인된 리디렉션 URI** 추가:
   - 개발: `http://localhost:3000/auth/google_oauth2/callback`
   - 프로덕션: `https://jaeho.im/auth/google_oauth2/callback`
6. **만들기** 클릭
7. **클라이언트 ID**와 **클라이언트 보안 비밀번호**를 복사하여 안전하게 보관

### 1.4 필요한 값

| 항목 | 환경변수 | 예시 |
|------|----------|------|
| 클라이언트 ID | `GOOGLE_CLIENT_ID` | `123456789-abc.apps.googleusercontent.com` |
| 클라이언트 보안 비밀번호 | `GOOGLE_CLIENT_SECRET` | `GOCSPX-abcdef123456` |

---

## 2. Kakao OAuth 설정

### 2.1 Kakao Developers 애플리케이션 생성

1. [Kakao Developers](https://developers.kakao.com/) 접속 > 로그인
2. **내 애플리케이션** > **애플리케이션 추가하기**
3. 앱 정보 입력:
   - **앱 이름**: TeoVibe
   - **사업자명**: 본인 이름 또는 사업자명
4. **저장** 클릭

### 2.2 플랫폼 등록

1. 생성된 앱 클릭 > **앱 설정** > **플랫폼**
2. **Web 플랫폼 등록**:
   - 개발: `http://localhost:3000`
   - 프로덕션: `https://jaeho.im`

### 2.3 Redirect URI 등록

1. **제품 설정** > **카카오 로그인** > **활성화 설정** ON
2. **Redirect URI** 등록:
   - 개발: `http://localhost:3000/auth/kakao_oauth2/callback`
   - 프로덕션: `https://jaeho.im/auth/kakao_oauth2/callback`

### 2.4 동의 항목 설정

1. **제품 설정** > **카카오 로그인** > **동의항목**
2. 다음 항목을 **필수 동의**로 설정:
   - **닉네임** (profile_nickname)
   - **카카오계정(이메일)** (account_email)
3. 선택: **프로필 사진** (profile_image)

### 2.5 앱 키 확인

1. **앱 설정** > **앱 키**
2. **REST API 키** = `KAKAO_CLIENT_ID`
3. **제품 설정** > **카카오 로그인** > **보안** > **Client Secret** 코드 생성
   - 활성화 상태를 **사용함**으로 변경
   - 생성된 코드 = `KAKAO_CLIENT_SECRET`

### 2.6 필요한 값

| 항목 | 환경변수 | 예시 |
|------|----------|------|
| REST API 키 | `KAKAO_CLIENT_ID` | `abcdef1234567890abcdef1234567890` |
| Client Secret | `KAKAO_CLIENT_SECRET` | `AbCdEfGhIjKlMnOpQrStUv` |

---

## 3. 환경변수 적용

### 3.1 개발 환경 (.env)

프로젝트 루트(`teovibe/`)에 `.env` 파일 생성:

```bash
# Google OAuth
GOOGLE_CLIENT_ID=your-google-client-id
GOOGLE_CLIENT_SECRET=your-google-client-secret

# Kakao OAuth
KAKAO_CLIENT_ID=your-kakao-rest-api-key
KAKAO_CLIENT_SECRET=your-kakao-client-secret
```

> `.env` 파일은 `.gitignore`에 포함되어 있으므로 커밋되지 않습니다.

### 3.2 프로덕션 환경 (Kamal)

Kamal 배포 시 `.kamal/secrets` 파일에 추가:

```bash
GOOGLE_CLIENT_ID=your-google-client-id
GOOGLE_CLIENT_SECRET=your-google-client-secret
KAKAO_CLIENT_ID=your-kakao-rest-api-key
KAKAO_CLIENT_SECRET=your-kakao-client-secret
```

그리고 `config/deploy.yml`의 `env.secret`에 등록:

```yaml
env:
  secret:
    - RAILS_MASTER_KEY
    - GOOGLE_CLIENT_ID
    - GOOGLE_CLIENT_SECRET
    - KAKAO_CLIENT_ID
    - KAKAO_CLIENT_SECRET
```

---

## 4. 개발 환경 테스트

### 4.1 Mock 모드 (환경변수 없이)

환경변수를 설정하지 않으면 자동으로 Mock 모드가 활성화됩니다.
(`config/initializers/omniauth.rb` 참고)

- Google 테스트 계정: `testuser@gmail.com` / `Google 테스트유저`
- Kakao 테스트 계정: `testuser@kakao.com` / `카카오 테스트유저`

소셜 로그인 버튼을 클릭하면 실제 OAuth 없이 위 테스트 계정으로 로그인됩니다.

### 4.2 실제 OAuth 테스트

환경변수를 설정하면 Mock 모드가 비활성화되고 실제 OAuth 플로우가 작동합니다:

```bash
cd teovibe
bin/rails server
```

`http://localhost:3000/session/new`에서 Google/Kakao 로그인 버튼을 클릭하여 테스트합니다.

---

## 5. 프로덕션 배포

### 5.1 배포 전 체크리스트

- [ ] Google Cloud Console에서 프로덕션 Redirect URI 등록 (`https://jaeho.im/auth/google_oauth2/callback`)
- [ ] Kakao Developers에서 프로덕션 Redirect URI 등록 (`https://jaeho.im/auth/kakao_oauth2/callback`)
- [ ] Kakao 플랫폼에 프로덕션 도메인 등록 (`https://jaeho.im`)
- [ ] `.kamal/secrets`에 OAuth 환경변수 추가
- [ ] `config/deploy.yml`에 secret 환경변수 등록
- [ ] Google OAuth 동의 화면에서 **프로덕션으로 게시** (테스트 모드 해제)

### 5.2 Kamal 배포

```bash
cd teovibe
kamal deploy
```

### 5.3 배포 후 확인

```bash
# 서버에서 환경변수 확인
kamal app exec "printenv | grep -E 'GOOGLE|KAKAO'"

# 로그 확인
kamal app logs -f
```

---

## 6. 트러블슈팅

### "redirect_uri_mismatch" 오류

OAuth 제공자에 등록한 Redirect URI와 실제 콜백 URL이 다를 때 발생합니다.

- Google: `https://jaeho.im/auth/google_oauth2/callback` (정확히 일치해야 함)
- Kakao: `https://jaeho.im/auth/kakao_oauth2/callback`
- 후행 슬래시(`/`) 유무도 일치해야 합니다

### "소셜 로그인에 실패했습니다" 메시지

`/auth/failure`로 리다이렉트된 경우입니다. 원인:

1. 환경변수가 비어있거나 잘못됨
2. Client Secret이 만료됨 (Kakao는 주기적 갱신 필요할 수 있음)
3. 사용자가 동의 화면에서 취소함

Rails 로그에서 상세 오류를 확인하세요:

```bash
# 개발
tail -f teovibe/log/development.log | grep -i omniauth

# 프로덕션
kamal app logs -f
```

### Google "이 앱은 확인되지 않았습니다" 경고

Google OAuth 동의 화면이 테스트 모드일 때 표시됩니다.

- 테스트 모드: 등록된 테스트 사용자만 로그인 가능
- 프로덕션 게시: 모든 사용자 로그인 가능 (email, profile 범위는 검증 불필요)

### Kakao "이메일 동의항목" 관련 오류

Kakao 동의항목에서 이메일이 선택 동의일 때, 사용자가 이메일 제공을 거부하면 회원가입이 실패할 수 있습니다.
**카카오계정(이메일)을 필수 동의로 설정**하세요.

### 개발 환경에서 실제 OAuth가 작동하지 않음

환경변수를 설정했는데도 Mock 모드로 동작하는 경우:

1. `.env` 파일 위치가 `teovibe/` 디렉토리 안에 있는지 확인
2. 서버를 재시작 (`Ctrl+C` 후 `bin/rails server`)
3. `rails console`에서 확인:
   ```ruby
   ENV["GOOGLE_CLIENT_ID"]  # nil이면 환경변수 미로드
   ```

---

## 동작 원리 (참고)

### OAuth 인증 플로우

```
사용자 ──[소셜 로그인 버튼 클릭]──> POST /auth/google_oauth2 (또는 /auth/kakao)
                                         │
                                    OmniAuth 미들웨어
                                         │
                                    OAuth 제공자로 리다이렉트
                                         │
                                    사용자가 동의/로그인
                                         │
                                    GET /auth/:provider/callback
                                         │
                                    Omniauth::SessionsController#create
                                         │
                         ┌────────────────┼────────────────┐
                         │                │                │
                    기존 계정 있음    로그인 상태에서     신규 사용자
                         │           계정 연결              │
                    해당 유저로        connected_service   User 생성 +
                    로그인             생성               connected_service
```

### 관련 파일

| 파일 | 역할 |
|------|------|
| `config/initializers/omniauth.rb` | OmniAuth 미들웨어 설정, Mock 모드 |
| `app/controllers/omniauth/sessions_controller.rb` | OAuth 콜백 처리 |
| `app/models/connected_service.rb` | 소셜 계정 연결 정보 저장 |
| `app/models/user.rb` | 사용자 모델 |
| `app/views/shared/_auth_social.html.erb` | 소셜 로그인 버튼 UI |
| `config/routes.rb` | OAuth 콜백 라우트 정의 |
