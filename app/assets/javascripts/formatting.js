document.addEventListener("DOMContentLoaded", function() {
  var node = document.getElementById('elm');
  var app = Elm.Main.fullscreen();

  // IN: ( String, NoteSource )
  var formatPort = app.ports.format_;

  // OUT: ( String, NoteMarkup )
  var resultsPort = app.ports.results_;

  formatPort.subscribe(function(req) {
    var path   = req[0]
    var source = req[1]

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

    resultsPort.send([path, orgHTMLDocument.toString()]);
  });
});
