import { createRoot } from "react-dom/client"
import CheckoutWidget from "../components/checkout/CheckoutWidget"

// module 스코프에 root 레퍼런스를 저장하여 중복 마운트 방지
let root = null

// Turbo Drive 페이지 진입 시 마운트
document.addEventListener("turbo:load", () => {
  const el = document.getElementById("checkout-root")
  if (el && !root) {
    // data attributes에서 props 추출
    const clientKey = el.dataset.clientKey
    const customerKey = el.dataset.customerKey
    const orderId = el.dataset.orderId
    const orderName = el.dataset.orderName
    const amount = parseInt(el.dataset.amount, 10)
    const successUrl = el.dataset.successUrl
    const failUrl = el.dataset.failUrl

    root = createRoot(el)
    root.render(
      <CheckoutWidget
        clientKey={clientKey}
        customerKey={customerKey}
        orderId={orderId}
        orderName={orderName}
        amount={amount}
        successUrl={successUrl}
        failUrl={failUrl}
      />
    )
  }
})

// Turbo Drive 페이지 이탈 전 언마운트 (캐시 오염 방지)
// turbo:before-render가 아닌 turbo:before-cache를 사용 (RESEARCH.md 권장)
document.addEventListener("turbo:before-cache", () => {
  if (root) {
    root.unmount()
    root = null
  }
})
