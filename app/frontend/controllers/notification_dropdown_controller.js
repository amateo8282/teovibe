import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["menu", "badge"]

  toggle() {
    this.menuTarget.classList.toggle("hidden")
  }

  close(event) {
    if (!this.element.contains(event.target)) {
      this.menuTarget.classList.add("hidden")
    }
  }

  connect() {
    this.closeHandler = this.close.bind(this)
    document.addEventListener("click", this.closeHandler)
  }

  disconnect() {
    document.removeEventListener("click", this.closeHandler)
  }
}
