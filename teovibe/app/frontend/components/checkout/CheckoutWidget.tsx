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
  clientKey,
  customerKey,
  orderId,
  orderName,
  amount,
  successUrl,
  failUrl,
}: CheckoutWidgetProps) {
  // React state가 아닌 DOM 참조이므로 useRef로 관리
  const paymentWidgetRef = useRef<Awaited<ReturnType<typeof loadPaymentWidget>> | null>(null)
  // eslint-disable-next-line @typescript-eslint/no-explicit-any
  const paymentMethodsRef = useRef<any>(null)

  useEffect(() => {
    // cleanup 플래그로 비동기 경쟁 조건 방지
    let cleanup = false

    ;(async () => {
      const paymentWidget = await loadPaymentWidget(clientKey, customerKey)
      if (cleanup) return

      // 결제 수단 UI 렌더링
      const paymentMethods = paymentWidget.renderPaymentMethods(
        "#payment-method",
        { value: amount, currency: "KRW", country: "KR" }
      )

      // 약관 동의 UI 렌더링
      paymentWidget.renderAgreement("#agreement", { variantKey: "AGREEMENT" })

      paymentWidgetRef.current = paymentWidget
      paymentMethodsRef.current = paymentMethods
    })()

    return () => {
      cleanup = true
    }
  }, [])

  // 결제 요청 핸들러
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

  // amount를 "15,000원" 형태로 포맷
  const formattedAmount = amount.toLocaleString("ko-KR") + "원"

  return (
    <div className="space-y-6">
      {/* 상품 정보 섹션 */}
      <div className="rounded-lg border border-gray-200 bg-white p-6">
        <h2 className="text-lg font-semibold text-gray-900">주문 정보</h2>
        <div className="mt-4 flex items-center justify-between">
          <span className="text-gray-700">{orderName}</span>
          <span className="text-xl font-bold text-gray-900">{formattedAmount}</span>
        </div>
      </div>

      {/* 토스페이먼츠 결제 수단 UI */}
      <div id="payment-method" />

      {/* 약관 동의 UI */}
      <div id="agreement" />

      {/* 결제하기 버튼 */}
      <button
        onClick={handlePayment}
        className="w-full rounded-lg bg-tv-orange px-6 py-4 text-base font-semibold text-white transition hover:bg-orange-600 focus:outline-none focus:ring-2 focus:ring-orange-500 focus:ring-offset-2"
      >
        결제하기
      </button>
    </div>
  )
}

export default CheckoutWidget
