# Phase 4: Commerce - Research

**Researched:** 2026-02-22
**Domain:** 토스페이먼츠 결제 위젯 연동, Rails Order 모델, React 체크아웃 UI
**Confidence:** HIGH (토스페이먼츠 공식 문서 + npm 패키지 직접 확인)

---

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|-----------------|
| COMM-01 | Order 모델과 결제 상태 관리 스키마를 구축한다 (pending/paid/failed/refunded) | Rails migration 패턴, payment_event_id unique index, enum 상태 관리 |
| COMM-02 | 스킬팩 체크아웃 페이지 UI를 구현한다 (상품 정보, 가격, 결제 버튼) | SkillPack 모델에 price 컬럼 추가, CheckoutsController + 뷰 신규 생성 |
| COMM-03 | 토스페이먼츠 SDK 초기화와 결제 위젯 연동 기반을 마련한다 | @tosspayments/payment-widget-sdk npm 패키지, React 훅 패턴 |
| COMM-04 | 서버사이드 결제 확인(confirm) API 엔드포인트를 구현한다 | POST https://api.tosspayments.com/v1/payments/confirm, Faraday HTTP 호출 |
</phase_requirements>

---

## Summary

Phase 4는 토스페이먼츠 결제 위젯을 Rails 앱에 연동하는 작업이다. 프론트엔드는 npm 패키지 `@tosspayments/payment-widget-sdk`를 통해 결제 UI를 렌더링하고, 백엔드는 Faraday로 토스페이먼츠 confirm API를 직접 호출한다. 공식 Ruby gem이 없으므로 Faraday 직접 호출이 유일한 선택지이며, 이는 PROJECT.md에 이미 결정된 사항이다.

현재 SkillPack 모델에는 `price` 컬럼이 없다. 체크아웃 기능을 위해 `price_cents` (integer, 원 단위) 또는 `price` (integer) 컬럼을 추가해야 한다. Order 모델은 신규 생성이 필요하며, `payment_event_id` (토스페이먼츠의 `paymentKey`)에 유니크 인덱스를 걸어 멱등성을 보장해야 한다.

토스페이먼츠 SDK v2 (`@tosspayments/tosspayments-sdk`)가 최신이지만, 기존 결제위젯 전용 SDK `@tosspayments/payment-widget-sdk` (v1)도 여전히 동작한다. 두 패키지 모두 현재 활성화 상태이며 API(서버사이드 confirm 엔드포인트)는 동일하다. 이 Phase에서는 `@tosspayments/payment-widget-sdk`로 구현한다. (v2 마이그레이션은 다음 마일스톤 검토 대상)

**Primary recommendation:** `@tosspayments/payment-widget-sdk`로 결제위젯을 React 컴포넌트에 구현하고, CheckoutsController + PaymentService로 서버사이드 confirm을 처리하라.

---

## Standard Stack

### Core

| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| `@tosspayments/payment-widget-sdk` | latest (npm) | 결제위젯 초기화, renderPaymentMethods, requestPayment | 토스페이먼츠 공식 SDK, 결제위젯 전용 |
| `faraday` gem | 추가 필요 | 토스페이먼츠 confirm API HTTP 호출 | PROJECT.md 결정: 공식 Ruby gem 없음, Faraday 직접 호출 |
| Rails `enum` | Rails 내장 | Order 상태 (pending/paid/failed/refunded) | 표준 Rails 패턴 |
| Rails migration | Rails 내장 | Order 테이블 + payment_event_id unique index | 표준 Rails 패턴 |

### Supporting

| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| `@tosspayments/tosspayments-sdk` | 2.5.0 | SDK v2 (통합 버전) | v2로 마이그레이션 시 사용. 이번 Phase에서는 불필요 |
| React `useRef` | React 내장 | 결제 위젯 인스턴스 보관 | 위젯 인스턴스가 React state가 아니라 DOM 참조이므로 useRef 사용 |
| React `useEffect` | React 내장 | 위젯 초기화 (마운트 후 실행) | 비동기 SDK 로드는 반드시 useEffect 내에서 |

### Alternatives Considered

| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| `@tosspayments/payment-widget-sdk` | `@tosspayments/tosspayments-sdk` v2 | v2는 API 동일하나 결제위젯 초기화 방식이 다름 (tossPayments.widgets()). 이번 Phase에서는 v1 유지 |
| Faraday | Net::HTTP | Net::HTTP는 표준 라이브러리지만 Faraday가 테스트 mocking, 미들웨어 지원 더 좋음 |
| Faraday | httparty | 프로젝트에 Gemfile 없음. Faraday가 Rails 생태계 표준 |

**Installation:**

```bash
# Frontend (프로젝트 루트의 pnpm)
pnpm add @tosspayments/payment-widget-sdk

# Backend (Gemfile에 추가 후)
bundle add faraday
```

---

## Architecture Patterns

### Recommended Project Structure

```
teovibe/
├── app/
│   ├── models/
│   │   └── order.rb                    # 신규: Order 모델 (pending/paid/failed/refunded enum)
│   ├── controllers/
│   │   ├── checkouts_controller.rb     # 신규: show(체크아웃 페이지), success, fail
│   │   └── api/v1/
│   │       └── payments_controller.rb  # 신규: confirm 액션 (POST /api/v1/payments/confirm)
│   ├── services/
│   │   └── payment_service.rb          # 신규: 토스페이먼츠 confirm API 호출 로직
│   ├── views/
│   │   └── checkouts/
│   │       ├── show.html.erb           # 체크아웃 페이지 (React 마운트 포인트 포함)
│   │       ├── success.html.erb        # 결제 완료 (orderId, paymentKey, amount 수신)
│   │       └── fail.html.erb           # 결제 실패
│   └── frontend/
│       ├── entrypoints/
│       │   └── checkout.jsx            # 신규: React 체크아웃 엔트리포인트
│       └── components/
│           └── checkout/
│               └── CheckoutWidget.tsx  # 신규: 결제위젯 React 컴포넌트
└── db/migrate/
    ├── XXXXXX_create_orders.rb         # 신규
    └── XXXXXX_add_price_to_skill_packs.rb  # 신규
```

### Pattern 1: Order 모델 + payment_event_id 멱등성

**What:** Order는 SkillPack 구매를 추적하며, `payment_event_id`는 토스페이먼츠의 `paymentKey`를 저장한다. 유니크 인덱스로 중복 확인 방지.

**When to use:** 결제 confirm이 네트워크 오류로 중복 호출될 수 있으므로 DB 레벨 유니크 보장 필수.

**Migration 예시:**
```ruby
# Source: ActiveRecord Migration standard pattern
class CreateOrders < ActiveRecord::Migration[8.1]
  def change
    create_table :orders do |t|
      t.references :user, null: false, foreign_key: true
      t.references :skill_pack, null: false, foreign_key: true
      t.integer :status, default: 0, null: false      # enum: pending/paid/failed/refunded
      t.string :toss_order_id, null: false            # 우리가 생성하는 orderId
      t.string :payment_event_id                      # 토스의 paymentKey (결제 완료 후 저장)
      t.integer :amount, null: false                  # 결제 금액 (원 단위)

      t.timestamps
    end

    add_index :orders, :toss_order_id, unique: true
    add_index :orders, :payment_event_id, unique: true, where: "payment_event_id IS NOT NULL"
    add_index :orders, :status
  end
end
```

**Order 모델 예시:**
```ruby
# app/models/order.rb
class Order < ApplicationRecord
  belongs_to :user
  belongs_to :skill_pack

  enum :status, { pending: 0, paid: 1, failed: 2, refunded: 3 }

  validates :toss_order_id, presence: true, uniqueness: true
  validates :amount, presence: true, numericality: { greater_than: 0 }

  before_validation :generate_toss_order_id, on: :create

  private

  def generate_toss_order_id
    # 토스페이먼츠 orderId 규칙: 6~64자, 영문/숫자/-/_
    self.toss_order_id ||= "order-#{SecureRandom.urlsafe_base64(16)}"
  end
end
```

### Pattern 2: 토스페이먼츠 결제위젯 React 컴포넌트

**What:** `loadPaymentWidget`을 useEffect 내 비동기로 호출하고, 인스턴스를 `useRef`에 저장. 결제 버튼 클릭 시 `requestPayment` 호출.

**When to use:** Rails ERB 뷰에 `<div id="checkout-root">` 마운트 포인트를 만들고, `content_for :head`로 checkout.jsx 엔트리포인트 로드.

**React 컴포넌트 패턴:**
```typescript
// Source: TossPayments 공식 블로그 (paytech-4), docs.tosspayments.com/en/integration-widget
import { loadPaymentWidget } from "@tosspayments/payment-widget-sdk"
import { useEffect, useRef } from "react"

interface CheckoutWidgetProps {
  clientKey: string
  customerKey: string
  orderId: string
  orderName: string
  amount: number
  successUrl: string
  failUrl: string
}

export function CheckoutWidget({
  clientKey, customerKey, orderId, orderName, amount, successUrl, failUrl
}: CheckoutWidgetProps) {
  const paymentWidgetRef = useRef(null)
  const paymentMethodsRef = useRef(null)

  useEffect(() => {
    let cleanup = false
    ;(async () => {
      const paymentWidget = await loadPaymentWidget(clientKey, customerKey)
      if (cleanup) return
      const paymentMethods = paymentWidget.renderPaymentMethods(
        "#payment-method",
        { value: amount, currency: "KRW", country: "KR" }
      )
      paymentWidget.renderAgreement("#agreement", { variantKey: "AGREEMENT" })
      paymentWidgetRef.current = paymentWidget
      paymentMethodsRef.current = paymentMethods
    })()
    return () => { cleanup = true }
  }, [])

  const handlePayment = async () => {
    try {
      await paymentWidgetRef.current?.requestPayment({
        orderId,
        orderName,
        successUrl,
        failUrl,
      })
    } catch (error) {
      console.error("결제 요청 실패:", error)
    }
  }

  return (
    <div>
      <div id="payment-method" />
      <div id="agreement" />
      <button onClick={handlePayment}>결제하기</button>
    </div>
  )
}
```

### Pattern 3: 서버사이드 PaymentService (Faraday)

**What:** Rails 서비스 클래스가 토스페이먼츠 confirm 엔드포인트를 Faraday로 호출. Basic auth는 `secret_key:`를 base64 인코딩.

**confirm 엔드포인트:**
- URL: `POST https://api.tosspayments.com/v1/payments/confirm`
- Auth: `Authorization: Basic #{Base64.strict_encode64("#{secret_key}:")}`
- Body: `{ paymentKey:, orderId:, amount: }`
- 성공 응답: HTTP 200, Payment 객체

**서비스 클래스 패턴:**
```ruby
# app/services/payment_service.rb
# Source: TossPayments 공식 문서 (docs.tosspayments.com/en/api-guide)
require "base64"

class PaymentService
  TOSS_CONFIRM_URL = "https://api.tosspayments.com/v1/payments/confirm"

  def initialize(secret_key)
    @secret_key = secret_key
  end

  def confirm(payment_key:, order_id:, amount:)
    conn = Faraday.new do |f|
      f.request :json
      f.response :json
      f.response :raise_error
    end

    encoded = Base64.strict_encode64("#{@secret_key}:")
    response = conn.post(TOSS_CONFIRM_URL) do |req|
      req.headers["Authorization"] = "Basic #{encoded}"
      req.headers["Content-Type"] = "application/json"
      req.body = { paymentKey: payment_key, orderId: order_id, amount: amount }.to_json
    end

    { success: true, data: response.body }
  rescue Faraday::Error => e
    { success: false, error: e.message }
  end
end
```

### Pattern 4: Checkout 흐름 (Rails 라우트 + 뷰)

**결제 흐름:**
```
[SkillPack#show] 구매 버튼 클릭
    -> GET /skill_packs/:id/checkout    (CheckoutsController#show)
       React 체크아웃 컴포넌트 렌더링, 위젯 초기화
    -> requestPayment() 호출
    -> 결제 성공 시 리다이렉트:
       GET /skill_packs/:id/checkout/success?paymentKey=...&orderId=...&amount=...
       (CheckoutsController#success) -> Rails에서 서버사이드 confirm 호출
    -> 결제 실패 시:
       GET /skill_packs/:id/checkout/fail?code=...&message=...
       (CheckoutsController#fail)
```

**successUrl / failUrl 패턴:**
```ruby
# successUrl은 절대 URL이어야 함
success_url = checkout_success_url(skill_pack_id: @skill_pack.id)
fail_url = checkout_fail_url(skill_pack_id: @skill_pack.id)
```

**Rails 라우트:**
```ruby
resources :skill_packs, only: [:index, :show] do
  member do
    get :download
    get "checkout", to: "checkouts#show", as: :checkout
    get "checkout/success", to: "checkouts#success", as: :checkout_success
    get "checkout/fail", to: "checkouts#fail", as: :checkout_fail
  end
end
```

### Anti-Patterns to Avoid

- **결제 위젯을 useEffect 밖에서 초기화:** `loadPaymentWidget`은 비동기 함수이므로 반드시 useEffect 내에서 await로 호출해야 함
- **amount를 프론트엔드에서만 검증:** 서버사이드 confirm 시 DB에 저장된 Order의 amount와 반드시 대조해야 함 (금액 위변조 방지)
- **payment_event_id 없이 Order 완료 처리:** paymentKey가 없으면 환불/조회 불가. confirm 응답에서 반드시 저장
- **secret_key를 프론트엔드에 노출:** clientKey(test_ck_)만 프론트엔드에 전달. secret_key(test_sk_)는 서버에만
- **OrderId 재사용:** 토스페이먼츠 orderId는 결제마다 유일해야 함. 실패한 결제라도 새 orderId 생성

---

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| 결제 UI 렌더링 | 직접 카드/계좌 입력 폼 | `@tosspayments/payment-widget-sdk` | PCI DSS 컴플라이언스, 다양한 결제수단 자동 지원 |
| Base64 인코딩 | 커스텀 인코딩 | Ruby `Base64.strict_encode64` | 표준 라이브러리 내장 |
| HTTP 클라이언트 | 직접 Net::HTTP | `faraday` gem | 미들웨어, 에러 처리, 테스트 mocking 용이 |
| orderId 생성 | 순차 번호 | `SecureRandom.urlsafe_base64` | 토스페이먼츠 정책: 예측 불가능한 값 권장 |

**Key insight:** 결제 UI는 절대 직접 만들지 말 것. 카드 정보 직접 수집은 PCI DSS 인증 문제. 토스페이먼츠 위젯이 모든 복잡성을 처리함.

---

## Common Pitfalls

### Pitfall 1: amount 위변조 (금액 불일치)

**What goes wrong:** 프론트엔드에서 amount를 조작하여 실제보다 낮은 금액으로 결제 요청
**Why it happens:** 토스페이먼츠는 프론트에서 전달한 amount를 그대로 과금함
**How to avoid:** 서버사이드 confirm 시 `params[:amount].to_i == order.amount` 검증 후 불일치 시 confirm 호출 거부
**Warning signs:** `amount` 파라미터가 DB Order와 일치하지 않는 경우

### Pitfall 2: toss_order_id 중복

**What goes wrong:** 네트워크 오류 후 재시도 시 같은 orderId로 새 결제 생성
**Why it happens:** 결제 중 새로고침이나 재시도 시 중복 Order 생성 가능
**How to avoid:** `toss_order_id`에 DB unique index + `validates :toss_order_id, uniqueness: true`. 또한 `pending` 상태의 기존 Order가 있으면 재사용하는 로직 검토
**Warning signs:** ActiveRecord::RecordNotUnique 예외 발생

### Pitfall 3: payment_event_id (paymentKey) 미저장

**What goes wrong:** 결제 완료 후 paymentKey를 Order에 저장하지 않으면 환불 API 호출 불가
**Why it happens:** confirm 응답에서 paymentKey를 별도로 저장하지 않음
**How to avoid:** confirm 성공 후 반드시 `order.update!(payment_event_id: payment_key, status: :paid)` 실행
**Warning signs:** Order가 paid 상태인데 payment_event_id가 nil

### Pitfall 4: successUrl이 상대경로

**What goes wrong:** 토스페이먼츠 SDK가 상대경로 successUrl을 처리하지 못함
**Why it happens:** Rails URL helper를 `_path`로 사용하면 상대경로 반환
**How to avoid:** 반드시 `_url` 헬퍼 사용 (절대 URL). 또는 `"#{request.base_url}/..."`로 조합
**Warning signs:** 결제 완료 후 success 페이지로 리다이렉트되지 않음

### Pitfall 5: Turbo Drive와 React 위젯 충돌

**What goes wrong:** 체크아웃 페이지에서 Turbo Drive가 활성화되면 React 위젯이 마운트/언마운트 타이밍 문제
**Why it happens:** 기존 landing.jsx 패턴과 동일한 문제 (turbo:load + turbo:before-cache 처리 필요)
**How to avoid:** checkout.jsx 엔트리포인트도 `turbo:load` / `turbo:before-cache` 패턴 적용 (landing.jsx 참고)
**Warning signs:** 결제 위젯이 페이지 재방문 시 두 번 초기화됨

### Pitfall 6: 테스트 모드 customerKey

**What goes wrong:** 로그인한 사용자의 email을 customerKey로 사용하면 보안 위험
**Why it happens:** customerKey에 예측 가능한 값 사용 금지 (토스페이먼츠 공식 정책)
**How to avoid:** `customerKey = SecureRandom.urlsafe_base64(16)` 또는 User 모델에 `payment_customer_key` UUID 컬럼 추가 (한 번 생성 후 재사용)
**Warning signs:** customerKey가 이메일, ID 등 예측 가능한 값

---

## Code Examples

Verified patterns from official sources:

### 토스페이먼츠 SDK 초기화 (React, TypeScript)
```typescript
// Source: docs.tosspayments.com/en/integration-widget + TossPayments 공식 블로그
import { loadPaymentWidget } from "@tosspayments/payment-widget-sdk"

const TEST_CLIENT_KEY = "test_ck_D5GePWvyJnrK0W0k6q8gLzN97Eoq"

const paymentWidget = await loadPaymentWidget(TEST_CLIENT_KEY, customerKey)

await paymentWidget.renderPaymentMethods(
  "#payment-method",
  { value: 50000, currency: "KRW", country: "KR" }
)

await paymentWidget.renderAgreement("#agreement", { variantKey: "AGREEMENT" })

// 결제 요청
await paymentWidget.requestPayment({
  orderId: "order-abc123",           // 6~64자, 영문/숫자/-/_
  orderName: "React 컴포넌트 스킬팩",
  successUrl: "https://example.com/checkout/success",
  failUrl: "https://example.com/checkout/fail",
})
```

### 서버사이드 confirm API 호출 (Ruby/Faraday)
```ruby
# Source: TossPayments 공식 문서 (confirm 엔드포인트 curl 예시 기반)
# POST https://api.tosspayments.com/v1/payments/confirm
# Authorization: Basic #{Base64.strict_encode64("#{SECRET_KEY}:")}

require "base64"

encoded = Base64.strict_encode64("test_sk_D4yKeq5bgrpKRd9wXY3jrGz49bNw:")

conn = Faraday.new("https://api.tosspayments.com") do |f|
  f.request :json
  f.response :json
end

response = conn.post("/v1/payments/confirm") do |req|
  req.headers["Authorization"] = "Basic #{encoded}"
  req.body = {
    paymentKey: "P5qJ5TLLWt-yD51UZrpD6",
    orderId: "Rjbb0lCkPeGe56cw-JmUk",
    amount: 15000
  }
end
```

### Rails CheckoutsController 패턴
```ruby
# app/controllers/checkouts_controller.rb
class CheckoutsController < ApplicationController
  before_action :require_authentication
  before_action :set_skill_pack

  def show
    # pending Order를 생성하거나 기존 pending Order 재사용
    @order = Order.find_or_create_by(
      user: Current.user,
      skill_pack: @skill_pack,
      status: :pending
    ) do |o|
      o.amount = @skill_pack.price
    end
  end

  def success
    payment_key = params[:paymentKey]
    order_id = params[:orderId]
    amount = params[:amount].to_i

    order = Order.find_by!(toss_order_id: order_id, user: Current.user)

    # 금액 검증
    if order.amount != amount
      redirect_to fail_skill_pack_checkout_path(@skill_pack), alert: "금액이 일치하지 않습니다."
      return
    end

    service = PaymentService.new(Rails.application.credentials.toss_payments_secret_key)
    result = service.confirm(payment_key: payment_key, order_id: order_id, amount: amount)

    if result[:success]
      order.update!(status: :paid, payment_event_id: payment_key)
      # 다운로드 권한 부여
      @skill_pack.downloads.find_or_create_by(user: Current.user)
      redirect_to skill_pack_path(@skill_pack), notice: "결제가 완료되었습니다."
    else
      order.update!(status: :failed)
      redirect_to fail_skill_pack_checkout_path(@skill_pack)
    end
  end

  def fail
    # 실패 페이지
  end

  private

  def set_skill_pack
    @skill_pack = SkillPack.published.find(params[:skill_pack_id])
  end
end
```

### SkillPack에 price 컬럼 추가
```ruby
# db/migrate/XXXXXX_add_price_to_skill_packs.rb
class AddPriceToSkillPacks < ActiveRecord::Migration[8.1]
  def change
    add_column :skill_packs, :price, :integer, default: 0, null: false
    # price = 0이면 무료, 0 초과이면 유료
  end
end
```

### credentials 설정
```bash
# config/credentials.yml.enc에 추가 (rails credentials:edit)
toss_payments:
  client_key: test_ck_D5GePWvyJnrK0W0k6q8gLzN97Eoq
  secret_key: test_sk_D4yKeq5bgrpKRd9wXY3jrGz49bNw
```

---

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| `@tosspayments/payment-widget-sdk` (v1) | `@tosspayments/tosspayments-sdk` (v2) | 2024년 SDK v2 출시 | API(서버사이드) 변경 없음. 클라이언트 초기화만 다름 |
| `loadPaymentWidget()` (v1) | `tossPayments.widgets()` (v2) | v2 전환 시 | v2에서는 `loadTossPayments()` → `.widgets()` 체인 |
| `renderPaymentMethods(selector, amount)` | `setAmount()` 분리 후 `renderPaymentMethods()` | v2 | v2에서 amount 설정이 별도 메서드로 분리됨 |

**Deprecated/outdated:**
- v1 SDK `updateAmount()`: v2에서 제거됨. v2에서는 `widgets.setAmount()` 재호출
- v1 SDK `on('ready', ...)`: v2에서 제거됨

---

## Open Questions

1. **SkillPack price 컬럼 단위**
   - What we know: 토스페이먼츠 amount는 원 단위 integer
   - What's unclear: `price` (정수, 원 단위) vs `price_cents` (명시적) 어느 것이 더 명확한가
   - Recommendation: 이 프로젝트는 KRW만 지원하므로 `price` (integer, 원 단위)로 단순하게 가라. DB 코멘트로 "원 단위" 명시

2. **customerKey 전략**
   - What we know: 토스페이먼츠는 email/id 등 예측 가능한 값 금지
   - What's unclear: User 모델에 `payment_customer_key` 컬럼을 추가할지, 매번 새로 생성할지
   - Recommendation: User 모델에 `payment_customer_key` UUID 컬럼 추가 (한 번 생성, 재사용). 이렇게 해야 결제 수단 저장 기능 등 추후 확장 가능

3. **무료 스킬팩의 체크아웃 처리**
   - What we know: 현재 모든 스킬팩은 무료 다운로드 (price 컬럼 없음)
   - What's unclear: price=0인 스킬팩도 체크아웃 페이지를 거쳐야 하는지
   - Recommendation: price=0이면 기존 `/download` 로직 유지, price>0이면 `/checkout`으로 라우팅. SkillPack#show 뷰에서 조건 분기

4. **웹훅 처리 여부**
   - What we know: COMM-05는 v2 deferred (REQUIREMENTS.md 참조)
   - What's unclear: 이번 Phase에 웹훅 없이 서버사이드 confirm만으로 충분한지
   - Recommendation: 이번 Phase는 서버사이드 confirm (동기 방식)만 구현. 웹훅은 Phase 5 이후 또는 다음 마일스톤 (이미 REQUIREMENTS.md에서 deferred)

---

## Sources

### Primary (HIGH confidence)
- `docs.tosspayments.com/en/integration-widget` - 결제위젯 연동 가이드, renderPaymentMethods/requestPayment 파라미터
- `docs.tosspayments.com/reference/using-api/authorization` - Basic auth + base64 인코딩 방법
- `docs.tosspayments.com/en/api-guide` - confirm API idempotency key, request/response 구조
- TossPayments 공식 블로그 `paytech-4` - React 훅 패턴 (useRef + useEffect)
- npm `@tosspayments/payment-widget-sdk` - 패키지명 확인

### Secondary (MEDIUM confidence)
- WebSearch "TossPayments confirm API paymentKey orderId amount" - confirm 엔드포인트 URL 및 curl 예시 확인
- WebSearch "SDK v1 vs v2 차이점" - 공식 마이그레이션 문서 참조, v2 변경사항 확인
- WebSearch "Faraday Ruby HTTP client Basic auth" - Faraday basic_auth 패턴 확인

### Tertiary (LOW confidence)
- 없음

---

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH - npm 패키지명/버전 공식 문서 직접 확인
- Architecture: HIGH - 공식 문서 코드 예시 + 프로젝트 기존 패턴 (landing.jsx) 기반
- Pitfalls: MEDIUM - 공식 정책 확인 (amount 검증, customerKey 정책) + 일반적인 결제 연동 패턴
- Faraday 사용: HIGH - Rails 표준 HTTP 클라이언트, Gemfile에 없으므로 추가 필요

**Research date:** 2026-02-22
**Valid until:** 2026-03-22 (토스페이먼츠 SDK는 안정적이나 v2 전환 권고 추세)
