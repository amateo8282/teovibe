import { Controller } from "@hotwired/stimulus"

// 페이지 상단 스크롤 진행바. <div class="tv-scroll-progress" data-controller="scroll-progress">
//   <span data-scroll-progress-target="bar"></span></div>
export default class extends Controller {
  static targets = ["bar"]

  connect() {
    this.ticking = false
    this.onScroll = this.onScroll.bind(this)
    addEventListener("scroll", this.onScroll, { passive: true })
    addEventListener("resize", this.onScroll, { passive: true })
    this.update()
  }

  onScroll() {
    if (this.ticking) return
    this.ticking = true
    requestAnimationFrame(() => { this.update(); this.ticking = false })
  }

  update() {
    const max = document.documentElement.scrollHeight - innerHeight
    const p = max > 0 ? Math.min(scrollY / max, 1) : 0
    if (this.hasBarTarget) this.barTarget.style.transform = `scaleX(${p})`
  }

  disconnect() {
    removeEventListener("scroll", this.onScroll)
    removeEventListener("resize", this.onScroll)
  }
}
