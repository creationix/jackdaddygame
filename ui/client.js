window.addEventListener('load', function (evt) {
  // Delete the cookie
  document.cookie = "since=;expires=28, Mar 1982 02:47:11 UTC;";

  (function poll() {
    XHR("/listen", function (err, json) {
      if (err) throw err;
      var message = JSON.parse(json);
      console.log(message)
      poll();
    });
  }());
}, true);

function XHR(url, callback) {
  var xhr = new XMLHttpRequest();
  xhr.open("GET", url, true);
  xhr.onreadystatechange = function (evt) {
    if (xhr.readyState === 4) {
      if (xhr.status === 200) {
        callback(null, xhr.responseText);
      } else {
        callback(new Error(xhr.statusText));
      }
    }
  };
  xhr.send(null);
}
