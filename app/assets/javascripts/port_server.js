function renderNote(request) {
  requestAnimationFrame(function() {
    var parser = new Org.Parser();
    var orgDocument = parser.parse(request.content, { toc: 0 });
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
}

document.addEventListener("DOMContentLoaded", function() {
  var node = document.getElementById('elm');
  var app = Elm.Main.fullscreen();

  app.ports.sendRequest.subscribe(function(request) {
    switch(request.type) {
    case "render":
      renderNote(request);
      break;
    case "store":
      console.log("TODO: store note's contents");
      break;
    case "fetch":
      console.log("TODO: fetch note from local db");
      break;
    default:
      console.err("Unexpected request", request)
    }
  });
});
