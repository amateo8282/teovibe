import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["tab", "panel"]
  static values = { index: { type: Number, default: 0 } }

  connect() {
    this.showTab(this.indexValue)
  }

  select(event) {
    const index = this.tabTargets.indexOf(event.currentTarget)
    this.showTab(index)
  }

  showTab(index) {
    this.tabTargets.forEach((tab, i) => {
      tab.classList.toggle("bg-tv-black", i === index)
      tab.classList.toggle("text-white", i === index)
      tab.classList.toggle("bg-white", i !== index)
      tab.classList.toggle("text-tv-burgundy", i !== index)
    })
    this.panelTargets.forEach((panel, i) => {
      panel.classList.toggle("hidden", i !== index)
    })
  }
}
