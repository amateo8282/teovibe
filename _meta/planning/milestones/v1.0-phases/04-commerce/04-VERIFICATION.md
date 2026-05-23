---
phase: 04-commerce
verified: 2026-02-22T11:00:00Z
status: passed
score: 4/4 must-haves verified
re_verification: false
---

# Phase 4: Commerce Verification Report

**Phase Goal:** 토스페이먼츠 결제 기반 구조를 완성하여 다음 마일스톤에서 실결제를 바로 활성화할 수 있는 상태를 만든다
**Verified:** 2026-02-22T11:00:00Z
**Status:** PASSED
**Re-verification:** No — initial verification

---

## Goal Achievement

### Observable Truths (from Success Criteria)

| #   | Truth                                                                                                   | Status     | Evidence                                                                                       |
| --- | ------------------------------------------------------------------------------------------------------- | ---------- | ---------------------------------------------------------------------------------------------- |
| 1   | Order 모델이 payment_event_id 유니크 인덱스를 포함하여 생성되고 pending/paid/failed/refunded 상태를 추적한다 | VERIFIED   | `20260222102017_create_orders.rb` — enum integer + `add_index :payment_event_id, unique: true, where: "payment_event_id IS NOT NULL"`. Rails runner `Order.new.pending?` => `true` |
| 2   | 스킬팩 체크아웃 페이지에서 상품 정보와 가격이 표시되고 결제 버튼이 렌더링된다                                  | VERIFIED   | `CheckoutWidget.tsx` 상품 정보 섹션(orderName, formattedAmount) + 결제하기 버튼 존재. `show.html.erb`에서 data attributes로 props 전달 |
| 3   | 토스페이먼츠 위젯이 테스트 모드로 초기화되어 결제 UI가 표시된다                                               | VERIFIED   | `CheckoutWidget.tsx` — `loadPaymentWidget(clientKey, customerKey)` useEffect 비동기 초기화, `renderPaymentMethods`/`renderAgreement` UI 렌더링 구현 |
| 4   | 결제 완료 후 서버사이드 confirm API가 호출되고 Order 상태가 업데이트된다                                       | VERIFIED   | `PaymentService#confirm` — Faraday POST `api.tosspayments.com/v1/payments/confirm`. `CheckoutsController#success` — 금액 검증 → confirm → `order.update!(status: :paid, payment_event_id: payment_key)` 또는 `status: :failed` |

**Score: 4/4 truths verified**

---

### Required Artifacts

| Artifact                                                             | Expected                                        | Status     | Details                                                  |
| -------------------------------------------------------------------- | ----------------------------------------------- | ---------- | -------------------------------------------------------- |
| `teovibe/app/models/order.rb`                                        | Order 모델 (enum, validations, toss_order_id 자동생성) | VERIFIED   | `enum :status`, `belongs_to :user`, `belongs_to :skill_pack`, `before_validation :generate_toss_order_id` 모두 존재 |
| `teovibe/app/controllers/checkouts_controller.rb`                    | CheckoutsController (show/success/fail)          | VERIFIED   | 3개 액션 완성. success에 PaymentService 호출 + Order 상태 업데이트 로직 포함 |
| `teovibe/app/services/payment_service.rb`                            | 토스페이먼츠 confirm API 호출 서비스               | VERIFIED   | `def confirm(payment_key:, order_id:, amount:)` — Faraday POST + Base64 Basic auth + 성공/실패 해시 반환 |
| `teovibe/app/frontend/components/checkout/CheckoutWidget.tsx`        | 토스페이먼츠 결제위젯 React 컴포넌트               | VERIFIED   | `loadPaymentWidget`, `renderPaymentMethods`, `renderAgreement`, `requestPayment` 모두 구현됨 |
| `teovibe/app/frontend/entrypoints/checkout.jsx`                      | 체크아웃 React 진입점 (turbo:load/turbo:before-cache) | VERIFIED   | `turbo:load` 마운트 + `turbo:before-cache` 언마운트 패턴 존재. `CheckoutWidget` import 및 렌더링 |
| `teovibe/app/views/checkouts/show.html.erb`                          | 체크아웃 페이지 (React 마운트 포인트 + data attributes) | VERIFIED   | `vite_javascript_tag 'checkout'`, `id="checkout-root"`, 7개 data attributes 모두 존재. `_url` 헬퍼 사용 (절대 URL) |
| `teovibe/app/views/checkouts/success.html.erb`                       | 결제 완료 안내 페이지 (로딩 중 스피너)              | VERIFIED   | 로딩 스피너 렌더링. confirm 성공 후 즉시 리다이렉트되므로 스피너 용도가 적절 |
| `teovibe/app/views/checkouts/fail.html.erb`                          | 결제 실패 안내 + 재시도 링크                        | VERIFIED   | `params[:message]`, `params[:code]` 표시. 재시도 버튼 + 목록 링크 존재 |
| `teovibe/db/migrate/20260222102017_create_orders.rb`                 | orders 테이블 + unique index                      | VERIFIED   | `toss_order_id unique: true`, `payment_event_id unique: true, where: "payment_event_id IS NOT NULL"`, `status index` 포함 |
| `teovibe/db/migrate/20260222102044_add_price_to_skill_packs.rb`      | SkillPack price 컬럼                              | VERIFIED   | `SkillPack.column_names.include?('price')` => `true`. 마이그레이션 상태 `up` |
| `teovibe/db/migrate/20260222102056_add_payment_customer_key_to_users.rb` | User payment_customer_key 컬럼              | VERIFIED   | `User.column_names.include?('payment_customer_key')` => `true`. 마이그레이션 상태 `up` |

---

### Key Link Verification

| From                                   | To                                             | Via                          | Status     | Details                                                                      |
| -------------------------------------- | ---------------------------------------------- | ---------------------------- | ---------- | ---------------------------------------------------------------------------- |
| `order.rb`                             | `user.rb`                                      | `belongs_to :user`           | WIRED      | `belongs_to :user` line 2, `user.rb` has `has_many :orders, dependent: :destroy` line 11 |
| `order.rb`                             | `skill_pack.rb`                                | `belongs_to :skill_pack`     | WIRED      | `belongs_to :skill_pack` line 3, `skill_pack.rb` has `has_many :orders, dependent: :destroy` line 5 |
| `checkout.jsx`                         | `CheckoutWidget.tsx`                           | `import CheckoutWidget`      | WIRED      | `import CheckoutWidget from "../components/checkout/CheckoutWidget"` line 2. `root.render(<CheckoutWidget .../>)` 렌더링 |
| `show.html.erb`                        | `checkout.jsx`                                 | `vite_javascript_tag 'checkout'` | WIRED  | `content_for :head` 블록 내 `vite_javascript_tag 'checkout'` line 5         |
| `CheckoutWidget.tsx`                   | `@tosspayments/payment-widget-sdk`             | `loadPaymentWidget import`   | WIRED      | `import { loadPaymentWidget } from "@tosspayments/payment-widget-sdk"` line 1. `package.json` 에 `"^0.12.1"` 등록 |
| `checkouts_controller.rb`             | `payment_service.rb`                           | `PaymentService.new.confirm` | WIRED      | `service = PaymentService.new(secret_key)` line 54, `service.confirm(...)` line 55 |
| `payment_service.rb`                   | `https://api.tosspayments.com/v1/payments/confirm` | Faraday POST             | WIRED      | `TOSS_CONFIRM_URL = "https://api.tosspayments.com/v1/payments/confirm"` line 6. `conn.post(TOSS_CONFIRM_URL)` line 27 |
| `checkouts_controller.rb`             | `order.rb`                                     | `order.update!(status: :paid, payment_event_id:)` | WIRED | Line 59: `order.update!(status: :paid, payment_event_id: payment_key)`. Line 65: `order.update!(status: :failed)` |

---

### Requirements Coverage

| Requirement | Source Plan | Description                                                              | Status    | Evidence                                                             |
| ----------- | ----------- | ------------------------------------------------------------------------ | --------- | -------------------------------------------------------------------- |
| COMM-01     | 04-01-PLAN  | Order 모델과 결제 상태 관리 스키마를 구축한다 (pending/paid/failed/refunded) | SATISFIED | Order 모델 enum, toss_order_id/payment_event_id unique index, 3개 마이그레이션 모두 `up` 상태 |
| COMM-02     | 04-02-PLAN  | 스킬팩 체크아웃 페이지 UI를 구현한다 (상품 정보, 가격, 결제 버튼)               | SATISFIED | `show.html.erb` + `CheckoutWidget.tsx` — 상품명/가격 표시, 결제하기 버튼, fail.html.erb 재시도 링크 |
| COMM-03     | 04-02-PLAN  | 토스페이먼츠 SDK 초기화와 결제 위젯 연동 기반을 마련한다                        | SATISFIED | `@tosspayments/payment-widget-sdk 0.12.1` 설치, `loadPaymentWidget` 비동기 초기화, `renderPaymentMethods`/`renderAgreement` 호출 |
| COMM-04     | 04-03-PLAN  | 서버사이드 결제 확인(confirm) API 엔드포인트를 구현한다                        | SATISFIED | `PaymentService#confirm` Faraday POST + `CheckoutsController#success` 금액 검증 → confirm → Order 상태 업데이트 전체 흐름 완성 |

모든 4개 요구사항이 해당 플랜에서 선언되고 구현되었음. 고아 요구사항 없음.

---

### Anti-Patterns Found

| File | Line | Pattern | Severity | Impact |
| ---- | ---- | ------- | -------- | ------ |
| 없음 | - | - | - | - |

스캔 대상 파일 전체(order.rb, checkouts_controller.rb, payment_service.rb, CheckoutWidget.tsx, checkout.jsx)에서 TODO/FIXME/PLACEHOLDER/placeholder/return nil/return {}/ 빈 구현 패턴 발견 없음.

---

### Commit Verification

6개 커밋 모두 실제 git 히스토리에서 확인됨:

| Commit  | Description                                         |
| ------- | --------------------------------------------------- |
| 1acd844 | feat(04-01): Order 모델 + 결제 관련 DB 스키마 구축     |
| 97e724f | feat(04-01): 체크아웃 라우트 + CheckoutsController 스켈레톤 생성 |
| 7b3f292 | feat(04-02): 토스페이먼츠 SDK 설치 + CheckoutWidget + checkout.jsx 엔트리포인트 생성 |
| f5f95f5 | feat(04-02): 체크아웃 ERB 뷰 3개 생성 + success/fail 액션 render 방식 전환 |
| 03cda8b | feat(04-03): PaymentService 구현 - 토스페이먼츠 confirm API Faraday 호출 |
| 78b1c44 | feat(04-03): CheckoutsController#success confirm 로직 완성 |

---

### Human Verification Required

#### 1. 결제 위젯 실제 렌더링 확인

**Test:** 토스페이먼츠 테스트 키(`test_ck_...`)를 `rails credentials:edit`으로 설정 후, 유료 스킬팩의 체크아웃 URL(`/skill_packs/:id/checkout`)에 로그인 상태로 접속한다.
**Expected:** 결제 수단 UI(카드, 계좌이체 등)와 약관 동의 UI가 렌더링된다.
**Why human:** 위젯 초기화는 브라우저에서 실제 API 키로만 확인 가능. 테스트 모드 `clientKey`가 credentials에 없으면 위젯이 에러를 반환할 수 있다.

#### 2. 결제하기 버튼 클릭 -> requestPayment 흐름

**Test:** 결제 위젯이 렌더링된 상태에서 "결제하기" 버튼을 클릭한다.
**Expected:** 토스페이먼츠 결제 팝업 또는 인앱 결제 UI가 활성화된다.
**Why human:** `requestPayment` 호출 성공 여부는 실제 브라우저 + SDK 로드 상태에 따라 결정된다.

#### 3. 테스트 결제 완료 -> confirm -> paid 상태 전환

**Test:** 토스페이먼츠 테스트 카드로 결제를 완료한다.
**Expected:** `success` URL로 리다이렉트 후 서버사이드 confirm이 호출되고, Order의 status가 `paid`로 업데이트되며, 스킬팩 상세 페이지로 리다이렉트 후 "결제가 완료되었습니다." 플래시 메시지가 표시된다.
**Why human:** 실제 HTTP 흐름(토스 서버 -> confirm API -> DB 업데이트)은 통합 실행 없이 확인 불가. 테스트 시크릿 키(`test_sk_...`) credentials 설정 필요.

---

### Gaps Summary

갭 없음. 모든 4개 Success Criteria가 코드베이스에서 완전히 구현되었음.

- Order 모델: enum, unique index, before_validation 자동생성, belongs_to 관계 모두 실동작 확인 (`bin/rails runner` 테스트 통과)
- 체크아웃 페이지: React 마운트 포인트, data attributes, 상품 정보, 결제 버튼 완성
- 토스페이먼츠 위젯: SDK import, loadPaymentWidget, renderPaymentMethods, requestPayment 완성
- 서버사이드 confirm: PaymentService Faraday POST, 금액 검증, Order 상태 업데이트 완성

실결제 테스트를 위해서는 `rails credentials:edit`으로 `toss_payments.client_key` 및 `toss_payments.secret_key` 설정이 필요하나, 이는 인프라 설정 사항이며 코드 구현 완성도와는 별개이다.

---

_Verified: 2026-02-22T11:00:00Z_
_Verifier: Claude (gsd-verifier)_
