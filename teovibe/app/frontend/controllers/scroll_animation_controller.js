import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  connect() {
    this.observer = new IntersectionObserver(
      (entries) => {
        entries.forEach((entry) => {
          if (entry.isIntersecting) {
            entry.target.classList.add("animate-fade-in")
            entry.target.classList.remove("opacity-0", "translate-y-8")
            this.observer.unobserve(entry.target)
          }
        })
      },
      { threshold: 0.1 }
    )

    this.element.classList.add("opacity-0", "translate-y-8", "transition-all", "duration-700", "ease-out")
    this.observer.observe(this.element)
  }

  disconnect() {
    this.observer?.disconnect()
  }
}
