import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["source", "label"]
  static values = { copied: String, failed: String, copy: String }

  async copy() {
    const text = this.sourceTarget.textContent || this.sourceTarget.value
    
    try {
      await navigator.clipboard.writeText(text)
      
      if (this.hasLabelTarget) {
        const originalText = this.labelTarget.textContent
        this.labelTarget.textContent = this.hasCopiedValue ? this.copiedValue : "Copied!"
        
        setTimeout(() => {
          this.labelTarget.textContent = originalText
        }, 2000)
      }
    } catch (err) {
      console.error("Failed to copy:", err)
      
      if (this.hasLabelTarget) {
        this.labelTarget.textContent = this.hasFailedValue ? this.failedValue : "Failed"
        
        setTimeout(() => {
          this.labelTarget.textContent = this.hasCopyValue ? this.copyValue : "Copy"
        }, 2000)
      }
    }
  }
}
