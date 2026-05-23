---
phase: 04-commerce
plan: 01
subsystem: payments
tags: [rails, order, toss-payments, sqlite, enum, migration, checkout]

# Dependency graph
requires:
  - phase: 02-content-experience
    provides: SkillPack 모델, Downloads 모델, User 모델 기반
provides:
  - Order 모델 (pending/paid/failed/refunded enum, toss_order_id 자동생성, payment_event_id unique index)
  - SkillPack price 컬럼 (integer, default 0, 원 단위)
  - User payment_customer_key 컬럼 (UUID, 토스페이먼츠 customerKey용)
  - CheckoutsController 스켈레톤 (show/success/fail)
  - 체크아웃 라우트 3개 (/checkout, /checkout/success, /checkout/fail)
affects:
  - 04-commerce/04-02 (체크아웃 UI, React 위젯 연동)
  - 04-commerce/04-03 (서버사이드 confirm API)

# Tech tracking
tech-stack:
  added: []
  patterns:
    - Order enum 상태 관리 (pending/paid/failed/refunded)
    - toss_order_id SecureRandom.urlsafe_base64(16) 자동생성 (before_validation)
    - payment_customer_key UUID 자동생성 (User before_validation)
    - find_or_create_by pending Order 재사용 패턴 (멱등성 보장)
    - 무료 스킬팩 체크아웃 가드 (price.zero? 검사)

key-files:
  created:
    - teovibe/app/models/order.rb
    - teovibe/db/migrate/20260222102017_create_orders.rb
    - teovibe/db/migrate/20260222102044_add_price_to_skill_packs.rb
    - teovibe/db/migrate/20260222102056_add_payment_customer_key_to_users.rb
    - teovibe/app/controllers/checkouts_controller.rb
  modified:
    - teovibe/app/models/user.rb
    - teovibe/app/models/skill_pack.rb
    - teovibe/config/routes.rb
    - teovibe/db/structure.sql

key-decisions:
  - "Order status는 integer enum (pending=0/paid=1/failed=2/refunded=3)로 구현 — Rails 내장 enum 활용"
  - "toss_order_id unique index + payment_event_id conditional unique index (IS NOT NULL) — SQLite partial index 지원 확인"
  - "User payment_customer_key를 UUID로 자동생성하여 재사용 — 이메일/ID 같은 예측 가능 값 사용 금지 (토스 정책)"
  - "CheckoutsController success 액션은 Plan 03에서 confirm 로직 추가 예정, 현재 안내 메시지만 표시"

patterns-established:
  - "Order 생성 시 before_validation으로 toss_order_id 자동생성 (SecureRandom.urlsafe_base64(16))"
  - "체크아웃 show 액션에서 find_or_create_by(:pending)으로 Order 재사용 (중복 결제 방지)"
  - "skill_packs member 라우트에 checkout/* 중첩하여 skill_pack_id 파라미터 자동 전달"

requirements-completed: [COMM-01]

# Metrics
duration: 2min
completed: 2026-02-22
---

# Phase 4 Plan 01: Order 모델 + 체크아웃 스켈레톤 Summary

**Rails Order 모델(pending/paid/failed/refunded enum, toss_order_id unique index)과 CheckoutsController 스켈레톤(show/success/fail)으로 토스페이먼츠 결제 연동 DB 기반 완성**

## Performance

- **Duration:** 2 min
- **Started:** 2026-02-22T10:20:05Z
- **Completed:** 2026-02-22T10:22:39Z
- **Tasks:** 2
- **Files modified:** 9

## Accomplishments

- Order 모델 생성 — pending/paid/failed/refunded enum 상태, toss_order_id(unique) + payment_event_id(conditional unique) index 포함
- SkillPack price 컬럼 + User payment_customer_key 컬럼 마이그레이션 완료 (3개 마이그레이션 모두 up)
- CheckoutsController 스켈레톤 생성 — 무료 스킬팩 가드, pending Order 재사용 패턴, 인증 필수

## Task Commits

Each task was committed atomically:

1. **Task 1: Order 모델 + 마이그레이션 생성** - `1acd844` (feat)
2. **Task 2: 체크아웃 라우트 + CheckoutsController 스켈레톤** - `97e724f` (feat)

## Files Created/Modified

- `teovibe/app/models/order.rb` - Order 모델 (enum, validations, toss_order_id 자동생성)
- `teovibe/db/migrate/20260222102017_create_orders.rb` - orders 테이블 + unique/status index
- `teovibe/db/migrate/20260222102044_add_price_to_skill_packs.rb` - SkillPack price 컬럼 (integer, default 0)
- `teovibe/db/migrate/20260222102056_add_payment_customer_key_to_users.rb` - User payment_customer_key 컬럼
- `teovibe/app/controllers/checkouts_controller.rb` - CheckoutsController (show/success/fail)
- `teovibe/app/models/user.rb` - has_many :orders, before_validation generate_payment_customer_key 추가
- `teovibe/app/models/skill_pack.rb` - has_many :orders 추가
- `teovibe/config/routes.rb` - checkout/success/fail 라우트 추가

## Decisions Made

- Order status는 integer enum (pending=0/paid=1/failed=2/refunded=3) — Rails 내장 enum 활용
- toss_order_id unique index + payment_event_id conditional unique index (WHERE IS NOT NULL) — SQLite partial index 지원 확인
- User payment_customer_key를 UUID로 자동생성하여 재사용 — 이메일/ID 같은 예측 가능 값 금지 (토스 정책)
- CheckoutsController success 액션은 Plan 03에서 confirm 로직 추가 예정, 현재 안내 메시지만 표시

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered

None

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- Order 모델과 결제 스키마 완성, 04-02 체크아웃 UI(React 결제위젯) 구현 준비 완료
- `@tosspayments/payment-widget-sdk` npm 패키지 설치 및 CheckoutWidget.tsx 컴포넌트 구현 필요
- checkouts/show.html.erb 뷰 파일 생성 필요 (React 마운트 포인트 포함)

## Self-Check: PASSED

- teovibe/app/models/order.rb: FOUND
- teovibe/db/migrate/20260222102017_create_orders.rb: FOUND
- teovibe/db/migrate/20260222102044_add_price_to_skill_packs.rb: FOUND
- teovibe/db/migrate/20260222102056_add_payment_customer_key_to_users.rb: FOUND
- teovibe/app/controllers/checkouts_controller.rb: FOUND
- Commit 1acd844: FOUND
- Commit 97e724f: FOUND

---
*Phase: 04-commerce*
*Completed: 2026-02-22*
