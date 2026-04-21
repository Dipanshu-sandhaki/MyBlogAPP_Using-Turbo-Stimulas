import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["view", "edit"]

  showEdit() {
    this.viewTarget.classList.add("hidden")
    this.editTarget.classList.remove("hidden")
  }

  cancelEdit() {
    this.editTarget.classList.add("hidden")
    this.viewTarget.classList.remove("hidden")
  }
}