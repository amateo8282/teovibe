import { Controller } from "@hotwired/stimulus"

// 골드 마퀴: topics 배열로 시퀀스 생성 후 복제(끊김 없는 -50% 루프).
// <div data-controller="marquee" data-marquee-topics-value='["A","B"]'>
//   <div class="tv-marquee"><div class="tv-marquee-track" data-marquee-target="track">
//     <div class="tv-marquee-seq" data-marquee-target="seq"></div></div></div></div>
export default class extends Controller {
  static targets = ["track", "seq"]
  static values = { topics: { type: Array, default: [] } }

  connect() {
    const topics = this.topicsValue.length ? this.topicsValue : ["Vibe Coding", "Ship It"]
    this.seqTarget.innerHTML = topics
      .map((t, i) => `<span class="tv-marquee-item">${this.escape(t)}</span><span class="tv-marquee-star">${i % 2 ? "✦" : "✶"}</span>`)
      .join("")
    const clone = this.seqTarget.cloneNode(true)
    clone.setAttribute("aria-hidden", "true")
    this.trackTarget.appendChild(clone)
  }

  escape(s) {
    const d = document.createElement("div")
    d.textContent = s
    return d.innerHTML
  }
}
