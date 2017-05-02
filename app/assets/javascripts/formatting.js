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
    var orgDocument = parser.parse(source);
    var outputContainer = document.querySelector("#formatted-code");

    var orgHTMLDocument = orgDocument.convert(Org.ConverterHTML, {
      headerOffset: 1,
      exportFromLineNumber: false,
      suppressSubScriptHandling: false,
      suppressAutoLink: false
    });

    resultsPort.send([path, orgHTMLDocument.contentHTML]);
  });
});
