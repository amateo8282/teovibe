import { Controller } from "@hotwired/stimulus"

// 스크롤 리빌: 컨테이너에 붙이면 내부 .tv-reveal 요소들을 뷰포트 진입 시 스태거로 등장.
// 인라인 style="--d:.3s"가 있으면 그 값을 존중, 없으면 DOM 순서로 자동 스태거.
// data-tv-reveal-stagger-value(기본 0.06), data-tv-reveal-max-value(기본 0.42)
export default class extends Controller {
  static values = { stagger: { type: Number, default: 0.06 }, max: { type: Number, default: 0.42 } }

  connect() {
    if (window.matchMedia("(prefers-reduced-motion: reduce)").matches) {
      this.element.querySelectorAll(".tv-reveal").forEach((el) => el.classList.add("in"))
      return
    }
    this.io = new IntersectionObserver(
      (entries) => {
        for (const e of entries) {
          if (e.isIntersecting) { e.target.classList.add("in"); this.io.unobserve(e.target) }
        }
      },
      { threshold: 0.12, rootMargin: "0px 0px -4% 0px" }
    )
    this.observe()
  }

  // 동적으로 카드가 추가되면 reobserve() 호출 가능
  observe() {
    const items = this.element.querySelectorAll(".tv-reveal:not(.in)")
    items.forEach((el, i) => {
      if (!el.style.getPropertyValue("--d")) {
        el.style.setProperty("--d", `${Math.min(i * this.staggerValue, this.maxValue)}s`)
      }
      this.io.observe(el)
    })
  }

  disconnect() { this.io?.disconnect() }
}
