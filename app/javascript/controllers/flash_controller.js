import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  connect() {
    this.timeout = setTimeout(() => {
      this.remove()
    }, 3000)
  }

  remove() {
    this.element.classList.add("opacity-0", "translate-x-5")

    setTimeout(() => {
      this.element.remove()
    }, 300)
  }
}