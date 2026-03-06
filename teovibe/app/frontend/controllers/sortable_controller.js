import { Controller } from "@hotwired/stimulus"
import Sortable from "sortablejs"

// Admin 카테고리 목록에서 드래그앤드롭 순서 변경을 처리하는 Stimulus 컨트롤러
export default class extends Controller {
  static values = { url: String }

  connect() {
    this.sortable = Sortable.create(this.element, {
      animation: 150,
      handle: "[data-sortable-handle]",
      ghostClass: "opacity-50",
      onEnd: this.onEnd.bind(this)
    })
  }

  disconnect() {
    this.sortable?.destroy()
  }

  // 드래그 완료 시 서버에 새 순서를 PATCH 전송
  onEnd() {
    const positions = [ ...this.element.querySelectorAll("[data-id]") ].map(el => el.dataset.id)
    fetch(this.urlValue, {
      method: "PATCH",
      headers: {
        "Content-Type": "application/json",
        "X-CSRF-Token": document.querySelector('meta[name="csrf-token"]')?.content
      },
      body: JSON.stringify({ positions })
    })
  }
}
