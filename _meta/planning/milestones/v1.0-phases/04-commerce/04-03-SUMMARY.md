---
phase: 04-commerce
plan: 03
subsystem: payments
tags: [rails, faraday, toss-payments, confirm-api, payment-service, order, clean-architecture]

# Dependency graph
requires:
  - phase: 04-commerce/04-01
    provides: Order 모델, CheckoutsController 스켈레톤, toss_order_id, payment_event_id 컬럼
  - phase: 04-commerce/04-02
    provides: CheckoutWidget React 컴포넌트, checkouts success/fail ERB 뷰, 체크아웃 라우트 3개
provides:
  - PaymentService: 토스페이먼츠 confirm API Faraday HTTP 호출 서비스 클래스 (success: true/false 반환)
  - CheckoutsController#success: 서버사이드 confirm 로직 (금액 검증 -> confirm -> Order 상태 업데이트 -> 다운로드 권한 부여)
  - 결제 완료 흐름 완성: requestPayment 성공 -> success 액션 -> confirm -> paid 상태 + 다운로드 권한
affects: []

# Tech tracking
tech-stack:
  added: []
  patterns:
    - PaymentService 서비스 클래스 패턴 (app/services/)
    - Base64.strict_encode64("#{secret_key}:") Basic auth 인코딩
    - Faraday request :json + response :json + response :raise_error 미들웨어 스택
    - 서버사이드 금액 검증: params[:amount].to_i != order.amount 비교 후 거부
    - credentials nil 방어: blank? 체크 + Rails.logger.error 후 실패 처리

key-files:
  created:
    - teovibe/app/services/payment_service.rb
  modified:
    - teovibe/app/controllers/checkouts_controller.rb
    - teovibe/app/views/checkouts/success.html.erb

key-decisions:
  - "faraday gem은 이미 설치되어 있었음 (bundle add 불필요) — bundle list 확인으로 선행 설치 감지"
  - "success 액션은 confirm 성공 후 skill_pack_path로 즉시 리다이렉트 — success.html.erb는 로딩 중 스피너 표시용 (거의 보이지 않음)"
  - "secret_key nil 방어를 PaymentService 외부(컨트롤러)에서 처리 — 서비스 클래스는 key를 받아 사용만 함"

patterns-established:
  - "PaymentService: initialize(secret_key) + confirm(payment_key:, order_id:, amount:) 인터페이스"
  - "confirm 결과: { success: true, data: } / { success: false, error: } 해시 반환 패턴"
  - "결제 흐름: 금액 검증 -> secret_key 검증 -> confirm 호출 -> 성공/실패 분기"

requirements-completed: [COMM-04]

# Metrics
duration: 2min
completed: 2026-02-22
---

# Phase 4 Plan 03: 토스페이먼츠 서버사이드 confirm API Summary

**Faraday 기반 PaymentService + CheckoutsController#success confirm 로직으로 결제 위젯 -> 서버사이드 확인 -> Order paid 전환 + 다운로드 권한 부여 흐름 완성**

## Performance

- **Duration:** 2 min
- **Started:** 2026-02-22T10:33:50Z
- **Completed:** 2026-02-22T10:35:07Z
- **Tasks:** 2
- **Files modified:** 3

## Accomplishments

- PaymentService 구현 — Faraday로 토스페이먼츠 confirm API(POST) 호출, Basic auth base64 인코딩, 성공/실패 해시 반환, Faraday::Error rescue
- CheckoutsController#success 완성 — 금액 위변조 방지 검증, secret_key nil 방어, confirm 호출, Order paid/failed 업데이트, 다운로드 권한 부여, ActiveRecord::RecordNotFound rescue
- success.html.erb 업데이트 — 개발 환경 debug 정보 제거, 로딩 스피너로 교체 (confirm 성공 후 즉시 리다이렉트되므로 거의 보이지 않음)

## Task Commits

Each task was committed atomically:

1. **Task 1: PaymentService 구현** - `03cda8b` (feat)
2. **Task 2: CheckoutsController#success confirm 로직 완성 + success 뷰 업데이트** - `78b1c44` (feat)

## Files Created/Modified

- `teovibe/app/services/payment_service.rb` - 토스페이먼츠 confirm API Faraday 호출 서비스 클래스
- `teovibe/app/controllers/checkouts_controller.rb` - success 액션에 confirm 로직 완성 (금액 검증, PaymentService 호출, Order 상태 업데이트)
- `teovibe/app/views/checkouts/success.html.erb` - 개발 환경 debug 제거, 로딩 스피너로 교체

## Decisions Made

- faraday gem이 이미 설치되어 있어 bundle add가 불필요했음 — 기존에 다른 의존성에 의해 설치됨
- success 액션에서 confirm 성공 후 바로 skill_pack_path로 리다이렉트 — success.html.erb는 처리 중 잠깐 보이는 로딩 화면 용도
- secret_key nil 체크를 컨트롤러에서 수행 — PaymentService는 단순 키 수신/사용, nil 방어 책임은 호출자가 담당

## Deviations from Plan

None - plan executed exactly as written. (faraday가 이미 설치되어 있어 bundle add 단계 생략됨 — 기능적으로 동일)

## Issues Encountered

None

## User Setup Required

**토스페이먼츠 API 키 설정이 필요합니다.** confirm API 동작을 위해:

- `rails credentials:edit`으로 아래 키 추가 필요:
  ```yaml
  toss_payments:
    client_key: test_ck_...  # 토스페이먼츠 개발자센터 -> 테스트 클라이언트 키
    secret_key: test_sk_...  # 토스페이먼츠 개발자센터 -> 테스트 시크릿 키
  ```
- 대시보드: https://developers.tosspayments.com
- secret_key가 없으면 confirm 호출이 실패 처리됨 (에러 로그 + failed 상태)

## Next Phase Readiness

- Phase 4 Commerce 완성: Order 모델 + 결제위젯 React 컴포넌트 + 서버사이드 confirm 전체 흐름 완성
- 실결제 테스트를 위해서는 토스페이먼츠 개발자센터에서 테스트 키 발급 후 credentials 설정 필요
- Phase 5 이후: 토스페이먼츠 웹훅 서명 검증(HMAC), 환불 API, SDK v2 마이그레이션 고려

## Self-Check: PASSED

- teovibe/app/services/payment_service.rb: FOUND
- teovibe/app/controllers/checkouts_controller.rb: FOUND
- teovibe/app/views/checkouts/success.html.erb: FOUND
- Commit 03cda8b: FOUND
- Commit 78b1c44: FOUND

---
*Phase: 04-commerce*
*Completed: 2026-02-22*
