import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["form", "saveStatus"]
  static values  = { originalStatus: String }

  connect() {
    this._isDirty    = false
    this._isSaving   = false
    this._savedRange = null

    this._setupTrixAttributes()

    this._beforeUnloadHandler = (e) => {
      if (this._isDirty) {
        e.preventDefault()
        e.returnValue = ""
      }
    }
    window.addEventListener("beforeunload", this._beforeUnloadHandler)

    this._outsideClickHandler = (e) => {
      const dialog = document.getElementById("be-link-dialog")
      if (dialog && !dialog.contains(e.target) && !e.target.closest('[data-action*="toggleLinkDialog"]')) {
        this._closeDialog()
      }
    }
    document.addEventListener("mousedown", this._outsideClickHandler)
  }

  disconnect() {
    window.removeEventListener("beforeunload", this._beforeUnloadHandler)
    document.removeEventListener("mousedown", this._outsideClickHandler)
  }

  markDirty() {
    this._isDirty = true
  }

  async goBack(event) {
    event.preventDefault()
    const destination = event.currentTarget.dataset.destination || "/"

    if (this.originalStatusValue === "published" || this.originalStatusValue === "saved") {
      window.location.href = destination
      return
    }

    await this._autoSaveAndLeave(destination)
  }

  async discard(event) {
    event.preventDefault()
    const destination = event.currentTarget.dataset.destination || "/"

    if (this.originalStatusValue === "published" || this.originalStatusValue === "saved") {
      window.location.href = destination
      return
    }

    const title = this.formTarget?.querySelector("input[name*='title']")?.value?.trim()
    if (!title && !this._isDirty) {
      window.location.href = destination
      return
    }

    await this._autoSaveAndLeave(destination)
  }

  async _autoSaveAndLeave(destination) {
    if (this._isSaving) return
    this._isSaving = true

    this._showStatus("Saving draft…", "saving")

    try {
      const form     = this.formTarget
      const formData = new FormData(form)

      formData.set("commit", "Save Draft")

      const csrfToken = document.querySelector('meta[name="csrf-token"]')?.content
      const headers   = csrfToken ? { "X-CSRF-Token": csrfToken } : {}

      const methodField = formData.get("_method")
      const fetchMethod = methodField ? "POST" : form.method.toUpperCase() || "POST"

      const res = await fetch(form.action, {
        method:  fetchMethod,
        body:    formData,
        headers: { ...headers, "Accept": "text/html, application/json" }
      })

      if (res.ok) {
        this._isDirty  = false
        this._isSaving = false
        this._showStatus("Saved to drafts ✓", "saved")
        setTimeout(() => { window.location.href = destination }, 600)
      } else {
        throw new Error("Save failed")
      }
    } catch (err) {
      this._isSaving = false
      this._showStatus("Could not save — leaving anyway", "error")
      setTimeout(() => { window.location.href = destination }, 1200)
    }
  }

  _showStatus(message, state) {
    if (!this.hasSaveStatusTarget) return
    const el = this.saveStatusTarget
    el.textContent = message
    el.classList.remove("hidden", "text-gray-400", "text-emerald-500", "text-red-400", "text-amber-400")

    const colorMap = {
      saving: "text-amber-400 dark:text-amber-300",
      saved:  "text-emerald-500 dark:text-emerald-400",
      error:  "text-red-400 dark:text-red-300"
    }
    el.classList.add(...(colorMap[state] || "text-gray-400").split(" "))
  }

  _setupTrixAttributes() {
    const register = () => {
      if (!Trix.config.textAttributes.foregroundColor) {
        Trix.config.textAttributes.foregroundColor = { styleProperty: "color", inheritable: true }
      }
      if (!Trix.config.textAttributes.customFontSize) {
        Trix.config.textAttributes.customFontSize = { styleProperty: "fontSize", inheritable: true }
      }
    }
    window.Trix ? register() : document.addEventListener("trix-initialize", register, { once: true })
  }

  get trixEditor() { return this.element.querySelector("trix-editor") }
  get editor()     { return this.trixEditor?.editor }

  toggleLinkDialog() {
    const dialog = document.getElementById("be-link-dialog")
    if (!dialog) return

    if (dialog.style.display === "block") { this._closeDialog(); return }

    if (this.editor) {
      this._savedRange = this.editor.getSelectedRange()
      const attrs = this.editor.composition.currentAttributes
      const input = document.getElementById("be-link-url-input")
      if (input) input.value = attrs.href || ""
    }

    dialog.style.display = "block"
    setTimeout(() => document.getElementById("be-link-url-input")?.focus(), 50)
  }

  _closeDialog() {
    const dialog = document.getElementById("be-link-dialog")
    if (dialog) dialog.style.display = "none"
    this._savedRange = null
  }

  applyLink() {
    const input = document.getElementById("be-link-url-input")
    let url = input?.value?.trim()
    if (!url) return
    if (!/^https?:\/\//i.test(url)) url = "https://" + url
    if (this.editor) {
      if (this._savedRange) this.editor.setSelectedRange(this._savedRange)
      this.editor.activateAttribute("href", url)
    }
    this._closeDialog()
    this.trixEditor?.focus()
  }

  removeLink() {
    if (this.editor) {
      if (this._savedRange) this.editor.setSelectedRange(this._savedRange)
      this.editor.deactivateAttribute("href")
    }
    const input = document.getElementById("be-link-url-input")
    if (input) input.value = ""
    this._closeDialog()
    this.trixEditor?.focus()
  }

  openColorPicker() { this.element.querySelector("#text-color-picker")?.click() }

  applyColor(event) {
    const color = event.target.value
    const indicator = this.element.querySelector("#color-indicator")
    if (indicator) indicator.style.fill = color
    this.editor?.activateAttribute("foregroundColor", color)
  }

  increaseFontSize() { this._shiftFontSize(1) }
  decreaseFontSize() { this._shiftFontSize(-1) }

  _shiftFontSize(dir) {
    if (!this.editor) return
    const steps   = [11, 13, 15, 17, 20, 24, 28, 34, 40]
    const current = this.editor.composition.currentAttributes.customFontSize
    const px      = current ? parseInt(current) : 15
    const idx     = steps.findIndex(s => s >= px)
    const safeIdx = idx < 0 ? 2 : idx
    const nextIdx = Math.max(0, Math.min(steps.length - 1, safeIdx + dir))
    this.editor.activateAttribute("customFontSize", steps[nextIdx] + "px")
  }

  toggleCase() {
    if (!this.editor) return
    const [s, e] = this.editor.getSelectedRange()
    if (s === e) return
    const text       = this.editor.getDocument().toString().slice(s, e)
    const isAllUpper = text === text.toUpperCase()
    this.editor.setSelectedRange([s, e])
    this.editor.insertString(isAllUpper ? text.toLowerCase() : text.toUpperCase())
    this.editor.setSelectedRange([s, s + text.length])
  }
}