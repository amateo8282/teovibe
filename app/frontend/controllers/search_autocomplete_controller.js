import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["input", "results"]
  static values = { url: String }

  connect() {
    this.timeout = null
  }

  search() {
    clearTimeout(this.timeout)
    const query = this.inputTarget.value.trim()

    if (query.length < 2) {
      this.resultsTarget.classList.add("hidden")
      return
    }

    this.timeout = setTimeout(() => {
      fetch(`${this.urlValue}?q=${encodeURIComponent(query)}`)
        .then(response => response.json())
        .then(suggestions => {
          if (suggestions.length > 0) {
            this.resultsTarget.innerHTML = suggestions.map(s =>
              `<a href="/search?q=${encodeURIComponent(s)}" class="block px-4 py-2 text-sm hover:bg-tv-cream">${this.escapeHtml(s)}</a>`
            ).join("")
            this.resultsTarget.classList.remove("hidden")
          } else {
            this.resultsTarget.classList.add("hidden")
          }
        })
    }, 300)
  }

  close() {
    setTimeout(() => this.resultsTarget.classList.add("hidden"), 200)
  }

  escapeHtml(text) {
    const div = document.createElement("div")
    div.textContent = text
    return div.innerHTML
  }
}
