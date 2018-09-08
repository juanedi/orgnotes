(function() {
  document.addEventListener("DOMContentLoaded", function() {
    var node = document.getElementById('elm');
    var app = Elm.Main.fullscreen();
    var dbSetup = DB.initialize();
    var send = app.ports.fromJs.send;

    app.ports.toJs.subscribe(function(request) {
      switch(request.type) {
      case "render":
        Render.render(request);
        break;
      case "store":
        dbSetup.then(function(db) {
          DB.store(request, db);
        });
        break;
      case "fetch":
        dbSetup.then(function(db) {
          return DB.fetch(request, db);
        }).then(function(note) {
          send(note);
        }).catch(function(err) {
          send({error: err})
        });
        break;
      default:
        console.err("Unexpected request", request);
      }
    });
  });
})();