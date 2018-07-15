(function() {
  function renderNote(request) {
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

  function initializeDb() {
    return new Promise(function(resolve, reject) {
      if (!('indexedDB' in window)) {
        reject(Error("This browser doesn't support IndexedDB"));
        return;
      }

      var openRequest = window.indexedDB.open('orgnotes-db1', 1);

      openRequest.onupgradeneeded = function() {
        if (!this.result.objectStoreNames.contains('notes')) {
          this.result.createObjectStore('notes', { keyPath: 'path' });;
        }
      };

      openRequest.onsuccess = function() {
        resolve(this.result);
      };

      openRequest.onerror = function(error) {
        reject(error);
      };
    });
  }

  function storeNote(request, db) {
    var tx = db.transaction("notes", "readwrite");
    var store = tx.objectStore("notes");

    store.put(request.note);
  }

  function fetchNote(request, db) {
    var tx = db.transaction("notes", "readonly");
    var store = tx.objectStore("notes");

    return new Promise(function(resolve, reject) {
      var getRequest = store.get(request.path);

      getRequest.onsuccess = function(e) {
        resolve(e.target.result);
      };

      getRequest.onerror = function(error) {
        reject(error);
      };
    });
  }

  document.addEventListener("DOMContentLoaded", function() {
    var node = document.getElementById('elm');
    var app = Elm.Main.fullscreen();
    var dbSetup = initializeDb();
    var send = app.ports.fromJs.send;

    app.ports.toJs.subscribe(function(request) {
      switch(request.type) {
      case "render":
        renderNote(request);
        break;
      case "store":
        dbSetup.then(function(db) {
          storeNote(request, db);
        });
        break;
      case "fetch":
        dbSetup.then(function(db) {
          return fetchNote(request, db);
        }).then(function(note) {
          send(note);
        });
        break;
      default:
        console.err("Unexpected request", request);
      }
    });
  });
})();
