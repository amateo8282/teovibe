---
phase: 04-commerce
plan: 02
subsystem: payments
tags: [react, toss-payments, checkout, vite, erb, typescript, turbo-drive]

# Dependency graph
requires:
  - phase: 04-commerce/04-01
    provides: CheckoutsController 스켈레톤, Order 모델, toss_order_id, payment_customer_key, 체크아웃 라우트 3개
provides:
  - CheckoutWidget.tsx: 토스페이먼츠 결제위젯 React 컴포넌트 (loadPaymentWidget/renderPaymentMethods/requestPayment)
  - checkout.jsx: 체크아웃 React 엔트리포인트 (turbo:load/turbo:before-cache 패턴)
  - checkouts/show.html.erb: 체크아웃 페이지 (React 마운트 포인트 + data attributes)
  - checkouts/success.html.erb: 결제 완료 안내 페이지
  - checkouts/fail.html.erb: 결제 실패 안내 페이지 (에러 메시지 + 재시도 링크)
affects:
  - 04-commerce/04-03 (서버사이드 confirm API, success 액션에 confirm 로직 추가)

# Tech tracking
tech-stack:
  added:
    - "@tosspayments/payment-widget-sdk 0.12.1"
  patterns:
    - loadPaymentWidget useEffect 비동기 초기화 + cleanup 플래그로 경쟁 조건 방지
    - useRef로 결제 위젯 인스턴스 관리 (React state 아닌 DOM 참조)
    - checkout.jsx의 turbo:load/turbo:before-cache 패턴 (landing.jsx와 동일)
    - data attributes로 ERB -> React props 전달 (data-client-key 등)
    - successUrl/failUrl에 _url 헬퍼 사용 (절대 URL, 토스 SDK 요구사항)

key-files:
  created:
    - teovibe/app/frontend/components/checkout/CheckoutWidget.tsx
    - teovibe/app/frontend/entrypoints/checkout.jsx
    - teovibe/app/views/checkouts/show.html.erb
    - teovibe/app/views/checkouts/success.html.erb
    - teovibe/app/views/checkouts/fail.html.erb
  modified:
    - teovibe/package.json
    - teovibe/pnpm-lock.yaml
    - teovibe/app/controllers/checkouts_controller.rb

key-decisions:
  - "CheckoutWidget.tsx의 paymentMethodsRef 타입은 any로 지정 — SDK 반환 타입이 복잡하여 인라인 타입 추출 불가"
  - "success/fail 액션을 redirect에서 render로 전환 — ERB 뷰를 실제로 활성화하기 위한 필수 변경"
  - "success.html.erb는 현재 단순 안내만 표시 — Plan 03에서 confirm 로직 추가 예정"

patterns-established:
  - "페이지별 JS 엔트리포인트: content_for :head에서 vite_javascript_tag 'checkout' 로드"
  - "React props 전달: ERB data attributes (data-client-key 등) -> checkout.jsx에서 dataset으로 추출 -> CheckoutWidget에 props 전달"
  - "turbo:load/turbo:before-cache 이중 이벤트 패턴 (landing.jsx, checkout.jsx에서 공통 사용)"

requirements-completed: [COMM-02, COMM-03]

# Metrics
duration: 5min
completed: 2026-02-22
---

# Phase 4 Plan 02: 토스페이먼츠 결제위젯 React 컴포넌트 + 체크아웃 뷰 Summary

**@tosspayments/payment-widget-sdk 기반 CheckoutWidget React 컴포넌트와 체크아웃 ERB 뷰 3개로 결제 UI 프론트엔드 완성**

## Performance

- **Duration:** 5 min
- **Started:** 2026-02-22T10:25:29Z
- **Completed:** 2026-02-22T10:30:50Z
- **Tasks:** 2
- **Files modified:** 8

## Accomplishments

- CheckoutWidget.tsx 구현 — loadPaymentWidget 비동기 초기화, renderPaymentMethods/renderAgreement UI 렌더링, requestPayment 결제 요청, useRef 인스턴스 관리
- checkout.jsx 엔트리포인트 생성 — landing.jsx와 동일한 turbo:load/turbo:before-cache 패턴, data attributes에서 props 추출
- 체크아웃 ERB 뷰 3개 생성 — show(React 마운트 포인트), success(안내 메시지), fail(에러+재시도)

## Task Commits

Each task was committed atomically:

1. **Task 1: SDK 설치 + CheckoutWidget.tsx + checkout.jsx 생성** - `7b3f292` (feat)
2. **Task 2: 체크아웃 ERB 뷰 3개 + 컨트롤러 수정** - `f5f95f5` (feat)

## Files Created/Modified

- `teovibe/app/frontend/components/checkout/CheckoutWidget.tsx` - 토스페이먼츠 결제위젯 React 컴포넌트
- `teovibe/app/frontend/entrypoints/checkout.jsx` - 체크아웃 React 엔트리포인트 (Turbo Drive 패턴)
- `teovibe/app/views/checkouts/show.html.erb` - 체크아웃 페이지 (React 마운트 포인트 + data attributes)
- `teovibe/app/views/checkouts/success.html.erb` - 결제 완료 안내 페이지 (dev 환경 debug 정보 포함)
- `teovibe/app/views/checkouts/fail.html.erb` - 결제 실패 안내 페이지 (에러 코드/메시지 + 재시도 링크)
- `teovibe/package.json` - @tosspayments/payment-widget-sdk 0.12.1 추가
- `teovibe/pnpm-lock.yaml` - lockfile 업데이트
- `teovibe/app/controllers/checkouts_controller.rb` - success/fail 액션 redirect -> render 전환

## Decisions Made

- CheckoutWidget.tsx의 paymentMethodsRef 타입을 any로 지정 — SDK 내부 반환 타입이 복잡하여 정확한 인라인 타입 추출 불가
- success/fail 액션을 redirect에서 render로 전환 — ERB 뷰 파일이 실제로 활성화되도록 필요한 변경
- success.html.erb는 현재 단순 안내만 표시 (Plan 03에서 PaymentService confirm 로직 추가 예정)

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] CheckoutsController success/fail 액션 redirect -> render 전환**
- **Found during:** Task 2 (체크아웃 ERB 뷰 생성)
- **Issue:** success/fail 액션이 redirect_to를 호출하여 새로 생성한 ERB 뷰가 렌더링되지 않음
- **Fix:** success/fail 액션 본문을 빈 render 방식으로 전환 (액션명 일치 뷰 자동 렌더링)
- **Files modified:** teovibe/app/controllers/checkouts_controller.rb
- **Verification:** ERB 구문 검사 통과, 뷰 파일 존재 확인
- **Committed in:** f5f95f5 (Task 2 commit)

---

**Total deviations:** 1 auto-fixed (1 bug)
**Impact on plan:** 필수 수정. redirect 방식이면 ERB 뷰가 절대 렌더링되지 않음. Plan 03에서 confirm 로직 추가 시 success 액션에 비즈니스 로직 추가 예정.

## Issues Encountered

- pnpm이 PATH에 없어 `/Users/jaehohan/Library/pnpm`을 명시적으로 추가하여 실행 (환경 이슈)

## User Setup Required

**토스페이먼츠 API 키 설정이 필요합니다.** 결제위젯 테스트 모드 동작을 위해:

- `rails credentials:edit`으로 아래 키 추가 필요:
  ```yaml
  toss_payments:
    client_key: test_ck_...  # 토스페이먼츠 개발자센터 -> 테스트 클라이언트 키
    secret_key: test_sk_...  # 토스페이먼츠 개발자센터 -> 테스트 시크릿 키
  ```
- 대시보드: https://developers.tosspayments.com

## Next Phase Readiness

- CheckoutWidget + 체크아웃 뷰 완성, 04-03 서버사이드 confirm API 구현 준비 완료
- CheckoutsController success 액션에 PaymentService confirm 로직 추가 필요 (Plan 03)
- 토스페이먼츠 API 키가 credentials에 설정되어야 체크아웃 페이지 정상 동작

## Self-Check: PASSED

- teovibe/app/frontend/components/checkout/CheckoutWidget.tsx: FOUND
- teovibe/app/frontend/entrypoints/checkout.jsx: FOUND
- teovibe/app/views/checkouts/show.html.erb: FOUND
- teovibe/app/views/checkouts/success.html.erb: FOUND
- teovibe/app/views/checkouts/fail.html.erb: FOUND
- Commit 7b3f292: FOUND
- Commit f5f95f5: FOUND

---
*Phase: 04-commerce*
*Completed: 2026-02-22*
