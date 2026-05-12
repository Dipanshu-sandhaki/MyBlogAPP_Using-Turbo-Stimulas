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
    if (event.target.id === "modal") {
      this.open()
    }
  }

  handleTurboVisit() {
    this._unlockScroll()
  }

  open() {
    this.modalTarget.classList.remove("hidden")
    this._lockScroll()
  }

  close() {
    this.modalTarget.classList.add("hidden")
    const frame = this.modalTarget.querySelector("turbo-frame#modal")
    if (frame) frame.innerHTML = ""
    this._unlockScroll()
  }

  backdropClose(event) {
    if (event.target === this.modalTarget) {
      this.close()
    }
    if (event.target === this.deleteModalTarget) {
      this.closeDelete()
    }
  }

  handleKeydown(event) {
    if (event.key === "Escape") {
      this.close()
      this.closeDelete()
    }
  }

  submitEnd(event) {
    if (event.detail.success) {
      this.close()
    }
  }

  openDelete(event) {
    this.deleteUrl = event.currentTarget.dataset.url
    if (this.hasDeleteModalTarget) {
      this.deleteModalTarget.classList.remove("hidden")
    }
    this._lockScroll()
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

    fetch(this.deleteUrl, {
      method: "DELETE",
      headers: {
        "X-CSRF-Token": document.querySelector('meta[name="csrf-token"]').content,
        "Accept": "text/vnd.turbo-stream.html"
      }
    }).then((response) => {
      if (response.ok) {
        this.closeDelete()
        window.location.reload()
      }
    })
  }

  _lockScroll() {
    document.body.classList.add("overflow-hidden")
  }

  _unlockScroll() {
    document.body.classList.remove("overflow-hidden")
  }
}