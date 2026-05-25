import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["modal", "deleteModal"]

  connect() {
    this.deleteUrl = null
    this.handleKeydown = this.handleKeydown.bind(this)
    this.handleFrameLoad = this.handleFrameLoad.bind(this)
    this.handleTurboVisit = this.handleTurboVisit.bind(this)

    document.addEventListener("keydown", this.handleKeydown)
    document.addEventListener("turbo:frame-load", this.handleFrameLoad)
    document.addEventListener("turbo:visit", this.handleTurboVisit)
  }

  disconnect() {
    document.removeEventListener("keydown", this.handleKeydown)
    document.removeEventListener("turbo:frame-load", this.handleFrameLoad)
    document.removeEventListener("turbo:visit", this.handleTurboVisit)
    this._unlockScroll()
  }

  handleFrameLoad(event) {
    if (
      event.target.id === "modal" &&
      this.hasModalTarget &&
      event.target.innerHTML.trim() !== ""
    ) {
      this.open()
    }
  }

  handleTurboVisit() {
    this._unlockScroll()
  }

  handleKeydown(event) {
    if (event.key === "Escape") {
      if (this.hasModalTarget && !this.modalTarget.classList.contains("hidden")) {
        this.close()
      }
      if (this.hasDeleteModalTarget && !this.deleteModalTarget.classList.contains("hidden")) {
        this.closeDelete()
      }
    }
  }

  open() {
    if (this.hasModalTarget) {
      this.modalTarget.classList.remove("hidden")
      this._lockScroll()
    }
  }

  close() {
    if (this.hasModalTarget) {
      this.modalTarget.classList.add("hidden")
      const frame = this.modalTarget.querySelector("turbo-frame#modal")
      if (frame) frame.innerHTML = ""
    }
    this._unlockScroll()
  }

  openDelete(event) {
    this.deleteUrl = event.currentTarget.dataset.url
    if (this.hasDeleteModalTarget) {
      this.deleteModalTarget.classList.remove("hidden")
      this._lockScroll()
    }
  }

  closeDelete() {
    if (this.hasDeleteModalTarget) {
      this.deleteModalTarget.classList.add("hidden")
    }
    this.deleteUrl = null
    this._unlockScroll()
  }

  confirmDelete() {
    if (!this.deleteUrl) return

    const url = this.deleteUrl
    this.closeDelete()

    fetch(url, {
      method: "DELETE",
      headers: {
        "X-CSRF-Token": document.querySelector('meta[name="csrf-token"]').content,
        "Accept": "text/vnd.turbo-stream.html, text/html, application/xhtml+xml"
      }
    })
    .then(async (response) => {
      if (response.ok) {
        const contentType = response.headers.get("content-type") || ""
        if (contentType.includes("turbo-stream")) {
          const html = await response.text()
          Turbo.renderStreamMessage(html)
        }
      }
    })
    .catch((err) => {
      console.error("Delete failed:", err)
    })
  }

  _lockScroll() {
    document.body.classList.add("overflow-hidden")
  }

  _unlockScroll() {
    document.body.classList.remove("overflow-hidden")
  }

  openEmptyDrafts() {
  document.getElementById("empty-drafts-modal").classList.remove("hidden");
  }

closeEmptyDrafts() {
  document.getElementById("empty-drafts-modal").classList.add("hidden");
  }
}