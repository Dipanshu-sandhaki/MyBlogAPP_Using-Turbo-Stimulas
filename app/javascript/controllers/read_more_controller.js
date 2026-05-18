import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["content", "button", "fader", "icon", "text"]

  connect() {
    setTimeout(() => {
      if (this.contentTarget.scrollHeight > 260) {
        this.buttonTarget.classList.remove('hidden')
      } else {
        this.contentTarget.classList.remove('max-h-[250px]')
        if (this.hasFaderTarget) this.faderTarget.style.display = 'none'
      }
    }, 150)
  }

  toggle(event) {
    event.preventDefault()
    
    if (this.contentTarget.classList.contains('max-h-[250px]')) {
      this.contentTarget.style.maxHeight = this.contentTarget.scrollHeight + "px"
      this.contentTarget.classList.remove('max-h-[250px]')
      if (this.hasFaderTarget) this.faderTarget.style.opacity = '0'
      this.textTarget.textContent = 'See Less'
      this.iconTarget.classList.add('rotate-180')
      
      setTimeout(() => { this.contentTarget.style.maxHeight = 'none' }, 500)
    } else {
      this.contentTarget.style.maxHeight = this.contentTarget.scrollHeight + "px"
      void this.contentTarget.offsetHeight
      
      this.contentTarget.classList.add('max-h-[250px]')
      this.contentTarget.style.maxHeight = null
      if (this.hasFaderTarget) this.faderTarget.style.opacity = '1'
      this.textTarget.textContent = 'See More'
      this.iconTarget.classList.remove('rotate-180')
      
      const scrollArea = document.getElementById('global-modal-scroll')
      if (scrollArea) scrollArea.scrollTo({ top: 0, behavior: 'smooth' })
    }
  }
}