import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["defaultState", "loadingState", "chosenState", "fileNameEl", "dropZone", "fileInput"]

  choose() {
    this.fileInputTarget.click()
  }

  handleFile(event) {
    const file = event.target.files?.[0]
    if (!file) return

    this.defaultStateTarget.classList.add("hidden")
    this.chosenStateTarget.classList.add("hidden")
    this.loadingStateTarget.classList.remove("hidden")

    setTimeout(() => {
      const sizeKB = (file.size / 1024).toFixed(1)
      this.fileNameElTarget.textContent = `${file.name}  (${sizeKB} KB)`

      this.loadingStateTarget.classList.add("hidden")
      this.chosenStateTarget.classList.remove("hidden")

      this.dropZoneTarget.classList.remove("border-gray-300", "dark:border-gray-600")
      this.dropZoneTarget.classList.add("border-green-500", "bg-green-50", "dark:bg-green-950", "dark:border-green-600")
    }, 600)
  }
}