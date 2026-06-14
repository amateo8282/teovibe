import { Controller } from "@hotwired/stimulus"

// 카운트업: 뷰포트 진입 시 0→to 까지 easeOutQuart 애니메이션.
// <span data-controller="count-up" data-count-up-to-value="128" data-count-up-duration-value="1400">0</span>
export default class extends Controller {
  static values = { to: Number, duration: { type: Number, default: 1400 } }

  connect() {
    if (window.matchMedia("(prefers-reduced-motion: reduce)").matches || !this.toValue) {
      this.element.textContent = this.format(this.toValue || 0)
      return
    }
    this.io = new IntersectionObserver(
      (entries) => {
        for (const e of entries) {
          if (e.isIntersecting) { this.run(); this.io.disconnect(); break }
        }
      },
      { threshold: 0.4 }
    )
    this.io.observe(this.element)
  }

  run() {
    const t0 = performance.now()
    const tick = (now) => {
      const p = Math.min((now - t0) / this.durationValue, 1)
      this.element.textContent = this.format(Math.round(this.toValue * (1 - Math.pow(1 - p, 4))))
      if (p < 1) requestAnimationFrame(tick)
    }
    requestAnimationFrame(tick)
  }

  format(n) { return n.toLocaleString() }

  disconnect() { this.io?.disconnect() }
}
