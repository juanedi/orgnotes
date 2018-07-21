(function() {
  var RESOURCES_STORE = "resources"

  window.DB = {
    initialize: initialize,
    store: store,
    fetch: fetch
  };

  function initialize() {
    return new Promise(function(resolve, reject) {
      if (!('indexedDB' in window)) {
        reject(Error("This browser doesn't support IndexedDB"));
        return;
      }

      var openRequest = window.indexedDB.open('orgnotes-db1', 1);

      openRequest.onupgradeneeded = function() {
        if (!this.result.objectStoreNames.contains(RESOURCES_STORE)) {
          // TODO: is this operation async?
          this.result.createObjectStore(RESOURCES_STORE, { keyPath: 'path' });;
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

  function store(request, db) {
    var tx = db.transaction(RESOURCES_STORE, "readwrite");
    var store = tx.objectStore(RESOURCES_STORE);

    store.put(request.resource);
  }

  function fetch(request, db) {
    var tx = db.transaction(RESOURCES_STORE, "readonly");
    var store = tx.objectStore(RESOURCES_STORE);

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
})();
