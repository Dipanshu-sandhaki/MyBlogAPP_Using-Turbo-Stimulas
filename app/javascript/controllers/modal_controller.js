import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["modal", "deleteModal"]

connect() {
  this.deleteUrl = null

  this.handleKeydown = this.handleKeydown.bind(this)
  this.handleFrameLoad = this.handleFrameLoad.bind(this)

  document.addEventListener("keydown", this.handleKeydown)
  document.addEventListener("turbo:frame-load", this.handleFrameLoad)
}

disconnect() {
  document.removeEventListener("keydown", this.handleKeydown)
  document.removeEventListener("turbo:frame-load", this.handleFrameLoad)
}

handleFrameLoad(event) {
  if (event.target.id === "modal") {
    this.open()
  }
}

  disconnect() {
    document.removeEventListener("keydown", this.handleKeydown)
  }

  // ================= MODAL =================

  open() {
    this.modalTarget.classList.remove("hidden")

    // scroll lock (important UX 🔥)
    document.body.classList.add("overflow-hidden")
  }

  close() {
    this.modalTarget.classList.add("hidden")

    document.body.classList.remove("overflow-hidden")
  }

  // click outside close
  backdropClose(event) {
    if (event.target === this.modalTarget) {
      this.close()
    }
  }

  // ESC key close
  handleKeydown(event) {
    if (event.key === "Escape") {
      this.close()
      this.closeDelete()
    }
  }

  // turbo form submit success → close modal
  submitEnd(event) {
    if (event.detail.success) {
      this.close()
    }
  }

  // ================= DELETE =================

  openDelete(event) {
    this.deleteUrl = event.currentTarget.dataset.url
    this.deleteModalTarget.classList.remove("hidden")
    document.body.classList.add("overflow-hidden")
  }

  closeDelete() {
    this.deleteModalTarget.classList.add("hidden")
    document.body.classList.remove("overflow-hidden")
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
}