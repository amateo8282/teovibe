import { Controller } from "@hotwired/stimulus"

// 스크롤 시 document.body에 data-scrolled 토글 → 헤더(네비) 변형 트리거.
// 네비 등 영속 요소에 data-controller="header-scroll" data-header-scroll-threshold-value="24"
export default class extends Controller {
  static values = { threshold: { type: Number, default: 24 } }

  connect() {
    this.onScroll = this.onScroll.bind(this)
    addEventListener("scroll", this.onScroll, { passive: true })
    this.onScroll()
  }

  onScroll() {
    document.body.toggleAttribute("data-scrolled", scrollY > this.thresholdValue)
  }

  disconnect() { removeEventListener("scroll", this.onScroll) }
}
