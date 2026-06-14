import { Controller } from "@hotwired/stimulus"

// 3D 틸트: 컨테이너에 붙이면 내부 카드(기본 .tv-card)에 pointermove 미세 회전.
// fine 포인터 + 모션 허용일 때만. data-tilt-selector-value, data-tilt-max-value(기본 4deg)
export default class extends Controller {
  static values = { selector: { type: String, default: ".tv-card" }, max: { type: Number, default: 4 } }

  connect() {
    if (!window.matchMedia("(pointer: fine)").matches) return
    if (window.matchMedia("(prefers-reduced-motion: reduce)").matches) return
    this.cards = Array.from(this.element.querySelectorAll(this.selectorValue))
    this.handlers = new Map()
    this.cards.forEach((card) => {
      const move = (e) => {
        const r = card.getBoundingClientRect()
        const px = (e.clientX - r.left) / r.width - 0.5
        const py = (e.clientY - r.top) / r.height - 0.5
        card.style.setProperty("--ry", `${(px * this.maxValue).toFixed(2)}deg`)
        card.style.setProperty("--rx", `${(-py * this.maxValue).toFixed(2)}deg`)
      }
      const leave = () => { card.style.setProperty("--ry", "0deg"); card.style.setProperty("--rx", "0deg") }
      card.addEventListener("pointermove", move)
      card.addEventListener("pointerleave", leave)
      this.handlers.set(card, { move, leave })
    })
  }

  disconnect() {
    this.handlers?.forEach(({ move, leave }, card) => {
      card.removeEventListener("pointermove", move)
      card.removeEventListener("pointerleave", leave)
    })
  }
}
