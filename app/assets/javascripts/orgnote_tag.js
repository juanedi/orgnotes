class OrgNote extends HTMLElement {
  static get observedAttributes() { return ['value'] }

  constructor() {
    super()
  }

  connectedCallback() {
    this.render()
  }

  attributeChangedCallback(name, oldValue, newValue) {
    if (name === 'value') {
      this.render()
    }
  }

  get value() {
    return this.getAttribute('value')
  }

  set value(value) {
    this.setAttribute('value', value)
  }

  render() {
    var parser = new Org.Parser()
    var orgDocument = parser.parse(this.value, { toc: 0 })

    var orgHTMLDocument = orgDocument.convert(Org.ConverterHTML, {
      // header levels to skip (1 means first level header will be h2)
      headerOffset: 0,
      exportFromLineNumber: false,
      suppressSubScriptHandling: false,
      suppressAutoLink: false,
      translateSymbolArrow: true
    })

    this.innerHTML = orgHTMLDocument.toString()
  }
}

window.customElements.define('org-note', OrgNote)
