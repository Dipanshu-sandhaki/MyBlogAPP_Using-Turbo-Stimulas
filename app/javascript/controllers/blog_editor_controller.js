import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  connect() {
    this._setupTrixAttributes()
    this._savedRange = null

    // Close link dialog if user clicks outside
    this._outsideClickHandler = (e) => {
      const dialog = document.getElementById("be-link-dialog")
      if (dialog && !dialog.contains(e.target) && !e.target.closest('[data-action*="toggleLinkDialog"]')) {
        this._closeDialog()
      }
    }
    document.addEventListener("mousedown", this._outsideClickHandler)
  }

  disconnect() {
    document.removeEventListener("mousedown", this._outsideClickHandler)
  }

 // SETUP: Register custom Trix attributes

  _setupTrixAttributes() {
    const register = () => {
      if (!Trix.config.textAttributes.foregroundColor) {
        Trix.config.textAttributes.foregroundColor = {
          styleProperty: "color",
          inheritable: true
        }
      }
      if (!Trix.config.textAttributes.customFontSize) {
        Trix.config.textAttributes.customFontSize = {
          styleProperty: "fontSize",
          inheritable: true
        }
      }
    }
    window.Trix ? register() : document.addEventListener("trix-initialize", register, { once: true })
  }

  // HELPERS

  get trixEditor() {
    return this.element.querySelector("trix-editor")
  }

  get editor() {
    return this.trixEditor?.editor
  }

// LINK DIALOG — fully manual (bypasses broken Trix wiring)

  toggleLinkDialog() {
    const dialog = document.getElementById("be-link-dialog")
    if (!dialog) return

    const isOpen = dialog.style.display === "block"

    if (isOpen) {
      this._closeDialog()
      return
    }

    // Save selection BEFORE dialog opens 
    if (this.editor) {
      this._savedRange = this.editor.getSelectedRange()

      // Pre-fill input if selection already has a link
      const attrs = this.editor.composition.currentAttributes
      const input = document.getElementById("be-link-url-input")
      if (input) input.value = attrs.href || ""
    }

    dialog.style.display = "block"

    // Focus the input
    setTimeout(() => {
      document.getElementById("be-link-url-input")?.focus()
    }, 50)
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

    // Auto-prepend https:// if missing
    if (!/^https?:\/\//i.test(url)) url = "https://" + url

    if (this.editor) {
      // Restore saved selection so link applies to correct text
      if (this._savedRange) {
        this.editor.setSelectedRange(this._savedRange)
      }
      this.editor.activateAttribute("href", url)
    }

    this._closeDialog()
    this.trixEditor?.focus()
  }

  removeLink() {
    if (this.editor) {
      if (this._savedRange) {
        this.editor.setSelectedRange(this._savedRange)
      }
      this.editor.deactivateAttribute("href")
    }

    const input = document.getElementById("be-link-url-input")
    if (input) input.value = ""

    this._closeDialog()
    this.trixEditor?.focus()
  }

  // COLOR

  openColorPicker() {
    this.element.querySelector("#text-color-picker")?.click()
  }

  applyColor(event) {
    const color = event.target.value
    const indicator = this.element.querySelector("#color-indicator")
    if (indicator) indicator.style.fill = color
    this.editor?.activateAttribute("foregroundColor", color)
  }

  // FONT SIZE
  increaseFontSize() { this._shiftFontSize(1) }
  decreaseFontSize() { this._shiftFontSize(-1) }

  _shiftFontSize(dir) {
    if (!this.editor) return
    const steps = [11, 13, 15, 17, 20, 24, 28, 34, 40]
    const current = this.editor.composition.currentAttributes.customFontSize
    const px = current ? parseInt(current) : 15
    const idx = steps.findIndex(s => s >= px)
    const safeIdx = idx < 0 ? 2 : idx
    const nextIdx = Math.max(0, Math.min(steps.length - 1, safeIdx + dir))
    this.editor.activateAttribute("customFontSize", steps[nextIdx] + "px")
  }

  // CASE TOGGLE
  toggleCase() {
    if (!this.editor) return
    const [s, e] = this.editor.getSelectedRange()
    if (s === e) return
    const text = this.editor.getDocument().toString().slice(s, e)
    const isAllUpper = text === text.toUpperCase()
    this.editor.setSelectedRange([s, e])
    this.editor.insertString(isAllUpper ? text.toLowerCase() : text.toUpperCase())
    this.editor.setSelectedRange([s, s + text.length])
  }
}