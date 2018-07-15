document.addEventListener("DOMContentLoaded", function() {
  var node = document.getElementById('elm');
  var app = Elm.Main.fullscreen();

  app.ports.renderNote.subscribe(function(source) {
    requestAnimationFrame(function() {
      var parser = new Org.Parser();
      var orgDocument = parser.parse(source, { toc: 0 });
      var outputContainer = document.querySelector("#formatted-code");

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
  });
});
