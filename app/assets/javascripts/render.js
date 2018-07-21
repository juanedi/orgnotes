(function() {
  window.Render = {
    render: function(request) {
      requestAnimationFrame(function() {
        var parser = new Org.Parser();
        var orgDocument = parser.parse(request.content, { toc: 0 });

        var orgHTMLDocument = orgDocument.convert(Org.ConverterHTML, {
          // header levels to skip (1 means first level header will be h2)
          headerOffset: 0,
          exportFromLineNumber: false,
          suppressSubScriptHandling: false,
          suppressAutoLink: false,
          translateSymbolArrow: true
        });

        document.getElementById("note-content").innerHTML = orgHTMLDocument.toString();
      });
    }
  };
})();
