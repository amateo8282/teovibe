import { createRoot } from "react-dom/client"
import ReactDemo from "../components/ReactDemo"

// module 스코프에 root 레퍼런스를 저장하여 중복 마운트 방지
let root = null

// Turbo Drive 페이지 진입 시 마운트
document.addEventListener("turbo:load", () => {
  const el = document.getElementById("react-root")
  if (el && !root) {
    root = createRoot(el)
    root.render(<ReactDemo />)
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
